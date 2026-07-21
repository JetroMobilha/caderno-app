import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../network/api_service.dart';

class AIAssistantService {
  final ApiService _apiService = ApiService();

  /// 🔎 PESQUISA SEMÂNTICA: Pergunta à IA sobre o conteúdo dos cadernos
  Future<List<AIQueryResult>> searchInNotebooks(String query, {int? notebookId}) async {
    try {
      final response = await _apiService.post('/ai/search', {
        'query': query,
        if (notebookId != null) 'notebook_id': notebookId,
      });

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body)['results'] ?? [];
        return data.map((json) => AIQueryResult.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('🚨 [AI Service] Erro na pesquisa: $e');
    }
    return [];
  }

  /// 📝 RESUMO INTELIGENTE: Gera um resumo de uma página ou caderno
  Future<String?> generateSummary({int? notebookId, int? pageId}) async {
    try {
      final response = await _apiService.post('/ai/summarize', {
        if (notebookId != null) 'notebook_id': notebookId,
        if (pageId != null) 'page_id': pageId,
      });

      if (response.statusCode == 200) {
        return jsonDecode(response.body)['summary'];
      }
    } catch (e) {
      debugPrint('🚨 [AI Service] Erro no resumo: $e');
    }
    return null;
  }
}

class AIQueryResult {
  final String text;
  final int notebookId;
  final int pageNumber;
  final double confidence;

  AIQueryResult({
    required this.text,
    required this.notebookId,
    required this.pageNumber,
    required this.confidence,
  });

  factory AIQueryResult.fromJson(Map<String, dynamic> json) {
    return AIQueryResult(
      text: json['text'] ?? '',
      notebookId: json['notebook_id'] ?? 0,
      pageNumber: json['page_number'] ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
