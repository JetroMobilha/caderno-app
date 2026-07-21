import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';

import 'package:caderno_digital_app/features/subjects/repositories/subject_repository.dart';
import 'package:caderno_digital_app/features/auth/controllers/auth_controller.dart';
import 'package:mockito/mockito.dart';

class MockSubjectRepository extends Mock implements SubjectRepository {
  @override
  Stream<List<Subject>> watchAllSubjects() => Stream.value([]);
}

class MockAuthController extends Mock implements AuthController {
  @override
  bool get isAuthenticated => true;
}

void main() {
  group('SubjectsController Unit Tests', () {
    test('Initial state - Empty list', () {
      final container = ProviderContainer(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(MockSubjectRepository()),
          authProvider.overrideWith((ref) => MockAuthController()),
        ],
      );
      final subjects = container.read(subjectsProvider);

      expect(subjects, isEmpty);
    });
  });
}
