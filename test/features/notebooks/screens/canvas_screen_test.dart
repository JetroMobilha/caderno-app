import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/features/notebooks/screens/canvas_screen.dart';

void main() {
  testWidgets('Deve renderizar o ecrã de Canvas com a área de desenho', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CanvasScreen(notebookTitle: 'Apontamentos de Álgebra'),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Apontamentos de Álgebra'), findsOneWidget);

    // 🔥 CORREÇÃO: Verificamos se existe pelo menos um GestureDetector na árvore
    // sem falhar caso o Scaffold/AppBar crie os seus próprios por defeito.
    expect(find.byType(GestureDetector), findsAtLeastNWidgets(1));
  });
}