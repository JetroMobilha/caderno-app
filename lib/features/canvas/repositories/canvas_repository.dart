import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/api_service.dart';
import '../models/local_page_model.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../models/image_block_model.dart';

class CanvasRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService();

  // =========================================================================
  // 📖 LER FOLHAS DO CADERNO
  // =========================================================================
  Future<List<LocalPage>> getPagesByNotebook(int notebookId, int? notebookServerId) async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> pageMaps = await db.query(
      'pages', where: 'notebook_id = ?', whereArgs: [notebookId], orderBy: 'page_number ASC',
    );

    List<LocalPage> pages = [];

    for (var pMap in pageMaps) {
      final int pageId = pMap['id'] as int;

      final strokeMaps = await db.query('canvas_strokes', where: 'page_id = ? AND is_deleted = 0', whereArgs: [pageId]);
      final strokes = strokeMaps.map((s) => Stroke.fromJsonString(s['stroke_data'] as String)).toList();

      final textMaps = await db.query('canvas_text_blocks', where: 'page_id = ? AND is_deleted = 0', whereArgs: [pageId]);
      final texts = textMaps.map((t) => TextBlock.fromMap(jsonDecode(t['text_data'] as String))).toList();

      final imgMaps = await db.query('canvas_image_blocks', where: 'page_id = ?', whereArgs: [pageId]);
      final images = imgMaps.map((img) => ImageBlock.fromMap({
        'id': img['client_image_id'],
        'image_path': img['image_path'],
        'dx': img['pos_x'],
        'dy': img['pos_y'],
        'width': img['width'] ?? 300.0,
        'height': img['height'] ?? 200.0,
        'rotation': img['rotation'],
      })).toList();

      pages.add(LocalPage.fromDatabaseMap(pMap, strokes: strokes, textBlocks: texts, imageBlocks: images));
    }
    return pages;
  }

  // =========================================================================
  // 📥 SALVAR FOLHAS (BULK) E MICRO-SAVES
  // =========================================================================
  Future<void> savePage(LocalPage page, int? notebookServerId) async {
    final db = await _dbHelper.database;
    await db.transaction((txn) async {
      int currentPageId;
      final Map<String, dynamic> pageMap = page.toDatabaseMap();

      if (page.id == null) {
        currentPageId = await txn.insert('pages', pageMap);
        page.id = currentPageId;
      } else {
        currentPageId = page.id!;
        await txn.update('pages', pageMap, where: 'id = ?', whereArgs: [currentPageId]);
      }

      await txn.delete('canvas_strokes', where: 'page_id = ?', whereArgs: [currentPageId]);
      for (var stroke in List<Stroke>.from(page.strokes)) {
        await txn.insert('canvas_strokes', {
          'client_stroke_id': stroke.id,
          'page_id': currentPageId,
          'stroke_data': stroke.toJsonString(),
          'is_deleted': stroke.isDeleted ? 1 : 0,
          'synced_with_cloud': 0
        });
      }

      await txn.delete('canvas_text_blocks', where: 'page_id = ?', whereArgs: [currentPageId]);
      for (var tb in List<TextBlock>.from(page.textBlocks)) {
        await txn.insert('canvas_text_blocks', {
          'client_text_id': tb.id,
          'page_id': currentPageId,
          'text_data': jsonEncode(tb.toMap()),
          'is_deleted': 0,
          'synced_with_cloud': 0
        });
      }

      await txn.delete('canvas_image_blocks', where: 'page_id = ?', whereArgs: [currentPageId]);
      for (var img in List<ImageBlock>.from(page.imageBlocks)) {
        await txn.insert('canvas_image_blocks', {
          'client_image_id': img.id,
          'page_id': currentPageId,
          'image_path': img.imagePath,
          'pos_x': img.position.dx,
          'pos_y': img.position.dy,
          'width': img.width,
          'height': img.height,
          'rotation': img.rotation,
          'is_deleted': 0,
          'synced_with_cloud': 0
        });
      }
    });
  }

  Future<LocalPage?> createNewPage(int notebookId, int pageNumber, bool isLandscape, int? notebookServerId) async {
    final newPage = LocalPage(notebookId: notebookId, pageNumber: pageNumber, isLandscape: isLandscape, title: 'Folha $pageNumber');
    await savePage(newPage, notebookServerId);
    return newPage;
  }

  Future<void> saveSingleStroke(int pageId, Stroke stroke) async {
    final db = await _dbHelper.database;
    await db.insert('canvas_strokes', {
      'client_stroke_id': stroke.id,
      'page_id': pageId,
      'stroke_data': jsonEncode(stroke.toMap()),
      'synced_with_cloud': 0
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> saveSingleTextBlock(int pageId, TextBlock block) async {
    final db = await _dbHelper.database;
    await db.insert('canvas_text_blocks', {
      'client_text_id': block.id,
      'page_id': pageId,
      'text_data': jsonEncode(block.toMap()),
      'synced_with_cloud': 0
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> deleteSingleStroke(int pageId, String clientStrokeId) async {
    final db = await _dbHelper.database;
    await db.update('canvas_strokes', {'is_deleted': 1, 'synced_with_cloud': 0}, where: 'client_stroke_id = ? AND page_id = ?', whereArgs: [clientStrokeId, pageId]);
  }

  Future<void> saveSingleImageBlock(int pageId, ImageBlock img) async {
    final db = await _dbHelper.database;
    await db.insert('canvas_image_blocks', {
      'client_image_id': img.id,
      'page_id': pageId,
      'image_path': img.imagePath,
      'pos_x': img.position.dx,
      'pos_y': img.position.dy,
      'width': img.width,
      'height': img.height,
      'rotation': img.rotation,
      'is_deleted': 0,
      'synced_with_cloud': 0
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future<void> updatePageMetadata(int pageId, String title, String footer) async {
    final db = await _dbHelper.database;
    await db.update('pages', {
      'header_data': title,
      'footer_data': footer,
      'synced_with_cloud': 0,
      'updated_at': DateTime.now().millisecondsSinceEpoch
    }, where: 'id = ?', whereArgs: [pageId]);
  }

  // =========================================================================
  // 🗑️ DESTRUIÇÃO DE PÁGINA (O Exterminador de Folhas)
  // =========================================================================
  Future<void> deletePage(int pageId) async {
    final db = await _dbHelper.database;
    await db.delete('pages', where: 'id = ?', whereArgs: [pageId]);
    await db.delete('canvas_strokes', where: 'page_id = ?', whereArgs: [pageId]);
    await db.delete('canvas_text_blocks', where: 'page_id = ?', whereArgs: [pageId]);
    await db.delete('canvas_image_blocks', where: 'page_id = ?', whereArgs: [pageId]);
  }

  Future<void> triggerSyncRadar(int pageId) async {
    final db = await _dbHelper.database;
    await db.update('pages', {'synced_with_cloud': 0, 'updated_at': DateTime.now().millisecondsSinceEpoch}, where: 'id = ?', whereArgs: [pageId]);
  }

  // =========================================================================
  // 🚀 SERVER-AUTHORITATIVE SAVE (Ligar ao Laravel)
  // =========================================================================
  Future<bool> savePageToCloud(LocalPage page, int notebookServerId, String myUserId) async {
    try {
      final map = await page.toMapAsync();
      map['notebook_id'] = notebookServerId;
      map['sender_id'] = myUserId; // 🛡️ Crucial para evitar duplicidade no broadcast

      final response = await _apiService.post('/sync/pages/push', {
        'pages': [map]
      });

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('🚨 [Repository] Erro ao salvar na Cloud: $e');
      return false;
    }
  }

  // =========================================================================
  // ☁️ UPLOAD DE IMAGEM PARA O SERVIDOR (Compatível com Web e Mobile)
  // =========================================================================
  Future<String?> uploadImage(int notebookId, String filename, Uint8List bytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('sanctum_token');
      
      final uri = Uri.parse('http://35.205.132.251:8080/api/notebooks/$notebookId/upload-image');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['url'];
      } else {
        debugPrint('❌ Erro no Upload: ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('🚨 Exceção no Upload: $e');
      return null;
    }
  }
}
