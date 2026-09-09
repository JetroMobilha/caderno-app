import 'dart:convert';
import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:vector_math/vector_math_64.dart';
import '../../../core/database/app_database.dart' hide User, Subject, Notebook, Page;
import '../../../core/network/api_service.dart';
import '../../../core/network/time_service.dart';
import '../models/local_page_model.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../models/image_block_model.dart';
import '../models/shape_model.dart'; 
import '../models/audio_block_model.dart'; 
import '../models/animation_object_model.dart'; 
import '../models/table_model.dart'; 
import '../models/link_model.dart'; 
import '../models/attachment_model.dart';
import '../models/page_object.dart';

class CanvasRepository {
  final AppDatabase _db;
  final ApiService _apiService = ApiService();

  CanvasRepository(this._db);

  AppDatabase get db => _db;

  Future<LocalPage?> getPageByClientId(String clientId, {bool onlyUnsynced = false}) async {
    final pRow = await (_db.select(_db.pages)..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    if (pRow == null) return null;
    final int pageId = pRow.id;
    
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
      'parent_id': (s as dynamic).parentId,
      'is_visible': (s as dynamic).isVisible == 1,
      'is_locked': (s as dynamic).isLocked == 1,
      'opacity': (s as dynamic).opacity,
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
      'parent_id': (t as dynamic).parentId,
      'is_visible': (t as dynamic).isVisible == 1,
      'is_locked': (t as dynamic).isLocked == 1,
      'opacity': (t as dynamic).opacity,
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
      'layer_id': i.layerId,
      'synced_with_cloud': i.syncedWithCloud == 1,
      'page_number': pRow.pageNumber,
      'parent_id': (i as dynamic).parentId,
      'is_visible': (i as dynamic).isVisible == 1,
      'is_locked': (i as dynamic).isLocked == 1,
      'opacity': (i as dynamic).opacity,
    })).toList();

    final shapeRows = await (_db.select(_db.canvasShapes)..where((t) => t.pageId.equals(pageId))).get();
    final shapes = shapeRows.map((s) => ShapeObject.fromJson({
      ...jsonDecode(s.shapeData),
      'parent_id': (s as dynamic).parentId,
      'is_visible': (s as dynamic).isVisible == 1,
      'is_locked': (s as dynamic).isLocked == 1,
      'opacity': (s as dynamic).opacity,
    })).toList();

    final audioRows = await (_db.select(_db.canvasAudioBlocks)..where((t) => t.pageId.equals(pageId))).get();
    final audios = audioRows.map((a) => AudioBlock.fromJson({
      ...jsonDecode(a.audioData),
      'parent_id': (a as dynamic).parentId,
      'is_visible': (a as dynamic).isVisible == 1,
      'is_locked': (a as dynamic).isLocked == 1,
      'opacity': (a as dynamic).opacity,
    })).toList();

    final animRows = await (_db.select(_db.canvasAnimations)..where((t) => t.pageId.equals(pageId))).get();
    final animations = animRows.map((a) => AnimationObject.fromJson({
      ...jsonDecode(a.animationData),
      'parent_id': (a as dynamic).parentId,
      'is_visible': (a as dynamic).isVisible == 1,
      'is_locked': (a as dynamic).isLocked == 1,
      'opacity': (a as dynamic).opacity,
    })).toList();

    final tableRows = await (_db.select(_db.canvasTables)..where((t) => t.pageId.equals(pageId))).get();
    final tables = tableRows.map((t) => TableObject.fromJson({
      ...jsonDecode(t.tableData),
      'parent_id': (t as dynamic).parentId,
      'is_visible': (t as dynamic).isVisible == 1,
      'is_locked': (t as dynamic).isLocked == 1,
      'opacity': (t as dynamic).opacity,
    })).toList();

    final linkRows = await (_db.select(_db.canvasLinks)..where((t) => t.pageId.equals(pageId))).get();
    final links = linkRows.map((l) => LinkObject.fromJson({
      ...jsonDecode(l.linkData),
      'parent_id': (l as dynamic).parentId,
      'is_visible': (l as dynamic).isVisible == 1,
      'is_locked': (l as dynamic).isLocked == 1,
      'opacity': (l as dynamic).opacity,
    })).toList();

    final attachRows = await (_db.select(_db.canvasAttachments)..where((t) => t.pageId.equals(pageId))).get();
    final attachments = attachRows.map((a) => AttachmentObject.fromJson({
      ...jsonDecode(a.attachmentData),
      'parent_id': (a as dynamic).parentId,
      'is_visible': (a as dynamic).isVisible == 1,
      'is_locked': (a as dynamic).isLocked == 1,
      'opacity': (a as dynamic).opacity,
    })).toList();

    return LocalPage(
      id: pRow.id, serverId: pRow.serverId, notebookId: pRow.notebookId, pageNumber: pRow.pageNumber,
      isLandscape: pRow.isLandscape == 1, paperSize: pRow.paperSize, lineType: pRow.lineType,
      lineSpacing: pRow.lineSpacing, clientId: pRow.clientId, title: LocalPage.parseMeta(pRow.headerData),
      sectionTitle: LocalPage.parseSection(pRow.headerData), sectionColor: LocalPage.parseSectionColor(pRow.headerData),
      footer: LocalPage.parseMeta(pRow.footerData), extractedText: pRow.extractedText, isFrozen: pRow.isFrozen == 1,
      isFavorite: pRow.isFavorite == 1, backgroundConfig: pRow.backgroundConfig != null ? BackgroundConfig.fromJson(jsonDecode(pRow.backgroundConfig!)) : null,
      viewportMatrix: pRow.viewportMatrix != null ? Matrix4.fromList(List<double>.from(jsonDecode(pRow.viewportMatrix!))) : null,
      layers: pRow.layers != null ? (jsonDecode(pRow.layers!) as List).map((l) => LayerDefinition.fromJson(l)).toList() : null,
      syncedWithCloud: pRow.syncedWithCloud, updatedAt: pRow.updatedAt,
      objects: [...strokes, ...textBlocks, ...imageBlocks, ...shapes, ...audios, ...animations, ...tables, ...links, ...attachments],
    );
  }

  Future<List<LocalPage>> getPagesByNotebook(int notebookId, int? notebookServerId) async {
    final pageRows = await (_db.select(_db.pages)..where((t) => t.notebookId.equals(notebookId) & t.isDeleted.equals(0))..orderBy([(t) => OrderingTerm(expression: t.pageNumber), (t) => OrderingTerm(expression: t.clientId)])).get();
    List<LocalPage> pages = [];
    for (var pRow in pageRows) { final p = await getPageByClientId(pRow.clientId); if (p != null) pages.add(p); }
    return pages;
  }

  Future<void> saveSingleStroke(String pageClientId, Stroke s, {int? pageId, int? updatedAt}) async {
    final p = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingleOrNull();
    if (p == null) return;
    try {
      await _db.into(_db.canvasStrokes).insertOnConflictUpdate((_db.canvasStrokes as dynamic).companion(
        clientStrokeId: Value(s.id), pageId: Value(p.id), strokeData: Value(jsonEncode(s.toJson())),
        isDeleted: Value(s.isDeleted ? 1 : 0), deletedInSession: Value(s.deletedInSession ? 1 : 0),
        creatorId: Value(s.creatorId), updatedAt: Value(s.updatedAt), syncedWithCloud: Value(s.syncedWithCloud ? 1 : 0),
        parentId: Value(s.parentId), isVisible: Value(s.isVisible ? 1 : 0), isLocked: Value(s.isLocked ? 1 : 0), opacity: Value(s.opacity),
      ));
      await markPageAsUnsynced(pageClientId, updatedAt: updatedAt);
    } catch (e) {}
  }

  Future<void> saveSingleTextBlock(String pageClientId, TextBlock t, {int? pageId, int? updatedAt}) async {
    final p = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingleOrNull();
    if (p == null) return;
    try {
      await _db.into(_db.canvasTextBlocks).insertOnConflictUpdate((_db.canvasTextBlocks as dynamic).companion(
        clientTextId: Value(t.id), pageId: Value(p.id), textData: Value(jsonEncode(t.toJson())),
        isDeleted: Value(t.isDeleted ? 1 : 0), deletedInSession: Value(t.deletedInSession ? 1 : 0),
        creatorId: Value(t.creatorId), updatedAt: Value(t.updatedAt), syncedWithCloud: Value(t.syncedWithCloud ? 1 : 0),
        parentId: Value(t.parentId), isVisible: Value(t.isVisible ? 1 : 0), isLocked: Value(t.isLocked ? 1 : 0), opacity: Value(t.opacity),
      ));
      await markPageAsUnsynced(pageClientId, updatedAt: updatedAt);
    } catch (e) {}
  }

  Future<void> saveSingleImageBlock(String pageClientId, ImageBlock i, {int? pageId, int? updatedAt}) async {
    final p = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingleOrNull();
    if (p == null) return;
    try {
      await _db.into(_db.canvasImageBlocks).insertOnConflictUpdate((_db.canvasImageBlocks as dynamic).companion(
        clientImageId: Value(i.id), pageId: Value(p.id), imagePath: Value(i.imagePath),
        posX: Value(i.position.dx), posY: Value(i.position.dy), width: Value(i.width), height: Value(i.height),
        rotation: Value(i.rotation), isDeleted: Value(i.isDeleted ? 1 : 0), deletedInSession: Value(i.deletedInSession ? 1 : 0),
        creatorId: Value(i.creatorId), updatedAt: Value(i.updatedAt), syncedWithCloud: Value(i.syncedWithCloud ? 1 : 0),
        parentId: Value(i.parentId), isVisible: Value(i.isVisible ? 1 : 0), isLocked: Value(i.isLocked ? 1 : 0), opacity: Value(i.opacity),
      ));
      await markPageAsUnsynced(pageClientId, updatedAt: updatedAt);
    } catch (e) {}
  }

  Future<void> saveSingleShape(String pageClientId, ShapeObject s, {int? pageId, int? updatedAt}) async {
    final p = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingleOrNull();
    if (p == null) return;
    try {
      await _db.into(_db.canvasShapes).insertOnConflictUpdate((_db.canvasShapes as dynamic).companion(
        clientShapeId: Value(s.id), pageId: Value(p.id), shapeData: Value(jsonEncode(s.toJson())),
        isDeleted: Value(s.isDeleted ? 1 : 0), updatedAt: Value(s.updatedAt), layerId: Value(s.layerId),
        parentId: Value(s.parentId), isVisible: Value(s.isVisible ? 1 : 0), isLocked: Value(s.isLocked ? 1 : 0), opacity: Value(s.opacity),
      ));
      await markPageAsUnsynced(pageClientId, updatedAt: updatedAt);
    } catch (e) {}
  }

  Future<void> saveSingleAudioBlock(String pageClientId, AudioBlock a, {int? pageId, int? updatedAt}) async {
    final p = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingleOrNull();
    if (p == null) return;
    try {
      await _db.into(_db.canvasAudioBlocks).insertOnConflictUpdate((_db.canvasAudioBlocks as dynamic).companion(
        clientAudioId: Value(a.id), pageId: Value(p.id), audioData: Value(jsonEncode(a.toJson())),
        isDeleted: Value(a.isDeleted ? 1 : 0), updatedAt: Value(a.updatedAt), layerId: Value(a.layerId),
        parentId: Value(a.parentId), isVisible: Value(a.isVisible ? 1 : 0), isLocked: Value(a.isLocked ? 1 : 0), opacity: Value(a.opacity),
      ));
      await markPageAsUnsynced(pageClientId, updatedAt: updatedAt);
    } catch (e) {}
  }

  Future<void> saveSingleAnimationObject(String pageClientId, AnimationObject a, {int? pageId, int? updatedAt}) async {
    final p = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingleOrNull();
    if (p == null) return;
    try {
      await _db.into(_db.canvasAnimations).insertOnConflictUpdate((_db.canvasAnimations as dynamic).companion(
        clientAnimationId: Value(a.id), pageId: Value(p.id), animationData: Value(jsonEncode(a.toJson())),
        isDeleted: Value(a.isDeleted ? 1 : 0), updatedAt: Value(a.updatedAt), layerId: Value(a.layerId),
        parentId: Value(a.parentId), isVisible: Value(a.isVisible ? 1 : 0), isLocked: Value(a.isLocked ? 1 : 0), opacity: Value(a.opacity),
      ));
      await markPageAsUnsynced(pageClientId, updatedAt: updatedAt);
    } catch (e) {}
  }

  Future<void> saveSingleTable(String pageClientId, TableObject t, {int? pageId, int? updatedAt}) async {
    final p = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingleOrNull();
    if (p == null) return;
    try {
      await _db.into(_db.canvasTables).insertOnConflictUpdate((_db.canvasTables as dynamic).companion(
        clientTableId: Value(t.id), pageId: Value(p.id), tableData: Value(jsonEncode(t.toJson())),
        isDeleted: Value(t.isDeleted ? 1 : 0), updatedAt: Value(t.updatedAt), layerId: Value(t.layerId),
        parentId: Value(t.parentId), isVisible: Value(t.isVisible ? 1 : 0), isLocked: Value(t.isLocked ? 1 : 0), opacity: Value(t.opacity),
      ));
      await markPageAsUnsynced(pageClientId, updatedAt: updatedAt);
    } catch (e) {}
  }

  Future<void> saveSingleLink(String pageClientId, LinkObject l, {int? pageId, int? updatedAt}) async {
    final p = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingleOrNull();
    if (p == null) return;
    try {
      await _db.into(_db.canvasLinks).insertOnConflictUpdate((_db.canvasLinks as dynamic).companion(
        clientLinkId: Value(l.id), pageId: Value(p.id), linkData: Value(jsonEncode(l.toJson())),
        isDeleted: Value(l.isDeleted ? 1 : 0), updatedAt: Value(l.updatedAt), layerId: Value(l.layerId),
        parentId: Value(l.parentId), isVisible: Value(l.isVisible ? 1 : 0), isLocked: Value(l.isLocked ? 1 : 0), opacity: Value(l.opacity),
      ));
      await markPageAsUnsynced(pageClientId, updatedAt: updatedAt);
    } catch (e) {}
  }

  Future<void> saveSingleAttachment(String pageClientId, AttachmentObject a, {int? pageId, int? updatedAt}) async {
    final p = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingleOrNull();
    if (p == null) return;
    try {
      await _db.into(_db.canvasAttachments).insertOnConflictUpdate((_db.canvasAttachments as dynamic).companion(
        clientAttachmentId: Value(a.id), pageId: Value(p.id), attachmentData: Value(jsonEncode(a.toJson())),
        isDeleted: Value(a.isDeleted ? 1 : 0), updatedAt: Value(a.updatedAt), layerId: Value(a.layerId),
        parentId: Value(a.parentId), isVisible: Value(a.isVisible ? 1 : 0), isLocked: Value(a.isLocked ? 1 : 0), opacity: Value(a.opacity),
      ));
      await markPageAsUnsynced(pageClientId, updatedAt: updatedAt);
    } catch (e) {}
  }

  Future<void> markPageAsUnsynced(String pageClientId, {int? updatedAt}) async {
    final page = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingleOrNull();
    if (page == null) return;
    final now = updatedAt ?? TimeService().nowMs();
    await (_db.update(_db.pages)..where((t) => t.clientId.equals(pageClientId))).write(PagesCompanion(syncedWithCloud: const Value(0), updatedAt: Value(now)));
    await (_db.update(_db.notebooks)..where((t) => t.id.equals(page.notebookId))).write(NotebooksCompanion(updatedAt: Value(now), syncedWithCloud: const Value(0)));
  }

  Future<void> deleteObjectById(String objectId) async {
    await (_db.update(_db.canvasStrokes)..where((t) => t.clientStrokeId.equals(objectId))).write(const CanvasStrokesCompanion(isDeleted: Value(1)));
    await (_db.update(_db.canvasTextBlocks)..where((t) => t.clientTextId.equals(objectId))).write(const CanvasTextBlocksCompanion(isDeleted: Value(1)));
    await (_db.update(_db.canvasImageBlocks)..where((t) => t.clientImageId.equals(objectId))).write(const CanvasImageBlocksCompanion(isDeleted: Value(1)));
    await (_db.update(_db.canvasShapes)..where((t) => t.clientShapeId.equals(objectId))).write(const CanvasShapesCompanion(isDeleted: Value(1)));
    await (_db.update(_db.canvasTables)..where((t) => t.clientTableId.equals(objectId))).write(const CanvasTablesCompanion(isDeleted: Value(1)));
    await (_db.update(_db.canvasLinks)..where((t) => t.clientLinkId.equals(objectId))).write(const CanvasLinksCompanion(isDeleted: Value(1)));
    await (_db.update(_db.canvasAttachments)..where((t) => t.clientAttachmentId.equals(objectId))).write(const CanvasAttachmentsCompanion(isDeleted: Value(1)));
    await (_db.update(_db.canvasAudioBlocks)..where((t) => t.clientAudioId.equals(objectId))).write(const CanvasAudioBlocksCompanion(isDeleted: Value(1)));
    await (_db.update(_db.canvasAnimations)..where((t) => t.clientAnimationId.equals(objectId))).write(const CanvasAnimationsCompanion(isDeleted: Value(1)));
  }

  Future<void> deletePagesBatch(List<int> pageIds) async {
    await (_db.update(_db.pages)..where((t) => t.id.isIn(pageIds))).write(PagesCompanion(isDeleted: const Value(1), syncedWithCloud: const Value(0), updatedAt: Value(TimeService().nowMs())));
  }

  Future<void> updatePagesSectionBatch(List<int> pageIds, Map<String, dynamic> headerData) async {
    await (_db.update(_db.pages)..where((t) => t.id.isIn(pageIds))).write(PagesCompanion(headerData: Value(jsonEncode(headerData)), updatedAt: Value(TimeService().nowMs()), syncedWithCloud: const Value(0)));
  }

  int? _parseSafeInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) {
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
    } catch (e) {}
  }

  Future<Map<String, dynamic>?> fetchSessionStatus(int notebookId) async {
    try {
      final response = await _apiService.get('/notebooks/$notebookId/session/status');
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {}
    return null;
  }
}

final canvasRepositoryProvider = Provider<CanvasRepository>((ref) => CanvasRepository(AppDatabase.instance));
