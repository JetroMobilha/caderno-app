import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/app_database.dart' hide User, Subject, Notebook, Page;
import '../../../core/network/api_service.dart';
import '../models/local_page_model.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../models/image_block_model.dart';

class CanvasRepository {
  final AppDatabase _db;
  final ApiService _apiService = ApiService();

  CanvasRepository(this._db);

  // =========================================================================
  // 📖 LER FOLHAS DO CADERNO
  // =========================================================================
  Future<List<LocalPage>> getPagesByNotebook(int notebookId, int? notebookServerId) async {
    final pageRows = await (_db.select(_db.pages)
          ..where((t) => t.notebookId.equals(notebookId))
          ..orderBy([(t) => OrderingTerm(expression: t.pageNumber)]))
        .get();

    List<LocalPage> pages = [];

    for (var pRow in pageRows) {
      final int pageId = pRow.id;

      final strokeRows = await (_db.select(_db.canvasStrokes)
            ..where((t) => t.pageId.equals(pageId) & t.isDeleted.equals(0)))
          .get();
      final strokes = strokeRows.map((s) => Stroke.fromJsonString(s.strokeData)).toList();

      final textRows = await (_db.select(_db.canvasTextBlocks)
            ..where((t) => t.pageId.equals(pageId) & t.isDeleted.equals(0)))
          .get();
      final texts = textRows.map((t) => TextBlock.fromJson(jsonDecode(t.textData))).toList();

      final imgRows = await (_db.select(_db.canvasImageBlocks)
            ..where((t) => t.pageId.equals(pageId)))
          .get();
      final images = imgRows.map((img) => ImageBlock.fromJson({
        'id': img.clientImageId,
        'image_path': img.imagePath,
        'dx': img.posX,
        'dy': img.posY,
        'width': img.width,
        'height': img.height,
        'rotation': img.rotation,
      })).toList();

      pages.add(LocalPage(
        id: pRow.id,
        serverId: pRow.serverId,
        notebookId: pRow.notebookId,
        pageNumber: pRow.pageNumber,
        isLandscape: pRow.isLandscape == 1,
        title: pRow.headerData ?? '',
        footer: pRow.footerData ?? '',
        extractedText: pRow.extractedText,
        syncedWithCloud: pRow.syncedWithCloud,
        strokes: strokes,
        textBlocks: texts,
        imageBlocks: images,
      ));
    }
    return pages;
  }

  // =========================================================================
  // 📡 ASSINAR PÁGINAS DO CADERNO (REATIVO)
  // =========================================================================
  Stream<List<LocalPage>> watchPagesByNotebook(int notebookId) {
    return (_db.select(_db.pages)
          ..where((t) => t.notebookId.equals(notebookId))
          ..orderBy([(t) => OrderingTerm(expression: t.pageNumber)]))
        .watch()
        .asyncMap((pageRows) async {
      List<LocalPage> fullPages = [];
      for (var pRow in pageRows) {
        final int pageId = pRow.id;

        final strokeRows = await (_db.select(_db.canvasStrokes)
              ..where((t) => t.pageId.equals(pageId) & t.isDeleted.equals(0)))
            .get();
        final strokes = strokeRows.map((s) => Stroke.fromJsonString(s.strokeData)).toList();

        final textRows = await (_db.select(_db.canvasTextBlocks)
              ..where((t) => t.pageId.equals(pageId) & t.isDeleted.equals(0)))
            .get();
        final texts = textRows.map((t) => TextBlock.fromJson(jsonDecode(t.textData))).toList();

        final imgRows = await (_db.select(_db.canvasImageBlocks)
              ..where((t) => t.pageId.equals(pageId)))
            .get();
        final images = imgRows.map((img) => ImageBlock.fromJson({
          'id': img.clientImageId,
          'image_path': img.imagePath,
          'dx': img.posX,
          'dy': img.posY,
          'width': img.width,
          'height': img.height,
          'rotation': img.rotation,
        })).toList();

        fullPages.add(LocalPage(
          id: pRow.id,
          serverId: pRow.serverId,
          notebookId: pRow.notebookId,
          pageNumber: pRow.pageNumber,
          isLandscape: pRow.isLandscape == 1,
          title: pRow.headerData ?? '',
          footer: pRow.footerData ?? '',
          syncedWithCloud: pRow.syncedWithCloud,
          strokes: strokes,
          textBlocks: texts,
          imageBlocks: images,
        ));
      }
      return fullPages;
    });
  }

