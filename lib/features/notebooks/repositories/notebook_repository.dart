import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../models/notebook_model.dart';
import '../models/drawing_point_model.dart'; // 🚀 IMPORTA O MODELO DO TRAÇO E DA PÁGINA

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

  /// 🚀 NOVO: Salva de forma transacional todas as páginas e traços do caderno
  Future<void> saveFullNotebook(int notebookId, List<LocalPage> pages) async {
    if (kIsWeb) {
      // NA WEB: Como o SQLite FFI não funciona aqui, deixamos um aviso de debug
      // No futuro, isto será um POST/PUT para a tua API em Laravel/Node.js
      debugPrint("Web: Salvamento de páginas e traços interceptado pelo cache.");
      return;
    }

    final db = await _dbHelper.database;

    // Inicia uma Transação Segura. Se a app fechar ou a bateria acabar a meio
    // deste bloco, o SQLite reverte tudo automaticamente para não corromper os dados.
    await db.transaction((txn) async {

      // 1. Apaga as páginas e traços antigos deste caderno (Limpeza antes de regravar)
      // Como a tabela pages está ligada com "ON DELETE CASCADE", apagar as páginas
      // vai apagar também todos os traços (canvas_strokes) órfãos magicamente!
      await txn.delete(
          'pages',
          where: 'notebook_id = ?',
          whereArgs: [notebookId]
      );

      // 2. Grava a nova estrutura de folhas atualizada
      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];

        // Insere a Página e recupera o ID auto-incremental gerado pelo SQLite
        final pageId = await txn.insert('pages', {
          'notebook_id': notebookId,
          'page_number': i + 1,
          'is_landscape': page.isLandscape ? 1 : 0, // 1 = Paisagem, 0 = Retrato
          'synced_with_cloud': 0, // Carimbo a zero (Ainda não foi para o servidor)
        });

        // 3. Insere todos os traços contidos nesta página específica
        for (var stroke in page.strokes) {
          await txn.insert('canvas_strokes', {
            'client_stroke_id': stroke.id, // O UUID gerado
            'page_id': pageId,
            'stroke_data': stroke.toJsonString(), // O JSON compactado das coordenadas
            'synced_with_cloud': 0,
          });
        }
      }
    });
  }
}