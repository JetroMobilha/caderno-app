import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/api_service.dart';
import '../models/notebook_model.dart';

class NotebookRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService();

  // =========================================================================
  // 📚 LISTAR CADERNOS
  // =========================================================================
  Future<List<Notebook>> getNotebooksBySubject(int subjectId, int? subjectServerId) async {
    if (kIsWeb) {
      final int targetId = subjectServerId ?? subjectId;
      final response = await _apiService.get('/subjects/$targetId/notebooks');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((map) => Notebook.fromMap(map)).toList();
      }
      return [];
    } else {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notebooks',
        where: 'subject_id = ?',
        whereArgs: [subjectId],
      );
      return maps.map((map) => Notebook.fromMap(map)).toList();
    }
  }

  // =========================================================================
  // 📓 CRIAR NOVO CADERNO
  // =========================================================================
  Future<int> insertNotebook(Notebook notebook) async {
    if (kIsWeb) {
      final response = await _apiService.post(
        '/subjects/${notebook.subjectId}/notebooks',
        notebook.toMap(),
      );

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'] as int; // Devolve o ID oficial da Nuvem!
      }
      return 0;
    } else {
      final db = await _dbHelper.database;
      final id = await db.insert('notebooks', notebook.toMap());
      return id;
    }
  }

  // =========================================================================
  // 🗑️ APAGAR CADERNO
  // =========================================================================
  Future<void> deleteNotebook(Notebook notebook) async {
    if (kIsWeb) {
      await _apiService.delete('/notebooks/${notebook.serverId ?? notebook.id}');
    } else {
      if (notebook.id == null) return;
      final db = await _dbHelper.database;
      await db.delete('notebooks', where: 'id = ?', whereArgs: [notebook.id]);
    }
  }

  // =========================================================================
  // 📐 MUDAR TIPO DE PAUTA
  // =========================================================================
  Future<void> updateLineType(int notebookId, String newLineType) async {
    if (kIsWeb) {
      await _apiService.put('/notebooks/$notebookId', {'line_type': newLineType});
    } else {
      final db = await _dbHelper.database;
      await db.update(
        'notebooks',
        {'line_type': newLineType, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [notebookId],
      );
    }
  }

  // =========================================================================
  // 🤝 PARTILHAR CADERNO COM COLEGA
  // =========================================================================
  Future<bool> shareNotebookWithFriend({required int notebookId, required String email, required String role}) async {
    try {
      final response = await _apiService.post(
        '/notebooks/$notebookId/share',
        {'email': email, 'role': role},
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('🚨 Erro ao partilhar nas rotas da API: $e');
      return false;
    }
  }
}