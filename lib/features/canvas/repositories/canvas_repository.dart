import 'dart:convert';
import 'dart:async';
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

  // 🔒 Mutex em memória para serializar operações na mesma página (evita Unique Constraint Race)
  final Map<String, Completer<int>> _pageLocks = {};

  // =========================================================================
  // 📖 LER FOLHAS DO CADERNO
  // =========================================================================
  Future<List<LocalPage>> getPagesByNotebook(int notebookId, int? notebookServerId) async {
    final pageRows = await (_db.select(_db.pages)
          ..where((t) => t.notebookId.equals(notebookId) & t.isDeleted.equals(0))
          ..orderBy([
            (t) => OrderingTerm(expression: t.pageNumber),
            (t) => OrderingTerm(expression: t.clientId), // 🚀 DESEMPATE GLOBAL
          ]))
        .get();

    List<LocalPage> pages = [];
    for (var pRow in pageRows) {
      final int pageId = pRow.id;
      final strokeRows = await (_db.select(_db.canvasStrokes)..where((t) => t.pageId.equals(pageId))).get();
      final strokes = strokeRows.map((s) => Stroke.fromJson({
        ...jsonDecode(s.strokeData),
        'updated_at': s.updatedAt,
        'is_deleted': s.isDeleted == 1,
        'deleted_in_session': s.deletedInSession == 1,
        'creator_id': s.creatorId,
      })).toList();

      final textRows = await (_db.select(_db.canvasTextBlocks)..where((t) => t.pageId.equals(pageId))).get();
      final textBlocks = textRows.map((t) => TextBlock.fromJson({
        ...jsonDecode(t.textData),
        'updated_at': t.updatedAt,
        'is_deleted': t.isDeleted == 1,
        'deleted_in_session': t.deletedInSession == 1,
        'creator_id': t.creatorId,
      })).toList();

      final imgRows = await (_db.select(_db.canvasImageBlocks)..where((t) => t.pageId.equals(pageId))).get();
      final imageBlocks = imgRows.map((i) => ImageBlock.fromJson({
        'id': i.clientImageId,
        'image_path': i.imagePath,
        'dx': i.posX,
        'dy': i.posY,
        'width': i.width,
        'height': i.height,
        'rotation': i.rotation,
        'updated_at': i.updatedAt,
        'is_deleted': i.isDeleted == 1,
        'deleted_in_session': i.deletedInSession == 1,
        'creator_id': i.creatorId,
      })).toList();

      pages.add(LocalPage(
        id: pRow.id,
        serverId: pRow.serverId,
        notebookId: pRow.notebookId,
        pageNumber: pRow.pageNumber,
        isLandscape: pRow.isLandscape == 1,
        paperSize: pRow.paperSize,
        clientId: pRow.clientId,
        title: LocalPage.parseMeta(pRow.headerData),
        footer: LocalPage.parseMeta(pRow.footerData),
        extractedText: pRow.extractedText,
        isFrozen: pRow.isFrozen == 1,
        strokes: strokes,
        textBlocks: textBlocks,
        imageBlocks: imageBlocks,
        syncedWithCloud: pRow.syncedWithCloud,
        updatedAt: pRow.updatedAt,
      ));
    }
    return pages;
  }

  Stream<List<LocalPage>> watchPagesByNotebook(int notebookId) {
    return (_db.select(_db.pages)..where((t) => t.notebookId.equals(notebookId))).watch().asyncMap((rows) async {
      List<LocalPage> list = [];
      for (var row in rows) {
        final strokes = await (_db.select(_db.canvasStrokes)..where((t) => t.pageId.equals(row.id))).get();
        final textBlocks = await (_db.select(_db.canvasTextBlocks)..where((t) => t.pageId.equals(row.id))).get();
        final imageBlocks = await (_db.select(_db.canvasImageBlocks)..where((t) => t.pageId.equals(row.id))).get();

        list.add(LocalPage(
          id: row.id,
          serverId: row.serverId,
          notebookId: row.notebookId,
          pageNumber: row.pageNumber,
          isLandscape: row.isLandscape == 1,
          paperSize: row.paperSize,
          clientId: row.clientId,
          title: LocalPage.parseMeta(row.headerData),
          footer: LocalPage.parseMeta(row.footerData),
          extractedText: row.extractedText,
          isFrozen: row.isFrozen == 1,
          isDeleted: row.isDeleted == 1,
          strokes: strokes.map((s) => Stroke.fromJson({...jsonDecode(s.strokeData), 'updated_at': s.updatedAt, 'is_deleted': s.isDeleted == 1, 'deleted_in_session': s.deletedInSession == 1, 'creator_id': s.creatorId})).toList(),
          textBlocks: textBlocks.map((t) => TextBlock.fromJson({...jsonDecode(t.textData), 'updated_at': t.updatedAt, 'is_deleted': t.isDeleted == 1, 'deleted_in_session': t.deletedInSession == 1, 'creator_id': t.creatorId})).toList(),
          imageBlocks: imageBlocks.map((i) => ImageBlock.fromJson({'id': i.clientImageId, 'image_path': i.imagePath, 'dx': i.posX, 'dy': i.posY, 'width': i.width, 'height': i.height, 'rotation': i.rotation, 'updated_at': i.updatedAt, 'is_deleted': i.isDeleted == 1, 'deleted_in_session': i.deletedInSession == 1, 'creator_id': i.creatorId})).toList(),
          syncedWithCloud: row.syncedWithCloud,
          updatedAt: row.updatedAt,
        ));
      }
      return list;
    });
  }

  Future<int> savePage(LocalPage page, int? notebookSid) async {
    final lockKey = page.clientId;
    if (_pageLocks.containsKey(lockKey)) {
      return await _pageLocks[lockKey]!.future;
    }

    final completer = Completer<int>();
    _pageLocks[lockKey] = completer;

    try {
      final id = await _db.transaction(() async {
        // 🚀 LÓGICA ANTI-DUPLICADOS ROBUSTA
        // 1. Procurar todos os registros que possam ser esta página
        final query = _db.select(_db.pages)..where((t) {
          var expr = t.clientId.equals(page.clientId);
          if (page.serverId != null) {
            expr = expr | t.serverId.equals(page.serverId!);
          }
          if (page.id != null) {
            expr = expr | t.id.equals(page.id!);
          }
          return expr;
        });
        
        final candidates = await query.get();
        int? effectiveId;
        
        if (candidates.isEmpty) {
          // Novo registro total
          effectiveId = null;
        } else if (candidates.length == 1) {
          // Caso ideal: encontrou exatamente um
          effectiveId = candidates.first.id;
        } else {
          // 💣 CRISE: Múltiplos registros locais para a mesma página!
          // Escolher o melhor sobrevivente (prioridade para quem tem serverId)
          final survivor = candidates.firstWhere((c) => c.serverId != null, orElse: () => candidates.first);
          effectiveId = survivor.id;
          
          debugPrint('🧨 [Sync-Fix] Detectados ${candidates.length} duplicados para página ${page.pageNumber}. Fundindo no ID $effectiveId...');
          
          for (var cand in candidates) {
            if (cand.id == effectiveId) continue;
            
            // 🛡️ LIMPEZA DE COLISÕES ANTES DA REATRIBUIÇÃO
            // Se o sobrevivente já tem o mesmo stroke/text/image ID, removemos do duplicado
            final strokesInSurvivor = await (_db.select(_db.canvasStrokes)..where((t) => t.pageId.equals(effectiveId!))).get();
            final survivorStrokeIds = strokesInSurvivor.map((s) => s.clientStrokeId).toSet();
            await (_db.delete(_db.canvasStrokes)..where((t) => t.pageId.equals(cand.id) & t.clientStrokeId.isIn(survivorStrokeIds))).go();

            final textsInSurvivor = await (_db.select(_db.canvasTextBlocks)..where((t) => t.pageId.equals(effectiveId!))).get();
            final survivorTextIds = textsInSurvivor.map((t) => t.clientTextId).toSet();
            await (_db.delete(_db.canvasTextBlocks)..where((t) => t.pageId.equals(cand.id) & t.clientTextId.isIn(survivorTextIds))).go();

            final imagesInSurvivor = await (_db.select(_db.canvasImageBlocks)..where((t) => t.pageId.equals(effectiveId!))).get();
            final survivorImageIds = imagesInSurvivor.map((i) => i.clientImageId).toSet();
            await (_db.delete(_db.canvasImageBlocks)..where((t) => t.pageId.equals(cand.id) & t.clientImageId.isIn(survivorImageIds))).go();

            // Reatribuir dados dependentes remanescentes
            await (_db.update(_db.canvasStrokes)..where((t) => t.pageId.equals(cand.id)))
                .write(CanvasStrokesCompanion(pageId: Value(effectiveId!)));
            
            await (_db.update(_db.canvasTextBlocks)..where((t) => t.pageId.equals(cand.id)))
                .write(CanvasTextBlocksCompanion(pageId: Value(effectiveId!)));
                
            await (_db.update(_db.canvasImageBlocks)..where((t) => t.pageId.equals(cand.id)))
                .write(CanvasImageBlocksCompanion(pageId: Value(effectiveId!)));
            
            // Apagar o duplicado
            await (_db.delete(_db.pages)..where((t) => t.id.equals(cand.id))).go();
          }
        }

        final companion = PagesCompanion.insert(
          id: effectiveId != null ? Value(effectiveId) : const Value.absent(),
          serverId: Value(page.serverId),
          clientId: Value(page.clientId),
          notebookId: page.notebookId,
          pageNumber: page.pageNumber,
          isLandscape: Value(page.isLandscape ? 1 : 0),
          headerData: Value(LocalPage.encodeMeta(page.title)),
          footerData: Value(LocalPage.encodeMeta(page.footer)),
          extractedText: Value(page.extractedText),
          isFrozen: Value(page.isFrozen ? 1 : 0),
          paperSize: Value(page.paperSize),
          updatedAt: Value(page.updatedAt),
          syncedWithCloud: Value(page.syncedWithCloud),
        );

        final insertedId = await _db.into(_db.pages).insertOnConflictUpdate(companion);
        
        page.id = insertedId;
        return insertedId;
      });
      completer.complete(id);
      return id;
    } catch (e) {
      completer.completeError(e);
      rethrow;
    } finally {
      _pageLocks.remove(lockKey);
    }
  }

  Future<void> saveSingleStroke(int pageId, Stroke s) async {
    await _db.into(_db.canvasStrokes).insertOnConflictUpdate(CanvasStrokesCompanion.insert(
      clientStrokeId: s.id,
      pageId: pageId,
      strokeData: jsonEncode(s.toJson()),
      isDeleted: Value(s.isDeleted ? 1 : 0),
      deletedInSession: Value(s.deletedInSession ? 1 : 0),
      creatorId: Value(s.creatorId),
      updatedAt: Value(s.updatedAt),
    ));
  }

  Future<void> deleteSingleStroke(int pageId, String strokeId) async {
    await (_db.update(_db.canvasStrokes)..where((t) => t.clientStrokeId.equals(strokeId))).write(const CanvasStrokesCompanion(isDeleted: Value(1)));
  }

  Future<void> saveSingleImageBlock(int pageId, ImageBlock i) async {
    await _db.into(_db.canvasImageBlocks).insertOnConflictUpdate(CanvasImageBlocksCompanion.insert(
      clientImageId: i.id,
      pageId: pageId,
      imagePath: i.imagePath,
      posX: i.position.dx,
      posY: i.position.dy,
      width: i.width,
      height: i.height,
      rotation: i.rotation,
      isDeleted: Value(i.isDeleted ? 1 : 0),
      deletedInSession: Value(i.deletedInSession ? 1 : 0),
      creatorId: Value(i.creatorId),
      updatedAt: Value(i.updatedAt),
    ));
  }

  Future<void> reindexPages(int notebookId) async {
    final all = await (_db.select(_db.pages)..where((t) => t.notebookId.equals(notebookId) & t.isDeleted.equals(0))..orderBy([(t) => OrderingTerm(expression: t.pageNumber), (t) => OrderingTerm(expression: t.clientId)])).get();
    await _db.batch((batch) {
      for (int i = 0; i < all.length; i++) {
        batch.update(_db.pages, PagesCompanion(pageNumber: Value(i + 1)), where: (t) => t.id.equals(all[i].id));
      }
    });
  }

  Future<String?> uploadImage(int notebookId, String fileName, Uint8List bytes) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/notebooks/$notebookId/upload-image');
      final request = http.MultipartRequest('POST', uri);
      final token = await _apiService.getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: fileName));
      final response = await request.send();
      if (response.statusCode == 200) {
        final data = jsonDecode(await response.stream.bytesToString());
        return data['url'];
      }
    } catch (e) { debugPrint('🚨 Erro upload imagem: $e'); }
    return null;
  }

  Future<String?> uploadAudio(int notebookId, String fileName, Uint8List bytes) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/notebooks/$notebookId/upload-audio');
      final request = http.MultipartRequest('POST', uri);
      final token = await _apiService.getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes('audio', bytes, filename: fileName));
      final response = await request.send();
      if (response.statusCode == 200) {
        final data = jsonDecode(await response.stream.bytesToString());
        return data['url'];
      }
    } catch (e) { debugPrint('🚨 Erro upload áudio: $e'); }
    return null;
  }

  Future<String?> uploadLessonAudio(int notebookId, String fileName, Uint8List bytes, {required String title, required int duration, String? clientId}) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/notebooks/$notebookId/upload-audio');
      final request = http.MultipartRequest('POST', uri);
      final token = await _apiService.getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes('audio', bytes, filename: fileName));
      request.fields['title'] = title;
      request.fields['duration'] = duration.toString();
      if (clientId != null) request.fields['client_id'] = clientId;
      final response = await request.send();
      if (response.statusCode == 200) {
        final data = jsonDecode(await response.stream.bytesToString());
        return data['url'];
      }
    } catch (e) { debugPrint('🚨 Erro upload aula: $e'); }
    return null;
  }

  Future<void> updateNotebookMetadata(int notebookId, String lineType, double lineSpacing) async {
    await (_db.update(_db.notebooks)..where((t) => t.id.equals(notebookId))).write(NotebooksCompanion(lineType: Value(lineType), lineSpacing: Value(lineSpacing)));
  }

  Future<void> savePageToCloud(LocalPage page, int notebookSid, String myUserId) async {
    try {
      final payload = await page.toJsonAsync();
      payload['notebook_id'] = notebookSid;
      payload['sender_id'] = myUserId;
      await _apiService.post('/sync/pages/push', {'pages': [payload]});
    } catch (e) { debugPrint('🚨 Cloud save error: $e'); }
  }

  // 🚀 BUSCAR STATUS DA SESSÃO (Para Memória de Partilha)
  Future<Map<String, dynamic>?> fetchSessionStatus(int notebookId) async {
    try {
      final response = await _apiService.get('/notebooks/$notebookId/session/status');
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      debugPrint('🚨 Erro ao buscar status da sessão: $e');
    }
    return null;
  }
}

final canvasRepositoryProvider = Provider<CanvasRepository>((ref) {
  return CanvasRepository(AppDatabase.instance);
});
