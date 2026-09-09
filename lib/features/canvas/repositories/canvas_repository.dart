import 'dart:convert';
import 'dart:async';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' show Offset, Size, debugPrint;
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
import '../../notebooks/models/notebook_configuration.dart';

/// 🚀 v10.1: Repositório com suporte a Grupos e Metadados.
/// NOTA: Usamos (row as dynamic) para campos novos enquanto o build_runner não é executado.
class CanvasRepository {
  final AppDatabase _db;
  final ApiService _apiService = ApiService();

  CanvasRepository(this._db);

  AppDatabase get db => _db;

  Future<LocalPage?> getPageByClientId(String clientId, {bool onlyUnsynced = false}) async {
    final pRow = await (_db.select(_db.pages)..where((t) => t.clientId.equals(clientId))).getSingleOrNull();
    if (pRow == null) return null;
    final int pageId = pRow.id;
    
    // Strokes
    final strokeRows = await (_db.select(_db.canvasStrokes)..where((t) => t.pageId.equals(pageId))).get();
    final strokes = strokeRows.map((s) {
      final Map<String, dynamic> data = jsonDecode(s.strokeData);
      final dynamic row = s;
      return Stroke.fromJson({
        ...data,
        'id': s.clientStrokeId,
        'updated_at': s.updatedAt,
        'is_deleted': s.isDeleted == 1,
        'deleted_in_session': s.deletedInSession == 1,
        'creator_id': s.creatorId,
        'synced_with_cloud': s.syncedWithCloud == 1,
        'page_number': pRow.pageNumber,
        'parent_id': row.parentId,
        'is_visible': row.isVisible == null || row.isVisible == 1,
        'is_locked': row.isLocked == 1,
        'opacity': (row.opacity as num?)?.toDouble() ?? 1.0,
        'layer_id': row.layerId,
      });
    }).toList();

    // TextBlocks
    final textRows = await (_db.select(_db.canvasTextBlocks)..where((t) => t.pageId.equals(pageId))).get();
    final textBlocks = textRows.map((t) {
      final Map<String, dynamic> data = jsonDecode(t.textData);
      final dynamic row = t;
      return TextBlock.fromJson({
        ...data,
        'id': t.clientTextId,
        'updated_at': t.updatedAt,
        'is_deleted': t.isDeleted == 1,
        'deleted_in_session': t.deletedInSession == 1,
        'creator_id': t.creatorId,
        'synced_with_cloud': t.syncedWithCloud == 1,
        'page_number': pRow.pageNumber,
        'parent_id': row.parentId,
        'is_visible': row.isVisible == null || row.isVisible == 1,
        'is_locked': row.isLocked == 1,
        'opacity': (row.opacity as num?)?.toDouble() ?? 1.0,
        'layer_id': row.layerId,
      });
    }).toList();

    // Images
    final imgRows = await (_db.select(_db.canvasImageBlocks)..where((t) => t.pageId.equals(pageId))).get();
    final imageBlocks = imgRows.map((i) {
      final dynamic row = i;
      return ImageBlock.fromJson({
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
        'parent_id': row.parentId,
        'is_visible': row.isVisible == null || row.isVisible == 1,
        'is_locked': row.isLocked == 1,
        'opacity': (row.opacity as num?)?.toDouble() ?? 1.0,
      });
    }).toList();

    // Shapes
    final shapeRows = await (_db.select(_db.canvasShapes)..where((t) => t.pageId.equals(pageId))).get();
    final shapes = shapeRows.map((s) {
      final Map<String, dynamic> data = jsonDecode(s.shapeData);
      final dynamic row = s;
      return ShapeObject.fromJson({
        ...data,
        'id': s.clientShapeId,
        'updated_at': s.updatedAt,
        'is_deleted': s.isDeleted == 1,
        'synced_with_cloud': s.syncedWithCloud == 1,
        'parent_id': row.parentId,
        'is_visible': row.isVisible == null || row.isVisible == 1,
        'is_locked': row.isLocked == 1,
        'opacity': (row.opacity as num?)?.toDouble() ?? 1.0,
        'layer_id': row.layerId,
      });
    }).toList();

    // Audios
    final audioRows = await (_db.select(_db.canvasAudioBlocks)..where((t) => t.pageId.equals(pageId))).get();
    final audios = audioRows.map((a) {
      final Map<String, dynamic> data = jsonDecode(a.audioData);
      final dynamic row = a;
      return AudioBlock.fromJson({
        ...data,
        'id': a.clientAudioId,
        'updated_at': a.updatedAt,
        'is_deleted': a.isDeleted == 1,
        'synced_with_cloud': a.syncedWithCloud == 1,
        'parent_id': row.parentId,
        'is_visible': row.isVisible == null || row.isVisible == 1,
        'is_locked': row.isLocked == 1,
        'opacity': (row.opacity as num?)?.toDouble() ?? 1.0,
        'layer_id': row.layerId,
      });
    }).toList();

    // Animations
    final animRows = await (_db.select(_db.canvasAnimations)..where((t) => t.pageId.equals(pageId))).get();
    final animations = animRows.map((a) {
      final Map<String, dynamic> data = jsonDecode(a.animationData);
      final dynamic row = a;
      return AnimationObject.fromJson({
        ...data,
        'id': a.clientAnimationId,
        'updated_at': a.updatedAt,
        'is_deleted': a.isDeleted == 1,
        'synced_with_cloud': a.syncedWithCloud == 1,
        'parent_id': row.parentId,
        'is_visible': row.isVisible == null || row.isVisible == 1,
        'is_locked': row.isLocked == 1,
        'opacity': (row.opacity as num?)?.toDouble() ?? 1.0,
        'layer_id': row.layerId,
      });
    }).toList();

    // Tables
    final tableRows = await (_db.select(_db.canvasTables)..where((t) => t.pageId.equals(pageId))).get();
    final tables = tableRows.map((t) {
      final Map<String, dynamic> data = jsonDecode(t.tableData);
      final dynamic row = t;
      return TableObject.fromJson({
        ...data,
        'id': t.clientTableId,
        'updated_at': t.updatedAt,
        'is_deleted': t.isDeleted == 1,
        'synced_with_cloud': t.syncedWithCloud == 1,
        'parent_id': row.parentId,
        'is_visible': row.isVisible == null || row.isVisible == 1,
        'is_locked': row.isLocked == 1,
        'opacity': (row.opacity as num?)?.toDouble() ?? 1.0,
        'layer_id': row.layerId,
      });
    }).toList();

    // Links
    final linkRows = await (_db.select(_db.canvasLinks)..where((t) => t.pageId.equals(pageId))).get();
    final links = linkRows.map((l) {
      final Map<String, dynamic> data = jsonDecode(l.linkData);
      final dynamic row = l;
      return LinkObject.fromJson({
        ...data,
        'id': l.clientLinkId,
        'updated_at': l.updatedAt,
        'is_deleted': l.isDeleted == 1,
        'synced_with_cloud': l.syncedWithCloud == 1,
        'parent_id': row.parentId,
        'is_visible': row.isVisible == null || row.isVisible == 1,
        'is_locked': row.isLocked == 1,
        'opacity': (row.opacity as num?)?.toDouble() ?? 1.0,
        'layer_id': row.layerId,
      });
    }).toList();

    // Attachments
    final attachRows = await (_db.select(_db.canvasAttachments)..where((t) => t.pageId.equals(pageId))).get();
    final attachments = attachRows.map((a) {
      final Map<String, dynamic> data = jsonDecode(a.attachmentData);
      final dynamic row = a;
      return AttachmentObject.fromJson({
        ...data,
        'id': a.clientAttachmentId,
        'updated_at': a.updatedAt,
        'is_deleted': a.isDeleted == 1,
        'synced_with_cloud': a.syncedWithCloud == 1,
        'parent_id': row.parentId,
        'is_visible': row.isVisible == null || row.isVisible == 1,
        'is_locked': row.isLocked == 1,
        'opacity': (row.opacity as num?)?.toDouble() ?? 1.0,
        'layer_id': row.layerId,
      });
    }).toList();

    return LocalPage(
      id: pRow.id,
      serverId: pRow.serverId,
      notebookId: pRow.notebookId,
      pageNumber: pRow.pageNumber,
      isLandscape: pRow.isLandscape == 1,
      paperSize: pRow.paperSize,
      lineType: pRow.lineType,
      lineSpacing: pRow.lineSpacing,
      clientId: pRow.clientId ?? '',
      title: LocalPage.parseMeta(pRow.headerData),
      sectionTitle: LocalPage.parseSection(pRow.headerData),
      sectionColor: LocalPage.parseSectionColor(pRow.headerData),
      footer: LocalPage.parseMeta(pRow.footerData),
      extractedText: pRow.extractedText,
      isFrozen: pRow.isFrozen == 1,
      isFavorite: pRow.isFavorite == 1,
      backgroundConfig: pRow.backgroundConfig != null ? BackgroundConfig.fromJson(jsonDecode(pRow.backgroundConfig!)) : null,
      viewportMatrix: pRow.viewportMatrix != null ? Matrix4.fromList(List<double>.from(jsonDecode(pRow.viewportMatrix!))) : null,
      layers: pRow.layers != null 
          ? (jsonDecode(pRow.layers!) as List).map((l) => LayerDefinition.fromJson(l)).toList() 
          : null,
      syncedWithCloud: pRow.syncedWithCloud,
      updatedAt: pRow.updatedAt,
      objects: [
        ...strokes, ...textBlocks, ...imageBlocks, ...shapes, ...audios, ...animations,
        ...tables, ...links, ...attachments
      ],
    );
  }

