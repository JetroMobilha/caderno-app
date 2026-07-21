import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/main.dart';

void main() {
  testWidgets('A aplicação deve arrancar corretamente', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MyApp(),
      ),
    );

    expect(find.byType(MaterialApp), findsOneWidget);
    
    // Limpar timers pendentes (como o do SplashScreen)
    await tester.pump(const Duration(seconds: 5));
  });
}
