import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import 'package:permission_handler/permission_handler.dart';

import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

/// 🎙️ PttWalkieTalkieService
/// Serviço especializado em Comunicação Half-Duplex (Walkie-Talkie)
/// Zero-HTTP: Comunicação de áudio 100% via Whispers em WebSockets (Laravel Reverb / Pusher).
class PttWalkieTalkieService extends ChangeNotifier {
  final RealtimeService _realtimeService;

  final AudioPlayer? _customAudioPlayer;
  final AudioRecorder? _customAudioRecorder;

  AudioPlayer? _audioPlayerInstance;
  AudioPlayer get _audioPlayer => _audioPlayerInstance ??= (_customAudioPlayer ?? AudioPlayer());

  AudioRecorder? _audioRecorderInstance;
  AudioRecorder get _audioRecorder => _audioRecorderInstance ??= (_customAudioRecorder ?? AudioRecorder());

  // Estados de Canal e Bloqueio
  bool isChannelBusy = false;
  String? activeSpeakerId;
  String? activeSpeakerName;
  int? activeLockTimestamp;

  // Estados Locais de Transmissão
  bool isTransmitting = false;
  int? localLockTimestamp;
  int _sequenceNumber = 0;
  StreamSubscription<Uint8List>? _recordStreamSubscription;

  // Jitter Buffer para Absorver Oscilações de Rede (3-4 pacotes de retenção)
  final List<Uint8List> _jitterBuffer = [];
  bool _isPlayingJitterBuffer = false;
  static const int _jitterBufferMinSize = 3;

  // Gestão de Permissões, Erros e Web Autoplay
  bool isPermissionGranted = false;
  bool isWebAudioInitialized = false;
  bool _isDisposed = false;
  String? pttErrorMessage;

  void clearErrorMessage() {
    pttErrorMessage = null;
  }

  // Subscrições dos Whispers
  StreamSubscription? _lockedSub;
  StreamSubscription? _chunkSub;
  StreamSubscription? _unlockedSub;

  PttWalkieTalkieService(
    this._realtimeService, {
    AudioPlayer? audioPlayer,
    AudioRecorder? audioRecorder,
  })  : _customAudioPlayer = audioPlayer,
        _customAudioRecorder = audioRecorder {
    _initSubscriptions();
    try {
      _audioPlayer.setVolume(1.0);
    } catch (_) {}
  }

  void _safeNotify() {
    if (!_isDisposed) notifyListeners();
  }

  // -------------------------------------------------------------------------
  // 🌐 AUTOPLAY & PERMISSÕES MULTIPLATAFORMA (Android, iOS, Web, Win, Mac)
  // -------------------------------------------------------------------------

  /// Desbloqueia o AudioContext em navegadores Web mediante o primeiro clique do utilizador
  Future<void> initWebAudioContext() async {
    if (isWebAudioInitialized) return;
    try {
      if (kIsWeb) {
        await _audioPlayer.resume();
      }
      isWebAudioInitialized = true;
    } catch (_) {}
  }

  /// Verificação unificada de permissão de microfone
  Future<bool> checkAndRequestPermissions() async {
    try {
      if (!kIsWeb) {
        final status = await Permission.microphone.request();
        isPermissionGranted = status.isGranted;
      } else {
        isPermissionGranted = await _audioRecorder.hasPermission();
      }
      _safeNotify();
      return isPermissionGranted;
    } catch (e) {
      isPermissionGranted = false;
      _safeNotify();
      return false;
    }
  }

  // -------------------------------------------------------------------------
  // 📡 INICIALIZAÇÃO DE SUBSCRIÇÕES WEBSOCKET (WHISPERS)
  // -------------------------------------------------------------------------

