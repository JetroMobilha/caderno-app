import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/services.dart';
import 'package:caderno_digital_app/features/canvas/controllers/canvas_controller.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';
import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/core/network/sync_service.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/models/image_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/stroke_model.dart';
import 'package:caderno_digital_app/features/canvas/models/text_block_model.dart';

import 'canvas_controller_test.mocks.dart';

class MockSyncService extends Mock implements SyncService {
  @override
  Future<void> syncAll({bool forced = false, bool metadataOnly = false}) async {}
  @override
  Future<bool> pushPages({int? onlyNotebookId}) async => true;
  @override
  Future<bool> pullPages({bool forceFull = false, int? onlyNotebookId}) async => true;
  @override
  Future<void> pullSpecificPage(int notebookServerId, int pageNumber, {String? clientId, bool isRetry = false}) async {}
  @override
  Future<bool> fastPushPage(LocalPage page, int notebookServerId, String myUserId) async => true;
  @override
  Future<void> pushOfflineSubjects() async {}
  @override
  Future<void> pushNotebooks() async {}
}

@GenerateMocks([CanvasRepository, RealtimeService])
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
  late MockSyncService mockSync;

  setUp(() {
    mockRepo = MockCanvasRepository();
    mockRealtime = MockRealtimeService();
    mockSync = MockSyncService();
    
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
    when(mockRealtime.onNotebookStructureUpdated).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.statusNotifier).thenReturn(ValueNotifier(RealtimeStatus.disconnected));

    controller = CanvasController(mockRealtime, mockSync, repository: mockRepo);
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

      controller.selectedImageIds.add('img1');
      controller.eraseAtPosition(const Offset(55, 55), p2);

      expect(p2.imageBlocks.first.isDeleted, true);
      expect(p1.imageBlocks.first.isDeleted, false);
    });

    test('Add Page should increment pageNumber correctly', () async {
      final p1 = LocalPage(clientId: 'cid1', notebookId: 1, pageNumber: 1, isLandscape: false);
      controller.pages = [p1];
      await controller.addNewPage(false);
      expect(controller.pages.length, 2);
      expect(controller.pages.last.pageNumber, 2);
    });
  });
}
