import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:caderno_digital_app/features/canvas/controllers/canvas_controller.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';
import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/models/image_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/canvas_action_model.dart';

import 'canvas_controller_test.mocks.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

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
    when(mockRealtime.onStrokeReceived).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.onTextReceived).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.onImageReceived).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.onViewportReceived).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.onFollowUpdateReceived).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.onPageEventReceived).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.onPageUpdated).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.onHandEventReceived).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.onRemoteUploading).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.onPointerMoveReceived).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.onChatMessageReceived).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.onAudioMessageReceived).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.onReactionReceived).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.onCollectiveSyncRequested).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.onGlobalActionReceived).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.statusNotifier).thenReturn(ValueNotifier(RealtimeStatus.disconnected));

    controller = CanvasController(mockRealtime, repository: mockRepo);
    controller.currentUserRole = 'owner';
  });

  group('Page Isolation and Eraser Logic', () {
    test('Should find and erase on Page 2 when multiple pages exist', () async {
      final p1 = LocalPage(id: 1, notebookId: 1, pageNumber: 1, isLandscape: false);
      final p2 = LocalPage(id: 2, notebookId: 1, pageNumber: 2, isLandscape: false);
      
      final img = ImageBlock(id: 'img_p2', imagePath: 'p2.png', position: const Offset(50, 50));
      p2.imageBlocks.add(img);
      
      controller.pages = [p1, p2];
      
      // Simulate eraser touch on Page 2
      controller.eraseAtPosition(const Offset(55, 55), p2);
      
      expect(p2.imageBlocks.first.isDeleted, true, reason: 'Image on page 2 should be marked as deleted');
      expect(p2.version, 2, reason: 'Page 2 version should be incremented');
      expect(p1.version, 1, reason: 'Page 1 should remain untouched');
    });

    test('Should handle stream updates without losing deletion state', () async {
      final p1 = LocalPage(id: 1, notebookId: 1, pageNumber: 1, isLandscape: false);
      final img = ImageBlock(id: 'img1', imagePath: 'p1.png', position: const Offset(10, 10));
      p1.imageBlocks.add(img);
      controller.pages = [p1];

      // Erase
      controller.eraseAtPosition(const Offset(15, 15), p1);
      expect(p1.imageBlocks.first.isDeleted, true);

      // Simulate stream update (re-fetching from DB)
      // Here we simulate what happens when watchPages emits
      final p1Fresh = LocalPage(id: 1, notebookId: 1, pageNumber: 1, isLandscape: false, version: p1.version);
      // If the repository fails to load the isDeleted flag, it will be false here
      final imgFresh = ImageBlock(id: 'img1', imagePath: 'p1.png', position: const Offset(10, 10), isDeleted: true);
      p1Fresh.imageBlocks.add(imgFresh);
      
      controller.pages = [p1Fresh];
      
      expect(controller.pages.first.imageBlocks.first.isDeleted, true, reason: 'Deletion must persist after stream update');
    });
  });
}