  void _initSubscriptions() {
    _lockedSub?.cancel();
    _lockedSub = _realtimeService.onChannelLocked.listen(_handleRemoteChannelLocked);

    _chunkSub?.cancel();
    _chunkSub = _realtimeService.onAudioChunk.listen(_handleRemoteAudioChunk);

    _unlockedSub?.cancel();
    _unlockedSub = _realtimeService.onChannelUnlocked.listen(_handleRemoteChannelUnlocked);
  }

  // -------------------------------------------------------------------------
  // 🎤 TRANSMISSÃO LOCAL (PUSH-TO-TALK)
  // -------------------------------------------------------------------------

  Future<void> acquireLock({
    required int notebookId,
    required String myUserId,
    required String myUserName,
  }) async {
    if (_isDisposed) return;

    // 1. Garantir Permissão de Microfone
    final hasPerm = await checkAndRequestPermissions();
    if (!hasPerm) return;

    // 2. Se o canal estiver ocupado por outro utilizador, ignora
    if (isChannelBusy && activeSpeakerId != myUserId) return;

    // 3. Inicializar timestamps de bloqueio
    final nowMs = TimeService().nowMs();
    localLockTimestamp = nowMs;
    activeLockTimestamp = nowMs;
    isTransmitting = true;
    isChannelBusy = true;
    activeSpeakerId = myUserId;
    activeSpeakerName = myUserName;
    _sequenceNumber = 0;

    _safeNotify();

    // 4. Disparar Whisper `client-channel-locked`
    _realtimeService.broadcastChannelLocked(
      notebookId: notebookId,
      userId: myUserId,
      userName: myUserName,
      timestamp: nowMs,
    );

    // 5. Iniciar gravação em stream do microfone (chunks ~150ms)
    try {
      final recordConfig = RecordConfig(
        encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc,
        sampleRate: 16000,
        bitRate: 24000,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
        autoGain: true,
      );

      final stream = await _audioRecorder.startStream(recordConfig);
      _recordStreamSubscription?.cancel();
      _recordStreamSubscription = stream.listen((chunk) {
        if (!isTransmitting) return;

        _sequenceNumber++;
        final base64String = base64Encode(chunk);

        // Disparar Whisper `client-audio-chunk` diretamente no WebSocket
        _realtimeService.broadcastAudioChunk(
          notebookId: notebookId,
          userId: myUserId,
          sequence: _sequenceNumber,
          base64Data: base64String,
        );
      });
    } on PlatformException catch (e) {
      debugPrint('🚨 [PTT] Streaming de áudio não suportado nesta plataforma: $e');
      pttErrorMessage = defaultTargetPlatform == TargetPlatform.windows
          ? 'Rádio Aberta em tempo real disponível em Android, iOS e Web. No Windows utilize notas de voz no chat.'
          : 'Microfone não disponível ou não suportado.';
      releaseLock(notebookId: notebookId, myUserId: myUserId);
      _safeNotify();
    } catch (e) {
      debugPrint('🚨 [PTT] Erro ao iniciar stream de gravação: $e');
      releaseLock(notebookId: notebookId, myUserId: myUserId);
    }
  }

  Future<void> releaseLock({
    required int notebookId,
    required String myUserId,
  }) async {
    if (!isTransmitting && activeSpeakerId != myUserId) return;

    isTransmitting = false;
    isChannelBusy = false;
    activeSpeakerId = null;
    activeSpeakerName = null;
    localLockTimestamp = null;
    activeLockTimestamp = null;

    _recordStreamSubscription?.cancel();
    _recordStreamSubscription = null;

    try {
      await _audioRecorder.stop();
    } catch (_) {}

    _safeNotify();

    // Disparar Whisper `client-channel-unlocked`
    _realtimeService.broadcastChannelUnlocked(
      notebookId: notebookId,
      userId: myUserId,
    );
  }

  // -------------------------------------------------------------------------
  // 🔊 RECEÇÃO & JITTER BUFFER (ZERO-HTTP)
  // -------------------------------------------------------------------------

