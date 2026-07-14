import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:dart_pusher_channels/dart_pusher_channels.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class RealtimeService {
  static final RealtimeService _instance = RealtimeService._internal();
  factory RealtimeService() => _instance;
  RealtimeService._internal();

  PusherChannelsClient? _pusher;
  PresenceChannel? _notebookChannel;
  StreamSubscription? _eventSubscription;
  bool _isConnected = false;
  // 🧠 Registo central dos estudantes ativos na sala
  final Map<String, dynamic> _estudantesNaSala = {};

  // 🚀 INICIALIZAR LIGAÇÃO UNIVERSAL (WIN, WEB, ANDROID, IOS)
  Future<void> initConnection() async {
    if (_isConnected) return;

    // 1. Configurar opções com protocolo WebSocket puro para o Apache/Reverb
    final options = PusherChannelsOptions.fromHost(
      scheme: 'ws',
      host: '35.205.132.251',
      key: '6572db37e0db7615a423',
      port: 6001, // 🔌 Força a porta do servidor Reverb aqui
      shouldSupplyMetadataQueries: true,
      metadata: const PusherChannelsOptionsMetadata(
        client: 'dart',
        version: '1.3.1',
        protocol: 7, // 👈 O protocolo oficial que o Laravel Reverb exige para autenticar!
      ),
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
      debugPrint('⚡ [Reverb] Motor Pure Dart ligado a 35.205.132.251:6001!');
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
    final channelName = 'presence-notebook.$notebookId';

// 🕵️ DETETIVE FINAL: Vamos ver o que o Laravel cospe agora com o .env arranjado!
    try {
      debugPrint('🕵️ A testar o canal no Laravel...');
      final authResponse = await http.post(
        Uri.parse('http://35.205.132.251:8080/api/broadcasting/auth'),
        headers: {
          'Authorization': 'Bearer $token',
          'Accept': 'application/json',
        },
        body: {
          'socket_id': '12345.67890',
          'channel_name': channelName,
        },
      );

      debugPrint('🚨 [LARAVEL STATUS CODE]: ${authResponse.statusCode}');
      debugPrint('🚨 [LARAVEL RESPOSTA]: ${authResponse.body}');
    } catch (e) {
      debugPrint('🚨 [ERRO DE REDE HTTP]: $e');
    }
    debugPrint('🛰️ [SOCKET] A iniciar subscrição no canal: $channelName');

    // 1. Criar o autorizador correto do pacote para canais de presença
    final authDelegate = EndpointAuthorizableChannelTokenAuthorizationDelegate.forPresenceChannel(
      // 🎯 Prefixado com /api/ corretamente e a apontar para a porta HTTP 8080
      authorizationEndpoint: Uri.parse('http://35.205.132.251:8080/api/broadcasting/auth'),
      headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',          // 🔥 Obriga o Laravel a responder JSON limpo
        //'Content-Type': 'application/json',
        //'X-Requested-With': 'XMLHttpRequest',  // 🔥 Bypass de segurança do Laravel Sanctum
      },
    );

    // 1. Obter o canal de presença (NÃO SUBSCREVAS AINDA!)
    _notebookChannel = _pusher!.presenceChannel(
      channelName,
      authorizationDelegate: authDelegate,
    );

    // =================================================================
    // 👥 GESTÃO DE PRESENÇA (QUEM ESTÁ NA SALA)
    // =================================================================

    // A) Sucesso Absoluto (Lê todos os que já lá estavam)
    _notebookChannel!.whenSubscriptionSucceeded().listen((event) {
      debugPrint('🟢 [SOCKET] Ligação autorizada pelo Reverb!');
      try {
        final Map<String, dynamic> payload = jsonDecode(event.data);
        if (payload['presence'] != null && payload['presence']['hash'] != null) {
          final Map<String, dynamic> hash = Map<String, dynamic>.from(payload['presence']['hash']);

          _estudantesNaSala.clear(); // Limpa resíduos de sessões anteriores
          _estudantesNaSala.addAll(hash); // Guarda todos no registo local

          // Dispara a lista completa para a UI desenhar
          onUsersUpdated(_estudantesNaSala.values.toList());
        }
      } catch (e) {
        debugPrint('🚨 Erro ao ler membros iniciais: $e');
      }
    });

    // B) Novo Estudante Entra
    _notebookChannel!.whenMemberAdded().listen((event) {
      debugPrint('➕ [SOCKET] Um novo estudante entrou na sala!');
      try {
        final Map<String, dynamic> payload = jsonDecode(event.data);
        final String userId = payload['user_id'].toString();
        final Map<String, dynamic> userInfo = payload['user_info'];

        // 1. Adiciona o colega ao registo
        _estudantesNaSala[userId] = userInfo;

        // 2. Dispara o refresh tático da UI
        onUsersUpdated(_estudantesNaSala.values.toList());
      } catch (e) {
        debugPrint('🚨 Erro ao processar entrada de membro: $e');
      }
    });

    // C) Estudante Sai da Sala
    _notebookChannel!.whenMemberRemoved().listen((event) {
      debugPrint('➖ [SOCKET] Um estudante saiu da sala.');
      try {
        final Map<String, dynamic> payload = jsonDecode(event.data);
        final String userId = payload['user_id'].toString();

        // 1. Remove o colega do registo
        _estudantesNaSala.remove(userId);

        // 2. Dispara o refresh tático da UI
        onUsersUpdated(_estudantesNaSala.values.toList());
      } catch (e) {
        debugPrint('🚨 Erro ao processar saída de membro: $e');
      }
    });

    // D) Receber Tinta
    _notebookChannel!.bind('client-ink-stroke').listen((event) {
      if (event.data != null) {
        try {
          final rawData = event.data;
          Map<String, dynamic> parsedData;

          // Se por algum motivo o pacote já chegar convertido em Map, usamos direto
          if (rawData is Map) {
            parsedData = Map<String, dynamic>.from(rawData);
          } else {
            // Caso contrário, decodificamos a string JSON limpa
            parsedData = jsonDecode(rawData.toString());
          }

          debugPrint('🎨 [SOCKET] Traço de tinta processado com sucesso!');
          onStrokeReceived(parsedData);
        } catch (e) {
          debugPrint('🚨 Erro ao analisar JSON de tinta recebido: $e');
          debugPrint('   ↳ Conteúdo problemático: ${event.data}');
        }
      }
    });

    // =================================================================
    // 3. AGORA SIM, BATER À PORTA E PEDIR PARA ENTRAR!
    // =================================================================
    debugPrint('⏳ [SOCKET] A pedir autorização à porta 8080...');
    _notebookChannel!.subscribe();
  }

  // =========================================================================
  // 🛫 TRANSMISSÃO DE TRAÇOS (PUSH)
  // =========================================================================
  Future<bool> broadcastStroke({
    required int notebookId,
    required Map<String, dynamic> strokeData,
  }) async {
    // 🛡️ Segurança relacional: Só dispara se o canal estiver ativo e inscrito
    if (_notebookChannel == null) {
      debugPrint('⚠️ [RealtimeService] Erro: Não estás inscrito em nenhum canal para emitir tinta.');
      return false;
    }

    try {
      // 🎯 NO PROTOCOLO PUSHER PURO: Eventos do cliente DEVEM começar com "client-"
      // O método .trigger() envia os dados instantaneamente para o Reverb de Luanda
      _notebookChannel!.trigger(
        eventName: 'client-ink-stroke',
        data: jsonEncode(strokeData),
      );

      debugPrint('📡 [RealtimeService] Tinta ejetada com sucesso para o canal via .trigger()');
      return true;
    } catch (e) {
      debugPrint('❌ Erro crítico ao transmitir tinta via trigger: $e');
      return false;
    }
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