  // =========================================================================
  // 📥 SALVAR FOLHAS (BULK) E MICRO-SAVES
  // =========================================================================
  Future<void> savePage(LocalPage page, int? notebookServerId) async {
    await _db.transaction(() async {
      int currentPageId;

      if (page.id == null) {
        currentPageId = await _db.into(_db.pages).insert(
              PagesCompanion.insert(
                notebookId: page.notebookId,
                pageNumber: page.pageNumber,
                isLandscape: Value(page.isLandscape ? 1 : 0),
                headerData: Value(page.title),
                footerData: Value(page.footer),
                extractedText: Value(page.extractedText),
                syncedWithCloud: Value(page.syncedWithCloud),
              ),
            );
        page.id = currentPageId;
      } else {
        currentPageId = page.id!;
        await (_db.update(_db.pages)..where((t) => t.id.equals(currentPageId))).write(
          PagesCompanion(
            headerData: Value(page.title),
            footerData: Value(page.footer),
            extractedText: Value(page.extractedText),
            syncedWithCloud: Value(page.syncedWithCloud),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
        );
      }

      await (_db.delete(_db.canvasStrokes)..where((t) => t.pageId.equals(currentPageId))).go();
      for (var stroke in List<Stroke>.from(page.strokes)) {
        await _db.into(_db.canvasStrokes).insert(
              CanvasStrokesCompanion.insert(
                clientStrokeId: stroke.id,
                pageId: currentPageId,
                strokeData: stroke.toJsonString(),
                isDeleted: Value(stroke.isDeleted ? 1 : 0),
                syncedWithCloud: const Value(0),
              ),
            );
      }

      await (_db.delete(_db.canvasTextBlocks)..where((t) => t.pageId.equals(currentPageId))).go();
      for (var tb in List<TextBlock>.from(page.textBlocks)) {
        await _db.into(_db.canvasTextBlocks).insert(
              CanvasTextBlocksCompanion.insert(
                clientTextId: tb.id,
                pageId: currentPageId,
                textData: jsonEncode(tb.toJson()),
                isDeleted: const Value(0),
                syncedWithCloud: const Value(0),
              ),
            );
      }

      await (_db.delete(_db.canvasImageBlocks)..where((t) => t.pageId.equals(currentPageId))).go();
      for (var img in List<ImageBlock>.from(page.imageBlocks)) {
        await _db.into(_db.canvasImageBlocks).insert(
              CanvasImageBlocksCompanion.insert(
                clientImageId: img.id,
                pageId: currentPageId,
                imagePath: img.imagePath,
                posX: img.position.dx,
                posY: img.position.dy,
                width: img.width,
                height: img.height,
                rotation: img.rotation,
                isDeleted: const Value(0),
                syncedWithCloud: const Value(0),
              ),
            );
      }
    });
  }

  Future<LocalPage?> createNewPage(int notebookId, int pageNumber, bool isLandscape, int? notebookServerId) async {
    final newPage = LocalPage(notebookId: notebookId, pageNumber: pageNumber, isLandscape: isLandscape, title: 'Folha $pageNumber');
    await savePage(newPage, notebookServerId);
    return newPage;
  }

  Future<void> saveSingleStroke(int pageId, Stroke stroke) async {
    await _db.into(_db.canvasStrokes).insertOnConflictUpdate(
      CanvasStrokesCompanion.insert(
        clientStrokeId: stroke.id,
        pageId: pageId,
        strokeData: jsonEncode(stroke.toJson()),
        syncedWithCloud: const Value(0),
      ),
    );
  }

  Future<void> saveSingleTextBlock(int pageId, TextBlock block) async {
    await _db.into(_db.canvasTextBlocks).insertOnConflictUpdate(
      CanvasTextBlocksCompanion.insert(
        clientTextId: block.id,
        pageId: pageId,
        textData: jsonEncode(block.toJson()),
        syncedWithCloud: const Value(0),
      ),
    );
  }

  Future<void> deleteSingleStroke(int pageId, String clientStrokeId) async {
    await (_db.update(_db.canvasStrokes)
          ..where((t) => t.clientStrokeId.equals(clientStrokeId) & t.pageId.equals(pageId)))
        .write(const CanvasStrokesCompanion(isDeleted: Value(1), syncedWithCloud: Value(0)));
  }

  Future<void> saveSingleImageBlock(int pageId, ImageBlock img) async {
    await _db.into(_db.canvasImageBlocks).insertOnConflictUpdate(
      CanvasImageBlocksCompanion.insert(
        clientImageId: img.id,
        pageId: pageId,
        imagePath: img.imagePath,
        posX: img.position.dx,
        posY: img.position.dy,
        width: img.width,
        height: img.height,
        rotation: img.rotation,
        isDeleted: const Value(0),
        syncedWithCloud: const Value(0),
      ),
    );
  }

  Future<void> updatePageMetadata(int pageId, String title, String footer, {String? extractedText}) async {
    await (_db.update(_db.pages)..where((t) => t.id.equals(pageId))).write(
      PagesCompanion(
        headerData: Value(title),
        footerData: Value(footer),
        extractedText: Value(extractedText),
        syncedWithCloud: const Value(0),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  // =========================================================================
  // 🗑️ DESTRUIÇÃO DE PÁGINA (O Exterminador de Folhas)
  // =========================================================================
  Future<void> deletePage(int pageId) async {
    await (_db.delete(_db.pages)..where((t) => t.id.equals(pageId))).go();
    await (_db.delete(_db.canvasStrokes)..where((t) => t.pageId.equals(pageId))).go();
    await (_db.delete(_db.canvasTextBlocks)..where((t) => t.pageId.equals(pageId))).go();
    await (_db.delete(_db.canvasImageBlocks)..where((t) => t.pageId.equals(pageId))).go();
  }

  Future<void> triggerSyncRadar(int pageId) async {
    await (_db.update(_db.pages)..where((t) => t.id.equals(pageId))).write(
      PagesCompanion(
        syncedWithCloud: const Value(0),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  // =========================================================================
  // 🚀 SERVER-AUTHORITATIVE SAVE (Ligar ao Laravel)
  // =========================================================================
  Future<bool> savePageToCloud(LocalPage page, int notebookServerId, String myUserId) async {
    try {
      final map = await page.toJsonAsync();
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
      
      final uri = Uri.parse('https://appcaderno.duckdns.org:9000/api/notebooks/$notebookId/upload-image');
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

final canvasRepositoryProvider = Provider<CanvasRepository>((ref) {
  return CanvasRepository(AppDatabase.instance);
});
