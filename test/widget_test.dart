import 'package:caderno/features/auth/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caderno/main.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('Login page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider()),
        ],
        child: const MyApp(),
      ),
    );
    
    await tester.pumpAndSettle();

    // Verify that SyncScribe title is shown
    expect(find.text('SyncScribe'), findsOneWidget);
    
    // Verify that Email field is shown
    expect(find.byIcon(Icons.email), findsOneWidget);
    
    // Verify that Login button is shown
    expect(find.text('Entrar'), findsOneWidget);
  });
}
