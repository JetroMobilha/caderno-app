import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:caderno_digital_app/core/utils/rdp_simplifier.dart';
import 'package:caderno_digital_app/core/utils/stroke_utils.dart';
import '../../notebooks/models/notebook_configuration.dart'; 
import '../models/animation_object_model.dart';
import '../models/attachment_model.dart';
import '../models/audio_block_model.dart';
import '../models/canvas_enums.dart';
import '../models/link_model.dart';
import '../models/local_page_model.dart';
import '../models/shape_model.dart';
import '../models/stroke_model.dart';
import '../models/table_model.dart';
import '../models/text_block_model.dart';
import '../models/image_block_model.dart';
import '../models/page_object.dart'; 
import '../models/canvas_action_model.dart';
import '../repositories/canvas_repository.dart';
import '../../../core/network/realtime_service.dart';
import '../../../core/network/sync_service.dart';
import '../../../core/network/time_service.dart';
import '../services/audio_session_service.dart';
import '../services/collaboration_room_service.dart';
import '../services/undo_redo_manager.dart';
import '../../../core/network/sync_provider.dart';
import 'canvas_tool_provider.dart';
import 'canvas_ui_provider.dart';
import 'canvas_viewport_provider.dart';

class CanvasDocumentState {
  final List<LocalPage> pages;
  final int? liveNotebookSid;
  final int currentNotebookId;
  final String currentUserRole;
  final String currentTemplateType;
  final bool isCollaborationEnabled;
  final bool isGlobalSyncing;
  final String myUserId;
  final Set<String> tearingPageClientIds;
  final bool canUndo;
  final bool canRedo;
  final bool isLoading;

  CanvasDocumentState({
    this.pages = const [],
    this.liveNotebookSid,
    this.currentNotebookId = 0,
    this.currentUserRole = 'viewer',
    this.currentTemplateType = 'study',
    this.isCollaborationEnabled = false,
    this.isGlobalSyncing = false,
    this.myUserId = '',
    this.tearingPageClientIds = const {},
    this.canUndo = false,
    this.canRedo = false,
    this.isLoading = false,
  });

