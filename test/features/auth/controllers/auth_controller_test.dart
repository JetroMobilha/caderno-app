import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/auth/controllers/auth_controller.dart';
import 'package:caderno_digital_app/features/auth/models/user_model.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

import 'package:caderno_digital_app/core/database/app_database.dart' hide User;
import 'package:caderno_digital_app/features/auth/repositories/auth_repository.dart';
import 'package:drift/native.dart';

class MockAuthRepository extends Mock implements AuthRepository {}
class MockAppDatabase extends Mock implements AppDatabase {}

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
          authProvider.overrideWith((ref) => AuthController(ref, repository: MockAuthRepository(), database: db)),
        ],
      );
      final controller = container.read(authProvider);

      expect(controller.isAuthenticated, false);
      expect(controller.currentUser, isNull);
    });

    test('setUser updates authentication state', () {
      final container = ProviderContainer(
        overrides: [
          authProvider.overrideWith((ref) => AuthController(ref, repository: MockAuthRepository(), database: db)),
        ],
      );
      final controller = container.read(authProvider);
      
      final testUser = User(id: 1, name: 'Test', email: 'test@test.com', planType: 'free');
      
      controller.setUser(testUser, newToken: 'fake-token');

      expect(controller.isAuthenticated, true);
      expect(controller.currentUser!.name, 'Test');
      expect(controller.token, 'fake-token');
    });
  });
}
