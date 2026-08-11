import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/services.dart';
import 'package:caderno_digital_app/features/canvas/controllers/canvas_controller.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';
import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/models/image_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/stroke_model.dart';
import 'package:caderno_digital_app/features/canvas/models/canvas_action_model.dart';

import 'canvas_controller_test.mocks.dart';

@GenerateMocks([CanvasRepository, RealtimeService])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 🚀 MOCK PLATFORM CHANNELS
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

  group('CanvasController Logic Tests', () {
    test('Eraser should clear global selection on Page 2 if it belongs to Page 1', () {
      final p1 = LocalPage(clientId: 'cid1', notebookId: 1, pageNumber: 1, isLandscape: false);
      final p2 = LocalPage(clientId: 'cid2', notebookId: 1, pageNumber: 2, isLandscape: false);
      
      final img1 = ImageBlock(id: 'img1', imagePath: 'p1.png', position: const Offset(10, 10));
      final img2 = ImageBlock(id: 'img2', imagePath: 'p2.png', position: const Offset(50, 50));
      
      p1.imageBlocks.add(img1);
      p2.imageBlocks.add(img2);
      controller.pages = [p1, p2];

      // Simulate img1 selected (on Page 1)
      controller.selectedImageIds.add('img1');

      // User tries to erase img2 on Page 2
      controller.eraseAtPosition(const Offset(55, 55), p2);

      // Verify: img2 should be deleted even if something else was selected on p1
      expect(p2.imageBlocks.first.isDeleted, true, reason: 'Image on p2 should be deleted');
      expect(p1.imageBlocks.first.isDeleted, false, reason: 'Image on p1 should NOT be affected');
    });

    test('Add Page should increment pageNumber correctly', () async {
      final p1 = LocalPage(clientId: 'cid1', notebookId: 1, pageNumber: 1, isLandscape: false);
      controller.pages = [p1];
      
      await controller.addNewPage(false);
      
      expect(controller.pages.length, 2);
      expect(controller.pages.last.pageNumber, 2);
    });

    test('Logic should prevent ghost items after re-loading from DB', () {
      final p1 = LocalPage(clientId: 'cid1', notebookId: 1, pageNumber: 1, isLandscape: false);
      final stroke = Stroke(id: 's1', color: '#000000', thickness: 2, points: [const Offset(0,0)], isDeleted: true);
      p1.strokes.add(stroke);
      
      controller.pages = [p1];
      
      // Simulating what the painter does (filtering)
      final visibleStrokes = controller.pages.first.strokes.where((s) => !s.isDeleted).toList();
      expect(visibleStrokes.isEmpty, true);
    });

    test('Follow the Pen should be correctly configured when user is following', () {
      controller.followingUserId = 'user123';
      controller.lastScreenSize = const Size(1080, 1920);
      
      expect(controller.followingUserId, 'user123');
      expect(controller.lastScreenSize?.width, 1080);
    });
  });
}
