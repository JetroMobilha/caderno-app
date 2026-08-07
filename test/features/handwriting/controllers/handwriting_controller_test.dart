import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:caderno_digital_app/features/handwriting/controllers/handwriting_controller.dart';
import 'package:caderno_digital_app/features/handwriting/repositories/handwriting_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'handwriting_controller_test.mocks.dart';

@GenerateMocks([HandwritingRepository])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // 🚀 MOCK PLATFORM CHANNELS
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'), (message) async => '.');

  late MockHandwritingRepository mockRepo;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockHandwritingRepository();
    
    // Stub loadProgress response
    when(mockRepo.getTrainedCharacters()).thenAnswer((_) async => ['A', 'B']);

    container = ProviderContainer(
      overrides: [
        handwritingRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  group('HandwritingController Tests', () {
    test('initial load should fetch trained characters', () async {
      // The build method calls loadProgress
      // We need to wait for the async work to complete.
      await container.read(handwritingProvider.notifier).loadProgress();
      
      final state = container.read(handwritingProvider);
      expect(state.trainedCharacters.contains('A'), true);
      expect(state.trainedCharacters.contains('B'), true);
    });

    test('addFullStroke should update state', () {
      final notifier = container.read(handwritingProvider.notifier);
      final points = [const Offset(0, 0), const Offset(10, 10)];
      
      notifier.addFullStroke(points);
      
      final state = container.read(handwritingProvider);
      expect(state.currentStrokes.length, 1);
      expect(state.currentStrokes.first, points);
    });

    test('saveCurrentCharacter should call repository and update trained set', () async {
      final notifier = container.read(handwritingProvider.notifier);
      notifier.setCharacter('C');
      notifier.addFullStroke([const Offset(0, 0)]);
      
      when(mockRepo.saveCharacter(character: 'C', strokes: anyNamed('strokes')))
          .thenAnswer((_) async => true);

      final success = await notifier.saveCurrentCharacter();
      
      expect(success, true);
      expect(container.read(handwritingProvider).trainedCharacters.contains('C'), true);
    });
  });
}