  void _handleRemoteChannelLocked(Map<String, dynamic> d) {
    if (_isDisposed) return;

    final String remoteUserId = d['user_id']?.toString() ?? '';
    final String remoteUserName = d['user_name']?.toString() ?? 'Colega';
    final int remoteTimestamp = (d['timestamp'] as num?)?.toInt() ?? 0;

    // 🚀 RESOLUÇÃO DE RACE CONDITION (Desempate por Timestamp)
    if (isTransmitting && localLockTimestamp != null) {
      if (remoteTimestamp < localLockTimestamp!) {
        // O utilizador remoto pressionou o botão PRIMEIRO!
        // O aplicativo local silencia-se, cancela a gravação e cede a palavra.
        debugPrint('⚠️ [PTT Race Condition] Empate detetado. Perdeu para $remoteUserName. Cancelando gravação local...');
        _cancelLocalTransmitWithoutUnlocking();
      } else {
        // O aplicativo local ganhou o desempate, ignora a tentativa remota
        return;
      }
    }

    isChannelBusy = true;
    activeSpeakerId = remoteUserId;
    activeSpeakerName = remoteUserName;
    activeLockTimestamp = remoteTimestamp;

    _jitterBuffer.clear();
    _safeNotify();
  }

  void _handleRemoteAudioChunk(Map<String, dynamic> d) {
    if (_isDisposed) return;

    final String senderId = d['user_id']?.toString() ?? '';
    if (senderId != activeSpeakerId && activeSpeakerId != null) return;

    final String? base64Str = d['data']?.toString();
    if (base64Str == null || base64Str.isEmpty) return;

    try {
      final Uint8List audioBytes = base64Decode(base64Str);
      _jitterBuffer.add(audioBytes);

      // Inicia a reprodução do Jitter Buffer assim que atinge o tamanho mínimo
      if (!_isPlayingJitterBuffer && _jitterBuffer.length >= _jitterBufferMinSize) {
        _processJitterBuffer();
      }
    } catch (e) {
      debugPrint('🚨 [PTT Buffer] Erro ao descodificar chunk: $e');
    }
  }

  void _handleRemoteChannelUnlocked(Map<String, dynamic> d) {
    if (_isDisposed) return;

    final String senderId = d['user_id']?.toString() ?? '';
    if (senderId == activeSpeakerId || activeSpeakerId == null) {
      isChannelBusy = false;
      activeSpeakerId = null;
      activeSpeakerName = null;
      activeLockTimestamp = null;
      _safeNotify();
    }
  }

  void _cancelLocalTransmitWithoutUnlocking() {
    isTransmitting = false;
    _recordStreamSubscription?.cancel();
    _recordStreamSubscription = null;
    try {
      _audioRecorder.stop();
    } catch (_) {}
  }

  /// Processa a fila do Jitter Buffer sequencialmente para evitar cortes na reprodução
  Future<void> _processJitterBuffer() async {
    if (_isPlayingJitterBuffer || _isDisposed) return;
    _isPlayingJitterBuffer = true;

    while (_jitterBuffer.isNotEmpty && !_isDisposed) {
      final chunk = _jitterBuffer.removeAt(0);
      try {
        await _audioPlayer.play(BytesSource(chunk));
        await Future.delayed(const Duration(milliseconds: 140));
      } catch (_) {}
    }

    _isPlayingJitterBuffer = false;
  }

  @override
  void dispose() {
    _isDisposed = true;
    _lockedSub?.cancel();
    _chunkSub?.cancel();
    _unlockedSub?.cancel();
    _recordStreamSubscription?.cancel();
    try {
      _audioPlayerInstance?.dispose();
      _audioRecorderInstance?.dispose();
    } catch (_) {}
    super.dispose();
  }
}

/// Riverpod Provider para o PttWalkieTalkieService
final pttWalkieTalkieServiceProvider = ChangeNotifierProvider<PttWalkieTalkieService>((ref) {
  final realtime = ref.read(realtimeServiceProvider);
  return PttWalkieTalkieService(realtime);
});
