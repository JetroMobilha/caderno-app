import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/features/notebooks/screens/canvas_screen.dart';

void main() {
  testWidgets('Deve iniciar vazio, sem canvas e sem botão de rotação', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CanvasScreen(notebookTitle: 'Física', paperSize: 'A4'),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Este caderno está vazio.\nClique no + para adicionar a primeira folha.'), findsOneWidget);
    expect(find.byKey(const Key('canvas_custom_paint')), findsNothing);
    expect(find.byIcon(Icons.screen_rotation), findsNothing);
  });

  // 🚀 NOVO TESTE: Valida a criação sucessiva e a navegação entre as páginas
  testWidgets('Deve permitir adicionar múltiplas folhas e navegar entre elas', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: CanvasScreen(notebookTitle: 'História', paperSize: 'A4'),
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

    // Valida que estamos na folha 1 de 1
    expect(find.text('História - Folha 1/1'), findsOneWidget);

    // 2. Adiciona a SEGUNDA folha (via novo botão estendido inferior)
    await tester.tap(find.byIcon(Icons.add)); // Procura o ícone de + do novo botão
    await tester.pumpAndSettle();
    await tester.tap(find.text('Paisagem (Horizontal)'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Adicionar'));
    await tester.pumpAndSettle();

    // Valida que saltámos para a folha 2 de 2
    expect(find.text('História - Folha 2/2'), findsOneWidget);

    // 3. Clica no botão de "Página Anterior" (Seta para a esquerda)
    await tester.tap(find.byIcon(Icons.arrow_back_ios_new));
    await tester.pumpAndSettle();

    // Valida que recuámos com sucesso para a folha 1
    expect(find.text('História - Folha 1/2'), findsOneWidget);
  });
}