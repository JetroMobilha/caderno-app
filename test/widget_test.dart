import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  testWidgets('A aplicação deve arrancar e mostrar o ecrã de disciplinas', (WidgetTester tester) async {
    // Carrega a aplicação com o escopo global do Riverpod necessário para os providers
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(

        ),
      ),
    );

    // Aguarda o render das fontes e do layout
    await tester.pumpAndSettle();

    // Garante que o AppBar inicial com o título reativo do perfil está presente
    expect(find.text('Os meus Cadernos'), findsOneWidget);

    // Garante que o botão flutuante de adicionar está visível ao utilizador
    expect(find.byType(FloatingActionButton), findsOneWidget);
  });
}