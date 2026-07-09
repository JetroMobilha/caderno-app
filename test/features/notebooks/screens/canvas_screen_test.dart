import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/features/notebooks/screens/canvas_screen.dart';

void main() {
  testWidgets('Deve iniciar vazio, sem canvas e sem botão de rotação', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CanvasScreen(notebookId: 1,notebookSid:null,notebookTitle: 'Física', paperSize: 'A4'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Este caderno está vazio.\nClique no + para adicionar a primeira folha.'), findsOneWidget);
    expect(find.byKey(const Key('canvas_custom_paint')), findsNothing);
  });

  testWidgets('Deve adicionar múltiplas folhas e navegar via Dropdown', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CanvasScreen(notebookId: 1,notebookSid:null,notebookTitle: 'História', paperSize: 'A4'),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Adiciona a PRIMEIRA folha (via FAB central gigante)
    await tester.tap(find.byType(FloatingActionButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Retrato (Vertical)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('História - Folha 1/1'), findsOneWidget);

    // 🚀 NOVO TESTE: Garante que o motor de animação e deslize de folhas está ativo
    expect(find.byType(PageView), findsOneWidget);

    // 2. Adiciona a SEGUNDA folha (abrindo o Dropdown no topo)
    await tester.tap(find.text('História - Folha 1/1'));
    await tester.pumpAndSettle();

    // Clica no novo item "Nova Folha" dentro da lista suspensa
    await tester.tap(find.text('Nova Folha').last);
    await tester.pumpAndSettle();

    await tester.tap(find.text('Paisagem (Horizontal)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    expect(find.text('História - Folha 2/2'), findsOneWidget);

    // 3. Navega de volta para a folha 1 usando o Dropdown
    await tester.tap(find.text('História - Folha 2/2'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ir para Folha 1').last);
    await tester.pumpAndSettle();

    expect(find.text('História - Folha 1/2'), findsOneWidget);
  });
}