import '../../../core/database/database_helper.dart';
import '../models/notebook_model.dart';

class SharedNotebookRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  Future<List<Notebook>> getSharedNotebooks(int currentUserId, {int? serverUserId}) async {
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