  Future<List<LocalPage>> getPagesByNotebook(int notebookId, int? notebookServerId) async {
    final pageRows = await (_db.select(_db.pages)..where((t) => t.notebookId.equals(notebookId) & t.isDeleted.equals(0))..orderBy([(t) => OrderingTerm(expression: t.pageNumber), (t) => OrderingTerm(expression: t.clientId)])).get();
    List<LocalPage> pages = [];
    for (var pRow in pageRows) {
      final p = await getPageByClientId(pRow.clientId!);
      if (p != null) pages.add(p);
    }
    return pages;
  }

  Stream<List<LocalPage>> watchPagesByNotebook(int notebookId) {
    return (_db.select(_db.pages)..where((t) => t.notebookId.equals(notebookId) & t.isDeleted.equals(0))).watch().map((rows) {
       return rows.map((r) => LocalPage(
          id: r.id, serverId: r.serverId, notebookId: r.notebookId, pageNumber: r.pageNumber,
          isLandscape: r.isLandscape == 1, paperSize: r.paperSize, clientId: r.clientId ?? '',
          lineType: r.lineType, lineSpacing: r.lineSpacing, updatedAt: r.updatedAt, syncedWithCloud: r.syncedWithCloud,
          isDeleted: r.isDeleted == 1, isFrozen: r.isFrozen == 1, isFavorite: r.isFavorite == 1,
          objects: [], 
       )).toList();
    });
  }

