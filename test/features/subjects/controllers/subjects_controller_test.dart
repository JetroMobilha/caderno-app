import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';

import 'package:caderno_digital_app/features/subjects/repositories/subject_repository.dart';
import 'package:caderno_digital_app/features/auth/controllers/auth_controller.dart';
import 'package:caderno_digital_app/features/auth/controllers/auth_state.dart';
import 'package:caderno_digital_app/features/auth/providers/auth_providers.dart';
import 'package:caderno_digital_app/features/auth/repositories/auth_repository.dart';
import 'package:caderno_digital_app/features/auth/models/user_model.dart';
import 'package:mockito/mockito.dart';
import 'package:caderno_digital_app/core/database/app_database.dart' hide User, Subject, Notebook, Page;
import 'package:drift/native.dart';

class MockSubjectRepository extends Mock implements SubjectRepository {
  @override
  Stream<List<Subject>> watchAllSubjects() => Stream.value([]);
}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('SubjectsController Unit Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Initial state - Empty list', () {
      final container = ProviderContainer(
        overrides: [
          subjectRepositoryProvider.overrideWithValue(MockSubjectRepository()),
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          appDatabaseProvider.overrideWithValue(db),
          authProvider.overrideWith(() => AuthController()),
        ],
      );
      
      // Simular login
      container.read(authProvider.notifier).setUser(
        User(id: 1, name: 'Test', email: 'test@test.com', planType: 'free'),
        newToken: 'fake'
      );

      final subjects = container.read(subjectsProvider);

      expect(subjects, isEmpty);
    });
  });
}
