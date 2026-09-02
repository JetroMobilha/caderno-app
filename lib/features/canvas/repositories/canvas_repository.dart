import 'dart:convert';
import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../../core/database/app_database.dart' hide User, Subject, Notebook, Page;
import '../../../core/network/api_service.dart';
import '../../../core/network/time_service.dart';
import '../../notebooks/models/notebook_configuration.dart';
import '../models/local_page_model.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../models/image_block_model.dart';

class CanvasRepository {
  final AppDatabase _db;
  final ApiService _apiService = ApiService();

  CanvasRepository(this._db);

  AppDatabase get db => _db;

  // =========================================================================
  // 📖 LER FOLHA ÚNICA (Otimizado para Sync)
  // =========================================================================
  Future<LocalPage?> getPageByClientId(String clientId, {bool onlyUnsynced = false}) async {
    final pRow = await (_db.select(_db.pages)..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    if (pRow == null) return null;

    final int pageId = pRow.id;
    
    // 🚀 OTIMIZAÇÃO: Filtrar por syncedWithCloud se solicitado
    final strokeQuery = _db.select(_db.canvasStrokes)..where((t) => t.pageId.equals(pageId));
    if (onlyUnsynced) strokeQuery.where((t) => t.syncedWithCloud.equals(0));
    final strokeRows = await strokeQuery.get();

    final strokes = strokeRows.map((s) => Stroke.fromJson({
      ...jsonDecode(s.strokeData),
      'updated_at': s.updatedAt,
      'is_deleted': s.isDeleted == 1,
      'deleted_in_session': s.deletedInSession == 1,
      'creator_id': s.creatorId,
      'synced_with_cloud': s.syncedWithCloud == 1,
      'page_number': pRow.pageNumber,
    })).toList();

    final textQuery = _db.select(_db.canvasTextBlocks)..where((t) => t.pageId.equals(pageId));
    if (onlyUnsynced) textQuery.where((t) => t.syncedWithCloud.equals(0));
    final textRows = await textQuery.get();

    final textBlocks = textRows.map((t) => TextBlock.fromJson({
      ...jsonDecode(t.textData),
      'updated_at': t.updatedAt,
      'is_deleted': t.isDeleted == 1,
      'deleted_in_session': t.deletedInSession == 1,
      'creator_id': t.creatorId,
      'synced_with_cloud': t.syncedWithCloud == 1,
      'page_number': pRow.pageNumber,
    })).toList();

    final imageQuery = _db.select(_db.canvasImageBlocks)..where((t) => t.pageId.equals(pageId));
    if (onlyUnsynced) imageQuery.where((t) => t.syncedWithCloud.equals(0));
    final imgRows = await imageQuery.get();

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
      'synced_with_cloud': i.syncedWithCloud == 1,
      'page_number': pRow.pageNumber,
    })).toList();

    return LocalPage(
      id: pRow.id,
      serverId: pRow.serverId,
      notebookId: pRow.notebookId,
      pageNumber: pRow.pageNumber,
      isLandscape: pRow.isLandscape == 1,
      paperSize: pRow.paperSize,
      lineType: pRow.lineType,
      lineSpacing: pRow.lineSpacing,
      clientId: pRow.clientId,
      title: LocalPage.parseMeta(pRow.headerData),
      sectionTitle: LocalPage.parseSection(pRow.headerData),
      sectionColor: LocalPage.parseSectionColor(pRow.headerData),
      footer: LocalPage.parseMeta(pRow.footerData),
      extractedText: pRow.extractedText,
      isFrozen: pRow.isFrozen == 1,
      isFavorite: pRow.isFavorite == 1,
      objects: [...strokes, ...textBlocks, ...imageBlocks],
      backgroundConfig: pRow.backgroundConfig != null ? BackgroundConfig.fromJson(jsonDecode(pRow.backgroundConfig!)) : null,
      syncedWithCloud: pRow.syncedWithCloud,
      updatedAt: pRow.updatedAt,
    );
  }

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
        'synced_with_cloud': s.syncedWithCloud == 1,
        'page_number': pRow.pageNumber,
      })).toList();

      final textRows = await (_db.select(_db.canvasTextBlocks)..where((t) => t.pageId.equals(pageId))).get();
      final textBlocks = textRows.map((t) => TextBlock.fromJson({
        ...jsonDecode(t.textData),
        'updated_at': t.updatedAt,
        'is_deleted': t.isDeleted == 1,
        'deleted_in_session': t.deletedInSession == 1,
        'creator_id': t.creatorId,
        'synced_with_cloud': t.syncedWithCloud == 1,
        'page_number': pRow.pageNumber,
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
        'synced_with_cloud': i.syncedWithCloud == 1,
        'page_number': pRow.pageNumber,
      })).toList();

      pages.add(LocalPage(
        id: pRow.id,
        serverId: pRow.serverId,
        notebookId: pRow.notebookId,
        pageNumber: pRow.pageNumber,
        isLandscape: pRow.isLandscape == 1,
        paperSize: pRow.paperSize,
        lineType: pRow.lineType,
        lineSpacing: pRow.lineSpacing,
        clientId: pRow.clientId,
        title: LocalPage.parseMeta(pRow.headerData),
        sectionTitle: LocalPage.parseSection(pRow.headerData),
        sectionColor: LocalPage.parseSectionColor(pRow.headerData),
        footer: LocalPage.parseMeta(pRow.footerData),
        extractedText: pRow.extractedText,
        isFrozen: pRow.isFrozen == 1,
        isFavorite: pRow.isFavorite == 1,
        objects: [...strokes, ...textBlocks, ...imageBlocks],
        backgroundConfig: pRow.backgroundConfig != null ? BackgroundConfig.fromJson(jsonDecode(pRow.backgroundConfig!)) : null,
        syncedWithCloud: pRow.syncedWithCloud,
        updatedAt: pRow.updatedAt,
      ));
    }
    return pages;
  }

  Stream<List<LocalPage>> watchPagesByNotebook(int notebookId, {bool includeDeleted = false}) {
    final query = _db.select(_db.pages)..where((t) => t.notebookId.equals(notebookId));
    if (!includeDeleted) query.where((t) => t.isDeleted.equals(0));
    
    return query.watch().map((rows) {
      return rows.map((row) => LocalPage(
        id: row.id,
        serverId: row.serverId,
        notebookId: row.notebookId,
        pageNumber: row.pageNumber,
        isLandscape: row.isLandscape == 1,
        paperSize: row.paperSize,
        lineType: row.lineType,
        lineSpacing: row.lineSpacing,
        clientId: row.clientId,
        title: LocalPage.parseMeta(row.headerData),
        sectionTitle: LocalPage.parseSection(row.headerData),
        sectionColor: LocalPage.parseSectionColor(row.headerData),
        footer: LocalPage.parseMeta(row.footerData),
        extractedText: row.extractedText,
        isFrozen: row.isFrozen == 1,
        isFavorite: row.isFavorite == 1,
        isDeleted: row.isDeleted == 1,
        objects: [], // Lazy loaded
        syncedWithCloud: row.syncedWithCloud,
        updatedAt: row.updatedAt,
      )).toList();
    });
  }

  Future<List<LocalPage>> getDeletedPages(int notebookId) async {
    final rows = await (_db.select(_db.pages)
          ..where((t) => t.notebookId.equals(notebookId) & t.isDeleted.equals(1))
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .get();

    return rows.map((row) => LocalPage(
      id: row.id,
      serverId: row.serverId,
      notebookId: row.notebookId,
      pageNumber: row.pageNumber,
      isLandscape: row.isLandscape == 1,
      paperSize: row.paperSize,
      lineType: row.lineType,
      lineSpacing: row.lineSpacing,
      clientId: row.clientId,
      title: LocalPage.parseMeta(row.headerData),
      sectionTitle: LocalPage.parseSection(row.headerData),
      sectionColor: LocalPage.parseSectionColor(row.headerData),
      footer: LocalPage.parseMeta(row.footerData),
      extractedText: row.extractedText,
      isFrozen: row.isFrozen == 1,
      isFavorite: row.isFavorite == 1,
      isDeleted: true,
      objects: [],
      syncedWithCloud: row.syncedWithCloud,
      updatedAt: row.updatedAt,
    )).toList();
  }

  Future<void> restorePage(String clientId) async {
    await (_db.update(_db.pages)..where((t) => t.clientId.equals(clientId))).write(
      PagesCompanion(
        isDeleted: const Value(0),
        syncedWithCloud: const Value(0),
        updatedAt: Value(TimeService().nowMs()),
      ),
    );
  }

  Future<void> movePageToNotebook(String clientId, int targetNotebookId, int newPageNumber) async {
    await (_db.update(_db.pages)..where((t) => t.clientId.equals(clientId))).write(
      PagesCompanion(
        notebookId: Value(targetNotebookId),
        pageNumber: Value(newPageNumber),
        syncedWithCloud: const Value(0),
        updatedAt: Value(TimeService().nowMs()),
      ),
    );
  }

  /// 🚀 CARREGAMENTO SOB DEMANDA: Busca o conteúdo pesado de uma página
  Future<Map<String, dynamic>> loadPageContent(int pageId, {int? pageNumber}) async {
    final strokeRows = await (_db.select(_db.canvasStrokes)..where((t) => t.pageId.equals(pageId))).get();
    final textRows = await (_db.select(_db.canvasTextBlocks)..where((t) => t.pageId.equals(pageId))).get();
    final imgRows = await (_db.select(_db.canvasImageBlocks)..where((t) => t.pageId.equals(pageId))).get();

    final strokes = strokeRows.map((s) => Stroke.fromJson({
      ...jsonDecode(s.strokeData),
      'updated_at': s.updatedAt,
      'is_deleted': s.isDeleted == 1,
      'deleted_in_session': s.deletedInSession == 1,
      'creator_id': s.creatorId,
      'synced_with_cloud': s.syncedWithCloud == 1,
      'page_number': pageNumber,
    })).toList();

    final textBlocks = textRows.map((t) => TextBlock.fromJson({
      ...jsonDecode(t.textData),
      'updated_at': t.updatedAt,
      'is_deleted': t.isDeleted == 1,
      'deleted_in_session': t.deletedInSession == 1,
      'creator_id': t.creatorId,
      'synced_with_cloud': t.syncedWithCloud == 1,
      'page_number': pageNumber,
    })).toList();

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
      'synced_with_cloud': i.syncedWithCloud == 1,
      'page_number': pageNumber,
    })).toList();

    return {
      'strokes': strokes,
      'textBlocks': textBlocks,
      'imageBlocks': imageBlocks,
    };
  }

  Future<int> savePage(LocalPage page, int? notebookSid) async {
    return await savePageFromMap(page.toJson(), notebookSid);
  }

  /// 🚀 GRAVAÇÃO OTIMIZADA: Confiança total no servidor
  Future<int> savePageFromMap(Map<String, dynamic> pageData, int? notebookSid, {bool isLocalEdit = false}) async {
    final String clientId = pageData['client_id'];
    final int? serverId = pageData['id'] != null ? int.tryParse(pageData['id'].toString()) : null;
    
    // 1. BUSCAR REGISTO EXISTENTE (Âncora Única: clientId)
    final existingByClient = await (_db.select(_db.pages)..where((t) => t.clientId.equals(clientId))).getSingleOrNull();

    // 2. RESOLUÇÃO DE ID DO CADERNO
    int? localNotebookId;
    if (notebookSid != null && notebookSid != 0) {
      final nb = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(notebookSid))).getSingleOrNull();
      if (nb != null) localNotebookId = nb.id;
    }
    localNotebookId ??= pageData['notebook_id'] ?? existingByClient?.notebookId;

    if (localNotebookId == null) {
      debugPrint('⚠️ [CanvasRepo] notebook_id ausente para ClientId $clientId. Abortando gravação.');
      return existingByClient?.id ?? 0;
    }

    final int? effectiveId = existingByClient?.id;

    // 3. INSERIR OU ATUALIZAR
    final companion = PagesCompanion.insert(
      id: effectiveId != null ? Value(effectiveId) : const Value.absent(),
      serverId: Value(serverId),
      clientId: Value(clientId),
      notebookId: localNotebookId!, 
      pageNumber: int.tryParse(pageData['page_number']?.toString() ?? '1') ?? 1,
      isLandscape: Value((pageData['is_landscape'] == true || pageData['is_landscape'] == 1) ? 1 : 0),
      headerData: Value(jsonEncode(pageData['header_data'] ?? {'title': null})),
      footerData: Value(jsonEncode(pageData['footer_data'] ?? {'title': null})),
      extractedText: Value(pageData['extracted_text']),
      paperSize: Value(pageData['paper_size'] ?? 'A4'),
      lineType: Value(pageData['line_type']?.toString()),
      lineSpacing: Value(pageData['line_spacing'] != null ? double.tryParse(pageData['line_spacing'].toString()) : null),
      isFrozen: Value((pageData['is_frozen'] == true || pageData['is_frozen'] == 1) ? 1 : 0),
      isFavorite: Value((pageData['is_favorite'] == true || pageData['is_favorite'] == 1) ? 1 : 0),
      isDeleted: Value((pageData['is_deleted'] == true || pageData['is_deleted'] == 1) ? 1 : 0),
      backgroundConfig: Value(pageData['background_config'] != null ? jsonEncode(pageData['background_config']) : null),
      updatedAt: Value(_parseSafeInt(pageData['updated_at_ms']) ?? _parseSafeInt(pageData['updated_at']) ?? TimeService().nowMs()),
      syncedWithCloud: Value(isLocalEdit ? 0 : 1), // 🚀 CONTROLO DE SYNC
    );

    int finalId = await _db.into(_db.pages).insertOnConflictUpdate(companion);
    
    // 🚀 RECUPERAÇÃO DE ID: Se o insert retornar 0 (já existia), buscamos o ID real.
    if (finalId <= 0) {
      final row = await (_db.select(_db.pages)..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
      finalId = row?.id ?? 0;
    }
    
    if (finalId == 0) {
      debugPrint('🚨 [CanvasRepo] FATAL: Falha ao obter ID da página para $clientId');
    } else {
      debugPrint('💾 [CanvasRepo] Página salva: ID $finalId, ClientId $clientId');
    }
    return finalId;
  }

  Future<void> saveSingleStroke(String pageClientId, Stroke s, {int? pageId}) async {
    int? targetPageId = pageId;
    if (targetPageId == null) {
      final page = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingleOrNull();
      if (page == null) return;
      targetPageId = page.id;
    }

    try {
      // 🚀 CONSISTÊNCIA: Garantir que o strokeData JSON reflete o estado syncedWithCloud correto antes de salvar
      final strokeMap = s.toJson();
      
      await _db.into(_db.canvasStrokes).insertOnConflictUpdate(CanvasStrokesCompanion.insert(
        clientStrokeId: s.id,
        pageId: targetPageId,
        strokeData: jsonEncode(strokeMap),
        isDeleted: Value(s.isDeleted ? 1 : 0),
        deletedInSession: Value(s.deletedInSession ? 1 : 0),
        creatorId: Value(s.creatorId),
        updatedAt: Value(s.updatedAt),
        syncedWithCloud: Value(s.syncedWithCloud ? 1 : 0),
      ));
      
      // 🚀 GATILHO DE SYNC: Marcar a página como não sincronizada para o SyncService detectá-la
      if (!s.syncedWithCloud) {
        await markPageAsUnsynced(pageClientId);
      }
    } catch (e) {
      debugPrint('🚨 [CanvasRepo] Falha ao salvar traço: $e');
    }
  }

  Future<void> saveSingleTextBlock(String pageClientId, TextBlock t, {int? pageId}) async {
    int? targetPageId = pageId;
    if (targetPageId == null) {
      final page = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingleOrNull();
      if (page == null) return;
      targetPageId = page.id;
    }

    try {
      final textMap = t.toJson();

      await _db.into(_db.canvasTextBlocks).insertOnConflictUpdate(CanvasTextBlocksCompanion.insert(
        clientTextId: t.id,
        pageId: targetPageId,
        textData: jsonEncode(textMap),
        isDeleted: Value(t.isDeleted ? 1 : 0),
        deletedInSession: Value(t.deletedInSession ? 1 : 0),
        creatorId: Value(t.creatorId),
        updatedAt: Value(t.updatedAt),
        syncedWithCloud: Value(t.syncedWithCloud ? 1 : 0),
      ));

      if (!t.syncedWithCloud) {
        await markPageAsUnsynced(pageClientId);
      }
    } catch (e) {}
  }

  Future<void> saveSingleImageBlock(String pageClientId, ImageBlock i, {int? pageId}) async {
    int? targetPageId = pageId;
    if (targetPageId == null) {
      final page = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingleOrNull();
      if (page == null) return;
      targetPageId = page.id;
    }

    try {
      await _db.into(_db.canvasImageBlocks).insertOnConflictUpdate(CanvasImageBlocksCompanion.insert(
        clientImageId: i.id,
        pageId: targetPageId,
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
        syncedWithCloud: Value(i.syncedWithCloud ? 1 : 0),
      ));

      if (!i.syncedWithCloud) {
        await markPageAsUnsynced(pageClientId);
      }
    } catch (e) {}
  }

  Future<void> markPageAsUnsynced(String pageClientId) async {
    final page = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingleOrNull();
    if (page == null) return;

    final now = TimeService().nowMs();
    debugPrint('🚩 [CanvasRepo] Marcando página como SUJA: $pageClientId');
    
    await (_db.update(_db.pages)..where((t) => t.clientId.equals(pageClientId)))
        .write(PagesCompanion(
          syncedWithCloud: const Value(0),
          updatedAt: Value(now),
        ));

    // 🚀 ATUALIZAÇÃO DO PAI: O caderno também mudou
    await (_db.update(_db.notebooks)..where((t) => t.id.equals(page.notebookId)))
        .write(NotebooksCompanion(
          updatedAt: Value(now),
          syncedWithCloud: const Value(0),
        ));
  }

  Future<void> deleteSingleStroke(String strokeId) async {
    await (_db.update(_db.canvasStrokes)..where((t) => t.clientStrokeId.equals(strokeId))).write(const CanvasStrokesCompanion(isDeleted: Value(1)));
  }

  Future<void> deleteSingleTextBlock(String textId) async {
    await (_db.update(_db.canvasTextBlocks)..where((t) => t.clientTextId.equals(textId))).write(const CanvasTextBlocksCompanion(isDeleted: Value(1)));
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

  int? _parseSafeInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) {
      // Tentar ISO Date
      final date = DateTime.tryParse(val);
      if (date != null) return date.millisecondsSinceEpoch;
      return int.tryParse(val);
    }
    return null;
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
