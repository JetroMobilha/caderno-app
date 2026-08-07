import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/services.dart';
import 'package:caderno_digital_app/features/marketplace/controllers/marketplace_controller.dart';
import 'package:caderno_digital_app/features/marketplace/repositories/marketplace_repository.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'marketplace_controller_test.mocks.dart';

import 'package:caderno_digital_app/features/auth/controllers/auth_controller.dart';
import 'marketplace_controller_test.mocks.dart';

@GenerateMocks([MarketplaceRepository, AuthController])
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  // 🚀 MOCK PLATFORM CHANNELS
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
    const MethodChannel('plugins.flutter.io/path_provider'), (message) async => '.');

  late MockMarketplaceRepository mockRepo;
  late MockAuthController mockAuth;
  late ProviderContainer container;

  setUp(() {
    mockRepo = MockMarketplaceRepository();
    mockAuth = MockAuthController();
    
    when(mockAuth.token).thenReturn('fake-token');

    container = ProviderContainer(
      overrides: [
        marketplaceRepositoryProvider.overrideWithValue(mockRepo),
        authProvider.overrideWith((ref) => mockAuth),
      ],
    );
  });

  group('MarketplaceController Tests', () {
    test('loadInitial should fetch first page and update state', () async {
      final notebook = Notebook(id: 1, title: 'Test', coverType: 'color', lineType: 'ruled', paperSize: 'A4');
      
      when(mockRepo.getPublishedNotebooks(page: 1, searchQuery: ''))
          .thenAnswer((_) async => {
            'notebooks': [notebook],
            'last_page': 2,
            'total': 20,
          });

      final listener = container.listen(marketplaceProvider, (previous, next) {});
      
      // Wait for initial load
      await container.read(marketplaceProvider.notifier).loadInitial();
      
      final state = container.read(marketplaceProvider);
      expect(state.notebooks.length, 1);
      expect(state.notebooks.first.title, 'Test');
      expect(state.hasMore, true);
    });
  });
}
