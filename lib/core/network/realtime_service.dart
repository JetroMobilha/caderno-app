import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart'; 
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import 'api_config.dart';

enum RealtimeStatus { disconnected, connecting, connected, error }

class RealtimeService {
  PrivateChannel? _userChannel;
  PusherChannelsClient? _pusher;
  PresenceChannel? _notebookChannel;
  final Set<String> _boundEvents = {}; 
  
  // 🛡️ Subscrições e Estado de Membros
  StreamSubscription? _subSucceededSub;
  StreamSubscription? _memberAddedSub;
  StreamSubscription? _memberRemovedSub;
  StreamSubscription? _lifecycleSubscription; // 🚀 Única subscrição de ciclo de vida
  final Map<String, dynamic> _estudantesNaSala = {};

  final ValueNotifier<RealtimeStatus> statusNotifier = ValueNotifier(RealtimeStatus.disconnected);

  final _strokeStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _textStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _imageStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _viewportStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _followStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _usersStreamController = StreamController<List<dynamic>>.broadcast();
  final _pageEventStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _pageUpdatedStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _handStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _uploadingStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _inviteStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _voiceCallStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _voiceStateStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _activityStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _sessionMetaStreamController = StreamController<Map<String, dynamic>>.broadcast(); // 🚀 Novo
  final _pointerStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _audioMessageStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatSyncRequestController = StreamController<Map<String, dynamic>>.broadcast();
  final _chatSyncResponseController = StreamController<Map<String, dynamic>>.broadcast();
  final _reactionStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _collectiveSyncRequestController = StreamController<Map<String, dynamic>>.broadcast();
  final _fullStateRequestController = StreamController<Map<String, dynamic>>.broadcast();
  final _fullStateReceivedController = StreamController<Map<String, dynamic>>.broadcast();
  final _pageFingerprintStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _cloudSyncSignalStreamController = StreamController<Map<String, dynamic>>.broadcast(); // 🚀 Novo
  final _globalActionStreamController = StreamController<Map<String, dynamic>>.broadcast(); 
  final _syncPushFinishedController = StreamController<Map<String, dynamic>>.broadcast();
  final _pageDeletedStreamController = StreamController<Map<String, dynamic>>.broadcast(); 
  final _notebookDeletedStreamController = StreamController<Map<String, dynamic>>.broadcast(); 
  final _notebookAccessRevokedController = StreamController<Map<String, dynamic>>.broadcast(); // 🚀 Novo
  final _notebookStructureStreamController = StreamController<Map<String, dynamic>>.broadcast(); 

  Stream<Map<String, dynamic>> get onStrokeReceived => _strokeStreamController.stream;
  Stream<Map<String, dynamic>> get onTextReceived => _textStreamController.stream;
  Stream<Map<String, dynamic>> get onImageReceived => _imageStreamController.stream;
  Stream<Map<String, dynamic>> get onViewportReceived => _viewportStreamController.stream;
  Stream<Map<String, dynamic>> get onFollowUpdateReceived => _followStreamController.stream;
  Stream<List<dynamic>> get onUsersUpdated => _usersStreamController.stream;
  Stream<Map<String, dynamic>> get onPageEventReceived => _pageEventStreamController.stream;
  Stream<Map<String, dynamic>> get onPageUpdated => _pageUpdatedStreamController.stream;
  Stream<Map<String, dynamic>> get onHandEventReceived => _handStreamController.stream;
  Stream<Map<String, dynamic>> get onRemoteUploading => _uploadingStreamController.stream;
  Stream<Map<String, dynamic>> get onLiveInviteReceived => _inviteStreamController.stream;
  Stream<Map<String, dynamic>> get onVoiceCallStarted => _voiceCallStreamController.stream;
  Stream<Map<String, dynamic>> get onVoiceStateReceived => _voiceStateStreamController.stream;
  Stream<Map<String, dynamic>> get onUserActivityReceived => _activityStreamController.stream;
  Stream<Map<String, dynamic>> get onSessionMetaReceived => _sessionMetaStreamController.stream; // 🚀 Novo
  Stream<Map<String, dynamic>> get onPointerMoveReceived => _pointerStreamController.stream;
  Stream<Map<String, dynamic>> get onChatMessageReceived => _chatStreamController.stream;
  Stream<Map<String, dynamic>> get onAudioMessageReceived => _audioMessageStreamController.stream;
  Stream<Map<String, dynamic>> get onChatSyncRequestReceived => _chatSyncRequestController.stream;
  Stream<Map<String, dynamic>> get onChatSyncResponseReceived => _chatSyncResponseController.stream;
  Stream<Map<String, dynamic>> get onReactionReceived => _reactionStreamController.stream;
  Stream<Map<String, dynamic>> get onCollectiveSyncRequested => _collectiveSyncRequestController.stream;
  Stream<Map<String, dynamic>> get onFullStateRequested => _fullStateRequestController.stream;
  Stream<Map<String, dynamic>> get onFullStateReceived => _fullStateReceivedController.stream;
  Stream<Map<String, dynamic>> get onPageFingerprintReceived => _pageFingerprintStreamController.stream;
  Stream<Map<String, dynamic>> get onCloudSyncSignalReceived => _cloudSyncSignalStreamController.stream; // 🚀 Novo
  Stream<Map<String, dynamic>> get onGlobalActionReceived => _globalActionStreamController.stream; 
  Stream<Map<String, dynamic>> get onSyncPushFinished => _syncPushFinishedController.stream; 
  Stream<Map<String, dynamic>> get onPageDeleted => _pageDeletedStreamController.stream; 
  Stream<Map<String, dynamic>> get onNotebookDeleted => _notebookDeletedStreamController.stream; 
  Stream<Map<String, dynamic>> get onNotebookAccessRevoked => _notebookAccessRevokedController.stream; // 🚀
  Stream<Map<String, dynamic>> get onNotebookStructureUpdated => _notebookStructureStreamController.stream; 

