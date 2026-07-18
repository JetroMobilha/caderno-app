import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import 'package:permission_handler/permission_handler.dart';
import 'realtime_service.dart';
import 'dart:async';

class WebRTCService {
  static final WebRTCService _instance = WebRTCService._internal();
  factory WebRTCService() => _instance;
  Timer? _talkingTimer;
  WebRTCService._internal();

  MediaStream? _localStream;
  final Map<String, RTCPeerConnection> _peerConnections = {};

  // Servidores STUN públicos da Google (Gratuitos e estáveis)
  final Map<String, dynamic> _iceServers = {
    'iceServers': [
      {'urls': 'stun:stun.l.google.com:19302'},
      {'urls': 'stun:stun1.l.google.com:19302'},
    ]
  };

  bool _isMuted = false;
  bool _isSpeakerOn = true;
  String? _currentUserId;
  int? _currentNotebookId;

  // 1. INICIAR ÁUDIO E OUVIR SINALIZAÇÃO
  Future<bool> joinVoiceRoom(int notebookId, String myUserId, List<String> existingUserIds) async {
    _currentNotebookId = notebookId;
    _currentUserId = myUserId;

    if (!kIsWeb) {
      final status = await Permission.microphone.request();
      if (!status.isGranted) return false;
    }

    try {
      _localStream = await navigator.mediaDevices.getUserMedia({
        'audio': true,
        'video': false,
      });

      RealtimeService().onWebRTCSignalReceived.listen(_handleIncomingSignal);

      for (var targetUserId in existingUserIds) {
        if (targetUserId != _currentUserId) {
          await _createPeerConnection(targetUserId, isInitiator: true);
        }
      }

      // 🚀 PONTO DE IGNIÇÃO: Liga o radar de voz mal entramos na sala!
      _startVoiceActivityDetection();

      return true;
    } catch (e) {
      debugPrint('🚨 Erro ao iniciar WebRTC: $e');
      return false;
    }
  }
  // 2. CRIAR CONEXÃO PEER-TO-PEER
  Future<RTCPeerConnection> _createPeerConnection(String targetUserId, {required bool isInitiator}) async {
    final pc = await createPeerConnection(_iceServers);
    _peerConnections[targetUserId] = pc;

    // Adicionar o nosso microfone à ligação
    _localStream?.getTracks().forEach((track) {
      pc.addTrack(track, _localStream!);
    });

    // Enviar ICE Candidates descobertos para o outro aluno via Reverb
    pc.onIceCandidate = (candidate) {
      RealtimeService().sendWebRTCSignal(_currentNotebookId!, {
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

    // Se nós formos os iniciadores, criamos a Oferta (SDP Offer)
    if (isInitiator) {
      RTCSessionDescription offer = await pc.createOffer();
      await pc.setLocalDescription(offer);
      RealtimeService().sendWebRTCSignal(_currentNotebookId!, {
        'type': 'offer',
        'target_id': targetUserId,
        'sender_id': _currentUserId,
        'sdp': offer.sdp,
      });
    }

    return pc;
  }

  // 3. PROCESSAR SINALIZAÇÃO RECEBIDA DO REVERB
  void _handleIncomingSignal(Map<String, dynamic> data) async {
    if (data['target_id'] != _currentUserId) return; // Não é para mim

    final String senderId = data['sender_id'].toString();
    final String type = data['type'];

    RTCPeerConnection? pc = _peerConnections[senderId];

    if (type == 'offer') {
      pc ??= await _createPeerConnection(senderId, isInitiator: false);
      await pc.setRemoteDescription(RTCSessionDescription(data['sdp'], 'offer'));

      RTCSessionDescription answer = await pc.createAnswer();
      await pc.setLocalDescription(answer);

      RealtimeService().sendWebRTCSignal(_currentNotebookId!, {
        'type': 'answer',
        'target_id': senderId,
        'sender_id': _currentUserId,
        'sdp': answer.sdp,
      });
    } else if (type == 'answer' && pc != null) {
      await pc.setRemoteDescription(RTCSessionDescription(data['sdp'], 'answer'));
    } else if (type == 'ice' && pc != null) {
      final cData = data['candidate'];
      await pc.addCandidate(RTCIceCandidate(cData['candidate'], cData['sdpMid'], cData['sdpMLineIndex']));
    } else if (type == 'leave') {
      _closePeer(senderId);
    }
  }

  // 4. CONTROLO DE ÁUDIO
  void toggleMute() {
    _isMuted = !_isMuted;
    _localStream?.getAudioTracks().forEach((track) => track.enabled = !_isMuted);
  }

  void toggleSpeaker() {
    _isSpeakerOn = !_isSpeakerOn;
    _localStream?.getAudioTracks().forEach((track) => track.enableSpeakerphone(_isSpeakerOn));
  }

  void _closePeer(String userId) {
    _peerConnections[userId]?.close();
    _peerConnections.remove(userId);
  }

  void leaveVoiceRoom() {
    // 🛑 DESLIGA O RADAR DE VOZ IMEDIATAMENTE
    _talkingTimer?.cancel();
    _talkingTimer = null;

    if (_currentNotebookId != null && _currentUserId != null) {
      RealtimeService().sendWebRTCSignal(_currentNotebookId!, {
        'type': 'leave',
        'sender_id': _currentUserId,
      });
    }

    _localStream?.dispose();
    _localStream = null;
    _peerConnections.forEach((_, pc) => pc.close());
    _peerConnections.clear();

    debugPrint('🔇 [WebRTC] Sala de voz encerrada e radar de áudio limpo.');
  }


  void _startVoiceActivityDetection() {
    _talkingTimer?.cancel();

    // Verifica o volume da voz a cada 400ms
    _talkingTimer = Timer.periodic(const Duration(milliseconds: 400), (_) async {
      for (var entry in _peerConnections.entries) {
        final String remoteUserId = entry.key;
        final RTCPeerConnection pc = entry.value;

        try {
          final stats = await pc.getStats();
          for (var report in stats) {
            // Procura pelo relatório da faixa de áudio que estamos a receber
            if (report.type == 'inbound-rtp' && report.values['kind'] == 'audio') {
              final double audioLevel = (report.values['audioLevel'] as num?)?.toDouble() ?? 0.0;

              // 🎙️ Se o nível de áudio for maior que 0.05, o aluno está a falar!
              final bool isSpeaking = audioLevel > 0.05;

              // Avisa o CanvasController para atualizar o aro verde desse ID
              RealtimeService().updateUserTalkingState(remoteUserId, isSpeaking);
            }
          }
        } catch (_) {
          // Ignora erros momentâneos de estatísticas durante a renegociação P2P
        }
      }
    });
  }
}