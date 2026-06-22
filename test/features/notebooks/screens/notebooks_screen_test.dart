import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/notebooks/screens/notebooks_screen.dart';

void main() {
  testWidgets('Deve renderizar o ecrã de cadernos com o título da disciplina', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: NotebooksScreen(
            subjectId: 1,
            subjectName: 'Matemática',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Valida se o ecrã principal carregou
    expect(find.text('Matemática'), findsOneWidget);

    // 2. Procura e clica no botão "+" para abrir o Dialog
    final fabFinder = find.byType(FloatingActionButton);
    expect(fabFinder, findsOneWidget);

    await tester.tap(fabFinder);
    // 🔥 CORREÇÃO: Força o motor de testes a processar a animação de abertura do Dialog
    await tester.pumpAndSettle();

    // 3. Agora o texto "Novo Caderno" já está visível na árvore
    expect(find.text('Novo Caderno'), findsOneWidget);
  });
}