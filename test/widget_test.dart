import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caderno/main.dart';

void main() {
  testWidgets('Login page smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that SyncScribe title is shown
    expect(find.text('SyncScribe'), findsOneWidget);
    
    // Verify that Email field is shown
    expect(find.byIcon(Icons.email), findsOneWidget);
    
    // Verify that Login button is shown
    expect(find.text('Entrar'), findsOneWidget);
  });
}
