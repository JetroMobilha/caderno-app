import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/api_service.dart';
import '../models/notebook_model.dart';

class NotebookRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService();

  // =========================================================================
  // 📚 LISTAR CADERNOS ATIVOS DA DISCIPLINA (Com Blindagem de ID)
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

      // 🚀 BLINDAGEM ANTI-FANTASMA: Descobre o ID local real da matéria!
      // Se a UI enviar o ID da nuvem por engano, o SQLite traduz para o ID local.
      int realLocalSubjectId = subjectId;
      if (subjectServerId != null) {
        final subQuery = await db.query('subjects', columns: ['id'], where: 'server_id = ?', whereArgs: [subjectServerId]);
        if (subQuery.isNotEmpty) {
          realLocalSubjectId = subQuery.first['id'] as int;
        }
      }

      // Agora procura com absoluta certeza na tabela de cadernos
      final List<Map<String, dynamic>> maps = await db.query(
        'notebooks',
        where: 'is_deleted = ? AND subject_id = ?',
        whereArgs: [0, realLocalSubjectId],
        orderBy: 'updated_at DESC',
      );

      return maps.map((map) => Notebook.fromMap(map)).toList();
    }
  }
  // =========================================================================
  // 📓 CRIAR CADERNO (OFFLINE-FIRST)
  // =========================================================================
  Future<int> insertNotebook(Notebook notebook) async {
    if (kIsWeb) {
      final response = await _apiService.post('/subjects/${notebook.subjectId}/notebooks', notebook.toMap());
      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['id'] as int;
      }
      return 0;
    } else {
      final db = await _dbHelper.database;
      final map = notebook.toMapForSQLite();

      map['synced_with_cloud'] = 0;
      map['is_deleted'] = 0;
      map['updated_at'] = DateTime.now().millisecondsSinceEpoch;

      return await db.insert('notebooks', map);
    }
  }

  // =========================================================================
  // ✏️ ATUALIZAR CADERNO (OFFLINE-FIRST)
  // =========================================================================
  Future<void> updateNotebook(Notebook notebook) async {
    if (kIsWeb) {
      await _apiService.put('/notebooks/${notebook.serverId ?? notebook.id}', notebook.toMap());
    } else {
      if (notebook.id == null) return;
      final db = await _dbHelper.database;
      final map = notebook.toMapForSQLite();

      map['synced_with_cloud'] = 0;
      map['updated_at'] = DateTime.now().millisecondsSinceEpoch;

      await db.update('notebooks', map, where: 'id = ?', whereArgs: [notebook.id]);
    }
  }

  // =========================================================================
  // 🗑️ APAGAR CADERNO (SOFT DELETE OFFLINE-FIRST)
  // =========================================================================
  Future<void> deleteNotebook(Notebook notebook) async {
    if (kIsWeb) {
      await _apiService.delete('/notebooks/${notebook.serverId ?? notebook.id}');
    } else {
      if (notebook.id == null) return;
      final db = await _dbHelper.database;

      await db.update(
        'notebooks',
        {'is_deleted': 1, 'synced_with_cloud': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch},
        where: 'id = ?',
        whereArgs: [notebook.id],
      );
    }
  }

  // =========================================================================
  // 🤝 PARTILHAR CADERNO COM COLEGA (API)
  // =========================================================================
  Future<bool> shareNotebookWithFriend({required int notebookId, required String email, required String role}) async {
    try {
      final response = await _apiService.post('/notebooks/$notebookId/share', {'email': email, 'role': role});
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('🚨 Erro ao partilhar nas rotas da API: $e');
      return false;
    }
  }

  // A. Procurar e-mails para sugestões
  Future<List<String>> searchEmails(String query) async {
    try {
      final response = await _apiService.get('/users/search?q=$query');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((user) => user['email'] as String).toList();
      }
    } catch (e) {
      debugPrint('🚨 Erro Autocomplete: $e');
    }
    return [];
  }

  // B. Puxar colaboradores guardados na nuvem
  Future<List<Map<String, String>>> fetchCollaborators(int notebookId) async {
    try {
      final response = await _apiService.get('/notebooks/$notebookId/collaborators');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((c) => {
          'name': c['name'] as String,
          'email': c['email'] as String,
          'role': c['role'] as String,
        }).toList();
      }
    } catch (e) {
      debugPrint('🚨 Erro ao buscar colaboradores: $e');
    }
    return [];
  }

  // C. Deletar permissão na nuvem
  Future<bool> removeShareWithFriend({required int notebookId, required String email}) async {
    try {
      final response = await _apiService.deleteWithBody('/notebooks/$notebookId/share', {'email': email});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🚨 Erro ao revogar acesso: $e');
      return false;
    }
  }
}