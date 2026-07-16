import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/api_service.dart';
import '../models/notebook_model.dart';

class SharedNotebookRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService();

  Future<List<Notebook>> getSharedNotebooks(int currentUserId, {int? serverUserId}) async {
    // 🌐 NA WEB: Pede diretamente à rota do Laravel enviando a rota unificada
    if (kIsWeb) {
      try {
        final response = await _apiService.get('/subjects/-1/notebooks');
        if (response.statusCode == 200) {
          final List<dynamic> data = jsonDecode(response.body);
          return data.map((map) => Notebook.fromMap(map)).toList();
        }
      } catch (e) {
        debugPrint('🚨 [WEB] Erro ao carregar cadernos partilhados: $e');
      }
      return [];
    }

    // 📱 NO MOBILE/DESKTOP: JOIN Inteligente e Anti-Amnésia
    else {
      final db = await _dbHelper.database;

      // 🚀 O SEGREDO: Procura na tabela pivô tanto pelo ID local (1, 2) como pelo ID do Servidor (58, 65)
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT DISTINCT
          n.*, 
          nu.role 
        FROM notebooks n
        INNER JOIN notebook_user nu ON n.id = nu.notebook_id
        WHERE (nu.user_id = ? OR (nu.user_id = ? AND ? != 0)) AND n.is_deleted = 0
        ORDER BY n.updated_at DESC
      ''', [currentUserId, serverUserId ?? 0, serverUserId ?? 0]);

      return maps.map((map) => Notebook.fromMap(map)).toList();
    }
  }
}