  Future<Map<String, dynamic>> loadPageContent(int pageId, {int? pageNumber}) async {
    final page = await (_db.select(_db.pages)..where((t) => t.id.equals(pageId))).getSingle();
    final fullPage = await getPageByClientId(page.clientId!);
    if (fullPage == null) return {'strokes':[], 'textBlocks':[], 'imageBlocks':[], 'shapes':[], 'audios':[], 'animations':[], 'tables':[], 'links':[], 'attachments':[]};
    return {
      'strokes': fullPage.objects.whereType<Stroke>().toList(),
      'textBlocks': fullPage.objects.whereType<TextBlock>().toList(),
      'imageBlocks': fullPage.objects.whereType<ImageBlock>().toList(),
      'shapes': fullPage.objects.whereType<ShapeObject>().toList(),
      'audios': fullPage.objects.whereType<AudioBlock>().toList(),
      'animations': fullPage.objects.whereType<AnimationObject>().toList(),
      'tables': fullPage.objects.whereType<TableObject>().toList(),
      'links': fullPage.objects.whereType<LinkObject>().toList(),
      'attachments': fullPage.objects.whereType<AttachmentObject>().toList(),
    };
  }

  Future<int> savePage(LocalPage page, int? notebookSid) async {
    final companion = PagesCompanion.insert(
      id: page.id != null ? Value(page.id!) : const Value.absent(),
      serverId: Value(page.serverId),
      clientId: Value(page.clientId),
      notebookId: page.notebookId,
      pageNumber: page.pageNumber,
      isLandscape: Value(page.isLandscape ? 1 : 0),
      paperSize: Value(page.paperSize),
      lineType: Value(page.lineType),
      lineSpacing: Value(page.lineSpacing),
      isFrozen: Value(page.isFrozen ? 1 : 0),
      isFavorite: Value(page.isFavorite ? 1 : 0),
      isDeleted: Value(page.isDeleted ? 1 : 0),
      updatedAt: Value(page.updatedAt),
      syncedWithCloud: Value(page.syncedWithCloud),
      backgroundConfig: Value(page.backgroundConfig != null ? jsonEncode(page.backgroundConfig!.toJson()) : null),
      viewportMatrix: Value(page.viewportMatrix != null ? jsonEncode(page.viewportMatrix!.storage.toList()) : null),
      layers: Value(page.layers.isNotEmpty ? jsonEncode(page.layers.map((l) => l.toJson()).toList()) : null),
    );
    return await _db.into(_db.pages).insertOnConflictUpdate(companion);
  }

