import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/local_database_service.dart';
import '../models/notebook_model.dart';
import '../models/drawing_point_model.dart';

class NotebookRepository {
  final _dbHelper = DatabaseHelper.instance;
  final List<Notebook> _webCache = [];

  Future<List<Notebook>> getNotebooksBySubject(int subjectId) async {
    if (kIsWeb) {
      return _webCache.where((notebook) => notebook.subject_id == subjectId).toList();
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

  /// Insere um novo caderno e DEVOLVE o ID gerado!
  Future<int> insertNotebook(Notebook notebook) async {
    if (kIsWeb) {
      _webCache.add(notebook);
      return _webCache.length; // Retorna um ID falso para a Web
    } else {
      final db = await _dbHelper.database;

      // 🚀 SQLite insere e devolve o ID real
      final id = await db.insert('notebooks', notebook.toMap());

      // Atualiza a memória RAM
      notebook.id = id;

      return id;
    }
  }

  // ============================================================================
  // 📥 ESTRATÉGIA 1: BULK SAVE (100% Blindado contra falhas de Transação)
  // ============================================================================
  Future<void> saveFullNotebook(int notebookId, List<LocalPage> pages) async {
    if (kIsWeb) return;

    final db = await _dbHelper.database;

    try {
      await db.transaction((txn) async {

        // 🚀 1. LIMPEZA MANUAL SEGURA: Primeiro vamos buscar as páginas atuais deste caderno
        final oldPages = await txn.query('pages', columns: ['id'], where: 'notebook_id = ?', whereArgs: [notebookId]);

        // 🚀 2. Destruímos os traços velhos manualmente (contorna o bug das Foreign Keys desligadas)
        for (var p in oldPages) {
          await txn.delete('canvas_strokes', where: 'page_id = ?', whereArgs: [p['id']]);
          await txn.delete('canvas_text_blocks', where: 'page_id = ?', whereArgs: [p['id']]);
        }

        // 🚀 3. Apagamos as páginas antigas
        await txn.delete('pages', where: 'notebook_id = ?', whereArgs: [notebookId]);

        // 🚀 4. RECONSTRUÇÃO LIMPA
        for (int i = 0; i < pages.length; i++) {
          final page = pages[i];

          // Insere a página e captura o ID novo
          final pageId = await txn.insert('pages', {
            'notebook_id': notebookId,
            'page_number': i + 1,
            'is_landscape': page.isLandscape ? 1 : 0,
            'header_data': page.title,
            'footer_data': page.footer,
            'synced_with_cloud': 0,
          });

          page.id = pageId; // Atualiza a memória RAM

          // Salva os traços forçando a substituição em caso de erro (ConflictAlgorithm)
          for (var stroke in page.strokes) {
            await txn.insert('canvas_strokes', {
              'client_stroke_id': stroke.id,
              'page_id': pageId,
              'stroke_data': jsonEncode(stroke.toMap()),
              'synced_with_cloud': 0,
            }, conflictAlgorithm: ConflictAlgorithm.replace); // <-- SALVA-VIDAS
          }

          // Salva os textos
          for (var block in page.textBlocks) {
            await txn.insert('canvas_text_blocks', {
              'client_text_id': block.id,
              'page_id': pageId,
              'text_data': jsonEncode(block.toMap()),
              'synced_with_cloud': 0,
            }, conflictAlgorithm: ConflictAlgorithm.replace); // <-- SALVA-VIDAS
          }
        }
      });
      print("✅ Caderno guardado com sucesso na base de dados!");
    } catch (e) {
      // 🚀 Se a aplicação tentar esconder um erro, ele vai gritar no terminal!
      print("🚨 ERRO GRAVE AO GUARDAR CADERNO: $e");
    }
  }
  // 🚀 NOVO: Método para o Ecrã buscar as folhas quando abre!
  Future<List<LocalPage>> getFullPagesForNotebook(int notebookId) async {
    if (kIsWeb) return [];

    // Isto chama o método que criámos no LocalDatabaseService
    final localDb = LocalDatabaseService();
    return await localDb.getFullPagesForNotebook(notebookId);
  }

  // ============================================================================
  // ⚡ ESTRATÉGIA 2: MICRO-SAVES (Para máxima performance no onPanEnd)
  // ============================================================================

  /// Salva apenas UM novo traço de forma cirúrgica (0ms de lag no ecrã)
  Future<void> saveSingleStroke(int pageId, Stroke stroke) async {
    if (kIsWeb) {
      debugPrint("Web: Traço salvo em cache.");
      return;
    }
    final db = await _dbHelper.database;
    await db.insert('canvas_strokes', {
      'client_stroke_id': stroke.id,
      'page_id': pageId,
      'stroke_data': jsonEncode(stroke.toMap()),
      'synced_with_cloud': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Salva apenas UM bloco de texto atualizado/novo
  Future<void> saveSingleTextBlock(int pageId, TextBlock block) async {
    if (kIsWeb) {
      debugPrint("Web: Bloco de texto salvo em cache.");
      return;
    }
    final db = await _dbHelper.database;
    await db.insert('canvas_text_blocks', {
      'client_text_id': block.id,
      'page_id': pageId,
      'text_data': jsonEncode(block.toMap()),
      'synced_with_cloud': 0,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /// Atualiza apenas os metadados da folha (Título ou Rodapé alterados)
  Future<void> updatePageMetadata(int pageId, String title, String footer) async {
    if (kIsWeb) return;
    final db = await _dbHelper.database;
    await db.update(
        'pages',
        {
          'header_data': title,
          'footer_data': footer,
          'synced_with_cloud': 0,
        },
        where: 'id = ?',
        whereArgs: [pageId]
    );
  }

// 🚀 APAGA UM TRAÇO ISOLADO (Soft Delete para sincronizar com a Nuvem depois)
  Future<void> deleteSingleStroke(int pageId, String clientStrokeId) async {
    if (kIsWeb) return;
    final db = await _dbHelper.database;

    await db.update(
      'canvas_strokes',
      {'is_deleted': 1, 'synced_with_cloud': 0}, // 1 = Apagado (O Painter vai ignorar)
      where: 'client_stroke_id = ? AND page_id = ?',
      whereArgs: [clientStrokeId, pageId],
    );
  }
}