  bool get isConnected => statusNotifier.value == RealtimeStatus.connected;

  final _webrtcStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onWebRTCSignalReceived => _webrtcStreamController.stream;

  Future<void> initConnection() async {
    if (statusNotifier.value == RealtimeStatus.connected && _pusher != null) return;
    statusNotifier.value = RealtimeStatus.connecting;

    final options = PusherChannelsOptions.fromHost(
      scheme: 'wss',
      host: ApiConfig.reverbHost,
      key: ApiConfig.reverbKey,
      port: ApiConfig.reverbPort,
      shouldSupplyMetadataQueries: true,
      metadata: const PusherChannelsOptionsMetadata(client: 'dart', version: '1.3.1', protocol: 7),
    );

    _pusher = PusherChannelsClient.websocket(
      options: options,
      connectionErrorHandler: (exception, trace, refresh) async {
        debugPrint('⚠️ [Realtime] Erro na conexão: $exception');
        statusNotifier.value = RealtimeStatus.error;
        await Future.delayed(const Duration(seconds: 5));
        refresh();
      },
    );

    _lifecycleSubscription?.cancel();
    _lifecycleSubscription = _pusher!.lifecycleStream.listen((state) async {
      debugPrint('📡 [Realtime] Estado do Socket: $state');
      if (state == PusherChannelsClientLifeCycleState.establishedConnection) {
        statusNotifier.value = RealtimeStatus.connected;
        debugPrint('✅ [Realtime] Conexão estabelecida com sucesso.');
        final prefs = await SharedPreferences.getInstance();
        final currentUserIdStr = prefs.getString('user_id');
        if (currentUserIdStr != null) _rebindGlobalListeners(int.parse(currentUserIdStr));
      } else if (state == PusherChannelsClientLifeCycleState.pendingConnection) {
        statusNotifier.value = RealtimeStatus.connecting;
      } else if (state == PusherChannelsClientLifeCycleState.disconnected) {
        statusNotifier.value = RealtimeStatus.disconnected;
        debugPrint('🔌 [Realtime] Socket desconectado.');
      } else if (state == PusherChannelsClientLifeCycleState.reconnecting) {
        statusNotifier.value = RealtimeStatus.connecting;
        debugPrint('🔄 [Realtime] Tentando reconectar...');
      } else if (state == PusherChannelsClientLifeCycleState.connectionError || 
                 state == PusherChannelsClientLifeCycleState.gotPusherError) {
        statusNotifier.value = RealtimeStatus.error;
        debugPrint('❌ [Realtime] Erro crítico de conexão.');
      }
    });

    try {
      _pusher!.connect();
    } catch (e) {
      statusNotifier.value = RealtimeStatus.error;
      debugPrint('❌ [Realtime] Falha ao ligar Reverb: $e');
    }
  }