  Future<int> savePageFromMap(Map<String, dynamic> data, int? notebookSid) async {
     final page = LocalPage.fromJson(data);
     return await savePage(page, notebookSid);
  }

  Future<void> saveSingleStroke(String pageClientId, Stroke s, {int? pageId, int? updatedAt}) async {
    final page = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingle();
    final dynamic table = _db.canvasStrokes;
    final companion = table.companion(
      clientStrokeId: Value(s.id), pageId: Value(page.id), strokeData: Value(jsonEncode(s.toJson())),
      isDeleted: Value(s.isDeleted ? 1 : 0), deletedInSession: Value(s.deletedInSession ? 1 : 0),
      creatorId: Value(s.creatorId), updatedAt: Value(updatedAt ?? s.updatedAt), syncedWithCloud: Value(s.syncedWithCloud ? 1 : 0),
      parentId: Value(s.parentId), isVisible: Value(s.isVisible ? 1 : 0), isLocked: Value(s.isLocked ? 1 : 0), opacity: Value(s.opacity),
      layerId: Value(s.layerId),
    );
    await _db.into(_db.canvasStrokes).insertOnConflictUpdate(companion);
  }

  Future<void> saveSingleTextBlock(String pageClientId, TextBlock t, {int? pageId, int? updatedAt}) async {
    final page = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingle();
    final dynamic table = _db.canvasTextBlocks;
    final companion = table.companion(
      clientTextId: Value(t.id), pageId: Value(page.id), textData: Value(jsonEncode(t.toJson())),
      isDeleted: Value(t.isDeleted ? 1 : 0), deletedInSession: Value(t.deletedInSession ? 1 : 0),
      creatorId: Value(t.creatorId), updatedAt: Value(updatedAt ?? t.updatedAt), syncedWithCloud: Value(t.syncedWithCloud ? 1 : 0),
      parentId: Value(t.parentId), isVisible: Value(t.isVisible ? 1 : 0), isLocked: Value(t.isLocked ? 1 : 0), opacity: Value(t.opacity),
      layerId: Value(t.layerId),
    );
    await _db.into(_db.canvasTextBlocks).insertOnConflictUpdate(companion);
  }

