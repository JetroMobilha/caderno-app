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
  // 🚀 MOTOR DE SALVAMENTO EM MASSA BLINDADO (Com Remoção de Páginas Fantasma e Reordenação)
  Future<void> saveFullNotebook(int notebookId, List<LocalPage> pages) async {
    if (kIsWeb) return;
    final db = await _dbHelper.database;

    await db.transaction((txn) async {
      // =======================================================================
      // 🕵️‍♂️ PASSO 1: DETECTAR E ELIMINAR AS FOLHAS QUE FORAM RASGADAS
      // =======================================================================

      // 1. Busca todos os IDs de páginas que estão atualmente gravados no SQLite para este caderno
      final List<Map<String, dynamic>> existingRows = await txn.query(
        'pages',
        columns: ['id'],
        where: 'notebook_id = ?',
        whereArgs: [notebookId],
      );

      final List<int> existingIds = existingRows
          .map((row) => row['id'] as int)
          .toList();

      // 2. Recolhe os IDs das páginas que continuam vivas na memória RAM
      final List<int> currentIds = pages
          .map((page) => page.id)
          .whereType<int>()
          .toList();

      // 3. Se um ID existe na base de dados mas não está na RAM, significa que a folha foi rasgada!
      for (final int id in existingIds) {
        if (!currentIds.contains(id)) {
          // O ON DELETE CASCADE configurado no DatabaseHelper limpa os filhos automaticamente!
          await txn.delete(
            'pages',
            where: 'id = ?',
            whereArgs: [id],
          );
        }
      }

      // =======================================================================
      // 💾 PASSO 2: ATUALIZAR AS FOLHAS SOBREVIVENTES E REORDENAR A PAGINAÇÃO
      // =======================================================================
      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        int currentPageId;

        // 🛡️ CORREÇÃO DE LACUNAS: Forçamos o 'page_number' a ser o índice real + 1.
        // Se apagares a Folha 2 de 3, a antiga Folha 3 passa a ser matematicamente a Folha 2 no SQLite!
        final Map<String, dynamic> pageMap = page.toDatabaseMap();
        pageMap['page_number'] = i + 1;

        if (page.id == null) {
          currentPageId = await txn.insert('pages', pageMap);
          page.id = currentPageId;
        } else {
          currentPageId = page.id!;
          await txn.update(
            'pages',
            pageMap,
            where: 'id = ?',
            whereArgs: [currentPageId],
          );
        }

        // 5. GRAVA OS TRAÇOS DA CANETA VETORIAL
        await txn.delete('canvas_strokes', where: 'page_id = ?', whereArgs: [currentPageId]);
        for (var stroke in page.strokes) {
          await txn.insert('canvas_strokes', {
            'client_stroke_id': stroke.id,
            'page_id': currentPageId,
            'stroke_data': stroke.toJsonString(),
            'is_deleted': 0,
            'synced_with_cloud': 0,
          });
        }

        // 6. GRAVA OS BLOCOS DE TEXTO TECLADO
        await txn.delete('canvas_text_blocks', where: 'page_id = ?', whereArgs: [currentPageId]);
        for (var tb in page.textBlocks) {
          await txn.insert('canvas_text_blocks', {
            'client_text_id': tb.id,
            'page_id': currentPageId,
            'text_data': jsonEncode(tb.toMap()),
            'is_deleted': 0,
            'synced_with_cloud': 0,
          });
        }

        // 7. GRAVA AS FOTOGRAFIAS MANIPULÁVEIS
        await txn.delete('canvas_image_blocks', where: 'page_id = ?', whereArgs: [currentPageId]);
        for (var img in page.imageBlocks) {
          await txn.insert('canvas_image_blocks', {
            'client_image_id': img.id,
            'page_id': currentPageId,
            'image_path': img.imageFile.path,
            'pos_x': img.position.dx,
            'pos_y': img.position.dy,
            'scale': img.width,
            'rotation': img.height,
            'is_deleted': 0,
            'synced_with_cloud': 0,
          });
        }
      }
    });
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


  Future<void> saveSingleImageBlock(int pageId, ImageBlock img) async {
    final localDb = LocalDatabaseService();
    await localDb.saveImageBlockLocally(pageId, img); // <--- Tem de chamar o nome exato!
  }
}