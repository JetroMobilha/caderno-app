import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/notebooks/screens/notebooks_screen.dart';

void main() {
  testWidgets('Deve renderizar o ecrã de cadernos com o título da disciplina', (WidgetTester tester) async {
    // Act: Carrega o ecrã passando uma disciplina fictícia (ID: 1, Nome: Matemática)
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          home: NotebooksScreen(subjectId: 1, subjectName: 'Matemática'),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Assert: Garante que o ecrã mostra o nome da disciplina no topo
    expect(find.text('Matemática'), findsOneWidget);
    expect(find.text('Novo Caderno'), findsOneWidget);
  });
}
