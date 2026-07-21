import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum RealtimeStatus { disconnected, connecting, connected, error }

class RealtimeService {
  PrivateChannel? _userChannel;
  PusherChannelsClient? _pusher;
  PresenceChannel? _notebookChannel;
  
  final ValueNotifier<RealtimeStatus> statusNotifier = ValueNotifier(RealtimeStatus.disconnected);
  final Map<String, dynamic> _estudantesNaSala = {};

  // 📡 AS NOSSAS ANTENAS DE RÁDIO (Streams Broadcast)
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

  bool get isConnected => statusNotifier.value == RealtimeStatus.connected;

  final _webrtcStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onWebRTCSignalReceived => _webrtcStreamController.stream;

  // =========================================================================
  // 🔌 1. INICIAR CONEXÃO WEBSOCKET (Laravel Reverb / Pusher)
  // =========================================================================
  Future<void> initConnection() async {
    if (statusNotifier.value == RealtimeStatus.connected && _pusher != null) return;

    statusNotifier.value = RealtimeStatus.connecting;

    final options = PusherChannelsOptions.fromHost(
      scheme: 'ws',
      host: '35.205.132.251',
      key: '6572db37e0db7615a423',
      port: 6001, // 🚀 Porta WS do Reverb
      shouldSupplyMetadataQueries: true,
      metadata: const PusherChannelsOptionsMetadata(client: 'dart', version: '1.3.1', protocol: 7),
    );

    _pusher = PusherChannelsClient.websocket(
      options: options,
      connectionErrorHandler: (exception, trace, refresh) async {
        debugPrint('⚠️ [Realtime] Erro na conexão: $exception');
        statusNotifier.value = RealtimeStatus.error;
        
        // 🚀 ABRADAMENTO: Esperar 5s antes de tentar de novo para não travar a CPU
        await Future.delayed(const Duration(seconds: 5));
        refresh();
      },
    );

    // 🚀 ESCUTAR ESTADO REAL DO SOCKET
    _pusher!.lifecycleStream.listen((state) {
      debugPrint('📡 [Realtime] Estado do Socket: $state');
      
      if (state == PusherChannelsClientLifeCycleState.establishedConnection) {
        statusNotifier.value = RealtimeStatus.connected;
      } else if (state == PusherChannelsClientLifeCycleState.pendingConnection) {
        statusNotifier.value = RealtimeStatus.connecting;
      } else if (state == PusherChannelsClientLifeCycleState.disconnected) {
        statusNotifier.value = RealtimeStatus.disconnected;
      } else if (state == PusherChannelsClientLifeCycleState.reconnecting) {
        statusNotifier.value = RealtimeStatus.connecting;
      } else if (state == PusherChannelsClientLifeCycleState.connectionError || 
                 state == PusherChannelsClientLifeCycleState.gotPusherError) {
        statusNotifier.value = RealtimeStatus.error;
      }
    });

    try {
      _pusher!.connect();
    } catch (e) {
      statusNotifier.value = RealtimeStatus.error;
      debugPrint('❌ [Realtime] Falha ao ligar Reverb: $e');
    }
  }

