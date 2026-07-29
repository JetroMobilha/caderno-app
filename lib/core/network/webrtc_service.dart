import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'realtime_service.dart';
import 'dart:async';

class AudioLevelEvent {
  final String userId;
  final double level;
  AudioLevelEvent(this.userId, this.level);
}

class PeerState {
  bool makingOffer = false;
  bool isCreating = false;
  bool isProcessingSignal = false;
  String? lastOfferSdp;
  String? lastAnswerSdp;
  DateTime lastOfferSentAt = DateTime.fromMillisecondsSinceEpoch(0);
  final List<RTCIceCandidate> iceQueue = [];
}

class PeerConnectionState {
  final RTCPeerConnection pc;
  final PeerState state;
  bool remoteDescriptionSet = false;
  MediaStream? remoteStream;

  PeerConnectionState(this.pc, this.state);
}

class WebRTCService {
  final RealtimeService _realtimeService;
  Timer? _talkingTimer;

  MediaStream? _localStream;
  final Map<String, PeerConnectionState> _peers = {};
  final Map<String, PeerState> _peerStates = {}; // Persistir estados entre re-criações
  StreamSubscription? _signalSubscription;

  final _audioLevelController = StreamController<AudioLevelEvent>.broadcast();
  Stream<AudioLevelEvent> get onAudioLevel => _audioLevelController.stream;

