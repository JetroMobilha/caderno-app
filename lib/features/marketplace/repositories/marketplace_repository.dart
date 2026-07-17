import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/network/api_service.dart';
import '../../notebooks/models/notebook_model.dart';

class MarketplaceRepository {
  final ApiService _apiService = ApiService();

  // 1. Puxar todos os cadernos públicos da Loja (Com filtro opcional)
  Future<List<Notebook>> getPublishedNotebooks({String? searchQuery}) async {
    try {
      final endpoint = searchQuery != null && searchQuery.isNotEmpty
          ? '/marketplace/notebooks?q=$searchQuery'
          : '/marketplace/notebooks';

      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((map) => Notebook.fromMap(map)).toList();
      }
    } catch (e) {
      debugPrint('🚨 [MARKETPLACE] Erro ao carregar loja: $e');
    }
    return [];
  }

  // 2. Ação de Adquirir/Clonar o caderno para a conta do estudante
  Future<bool> acquireNotebook(int notebookServerId) async {
    try {
      // O backend deve clonar o caderno e as suas páginas para a tabela do utilizador atual
      final response = await _apiService.post('/marketplace/notebooks/$notebookServerId/acquire', {});
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('🚨 [MARKETPLACE] Erro na aquisição: $e');
      return false;
    }
  }
}