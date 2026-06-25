import 'dart:convert';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart'; // Importa o teu DatabaseHelper real
import '../../features/notebooks/models/drawing_point_model.dart';

class LocalDatabaseService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 📥 SALVA A ESTRUTURA DE METADADOS DA PÁGINA
  Future<int> savePageMetadata(LocalPage page) async {
    final db = await _dbHelper.database;
    if (page.id != null) {
      await db.update(
        'pages',
        page.toDatabaseMap(),
        where: 'id = ?',
        whereArgs: [page.id],
      );
      return page.id!;
    } else {
      return await db.insert('pages', page.toDatabaseMap());
    }
  }

  // 📥 SALVA UM TRAÇO VETORIAL ISOLADO (Otimização granular em tempo real)
  Future<void> saveStrokeLocally(int pageId, Stroke stroke) async {
    final db = await _dbHelper.database;
    await db.insert(
      'canvas_strokes',
      {
        'client_stroke_id': stroke.id,
        'page_id': pageId,
        'stroke_data': jsonEncode(stroke.toMap()), // Converte os pontos e espessura em string JSON
        'is_deleted': 0,
        'synced_with_cloud': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 📥 SALVA UM BLOCO DE TEXTO ISOLADO
  Future<void> saveTextBlockLocally(int pageId, TextBlock block) async {
    final db = await _dbHelper.database;
    await db.insert(
      'canvas_text_blocks',
      {
        'client_text_id': block.id,
        'page_id': pageId,
        'text_data': jsonEncode(block.toMap()), // Converte o Rich Text completo em string JSON
        'is_deleted': 0,
        'synced_with_cloud': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 📤 CARREGA UMA PÁGINA COMPLETA COM TUDO O QUE LHE PERTENCE
  Future<List<LocalPage>> getFullPagesForNotebook(int notebookId) async {
    final db = await _dbHelper.database;

    // 1. Busca todas as páginas do caderno
    final pageMaps = await db.query(
        'pages',
        where: 'notebook_id = ?',
        whereArgs: [notebookId],
        orderBy: 'page_number ASC'
    );

    List<LocalPage> fullPages = [];

    for (var pMap in pageMaps) {
      final page = LocalPage.fromDatabaseMap(pMap);
      final pId = page.id;

      if (pId != null) {
        // 2. Busca os traços desta página específica
        final strokeMaps = await db.query('canvas_strokes', where: 'page_id = ? AND is_deleted = 0', whereArgs: [pId]);
        page.strokes = strokeMaps.map((s) {
          final data = jsonDecode(s['stroke_data'] as String);
          return Stroke.fromMap(data);
        }).toList();

        // 3. Busca os blocos de texto desta página específica
        final textMaps = await db.query('canvas_text_blocks', where: 'page_id = ? AND is_deleted = 0', whereArgs: [pId]);
        page.textBlocks = textMaps.map((t) {
          final data = jsonDecode(t['text_data'] as String);
          return TextBlock.fromMap(data);
        }).toList();
      }

      fullPages.add(page);
    }

    return fullPages;
  }
}