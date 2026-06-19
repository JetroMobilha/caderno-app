import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/subjects/screens/subjects_screen.dart';

void main() {
  testWidgets('Deve encontrar os elementos principais e validar o campo de texto do formulário', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: SubjectsScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final fab = find.byType(FloatingActionButton);
    expect(fab, findsOneWidget);

    await tester.tap(fab);
    await tester.pumpAndSettle();

    final textFormFieldFinder = find.byType(TextFormField);
    expect(textFormFieldFinder, findsOneWidget);

    final textFormField = tester.widget<TextFormField>(textFormFieldFinder);
    final validator = textFormField.validator;

    expect(validator, isNotNull);
    // 🔥 ALINHADO: Agora bate 100% certo com o validador da UI!
    expect(validator!(null), 'Introduza o nome');
    expect(validator('   '), 'Introduza o nome');
    expect(validator('Engenharia'), isNull);
  });
}