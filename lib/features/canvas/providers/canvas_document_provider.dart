import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:drift/drift.dart' hide Column;
import 'package:caderno_digital_app/core/database/app_database.dart';
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
import '../../../core/network/sync_provider.dart';
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
  final List<CanvasAction> undoStack;
  final List<CanvasAction> redoStack;
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
    this.undoStack = const [],
    this.redoStack = const [],
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
    List<CanvasAction>? undoStack,
    List<CanvasAction>? redoStack,
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
      undoStack: undoStack ?? this.undoStack,
      redoStack: redoStack ?? this.redoStack,
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
  StreamSubscription? _pagesSubscription;

  @override
  CanvasDocumentState build() {
    _repository = ref.read(canvasRepositoryProvider);
    _realtimeService = ref.read(realtimeServiceProvider);
    _syncService = ref.read(appSyncServiceProvider);
    _audioService = ref.read(audioSessionServiceProvider);
    _collabService = ref.read(collaborationRoomServiceProvider);

    ref.onDispose(() {
      _pagesSubscription?.cancel();
    });

    return CanvasDocumentState();
  }

  Future<void> initNotebook(int notebookId, int? notebookSid, String role, String? userId, {String? templateType}) async {
    state = state.copyWith(
      isLoading: false,
      currentNotebookId: notebookId,
      liveNotebookSid: notebookSid,
      currentUserRole: role,
      currentTemplateType: templateType ?? 'study',
      myUserId: userId ?? '',
    );

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

    _audioService.onAudioMessageProcessed = (d) => _collabService.chatMessages.add(d);

    _pagesSubscription?.cancel();
    _pagesSubscription = _repository.watchPagesByNotebook(notebookId).listen((newPagesFromDb) {
      final List<LocalPage> activePages = newPagesFromDb.where((p) => !p.isDeleted).toList();
      activePages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));

      if (state.pages.length == activePages.length) {
        bool listIdentical = true;
        for (int i = 0; i < activePages.length; i++) {
          if (activePages[i].clientId != state.pages[i].clientId || 
              activePages[i].updatedAt != state.pages[i].updatedAt ||
              activePages[i].syncedWithCloud != state.pages[i].syncedWithCloud) {
            listIdentical = false;
            break;
          }
        }
        if (listIdentical) return;
      }
      
      final bool wasEmpty = state.pages.isEmpty;

      final Map<String, LocalPage> existingPagesMap = {
        for (var p in state.pages) p.clientId: p
      };

      for (var i = 0; i < activePages.length; i++) {
        final newPage = activePages[i];
        final existing = existingPagesMap[newPage.clientId];
        
        if (existing != null && existing.isContentLoaded) {
          final bool isExternalUpdate = newPage.syncedWithCloud == 1 && existing.syncedWithCloud == 0;
          final bool isRemoteChange = newPage.updatedAt > (existing.updatedAt + 1000); 

          if (isExternalUpdate || (isRemoteChange && newPage.syncedWithCloud == 1)) {
            debugPrint('🔄 [CanvasDoc] Reload Externo detectado para p${newPage.pageNumber}');
            newPage.isContentLoaded = false;
            final currentIndex = ref.read(canvasViewportProvider).currentPageIndex;
            if (i == currentIndex) unawaited(ensurePageLoaded(i));
          } else {
            newPage.objects = existing.objects;
            newPage.viewportMatrix ??= existing.viewportMatrix;
            newPage.backgroundConfig ??= existing.backgroundConfig;
            
            newPage.isContentLoaded = true;
            newPage.version = existing.version;
          }
        }
      }

      state = state.copyWith(pages: activePages, isLoading: false);
      if (activePages.isNotEmpty && wasEmpty) ensurePageLoaded(0);
    });
  }

  Future<void> ensurePageLoaded(int index) async {
    if (index < 0 || index >= state.pages.length) return;
    final page = state.pages[index];
    if (page.isContentLoaded || page.id == null) return;
    try {
      final content = await _repository.loadPageContent(page.id!, pageNumber: page.pageNumber);
      final updatedPages = List<LocalPage>.from(state.pages);
      updatedPages[index] = page.copyWith(
        objects: [
          ...content['strokes'], 
          ...content['textBlocks'], 
          ...content['imageBlocks'],
          ...content['shapes'],
          ...content['audios'],
          ...content['animations'],
          ...content['tables'],
          ...content['links'],
          ...content['attachments'],
        ],
      )..isContentLoaded = true;
      state = state.copyWith(pages: updatedPages);
    } catch (e) {
      debugPrint('🚨 LazyLoad Error: $e');
    }
  }

  Future<void> addStroke(LocalPage p, Stroke s) async {
    final simplifiedPoints = RdpSimplifier.simplify(s.points, 0.2);
    final ns = Stroke(
      id: s.id, 
      color: s.color, 
      thickness: s.thickness, 
      points: simplifiedPoints, 
      creatorId: state.myUserId, 
      pageNumber: p.pageNumber, 
      isHighlighter: s.isHighlighter,
      brushType: s.brushType, // 🚀 v1.8: Persistência explícita
      isSmoothed: s.isSmoothed, // 🚀 v1.8: Persistência explícita
      layerId: 'drawings', 
    );
    final action = AddStrokeAction(pageClientId: p.clientId, pageNumber: p.pageNumber, stroke: ns);
    await _executeAction(action, targetPage: p);
  }

  Future<void> addTextBlock(LocalPage page, TextBlock block) async {
    block.layerId = 'text'; 
    final action = AddTextAction(pageClientId: page.clientId, pageNumber: page.pageNumber, block: block);
    await _executeAction(action, targetPage: page);
  }

  Future<void> addShape(LocalPage page, ShapeObject shape) async {
    shape.layerId = 'drawings';
    final action = AddShapeAction(pageClientId: page.clientId, pageNumber: page.pageNumber, shape: shape);
    await _executeAction(action, targetPage: page);
  }

  Future<void> addAudioBlock(LocalPage page, AudioBlock audio) async {
    audio.layerId = 'default';
    final action = AddAudioAction(pageClientId: page.clientId, pageNumber: page.pageNumber, audio: audio);
    await _executeAction(action, targetPage: page);
  }

  Future<void> addAnimation(LocalPage page, AnimationObject anim) async {
    anim.layerId = 'drawings';
    final action = AddAnimationAction(pageClientId: page.clientId, pageNumber: page.pageNumber, animation: anim);
    await _executeAction(action, targetPage: page);
  }

  Future<void> addTable(LocalPage page, TableObject table) async {
    table.layerId = 'default';
    final action = AddTableAction(pageClientId: page.clientId, pageNumber: page.pageNumber, table: table);
    await _executeAction(action, targetPage: page);
  }

  Future<void> addLink(LocalPage page, LinkObject link) async {
    link.layerId = 'default';
    final action = AddLinkAction(pageClientId: page.clientId, pageNumber: page.pageNumber, link: link);
    await _executeAction(action, targetPage: page);
  }

  Future<void> addAttachment(LocalPage page, AttachmentObject attach) async {
    attach.layerId = 'default';
    final action = AddAttachmentAction(pageClientId: page.clientId, pageNumber: page.pageNumber, attach: attach);
    await _executeAction(action, targetPage: page);
  }

  Future<void> deleteObjects(LocalPage page, List<String> objectIds) async {
    if (objectIds.isEmpty) return;
    final action = DeleteAction(
      pageClientId: page.clientId, 
      pageNumber: page.pageNumber, 
      objectIds: objectIds
    );
    await _executeAction(action, targetPage: page);
  }

  Future<void> updateObject(LocalPage page, PageObject obj) async {
    final oldObj = page.objects.firstWhere((o) => o.id == obj.id);
    final action = UpdateObjectAction(
      pageClientId: page.clientId,
      pageNumber: page.pageNumber,
      objectId: obj.id,
      oldState: oldObj.toJson(),
      newState: obj.toJson(),
    );
    await _executeAction(action, targetPage: page);
  }

  // 🚀 v4.0: Reordenar objetos individualmente (Z-Order)
  Future<void> reorderObject(LocalPage page, int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    
    final objects = List<PageObject>.from(page.objects);
    final item = objects.removeAt(oldIndex);
    objects.insert(newIndex, item);
    
    // Atualizar z-index baseado na nova posição para persistência
    for (int i = 0; i < objects.length; i++) {
      objects[i].zIndex = i;
    }

    final updatedPage = page.copyWith(objects: objects);
    await _repository.savePage(updatedPage, state.liveNotebookSid);
    
    state = state.copyWith(pages: List.from(state.pages));
    
    if (state.liveNotebookSid != null) {
      _collabService.broadcastPageEvent('reorder_objects', {'page_client_id': page.clientId});
    }
  }

  // 🚀 v4.1: Aplicar Ordenação Natural de Camadas
  Future<void> applyNaturalSort(LocalPage page) async {
    final objects = List<PageObject>.from(page.objects);
    
    // Pesos de hierarquia (Ordem de renderização: menor zIndex fica no fundo)
    int getTierWeight(PageObject o) {
      if (o is ImageBlock) return 10;
      if (o is ShapeObject || o is TableObject || o is LinkObject || o is AttachmentObject) return 20;
      if (o is TextBlock) return 30;
      if (o is Stroke) return 40;
      return 0;
    }

    // Ordenar por tipo e depois manter a ordem relativa original dentro do tipo
    objects.sort((a, b) {
      final wA = getTierWeight(a);
      final wB = getTierWeight(b);
      if (wA != wB) return wA.compareTo(wB);
      return a.zIndex.compareTo(b.zIndex);
    });

    // Recalcular z-index sequencial
    for (int i = 0; i < objects.length; i++) {
      objects[i].zIndex = i;
    }

    final updatedPage = page.copyWith(objects: objects);
    await _repository.savePage(updatedPage, state.liveNotebookSid);
    
    state = state.copyWith(pages: List.from(state.pages));
    
    if (state.liveNotebookSid != null) {
      _collabService.broadcastPageEvent('reorder_objects', {'page_client_id': page.clientId});
    }
  }

  // 🚀 v4.2: Limpar bloco de texto se estiver vazio
  Future<void> cleanupIfEmpty(LocalPage page, String? blockId) async {
    if (blockId == null) return;
    final block = page.objects.cast<PageObject?>().firstWhere((o) => o?.id == blockId, orElse: () => null);
    if (block is TextBlock && block.text.trim().isEmpty) {
      await deleteObjects(page, [blockId]);
    }
  }

  Future<void> updateLayerVisibility(LocalPage page, String layerId, bool isVisible) async {
    final updatedLayers = page.layers.map((l) {
      if (l.id == layerId) return l.copyWith(isVisible: isVisible);
      return l;
    }).toList();
    _applyLayerChange(page, updatedLayers);
  }

  Future<void> updateLayerLock(LocalPage page, String layerId, bool isLocked) async {
    final updatedLayers = page.layers.map((l) {
      if (l.id == layerId) return l.copyWith(isLocked: isLocked);
      return l;
    }).toList();
    _applyLayerChange(page, updatedLayers);
  }

  Future<void> addNewLayer(LocalPage page, String name) async {
    final newLayer = LayerDefinition(id: const Uuid().v4(), name: name);
    final updatedLayers = List<LayerDefinition>.from(page.layers)..add(newLayer);
    _applyLayerChange(page, updatedLayers);
  }

  Future<void> _applyLayerChange(LocalPage page, List<LayerDefinition> layers) async {
    final updatedPage = page.copyWith(layers: layers);
    await _repository.savePage(updatedPage, state.liveNotebookSid);
    
    final updatedList = List<LocalPage>.from(state.pages);
    final idx = updatedList.indexWhere((p) => p.clientId == page.clientId);
    if (idx != -1) {
      updatedList[idx] = updatedPage;
      state = state.copyWith(pages: updatedList);
    }
  }

  Future<void> updateStrokesColor(LocalPage page, Set<String> strokeIds, String colorHex) async {
    final List<Stroke> updatedStrokes = [];
    final now = TimeService().nowMs();
    for (var s in page.strokes) {
      if (strokeIds.contains(s.id)) {
        final updated = s.clone()..color = colorHex..updatedAt = now;
        updatedStrokes.add(updated);
        await _repository.saveSingleStroke(page.clientId, updated, pageId: page.id, updatedAt: now);
      }
    }
    if (updatedStrokes.isNotEmpty) {
      page.version++;
      page.updatedAt = now; 
      state = state.copyWith(pages: List.from(state.pages));
      for (var s in updatedStrokes) {
        _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: {'page_client_id': page.clientId, 'page_number': page.pageNumber, 'strokes': [s.toJson()]});
      }
    }
  }

  // 🚀 v2.1: Borracha de Precisão com suporte a Undo/Redo e Memória de Estilo
  Future<void> pixelErase(LocalPage page, Offset eraserPos, double radius, {bool isFinal = false, List<String>? deletedAccumulator, List<Stroke>? addedAccumulator}) async {
    bool changed = false;
    final List<Stroke> toAdd = [];
    final List<String> toDelete = [];
    final now = TimeService().nowMs();

    // 1. Identificar traços afetados (apenas os visíveis)
    final activeStrokes = page.objects.whereType<Stroke>().where((s) => !s.isDeleted).toList();

    for (var s in activeStrokes) {
      final result = StrokeUtils.erasePartOfStroke(s, eraserPos, radius);
      
      // Se o resultado for diferente do original, houve corte
      if (result.length == 1 && listEquals(result.first.points, s.points)) continue;
      
      changed = true;
      toDelete.add(s.id);
      toAdd.addAll(result);
      
      // 🚀 v2.1: Marcar como deletado na lista REAL de objetos imediatamente para feedback visual
      s.isDeleted = true;
      s.updatedAt = now;
    }

    if (changed) {
      // Adicionar novos segmentos à lista real
      page.objects.addAll(toAdd);
      page.version++;
      
      // Notificar UI (Rebuild rápido)
      state = state.copyWith(pages: List.from(state.pages));

      // Se estivermos num acumulador (para Undo final), guardar as mudanças
      if (deletedAccumulator != null) deletedAccumulator.addAll(toDelete);
      if (addedAccumulator != null) addedAccumulator.addAll(toAdd);

      // Broadcast em tempo real para outros
      if (state.liveNotebookSid != null) {
        _realtimeService.broadcastStroke(
          notebookId: state.liveNotebookSid!, 
          myUserId: state.myUserId, 
          strokeData: {
            'page_client_id': page.clientId, 
            'strokes': [
              ...toDelete.map((id) => {'id': id, 'is_deleted': true}),
              ...toAdd.map((s) => s.toJson())
            ]
          }
        );
      }
    }
  }

  // 🚀 v2.1: Finalizar a sessão de borracha e gravar no Undo/Redo e DB
  Future<void> commitPixelErase(LocalPage page, List<String> deletedIds, List<Stroke> addedStrokes) async {
    if (deletedIds.isEmpty && addedStrokes.isEmpty) return;

    final action = PixelEraseAction(
      pageClientId: page.clientId,
      pageNumber: page.pageNumber,
      deletedStrokeIds: deletedIds.toSet().toList(), // Remover duplicados
      addedStrokes: addedStrokes,
    );

    // 1. Gravar no Histórico (Undo/Redo)
    final newUndoStack = List<CanvasAction>.from(state.undoStack)..add(action);
    if (newUndoStack.length > 50) newUndoStack.removeAt(0);
    state = state.copyWith(undoStack: newUndoStack, redoStack: []);

    // 2. Persistir no Banco de Dados
    final cid = page.clientId;
    final pid = page.id;
    for (var id in deletedIds) {
      await _repository.deleteSingleStroke(id);
    }
    for (var s in addedStrokes) {
      await _repository.saveSingleStroke(cid, s, pageId: pid);
    }
    await _repository.markPageAsUnsynced(cid);
    
    debugPrint('🧹 [CanvasDoc] Borracha de Precisão gravada: ${deletedIds.length} removidos, ${addedStrokes.length} criados.');
  }

  Future<void> _executeAction(CanvasAction action, {bool isRemote = false, LocalPage? targetPage}) async {
    final target = targetPage ?? state.pages.cast<LocalPage?>().firstWhere((p) => p?.clientId == action.pageClientId, orElse: () => null);
    if (target == null || (target.isFrozen && !isRemote)) return;

    final now = TimeService().nowMs();
    target.version++;
    if (!isRemote) target.updatedAt = now; 

    action.execute(target);
    final newUndoStack = List<CanvasAction>.from(state.undoStack)..add(action);
    if (newUndoStack.length > 50) newUndoStack.removeAt(0);
    state = state.copyWith(pages: List.from(state.pages), undoStack: newUndoStack, redoStack: []);
    
    unawaited(_persistIncrementalAction(target, action, updatedAt: isRemote ? null : now));
    if (!isRemote) _broadcastAction(action);
  }

  void broadcastLiveStroke({
    required String pageClientId,
    required int pageNumber,
    required String strokeId,
    required List<Offset> points,
    required String color,
    required double thickness,
    required bool isHighlighter,
    BrushType brushType = BrushType.gel, // 🚀 v1.2
    bool isSmoothed = false,           // 🚀 v1.2
    bool isFinal = false,
  }) {
    if (!state.isCollaborationEnabled || state.liveNotebookSid == null) return;
    final data = {
      'page_client_id': pageClientId,
      'page_number': pageNumber,
      'strokes': [{
        'id': strokeId,
        'color': color,
        'thickness': thickness,
        'is_final': isFinal,
        'is_highlighter': isHighlighter ? 1 : 0,
        'brush_type': brushType.name,
        'is_smoothed': isSmoothed ? 1 : 0,
        'points': points.map((pt) => {'x': pt.dx, 'y': pt.dy}).toList()
      }]
    };
    _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: data);
  }

  Future<void> _persistIncrementalAction(LocalPage target, CanvasAction action, {int? updatedAt}) async {
    final String cid = target.clientId;
    final int? pid = target.id;
    try {
      if (action is AddStrokeAction) await _repository.saveSingleStroke(cid, action.stroke, pageId: pid, updatedAt: updatedAt);
      else if (action is AddTextAction) await _repository.saveSingleTextBlock(cid, action.block, pageId: pid, updatedAt: updatedAt);
      else if (action is AddImageAction) await _repository.saveSingleImageBlock(cid, action.block, pageId: pid, updatedAt: updatedAt);
      else if (action is AddShapeAction) await _repository.saveSingleShape(cid, action.shape, pageId: pid, updatedAt: updatedAt); 
      else if (action is AddAudioAction) await _repository.saveSingleAudioBlock(cid, action.audio, pageId: pid, updatedAt: updatedAt);
      else if (action is AddAnimationAction) await _repository.saveSingleAnimationObject(cid, action.animation, pageId: pid, updatedAt: updatedAt);
      else if (action is AddTableAction) await _repository.saveSingleTable(cid, action.table, pageId: pid, updatedAt: updatedAt); 
      else if (action is AddLinkAction) await _repository.saveSingleLink(cid, action.link, pageId: pid, updatedAt: updatedAt); 
      else if (action is AddAttachmentAction) await _repository.saveSingleAttachment(cid, action.attach, pageId: pid, updatedAt: updatedAt); 
      else if (action is MoveAction) {
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
      }
      else if (action is UpdateObjectAction) {
        final type = action.newState['type'];
        if (type == 'text') await _repository.saveSingleTextBlock(cid, TextBlock.fromJson(action.newState), pageId: pid, updatedAt: updatedAt);
        else if (type == 'image') await _repository.saveSingleImageBlock(cid, ImageBlock.fromJson(action.newState), pageId: pid, updatedAt: updatedAt);
        else if (type == 'stroke') await _repository.saveSingleStroke(cid, Stroke.fromJson(action.newState), pageId: pid, updatedAt: updatedAt);
        else if (type == 'shape') await _repository.saveSingleShape(cid, ShapeObject.fromJson(action.newState), pageId: pid, updatedAt: updatedAt);
        else if (type == 'audio') await _repository.saveSingleAudioBlock(cid, AudioBlock.fromJson(action.newState), pageId: pid, updatedAt: updatedAt);
        else if (type == 'animation') await _repository.saveSingleAnimationObject(cid, AnimationObject.fromJson(action.newState), pageId: pid, updatedAt: updatedAt);
        else if (type == 'table') await _repository.saveSingleTable(cid, TableObject.fromJson(action.newState), pageId: pid, updatedAt: updatedAt); 
        else if (type == 'link') await _repository.saveSingleLink(cid, LinkObject.fromJson(action.newState), pageId: pid, updatedAt: updatedAt); 
        else if (type == 'attachment') await _repository.saveSingleAttachment(cid, AttachmentObject.fromJson(action.newState), pageId: pid, updatedAt: updatedAt); 
      }
      else if (action is DeleteAction) { 
        for (var oid in action.objectIds) {
          final obj = target.objects.cast<PageObject?>().firstWhere((o) => o?.id == oid, orElse: () => null);
          if (obj == null) continue;
          
          if (obj is Stroke) await _repository.deleteSingleStroke(oid);
          else if (obj is TextBlock) await _repository.deleteSingleTextBlock(oid);
          else if (obj is ImageBlock) await _repository.deleteSingleImageBlock(oid);
          else if (obj is ShapeObject) await _repository.deleteSingleShape(oid);
          else if (obj is TableObject) await _repository.deleteSingleTable(oid);
          else if (obj is LinkObject) await _repository.deleteSingleLink(oid);
          else if (obj is AttachmentObject) await _repository.deleteSingleAttachment(oid);
          else if (obj is AudioBlock) await _repository.deleteSingleAudio(oid);
          else if (obj is AnimationObject) await _repository.deleteSingleAnimation(oid);
        }
        await _repository.markPageAsUnsynced(cid, updatedAt: updatedAt);
      }
    } catch (e) { debugPrint('🚨 Persist Error: $e'); }
  }

  void _broadcastAction(CanvasAction action) {
    if (!state.isCollaborationEnabled || state.liveNotebookSid == null) return;
    if (action is DeleteAction) {
      _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: {
        'page_client_id': action.pageClientId, 
        'page_number': action.pageNumber, 
        'strokes': action.objectIds.map((id) => {'id': id, 'is_deleted': true}).toList()
      });
    } else if (action is AddStrokeAction) {
      _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: {'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'strokes': [action.stroke.toJson()]});
    } else if (action is AddTextAction) {
      _realtimeService.broadcastTextBlock(notebookId: state.liveNotebookSid!, textData: {'sender_id': state.myUserId, 'page_number': action.pageNumber, 'block': action.block.toJson(), 'is_editing': false});
    } else if (action is AddShapeAction) { 
      _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: {
        'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'shapes': [action.shape.toJson()]
      });
    } else if (action is AddAudioAction) { 
      _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: {
        'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'audios': [action.audio.toJson()]
      });
    } else if (action is AddAnimationAction) { 
      _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: {
        'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'animations': [action.animation.toJson()]
      });
    } else if (action is AddTableAction) { 
      _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: {
        'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'tables': [action.table.toJson()]
      });
    } else if (action is AddLinkAction) { 
      _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: {
        'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'links': [action.link.toJson()]
      });
    } else if (action is AddAttachmentAction) { 
      _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: {
        'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'attachments': [action.attach.toJson()]
      });
    }
  }

  Future<void> addNewPage({
    required bool isLandscape, 
    String paperSize = 'A4', 
    bool isInfinite = false, 
    String? lineType, 
    double? lineSpacing, 
    String? sectionTitle,
    int count = 1,
    int? insertIndex,
  }) async {
    final int startPageNumber = (insertIndex ?? state.pages.length) + 1;

    if (insertIndex != null && insertIndex < state.pages.length) {
      final d = ref.read(canvasRepositoryProvider).db;
      await d.batch((batch) {
        for (int i = insertIndex; i < state.pages.length; i++) {
          final page = state.pages[i];
          if (page.id != null) {
            batch.update(d.pages, PagesCompanion(
              pageNumber: Value(page.pageNumber + count),
              updatedAt: Value(TimeService().nowMs()),
              syncedWithCloud: const Value(0),
            ), where: (t) => t.id.equals(page.id!));
          }
        }
      });
    }

    for (int i = 0; i < count; i++) {
      final np = LocalPage(
        notebookId: state.currentNotebookId,
        pageNumber: startPageNumber + i,
        isLandscape: isLandscape,
        paperSize: paperSize,
        isInfinite: isInfinite, 
        lineType: lineType,
        lineSpacing: lineSpacing,
        sectionTitle: sectionTitle,
      );
      await _repository.savePage(np, state.liveNotebookSid);
    }

    await _repository.reindexPages(state.currentNotebookId);
    
    if (state.liveNotebookSid != null) {
      _collabService.broadcastPageEvent('add', {'count': count, 'at': startPageNumber});
    }
  }

  Future<void> duplicatePage(LocalPage source) async {
    if (!source.isContentLoaded && source.id != null) {
      final content = await _repository.loadPageContent(source.id!);
      source = source.copyWith(
        objects: [...content['strokes'], ...content['textBlocks'], ...content['imageBlocks']],
      )..isContentLoaded = true;
    }

    final clonedPage = source.clone(
      newClientId: const Uuid().v4(),
      newPageNumber: source.pageNumber + 1,
    );

    await _repository.savePage(clonedPage, state.liveNotebookSid);
    
    for (var s in clonedPage.strokes) await _repository.saveSingleStroke(clonedPage.clientId, s, pageId: null);
    for (var t in clonedPage.textBlocks) await _repository.saveSingleTextBlock(clonedPage.clientId, t, pageId: null);
    for (var i in clonedPage.imageBlocks) await _repository.saveSingleImageBlock(clonedPage.clientId, i, pageId: null);
    
    for (var obj in clonedPage.objects) {
      if (obj is ShapeObject) await _repository.saveSingleShape(clonedPage.clientId, obj, pageId: null);
      else if (obj is TableObject) await _repository.saveSingleTable(clonedPage.clientId, obj, pageId: null);
      else if (obj is LinkObject) await _repository.saveSingleLink(clonedPage.clientId, obj, pageId: null);
      else if (obj is AttachmentObject) await _repository.saveSingleAttachment(clonedPage.clientId, obj, pageId: null);
      else if (obj is AudioBlock) await _repository.saveSingleAudioBlock(clonedPage.clientId, obj, pageId: null);
      else if (obj is AnimationObject) await _repository.saveSingleAnimationObject(clonedPage.clientId, obj, pageId: null);
    }
    
    await _repository.reindexPages(state.currentNotebookId);
  }

  Future<void> duplicatePages(List<LocalPage> sources) async {
    for (var s in sources) await duplicatePage(s);
  }

  Future<void> reorderPage(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final List<LocalPage> list = List.from(state.pages);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    
    state = state.copyWith(pages: list);

    final d = ref.read(canvasRepositoryProvider).db;
    await d.batch((batch) {
      for (int i = 0; i < list.length; i++) {
        if (list[i].id != null) {
          batch.update(d.pages, PagesCompanion(
            pageNumber: Value(i + 1), 
            updatedAt: Value(TimeService().nowMs()),
            syncedWithCloud: const Value(0), 
          ), where: (t) => t.id.equals(list[i].id!));
        }
      }
    });

    if (state.liveNotebookSid != null) {
      _collabService.broadcastPageEvent('reorder', {});
      unawaited(_syncService.pushPages(onlyNotebookId: state.currentNotebookId));
    }
  }

  Future<void> updatePageSettings(LocalPage page, NotebookConfiguration newConfig) async {
    if (page.id == null) return;
    
    final updated = page.copyWith(
      isLandscape: newConfig.page.orientation == 'landscape',
      paperSize: newConfig.page.paperSize,
      isInfinite: newConfig.page.isInfinite,
      backgroundConfig: newConfig.background,
      lineType: newConfig.background.type,
      lineSpacing: newConfig.background.spacing,
      title: newConfig.header.enabled ? (newConfig.header.fields.isNotEmpty ? newConfig.header.fields.join(' / ') : page.title) : page.title,
      footer: newConfig.footer.enabled ? (newConfig.footer.fields.isNotEmpty ? newConfig.footer.fields.join(' / ') : page.footer) : page.footer,
      updatedAt: TimeService().nowMs(),
    );

    await _repository.savePage(updated, state.liveNotebookSid);
    
    final updatedPages = List<LocalPage>.from(state.pages);
    final idx = updatedPages.indexWhere((p) => p.clientId == page.clientId);
    if (idx != -1) {
      updatedPages[idx] = updated;
      state = state.copyWith(pages: updatedPages);
    }

    if (state.liveNotebookSid != null) {
      _collabService.broadcastPageEvent('update_settings', {'page_client_id': page.clientId});
    }
  }

  Future<void> renamePage(LocalPage page, String newTitle) async {
    if (page.id == null) return;
    await _repository.savePageFromMap(
      page.copyWith(title: newTitle, updatedAt: TimeService().nowMs()).toJson(),
      state.liveNotebookSid,
      isLocalEdit: true,
    );
    unawaited(_syncService.pushPages(onlyNotebookId: state.currentNotebookId));
  }

  Future<void> updatePageViewport(String clientId, Matrix4 matrix) async {
    final idx = state.pages.indexWhere((p) => p.clientId == clientId);
    if (idx == -1) return;

    final page = state.pages[idx];
    final now = TimeService().nowMs();
    
    final updated = page.copyWith(
      viewportMatrix: matrix,
      objects: page.objects, 
      updatedAt: now, 
    );
    
    final newList = List<LocalPage>.from(state.pages);
    newList[idx] = updated;
    state = state.copyWith(pages: newList);

    await _repository.savePageFromMap(
      updated.toJson(), 
      state.liveNotebookSid, 
      isLocalEdit: true
    );
  }

  Future<void> updatePageSection(LocalPage page, String? sectionTitle, {String? sectionColor}) async {
    if (page.id == null) return;
    final updated = page.copyWith(
      sectionTitle: sectionTitle,
      sectionColor: sectionColor,
      clearSection: sectionTitle == null || sectionTitle.isEmpty,
      updatedAt: TimeService().nowMs(),
    );
    await _repository.savePageFromMap(updated.toJson(), state.liveNotebookSid, isLocalEdit: true);
    unawaited(_syncService.pushPages(onlyNotebookId: state.currentNotebookId));
  }

  Future<void> updatePagesSection(List<LocalPage> pagesToUpdate, String? sectionTitle, {String? sectionColor}) async {
    final d = ref.read(canvasRepositoryProvider).db;
    await d.batch((batch) {
      for (var page in pagesToUpdate) {
        if (page.id != null) {
          final hData = {
            'title': page.title, 
            'section': sectionTitle,
            'section_color': sectionColor ?? page.sectionColor,
          };
          batch.update(d.pages, PagesCompanion(
            headerData: Value(jsonEncode(hData)), 
            updatedAt: Value(TimeService().nowMs()),
            syncedWithCloud: const Value(0), 
          ), where: (t) => t.id.equals(page.id!));
        }
      }
    });

    if (state.liveNotebookSid != null) {
      _collabService.broadcastPageEvent('update_structure', {});
      unawaited(_syncService.pushPages(onlyNotebookId: state.currentNotebookId));
    }
  }

  Future<void> toggleFavorite(LocalPage page) async {
    if (page.id == null) return;
    await _repository.savePage(page.copyWith(isFavorite: !page.isFavorite, updatedAt: TimeService().nowMs()), state.liveNotebookSid);
  }

  void setLineType(LocalPage page, String type) {
    page.lineType = type;
    _repository.savePage(page, state.liveNotebookSid);
  }

  Future<void> deletePage(LocalPage page) async {
    await deletePages([page]);
  }

  Future<void> deletePages(List<LocalPage> pagesToDelete) async {
    final clientIds = pagesToDelete.map((p) => p.clientId).toSet();
    state = state.copyWith(tearingPageClientIds: {...state.tearingPageClientIds, ...clientIds});
    await Future.delayed(const Duration(milliseconds: 400));
    final d = ref.read(canvasRepositoryProvider).db;
    await d.batch((batch) {
      for (var page in pagesToDelete) {
        if (page.id != null) {
          batch.update(d.pages, PagesCompanion(
            isDeleted: const Value(1),
            syncedWithCloud: const Value(0),
            updatedAt: Value(TimeService().nowMs()),
          ), where: (t) => t.id.equals(page.id!));
        }
      }
    });
    await _repository.reindexPages(state.currentNotebookId);
    state = state.copyWith(tearingPageClientIds: state.tearingPageClientIds.where((id) => !clientIds.contains(id)).toSet());
    if (state.liveNotebookSid != null) _collabService.broadcastPageEvent('delete', {});
  }

  Future<void> restorePage(LocalPage page) async {
    await _repository.restorePage(page.clientId);
    await _repository.reindexPages(state.currentNotebookId);
    unawaited(_syncService.pushPages(onlyNotebookId: state.currentNotebookId));
  }

  Future<void> movePageToOtherNotebook(LocalPage page, int targetNotebookId) async {
    final targetPages = await _repository.getPagesByNotebook(targetNotebookId, null);
    final int newPageNumber = targetPages.length + 1;
    await _repository.movePageToNotebook(page.clientId, targetNotebookId, newPageNumber);
    await _repository.reindexPages(state.currentNotebookId);
    await _repository.reindexPages(targetNotebookId);
    unawaited(_syncService.pushPages(onlyNotebookId: state.currentNotebookId));
    unawaited(_syncService.pushPages(onlyNotebookId: targetNotebookId));
  }

  Future<void> copyPageToOtherNotebook(LocalPage page, int targetNotebookId) async {
    if (!page.isContentLoaded && page.id != null) {
      final content = await _repository.loadPageContent(page.id!, pageNumber: page.pageNumber);
      page = page.copyWith(
        objects: [...content['strokes'], ...content['textBlocks'], ...content['imageBlocks']],
      )..isContentLoaded = true;
    }
    final targetPages = await _repository.getPagesByNotebook(targetNotebookId, null);
    final int newPageNumber = targetPages.length + 1;
    final clonedPage = page.clone(
      newNotebookId: targetNotebookId,
      newPageNumber: newPageNumber,
    );
    await _repository.savePage(clonedPage, null);
    for (var s in clonedPage.strokes) await _repository.saveSingleStroke(clonedPage.clientId, s);
    for (var t in clonedPage.textBlocks) await _repository.saveSingleTextBlock(clonedPage.clientId, t);
    for (var i in clonedPage.imageBlocks) await _repository.saveSingleImageBlock(clonedPage.clientId, i);
    await _repository.reindexPages(targetNotebookId);
    unawaited(_syncService.pushPages(onlyNotebookId: targetNotebookId));
  }

  Future<List<LocalPage>> getDeletedPages() async {
    return await _repository.getDeletedPages(state.currentNotebookId);
  }

  Future<void> moveSelection(
    LocalPage page, {
    required List<String> strokeIds, 
    required List<String> textIds, 
    required List<String> imageIds, 
    required List<String> shapeIds, 
    required List<String> audioIds, 
    required List<String> animationIds, 
    required List<String> tableIds,
    required List<String> linkIds,
    required List<String> attachmentIds,
    required Offset delta
  }) async {
    if (page.isFrozen || delta == Offset.zero) return;
    final action = MoveAction(
      pageClientId: page.clientId, 
      pageNumber: page.pageNumber, 
      objectIds: [...strokeIds, ...textIds, ...imageIds, ...shapeIds, ...audioIds, ...animationIds, ...tableIds, ...linkIds, ...attachmentIds], 
      delta: delta
    );
    await _executeAction(action, targetPage: page);
  }

  void undo(LocalPage page) {
    if (state.undoStack.isEmpty) return;
    final action = state.undoStack.last;
    action.undo(page);
    page.version++;
    state = state.copyWith(pages: List.from(state.pages), undoStack: state.undoStack.sublist(0, state.undoStack.length - 1), redoStack: [...state.redoStack, action]);
  }

  void redo(LocalPage page) {
    if (state.redoStack.isEmpty) return;
    final action = state.redoStack.last;
    action.execute(page);
    page.version++;
    state = state.copyWith(pages: List.from(state.pages), undoStack: [...state.undoStack, action], redoStack: state.redoStack.sublist(0, state.redoStack.length - 1));
  }

  Future<void> pickAndInsertImage(LocalPage page) async {
    final pf = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pf != null) {
      String path = pf.path;
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final String newPath = '${appDir.path}/img_${TimeService().nowMs()}';
        await io.File(pf.path).copy(newPath);
        path = newPath;
      }
      final nib = ImageBlock(id: const Uuid().v4(), imagePath: path, position: const Offset(100, 150), width: 300.0, height: 200.0, creatorId: state.myUserId);
      final action = AddImageAction(pageClientId: page.clientId, pageNumber: page.pageNumber, block: nib);
      await _executeAction(action, targetPage: page);
    }
  }

  void reset() {
    _pagesSubscription?.cancel();
    _collabService.leaveSession();
    state = CanvasDocumentState();
  }

  Future<void> _performCollectiveSync() async {
    if (state.isGlobalSyncing) return;
    state = state.copyWith(isGlobalSyncing: true);
    try {
      if (state.currentUserRole == 'owner' || state.currentUserRole == 'editor') await _syncService.pushPages(onlyNotebookId: state.currentNotebookId);
      await _syncService.pullPages(forceFull: true, onlyNotebookId: state.liveNotebookSid);
    } finally { state = state.copyWith(isGlobalSyncing: false); }
  }

  Future<void> _handleRemoteAction(Map<String, dynamic> d) async {
    final action = CanvasAction.fromMap(d['action_type'] ?? d['type'], d['data']);
    if (action != null) {
      final target = state.pages.cast<LocalPage?>().firstWhere((p) => p?.clientId == action.pageClientId, orElse: () => null);
      if (target != null) {
        if (d['type'] == 'sync_undo') action.undo(target); else action.execute(target);
        target.version++;
        state = state.copyWith(pages: List.from(state.pages));
      }
    }
  }

  Future<void> _handlePageEvent(Map<String, dynamic> d) async {
    if (d['action'] == 'add' || d['action'] == 'delete' || d['action'] == 'reorder') await _performCollectiveSync();
  }

  Future<void> _handleFullStateRequest(Map<String, dynamic> d) async {
    final idx = state.pages.indexWhere((p) => p.pageNumber == d['page_number']);
    if (idx != -1 && state.liveNotebookSid != null) _realtimeService.deliverFullState(notebookId: state.liveNotebookSid!, targetUserId: d['sender_id'].toString(), pageData: state.pages[idx].toJson());
  }

  Future<void> _handleFullStateReceived(Map<String, dynamic> d) async {
    final Map<String, dynamic> pageData = d['page_data'];
    final idx = state.pages.indexWhere((p) => p.pageNumber == pageData['page_number']);
    if (idx != -1) {
      final np = LocalPage.fromJson(pageData);
      np.id = state.pages[idx].id;
      final updatedPages = List<LocalPage>.from(state.pages);
      updatedPages[idx] = np;
      await _repository.savePage(np, state.liveNotebookSid);
      state = state.copyWith(pages: updatedPages);
    }
  }

  void _startSmoothTransition(Matrix4 target) {
    final viewportState = ref.read(canvasViewportProvider);
    if (viewportState.currentPageClientId == null) return;
    
    final controller = ref.read(canvasViewportProvider.notifier).getControllerFor(viewportState.currentPageClientId!);
    Timer.periodic(const Duration(milliseconds: 16), (t) {
      final current = controller.value;
      final next = Matrix4.identity();
      for (int i = 0; i < 16; i++) next.storage[i] = current.storage[i] + (target.storage[i] - current.storage[i]) * 0.04;
      controller.value = next;
      double diff = 0;
      for (int i = 0; i < 16; i++) diff += (next.storage[i] - target.storage[i]).abs();
      if (diff < 0.001) { controller.value = target; t.cancel(); }
    });
  }

  void _autoNavigateAfterDeletion() {
    if (state.pages.isEmpty) return;
    final viewportNotifier = ref.read(canvasViewportProvider.notifier);
    final currentIndex = ref.read(canvasViewportProvider).currentPageIndex;
    int targetIndex = (currentIndex >= state.pages.length) ? state.pages.length - 1 : currentIndex;
    viewportNotifier.jumpToPage(targetIndex < 0 ? 0 : targetIndex);
  }
}

final canvasDocumentProvider = NotifierProvider.autoDispose<CanvasDocumentNotifier, CanvasDocumentState>(() {
  return CanvasDocumentNotifier();
});