  Future<void> saveSingleImageBlock(String pageClientId, ImageBlock i, {int? pageId, int? updatedAt}) async {
    final page = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingle();
    final dynamic table = _db.canvasImageBlocks;
    final companion = table.companion(
      clientImageId: Value(i.id), pageId: Value(page.id), imagePath: Value(i.imagePath), posX: Value(i.position.dx), posY: Value(i.position.dy), width: Value(i.width), height: Value(i.height), rotation: Value(i.rotation),
      isDeleted: Value(i.isDeleted ? 1 : 0), deletedInSession: Value(i.deletedInSession ? 1 : 0),
      creatorId: Value(i.creatorId), updatedAt: Value(updatedAt ?? i.updatedAt), syncedWithCloud: Value(i.syncedWithCloud ? 1 : 0),
      parentId: Value(i.parentId), isVisible: Value(i.isVisible ? 1 : 0), isLocked: Value(i.isLocked ? 1 : 0), opacity: Value(i.opacity),
      layerId: Value(i.layerId),
    );
    await _db.into(_db.canvasImageBlocks).insertOnConflictUpdate(companion);
  }

  Future<void> saveSingleShape(String pageClientId, ShapeObject s, {int? pageId, int? updatedAt}) async {
    final page = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingle();
    final dynamic table = _db.canvasShapes;
    final companion = table.companion(
      clientShapeId: Value(s.id), pageId: Value(page.id), shapeData: Value(jsonEncode(s.toJson())),
      isDeleted: Value(s.isDeleted ? 1 : 0), updatedAt: Value(updatedAt ?? s.updatedAt),
      parentId: Value(s.parentId), isVisible: Value(s.isVisible ? 1 : 0), isLocked: Value(s.isLocked ? 1 : 0), opacity: Value(s.opacity),
      layerId: Value(s.layerId),
    );
    await _db.into(_db.canvasShapes).insertOnConflictUpdate(companion);
  }

  Future<void> saveSingleTable(String pageClientId, TableObject t, {int? pageId, int? updatedAt}) async {
    final page = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingle();
    final dynamic table = _db.canvasTables;
    final companion = table.companion(
      clientTableId: Value(t.id), pageId: Value(page.id), tableData: Value(jsonEncode(t.toJson())),
      isDeleted: Value(t.isDeleted ? 1 : 0), updatedAt: Value(updatedAt ?? t.updatedAt),
      parentId: Value(t.parentId), isVisible: Value(t.isVisible ? 1 : 0), isLocked: Value(t.isLocked ? 1 : 0), opacity: Value(t.opacity),
      layerId: Value(t.layerId),
    );
    await _db.into(_db.canvasTables).insertOnConflictUpdate(companion);
  }

  Future<void> saveSingleLink(String pageClientId, LinkObject l, {int? pageId, int? updatedAt}) async {
    final page = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingle();
    final dynamic table = _db.canvasLinks;
    final companion = table.companion(
      clientLinkId: Value(l.id), pageId: Value(page.id), linkData: Value(jsonEncode(l.toJson())),
      isDeleted: Value(l.isDeleted ? 1 : 0), updatedAt: Value(updatedAt ?? l.updatedAt),
      parentId: Value(l.parentId), isVisible: Value(l.isVisible ? 1 : 0), isLocked: Value(l.isLocked ? 1 : 0), opacity: Value(l.opacity),
      layerId: Value(l.layerId),
    );
    await _db.into(_db.canvasLinks).insertOnConflictUpdate(companion);
  }

