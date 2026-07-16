import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../models/notebook_model.dart';

class SharedNotebookRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // =========================================================================
  // 🤝 LISTAR APENAS CADERNOS PARTILHADOS (A "Soft Implementation")
  // =========================================================================
  Future<List<Notebook>> getSharedNotebooks(int currentUserId) async {
    if (kIsWeb) return []; // Na web a API trata disto diretamente através das rotas

    final db = await _dbHelper.database;

    // 🚀 A ELEGÂNCIA DO JOIN: Cruza a tabela principal com a Tabela Pivô
    final List<Map<String, dynamic>> maps = await db.rawQuery('''
      SELECT 
        n.*, 
        nu.role 
      FROM notebooks n
      INNER JOIN notebook_user nu ON n.id = nu.notebook_id
      WHERE nu.user_id = ? AND n.is_deleted = 0
      ORDER BY n.updated_at DESC
    ''', [currentUserId]);

    return maps.map((map) => Notebook.fromMap(map)).toList();
  }
}