  WebRTCService(this._realtimeService);

  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
      {'urls': 'stun:stun2.l.google.com:19302'},
      {'urls': 'stun:stun3.l.google.com:19302'},
      {'urls': 'stun:stun4.l.google.com:19302'},
    ],
    'sdpSemantics': 'unified-plan'
  };

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  String? _currentUserId;
  int? _currentNotebookId;

  Future<bool> joinVoiceRoom(int notebookId, String myUserId, List<String> existingUserIds) async {
    _currentNotebookId = notebookId;
    _currentUserId = myUserId;

    try {
      await _signalSubscription?.cancel();
      _signalSubscription = _realtimeService.onWebRTCSignalReceived.listen(_handleIncomingSignal);

      final int myIdNum = int.tryParse(myUserId) ?? 0;

      for (var targetUserId in existingUserIds) {
        if (targetUserId != _currentUserId) {
          final int targetIdNum = int.tryParse(targetUserId) ?? 0;
          if (myIdNum > targetIdNum) {
            debugPrint('📡 [WebRTC] SOU o iniciador para $targetUserId');
            if (!_peers.containsKey(targetUserId)) {
              await _createPeerConnection(targetUserId, isInitiator: true);
            }
          } else {
            debugPrint('⏳ [WebRTC] Aguardando oferta de $targetUserId');
          }
        }
      }

      _startVoiceActivityDetection();
      return true;
    } catch (e) {
      debugPrint('🚨 Erro ao entrar na sala WebRTC: $e');
      return false;
    }
  }

  void handleNewUserJoined(List<String> currentOnlineIds) async {
    if (_currentUserId == null) return;
    final int myIdNum = int.tryParse(_currentUserId!) ?? 0;

    for (var userId in currentOnlineIds) {
      if (userId != _currentUserId && !_peers.containsKey(userId)) {
        final int targetIdNum = int.tryParse(userId) ?? 0;
        if (myIdNum > targetIdNum) {
          debugPrint('📡 [WebRTC] Novo utilizador detectado ($userId). Iniciando oferta...');
          await _createPeerConnection(userId, isInitiator: true);
        }
      }
    }
  }

  void onUserJoinedVoice(String userId) async {
    if (_currentUserId == null || userId == _currentUserId) return;
    
    final int myIdNum = int.tryParse(_currentUserId!) ?? 0;
    final int targetIdNum = int.tryParse(userId) ?? 0;

    if (myIdNum > targetIdNum) {
      PeerConnectionState? peer = _peers[userId];
      if (peer == null) {
        debugPrint('📡 [WebRTC] Utilizador $userId entrou na VOZ. Criando ligação...');
        await _createPeerConnection(userId, isInitiator: true);
      } else {
        final signalingState = await peer.pc.getSignalingState();
        if (signalingState == RTCSignalingState.RTCSignalingStateStable) return;
        _makeOffer(userId, peer.pc);
      }
    }
  }

  Future<bool> enableLocalAudio() async {
    if (_localStream != null) return true;

    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
      await Permission.microphone.request();
    }

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': {
          'echoCancellation': true,
          'noiseSuppression': true,
          'autoGainControl': true,
        },
        'video': false,
      });

      if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) {
        await Helper.setSpeakerphoneOn(_isSpeakerOn);
        if (Platform.isAndroid) {
          await Helper.setAndroidAudioConfiguration(AndroidAudioConfiguration.communication);
        }
      }

      final audioTrack = _localStream!.getAudioTracks().firstOrNull;
      if (audioTrack != null) {
        audioTrack.enabled = !_isMuted;
        for (var peer in _peers.values) {
          final transceivers = await peer.pc.getTransceivers();
          final audioT = transceivers.where((t) => t.sender.track?.kind == 'audio' || t.receiver.track?.kind == 'audio').firstOrNull;
          if (audioT != null) await audioT.sender.replaceTrack(audioTrack);
        }
      }

      debugPrint('🎙️ [WebRTC] Microfone ativado localmente.');
      return true;
    } catch (e) {
      debugPrint('🚨 Erro ao capturar áudio local: $e');
      return false;
    }
  }

  Future<RTCPeerConnection> _createPeerConnection(String targetUserId, {required bool isInitiator}) async {
    final pc = await createPeerConnection(_iceServers);
    
    final state = _peerStates[targetUserId] ?? PeerState();
    _peerStates[targetUserId] = state;
    _peers[targetUserId] = PeerConnectionState(pc, state);

    // 🛡️ UNIFIED PLAN SYNC: Adicionar Audio E Video (mesmo que vídeo seja inativo)
    // Isto garante que o número de m-lines no SDP coincide com o que o Windows envia.
    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeAudio,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.SendRecv),
    );
    
    await pc.addTransceiver(
      kind: RTCRtpMediaType.RTCRtpMediaTypeVideo,
      init: RTCRtpTransceiverInit(direction: TransceiverDirection.Inactive),
    );

    if (_localStream != null && _localStream!.getAudioTracks().isNotEmpty) {
      final transceivers = await pc.getTransceivers();
      final audioT = transceivers.where((t) => t.sender.track?.kind == 'audio').firstOrNull;
      if (audioT != null) await audioT.sender.replaceTrack(_localStream!.getAudioTracks().first);
    }

    pc.onRenegotiationNeeded = () {
      debugPrint('🔄 [WebRTC] Renegociação necessária para $targetUserId');
      _makeOffer(targetUserId, pc);
    };

    pc.onTrack = (RTCTrackEvent event) {
      if (event.track.kind == 'audio') {
        debugPrint('🎧 [WebRTC] Áudio remoto recebido de $targetUserId');
        event.track.enabled = true;
        if (event.streams.isNotEmpty) {
          _peers[targetUserId]?.remoteStream = event.streams.first;
        }
      }
    };

    pc.onConnectionState = (state) {
      debugPrint('📡 [WebRTC] Estado da ligação com $targetUserId: ${state.name}');
    };

    pc.onIceConnectionState = (state) {
      debugPrint('🕸️ [WebRTC] ICE Connection ($targetUserId): ${state.name}');
      if (state == RTCIceConnectionState.RTCIceConnectionStateFailed) {
        debugPrint('🔄 [WebRTC] ICE falhou. Tentando RESTART em 2s...');
        Timer(const Duration(seconds: 2), () {
          if (_peers.containsKey(targetUserId)) _makeOffer(targetUserId, pc, restartIce: true);
        });
      }
    };

    pc.onIceCandidate = (candidate) {
      final candStr = candidate.candidate ?? '';
      String type = candStr.contains('typ srflx') ? 'SRFLX' : (candStr.contains('typ relay') ? 'RELAY' : 'HOST');
      debugPrint('📍 [WebRTC] Candidate ($type) para $targetUserId: ${candStr.substring(0, candStr.length > 25 ? 25 : candStr.length)}...');
      
      _realtimeService.sendWebRTCSignal(_currentNotebookId!, {
        'type': 'ice',
        'target_id': targetUserId,
        'sender_id': _currentUserId,
        'candidate': {
          'candidate': candidate.candidate,
          'sdpMid': candidate.sdpMid,
          'sdpMLineIndex': candidate.sdpMLineIndex,
        }
      });
    };

    if (isInitiator) _makeOffer(targetUserId, pc);
    return pc;
  }

  Future<void> _makeOffer(String targetUserId, RTCPeerConnection pc, {bool restartIce = false}) async {
    final peer = _peers[targetUserId];
    if (peer == null || peer.state.makingOffer) return;

    final now = DateTime.now();
    if (!restartIce && now.difference(peer.state.lastOfferSentAt).inMilliseconds < 1500) return;

    try {
      peer.state.makingOffer = true;
      peer.state.lastOfferSentAt = now;
      debugPrint('📤 [WebRTC] Criando oferta para $targetUserId...');
      
      RTCSessionDescription offer = await pc.createOffer(restartIce ? {'iceRestart': true} : {});
      await pc.setLocalDescription(offer);
      
      _realtimeService.sendWebRTCSignal(_currentNotebookId!, {
        'type': 'offer', 'target_id': targetUserId, 'sender_id': _currentUserId, 'sdp': offer.sdp,
      });
    } catch (e) {
      debugPrint('🚨 Erro oferta: $e');
    } finally {
      peer.state.makingOffer = false;
    }
  }

  void _handleIncomingSignal(Map<String, dynamic> data) async {
    try {
      final String senderId = data['sender_id'].toString();
      final String targetId = data['target_id'].toString();
      final String type = data['type'];
      
      if (targetId != _currentUserId.toString() || senderId == _currentUserId.toString()) return;

      PeerConnectionState? peer = _peers[senderId];
      if (peer == null && type != 'leave') {
        await _createPeerConnection(senderId, isInitiator: false);
        peer = _peers[senderId];
      }
      if (peer == null) return;

      if (peer.state.isProcessingSignal && type != 'ice') return;

      if (type == 'offer') {
        final String sdp = data['sdp'];
        if (peer.state.lastOfferSdp == sdp) return;
        peer.state.isProcessingSignal = true;
        peer.state.lastOfferSdp = sdp;

        final int myIdNum = int.tryParse(_currentUserId ?? '0') ?? 0;
        final int senderIdNum = int.tryParse(senderId) ?? 0;
        
        bool collision = (peer.state.makingOffer) || (await peer.pc.getSignalingState() != RTCSignalingState.RTCSignalingStateStable);
        if (collision && myIdNum < senderIdNum) {
           debugPrint('🔄 [WebRTC] Glare: Eu ignoro a oferta de $senderId');
           peer.state.isProcessingSignal = false;
           return;
        }

        await peer.pc.setRemoteDescription(RTCSessionDescription(sdp, 'offer'));
        peer.remoteDescriptionSet = true;
        RTCSessionDescription answer = await peer.pc.createAnswer();
        await peer.pc.setLocalDescription(answer);

        _realtimeService.sendWebRTCSignal(_currentNotebookId!, {
          'type': 'answer', 'target_id': senderId, 'sender_id': _currentUserId, 'sdp': answer.sdp,
        });
        _processIceQueue(senderId);
        peer.state.isProcessingSignal = false;

      } else if (type == 'answer') {
        final sigState = await peer.pc.getSignalingState();
        if (sigState != RTCSignalingState.RTCSignalingStateHaveLocalOffer) return;

        peer.state.isProcessingSignal = true;
        await peer.pc.setRemoteDescription(RTCSessionDescription(data['sdp'], 'answer'));
        peer.remoteDescriptionSet = true;
        _processIceQueue(senderId);
        peer.state.isProcessingSignal = false;

      } else if (type == 'ice') {
        final candidate = RTCIceCandidate(data['candidate']['candidate'], data['candidate']['sdpMid'], data['candidate']['sdpMLineIndex']);
        if (!peer.remoteDescriptionSet) {
          peer.state.iceQueue.add(candidate);
        } else {
          await peer.pc.addCandidate(candidate);
        }
      } else if (type == 'leave') {
        _closePeer(senderId);
      }
    } catch (e) {
      debugPrint('⚠️ Erro sinal: $e');
    }
  }

  void _processIceQueue(String userId) async {
    final peer = _peers[userId];
    if (peer != null) {
      for (var cand in peer.state.iceQueue) {
        await peer.pc.addCandidate(cand).catchError((e) => debugPrint('! Erro ICE Queue: $e'));
      }
      peer.state.iceQueue.clear();
    }
  }

  void toggleMute() {
    _isMuted = !_isMuted;
    _localStream?.getAudioTracks().forEach((t) => t.enabled = !_isMuted);
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    if (!kIsWeb && (Platform.isAndroid || Platform.isIOS)) Helper.setSpeakerphoneOn(_isSpeakerOn);
  }

  void _closePeer(String userId) {
    _peers[userId]?.pc.dispose();
    _peers.remove(userId);
  }

  void leaveVoiceRoom() {
    _talkingTimer?.cancel();
    _signalSubscription?.cancel();
    if (_currentNotebookId != null && _currentUserId != null) {
      _realtimeService.sendWebRTCSignal(_currentNotebookId!, {'type': 'leave', 'sender_id': _currentUserId});
    }
    _localStream?.getTracks().forEach((t) => t.stop());
    _localStream?.dispose();
    _localStream = null;
    _peers.forEach((id, peer) => peer.pc.dispose());
    _peers.clear();
    debugPrint('🔇 [WebRTC] Sala encerrada.');
  }

  void _startVoiceActivityDetection() {
    _talkingTimer?.cancel();
    _talkingTimer = Timer.periodic(const Duration(milliseconds: 400), (_) async {
      if (_localStream != null && _currentUserId != null) {
        final audioTracks = _localStream!.getAudioTracks();
        if (audioTracks.isNotEmpty && audioTracks.first.enabled) {
          _audioLevelController.add(AudioLevelEvent(_currentUserId!, _isMuted ? 0.0 : 0.01));
        }
      }
      for (var entry in _peers.entries.toList()) {
        try {
          final stats = await entry.value.pc.getStats();
          for (var report in stats) {
            if (report.type == 'inbound-rtp' && report.values['kind'] == 'audio') {
              final double audioLevel = (report.values['audioLevel'] as num?)?.toDouble() ?? 0.0;
              _audioLevelController.add(AudioLevelEvent(entry.key, audioLevel));
              _realtimeService.updateUserTalkingState(entry.key, audioLevel > 0.05);
            }
          }
        } catch (_) { }
      }
    });
  }
}

final webrtcServiceProvider = Provider<WebRTCService>((ref) {
  return WebRTCService(ref.read(realtimeServiceProvider));
});
