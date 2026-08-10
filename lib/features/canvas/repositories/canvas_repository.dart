import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/database/app_database.dart' hide User, Subject, Notebook, Page;
import '../../../core/network/api_config.dart';
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
          ..where((t) => t.notebookId.equals(notebookId) & t.isDeleted.equals(0))
          ..orderBy([
            (t) => OrderingTerm(expression: t.pageNumber),
            (t) => OrderingTerm(expression: t.clientId), // 🚀 DESEMPATE GLOBAL: Garante ordem idêntica em todos os aparelhos
          ]))
        .get();

    List<LocalPage> pages = [];

    for (var pRow in pageRows) {
      final int pageId = pRow.id;

      final strokeRows = await (_db.select(_db.canvasStrokes)
            ..where((t) => t.pageId.equals(pageId)))
          .get();
      final strokes = strokeRows.map((s) => Stroke.fromJson({
        ...jsonDecode(s.strokeData),
        'updated_at': s.updatedAt,
        'is_deleted': s.isDeleted == 1,
        'deleted_in_session': s.deletedInSession == 1,
        'creator_id': s.creatorId,
      })).toList();

      final textRows = await (_db.select(_db.canvasTextBlocks)
            ..where((t) => t.pageId.equals(pageId)))
          .get();
      final texts = textRows.map((t) => TextBlock.fromJson({
        ...jsonDecode(t.textData),
        'updated_at': t.updatedAt,
        'is_deleted': t.isDeleted == 1,
        'deleted_in_session': t.deletedInSession == 1,
        'creator_id': t.creatorId,
      })).toList();

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
        'updated_at': img.updatedAt,
        'is_deleted': img.isDeleted == 1,
        'deleted_in_session': img.deletedInSession == 1,
        'creator_id': img.creatorId,
      })).toList();

      pages.add(LocalPage(
        id: pRow.id,
        serverId: pRow.serverId,
        clientId: pRow.clientId,
        notebookId: pRow.notebookId,
        pageNumber: pRow.pageNumber,
        isLandscape: pRow.isLandscape == 1,
        paperSize: pRow.paperSize,
        isFrozen: pRow.isFrozen == 1,
        title: LocalPage.parseMeta(pRow.headerData),
        footer: LocalPage.parseMeta(pRow.footerData),
        extractedText: pRow.extractedText,
        syncedWithCloud: pRow.syncedWithCloud,
        strokes: strokes,
        textBlocks: texts,
        imageBlocks: images,
        updatedAt: pRow.updatedAt,
      ));
    }
    return pages;
  }

  // =========================================================================
  // 🔄 RE-INDEXAR PÁGINAS (CORREÇÃO DE CONFLITOS)
  // =========================================================================
  Future<void> reindexPages(int notebookId) async {
    await _db.transaction(() async {
      // 1. Buscar todas as páginas (incluindo as marcadas como deletadas se necessário, 
      // mas aqui focamos nas ativas para a numeração do usuário)
      final allPages = await (_db.select(_db.pages)
            ..where((t) => t.notebookId.equals(notebookId) & t.isDeleted.equals(0))
            ..orderBy([
              (t) => OrderingTerm(expression: t.pageNumber),
              (t) => OrderingTerm(expression: t.clientId), // 🚀 CRUCIAL: UUID como critério de desempate universal
            ]))
          .get();

      for (int i = 0; i < allPages.length; i++) {
        final expectedNumber = i + 1;
        if (allPages[i].pageNumber != expectedNumber) {
          debugPrint('🔧 [Repository] Corrigindo página ${allPages[i].id}: ${allPages[i].pageNumber} -> $expectedNumber');
          await (_db.update(_db.pages)..where((t) => t.id.equals(allPages[i].id))).write(
            PagesCompanion(
              pageNumber: Value(expectedNumber),
              syncedWithCloud: const Value(0), // Marcar para subir a correção
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            ),
          );
        }
      }
    });
  }

  // =========================================================================
  // 📡 ASSINAR PÁGINAS DO CADERNO (REATIVO)
  // =========================================================================
  Stream<List<LocalPage>> watchPagesByNotebook(int notebookId) {
    // 🚀 REATIVIDADE TOTAL: Observar as 4 tabelas principais
    final stream = _db.select(_db.pages).join([
      leftOuterJoin(_db.canvasStrokes, _db.canvasStrokes.pageId.equalsExp(_db.pages.id)),
      leftOuterJoin(_db.canvasTextBlocks, _db.canvasTextBlocks.pageId.equalsExp(_db.pages.id)),
      leftOuterJoin(_db.canvasImageBlocks, _db.canvasImageBlocks.pageId.equalsExp(_db.pages.id)),
    ]).watch();

    return stream.asyncMap((_) async {
      return getPagesByNotebook(notebookId, null);
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
                clientId: Value(page.clientId),
                isLandscape: Value(page.isLandscape ? 1 : 0),
                isFrozen: Value(page.isFrozen ? 1 : 0),
                paperSize: Value(page.paperSize),
                headerData: Value(LocalPage.encodeMeta(page.title)),
                footerData: Value(LocalPage.encodeMeta(page.footer)),
                extractedText: Value(page.extractedText),
                syncedWithCloud: Value(page.syncedWithCloud),
                updatedAt: Value(page.updatedAt),
              ),
            );
        page.id = currentPageId;
      } else {
        currentPageId = page.id!;
        await (_db.update(_db.pages)..where((t) => t.id.equals(currentPageId))).write(
          PagesCompanion(
            headerData: Value(LocalPage.encodeMeta(page.title)),
            footerData: Value(LocalPage.encodeMeta(page.footer)),
            extractedText: Value(page.extractedText),
            isLandscape: Value(page.isLandscape ? 1 : 0),
            paperSize: Value(page.paperSize),
            syncedWithCloud: Value(page.syncedWithCloud),
            updatedAt: Value(page.updatedAt),
          ),
        );
      }

      for (var stroke in List<Stroke>.from(page.strokes)) {
        await _db.into(_db.canvasStrokes).insertOnConflictUpdate(
              CanvasStrokesCompanion.insert(
                clientStrokeId: stroke.id,
                pageId: currentPageId,
                strokeData: stroke.toJsonString(),
                isDeleted: Value(stroke.isDeleted ? 1 : 0),
                deletedInSession: Value(stroke.deletedInSession ? 1 : 0),
                updatedAt: Value(stroke.updatedAt),
                creatorId: Value(stroke.creatorId),
                syncedWithCloud: const Value(0),
              ),
            );
      }

      for (var tb in List<TextBlock>.from(page.textBlocks)) {
        await _db.into(_db.canvasTextBlocks).insertOnConflictUpdate(
              CanvasTextBlocksCompanion.insert(
                clientTextId: tb.id,
                pageId: currentPageId,
                textData: jsonEncode(tb.toJson()),
                isDeleted: Value(tb.isDeleted ? 1 : 0),
                deletedInSession: Value(tb.deletedInSession ? 1 : 0),
                updatedAt: Value(tb.updatedAt),
                creatorId: Value(tb.creatorId),
                syncedWithCloud: const Value(0),
              ),
            );
      }

      for (var img in List<ImageBlock>.from(page.imageBlocks)) {
        await _db.into(_db.canvasImageBlocks).insertOnConflictUpdate(
              CanvasImageBlocksCompanion.insert(
                clientImageId: img.id,
                pageId: currentPageId,
                imagePath: img.imagePath,
                posX: img.position.dx,
                posY: img.position.dy,
                width: img.width,
                height: img.height,
                rotation: img.rotation,
                isDeleted: Value(img.isDeleted ? 1 : 0),
                deletedInSession: Value(img.deletedInSession ? 1 : 0),
                updatedAt: Value(img.updatedAt),
                creatorId: Value(img.creatorId),
                syncedWithCloud: const Value(0),
              ),
            );
      }
    });
  }

  Future<LocalPage?> createNewPage(int notebookId, int pageNumber, bool isLandscape, int? notebookServerId) async {
    final newPage = LocalPage(notebookId: notebookId, pageNumber: pageNumber, isLandscape: isLandscape);
    await savePage(newPage, notebookServerId);
    return newPage;
  }

  Future<void> saveSingleStroke(int pageId, Stroke stroke) async {
    await _db.into(_db.canvasStrokes).insertOnConflictUpdate(
      CanvasStrokesCompanion.insert(
        clientStrokeId: stroke.id,
        pageId: pageId,
        strokeData: jsonEncode(stroke.toJson()),
        isDeleted: Value(stroke.isDeleted ? 1 : 0),
        deletedInSession: Value(stroke.deletedInSession ? 1 : 0),
        updatedAt: Value(stroke.updatedAt),
        creatorId: Value(stroke.creatorId),
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
        isDeleted: Value(block.isDeleted ? 1 : 0),
        deletedInSession: Value(block.deletedInSession ? 1 : 0),
        updatedAt: Value(block.updatedAt),
        creatorId: Value(block.creatorId),
        syncedWithCloud: const Value(0),
      ),
    );
  }

  Future<void> deleteSingleStroke(int pageId, String clientStrokeId) async {
    await (_db.update(_db.canvasStrokes)
          ..where((t) => t.clientStrokeId.equals(clientStrokeId) & t.pageId.equals(pageId)))
        .write(CanvasStrokesCompanion(
          isDeleted: const Value(1), 
          syncedWithCloud: const Value(0),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
        ));
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
        isDeleted: Value(img.isDeleted ? 1 : 0),
        deletedInSession: Value(img.deletedInSession ? 1 : 0),
        updatedAt: Value(img.updatedAt),
        creatorId: Value(img.creatorId),
        syncedWithCloud: const Value(0),
      ),
    );
  }

  Future<void> deletePage(int pageId) async {
    await (_db.update(_db.pages)..where((t) => t.id.equals(pageId))).write(
      PagesCompanion(
        isDeleted: const Value(1),
        syncedWithCloud: const Value(0),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> restorePage(int pageId) async {
    await (_db.update(_db.pages)..where((t) => t.id.equals(pageId))).write(
      PagesCompanion(
        isDeleted: const Value(0),
        syncedWithCloud: const Value(0),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<void> updateNotebookMetadata(int notebookId, String lineType, double lineSpacing) async {
    await (_db.update(_db.notebooks)..where((t) => t.id.equals(notebookId))).write(
      NotebooksCompanion(
        lineType: Value(lineType),
        lineSpacing: Value(lineSpacing),
        syncedWithCloud: const Value(0),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  Future<bool> savePageToCloud(LocalPage page, int notebookServerId, String myUserId) async {
    try {
      final Map<String, dynamic> map = await page.toJsonAsync();
      final simplifiedStrokes = page.strokes.map((s) => s.simplify(epsilon: 0.2)).toList();
      map['stroke_data'] = simplifiedStrokes.map((s) => s.toJson()).toList();
      map['notebook_id'] = notebookServerId;
      map['sender_id'] = myUserId;

      final response = await _apiService.post('/sync/pages/push', {
        'pages': [map]
      });

      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('🚨 [Repository] Erro ao salvar na Cloud: $e');
      return false;
    }
  }

  Future<String?> uploadAudio(int notebookServerId, String filename, Uint8List bytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('sanctum_token');
      final uri = Uri.parse('${ApiConfig.baseUrl}/notebooks/$notebookServerId/upload-audio');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..files.add(http.MultipartFile.fromBytes('audio', bytes, filename: filename));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadLessonAudio(int notebookServerId, String filename, Uint8List bytes, {String? title, int? duration, String? clientId}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('sanctum_token');
      final uri = Uri.parse('${ApiConfig.baseUrl}/notebooks/$notebookServerId/upload-audio');
      
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..files.add(http.MultipartFile.fromBytes('audio', bytes, filename: filename));
      
      if (title != null) request.fields['title'] = title;
      if (duration != null) request.fields['duration'] = duration.toString();
      if (clientId != null) request.fields['client_id'] = clientId;

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<String?> uploadImage(int notebookServerId, String filename, Uint8List bytes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final String? token = prefs.getString('sanctum_token');
      final uri = Uri.parse('${ApiConfig.baseUrl}/notebooks/$notebookServerId/upload-image');
      final request = http.MultipartRequest('POST', uri)
        ..headers['Authorization'] = 'Bearer $token'
        ..headers['Accept'] = 'application/json'
        ..files.add(http.MultipartFile.fromBytes('image', bytes, filename: filename));
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return data['url'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}

final canvasRepositoryProvider = Provider<CanvasRepository>((ref) {
  return CanvasRepository(AppDatabase.instance);
});
