import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../models/notebook_model.dart';

class NotebookRepository {
  final _dbHelper = DatabaseHelper.instance;

  // Cache temporário em memória para quando a app correr no browser
  final List<Notebook> _webCache = [];

  /// Procura todos os cadernos associados a uma disciplina específica ([subjectId])
  Future<List<Notebook>> getNotebooksBySubject(int subjectId) async {
    if (kIsWeb) {
      // NA WEB: Filtra o cache local (no futuro fará um GET /api/subjects/{id}/notebooks)
      return _webCache.where((notebook) => notebook.subject_id == subjectId).toList();
    } else {
      // NO MOBILE/DESKTOP: Query relacional no SQLite com cláusula WHERE
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'notebooks',
        where: 'subject_id = ?',
        whereArgs: [subjectId],
      );
      return maps.map((map) => Notebook.fromMap(map)).toList();
    }
  }

  /// Insere um novo caderno na base de dados de forma adaptativa
  Future<void> insertNotebook(Notebook notebook) async {
    if (kIsWeb) {
      _webCache.add(notebook);
    } else {
      final db = await _dbHelper.database;
      await db.insert('notebooks', notebook.toMap());
    }
  }
}