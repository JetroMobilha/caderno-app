import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/main.dart';

void main() {
  testWidgets('A aplicação deve arrancar e mostrar o ecrã de disciplinas', (WidgetTester tester) async {
    // Act: Montamos a nossa aplicação dentro do ProviderScope (o nosso cérebro Riverpod)
    await tester.pumpWidget(const ProviderScope(child: CadernoDigitalApp()));

    // Como a base de dados pode demorar uns milissegundos a inicializar, 
    // pedimos ao tester para renderizar os frames até estar tudo pronto.
    await tester.pumpAndSettle();

    // Assert: Verificamos se o título principal carregou corretamente no ecrã
    expect(find.text('Os Meus Cadernos'), findsOneWidget);

    // Verificamos se o botão de criar disciplina lá está
    expect(find.text('Nova Disciplina'), findsOneWidget);
  });
}