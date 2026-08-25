import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/audio_session_service.dart';

final audioSessionProvider = Provider.autoDispose((ref) {
  final service = ref.watch(audioSessionServiceProvider);
  return service;
});

final lessonRecordingsProvider = Provider.autoDispose((ref) {
  return ref.watch(audioSessionProvider.select((s) => s.lessonRecordings));
});
