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
    expect(find.byType(GestureDetector), findsAtLeastNWidgets(1));
  });

  testWidgets('Deve conter botões de seleção de cor na Toolbar', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CanvasScreen(notebookTitle: 'Teste de Cores'),
      ),
    );
    await tester.pumpAndSettle();

    // 🔥 CORREÇÃO: Procuramos por CircleAvatar (o nosso estojo de canetas real)
    // Esperamos pelo menos 4 candidatos (Azul, Preto, Vermelho, Verde)
    expect(find.byType(CircleAvatar), findsAtLeastNWidgets(4));
  });

  testWidgets('Deve instanciar o CanvasScreen com um tipo de pauta específico', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CanvasScreen(
          notebookTitle: 'Desenho Livre',
          lineType: 'blank',
        ),
      ),
    );
    await tester.pumpAndSettle();

    // 🔥 ALVO LOCALIZADO: Procura diretamente pela Key blindada!
    final canvasFinder = find.byKey(const Key('canvas_custom_paint'));

    expect(canvasFinder, findsOneWidget);
  });
}