import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();
  PrivateChannel? _userChannel;
  PusherChannelsClient? _pusher;
  PresenceChannel? _notebookChannel;
  bool _isConnected = false;
  final Map<String, dynamic> _estudantesNaSala = {};

  // 📡 AS NOSSAS ANTENAS DE RÁDIO (Streams Broadcast)
  final _strokeStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _usersStreamController = StreamController<List<dynamic>>.broadcast();

  Stream<Map<String, dynamic>> get onStrokeReceived => _strokeStreamController.stream;
  Stream<List<dynamic>> get onUsersUpdated => _usersStreamController.stream;

  bool get isConnected => _isConnected;

  final _webrtcStreamController = StreamController<Map<String, dynamic>>.broadcast();
  Stream<Map<String, dynamic>> get onWebRTCSignalReceived => _webrtcStreamController.stream;

  // =========================================================================
  // 🔌 1. INICIAR CONEXÃO WEBSOCKET (Laravel Reverb / Pusher)
  // =========================================================================
  Future<void> initConnection() async {
    if (_isConnected && _pusher != null) return;

    final options = PusherChannelsOptions.fromHost(
      scheme: 'ws',
      host: '35.205.132.251',
      key: '6572db37e0db7615a423',
      port: 6001,
      shouldSupplyMetadataQueries: true,
      metadata: const PusherChannelsOptionsMetadata(client: 'dart', version: '1.3.1', protocol: 7),
    );

    _pusher = PusherChannelsClient.websocket(
      options: options,
      connectionErrorHandler: (exception, trace, refresh) {
        debugPrint('⚠️ [Realtime] Erro na conexão, a tentar reconectar...');
        refresh();
      },
    );

    try {
      _pusher!.connect();
      _isConnected = true;
      debugPrint('✅ [Realtime] Conectado com sucesso ao servidor Reverb!');
    } catch (e) {
      debugPrint('❌ [Realtime] Erro de rede Reverb: $e');
    }
  }

  // =========================================================================
  // 📡 2. ENTRAR NA SALA DO CADERNO (Presence Channel via Sanctum)
  // =========================================================================
  Future<void> joinNotebookChannel({required int notebookId}) async {
    if (_pusher == null) await initConnection();
    if (_pusher == null) return;

    // Se já estava num canal anterior, sai primeiro para não sobrepor áudios/tintas
    if (_notebookChannel != null) {
      _notebookChannel!.unsubscribe();
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

    // 👥 Quando a subscrição tem sucesso (Carrega a lista inicial dos colegas presentes)
    _notebookChannel!.whenSubscriptionSucceeded().listen((event) {
      final payload = jsonDecode(event.data);
      if (payload['presence'] != null && payload['presence']['hash'] != null) {
        _estudantesNaSala.clear();
        _estudantesNaSala.addAll(Map<String, dynamic>.from(payload['presence']['hash']));
        _usersStreamController.add(_estudantesNaSala.values.toList()); // 📢 Dispara na Stream
        debugPrint('👥 [Realtime] Sucesso! Estão ${_estudantesNaSala.length} pessoa(s) nesta sala.');
      }
    });

    // ➕ Quando um colega entra na sala
    _notebookChannel!.whenMemberAdded().listen((event) {
      final payload = jsonDecode(event.data);
      _estudantesNaSala[payload['user_id'].toString()] = payload['user_info'];
      _usersStreamController.add(_estudantesNaSala.values.toList());
      debugPrint('🟢 [Realtime] Entrou um colega! ID: ${payload['user_id']}');
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
      if (event.data != null) {
        final rawData = event.data;
        Map<String, dynamic> parsedData = rawData is Map
            ? Map<String, dynamic>.from(rawData)
            : jsonDecode(rawData.toString());

        _strokeStreamController.add(parsedData); // 📢 Dispara a tinta para o CanvasController
      }
    });

    _notebookChannel!.bind('client-webrtc-signal').listen((event) {
      if (event.data != null) {
        final data = event.data is Map ? Map<String, dynamic>.from(event.data) : jsonDecode(event.data.toString());
        _webrtcStreamController.add(data);
      }
    });

    _notebookChannel!.subscribe();
  }

  void sendWebRTCSignal(int notebookId, Map<String, dynamic> signalData) {
    _notebookChannel?.trigger(eventName: 'client-webrtc-signal', data: jsonEncode(signalData));
  }

  // =========================================================================
  // 🛫 3. DISPARAR TRAÇO PARA OS COLEGAS (Broadcast P2P)
  // =========================================================================
  Future<bool> broadcastStroke({required int notebookId, required Map<String, dynamic> strokeData}) async {
    if (_notebookChannel == null) return false;
    try {
      _notebookChannel!.trigger(eventName: 'client-ink-stroke', data: jsonEncode(strokeData));
      return true;
    } catch (e) {
      debugPrint('🚨 [Realtime] Falha ao disparar traço via Reverb: $e');
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
    _isConnected = false;
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
}