  CanvasDocumentState copyWith({
    List<LocalPage>? pages,
    int? liveNotebookSid,
    int? currentNotebookId,
    String? currentUserRole,
    String? currentTemplateType,
    bool? isCollaborationEnabled,
    bool? isGlobalSyncing,
    String? myUserId,
    Set<String>? tearingPageClientIds,
    bool? canUndo,
    bool? canRedo,
    bool? isLoading,
  }) {
    return CanvasDocumentState(
      pages: pages ?? this.pages,
      liveNotebookSid: liveNotebookSid ?? this.liveNotebookSid,
      currentNotebookId: currentNotebookId ?? this.currentNotebookId,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      currentTemplateType: currentTemplateType ?? this.currentTemplateType,
      isCollaborationEnabled: isCollaborationEnabled ?? this.isCollaborationEnabled,
      isGlobalSyncing: isGlobalSyncing ?? this.isGlobalSyncing,
      myUserId: myUserId ?? this.myUserId,
      tearingPageClientIds: tearingPageClientIds ?? this.tearingPageClientIds,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class CanvasDocumentNotifier extends AutoDisposeNotifier<CanvasDocumentState> {
  late CanvasRepository _repository;
  late RealtimeService _realtimeService;
  late SyncService _syncService;
  late AudioSessionService _audioService;
  late CollaborationRoomService _collabService;
  late UndoRedoManager _undoRedoManager;
  StreamSubscription? _pagesSubscription;

  @override
  CanvasDocumentState build() {
    _repository = ref.read(canvasRepositoryProvider);
    _realtimeService = ref.read(realtimeServiceProvider);
    _syncService = ref.read(appSyncServiceProvider);
    _audioService = ref.read(audioSessionServiceProvider);
    _collabService = ref.read(collaborationRoomServiceProvider);
    _undoRedoManager = UndoRedoManager();
    ref.onDispose(() { _pagesSubscription?.cancel(); });
    return CanvasDocumentState();
  }

  Future<void> initNotebook(int notebookId, int? notebookSid, String role, String? userId, {String? templateType}) async {
    ref.invalidate(canvasInteractionProvider);
    ref.invalidate(canvasViewportProvider);
    ref.invalidate(canvasUiProvider);
    _undoRedoManager.clear();
    state = state.copyWith(isLoading: false, currentNotebookId: notebookId, liveNotebookSid: notebookSid, currentUserRole: role, currentTemplateType: templateType ?? 'study', myUserId: userId ?? '', canUndo: false, canRedo: false);
    _audioService.loadLessonRecordings(notebookId);
    _collabService.onSyncRequested = () => _performCollectiveSync();
    _collabService.onExecuteAction = (d) => _handleRemoteAction(d);
    _collabService.onPageEvent = (d) => _handlePageEvent(d);
    _collabService.onFullStateRequested = (d) => _handleFullStateRequest(d);
    _collabService.onFullStateReceived = (d) => _handleFullStateReceived(d);
    _collabService.onCloudSyncSignal = (d) => _syncService.pullSpecificPage(notebookSid!, d['page_number']);
    _collabService.onSmoothTransition = (m) => _startSmoothTransition(m);
    _collabService.onPageNavigationRequested = (i) => ref.read(canvasViewportProvider.notifier).jumpToPage(i);
    _collabService.onAutoNavigateAfterDeletion = () => _autoNavigateAfterDeletion();
    _collabService.onNotebookStructureUpdated = (d) => _performCollectiveSync(); 
    _collabService.onApplyRemoteChange = (pcid, newObjects, remoteTs) async {
       final idx = state.pages.indexWhere((p) => p.clientId == pcid);
       if (idx == -1) return;
       final updatedPage = state.pages[idx].copyWith(objects: newObjects, updatedAt: remoteTs);
       state = state.copyWith(pages: state.pages.map((p) => p.clientId == pcid ? updatedPage : p).toList());
    };
    _audioService.onAudioMessageProcessed = (d) => _collabService.chatMessages.add(d);
    _pagesSubscription?.cancel();
    _pagesSubscription = _repository.watchPagesByNotebook(notebookId).listen((newPagesFromDb) {
      final List<LocalPage> activePages = newPagesFromDb.where((p) => !p.isDeleted).toList();
      activePages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
      if (state.pages.length == activePages.length) { bool listIdentical = true; for (int i = 0; i < activePages.length; i++) { if (activePages[i].clientId != state.pages[i].clientId || activePages[i].updatedAt != state.pages[i].updatedAt || activePages[i].syncedWithCloud != state.pages[i].syncedWithCloud) { listIdentical = false; break; } } if (listIdentical) return; }
      final bool wasEmpty = state.pages.isEmpty;
      final Map<String, LocalPage> existingPagesMap = { for (var p in state.pages) p.clientId: p };
      final List<LocalPage> finalPages = [];
      for (var i = 0; i < activePages.length; i++) {
        final newPage = activePages[i];
        final existing = existingPagesMap[newPage.clientId];
        if (existing != null && existing.isContentLoaded) {
          final bool isExternalUpdate = newPage.syncedWithCloud == 1 && existing.syncedWithCloud == 0;
          final bool isRemoteChange = newPage.updatedAt > (existing.updatedAt + 1000); 
          if (isExternalUpdate || (isRemoteChange && newPage.syncedWithCloud == 1)) { finalPages.add(newPage.copyWith(isContentLoaded: false)); final currentIndex = ref.read(canvasViewportProvider).currentPageIndex; if (i == currentIndex) unawaited(ensurePageLoaded(i)); }
          else { finalPages.add(newPage.copyWith(objects: existing.objects, viewportMatrix: existing.viewportMatrix, backgroundConfig: existing.backgroundConfig, isContentLoaded: true, version: existing.version)); }
        } else { finalPages.add(newPage); }
      }
      state = state.copyWith(pages: finalPages, isLoading: false);
      if (finalPages.isNotEmpty && wasEmpty) ensurePageLoaded(0);
    });
  }

  Future<void> ensurePageLoaded(int index) async {
    if (index < 0 || index >= state.pages.length) return;
    final page = state.pages[index];
    if (page.isContentLoaded || page.id == null) return;
    try {
      final content = await _repository.loadPageContent(page.id!, pageNumber: page.pageNumber);
      final updatedPages = List<LocalPage>.from(state.pages);
      updatedPages[index] = page.copyWith(objects: [...content['strokes'], ...content['textBlocks'], ...content['imageBlocks'], ...content['shapes'], ...content['audios'], ...content['animations'], ...content['tables'], ...content['links'], ...content['attachments']], isContentLoaded: true);
      state = state.copyWith(pages: updatedPages);
    } catch (e) {}
  }

  Future<void> addStroke(LocalPage p, Stroke s) async { final ns = s.copyWith(creatorId: state.myUserId, pageNumber: p.pageNumber, layerId: 'drawings'); await _executeAction(AddStrokeAction(pageClientId: p.clientId, pageNumber: p.pageNumber, stroke: ns), targetPage: p); }
  Future<void> addTextBlock(LocalPage page, TextBlock block) async { await _executeAction(AddTextAction(pageClientId: page.clientId, pageNumber: page.pageNumber, block: block.copyWith(layerId: 'text')), targetPage: page); }
  Future<void> addShape(LocalPage page, ShapeObject shape) async { await _executeAction(AddShapeAction(pageClientId: page.clientId, pageNumber: page.pageNumber, shape: shape.copyWith(layerId: 'drawings')), targetPage: page); }
  Future<void> addAudioBlock(LocalPage page, AudioBlock audio) async { await _executeAction(AddAudioAction(pageClientId: page.clientId, pageNumber: page.pageNumber, audio: audio.copyWith(layerId: 'default')), targetPage: page); }
  Future<void> addAnimation(LocalPage page, AnimationObject anim) async { await _executeAction(AddAnimationAction(pageClientId: page.clientId, pageNumber: page.pageNumber, animation: anim.copyWith(layerId: 'drawings')), targetPage: page); }
  Future<void> addTable(LocalPage page, TableObject table) async { await _executeAction(AddTableAction(pageClientId: page.clientId, pageNumber: page.pageNumber, table: table.copyWith(layerId: 'default')), targetPage: page); }
  Future<void> addLink(LocalPage page, LinkObject link) async { await _executeAction(AddLinkAction(pageClientId: page.clientId, pageNumber: page.pageNumber, link: link.copyWith(layerId: 'default')), targetPage: page); }
  Future<void> addAttachment(LocalPage page, AttachmentObject attach) async { await _executeAction(AddAttachmentAction(pageClientId: page.clientId, pageNumber: page.pageNumber, attach: attach.copyWith(layerId: 'default')), targetPage: page); }
  Future<void> deleteObjects(LocalPage page, List<String> objectIds) async { if (objectIds.isEmpty) return; await _executeAction(DeleteAction(pageClientId: page.clientId, pageNumber: page.pageNumber, objectIds: objectIds), targetPage: page); }
  Future<void> updateObject(LocalPage page, PageObject obj) async { final oldObj = page.objects.firstWhere((o) => o.id == obj.id); await _executeAction(UpdateObjectAction(pageClientId: page.clientId, pageNumber: page.pageNumber, objectId: obj.id, oldState: oldObj.toJson(), newState: obj.toJson()), targetPage: page); }

  Future<void> executeInteractionAction(CanvasAction action) async { await _executeAction(action); }

  Future<void> reorderObject(LocalPage page, int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final objects = List<PageObject>.from(page.objects);
    final item = objects.removeAt(oldIndex);
    objects.insert(newIndex, item);
    final List<PageObject> finalObjects = [];
    for (int i = 0; i < objects.length; i++) finalObjects.add(objects[i].copyWith(zIndex: i));
    final updatedPage = page.copyWith(objects: finalObjects);
    await _repository.savePage(updatedPage, state.liveNotebookSid);
    state = state.copyWith(pages: state.pages.map((p) => p.clientId == page.clientId ? updatedPage : p).toList());
  }

  Future<void> applyNaturalSort(LocalPage page) async {
    final objects = List<PageObject>.from(page.objects);
    int getTierWeight(PageObject o) { if (o is ImageBlock) return 10; if (o is ShapeObject || o is TableObject || o is LinkObject || o is AttachmentObject) return 20; if (o is TextBlock) return 30; if (o is Stroke) return 40; return 0; }
    objects.sort((a, b) { final wA = getTierWeight(a); final wB = getTierWeight(b); if (wA != wB) return wA.compareTo(wB); return a.zIndex.compareTo(b.zIndex); });
    final List<PageObject> finalObjects = [];
    for (int i = 0; i < objects.length; i++) finalObjects.add(objects[i].copyWith(zIndex: i));
    final updatedPage = page.copyWith(objects: finalObjects);
    await _repository.savePage(updatedPage, state.liveNotebookSid);
    state = state.copyWith(pages: state.pages.map((p) => p.clientId == page.clientId ? updatedPage : p).toList());
  }

  Future<void> cleanupIfEmpty(LocalPage page, String? blockId) async { if (blockId == null || blockId.startsWith('proxy_')) return; final block = page.objects.cast<PageObject?>().firstWhere((o) => o?.id == blockId, orElse: () => null); if (block is TextBlock && block.text.trim().isEmpty) await deleteObjects(page, [blockId]); }
  Future<void> updateLayerVisibility(LocalPage page, String layerId, bool isVisible) async { final updatedLayers = page.layers.map((l) => l.id == layerId ? l.copyWith(isVisible: isVisible) : l).toList(); _applyLayerChange(page, updatedLayers); }
  Future<void> updateLayerLock(LocalPage page, String layerId, bool isLocked) async { final updatedLayers = page.layers.map((l) => l.id == layerId ? l.copyWith(isLocked: isLocked) : l).toList(); _applyLayerChange(page, updatedLayers); }
  Future<void> addNewLayer(LocalPage page, String name) async { final newLayer = LayerDefinition(id: const Uuid().v4(), name: name); final updatedLayers = List<LayerDefinition>.from(page.layers)..add(newLayer); _applyLayerChange(page, updatedLayers); }
  Future<void> _applyLayerChange(LocalPage page, List<LayerDefinition> layers) async { final updatedPage = page.copyWith(layers: layers); await _repository.savePage(updatedPage, state.liveNotebookSid); state = state.copyWith(pages: state.pages.map((p) => p.clientId == page.clientId ? updatedPage : p).toList()); }

  Future<void> updateStrokesColor(LocalPage page, Set<String> strokeIds, String colorHex) async {
    final List<Stroke> updatedStrokes = [];
    final now = TimeService().nowMs();
    final newObjects = page.objects.map((o) { if (o is Stroke && strokeIds.contains(o.id)) { final updated = o.copyWith(color: colorHex, updatedAt: now); updatedStrokes.add(updated); return updated; } return o; }).toList();
    if (updatedStrokes.isNotEmpty) {
      final updatedPage = page.copyWith(objects: newObjects, updatedAt: now);
      state = state.copyWith(pages: state.pages.map((p) => p.clientId == page.clientId ? updatedPage : p).toList());
      for (var s in updatedStrokes) { await _repository.saveSingleStroke(page.clientId, s, pageId: page.id, updatedAt: now); _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: {'page_client_id': page.clientId, 'page_number': page.pageNumber, 'strokes': [s.toJson()]}); }
    }
  }

  Future<void> pixelErase(LocalPage page, Offset eraserPos, double radius, {bool isFinal = false, List<String>? deletedAccumulator, List<Stroke>? addedAccumulator}) async {
    bool changed = false; final List<Stroke> toAdd = []; final List<String> toDelete = []; final now = TimeService().nowMs();
    final newObjects = page.objects.map((o) { if (o is Stroke && !o.isDeleted) { final result = StrokeUtils.erasePartOfStroke(o, eraserPos, radius); if (result.length == 1 && listEquals(result.first.points, (o as Stroke).points)) return o; changed = true; toDelete.add(o.id); toAdd.addAll(result); return o.copyWith(isDeleted: true, updatedAt: now); } return o; }).toList();
    if (changed) { newObjects.addAll(toAdd); final updatedPage = page.copyWith(objects: newObjects, updatedAt: now); state = state.copyWith(pages: state.pages.map((p) => p.clientId == page.clientId ? updatedPage : p).toList()); if (deletedAccumulator != null) deletedAccumulator.addAll(toDelete); if (addedAccumulator != null) addedAccumulator.addAll(toAdd); if (state.liveNotebookSid != null) _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: {'page_client_id': page.clientId, 'strokes': [...toDelete.map((id) => {'id': id, 'is_deleted': true}), ...toAdd.map((s) => s.toJson())]}); }
  }

  Future<void> commitPixelErase(LocalPage page, List<String> deletedIds, List<Stroke> addedStrokes) async { if (deletedIds.isEmpty && addedStrokes.isEmpty) return; final action = PixelEraseAction(pageClientId: page.clientId, pageNumber: page.pageNumber, deletedStrokeIds: deletedIds.toSet().toList(), addedStrokes: addedStrokes); _undoRedoManager.addAction(action); state = state.copyWith(canUndo: _undoRedoManager.canUndo, canRedo: _undoRedoManager.canRedo); for (var id in deletedIds) await _repository.deleteObjectById(id); for (var s in addedStrokes) await _repository.saveSingleStroke(page.clientId, s, pageId: page.id); await _repository.markPageAsUnsynced(page.clientId); }

  Future<void> _executeAction(CanvasAction action, {bool isRemote = false, LocalPage? targetPage}) async {
    final target = targetPage ?? state.pages.cast<LocalPage?>().firstWhere((p) => p?.clientId == action.pageClientId, orElse: () => null);
    if (target == null || (target.isFrozen && !isRemote)) return;
    final updatedTarget = action.execute(target);
    if (!isRemote) _undoRedoManager.addAction(action);
    state = state.copyWith(pages: state.pages.map((p) => p.clientId == target.clientId ? updatedTarget : p).toList(), canUndo: _undoRedoManager.canUndo, canRedo: _undoRedoManager.canRedo);
    unawaited(_persistIncrementalAction(updatedTarget, action, updatedAt: isRemote ? null : updatedTarget.updatedAt));
    if (!isRemote) _broadcastAction(action);
  }

  void undo(LocalPage page) { final updatedTarget = _undoRedoManager.undo(page); if (updatedTarget != null) state = state.copyWith(pages: state.pages.map((p) => p.clientId == page.clientId ? updatedTarget : p).toList(), canUndo: _undoRedoManager.canUndo, canRedo: _undoRedoManager.canRedo); }
  void redo(LocalPage page) { final updatedTarget = _undoRedoManager.redo(page); if (updatedTarget != null) state = state.copyWith(pages: state.pages.map((p) => p.clientId == page.clientId ? updatedTarget : p).toList(), canUndo: _undoRedoManager.canUndo, canRedo: _undoRedoManager.canRedo); }

  Future<void> _persistIncrementalAction(LocalPage target, CanvasAction action, {int? updatedAt}) async {
    final String cid = target.clientId; final int? pid = target.id;
    try {
      if (action is GroupAction) {
        for (var oid in action.objectIds) {
          final obj = target.objects.cast<PageObject?>().firstWhere((o) => o?.id == oid, orElse: () => null);
          if (obj == null) continue;
          if (obj is Stroke) await _repository.saveSingleStroke(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is TextBlock) await _repository.saveSingleTextBlock(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is ImageBlock) await _repository.saveSingleImageBlock(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is ShapeObject) await _repository.saveSingleShape(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is TableObject) await _repository.saveSingleTable(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is LinkObject) await _repository.saveSingleLink(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is AttachmentObject) await _repository.saveSingleAttachment(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is AudioBlock) await _repository.saveSingleAudioBlock(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is AnimationObject) await _repository.saveSingleAnimationObject(cid, obj, pageId: pid, updatedAt: updatedAt);
        }
      } else if (action is AddStrokeAction) await _repository.saveSingleStroke(cid, action.stroke, pageId: pid, updatedAt: updatedAt);
      else if (action is AddTextAction) await _repository.saveSingleTextBlock(cid, action.block, pageId: pid, updatedAt: updatedAt);
      else if (action is AddImageAction) await _repository.saveSingleImageBlock(cid, action.block, pageId: pid, updatedAt: updatedAt);
      else if (action is AddShapeAction) await _repository.saveSingleShape(cid, action.shape, pageId: pid, updatedAt: updatedAt); 
      else if (action is AddAudioAction) await _repository.saveSingleAudioBlock(cid, action.audio, pageId: pid, updatedAt: updatedAt);
      else if (action is AddAnimationAction) await _repository.saveSingleAnimationObject(cid, action.animation, pageId: pid, updatedAt: updatedAt);
      else if (action is AddTableAction) await _repository.saveSingleTable(cid, action.table, pageId: pid, updatedAt: updatedAt); 
      else if (action is AddLinkAction) await _repository.saveSingleLink(cid, action.link, pageId: pid, updatedAt: updatedAt); 
      else if (action is AddAttachmentAction) await _repository.saveSingleAttachment(cid, action.attach, pageId: pid, updatedAt: updatedAt); 
      else if (action is MoveAction || action is UpdateObjectAction) {
        for (var oid in (action is MoveAction ? action.objectIds : [(action as UpdateObjectAction).objectId])) {
          final obj = target.objects.cast<PageObject?>().firstWhere((o) => o?.id == oid, orElse: () => null);
          if (obj == null) continue;
          if (obj is Stroke) await _repository.saveSingleStroke(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is TextBlock) await _repository.saveSingleTextBlock(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is ImageBlock) await _repository.saveSingleImageBlock(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is ShapeObject) await _repository.saveSingleShape(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is TableObject) await _repository.saveSingleTable(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is LinkObject) await _repository.saveSingleLink(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is AttachmentObject) await _repository.saveSingleAttachment(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is AudioBlock) await _repository.saveSingleAudioBlock(cid, obj, pageId: pid, updatedAt: updatedAt);
          else if (obj is AnimationObject) await _repository.saveSingleAnimationObject(cid, obj, pageId: pid, updatedAt: updatedAt);
        }
      }
      else if (action is DeleteAction) { for (var oid in action.objectIds) await _repository.deleteObjectById(oid); await _repository.markPageAsUnsynced(cid, updatedAt: updatedAt); }
    } catch (e) {}
  }

  void _broadcastAction(CanvasAction action) {
    if (!state.isCollaborationEnabled || state.liveNotebookSid == null) return;
    if (action is DeleteAction) _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: {'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'strokes': action.objectIds.map((id) => {'id': id, 'is_deleted': true}).toList()});
    else if (action is AddStrokeAction) _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: {'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'strokes': [action.stroke.toJson()]});
    else if (action is AddTextAction) _realtimeService.broadcastTextBlock(notebookId: state.liveNotebookSid!, textData: {'sender_id': state.myUserId, 'page_number': action.pageNumber, 'block': action.block.toJson(), 'is_editing': false});
    else if (action is MoveAction) _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: {'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'is_move': true, 'strokes': action.objectIds.map((id) { final obj = state.pages.firstWhere((p) => p.clientId == action.pageClientId).objects.firstWhere((o) => o.id == id); return {'id': id, 'type': obj.type, 'offset': {'x': obj.position.dx, 'y': obj.position.dy}, 'updated_at': obj.updatedAt}; }).toList()});
  }

  Future<void> addNewPage({required bool isLandscape, String paperSize = 'A4', bool isInfinite = false, String? lineType, double? lineSpacing, String? sectionTitle, int count = 1, int? insertIndex}) async { final int startPageNumber = (insertIndex ?? state.pages.length) + 1; if (insertIndex != null && insertIndex < state.pages.length) await _repository.shiftPageNumbers(state.currentNotebookId, insertIndex, count); for (int i = 0; i < count; i++) { final np = LocalPage(notebookId: state.currentNotebookId, pageNumber: startPageNumber + i, isLandscape: isLandscape, paperSize: paperSize, isInfinite: isInfinite, lineType: lineType, lineSpacing: lineSpacing, sectionTitle: sectionTitle); await _repository.savePage(np, state.liveNotebookSid); } await _repository.reindexPages(state.currentNotebookId); }
  Future<void> duplicatePage(LocalPage source) async { if (!source.isContentLoaded && source.id != null) { final content = await _repository.loadPageContent(source.id!, pageNumber: source.pageNumber); source = source.copyWith(objects: [...content['strokes'], ...content['textBlocks'], ...content['imageBlocks']], isContentLoaded: true); } final clonedPage = source.clone(newClientId: const Uuid().v4(), newPageNumber: source.pageNumber + 1); await _repository.savePage(clonedPage, state.liveNotebookSid); for (var obj in clonedPage.objects) { if (obj is Stroke) await _repository.saveSingleStroke(clonedPage.clientId, obj); else if (obj is TextBlock) await _repository.saveSingleTextBlock(clonedPage.clientId, obj); else if (obj is ImageBlock) await _repository.saveSingleImageBlock(clonedPage.clientId, obj); else if (obj is ShapeObject) await _repository.saveSingleShape(clonedPage.clientId, obj); else if (obj is TableObject) await _repository.saveSingleTable(clonedPage.clientId, obj); else if (obj is LinkObject) await _repository.saveSingleLink(clonedPage.clientId, obj); else if (obj is AttachmentObject) await _repository.saveSingleAttachment(clonedPage.clientId, obj); else if (obj is AudioBlock) await _repository.saveSingleAudioBlock(clonedPage.clientId, obj); else if (obj is AnimationObject) await _repository.saveSingleAnimationObject(clonedPage.clientId, obj); } await _repository.reindexPages(state.currentNotebookId); }
  Future<void> reorderPage(int oldIndex, int newIndex) async { if (oldIndex == newIndex) return; final list = List<LocalPage>.from(state.pages); final item = list.removeAt(oldIndex); list.insert(newIndex, item); state = state.copyWith(pages: list); final pageIds = list.map((p) => p.id).whereType<int>().toList(); await _repository.updatePageNumbersBatch(pageIds); }
  Future<void> updatePageSettings(LocalPage page, NotebookConfiguration newConfig) async { if (page.id == null) return; final updated = page.copyWith(isLandscape: newConfig.page.orientation == 'landscape', paperSize: newConfig.page.paperSize, isInfinite: newConfig.page.isInfinite, backgroundConfig: newConfig.background, lineType: newConfig.background.type, lineSpacing: newConfig.background.spacing, title: newConfig.header.enabled ? (newConfig.header.fields.isNotEmpty ? newConfig.header.fields.join(' / ') : page.title) : page.title, footer: newConfig.footer.enabled ? (newConfig.footer.fields.isNotEmpty ? newConfig.footer.fields.join(' / ') : page.footer) : page.footer, updatedAt: TimeService().nowMs()); await _repository.savePage(updated, state.liveNotebookSid); state = state.copyWith(pages: state.pages.map((p) => p.clientId == page.clientId ? updated : p).toList()); }
  Future<void> renamePage(LocalPage page, String newTitle) async { if (page.id == null) return; final updated = page.copyWith(title: newTitle, updatedAt: TimeService().nowMs()); await _repository.savePage(updated, state.liveNotebookSid); state = state.copyWith(pages: state.pages.map((p) => p.clientId == page.clientId ? updated : p).toList()); }
  Future<void> updatePageViewport(String clientId, Matrix4 matrix) async { final idx = state.pages.indexWhere((p) => p.clientId == clientId); if (idx == -1) return; final updated = state.pages[idx].copyWith(viewportMatrix: matrix, updatedAt: TimeService().nowMs()); state = state.copyWith(pages: state.pages.map((p) => p.clientId == clientId ? updated : p).toList()); await _repository.savePage(updated, state.liveNotebookSid); }
  Future<void> updatePageSection(LocalPage page, String? sectionTitle, {String? sectionColor}) async { if (page.id == null) return; final updated = page.copyWith(sectionTitle: sectionTitle, sectionColor: sectionColor, clearSection: sectionTitle == null || sectionTitle.isEmpty, updatedAt: TimeService().nowMs()); await _repository.savePage(updated, state.liveNotebookSid); state = state.copyWith(pages: state.pages.map((p) => p.clientId == page.clientId ? updated : p).toList()); }
  Future<void> toggleFavorite(LocalPage page) async { if (page.id == null) return; final updated = page.copyWith(isFavorite: !page.isFavorite, updatedAt: TimeService().nowMs()); await _repository.savePage(updated, state.liveNotebookSid); state = state.copyWith(pages: state.pages.map((p) => p.clientId == page.clientId ? updated : p).toList()); }
  Future<void> deletePages(List<LocalPage> pagesToDelete) async { final clientIds = pagesToDelete.map((p) => p.clientId).toSet(); state = state.copyWith(tearingPageClientIds: {...state.tearingPageClientIds, ...clientIds}); await Future.delayed(const Duration(milliseconds: 400)); final pageIds = pagesToDelete.map((p) => p.id).whereType<int>().toList(); await _repository.deletePagesBatch(pageIds); await _repository.reindexPages(state.currentNotebookId); state = state.copyWith(pages: state.pages.where((p) => !clientIds.contains(p.clientId)).toList(), tearingPageClientIds: state.tearingPageClientIds.where((id) => !clientIds.contains(id)).toSet()); }
  Future<void> pickAndInsertImage(LocalPage page) async { final pf = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85); if (pf != null) { final appDir = await getApplicationDocumentsDirectory(); final String newPath = '${appDir.path}/img_${TimeService().nowMs()}'; await io.File(pf.path).copy(newPath); final nib = ImageBlock(id: const Uuid().v4(), imagePath: newPath, position: const Offset(100, 150), width: 300.0, height: 200.0, creatorId: state.myUserId); await _executeAction(AddImageAction(pageClientId: page.clientId, pageNumber: page.pageNumber, block: nib), targetPage: page); } }
  Future<void> moveSelection(LocalPage page, {required List<String> strokeIds, required List<String> textIds, required List<String> imageIds, required List<String> shapeIds, required List<String> audioIds, required List<String> animationIds, required List<String> tableIds, required List<String> linkIds, required List<String> attachmentIds, required Offset delta}) async { if (page.isFrozen || delta == Offset.zero) return; final action = MoveAction(pageClientId: page.clientId, pageNumber: page.pageNumber, objectIds: [...strokeIds, ...textIds, ...imageIds, ...shapeIds, ...audioIds, ...animationIds, ...tableIds, ...linkIds, ...attachmentIds], delta: delta); await _executeAction(action, targetPage: page); }
  Future<void> deletePage(LocalPage page) async { await deletePages([page]); }
  Future<void> movePageToOtherNotebook(LocalPage page, int targetNotebookId) async { final targetPages = await _repository.getPagesByNotebook(targetNotebookId, null); final int newPageNumber = targetPages.length + 1; await _repository.movePageToNotebook(page.clientId, targetNotebookId, newPageNumber); await _repository.reindexPages(state.currentNotebookId); await _repository.reindexPages(targetNotebookId); }
  Future<void> copyPageToOtherNotebook(LocalPage page, int targetNotebookId) async { if (!page.isContentLoaded && page.id != null) { final content = await _repository.loadPageContent(page.id!, pageNumber: page.pageNumber); page = page.copyWith(objects: [...content['strokes'], ...content['textBlocks'], ...content['imageBlocks']], isContentLoaded: true); } final targetPages = await _repository.getPagesByNotebook(targetNotebookId, null); final int newPageNumber = targetPages.length + 1; final clonedPage = page.clone(newNotebookId: targetNotebookId, newPageNumber: newPageNumber); await _repository.savePage(clonedPage, null); for (var obj in clonedPage.objects) { if (obj is Stroke) await _repository.saveSingleStroke(clonedPage.clientId, obj); else if (obj is TextBlock) await _repository.saveSingleTextBlock(clonedPage.clientId, obj); else if (obj is ImageBlock) await _repository.saveSingleImageBlock(clonedPage.clientId, obj); else if (obj is ShapeObject) await _repository.saveSingleShape(clonedPage.clientId, obj); else if (obj is TableObject) await _repository.saveSingleTable(clonedPage.clientId, obj); else if (obj is LinkObject) await _repository.saveSingleLink(clonedPage.clientId, obj); else if (obj is AttachmentObject) await _repository.saveSingleAttachment(clonedPage.clientId, obj); else if (obj is AudioBlock) await _repository.saveSingleAudioBlock(clonedPage.clientId, obj); else if (obj is AnimationObject) await _repository.saveSingleAnimationObject(clonedPage.clientId, obj); } await _repository.reindexPages(targetNotebookId); }
  Future<void> updatePagesSection(List<LocalPage> pagesToUpdate, String? sectionTitle, {String? sectionColor}) async { for (var page in pagesToUpdate) { if (page.id != null) { final hData = {'title': page.title, 'section': sectionTitle, 'section_color': sectionColor ?? page.sectionColor}; await _repository.updatePagesSectionBatch([page.id!], hData); } } await _performCollectiveSync(); }
  Future<List<LocalPage>> getDeletedPages() async { return await _repository.getDeletedPages(state.currentNotebookId); }
  Future<void> restorePage(LocalPage page) async { await _repository.restorePage(page.clientId); await _repository.reindexPages(state.currentNotebookId); }
  void reset() { _pagesSubscription?.cancel(); _collabService.leaveSession(); state = CanvasDocumentState(); }

  Future<void> _performCollectiveSync() async { if (state.isGlobalSyncing) return; state = state.copyWith(isGlobalSyncing: true); try { if (state.currentUserRole == 'owner' || state.currentUserRole == 'editor') await _syncService.pushPages(onlyNotebookId: state.currentNotebookId); await _syncService.pullPages(forceFull: true, onlyNotebookId: state.liveNotebookSid); } finally { state = state.copyWith(isGlobalSyncing: false); } }
  Future<void> _handleRemoteAction(Map<String, dynamic> d) async { final action = CanvasAction.fromMap(d['action_type'] ?? d['type'], d['data']); if (action != null) { final target = state.pages.cast<LocalPage?>().firstWhere((p) => p?.clientId == action.pageClientId, orElse: () => null); if (target != null) { final updatedTarget = (d['type'] == 'sync_undo') ? action.undo(target) : action.execute(target); state = state.copyWith(pages: state.pages.map((p) => p.clientId == target.clientId ? updatedTarget : p).toList()); } } }
  Future<void> _handlePageEvent(Map<String, dynamic> d) async { if (d['action'] == 'add' || d['action'] == 'delete' || d['action'] == 'reorder') await _performCollectiveSync(); }
  Future<void> _handleFullStateRequest(Map<String, dynamic> d) async { final idx = state.pages.indexWhere((p) => p.pageNumber == d['page_number']); if (idx != -1 && state.liveNotebookSid != null) _realtimeService.deliverFullState(notebookId: state.liveNotebookSid!, targetUserId: d['sender_id'].toString(), pageData: state.pages[idx].toJson()); }
  Future<void> _handleFullStateReceived(Map<String, dynamic> d) async { final Map<String, dynamic> pageData = d['page_data']; final idx = state.pages.indexWhere((p) => p.pageNumber == pageData['page_number']); if (idx != -1) { final np = LocalPage.fromJson(pageData).copyWith(id: state.pages[idx].id); final updatedPages = List<LocalPage>.from(state.pages); updatedPages[idx] = np; await _repository.savePage(np, state.liveNotebookSid); state = state.copyWith(pages: updatedPages); } }
  void _autoNavigateAfterDeletion() { if (state.pages.isEmpty) return; final viewportNotifier = ref.read(canvasViewportProvider.notifier); final currentIndex = ref.read(canvasViewportProvider).currentPageIndex; int targetIndex = (currentIndex >= state.pages.length) ? state.pages.length - 1 : currentIndex; viewportNotifier.jumpToPage(targetIndex < 0 ? 0 : targetIndex); }
  void _startSmoothTransition(Matrix4 target) { final viewportState = ref.read(canvasViewportProvider); if (viewportState.currentPageClientId == null) return; final controller = ref.read(canvasViewportProvider.notifier).getControllerFor(viewportState.currentPageClientId!); Timer.periodic(const Duration(milliseconds: 16), (t) { final current = controller.value; final next = Matrix4.identity(); for (int i = 0; i < 16; i++) next.storage[i] = current.storage[i] + (target.storage[i] - current.storage[i]) * 0.04; controller.value = next; double diff = 0; for (int i = 0; i < 16; i++) diff += (next.storage[i] - target.storage[i]).abs(); if (diff < 0.001) { controller.value = target; t.cancel(); } }); }
}

final canvasDocumentProvider = NotifierProvider.autoDispose<CanvasDocumentNotifier, CanvasDocumentState>(() { return CanvasDocumentNotifier(); });
