import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:caderno_digital_app/features/canvas/controllers/canvas_controller.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/models/image_block_model.dart';
import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/core/network/sync_service.dart';
import 'package:caderno_digital_app/features/canvas/services/audio_session_service.dart';
import 'package:caderno_digital_app/features/canvas/services/collaboration_room_service.dart';
import 'package:caderno_digital_app/features/canvas/models/stroke_model.dart';
import 'package:caderno_digital_app/core/database/app_database.dart' as db;

import 'canvas_controller_test.mocks.dart';

class MockSyncService extends Mock implements SyncService {
  @override
  Future<void> pullSpecificPage(int notebookServerId, int pageNumber, {String? clientId, bool isRetry = false}) async {}
}

class MockAudioSessionService extends Mock implements AudioSessionService {
  @override List<db.LessonRecording> get lessonRecordings => [];
}

class MockCollaborationRoomService extends Mock implements CollaborationRoomService {
  @override final ValueNotifier<Map<String, dynamic>> remotePointers = ValueNotifier({});
  @override final ValueNotifier<Map<String, Stroke>> remoteLiveStrokes = ValueNotifier({});
  @override final Set<String> usersInLiveSession = {};
  @override final Map<String, double> userAudioLevels = {};
  @override final List<Map<String, dynamic>> onlineUsers = [];
  @override final Map<String, String?> userReactions = {};
  @override final Set<String> whoIsWatchingMe = {};
  @override final Set<String> remoteMovingStrokeIds = {};
  @override final Set<String> tearingPageClientIds = {};
  @override final List<Map<String, dynamic>> chatMessages = [];
  @override final Map<int, String> remoteEditingTitles = {};
  @override final List<Map<String, dynamic>> enrolledMembers = [];
  @override Stream<Map<String, dynamic>> get onNewMessageAlert => const Stream.empty();
  @override Stream<String> get onPermissionAlert => const Stream.empty();
  @override Stream<void> get onNotebookDeletedByOwner => const Stream.empty();
  @override Stream<Map<String, dynamic>> get onSessionMetaReceived => const Stream.empty();
  @override final Map<String, Color> userColorsMap = {};
}

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
    when(mockRealtime.onNotebookStructureUpdated).thenAnswer((_) => const Stream.empty());
    when(mockRealtime.statusNotifier).thenReturn(ValueNotifier(RealtimeStatus.disconnected));

    final mockAudio = MockAudioSessionService();
    final mockCollab = MockCollaborationRoomService();

    controller = CanvasController(mockRealtime, mockSync, mockAudio, mockCollab, repository: mockRepo);
    controller.currentUserRole = 'owner';
  });

  group('Page Identity Resilience', () {
    test('Eraser should target the correct page CID even if page numbers are duplicated', () async {
      final p1 = LocalPage(clientId: 'cid-1', notebookId: 1, pageNumber: 1, isLandscape: false);
      final p2 = LocalPage(clientId: 'cid-2', notebookId: 1, pageNumber: 1, isLandscape: false);
      
      final imgP1 = ImageBlock(id: 'img1', imagePath: 'p1.png', position: const Offset(10, 10));
      final imgP2 = ImageBlock(id: 'img2', imagePath: 'p2.png', position: const Offset(10, 10));
      
      p1.imageBlocks.add(imgP1);
      p2.imageBlocks.add(imgP2);
      controller.pages = [p1, p2];

      controller.eraseAtPosition(const Offset(15, 15), p2);

      expect(p2.imageBlocks.first.isDeleted, true);
      expect(p1.imageBlocks.first.isDeleted, false);
      expect(p2.version, 2);
      expect(p1.version, 1);
    });
  });
}
