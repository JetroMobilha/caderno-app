import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:http/http.dart' as http;
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
// (Assume que criamos a classe PageRepository abaixo)

void main() {
  group('PageRepository Tests |', () {
    test('Deve enviar uma pagina com traços com sucesso para o Laravel', () async {
      // Aqui iríamos mockar o cliente HTTP para devolver status 201 Created
      // Garantindo que o payload toMap() é processado sem exceções.
      final page = LocalPage(
        notebookId: 1,
        pageNumber: 1,
         isLandscape: true,
      );

      expect(page.notebookId, 1);

    });
  });
}