  // =========================================================================
  // 📡 2. ENTRAR NA SALA DO CADERNO (Presence Channel via Sanctum)
  // =========================================================================
  Future<void> joinNotebookChannel({required int notebookId}) async {
    if (statusNotifier.value != RealtimeStatus.connected) {
      await initConnection();
    }
    
    // ⏳ AGUARDAR ATÉ ESTAR LIGADO (Máximo 10s)
    int attempts = 0;
    while (statusNotifier.value != RealtimeStatus.connected && attempts < 20) {
      await Future.delayed(const Duration(milliseconds: 500));
      attempts++;
    }

    if (statusNotifier.value != RealtimeStatus.connected) {
      debugPrint('🚨 [Realtime] Impossível entrar no canal: Socket não ligou a tempo.');
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('sanctum_token');
    final channelName = 'presence-notebook.$notebookId';

    debugPrint('📡 [Realtime] A tentar autenticar e subscrever na sala: $channelName');

    final authDelegate = EndpointAuthorizableChannelTokenAuthorizationDelegate.forPresenceChannel(
      authorizationEndpoint: Uri.parse('http://35.205.132.251:8080/api/broadcasting/auth'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    _notebookChannel = _pusher!.presenceChannel(channelName, authorizationDelegate: authDelegate);

    // 👥 Quando a subscrição tem sucesso
    _notebookChannel!.whenSubscriptionSucceeded().listen((event) {
      final payload = jsonDecode(event.data);
      
      if (payload['presence'] != null && payload['presence']['hash'] != null) {
        _estudantesNaSala.clear();
        final hash = Map<String, dynamic>.from(payload['presence']['hash']);
        hash.forEach((uid, info) {
          final infoMap = Map<String, dynamic>.from(info);
          infoMap['id'] = uid; 
          _estudantesNaSala[uid.toString()] = infoMap;
        });
        _usersStreamController.add(_estudantesNaSala.values.toList());
      }
    });

    // ➕ Quando um colega entra na sala
    _notebookChannel!.whenMemberAdded().listen((event) {
      final payload = jsonDecode(event.data);
      final info = Map<String, dynamic>.from(payload['user_info']);
      final String uid = payload['user_id'].toString();
      info['id'] = uid; // 🚀 Garante que o ID do servidor está no mapa
      _estudantesNaSala[uid] = info;
      _usersStreamController.add(_estudantesNaSala.values.toList());
      debugPrint('🟢 [Realtime] Entrou o colega $uid');
    });

    // ➖ Quando um colega sai ou fecha a App
    _notebookChannel!.whenMemberRemoved().listen((event) {
      final payload = jsonDecode(event.data);
      _estudantesNaSala.remove(payload['user_id'].toString());
      _usersStreamController.add(_estudantesNaSala.values.toList());
      debugPrint('🔴 [Realtime] Um colega saiu! ID: ${payload['user_id']}');
    });

    // 🎨 Quando um colega desenha um traço na tela!
    _notebookChannel!.bind('client-ink-stroke').listen((event) {
      debugPrint('📡 [WebSocket] Evento recebido: client-ink-stroke');
      if (event.data != null) {
        final rawData = event.data;
        Map<String, dynamic> parsedData = rawData is Map ? Map<String, dynamic>.from(rawData) : jsonDecode(rawData.toString());
        _strokeStreamController.add(parsedData);
      }
    });

    // 📝 Quando um colega mexe num bloco de texto!
    _notebookChannel!.bind('client-text-block').listen((event) {
      debugPrint('📡 [WebSocket] Evento recebido: client-text-block');
      if (event.data != null) {
        final rawData = event.data;
        Map<String, dynamic> parsedData = rawData is Map ? Map<String, dynamic>.from(rawData) : jsonDecode(rawData.toString());
        _textStreamController.add(parsedData);
      }
    });

    // 🖼️ Quando um colega mexe numa imagem!
    _notebookChannel!.bind('client-image-block').listen((event) {
      debugPrint('📡 [WebSocket] Evento recebido: client-image-block');
      if (event.data != null) {
        final rawData = event.data;
        Map<String, dynamic> parsedData = rawData is Map ? Map<String, dynamic>.from(rawData) : jsonDecode(rawData.toString());
        _imageStreamController.add(parsedData);
      }
    });

    // 🔭 Quando um colega mexe na câmara (Viewport Sync)!
    _notebookChannel!.bind('client-viewport-sync').listen((event) {
      // Log omitido para evitar spam no console (ocorre a cada 80ms)
      if (event.data != null) {
        final rawData = event.data;
        Map<String, dynamic> parsedData = rawData is Map ? Map<String, dynamic>.from(rawData) : jsonDecode(rawData.toString());
        _viewportStreamController.add(parsedData);
      }
    });

    // 👥 Quando alguém começa ou para de seguir alguém!
    _notebookChannel!.bind('client-follow-update').listen((event) {
      debugPrint('📡 [WebSocket] Evento recebido: client-follow-update');
      if (event.data != null) {
        final rawData = event.data;
        Map<String, dynamic> parsedData = rawData is Map ? Map<String, dynamic>.from(rawData) : jsonDecode(rawData.toString());
        _followStreamController.add(parsedData);
      }
    });

    // 📄 Quando alguém adiciona ou remove uma página!
    _notebookChannel!.bind('client-page-event').listen((event) {
      debugPrint('📡 [WebSocket] Evento recebido: client-page-event');
      if (event.data != null) {
        final rawData = event.data;
        Map<String, dynamic> parsedData = rawData is Map ? Map<String, dynamic>.from(rawData) : jsonDecode(rawData.toString());
        _pageEventStreamController.add(parsedData);
      }
    });

    // 🏆 SERVER-AUTHORITATIVE: Quando o Laravel confirma o salvamento da página!
    _notebookChannel!.bind('PageUpdated').listen((event) {
      debugPrint('📡 [WebSocket] Evento CRÍTICO recebido: PageUpdated (Confirmação do Servidor)');
      if (event.data != null) {
        final rawData = event.data;
        Map<String, dynamic> parsedData = rawData is Map ? Map<String, dynamic>.from(rawData) : jsonDecode(rawData.toString());
        _pageUpdatedStreamController.add(parsedData);
      }
    });

    _notebookChannel!.bind('client-webrtc-signal').listen((event) {
      if (event.data != null) {
        final data = event.data is Map ? Map<String, dynamic>.from(event.data) : jsonDecode(event.data.toString());
        _webrtcStreamController.add(data);
      }
    });

    _notebookChannel!.bind('client-hand-event').listen((event) {
      if (event.data != null) {
        final data = event.data is Map ? Map<String, dynamic>.from(event.data) : jsonDecode(event.data.toString());
        _handStreamController.add(data);
      }
    });

    _notebookChannel!.bind('client-image-uploading').listen((event) {
      if (event.data != null) {
        final data = event.data is Map ? Map<String, dynamic>.from(event.data) : jsonDecode(event.data.toString());
        _uploadingStreamController.add(data);
      }
    });

    _notebookChannel!.subscribe();
  }

  void sendWebRTCSignal(int notebookId, Map<String, dynamic> signalData) {
    _notebookChannel?.trigger(eventName: 'client-webrtc-signal', data: jsonEncode(signalData));
  }

  // =========================================================================
  // 🛫 3. DISPARAR EVENTOS PARA OS COLEGAS (Broadcast P2P)
  // =========================================================================
  Future<bool> broadcastStroke({required int notebookId, required Map<String, dynamic> strokeData, String? myUserId}) async {
    if (_notebookChannel == null) return false;
    try {
      if (myUserId != null) strokeData['sender_id'] = myUserId;
      _notebookChannel!.trigger(eventName: 'client-ink-stroke', data: jsonEncode(strokeData));
      return true;
    } catch (e) {
      debugPrint('🚨 [Realtime] Falha ao disparar traço: $e');
      return false;
    }
  }

  Future<bool> broadcastTextBlock({required int notebookId, required Map<String, dynamic> textData, String? myUserId}) async {
    if (_notebookChannel == null) return false;
    try {
      if (myUserId != null) textData['sender_id'] = myUserId;
      _notebookChannel!.trigger(eventName: 'client-text-block', data: jsonEncode(textData));
      return true;
    } catch (e) {
      debugPrint('🚨 [Realtime] Falha ao disparar texto: $e');
      return false;
    }
  }

  Future<bool> broadcastImageBlock({required int notebookId, required Map<String, dynamic> imageData, String? myUserId}) async {
    if (_notebookChannel == null) return false;
    try {
      if (myUserId != null) imageData['sender_id'] = myUserId;
      _notebookChannel!.trigger(eventName: 'client-image-block', data: jsonEncode(imageData));
      return true;
    } catch (e) {
      debugPrint('🚨 [Realtime] Falha ao disparar imagem: $e');
      return false;
    }
  }

  Future<bool> broadcastImageUploading({required int notebookId, required String myUserId, required bool isUploading}) async {
    if (_notebookChannel == null) return false;
    try {
      final data = {'sender_id': myUserId, 'is_uploading': isUploading};
      _notebookChannel!.trigger(eventName: 'client-image-uploading', data: jsonEncode(data));
      return true;
    } catch (e) {
      debugPrint('🚨 [Realtime] Falha ao disparar status upload: $e');
      return false;
    }
  }

  Future<bool> broadcastViewport({required int notebookId, required Map<String, dynamic> viewportData, required String myUserId}) async {
    if (_notebookChannel == null) return false;
    try {
      // Adicionamos o ID do autor para os seguidores saberem quem estão a acompanhar
      viewportData['sender_id'] = myUserId;
      _notebookChannel!.trigger(eventName: 'client-viewport-sync', data: jsonEncode(viewportData));
      return true;
    } catch (e) {
      debugPrint('🚨 [Realtime] Falha ao disparar viewport: $e');
      return false;
    }
  }

  Future<bool> broadcastFollowUpdate({required int notebookId, required String myUserId, String? followingUserId}) async {
    if (_notebookChannel == null) return false;
    try {
      final data = {
        'follower_id': myUserId,
        'following_id': followingUserId, // Se for null, parou de seguir
      };
      _notebookChannel!.trigger(eventName: 'client-follow-update', data: jsonEncode(data));
      return true;
    } catch (e) {
      debugPrint('🚨 [Realtime] Falha ao disparar follow update: $e');
      return false;
    }
  }

  Future<bool> broadcastPageEvent({required int notebookId, required Map<String, dynamic> pageData, required String myUserId}) async {
    if (_notebookChannel == null) return false;
    try {
      pageData['sender_id'] = myUserId; // 🚀 Identifica quem causou a mudança
      _notebookChannel!.trigger(eventName: 'client-page-event', data: jsonEncode(pageData));
      return true;
    } catch (e) {
      debugPrint('🚨 [Realtime] Falha ao disparar evento de página: $e');
      return false;
    }
  }

  Future<bool> broadcastHandEvent({required int notebookId, required String myUserId, required bool isRaised}) async {
    if (_notebookChannel == null) return false;
    try {
      final data = {
        'sender_id': myUserId,
        'is_raised': isRaised,
      };
      _notebookChannel!.trigger(eventName: 'client-hand-event', data: jsonEncode(data));
      return true;
    } catch (e) {
      debugPrint('🚨 [Realtime] Falha ao disparar hand event: $e');
      return false;
    }
  }

  // =========================================================================
  // 🚪 4. SAIR DA SALA DO CADERNO
  // =========================================================================
  void leaveNotebookChannel(int notebookId) {
    debugPrint('🚪 [Realtime] A sair da sala do caderno $notebookId');
    _notebookChannel?.unsubscribe();
    _notebookChannel = null;
    _estudantesNaSala.clear();
    _usersStreamController.add([]); // Avisa a UI para limpar a lista de avatares
  }

  // =========================================================================
  // 🛑 5. DESCONECTAR TOTALMENTE
  // =========================================================================
  void disconnect() {
    _pusher?.disconnect();
    statusNotifier.value = RealtimeStatus.disconnected;
  }

  // =========================================================================
  // 📡 6. ESCUTAR ALTERAÇÕES DA PRÓPRIA CONTA (Sincronização Multi-Dispositivo)
  // =========================================================================
  Future<void> listenToUserAccount(int userId, Function onGlobalSyncNeeded) async {
    if (_pusher == null) await initConnection();
    if (_pusher == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('sanctum_token');
    final channelName = 'private-user.$userId';

    final authDelegate = EndpointAuthorizableChannelTokenAuthorizationDelegate.forPrivateChannel(
      authorizationEndpoint: Uri.parse('http://35.205.132.251:8080/api/broadcasting/auth'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    _userChannel = _pusher!.privateChannel(channelName, authorizationDelegate: authDelegate);

    // Quando o Servidor Laravel gritar "A TUA CONTA MUDOU NOURO DISPOSITIVO!"
    _userChannel!.bind('SyncRequested').listen((event) {
      debugPrint('⚡ [Reverb] Sincronização Global Exigida pelo Servidor!');
      onGlobalSyncNeeded(); // Aciona o sync do SubjectsController
    });

    _userChannel!.subscribe();
  }

  // No RealtimeService em Flutter
  void updateUserTalkingState(String userId, bool isTalking) {
    if (_estudantesNaSala.containsKey(userId)) {
      // Só dispara se o estado tiver realmente mudado (para evitar rebuilds desnecessários)
      if (_estudantesNaSala[userId]['isTalking'] != isTalking) {
        _estudantesNaSala[userId]['isTalking'] = isTalking;
        _usersStreamController.add(_estudantesNaSala.values.toList());
      }
    }
  }

  void updateUserHandState(String userId, bool isRaised) {
    if (_estudantesNaSala.containsKey(userId)) {
      if (_estudantesNaSala[userId]['isHandRaised'] != isRaised) {
        _estudantesNaSala[userId]['isHandRaised'] = isRaised;
        _usersStreamController.add(_estudantesNaSala.values.toList());
      }
    }
  }
}

final realtimeServiceProvider = Provider<RealtimeService>((ref) {
  return RealtimeService();
});
