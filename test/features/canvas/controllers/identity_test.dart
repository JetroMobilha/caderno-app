import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:caderno_digital_app/features/canvas/controllers/canvas_controller.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/models/image_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/canvas_action_model.dart';
import 'package:caderno_digital_app/core/network/realtime_service.dart';

import 'canvas_controller_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Mocks para plugins nativos
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers'), (message) async => null);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('xyz.luan/audioplayers.global'), (message) async => null);
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'), (message) async => '.');

  late CanvasController controller;
  late MockCanvasRepository mockRepo;
  late MockRealtimeService mockRealtime;

  setUp(() {
    mockRepo = MockCanvasRepository();
    mockRealtime = MockRealtimeService();
    when(mockRealtime.onUsersUpdated).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.statusNotifier).thenReturn(ValueNotifier(RealtimeStatus.disconnected));

    controller = CanvasController(mockRealtime, repository: mockRepo);
    controller.currentUserRole = 'owner';
  });

  group('Page Identity Resilience', () {
    test('Eraser should target the correct page CID even if page numbers are duplicated', () async {
      // 1. Criar duas páginas com o MESMO número (Simulando erro de sync ou race condition)
      final p1 = LocalPage(clientId: 'cid-1', notebookId: 1, pageNumber: 1, isLandscape: false);
      final p2 = LocalPage(clientId: 'cid-2', notebookId: 1, pageNumber: 1, isLandscape: false);
      
      final imgP1 = ImageBlock(id: 'img1', imagePath: 'p1.png', position: const Offset(10, 10));
      final imgP2 = ImageBlock(id: 'img2', imagePath: 'p2.png', position: const Offset(10, 10));
      
      p1.imageBlocks.add(imgP1);
      p2.imageBlocks.add(imgP2);
      
      controller.pages = [p1, p2];

      // 2. Ação: Apagar na "segunda" página (que tem cid-2 e pageNumber 1)
      controller.eraseAtPosition(const Offset(15, 15), p2);

      // 3. Verificar: Apenas o item da cid-2 deve estar apagado
      expect(p2.imageBlocks.first.isDeleted, true, reason: 'Item na página alvo (cid-2) devia sumir');
      expect(p1.imageBlocks.first.isDeleted, false, reason: 'Item na página 1 (mesmo número) não devia ser afetado');
      
      // Verificar que o controlador encontrou a página correta via CID
      expect(p2.version, 2);
      expect(p1.version, 1);
    });
  });
}