  void _bindEvent(String eventName, void Function(ChannelReadEvent) onEvent) {
    if (_notebookChannel == null) return;
    if (_boundEvents.contains(eventName)) return;
    _boundEvents.add(eventName);
    _notebookChannel!.bind(eventName).listen(onEvent);
  }

  Map<String, dynamic> _safeParse(dynamic data) {
    if (data == null) return {};
    if (data is Map) return Map<String, dynamic>.from(data);
    if (data is String) {
      if (data.trim().isEmpty) return {};
      try {
        return jsonDecode(data);
      } catch (e) {
        debugPrint('❌ [Realtime] Erro ao decodificar JSON: $e | Data: $data');
        return {};
      }
    }
    return {};
  }

  Future<void> joinNotebookChannel({required int notebookId}) async {
    if (statusNotifier.value != RealtimeStatus.connected) await initConnection();
    
    int attempts = 0;
    while (statusNotifier.value != RealtimeStatus.connected && attempts < 10) {
      debugPrint('⏳ [Realtime] Aguardando conexão para entrar no canal (tentativa ${attempts + 1})...');
      await Future.delayed(const Duration(milliseconds: 1000));
      attempts++;
    }

    if (statusNotifier.value != RealtimeStatus.connected) {
      debugPrint('❌ [Realtime] Não foi possível conectar ao Reverb após $attempts tentativas.');
      return;
    }

    if (_notebookChannel != null) {
      debugPrint('🧹 [Realtime] Saindo do canal anterior: ${_notebookChannel!.name}');
      _notebookChannel!.unsubscribe();
    }

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('sanctum_token');
    final channelName = 'presence-notebook.$notebookId';
    
    _boundEvents.clear();

    final authDelegate = EndpointAuthorizableChannelTokenAuthorizationDelegate.forPresenceChannel(
      authorizationEndpoint: Uri.parse(ApiConfig.authEndpoint),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    _notebookChannel = _pusher!.presenceChannel(channelName, authorizationDelegate: authDelegate);

    _subSucceededSub = _notebookChannel!.whenSubscriptionSucceeded().listen((event) {
      final data = _safeParse(event.data);
      debugPrint('📡 [Realtime] Subscrição Presence confirmada para $channelName');
      
      _estudantesNaSala.clear();
      if (data['presence'] != null && data['presence']['hash'] != null) {
        final hash = Map<String, dynamic>.from(data['presence']['hash']);
        hash.forEach((uid, info) {
          final infoMap = Map<String, dynamic>.from(info);
          Map<String, dynamic> flattenedInfo = {};
          if (infoMap.containsKey('user_info')) {
            flattenedInfo = Map<String, dynamic>.from(infoMap['user_info']);
          } else {
            flattenedInfo = infoMap;
          }
          final String effectiveId = uid.toString();
          flattenedInfo['id'] = effectiveId; 
          
          // 🚀 PERSISTÊNCIA DE ESTADO: Recuperar estados de voz se existirem
          if (flattenedInfo['isInCall'] == null && flattenedInfo['is_in_call'] != null) {
            flattenedInfo['isInCall'] = flattenedInfo['is_in_call'] == true;
          }
          
          _estudantesNaSala[effectiveId] = flattenedInfo;
        });
      }
      _broadcastUsersList();
    });

    _memberAddedSub = _notebookChannel!.whenMemberAdded().listen((event) {
      final data = _safeParse(event.data);
      final String? uid = event.userId?.toString() ?? data['id']?.toString() ?? data['user_id']?.toString();
      debugPrint('🟢 [Realtime] EVENTO MEMBER_ADDED DETECTADO: $uid');
      if (uid == null) return;

      Map<String, dynamic> userInfo = {};
      if (data.containsKey('user_info')) {
        userInfo = Map<String, dynamic>.from(data['user_info']);
      } else {
        userInfo = data;
      }
      userInfo['id'] = uid; 
      
      // 🚀 NORMALIZAÇÃO DE CAMPOS
      if (userInfo['isInCall'] == null && userInfo['is_in_call'] != null) {
        userInfo['isInCall'] = userInfo['is_in_call'] == true;
      }

      _estudantesNaSala[uid] = userInfo;
      _broadcastUsersList();
    });

    _memberRemovedSub = _notebookChannel!.whenMemberRemoved().listen((event) {
      String? uid = event.userId?.toString();
      final dynamic rawData = event.data;
      
      debugPrint('🔴 [Realtime] EVENTO MEMBER_REMOVED DETECTADO: $uid | Data: $rawData');

      // 🚀 RECUPERAÇÃO DE ID MELHORADA PARA REVERB
      if (uid == null && rawData != null) {
        final parsedData = _safeParse(rawData);
        uid = parsedData['user_id']?.toString() ?? parsedData['id']?.toString();
      }
      
      if (uid != null) {
        _estudantesNaSala.remove(uid);
        _broadcastUsersList();
      }
    });

    _bindEvent('client-ink-stroke', (event) => _strokeStreamController.add(_safeParse(event.data)));
    _bindEvent('client-text-block', (event) => _textStreamController.add(_safeParse(event.data)));
    _bindEvent('client-image-block', (event) => _imageStreamController.add(_safeParse(event.data)));
    _bindEvent('client-viewport-sync', (event) => _viewportStreamController.add(_safeParse(event.data)));
    _bindEvent('client-follow-update', (event) => _followStreamController.add(_safeParse(event.data)));
    _bindEvent('client-page-event', (event) => _pageEventStreamController.add(_safeParse(event.data)));
    _bindEvent('PageUpdated', (event) => _pageUpdatedStreamController.add(_safeParse(event.data)));
    _bindEvent('client-webrtc-signal', (event) {
      _webrtcStreamController.add(_safeParse(event.data));
    });
    _bindEvent('client-hand-event', (event) => _handStreamController.add(_safeParse(event.data)));
    _bindEvent('client-image-uploading', (event) => _uploadingStreamController.add(_safeParse(event.data)));
    _bindEvent('client-voice-call-started', (event) => _voiceCallStreamController.add(_safeParse(event.data)));
    _bindEvent('client-voice-state-update', (event) => _voiceStateStreamController.add(_safeParse(event.data)));
    _bindEvent('client-session-meta', (event) => _sessionMetaStreamController.add(_safeParse(event.data))); // 🚀 Novo
    _bindEvent('client-user-activity', (event) => _activityStreamController.add(_safeParse(event.data)));
    _bindEvent('client-pointer-move', (event) => _pointerStreamController.add(_safeParse(event.data)));
    _bindEvent('client-chat-message', (event) => _chatStreamController.add(_safeParse(event.data)));
    _bindEvent('client-audio-message', (event) => _audioMessageStreamController.add(_safeParse(event.data)));
    _bindEvent('client-chat-sync-request', (event) => _chatSyncRequestController.add(_safeParse(event.data)));
    _bindEvent('client-chat-sync-response', (event) => _chatSyncResponseController.add(_safeParse(event.data)));
    _bindEvent('client-reaction', (event) => _reactionStreamController.add(_safeParse(event.data)));
    _bindEvent('client-collective-sync', (event) => _collectiveSyncRequestController.add(_safeParse(event.data)));
    _bindEvent('client-full-state-request', (event) => _fullStateRequestController.add(_safeParse(event.data)));
    _bindEvent('client-full-state-deliver', (event) => _fullStateReceivedController.add(_safeParse(event.data)));
    _bindEvent('client-page-fingerprint', (event) => _pageFingerprintStreamController.add(_safeParse(event.data)));
    _bindEvent('client-cloud-sync-signal', (event) => _cloudSyncSignalStreamController.add(_safeParse(event.data))); // 🚀 Novo
    _bindEvent('client-global-action', (event) => _globalActionStreamController.add(_safeParse(event.data))); 
    _bindEvent('client-sync-push-finished', (event) => _syncPushFinishedController.add(_safeParse(event.data)));
    _bindEvent('page.deleted', (event) => _pageDeletedStreamController.add(_safeParse(event.data))); // 🚀
    _bindEvent('notebook.deleted', (event) => _notebookDeletedStreamController.add(_safeParse(event.data))); // 🚀
    _bindEvent('notebook.structure.updated', (event) => _notebookStructureStreamController.add(_safeParse(event.data))); // 🚀
    _bindEvent('client-live-invite', (event) => _inviteStreamController.add(_safeParse(event.data)));

    _notebookChannel!.subscribe();
  }

  void sendWebRTCSignal(int notebookId, Map<String, dynamic> signalData) {
    if (signalData.containsKey('sender_id')) {
      signalData['sender_id'] = signalData['sender_id'].toString();
    }
    if (signalData.containsKey('target_id')) {
      signalData['target_id'] = signalData['target_id'].toString();
    }
    _notebookChannel?.trigger(eventName: 'client-webrtc-signal', data: jsonEncode(signalData));
  }

  Future<bool> broadcastStroke({required int notebookId, required Map<String, dynamic> strokeData, String? myUserId}) async {
    if (_notebookChannel == null) return false;
    if (myUserId != null) strokeData['sender_id'] = myUserId;
    _notebookChannel!.trigger(eventName: 'client-ink-stroke', data: jsonEncode(strokeData));
    return true;
  }

  Future<bool> broadcastTextBlock({required int notebookId, required Map<String, dynamic> textData, String? myUserId}) async {
    if (_notebookChannel == null) return false;
    if (myUserId != null) textData['sender_id'] = myUserId;
    _notebookChannel!.trigger(eventName: 'client-text-block', data: jsonEncode(textData));
    return true;
  }

  Future<bool> broadcastImageBlock({required int notebookId, required Map<String, dynamic> imageData, String? myUserId}) async {
    if (_notebookChannel == null) return false;
    if (myUserId != null) imageData['sender_id'] = myUserId;
    _notebookChannel!.trigger(eventName: 'client-image-block', data: jsonEncode(imageData));
    return true;
  }

  Future<bool> broadcastImageUploading({required int notebookId, required String myUserId, required bool isUploading}) async {
    if (_notebookChannel == null) return false;
    final data = {'sender_id': myUserId, 'is_uploading': isUploading};
    _notebookChannel!.trigger(eventName: 'client-image-uploading', data: jsonEncode(data));
    return true;
  }

  Future<bool> broadcastViewport({required int notebookId, required Map<String, dynamic> viewportData, required String myUserId}) async {
    if (_notebookChannel == null) return false;
    viewportData['sender_id'] = myUserId;
    _notebookChannel!.trigger(eventName: 'client-viewport-sync', data: jsonEncode(viewportData));
    return true;
  }

  Future<bool> broadcastFollowUpdate({required int notebookId, required String myUserId, String? followingUserId}) async {
    if (_notebookChannel == null) return false;
    final data = {'follower_id': myUserId, 'following_id': followingUserId};
    _notebookChannel!.trigger(eventName: 'client-follow-update', data: jsonEncode(data));
    return true;
  }

  Future<bool> broadcastPageEvent({required int notebookId, required Map<String, dynamic> pageData, required String myUserId}) async {
    if (_notebookChannel == null) return false;
    pageData['sender_id'] = myUserId;
    _notebookChannel!.trigger(eventName: 'client-page-event', data: jsonEncode(pageData));
    return true;
  }

  Future<bool> broadcastHandEvent({required int notebookId, required String myUserId, required bool isRaised}) async {
    if (_notebookChannel == null) return false;
    final data = {'sender_id': myUserId, 'is_raised': isRaised};
    _notebookChannel!.trigger(eventName: 'client-hand-event', data: jsonEncode(data));
    return true;
  }

  Future<bool> broadcastVoiceCallStarted({required int notebookId, required String myUserId, required String senderName}) async {
    if (_notebookChannel == null) return false;
    final data = {'notebook_id': notebookId, 'sender_id': myUserId, 'sender_name': senderName};
    _notebookChannel!.trigger(eventName: 'client-voice-call-started', data: jsonEncode(data));
    return true;
  }

  Future<bool> broadcastLiveInvite({required int notebookId, required String myUserId, required String senderName, required List<String> targetUserIds}) async {
    if (_notebookChannel == null) return false;
    final data = {'notebook_id': notebookId, 'sender_id': myUserId, 'sender_name': senderName, 'targets': targetUserIds};
    _notebookChannel!.trigger(eventName: 'client-live-invite', data: jsonEncode(data));
    return true;
  }

  Future<bool> broadcastVoiceStateUpdate({
    required int notebookId, 
    required String myUserId, 
    required bool isInCall,
    bool isTalking = false,
    double audioLevel = 0.0,
  }) async {
    if (_notebookChannel == null) return false;
    final data = {
      'sender_id': myUserId, 
      'is_in_call': isInCall,
      'is_talking': isTalking,
      'audio_level': audioLevel,
    };
    _notebookChannel!.trigger(eventName: 'client-voice-state-update', data: jsonEncode(data));
    return true;
  }

  Future<bool> broadcastSessionMeta({required int notebookId, required Map<String, dynamic> metaData}) async {
    if (_notebookChannel == null) return false;
    _notebookChannel!.trigger(eventName: 'client-session-meta', data: jsonEncode(metaData));
    return true;
  }

  Future<bool> broadcastUserActivity({required int notebookId, required String myUserId, required String activity}) async {
    if (_notebookChannel == null) return false;
    final data = {'sender_id': myUserId, 'activity': activity};
    _notebookChannel!.trigger(eventName: 'client-user-activity', data: jsonEncode(data));
    return true;
  }

  Future<bool> broadcastPointerMove({required int notebookId, required String myUserId, required Offset pos, int? pageNumber}) async {
    if (_notebookChannel == null) return false;
    final data = {
      'sender_id': myUserId, 
      'x': double.parse(pos.dx.toStringAsFixed(1)), 
      'y': double.parse(pos.dy.toStringAsFixed(1)),
      'page_number': pageNumber,
    };
    _notebookChannel!.trigger(eventName: 'client-pointer-move', data: jsonEncode(data));
    return true;
  }

  Future<bool> broadcastChatMessage({required int notebookId, required String myUserId, required String message}) async {
    if (_notebookChannel == null) return false;
    final data = {
      'msg_id': const Uuid().v4(),
      'type': 'text',
      'sender_id': myUserId, 
      'message': message, 
      'timestamp': DateTime.now().toIso8601String()
    };
    _notebookChannel!.trigger(eventName: 'client-chat-message', data: jsonEncode(data));
    return true;
  }

  Future<bool> broadcastAudioMessage({
    required int notebookId, 
    required String myUserId, 
    required String audioUrl, 
    required int duration, 
    bool isLive = false,
    String? streamMsgId,
    int? segmentIndex,
    bool? isFinal,
  }) async {
    if (_notebookChannel == null) return false;
    final data = {
      'msg_id': streamMsgId ?? const Uuid().v4(),
      'type': isLive ? 'audio_stream' : 'audio',
      'sender_id': myUserId, 
      'audio_url': audioUrl, 
      'duration': duration, 
      'is_live': isLive,
      'index': segmentIndex,
      'is_final': isFinal,
      'timestamp': DateTime.now().toIso8601String()
    };
    _notebookChannel!.trigger(eventName: 'client-audio-message', data: jsonEncode(data));
    return true;
  }

  Future<void> requestChatSync({required String myUserId}) async {
    if (_notebookChannel == null) return;
    final data = {'sender_id': myUserId};
    _notebookChannel!.trigger(eventName: 'client-chat-sync-request', data: jsonEncode(data));
  }

  Future<void> sendChatSyncResponse({required String targetUserId, required List<Map<String, dynamic>> history}) async {
    if (_notebookChannel == null) return;
    final data = {
      'target_id': targetUserId,
      'history': history,
    };
    _notebookChannel!.trigger(eventName: 'client-chat-sync-response', data: jsonEncode(data));
  }

  Future<void> requestCollectiveSync({required String myUserId}) async {
    if (_notebookChannel == null) return;
    final data = {'sender_id': myUserId};
    _notebookChannel!.trigger(eventName: 'client-collective-sync', data: jsonEncode(data));
  }

  Future<void> requestFullState({required int notebookId, required String targetUserId, required int pageNumber}) async {
    if (_notebookChannel == null) return;
    final data = {
      'sender_id': targetUserId, // Quem está a pedir
      'target_id': targetUserId, // Resiliência
      'page_number': pageNumber,
    };
    _notebookChannel!.trigger(eventName: 'client-full-state-request', data: jsonEncode(data));
  }

  Future<void> deliverFullState({required int notebookId, required String targetUserId, required Map<String, dynamic> pageData}) async {
    if (_notebookChannel == null) return;
    final data = {
      'target_id': targetUserId,
      'page_data': pageData,
    };
    _notebookChannel!.trigger(eventName: 'client-full-state-deliver', data: jsonEncode(data));
  }

  Future<void> broadcastPageFingerprint({required int notebookId, required String myUserId, required int pageNumber, required String fingerprint, int? updatedAt}) async {
    if (_notebookChannel == null) return;
    final data = {
      'sender_id': myUserId,
      'page_number': pageNumber,
      'fingerprint': fingerprint,
      'updated_at': updatedAt, // 🚀 Para eleição de fonte
    };
    _notebookChannel!.trigger(eventName: 'client-page-fingerprint', data: jsonEncode(data));
  }

  Future<void> broadcastCloudSyncSignal({required int notebookId, required String myUserId, required int pageNumber}) async {
    if (_notebookChannel == null) return;
    final data = {
      'sender_id': myUserId,
      'page_number': pageNumber,
    };
    _notebookChannel!.trigger(eventName: 'client-cloud-sync-signal', data: jsonEncode(data));
  }

  Future<void> broadcastGlobalAction({required int notebookId, required Map<String, dynamic> actionData}) async {
    if (_notebookChannel == null) return;
    _notebookChannel!.trigger(eventName: 'client-global-action', data: jsonEncode(actionData));
  }

  Future<void> broadcastSyncPushFinished({required int notebookId, required String myUserId}) async {
    if (_notebookChannel == null) return;
    final data = {'sender_id': myUserId};
    _notebookChannel!.trigger(eventName: 'client-sync-push-finished', data: jsonEncode(data));
  }

  Future<bool> broadcastReaction({required int notebookId, required String myUserId, required String reaction}) async {
    if (_notebookChannel == null) return false;
    final data = {'sender_id': myUserId, 'reaction': reaction};
    _notebookChannel!.trigger(eventName: 'client-reaction', data: jsonEncode(data));
    return true;
  }

  void _broadcastUsersList() {
    _usersStreamController.add(_estudantesNaSala.values.toList());
  }

  List<Map<String, dynamic>> getConnectedUsers() {
    return _estudantesNaSala.values.map((v) => Map<String, dynamic>.from(v)).toList();
  }

  void leaveNotebookChannel(int notebookId) {
    debugPrint('🚪 [Realtime] A sair da sala do caderno $notebookId');
    _subSucceededSub?.cancel();
    _memberAddedSub?.cancel();
    _memberRemovedSub?.cancel();
    _notebookChannel?.unsubscribe();
    _notebookChannel = null;
    _boundEvents.clear(); 
    _estudantesNaSala.clear();
    _usersStreamController.add([]); 
  }

  void disconnect() {
    _pusher?.disconnect();
    statusNotifier.value = RealtimeStatus.disconnected;
  }

  Future<void> listenToUserAccount(int userId, Function onGlobalSyncNeeded) async {
    if (_pusher == null) await initConnection();
    if (_pusher == null) return;
    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('sanctum_token');
    final channelName = 'private-user.$userId';
    final authDelegate = EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
      authorizationEndpoint: Uri.parse(ApiConfig.authEndpoint),
      headers: {'Authorization': 'Bearer $token', 'Accept': 'application/json'},
    );
    _userChannel = _pusher!.privateChannel(channelName, authorizationDelegate: authDelegate);
    _userChannel!.bind('SyncRequested').listen((event) => onGlobalSyncNeeded());
    _rebindGlobalListeners(userId);
    _userChannel!.subscribe();
  }

