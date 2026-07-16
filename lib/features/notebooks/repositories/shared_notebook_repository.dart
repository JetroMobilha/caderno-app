import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/api_service.dart';
import '../models/notebook_model.dart';

class SharedNotebookRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService();

  Future<List<Notebook>> getSharedNotebooks(int currentUserId, {int? serverUserId}) async {
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
    } else {
      final db = await _dbHelper.database;

      // 🚀 CORREÇÃO DO "ECO": GROUP BY n.id oblitera os cadernos duplicados!
      final List<Map<String, dynamic>> maps = await db.rawQuery('''
        SELECT 
          n.*, 
          nu.role 
        FROM notebooks n
        INNER JOIN notebook_user nu ON n.id = nu.notebook_id
        WHERE (nu.user_id = ? OR (nu.user_id = ? AND ? != 0)) AND n.is_deleted = 0
        GROUP BY n.id
        ORDER BY n.updated_at DESC
      ''', [currentUserId, serverUserId ?? 0, serverUserId ?? 0]);

      return maps.map((map) => Notebook.fromMap(map)).toList();
    }
  }
}