import 'package:http/http.dart' as http;
import 'dart:convert';
import '../models/page_model.dart';

class PageRepository {
  // Configuração do IP do teu servidor Laravel local
  // (Nota: No emulador Android, usa-se 10.0.2.2 em vez de localhost)
  final String _baseUrl = 'http://127.0.0.1:8000/api';

  /// Envia e salva a página atual com todos os seus traços no Laravel
  Future<bool> savePageToServer(NotebookPage page) async {
    final url = Uri.parse('$_baseUrl/pages');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(page.toMap()), // Serialização do modelo
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return true; // Sincronizado com sucesso!
      }
      return false;
    } catch (e) {
      // Se houver falha de rede, a app não crasha
      print('Erro de conexão ao Laravel: $e');
      return false;
    }
  }

  /// Procura as páginas de um caderno guardadas na nuvem
  Future<List<NotebookPage>> fetchPagesFromServer(int notebookId) async {
    final url = Uri.parse('$_baseUrl/notebooks/$notebookId/pages');

    try {
      final response = await http.get(url, headers: {'Accept': 'application/json'});

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => NotebookPage.fromMap(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }
}