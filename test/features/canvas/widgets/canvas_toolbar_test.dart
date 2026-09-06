import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/canvas/widgets/canvas_toolbar.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/providers/canvas_tool_provider.dart';

import 'package:caderno_digital_app/features/canvas/providers/canvas_document_provider.dart';

class MockDocumentNotifier extends Notifier<CanvasDocumentState> implements CanvasDocumentNotifier {
  @override
  CanvasDocumentState build() => CanvasDocumentState(
    currentUserRole: 'owner',
    myUserId: '1',
  );
  
  @override noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  late LocalPage mockPage;

  setUp(() {
    mockPage = LocalPage(
      notebookId: 1,
      pageNumber: 1,
      isLandscape: false,
    );
  });

  Widget createToolbar() {
    return ProviderScope(
      overrides: [
        canvasDocumentProvider.overrideWith(() => MockDocumentNotifier()),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: CanvasToolbar(
            currentPage: mockPage,
            onColorTap: () {},
            onThicknessTap: () {},
            onChangePaperTap: () {},
            onDeletePageTap: () {},
            onAiAssistantTap: () {},
          ),
        ),
      ),
    );
  }

  testWidgets('CanvasToolbar inicia no modo desenho com ícone de Pincel', (WidgetTester tester) async {
    await tester.pumpWidget(createToolbar());
    expect(find.byIcon(Icons.brush), findsOneWidget);
  });

  testWidgets('Ao selecionar ferramenta de texto, barra contextual de escrita aparece', (WidgetTester tester) async {
    await tester.pumpWidget(createToolbar());
    
    // Simular clique no ícone de texto (o que tem o "T")
    // Como unificámos Texto/Tabela, o ícone padrão é Icons.text_fields
    await tester.tap(find.byIcon(Icons.text_fields));
    await tester.pump();

    // Deve mostrar o botão "Voltar" da barra contextual
    expect(find.byIcon(Icons.arrow_back_rounded), findsOneWidget);
    expect(find.text('Toque na folha para escrever'), findsOneWidget);
  });

  testWidgets('Botão Voltar restaura modo desenho', (WidgetTester tester) async {
    await tester.pumpWidget(createToolbar());
    
    // Entrar no modo texto
    await tester.tap(find.byIcon(Icons.text_fields));
    await tester.pump();
    
    // Clicar no botão Voltar
    await tester.tap(find.byIcon(Icons.arrow_back_rounded));
    await tester.pump();

    // Pincel deve estar visível novamente
    expect(find.byIcon(Icons.brush), findsOneWidget);
  });
}
