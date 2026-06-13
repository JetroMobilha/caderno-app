import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caderno/main.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

void main() {
  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    FlutterSecureStorage.setMockInitialValues({});
  });

  testWidgets('Garantir que a estrutura básica do app carrega sem erros', (WidgetTester tester) async {
    // Build our app.
    await tester.pumpWidget(const MyApp());
    
    // O GoRouter leva um tempo para resolver a rota inicial
    await tester.pumpAndSettle();

    // Verifica se a tela de login (que é a inicial) renderizou o título
    expect(find.text('SyncScribe'), findsOneWidget);
    
    // Verifica se os campos de texto estão presentes
    expect(find.byType(TextField), findsNWidgets(2));
  });
}
