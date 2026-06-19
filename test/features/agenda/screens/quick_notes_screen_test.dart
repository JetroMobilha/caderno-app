import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/agenda/screens/quick_notes_screen.dart';

void main() {
  testWidgets('Deve mostrar mensagem vazia se nao existirem notas rapidas', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
          // 🚀 FORÇADO: Passa array vazio para testar a branch lógica do Center()
          home: QuickNotesScreen(initialNotes: []),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Nenhuma nota para hoje. Clique no + para começar!'), findsOneWidget);
  });
}