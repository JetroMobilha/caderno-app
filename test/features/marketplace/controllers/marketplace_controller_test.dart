import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:flutter/services.dart';
import 'package:caderno_digital_app/features/marketplace/controllers/marketplace_controller.dart';
import 'package:caderno_digital_app/features/marketplace/repositories/marketplace_repository.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/auth/controllers/auth_controller.dart';
import 'package:caderno_digital_app/features/auth/providers/auth_providers.dart';
import 'package:caderno_digital_app/features/auth/repositories/auth_repository.dart';
import 'package:caderno_digital_app/features/auth/models/user_model.dart';
import 'package:caderno_digital_app/core/database/app_database.dart' hide User, Subject, Notebook, Page;
import 'package:drift/native.dart';

class MockMarketplaceRepository extends Mock implements MarketplaceRepository {
  @override
  Future<Map<String, dynamic>> getPublishedNotebooks({int page = 1, String? searchQuery = ''}) async {
    return {
      'notebooks': [
        Notebook(id: 1, title: 'Test Manual', coverType: 'color', lineType: 'ruled', paperSize: 'A4')
      ], 
      'last_page': 1, 
      'total': 1
    };
  }
}

class MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'), (message) async => '.');

  late MockMarketplaceRepository mockRepo;
  late ProviderContainer container;
  late AppDatabase db;

  setUp(() {
    mockRepo = MockMarketplaceRepository();
    db = AppDatabase.forTesting(NativeDatabase.memory());

    container = ProviderContainer(
      overrides: [
        marketplaceRepositoryProvider.overrideWithValue(mockRepo),
        authRepositoryProvider.overrideWithValue(MockAuthRepository()),
        appDatabaseProvider.overrideWithValue(db),
        authProvider.overrideWith(() => AuthController()),
      ],
    );

    // Login fake
    container.read(authProvider.notifier).setUser(
      User(id: 1, name: 'Test', email: 'test@t.com', planType: 'free'),
      newToken: 'fake-token'
    );
  });

  tearDown(() async {
    await db.close();
    container.dispose();
  });

  group('MarketplaceController Tests', () {
    test('loadInitial should fetch first page and update state', () async {
      await container.read(marketplaceProvider.notifier).loadInitial();
      
      final state = container.read(marketplaceProvider);
      expect(state.notebooks.length, 1);
      expect(state.notebooks.first.title, 'Test Manual');
    });
  });
}
