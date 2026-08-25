import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart' as drift;

import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'package:caderno_digital_app/features/canvas/models/audio_stream_buffer.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';
import 'package:caderno_digital_app/core/database/app_database.dart' as db;

class AudioSessionService extends ChangeNotifier {
  final CanvasRepository _repository;
  final RealtimeService _realtimeService;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioRecorder? _audioRecorderInstance;
  AudioRecorder get _audioRecorder => _audioRecorderInstance ??= AudioRecorder();

  String? currentlyPlayingAudioUrl;
  double audioPlaybackProgress = 0.0;
  double playbackSpeed = 1.0;
  Duration? _currentAudioDuration;
  Duration? _currentAudioPosition;

  db.LessonRecording? currentlyPlayingRecording;
  List<db.LessonRecording> lessonRecordings = [];

  bool isRecording = false;
  bool isLessonRecording = false;
  bool _isRecordingLive = false;
  DateTime? _recordingStartTime;
  String? _activeStreamMessageId;
  int _currentSegmentIndex = 0;
  
  final Map<String, AudioStreamBuffer> _audioBuffers = {};
  final Set<String> _playingStreamIds = {};
  final List<Map<String, dynamic>> _failedSegmentsQueue = [];

  bool isSpeakerOn = true;
  bool _isDisposed = false;

  // Callbacks para sincronização com o CanvasController / Chat
  void Function(Map<String, dynamic>)? onAudioMessageProcessed;
  void Function(String streamId, bool isFinal)? onStreamBufferUpdated;
  void Function(bool isTalking, double level)? onAmplitudeChanged;