  void _rebindGlobalListeners(int userId) {
    if (_userChannel == null) return;
    _userChannel!.bind('LiveSessionInvite').listen((event) {
      _inviteStreamController.add(_safeParse(event.data));
    });
    
    // 🚀 OUVIR REVOGAÇÃO DE ACESSO
    _userChannel!.bind('notebook.access_revoked').listen((event) {
      debugPrint('🚨 [Realtime] Acesso revogado recebido via canal privado!');
      _notebookAccessRevokedController.add(_safeParse(event.data));
    });
  }

  void updateUserTalkingState(String userId, bool isTalking) {
    if (_estudantesNaSala.containsKey(userId)) {
      if (_estudantesNaSala[userId]['isTalking'] != isTalking) {
        _estudantesNaSala[userId]['isTalking'] = isTalking;
        _broadcastUsersList();
      }
    }
  }

  void updateUserActivityState(String userId, String activity) {
    if (_estudantesNaSala.containsKey(userId)) {
      if (_estudantesNaSala[userId]['activity'] != activity) {
        _estudantesNaSala[userId]['activity'] = activity;
        _broadcastUsersList();
      }
    }
  }

  void updateUserHandState(String userId, bool isRaised) {
    if (_estudantesNaSala.containsKey(userId)) {
      if (_estudantesNaSala[userId]['isHandRaised'] != isRaised) {
        _estudantesNaSala[userId]['isHandRaised'] = isRaised;
        _broadcastUsersList();
      }
    }
  }
}

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService();
});
