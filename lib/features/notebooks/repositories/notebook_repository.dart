import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/services/local_database_service.dart';
import '../../../core/network/api_service.dart'; // 🚀 IMPORTAÇÃO VITAL PARA A WEB
import '../models/local_page_model.dart';
import '../models/notebook_model.dart';
import '../models/drawing_point_model.dart';

class NotebookRepository {
  final _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService(); // 🚀 Rádio de comunicação direta para Web

  // =========================================================================
  // 📚 LISTAR CADERNOS
  // =========================================================================
  Future<List<Notebook>> getNotebooksBySubject(int subjectId) async {
    // 🌐 ROTA WEB: O Consumidor Direto (Lê direto da API Laravel)
    if (kIsWeb) {
      debugPrint('🌐 [Web] A carregar cadernos diretamente do Laravel...');
      final response = await _apiService.get('/subjects/$subjectId/notebooks');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((map) => Notebook.fromMap(map)).toList();
      }
      return [];
    }
    // 📱 ROTA MOBILE/WINDOWS: O Tanque Offline (Lê do SQLite)
    else {
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
    // 🌐 ROTA WEB: Dispara direto para o Laravel
    if (kIsWeb) {
      debugPrint('🌐 [Web] A criar caderno diretamente no Laravel...');
      final response = await _apiService.post(
        '/subjects/${notebook.subject_id}/notebooks',
        notebook.toMap(),
      );

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['id'] as int; // Devolve o ID oficial da Nuvem!
      }
      return 0;
    }
    // 📱 ROTA MOBILE/WINDOWS: Grava no SQLite e espera pelo Radar
    else {
      final db = await _dbHelper.database;
      final id = await db.insert('notebooks', notebook.toMap());
      notebook.id = id;
      return id;
    }
  }

  // =========================================================================
  // 🗑️ APAGAR CADERNO (Soft Delete)
  // =========================================================================
  Future<void> deleteNotebook(int notebookId) async {
    if (kIsWeb) {
      await _apiService.delete('/notebooks/$notebookId');
    } else {
      final db = await _dbHelper.database;
      await db.delete('notebooks', where: 'id = ?', whereArgs: [notebookId]);
      // Opcional: Acordar o SyncService para avisar o Laravel da eliminação
    }
  }

  // =========================================================================
  // 📖 LER FOLHAS DO CADERNO (Ao abrir o Canvas)
  // =========================================================================
  Future<List<LocalPage>> getFullPagesForNotebook(int notebookId) async {
    // 🌐 ROTA WEB: Lê as páginas da API (Com suporte a paginação 'data' da doc!)
    if (kIsWeb) {
      debugPrint('🌐 [Web] A carregar folhas e desenhos diretamente do Laravel...');
      final response = await _apiService.get('/notebooks/$notebookId/pages');

      if (response.statusCode == 200) {
        final jsonResponse = jsonDecode(response.body);
        // A API devolve paginação, os dados reais estão dentro de 'data'
        final List<dynamic> pagesData = jsonResponse['data'] ?? [];
        return pagesData.map((pMap) => LocalPage.fromMap(pMap)).toList();
      }
      return [];
    }
    // 📱 ROTA MOBILE/WINDOWS: Lê do SQLite via LocalDatabaseService
    else {
      final localDb = LocalDatabaseService();
      return await localDb.getFullPagesForNotebook(notebookId);
    }
  }

  // ============================================================================
  // 📥 ESTRATÉGIA 1: BULK SAVE (Mobile Only)
  // ============================================================================
  Future<void> saveFullNotebook(int notebookId, List<LocalPage> pages) async {
    if (kIsWeb) return; // A Web usa micro-saves diretos (Estratégia 2)

    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      final List<Map<String, dynamic>> existingRows = await txn.query('pages', columns: ['id'], where: 'notebook_id = ?', whereArgs: [notebookId]);
      final List<int> existingIds = existingRows.map((row) => row['id'] as int).toList();
      final List<int> currentIds = pages.map((page) => page.id).whereType<int>().toList();

      for (final int id in existingIds) {
        if (!currentIds.contains(id)) {
          await txn.delete('pages', where: 'id = ?', whereArgs: [id]);
        }
      }

      for (int i = 0; i < pages.length; i++) {
        final page = pages[i];
        int currentPageId;

        final Map<String, dynamic> pageMap = page.toDatabaseMap();
        pageMap['page_number'] = i + 1;

        if (page.id == null) {
          currentPageId = await txn.insert('pages', pageMap);
          page.id = currentPageId;
        } else {
          currentPageId = page.id!;
          await txn.update('pages', pageMap, where: 'id = ?', whereArgs: [currentPageId]);
        }

        await txn.delete('canvas_strokes', where: 'page_id = ?', whereArgs: [currentPageId]);
        for (var stroke in page.strokes) {
          await txn.insert('canvas_strokes', {'client_stroke_id': stroke.id, 'page_id': currentPageId, 'stroke_data': stroke.toJsonString(), 'is_deleted': 0, 'synced_with_cloud': 0});
        }

        await txn.delete('canvas_text_blocks', where: 'page_id = ?', whereArgs: [currentPageId]);
        for (var tb in page.textBlocks) {
          await txn.insert('canvas_text_blocks', {'client_text_id': tb.id, 'page_id': currentPageId, 'text_data': jsonEncode(tb.toMap()), 'is_deleted': 0, 'synced_with_cloud': 0});
        }

        await txn.delete('canvas_image_blocks', where: 'page_id = ?', whereArgs: [currentPageId]);
        for (var img in page.imageBlocks) {
          await txn.insert('canvas_image_blocks', {'client_image_id': img.id, 'page_id': currentPageId, 'image_path': img.imagePath, 'pos_x': img.position.dx, 'pos_y': img.position.dy, 'scale': img.width, 'rotation': img.height, 'is_deleted': 0, 'synced_with_cloud': 0});
        }
      }
    });
  }

  // ============================================================================
  // ⚡ ESTRATÉGIA 2: MICRO-SAVES (Para máxima performance no onPanEnd)
  // ============================================================================
  Future<void> saveSingleStroke(int pageId, Stroke stroke) async {
    if (kIsWeb) return;
    final db = await _dbHelper.database;
    await db.insert('canvas_strokes', {'client_stroke_id': stroke.id, 'page_id': pageId, 'stroke_data': jsonEncode(stroke.toMap()), 'synced_with_cloud': 0}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveSingleTextBlock(int pageId, TextBlock block) async {
    if (kIsWeb) return;
    final db = await _dbHelper.database;
    await db.insert('canvas_text_blocks', {'client_text_id': block.id, 'page_id': pageId, 'text_data': jsonEncode(block.toMap()), 'synced_with_cloud': 0}, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSingleStroke(int pageId, String clientStrokeId) async {
    if (kIsWeb) return;
    final db = await _dbHelper.database;
    await db.update('canvas_strokes', {'is_deleted': 1, 'synced_with_cloud': 0}, where: 'client_stroke_id = ? AND page_id = ?', whereArgs: [clientStrokeId, pageId]);
  }

  Future<void> saveSingleImageBlock(int pageId, ImageBlock img) async {
    if (kIsWeb) return; // Na Web a imagem deve subir via API direto com os metadados
    final localDb = LocalDatabaseService();
    await localDb.saveImageBlockLocally(pageId, img);
  }

  Future<void> updateLineType(int notebookId, String newLineType) async {
    if (kIsWeb) return;
    final db = await _dbHelper.database;
    await db.update('notebooks', {'line_type': newLineType, 'updated_at': DateTime.now().millisecondsSinceEpoch}, where: 'id = ?', whereArgs: [notebookId]);
  }

  Future<void> updatePageMetadata(int pageId, String title, String footer) async {
    if (kIsWeb) return;
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query('pages', columns: ['server_id'], where: 'id = ?', whereArgs: [pageId]);
    int? officialServerId;
    if (existing.isNotEmpty) officialServerId = existing.first['server_id'] as int?;

    await db.update('pages', {'header_data': title, 'footer_data': footer, 'server_id': officialServerId, 'synced_with_cloud': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch}, where: 'id = ?', whereArgs: [pageId]);
  }

  // =========================================================================
  // 🚨 GATILHO DO AUTO-SAVE PARA WEB E MOBILE
  // =========================================================================
  Future<void> triggerSyncRadar(int pageId, {LocalPage? webPagePayload}) async {
    // 🌐 ROTA WEB: Atira a folha completa para a nuvem em tempo real!
    if (kIsWeb && webPagePayload != null) {
      debugPrint('🌐 [Web] A gravar traço/imagem diretamente na Nuvem...');

      // 🚀 ALTERAÇÃO VITAL AQUI: Usa o toMapAsync e aguarda!
      final payload = await webPagePayload.toMapAsync();

      await _apiService.post(
        '/notebooks/${webPagePayload.notebookId}/pages',
        payload,
      );
      return;
    }

    // 📱 ROTA MOBILE: Acorda o radar local
    final db = await DatabaseHelper.instance.database;
    final existing = await db.query('pages', columns: ['server_id'], where: 'id = ?', whereArgs: [pageId]);
    int? officialServerId;
    if (existing.isNotEmpty) officialServerId = existing.first['server_id'] as int?;

    await db.update('pages', {'server_id': officialServerId, 'synced_with_cloud': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch}, where: 'id = ?', whereArgs: [pageId]);
  }

  Future<bool> shareNotebookWithFriend({required int notebookId, required String email, required String role}) async {
    try {
      final response = await ApiService().post(
        '/notebooks/$notebookId/share',
        {
          'email': email,
          'role': role,
        },
        requireAuth: true,
      );

      // Devolve true apenas se o Laravel responder status 200 OK
      return response.statusCode == 200;
    } catch (e) {
      print('🚨 Erro ao partilhar nas rotas da API: $e');
      return false;
    }
  }

}