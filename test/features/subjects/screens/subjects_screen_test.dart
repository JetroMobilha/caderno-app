import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/subjects/screens/subjects_screen.dart';

void main() {
  testWidgets('Deve mostrar erro de validacao se tentar criar disciplina com nome vazio', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(home: SubjectsScreen()),
      ),
    );

    // Abre o Modal de Criação
    final fab = find.byType(FloatingActionButton);
    await tester.tap(fab);
    await tester.pumpAndSettle();

    // Clica no botão "Criar" sem escrever nada
    final criarBtn = find.text('Criar');
    await tester.tap(criarBtn);
    await tester.pumpAndSettle();

    // Deve encontrar o texto de validação do Form
    expect(find.text('Por favor, introduza o nome da disciplina'), findsOneWidget);
  });
}