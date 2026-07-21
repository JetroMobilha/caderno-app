import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:caderno_digital_app/features/canvas/controllers/canvas_controller.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';
import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/core/network/webrtc_service.dart';
import 'package:caderno_digital_app/core/services/ocr_service.dart';
import 'dart:async';
import 'package:flutter/material.dart';

class MockRealtimeService extends Mock implements RealtimeService {
  final _strokeStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _usersStreamController = StreamController<List<dynamic>>.broadcast();
  final _followStreamController = StreamController<Map<String, dynamic>>.broadcast();
  final _handStreamController = StreamController<Map<String, dynamic>>.broadcast();

  @override
  Stream<Map<String, dynamic>> get onStrokeReceived => _strokeStreamController.stream;
  @override
  Stream<List<dynamic>> get onUsersUpdated => _usersStreamController.stream;
  @override
  Stream<Map<String, dynamic>> get onFollowUpdateReceived => _followStreamController.stream;
  @override
  Stream<Map<String, dynamic>> get onHandEventReceived => _handStreamController.stream;
  @override
  Stream<Map<String, dynamic>> get onTextReceived => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get onImageReceived => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get onViewportReceived => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get onPageEventReceived => const Stream.empty();
  @override
  Stream<Map<String, dynamic>> get onPageUpdated => const Stream.empty();

  void emitStroke(Map<String, dynamic> data) => _strokeStreamController.add(data);
  void emitUsers(List<dynamic> users) => _usersStreamController.add(users);
  void emitFollow(Map<String, dynamic> data) => _followStreamController.add(data);
  void emitHand(Map<String, dynamic> data) => _handStreamController.add(data);

  @override
  Future<void> initConnection() async {}
  @override
  Future<void> joinNotebookChannel({required int notebookId}) async {}
  @override
  void updateUserHandState(String userId, bool isRaised) {}
  @override
  Future<bool> broadcastHandEvent({required int notebookId, required String myUserId, required bool isRaised}) async => true;
}

class MockWebRTCService extends Mock implements WebRTCService {
  @override
  void leaveVoiceRoom() {}
}

class MockCanvasRepository extends Mock implements CanvasRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  late CanvasController controller;
  late MockRealtimeService mockRealtime;
  late MockWebRTCService mockWebRTC;
  late MockCanvasRepository mockRepo;

  setUp(() {
    mockRealtime = MockRealtimeService();
    mockWebRTC = MockWebRTCService();
    mockRepo = MockCanvasRepository();
    controller = CanvasController(mockRealtime, mockWebRTC, repository: mockRepo);
  });

  group('CanvasController Realtime Tests', () {
    test('Should update online users when received from realtime', () async {
      final testUsers = [
        {'id': '1', 'name': 'User 1'},
        {'id': '2', 'name': 'User 2'},
      ];

      await controller.initRealtimeCollaboration();
      mockRealtime.emitUsers(testUsers);

      // Wait for stream to process
      await Future.delayed(const Duration(milliseconds: 10));

      expect(controller.onlineUsers.length, 2);
      expect(controller.onlineUsers[0]['id'], '1');
    });

    test('Should handle follow update from another user', () async {
      controller.myUserId = 'my-id';
      await controller.initRealtimeCollaboration();
      
      mockRealtime.emitFollow({
        'follower_id': 'other-id',
        'following_id': 'my-id',
      });

      await Future.delayed(const Duration(milliseconds: 10));

      expect(controller.whoIsWatchingMe.contains('other-id'), true);
    });

    test('Should toggle local hand raised state', () async {
      controller.myUserId = 'me';
      controller.liveNotebookSid = 1;
      controller.isRealtimeActive = true;
      
      controller.toggleHandRaise();
      expect(controller.isMyHandRaised, true);
      
      controller.toggleHandRaise();
      expect(controller.isMyHandRaised, false);
    });
  });
}