  Future<void> saveSingleAttachment(String pageClientId, AttachmentObject a, {int? pageId, int? updatedAt}) async {
    final page = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingle();
    final dynamic table = _db.canvasAttachments;
    final companion = table.companion(
      clientAttachmentId: Value(a.id), pageId: Value(page.id), attachmentData: Value(jsonEncode(a.toJson())),
      isDeleted: Value(a.isDeleted ? 1 : 0), updatedAt: Value(updatedAt ?? a.updatedAt),
      parentId: Value(a.parentId), isVisible: Value(a.isVisible ? 1 : 0), isLocked: Value(a.isLocked ? 1 : 0), opacity: Value(a.opacity),
      layerId: Value(a.layerId),
    );
    await _db.into(_db.canvasAttachments).insertOnConflictUpdate(companion);
  }

  Future<void> saveSingleAudioBlock(String pageClientId, AudioBlock a, {int? pageId, int? updatedAt}) async {
    final page = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingle();
    final dynamic table = _db.canvasAudioBlocks;
    final companion = table.companion(
      clientAudioId: Value(a.id), pageId: Value(page.id), audioData: Value(jsonEncode(a.toJson())),
      isDeleted: Value(a.isDeleted ? 1 : 0), updatedAt: Value(updatedAt ?? a.updatedAt),
      parentId: Value(a.parentId), isVisible: Value(a.isVisible ? 1 : 0), isLocked: Value(a.isLocked ? 1 : 0), opacity: Value(a.opacity),
      layerId: Value(a.layerId),
    );
    await _db.into(_db.canvasAudioBlocks).insertOnConflictUpdate(companion);
  }

  Future<void> saveSingleAnimationObject(String pageClientId, AnimationObject a, {int? pageId, int? updatedAt}) async {
    final page = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingle();
    final dynamic table = _db.canvasAnimations;
    final companion = table.companion(
      clientAnimationId: Value(a.id), pageId: Value(page.id), animationData: Value(jsonEncode(a.toJson())),
      isDeleted: Value(a.isDeleted ? 1 : 0), updatedAt: Value(updatedAt ?? a.updatedAt),
      parentId: Value(a.parentId), isVisible: Value(a.isVisible ? 1 : 0), isLocked: Value(a.isLocked ? 1 : 0), opacity: Value(a.opacity),
      layerId: Value(a.layerId),
    );
    await _db.into(_db.canvasAnimations).insertOnConflictUpdate(companion);
  }

