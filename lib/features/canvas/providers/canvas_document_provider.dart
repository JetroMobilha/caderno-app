import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart'; // 🚀 Adicionado para kIsWeb
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:caderno_digital_app/core/utils/rdp_simplifier.dart';
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

    // 🚀 Configurar Callbacks de Colaboração
    _collabService.onSyncRequested = () => _performCollectiveSync();
    _collabService.onExecuteAction = (d) => _handleRemoteAction(d);
    _collabService.onPageEvent = (d) => _handlePageEvent(d);
    _collabService.onFullStateRequested = (d) => _handleFullStateRequest(d);
    _collabService.onFullStateReceived = (d) => _handleFullStateReceived(d);
    _collabService.onCloudSyncSignal = (d) => _syncService.pullSpecificPage(notebookSid!, d['page_number']);
    _collabService.onSmoothTransition = (m) => _startSmoothTransition(m);
    _collabService.onPageNavigationRequested = (i) => ref.read(canvasViewportProvider.notifier).jumpToPage(i);
    _collabService.onAutoNavigateAfterDeletion = () => _autoNavigateAfterDeletion();

    _audioService.onAudioMessageProcessed = (d) => _collabService.chatMessages.add(d);

    _pagesSubscription?.cancel();
    _pagesSubscription = _repository.watchPagesByNotebook(notebookId).listen((newPagesFromDb) async {
      debugPrint('📄 [DocumentNotifier] Stream Drift emitiu ${newPagesFromDb.length} páginas');
      final activePages = newPagesFromDb.where((p) => !p.isDeleted).toList();
      activePages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
      
      final bool wasEmpty = state.pages.isEmpty;

      // 🚀 ON-DEMAND SYNC: Se entramos num caderno e ele está vazio localmente,
      // disparamos o download das páginas da nuvem.
      if (activePages.isEmpty && notebookSid != null && !state.isGlobalSyncing) {
        debugPrint('☁️ [DocumentNotifier] Caderno vazio localmente. Iniciando Pull da Cloud...');
        // Marcamos como syncing para a UI saber e não mostrar "Nenhuma página" prematuramente
        state = state.copyWith(isGlobalSyncing: true);
        try {
          await _syncService.pullPages(onlyNotebookId: notebookSid);
        } finally {
          state = state.copyWith(isGlobalSyncing: false);
        }
        return; // O stream voltará a emitir assim que o pull inserir no banco
      }

      // 🚀 LÓGICA DE MERGE (Drift -> Memória) OTIMIZADA
      final Map<String, LocalPage> existingPagesMap = {
        for (var p in state.pages) p.clientId: p
      };

      for (var i = 0; i < activePages.length; i++) {
        final existing = existingPagesMap[activePages[i].clientId];
        
        if (existing != null && existing.isContentLoaded) {
          activePages[i].strokes = existing.strokes;
          activePages[i].textBlocks = existing.textBlocks;
          activePages[i].imageBlocks = existing.imageBlocks;
          activePages[i].isContentLoaded = true;
          activePages[i].version = existing.version;
          
          if (activePages[i].syncedWithCloud == 1 && existing.syncedWithCloud == 0) {
             for (var s in activePages[i].strokes) s.syncedWithCloud = true;
             for (var t in activePages[i].textBlocks) t.syncedWithCloud = true;
             for (var img in activePages[i].imageBlocks) img.syncedWithCloud = true;
          }
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
    // 🚀 OTIMIZAÇÃO: Simplificação de pontos antes de commitar
    final simplifiedPoints = RdpSimplifier.simplify(s.points, 0.2);

    final ns = Stroke(
      id: s.id, 
      color: s.color, 
      thickness: s.thickness, 
      points: simplifiedPoints, 
      creatorId: state.myUserId, 
      pageNumber: p.pageNumber,
      isHighlighter: s.isHighlighter,
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

  void broadcastLiveStroke({
    required String pageClientId,
    required int pageNumber,
    required String strokeId,
    required List<Offset> points,
    required String color,
    required double thickness,
    required bool isHighlighter,
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
        'points': points.map((pt) => {'x': pt.dx, 'y': pt.dy}).toList()
      }]
    };

    _realtimeService.broadcastStroke(
      notebookId: state.liveNotebookSid!,
      myUserId: state.myUserId,
      strokeData: data,
    );
  }

  Future<void> _persistIncrementalAction(LocalPage target, CanvasAction action) async {
    final String cid = target.clientId;
    final int? pid = target.id;
    try {
      if (action is AddStrokeAction) await _repository.saveSingleStroke(cid, action.stroke, pageId: pid);
      else if (action is AddTextAction) await _repository.saveSingleTextBlock(cid, action.block, pageId: pid);
      else if (action is AddImageAction) await _repository.saveSingleImageBlock(cid, action.block, pageId: pid);
      else if (action is UpdateTextAction) await _repository.saveSingleTextBlock(cid, action.newState, pageId: pid);
      else if (action is UpdateImageAction) await _repository.saveSingleImageBlock(cid, action.newState, pageId: pid);
      if (action is DeleteAction) { 
        for (var s in action.strokes) await _repository.deleteSingleStroke(s.id); 
        for (var t in action.texts) await _repository.deleteSingleTextBlock(t.id); 
        for (var i in action.images) await _repository.saveSingleImageBlock(cid, i, pageId: pid); 
      }
    } catch (e) {
      debugPrint('🚨 [DocumentNotifier] Erro ao persistir ação: $e');
    }
  }

  void _broadcastAction(CanvasAction action) {
    if (!state.isCollaborationEnabled || state.liveNotebookSid == null) return;
    
    if (action is DeleteAction) {
      for (var s in action.strokes) _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: { 'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'strokes': [{'id': s.id, 'is_deleted': true}] });
      for (var t in action.texts) _realtimeService.broadcastTextBlock(notebookId: state.liveNotebookSid!, textData: { 'sender_id': state.myUserId, 'page_number': action.pageNumber, 'block': t.toJson(), 'is_deleted': true });
      for (var i in action.images) _realtimeService.broadcastImageBlock(notebookId: state.liveNotebookSid!, imageData: { 'sender_id': state.myUserId, 'page_number': action.pageNumber, 'block': i.toJson(), 'is_deleted': true });
    } else if (action is AddStrokeAction) {
      final s = action.stroke;
      _realtimeService.broadcastStroke(notebookId: state.liveNotebookSid!, myUserId: state.myUserId, strokeData: { 'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'strokes': [s.toJson()] });
    } else if (action is AddTextAction) {
      _realtimeService.broadcastTextBlock(notebookId: state.liveNotebookSid!, textData: { 'sender_id': state.myUserId, 'page_number': action.pageNumber, 'block': action.block.toJson(), 'is_editing': false });
    } else if (action is UpdateTextAction) {
      _realtimeService.broadcastTextBlock(notebookId: state.liveNotebookSid!, textData: { 'sender_id': state.myUserId, 'page_number': action.pageNumber, 'block': action.newState.toJson(), 'is_editing': false });
    } else if (action is AddImageAction) {
      _realtimeService.broadcastImageBlock(notebookId: state.liveNotebookSid!, imageData: { 'sender_id': state.myUserId, 'page_number': action.pageNumber, 'block': action.block.toJson(), 'is_deleted': false });
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

  Future<void> deleteSelection(LocalPage page, {
    required Set<String> strokeIds,
    required Set<String> textIds,
    required Set<String> imageIds,
  }) async {
    if (page.isFrozen) return;

    final sR = page.strokes.where((s) => !s.isDeleted && strokeIds.contains(s.id)).toList();
    final tR = page.textBlocks.where((t) => !t.isDeleted && textIds.contains(t.id)).toList();
    final iR = page.imageBlocks.where((i) => !i.isDeleted && imageIds.contains(i.id)).toList();

    if (sR.isEmpty && tR.isEmpty && iR.isEmpty) return;

    final action = DeleteAction(
      pageClientId: page.clientId,
      pageNumber: page.pageNumber,
      strokes: sR.map((s) => s.clone()).toList(),
      texts: tR.map((t) => t.clone()).toList(),
      images: iR.map((i) => i.clone()).toList(),
    );

    await _executeAction(action, targetPage: page);
  }

  Future<void> moveSelection(LocalPage page, {
    required List<String> strokeIds,
    required List<String> textIds,
    required List<String> imageIds,
    required Offset delta,
  }) async {
    if (page.isFrozen || delta == Offset.zero) return;

    final action = MoveAction(
      pageClientId: page.clientId,
      pageNumber: page.pageNumber,
      strokeIds: strokeIds,
      textIds: textIds,
      imageIds: imageIds,
      delta: delta,
    );

    await _executeAction(action, targetPage: page);
  }

  Future<void> pickAndInsertImage(LocalPage page) async {
    final pf = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pf != null) {
      String path = pf.path;
      
      // 🚀 COMPATIBILIDADE WEB: Não usar io.File nem caminhos locais
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final String newPath = '${appDir.path}/img_${DateTime.now().millisecondsSinceEpoch}';
        await io.File(pf.path).copy(newPath);
        path = newPath;
      }
      
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

  void reset() {
    _pagesSubscription?.cancel();
    _collabService.leaveSession();
    state = CanvasDocumentState();
  }

  // -------------------------------------------------------------------------
  // 🛡️ [COLLABORATION HANDLERS]
  // -------------------------------------------------------------------------

  Future<void> _performCollectiveSync() async {
    if (state.isGlobalSyncing) return;
    state = state.copyWith(isGlobalSyncing: true);
    try {
      if (state.currentUserRole == 'owner' || state.currentUserRole == 'editor') {
        await _syncService.pushPages(onlyNotebookId: state.currentNotebookId);
      }
      await _syncService.pullPages(forceFull: true, onlyNotebookId: state.liveNotebookSid);
      // O stream do Drift atualizará o estado
    } finally {
      state = state.copyWith(isGlobalSyncing: false);
    }
  }

  Future<void> _handleRemoteAction(Map<String, dynamic> d) async {
    final action = CanvasAction.fromMap(d['action_type'] ?? d['type'], d['data']);
    if (action != null) {
      final target = state.pages.cast<LocalPage?>().firstWhere(
        (p) => p?.clientId == action.pageClientId, 
        orElse: () => null
      );
      if (target != null) {
        if (d['type'] == 'sync_undo') action.undo(target); 
        else action.execute(target);
        target.version++;
        state = state.copyWith(pages: List.from(state.pages));
      }
    }
  }

  Future<void> _handlePageEvent(Map<String, dynamic> d) async {
    if (d['action'] == 'add' || d['action'] == 'delete') {
      await _performCollectiveSync();
    }
  }

  Future<void> _handleFullStateRequest(Map<String, dynamic> d) async {
    final idx = state.pages.indexWhere((p) => p.pageNumber == d['page_number']);
    if (idx != -1 && state.liveNotebookSid != null) {
      _realtimeService.deliverFullState(
        notebookId: state.liveNotebookSid!, 
        targetUserId: d['sender_id'].toString(), 
        pageData: state.pages[idx].toJson()
      );
    }
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
    final controller = ref.read(canvasViewportProvider.notifier).transformationController;
    Timer.periodic(const Duration(milliseconds: 16), (t) {
      final current = controller.value;
      final next = Matrix4.identity();
      for (int i = 0; i < 16; i++) {
        next.storage[i] = current.storage[i] + (target.storage[i] - current.storage[i]) * 0.04;
      }
      controller.value = next;
      
      double diff = 0;
      for (int i = 0; i < 16; i++) {
        diff += (next.storage[i] - target.storage[i]).abs();
      }
      if (diff < 0.001) {
        controller.value = target;
        t.cancel();
      }
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