  AudioSessionService(this._repository, this._realtimeService) {
    _audioPlayer.onPlayerComplete.listen((_) {
      audioPlaybackProgress = 0.0;
      _currentAudioDuration = null;
      _currentAudioPosition = null;
      safeNotify();
    });
    _audioPlayer.onPositionChanged.listen((pos) {
      _currentAudioPosition = pos;
      if (currentlyPlayingAudioUrl == null) return;
      
      if (_currentAudioDuration != null && _currentAudioDuration!.inMilliseconds > 0) {
        audioPlaybackProgress = (pos.inMilliseconds / _currentAudioDuration!.inMilliseconds).clamp(0.0, 1.0);
        safeNotify();
      } else {
        _audioPlayer.getDuration().then((dur) {
          if (dur != null && dur.inMilliseconds > 0) {
            _currentAudioDuration = dur;
            audioPlaybackProgress = (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
            safeNotify();
          }
        });
      }
    });
    _audioPlayer.setVolume(1.0);
  }

  void safeNotify() { if (!_isDisposed) notifyListeners(); }

  bool get isAudioPlaying => _audioPlayer.state == PlayerState.playing;
  Duration get audioPosition => _currentAudioPosition ?? Duration.zero;
  Duration get audioDuration => _currentAudioDuration ?? Duration.zero;
  Duration get recordingDuration => _recordingStartTime != null ? DateTime.now().difference(_recordingStartTime!) : Duration.zero;

  Future<void> loadLessonRecordings(int notebookId) async {
    final d = db.AppDatabase.instance;
    final rows = await (d.select(d.lessonRecordings)..where((t) => t.notebookId.equals(notebookId))).get();
    lessonRecordings = rows;
    safeNotify();
  }

  Future<void> pauseAudio() async { await _audioPlayer.pause(); safeNotify(); }
  Future<void> resumeAudio() async { await _audioPlayer.resume(); safeNotify(); }
  Future<void> stopAudio() async { await _audioPlayer.stop(); currentlyPlayingAudioUrl = null; safeNotify(); }

  Future<void> playRecording(db.LessonRecording rec) async {
    currentlyPlayingRecording = rec;
    await playAudioMessage(rec.audioUrl);
  }

  void setPlaybackSpeed(double speed) {
    playbackSpeed = speed;
    _audioPlayer.setPlaybackRate(speed);
    safeNotify();
  }

  Future<void> seekAudio(double percent) async {
    final dur = await _audioPlayer.getDuration();
    if (dur != null) {
      final target = dur * percent;
      await _audioPlayer.seek(target);
    }
  }

  Future<void> skipAudio(int seconds) async {
    final pos = await _audioPlayer.getCurrentPosition();
    if (pos != null) {
      final target = pos + Duration(seconds: seconds);
      await _audioPlayer.seek(target);
    }
  }

  Future<void> startLessonRecording() async {
    if (isLessonRecording) return;
    try {
      if (await _audioRecorder.hasPermission()) {
        isLessonRecording = true;
        _recordingStartTime = DateTime.now();
        _activeStreamMessageId = const Uuid().v4();
        
        String? path;
        if (!kIsWeb) {
          final dir = await getTemporaryDirectory();
          path = '${dir.path}/lesson_$_activeStreamMessageId.m4a';
        }
        
        await _audioRecorder.start(_getRecordConfig(), path: path ?? '');
        safeNotify();
      }
    } catch (e) {
      isLessonRecording = false;
      safeNotify();
    }
  }

  Future<void> stopLessonRecording(String title, int notebookId, int? liveNotebookSid, String myUserId) async {
    if (!isLessonRecording) return;
    try {
      final String? tempPath = await _audioRecorder.stop();
      final duration = recordingDuration.inSeconds;
      final clientId = _activeStreamMessageId!;
      isLessonRecording = false;
      _recordingStartTime = null;
      safeNotify();

      if (tempPath != null && !kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final recordingsDir = io.Directory('${appDir.path}/recordings');
        if (!await recordingsDir.exists()) await recordingsDir.create(recursive: true);
        
        final permanentPath = '${recordingsDir.path}/lesson_$clientId.m4a';
        await io.File(tempPath).copy(permanentPath);

        final d = db.AppDatabase.instance;
        await d.into(d.lessonRecordings).insert(db.LessonRecordingsCompanion.insert(
          notebookId: notebookId,
          clientId: drift.Value(clientId),
          title: title,
          audioUrl: permanentPath, 
          durationSeconds: drift.Value(duration),
          updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
        ));
        await loadLessonRecordings(notebookId);

        if (liveNotebookSid != null && liveNotebookSid != 0) {
          final bytes = await io.File(permanentPath).readAsBytes();
          final remoteUrl = await _repository.uploadLessonAudio(
            liveNotebookSid, 
            'lesson_$clientId.m4a', 
            bytes,
            title: title,
            duration: duration,
            clientId: clientId
          );

          if (remoteUrl != null) {
            await (d.update(d.lessonRecordings)..where((t) => t.clientId.equals(clientId))).write(
              db.LessonRecordingsCompanion(
                audioUrl: drift.Value(remoteUrl),
                syncedWithCloud: const drift.Value(1),
              )
            );
            await loadLessonRecordings(notebookId);
          }
        }
      }
    } catch (e) {
      isLessonRecording = false;
      safeNotify();
    }
  }

  Future<void> startRecording({bool isLive = false, bool isLiveSessionActive = false, int? liveNotebookSid, String? myUserId}) async { 
    try { 
      if (_isDisposed || isRecording) return; 
      if (await _audioRecorder.hasPermission()) { 
        isRecording = true; _isRecordingLive = isLive; _recordingStartTime = DateTime.now(); _activeStreamMessageId = const Uuid().v4(); _currentSegmentIndex = 0; 
        
        String? path; 
        if (!kIsWeb) { 
          final dir = await getTemporaryDirectory(); 
          path = '${dir.path}/audio_${_activeStreamMessageId}_0.m4a'; 
        } 
        
        await _audioRecorder.start(_getRecordConfig(), path: path ?? ''); safeNotify(); 
        if (isLive) { 
          _segmentTimer = Timer.periodic(const Duration(seconds: 1), (timer) => _rotateRecordingSegment(liveNotebookSid, myUserId)); 
          _startAmplitudeMonitoring(isLiveSessionActive, liveNotebookSid, myUserId); 
        }
      } 
    } catch (e) { isRecording = false; _isRecordingLive = false; safeNotify(); } 
  }

  Timer? _segmentTimer;
  Timer? _amplitudeTimer;

  void _startAmplitudeMonitoring(bool isLiveSessionActive, int? liveNotebookSid, String? myUserId) {
    _amplitudeTimer?.cancel(); bool lastTalkingState = false; double lastBroadcastLevel = 0.0; int ticksSinceUpdate = 0;
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 200), (t) async {
      if (!isRecording || !isLiveSessionActive) { t.cancel(); return; }
      final amp = await _audioRecorder.getAmplitude(); final bool isTalkingNow = amp.current > -35.0; double currentLevel = isTalkingNow ? (amp.current + 50).clamp(0.0, 50.0) / 50.0 : 0.0;
      if (isTalkingNow != lastTalkingState || (isTalkingNow && ((currentLevel - lastBroadcastLevel).abs() > 0.15 || ticksSinceUpdate >= 5))) {
        lastTalkingState = isTalkingNow; lastBroadcastLevel = currentLevel; ticksSinceUpdate = 0;
        _realtimeService.broadcastVoiceStateUpdate(notebookId: liveNotebookSid ?? 0, myUserId: myUserId ?? '', isInCall: true, isTalking: isTalkingNow, audioLevel: currentLevel);
        onAmplitudeChanged?.call(isTalkingNow, currentLevel);
        safeNotify();
      } else ticksSinceUpdate++;
    });
  }

  void _rotateRecordingSegment(int? liveNotebookSid, String? myUserId) async { 
    if (!isRecording || _activeStreamMessageId == null) return; 
    final String mid = _activeStreamMessageId!; final int idx = _currentSegmentIndex; 
    final bool isLive = _isRecordingLive;
    try { 
      final String? stopPath = await _audioRecorder.stop(); _currentSegmentIndex++; 
      String? next; 
      if (!kIsWeb) { 
        final dir = await getTemporaryDirectory(); 
        next = '${dir.path}/audio_${mid}_$idx.m4a'; 
      } 
      await _audioRecorder.start(_getRecordConfig(), path: next ?? ''); 
      if (stopPath != null) { 
        await Future.delayed(const Duration(milliseconds: 100)); 
        _processAndSendSegment(stopPath, mid, idx, 1, isFinal: false, isLive: isLive, liveNotebookSid: liveNotebookSid, myUserId: myUserId); 
      } 
    } catch (e) { debugPrint('🚨 [Audio] Erro na rotação de segmento: $e'); } 
  }

  Future<void> stopAndSendAudio(int? liveNotebookSid, String? myUserId) async { 
    try { 
      if (_isDisposed || !isRecording) return; _segmentTimer?.cancel(); _segmentTimer = null; 
      final String mid = _activeStreamMessageId!; final int idx = _currentSegmentIndex; final int dur = recordingDuration.inSeconds; 
      final bool isLive = _isRecordingLive;
      final path = await _audioRecorder.stop(); await Future.delayed(const Duration(milliseconds: 150));
      isRecording = false; _isRecordingLive = false; _recordingStartTime = null; _activeStreamMessageId = null; safeNotify(); 
      if (path != null) _processAndSendSegment(path, mid, idx, dur % 1 == 0 ? 1 : dur % 1, isFinal: true, isLive: isLive, liveNotebookSid: liveNotebookSid, myUserId: myUserId); 
    } catch (e) { isRecording = false; _isRecordingLive = false; safeNotify(); } 
  }

  void _processAndSendSegment(String path, String msgId, int index, num duration, {bool isFinal = false, bool isLive = false, int retryCount = 0, int? liveNotebookSid, String? myUserId}) async {
    if (liveNotebookSid == null) return;
    try {
      if (kIsWeb) return; 
      final file = io.File(path);
      if (!await file.exists()) return;
      
      final bytes = await file.readAsBytes(); 
      final url = await _repository.uploadAudio(liveNotebookSid, 'segment_${msgId}_$index.m4a', bytes);
      
      if (url != null) { 
        _realtimeService.broadcastAudioMessage(
          notebookId: liveNotebookSid, 
          myUserId: myUserId ?? '', 
          audioUrl: url, 
          duration: duration, 
          isLive: isLive, 
          streamMsgId: msgId, 
          segmentIndex: index, 
          isFinal: isFinal
        ); 
        
        if (index == 0 && !isLive) {
          onAudioMessageProcessed?.call({
            'msg_id': msgId,
            'type': 'audio',
            'sender_id': myUserId,
            'audio_url': url,
            'duration': duration, 
            'timestamp': DateTime.now().toIso8601String(),
          });
        }

        if (_failedSegmentsQueue.isNotEmpty) { 
          final next = _failedSegmentsQueue.removeAt(0); 
          _processAndSendSegment(next['path'], next['msgId'], next['index'], next['duration'], isFinal: next['isFinal'], isLive: next['isLive'] ?? false, retryCount: 0, liveNotebookSid: liveNotebookSid, myUserId: myUserId); 
        } 
      } else {
        if (retryCount < 5) {
          final int delaySeconds = math.pow(2, retryCount).toInt();
          Timer(Duration(seconds: delaySeconds), () {
            _processAndSendSegment(path, msgId, index, duration, isFinal: isFinal, isLive: isLive, retryCount: retryCount + 1, liveNotebookSid: liveNotebookSid, myUserId: myUserId);
          });
        } else {
          _failedSegmentsQueue.add({'path': path, 'msgId': msgId, 'index': index, 'duration': duration, 'isFinal': isFinal, 'isLive': isLive, 'retryCount': retryCount});
        }
      }
    } catch (e) {
      debugPrint('🚨 [Audio-Sync] Erro crítico no envio do segmento: $e');
    }
  }

  bool isStreamPlaying(String streamId) => _playingStreamIds.contains(streamId);
  bool isStreamFinalized(String streamId) => _audioBuffers[streamId]?.isFinalized ?? false;
  int getStreamSegmentCount(String streamId) => _audioBuffers[streamId]?.bufferedCount ?? 0;

  Future<void> playAudioStream(String streamId) async {
    if (_playingStreamIds.contains(streamId)) { await _audioPlayer.stop(); _playingStreamIds.remove(streamId); currentlyPlayingAudioUrl = null; _currentAudioDuration = null; safeNotify(); return; }
    final buffer = _audioBuffers[streamId]; if (buffer == null) return;
    _playingStreamIds.add(streamId); safeNotify();
    while (!buffer.isReadyToStart && _playingStreamIds.contains(streamId)) await Future.delayed(const Duration(milliseconds: 200));
    int starvationRetries = 0;
    while (_playingStreamIds.contains(streamId)) {
      final String? nextUrl = buffer.popNext();
      if (nextUrl != null) {
        starvationRetries = 0; currentlyPlayingAudioUrl = nextUrl; _currentAudioDuration = null; audioPlaybackProgress = 0.0; safeNotify();
        try {
          if (isSpeakerOn) await _audioPlayer.setVolume(1.0); 
          await _audioPlayer.play(UrlSource(nextUrl));
          final Completer<void> doneCompleter = Completer<void>();
          final sub = _audioPlayer.onPlayerStateChanged.listen((state) { if (state == PlayerState.completed || state == PlayerState.stopped) { if (!doneCompleter.isCompleted) doneCompleter.complete(); } });
          try { await doneCompleter.future.timeout(const Duration(seconds: 5)); } catch (_) {} finally { await sub.cancel(); }
        } catch (e) { await Future.delayed(const Duration(milliseconds: 500)); }
      } else {
        if (buffer.isFinalized && !buffer.hasMoreToPlay) break;
        await Future.delayed(const Duration(milliseconds: 300)); starvationRetries++;
        if (starvationRetries > 20) break;
      }
    }
    _playingStreamIds.remove(streamId); currentlyPlayingAudioUrl = null; safeNotify();
  }

  Future<void> playAudioMessage(String url) async {
    if (currentlyPlayingAudioUrl == url) { 
      await _audioPlayer.stop(); 
      currentlyPlayingAudioUrl = null; 
      _currentAudioDuration = null; 
      safeNotify(); 
      return; 
    }
    currentlyPlayingAudioUrl = url; 
    _currentAudioDuration = null; 
    audioPlaybackProgress = 0.0;
    safeNotify(); 

    if (isSpeakerOn) await _audioPlayer.setVolume(1.0); 
    
    if (url.startsWith('http')) {
      await _audioPlayer.play(UrlSource(url));
    } else {
      await _audioPlayer.play(DeviceFileSource(url));
    }
  }

  void handleIncomingAudioStream(Map<String, dynamic> data, String myUserId, bool isLiveSessionActive) {
    final String? sid = data['msg_id']?.toString() ?? data['stream_msg_id']?.toString();
    final String? url = data['audio_url']?.toString();
    final int? index = data['index'] as int? ?? data['segment_index'] as int?;
    final String? senderId = data['sender_id']?.toString();
    if (sid == null || url == null || index == null || senderId == null) return;
    final bool isFinal = data['is_final'] == true;

    final buffer = _audioBuffers.putIfAbsent(sid, () => AudioStreamBuffer(msgId: sid, senderId: senderId));
    
    if (buffer.bufferedCount == 0) {
      onAudioMessageProcessed?.call(data);
    } else {
      onStreamBufferUpdated?.call(sid, isFinal);
    }
    
    buffer.addSegment(index, url, isFinal: isFinal);
    
    if (_audioBuffers.length > 50) { 
      final now = DateTime.now(); 
      _audioBuffers.removeWhere((id, b) => !_playingStreamIds.contains(id) && now.difference(b.lastActivity).inMinutes > 5); 
    }
    
    if (isLiveSessionActive && senderId != myUserId && !_playingStreamIds.contains(sid)) { 
      if (buffer.isReadyToStart) playAudioStream(sid); 
    }
    safeNotify();
  }

  RecordConfig _getRecordConfig() => RecordConfig(
    encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc, 
    bitRate: 48000, 
    sampleRate: 44100, 
    numChannels: 1, 
    echoCancel: true, 
    noiseSuppress: true, 
    autoGain: true
  );

  void toggleSpeaker() { isSpeakerOn = !isSpeakerOn; _audioPlayer.setVolume(isSpeakerOn ? 1.0 : 0.0); safeNotify(); }

  @override
  void dispose() {
    _isDisposed = true;
    _audioPlayer.dispose();
    _audioRecorderInstance?.dispose();
    _segmentTimer?.cancel();
    _amplitudeTimer?.cancel();
    super.dispose();
  }
}

final audioSessionServiceProvider = ChangeNotifierProvider.autoDispose<AudioSessionService>((ref) {
  final repository = ref.read(canvasRepositoryProvider);
  final realtime = ref.read(realtimeServiceProvider);
  return AudioSessionService(repository, realtime);
});