  Future<void> deleteSingleStroke(String strokeId) async {
    await (_db.update(_db.canvasStrokes)..where((t) => t.clientStrokeId.equals(strokeId))).write(const CanvasStrokesCompanion(isDeleted: Value(1)));
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

  Future<void> markPageAsUnsynced(String pageClientId, {int? updatedAt}) async {
    final page = await (_db.select(_db.pages)..where((t) => t.clientId.equals(pageClientId))).getSingleOrNull();
    if (page == null) return;
    final now = updatedAt ?? TimeService().nowMs();
    await (_db.update(_db.pages)..where((t) => t.clientId.equals(pageClientId))).write(PagesCompanion(syncedWithCloud: const Value(0), updatedAt: Value(now)));
    await (_db.update(_db.notebooks)..where((t) => t.id.equals(page.notebookId))).write(NotebooksCompanion(updatedAt: Value(now), syncedWithCloud: const Value(0)));
  }

  Future<void> deletePagesBatch(List<int> pageIds) async { await (_db.update(_db.pages)..where((t) => t.id.isIn(pageIds))).write(PagesCompanion(isDeleted: const Value(1), syncedWithCloud: const Value(0), updatedAt: Value(TimeService().nowMs()))); }
  Future<void> updatePageNumbersBatch(List<int> pageIds) async { await _db.batch((batch) { for (int i = 0; i < pageIds.length; i++) batch.update(_db.pages, PagesCompanion(pageNumber: Value(i + 1), updatedAt: Value(TimeService().nowMs()), syncedWithCloud: const Value(0)), where: (t) => t.id.equals(pageIds[i])); }); }
  Future<void> reindexPages(int notebookId) async { final all = await (_db.select(_db.pages)..where((t) => t.notebookId.equals(notebookId) & t.isDeleted.equals(0))..orderBy([(t) => OrderingTerm(expression: t.pageNumber), (t) => OrderingTerm(expression: t.clientId)])).get(); await _db.batch((batch) { for (int i = 0; i < all.length; i++) batch.update(_db.pages, PagesCompanion(pageNumber: Value(i + 1)), where: (t) => t.id.equals(all[i].id)); }); }
  Future<void> shiftPageNumbers(int notebookId, int fromIndex, int count) async { final pagesToShift = await (_db.select(_db.pages)..where((t) => t.notebookId.equals(notebookId) & t.pageNumber.isBiggerOrEqualValue(fromIndex + 1))).get(); await _db.batch((batch) { for (var page in pagesToShift) batch.update(_db.pages, PagesCompanion(pageNumber: Value(page.pageNumber + count), updatedAt: Value(TimeService().nowMs()), syncedWithCloud: const Value(0)), where: (t) => t.id.equals(page.id)); }); }
  Future<void> restorePage(String clientId) async { await (_db.update(_db.pages)..where((t) => t.clientId.equals(clientId))).write(PagesCompanion(isDeleted: const Value(0), syncedWithCloud: const Value(0), updatedAt: Value(TimeService().nowMs()))); }
  Future<void> movePageToNotebook(String clientId, int targetNotebookId, int newPageNumber) async { await (_db.update(_db.pages)..where((t) => t.clientId.equals(clientId))).write(PagesCompanion(notebookId: Value(targetNotebookId), pageNumber: Value(newPageNumber), syncedWithCloud: const Value(0), updatedAt: Value(TimeService().nowMs()))); }
  Future<void> updatePagesSectionBatch(List<int> pageIds, Map<String, dynamic> headerData) async { await (_db.update(_db.pages)..where((t) => t.id.isIn(pageIds))).write(PagesCompanion(headerData: Value(jsonEncode(headerData)), updatedAt: Value(TimeService().nowMs()), syncedWithCloud: const Value(0))); }
  Future<List<LocalPage>> getDeletedPages(int notebookId) async { final rows = await (_db.select(_db.pages)..where((t) => t.notebookId.equals(notebookId) & t.isDeleted.equals(1))..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)])).get(); return rows.map((r) => LocalPage(id: r.id, serverId: r.serverId, notebookId: r.notebookId, pageNumber: r.pageNumber, isLandscape: r.isLandscape == 1, paperSize: r.paperSize, clientId: r.clientId ?? '', lineType: r.lineType, lineSpacing: r.lineSpacing, updatedAt: r.updatedAt, syncedWithCloud: r.syncedWithCloud, isDeleted: true, objects: [])).toList(); }

  Future<String?> uploadImage(int notebookId, String fileName, Uint8List bytes) async {
    try {
      final uri = Uri.parse('${ApiService.baseUrl}/notebooks/$notebookId/upload-image');
      final request = http.MultipartRequest('POST', uri);
      final token = await _apiService.getToken();
      if (token != null) request.headers['Authorization'] = 'Bearer $token';
      request.files.add(http.MultipartFile.fromBytes('image', bytes, filename: fileName));
      final response = await request.send();
      if (response.statusCode == 200) { final data = jsonDecode(await response.stream.bytesToString()); return data['url']; }
    } catch (e) {}
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
      if (response.statusCode == 200) { final data = jsonDecode(await response.stream.bytesToString()); return data['url']; }
    } catch (e) {}
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
      if (response.statusCode == 200) { final data = jsonDecode(await response.stream.bytesToString()); return data['url']; }
    } catch (e) {}
    return null;
  }
}

final canvasRepositoryProvider = Provider<CanvasRepository>((ref) => CanvasRepository(AppDatabase.instance));
