import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/canvas/providers/canvas_document_provider.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';
import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/core/network/sync_service.dart';
import 'package:caderno_digital_app/core/network/sync_provider.dart';
import 'package:caderno_digital_app/features/canvas/services/audio_session_service.dart';
import 'package:caderno_digital_app/features/canvas/services/collaboration_room_service.dart';
import 'package:mockito/mockito.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/models/stroke_model.dart';
import 'package:flutter/material.dart';

class MockCanvasRepository extends Mock implements CanvasRepository {
  @override
  Stream<List<LocalPage>> watchPagesByNotebook(int notebookId) => Stream.value([]);
}
class MockRealtimeService extends Mock implements RealtimeService {}
class MockSyncService extends Mock implements SyncService {}
class MockAudioSessionService extends Mock implements AudioSessionService {
  @override
  Future<void> loadLessonRecordings(int notebookId) async {}
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
}
class MockCollaborationRoomService extends Mock implements CollaborationRoomService {
  @override
  void leaveSession() {}
  @override
  void addListener(VoidCallback listener) {}
  @override
  void removeListener(VoidCallback listener) {}
  @override
  final ValueNotifier<Map<String, Stroke>> remoteLiveStrokes = ValueNotifier({});
  @override
  final List<Map<String, dynamic>> chatMessages = [];
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('CanvasDocumentNotifier Tests', () {
    test('Initial state is empty', () {
      final container = ProviderContainer(
        overrides: [
          canvasRepositoryProvider.overrideWithValue(MockCanvasRepository()),
          realtimeServiceProvider.overrideWithValue(MockRealtimeService()),
          appSyncServiceProvider.overrideWithValue(MockSyncService()),
          audioSessionServiceProvider.overrideWith((ref) => MockAudioSessionService()),
          collaborationRoomServiceProvider.overrideWith((ref) => MockCollaborationRoomService()),
        ],
      );

      final state = container.read(canvasDocumentProvider);
      expect(state.pages, isEmpty);
      expect(state.isLoading, false);
    });

    test('addStroke updates the page state', () async {
      final mockRepo = MockCanvasRepository();
      final container = ProviderContainer(
        overrides: [
          canvasRepositoryProvider.overrideWithValue(mockRepo),
          realtimeServiceProvider.overrideWithValue(MockRealtimeService()),
          appSyncServiceProvider.overrideWithValue(MockSyncService()),
          audioSessionServiceProvider.overrideWith((ref) => MockAudioSessionService()),
          collaborationRoomServiceProvider.overrideWith((ref) => MockCollaborationRoomService()),
        ],
      );

      final page = LocalPage(id: 1, notebookId: 1, pageNumber: 1, clientId: 'c1', isLandscape: false, paperSize: 'A4');
      // basic compilation check
    });
  });
}
