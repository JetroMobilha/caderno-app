import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_service.dart';
import '../../notebooks/models/notebook_model.dart';

class MarketplaceRepository {
  final ApiService _apiService = ApiService();

  // 1. Puxar todos os cadernos públicos da Loja (Com paginação e pesquisa)
  Future<Map<String, dynamic>> getPublishedNotebooks({int page = 1, String? searchQuery}) async {
    try {
      final queryParams = StringBuffer('?page=$page');
      if (searchQuery != null && searchQuery.isNotEmpty) {
        queryParams.write('&q=$searchQuery');
      }

      final response = await _apiService.get('/marketplace/notebooks$queryParams');

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = jsonDecode(response.body);
        final List<dynamic> data = body['data'] ?? [];
        
        return {
          'notebooks': data.map((map) => Notebook.fromJson(map)).toList(),
          'last_page': body['last_page'] ?? 1,
          'total': body['total'] ?? 0,
        };
      }
    } catch (e) {
      debugPrint('🚨 [MARKETPLACE] Erro ao carregar loja: $e');
    }
    return {'notebooks': <Notebook>[], 'last_page': 1, 'total': 0};
  }

  // 2. Ação de Adquirir/Clonar o caderno para a conta do estudante
  Future<Notebook?> acquireNotebook(int notebookServerId) async {
    try {
      final response = await _apiService.post('/marketplace/notebooks/$notebookServerId/acquire', {});
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        if (data.containsKey('notebook')) {
          return Notebook.fromJson(data['notebook']);
        }
      }
    } catch (e) {
      debugPrint('🚨 [MARKETPLACE] Erro na aquisição do server_id $notebookServerId: $e');
    }
    return null;
  }
}

final marketplaceRepositoryProvider = Provider<MarketplaceRepository>((ref) {
  return MarketplaceRepository();
});
