import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/auth/controllers/auth_controller.dart';
import 'package:caderno_digital_app/features/auth/models/user_model.dart';
import 'package:caderno_digital_app/features/auth/providers/auth_providers.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:caderno_digital_app/core/database/app_database.dart' hide User;
import 'package:caderno_digital_app/features/auth/repositories/auth_repository.dart';
import 'package:drift/native.dart';

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  group('AuthController Unit Tests', () {
    late AppDatabase db;

    setUp(() {
      db = AppDatabase.forTesting(NativeDatabase.memory());
    });

    tearDown(() async {
      await db.close();
    });

    test('Initial state - Not authenticated', () {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      final state = container.read(authProvider);

      expect(state.isAuthenticated, false);
      expect(state.currentUser, isNull);
    });

    test('setUser updates authentication state', () {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(MockAuthRepository()),
          appDatabaseProvider.overrideWithValue(db),
        ],
      );
      
      final testUser = User(id: 1, name: 'Test', email: 'test@test.com', planType: 'free');
      
      container.read(authProvider.notifier).setUser(testUser, newToken: 'fake-token');

      final state = container.read(authProvider);
      expect(state.isAuthenticated, true);
      expect(state.currentUser!.name, 'Test');
      expect(state.token, 'fake-token');
    });
  });
}
