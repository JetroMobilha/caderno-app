import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:shared_preferences/shared_preferences.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  PusherChannelsClient? _pusher;
  PresenceChannel? _notebookChannel;
  StreamSubscription? _eventSubscription;
  bool _isConnected = false;

  // 🚀 INICIALIZAR LIGAÇÃO UNIVERSAL (WIN, WEB, ANDROID, IOS)
  Future<void> initConnection() async {
    if (_isConnected) return;

    // 1. Configurar opções com protocolo WebSocket puro para o Apache/Reverb
    final options = PusherChannelsOptions.fromHost(
      scheme: 'ws', // Usa 'wss' quando tiver HTTPS no servidor
      host: '35.205.132.251',
      port: 6001,
      key: '6572db37e0db7615a423',
    );

    // 2. Inicializar o cliente
    _pusher = PusherChannelsClient.websocket(
      options: options,
      connectionErrorHandler: (exception, trace, refresh) {
        debugPrint('⚠️ [Reverb Erro]: $exception');
        refresh(); // Tenta reconectar automaticamente
      },
    );

    try {
      _pusher!.connect();
      _isConnected = true;
      debugPrint('⚡ [Reverb] Motor Pure Dart ligado a 35.205.132.251:8080!');
    } catch (e) {
      debugPrint('❌ Erro crítico de rede: $e');
    }
  }

  // 🚀 ENTRAR NA SALA DE DESENHO (Presence Channel)
  Future<void> joinNotebookChannel({
    required int notebookId,
    required Function(Map<String, dynamic>) onStrokeReceived,
    required Function(List<dynamic>) onUsersUpdated,
  }) async {
    if (_pusher == null) return;

    final prefs = await SharedPreferences.getInstance();
    final String? token = prefs.getString('sanctum_token');

    if (token == null) {
      debugPrint('❌ Erro: Token Sanctum não encontrado para entrar na sala.');
      return;
    }

    final channelName = 'presence-notebook.$notebookId';
    debugPrint('📡 A pedir autorização ao Sanctum: $channelName');

    // 3. Autorizador Nativo (Pede o passe de entrada ao Laravel)
    final authDelegate = EndpointAuthorizableChannelTokenAuthorizationDelegate.forPresenceChannel(
      authorizationEndpoint: Uri.parse('http://35.205.132.251:8080/api/broadcasting/auth'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      },
    );

    // 4. Criar e subscrever à sala
    _notebookChannel = _pusher!.presenceChannel(
      channelName,
      authorizationDelegate: authDelegate,
    );

    _notebookChannel!.subscribeIfNotUnsubscribed();

    // 5. O Ouvinte Inteligente (A Mágica da Colaboração)
    // 5. O Ouvinte Inteligente (A Mágica da Colaboração)

    // A) Escutar Sucesso de Entrada na Sala
    _notebookChannel!.bind('pusher_internal:subscription_succeeded').listen((event) {
      debugPrint('🟢 Autorizado! A tua aplicação está na sala.');
      final data = jsonDecode(event.data);
      if (data['presence'] != null && data['presence']['hash'] != null) {
        final users = data['presence']['hash'].values.toList();
        onUsersUpdated(users);
      }
    });

    // B) Escutar Alguém a Entrar na Sala
    _notebookChannel!.bind('pusher_internal:member_added').listen((event) {
      debugPrint('👥 Um colega acabou de entrar!');
      // onUsersUpdated(...); // Pode atualizar a UI se desejar
    });

    // C) 🎨 Tinta na tela! Escutar o evento do Laravel
    // No Dart Pusher, ouvimos diretamente o nome exato do evento.
    // Tentamos ouvir a versão com e sem ponto para garantir compatibilidade.

    void handleStrokeEvent(ChannelReadEvent event) {
      debugPrint('🎨 [Tempo Real] Recebemos Tinta: ${event.data}');
      final data = jsonDecode(event.data);
      onStrokeReceived(data);
    }

    _notebookChannel!.bind('page.strokes.added').listen(handleStrokeEvent);
    _notebookChannel!.bind('.page.strokes.added').listen(handleStrokeEvent);
  }

  // 🚀 SAIR DA SALA E POUPAR BATERIA / MEMÓRIA
  void leaveNotebookChannel(int notebookId) {
    _eventSubscription?.cancel();
    _notebookChannel?.unsubscribe();
    debugPrint('🔌 Saímos ordenadamente da sala do caderno $notebookId.');
  }

  void disconnect() {
    _pusher?.disconnect();
    _isConnected = false;
  }
}