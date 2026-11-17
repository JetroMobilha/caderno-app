import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:caderno_digital_app/features/canvas/services/ptt_walkie_talkie_service.dart';
import 'package:caderno_digital_app/core/network/realtime_service.dart';

/// FakeRealtimeService para simular a camada de transporte WebSocket em testes
class FakeRealtimeService extends Fake implements RealtimeService {
  final channelLockedController = StreamController<Map<String, dynamic>>.broadcast();
  final audioChunkController = StreamController<Map<String, dynamic>>.broadcast();
  final channelUnlockedController = StreamController<Map<String, dynamic>>.broadcast();

  final List<Map<String, dynamic>> broadcastedLockedEvents = [];
  final List<Map<String, dynamic>> broadcastedChunkEvents = [];
  final List<Map<String, dynamic>> broadcastedUnlockedEvents = [];

  @override
  Stream<Map<String, dynamic>> get onChannelLocked => channelLockedController.stream;

  @override
  Stream<Map<String, dynamic>> get onAudioChunk => audioChunkController.stream;

  @override
  Stream<Map<String, dynamic>> get onChannelUnlocked => channelUnlockedController.stream;

  @override
  Future<bool> broadcastChannelLocked({
    required int notebookId,
    required String userId,
    required String userName,
    required int timestamp,
  }) async {
    broadcastedLockedEvents.add({
      'notebook_id': notebookId,
      'user_id': userId,
      'user_name': userName,
      'timestamp': timestamp,
    });
    return true;
  }

  @override
  Future<bool> broadcastAudioChunk({
    required int notebookId,
    required String userId,
    required int sequence,
    required String base64Data,
  }) async {
    broadcastedChunkEvents.add({
      'notebook_id': notebookId,
      'user_id': userId,
      'sequence': sequence,
      'data': base64Data,
    });
    return true;
  }

  @override
  Future<bool> broadcastChannelUnlocked({
    required int notebookId,
    required String userId,
  }) async {
    broadcastedUnlockedEvents.add({
      'notebook_id': notebookId,
      'user_id': userId,
    });
    return true;
  }

  void dispose() {
    channelLockedController.close();
    audioChunkController.close();
    channelUnlockedController.close();
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeRealtimeService fakeRealtime;
  late PttWalkieTalkieService pttService;

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers.global'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('xyz.luan/audioplayers'),
      (MethodCall methodCall) async => null,
    );
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('com.llfbandit.record/messages'),
      (MethodCall methodCall) async => null,
    );

    fakeRealtime = FakeRealtimeService();
    pttService = PttWalkieTalkieService(fakeRealtime);
  });

  tearDown(() {
    pttService.dispose();
    fakeRealtime.dispose();
  });

  group('PttWalkieTalkieService - Testes de Unidade e Lógica de Negócio', () {
    test('1. Estado inicial deve ser livre e sem emissor ativo', () {
      expect(pttService.isChannelBusy, false);
      expect(pttService.isTransmitting, false);
      expect(pttService.activeSpeakerId, null);
      expect(pttService.activeSpeakerName, null);
    });

    test('2. Receber evento client-channel-locked remoto deve ocupar o canal', () async {
      fakeRealtime.channelLockedController.add({
        'user_id': '101',
        'user_name': 'Carlos Silva',
        'timestamp': 1700000000100,
      });

      // Aguardar o evento processar no Stream
      await Future.delayed(const Duration(milliseconds: 50));

      expect(pttService.isChannelBusy, true);
      expect(pttService.activeSpeakerId, '101');
      expect(pttService.activeSpeakerName, 'Carlos Silva');
      expect(pttService.activeLockTimestamp, 1700000000100);
    });

    test('3. Receber client-channel-unlocked deve libertar o canal', () async {
      // Bloquear
      fakeRealtime.channelLockedController.add({
        'user_id': '101',
        'user_name': 'Carlos Silva',
        'timestamp': 1700000000100,
      });
      await Future.delayed(const Duration(milliseconds: 50));
      expect(pttService.isChannelBusy, true);

      // Desbloquear
      fakeRealtime.channelUnlockedController.add({
        'user_id': '101',
      });
      await Future.delayed(const Duration(milliseconds: 50));

      expect(pttService.isChannelBusy, false);
      expect(pttService.activeSpeakerId, null);
      expect(pttService.activeSpeakerName, null);
    });

    test('4. Resolução de Race Condition: O que tiver o timestamp mais antigo ganha', () async {
      // Simular que o utilizador local (ID: 55) iniciou gravação com timestamp 2000
      pttService.isTransmitting = true;
      pttService.isChannelBusy = true;
      pttService.activeSpeakerId = '55';
      pttService.activeSpeakerName = 'Eu';
      pttService.localLockTimestamp = 2000;

      // Evento remoto (ID: 99) chega com timestamp MAIS ANTIGO (1500 < 2000)
      fakeRealtime.channelLockedController.add({
        'user_id': '99',
        'user_name': 'Ana Vencedora',
        'timestamp': 1500,
      });

      await Future.delayed(const Duration(milliseconds: 50));

      // A app local deve cancelar a sua transmissão e ceder a palavra para Ana Vencedora!
      expect(pttService.isTransmitting, false); // Cancelou gravação local
      expect(pttService.isChannelBusy, true);
      expect(pttService.activeSpeakerId, '99');
      expect(pttService.activeSpeakerName, 'Ana Vencedora');
      expect(pttService.activeLockTimestamp, 1500);
    });

    test('5. Resolução de Race Condition: Se a app local for mais antiga, ignora o bloqueio remoto', () async {
      // Simular que o utilizador local (ID: 55) iniciou gravação com timestamp 1000
      pttService.isTransmitting = true;
      pttService.isChannelBusy = true;
      pttService.activeSpeakerId = '55';
      pttService.activeSpeakerName = 'Eu';
      pttService.localLockTimestamp = 1000;

      // Evento remoto (ID: 99) chega com timestamp MAIS RECENTE (1800 > 1000)
      fakeRealtime.channelLockedController.add({
        'user_id': '99',
        'user_name': 'Ana Perdedora',
        'timestamp': 1800,
      });

      await Future.delayed(const Duration(milliseconds: 50));

      // A app local deve MANTER a palavra
      expect(pttService.isTransmitting, true);
      expect(pttService.activeSpeakerId, '55');
      expect(pttService.activeSpeakerName, 'Eu');
    });

    test('6. Receber chunks de áudio em Base64 quando o canal está atribuído ao emissor', () async {
      // Definir emissor
      fakeRealtime.channelLockedController.add({
        'user_id': '101',
        'user_name': 'Carlos Silva',
        'timestamp': 1700000000100,
      });
      await Future.delayed(const Duration(milliseconds: 50));

      final chunkData = base64Encode(Uint8List.fromList([1, 2, 3, 4, 5]));

      // Enviar chunk
      fakeRealtime.audioChunkController.add({
        'user_id': '101',
        'sequence': 1,
        'data': chunkData,
      });
      await Future.delayed(const Duration(milliseconds: 50));

      // Deve aceitar o chunk sem erros
      expect(pttService.isChannelBusy, true);
      expect(pttService.activeSpeakerId, '101');
    });
  });
}
