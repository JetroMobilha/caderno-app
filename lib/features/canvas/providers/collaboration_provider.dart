import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/collaboration_room_service.dart';

// Provides a simplified interface to the collaboration service
final collaborationProvider = Provider.autoDispose((ref) {
  final service = ref.watch(collaborationRoomServiceProvider);
  return service;
});

// Selectors for specific collaboration states to minimize rebuilds
final onlineUsersProvider = Provider.autoDispose((ref) {
  return ref.watch(collaborationProvider.select((s) => s.onlineUsers));
});

final remotePointersProvider = Provider.autoDispose((ref) {
  return ref.watch(collaborationProvider.select((s) => s.remotePointers));
});
