import 'dart:async';
import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import '../models/local_page_model.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../models/image_block_model.dart';
import '../models/canvas_action_model.dart';
import '../repositories/canvas_repository.dart';
import '../../../core/network/realtime_service.dart';
import '../../../core/network/sync_service.dart';
import '../services/audio_session_service.dart';
import '../services/collaboration_room_service.dart';
import '../../../core/network/sync_provider.dart';

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
    // 🛡️ USAR READ PARA ESTABILIDADE: Evita rebuilds circulares se os serviços mudarem internamente
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
    debugPrint('🚀 [DocumentNotifier] Inicializando caderno ID: $notebookId, SID: $notebookSid');
    state = state.copyWith(
      isLoading: true,
      currentNotebookId: notebookId,
      liveNotebookSid: notebookSid,
      currentUserRole: role,
      currentTemplateType: templateType ?? 'study',
      myUserId: userId ?? '',
    );

    await _audioService.loadLessonRecordings(notebookId);

    _pagesSubscription?.cancel();
    _pagesSubscription = _repository.watchPagesByNotebook(notebookId).listen((newPagesFromDb) {
      debugPrint('📄 [DocumentNotifier] Stream Drift emitiu ${newPagesFromDb.length} páginas');
      final activePages = newPagesFromDb.where((p) => !p.isDeleted).toList();
      activePages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
      
      final bool wasEmpty = state.pages.isEmpty;

      // 🚀 LÓGICA DE MERGE (Drift -> Memória)
      for (var i = 0; i < activePages.length; i++) {
        final existingPageInState = state.pages.cast<LocalPage?>().firstWhere(
          (p) => p?.clientId == activePages[i].clientId, 
          orElse: () => null
        );
        
        if (existingPageInState != null && existingPageInState.isContentLoaded) {
          activePages[i].strokes = existingPageInState.strokes;
          activePages[i].textBlocks = existingPageInState.textBlocks;
          activePages[i].imageBlocks = existingPageInState.imageBlocks;
          activePages[i].isContentLoaded = true;
          activePages[i].version = existingPageInState.version;
        }
      }

      state = state.copyWith(
        pages: activePages,
        isLoading: false,
      );

      if (activePages.isNotEmpty && wasEmpty) {
        debugPrint('🎯 [DocumentNotifier] Forçando carga da primeira página');
        ensurePageLoaded(0);
      }
    });
  }

  Future<void> ensurePageLoaded(int index) async {
    if (index < 0 || index >= state.pages.length) return;
    final page = state.pages[index];
    if (page.isContentLoaded || page.id == null) return;

    try {
      debugPrint('📖 [DocumentNotifier] Carregando conteúdo da página ${page.pageNumber}');
      final content = await _repository.loadPageContent(page.id!);
      
      // Atualizar a página específica mantendo a reatividade
      final updatedPages = List<LocalPage>.from(state.pages);
      updatedPages[index] = page.copyWith(
        strokes: content['strokes'],
        textBlocks: content['textBlocks'],
        imageBlocks: content['imageBlocks'],
      )..isContentLoaded = true;

      state = state.copyWith(pages: updatedPages);
    } catch (e) {
      debugPrint('🚨 [DocumentNotifier] Erro no LazyLoad: $e');
    }
  }

  Future<void> addStroke(LocalPage p, Stroke s) async {
    final ns = Stroke(
      id: s.id, 
      color: s.color, 
      thickness: s.thickness, 
      points: s.points, 
      creatorId: state.myUserId, 
      pageNumber: p.pageNumber,
      isHighlighter: s.isHighlighter, // 🚀 Preservar flag
    );
    
    final action = AddStrokeAction(pageClientId: p.clientId, pageNumber: p.pageNumber, stroke: ns);
    await _executeAction(action, targetPage: p);
  }

  Future<void> addTextBlock(LocalPage page, TextBlock block) async {
    final action = AddTextAction(pageClientId: page.clientId, pageNumber: page.pageNumber, block: block);
    await _executeAction(action, targetPage: page);
  }

  Future<void> _executeAction(CanvasAction action, {bool isRemote = false, LocalPage? targetPage}) async {
    final target = targetPage ?? state.pages.firstWhere((p) => p.clientId == action.pageClientId);
    if (target.isFrozen && !isRemote) return;
    
    // Incrementar versão para forçar Repaint nas camadas
    target.version++;
    action.execute(target);
    
    final newUndoStack = List<CanvasAction>.from(state.undoStack)..add(action);
    if (newUndoStack.length > 50) newUndoStack.removeAt(0);
    
    state = state.copyWith(
      pages: List.from(state.pages),
      undoStack: newUndoStack,
      redoStack: [],
    );

    // Persistência em background
    unawaited(_persistIncrementalAction(target, action));
    if (!isRemote) _broadcastAction(action);
  }

  Future<void> _persistIncrementalAction(LocalPage target, CanvasAction action) async {
    final String cid = target.clientId;
    try {
      if (action is AddStrokeAction) await _repository.saveSingleStroke(cid, action.stroke);
      else if (action is AddTextAction) await _repository.saveSingleTextBlock(cid, action.block);
      else if (action is AddImageAction) await _repository.saveSingleImageBlock(cid, action.block);
      else if (action is UpdateTextAction) await _repository.saveSingleTextBlock(cid, action.newState);
      else if (action is UpdateImageAction) await _repository.saveSingleImageBlock(cid, action.newState);
      if (action is DeleteAction) { 
        for (var s in action.strokes) await _repository.deleteSingleStroke(s.id); 
        for (var t in action.texts) await _repository.deleteSingleTextBlock(t.id); 
        for (var i in action.images) await _repository.saveSingleImageBlock(cid, i); 
      }
    } catch (e) {
      debugPrint('🚨 [DocumentNotifier] Erro ao persistir ação: $e');
    }
  }

  void _broadcastAction(CanvasAction action) {
    if (!state.isCollaborationEnabled || state.liveNotebookSid == null) return;
    
    if (action is DeleteAction) {
      for (var s in action.strokes) _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: { 'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'strokes': [{'id': s.id, 'is_deleted': true}] });
    } else if (action is AddStrokeAction) {
      final s = action.stroke;
      _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: { 'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'strokes': [s.toJson()] });
    }
  }

  Future<void> addNewPage(bool isLandscape, {String paperSize = 'A4'}) async {
    final requestedPageNumber = (state.pages.isEmpty ? 0 : state.pages.last.pageNumber) + 1;
    final String clientId = const Uuid().v4();
    
    final np = LocalPage(
      notebookId: state.currentNotebookId, 
      pageNumber: requestedPageNumber, 
      isLandscape: isLandscape, 
      paperSize: paperSize, 
      clientId: clientId
    );
    
    await _repository.savePage(np, state.liveNotebookSid);
    // Nota: O state será atualizado automaticamente via stream do Drift
  }

  Future<void> deletePage(LocalPage page) async {
    if (page.id == null) return;
    
    state = state.copyWith(tearingPageClientIds: {...state.tearingPageClientIds, page.clientId});
    await Future.delayed(const Duration(milliseconds: 400));
    
    // Deletar localmente
    final d = ref.read(canvasRepositoryProvider).db; // Precisamos expor a db no provider ou repository
    await (d.delete(d.pages)..where((t) => t.id.equals(page.id!))).go();
    await _repository.reindexPages(state.currentNotebookId);
    
    state = state.copyWith(
      tearingPageClientIds: state.tearingPageClientIds.where((id) => id != page.clientId).toSet(),
    );
  }

  void undo(LocalPage page) {
    if (state.undoStack.isEmpty) return;
    final action = state.undoStack.last;
    action.undo(page);
    page.version++;
    
    state = state.copyWith(
      pages: List.from(state.pages),
      undoStack: state.undoStack.sublist(0, state.undoStack.length - 1),
      redoStack: [...state.redoStack, action],
    );
  }

  void redo(LocalPage page) {
    if (state.redoStack.isEmpty) return;
    final action = state.redoStack.last;
    action.execute(page);
    page.version++;
    
    state = state.copyWith(
      pages: List.from(state.pages),
      undoStack: [...state.undoStack, action],
      redoStack: state.redoStack.sublist(0, state.redoStack.length - 1),
    );
  }

  void setLineType(LocalPage page, String type) {
    page.lineType = type;
    _repository.savePage(page, state.liveNotebookSid);
    // UI atualiza via stream do Drift
  }

  Future<void> pickAndInsertImage(LocalPage page) async {
    final pf = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pf != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final String path = '${appDir.path}/img_${DateTime.now().millisecondsSinceEpoch}';
      await io.File(pf.path).copy(path);
      
      final nib = ImageBlock(
        id: const Uuid().v4(), 
        imagePath: path, 
        position: const Offset(100, 150), 
        width: 300.0, 
        height: 200.0, 
        creatorId: state.myUserId
      );
      
      final action = AddImageAction(pageClientId: page.clientId, pageNumber: page.pageNumber, block: nib);
      await _executeAction(action, targetPage: page);
    }
  }
}

final canvasDocumentProvider = NotifierProvider.autoDispose<CanvasDocumentNotifier, CanvasDocumentState>(() {
  return CanvasDocumentNotifier();
});
