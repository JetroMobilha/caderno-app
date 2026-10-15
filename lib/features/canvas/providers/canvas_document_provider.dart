import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/config/app_config.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:caderno_digital_app/core/utils/stroke_utils.dart';
import '../../notebooks/models/notebook_configuration.dart';
import '../models/animation_object_model.dart';
import '../models/attachment_model.dart';
import '../models/audio_block_model.dart';
import 'package:caderno_digital_app/features/explanations/models/explanation_model.dart';
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
import '../services/collaboration_history_manager.dart';
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

  final Set<String> uploadingAttachmentIds; // 🚀 v10
  final Set<String> attachmentUploadErrors; // 🚀 v10
  final Set<String> downloadingAttachmentIds; // 🚀 Offline-First

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
    this.uploadingAttachmentIds = const {},
    this.attachmentUploadErrors = const {},
    this.downloadingAttachmentIds = const {},
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
    Set<String>? uploadingAttachmentIds,
    Set<String>? attachmentUploadErrors,
    Set<String>? downloadingAttachmentIds,
  }) {
    return CanvasDocumentState(
      pages: pages ?? this.pages,
      liveNotebookSid: liveNotebookSid ?? this.liveNotebookSid,
      currentNotebookId: currentNotebookId ?? this.currentNotebookId,
      currentUserRole: currentUserRole ?? this.currentUserRole,
      currentTemplateType: currentTemplateType ?? this.currentTemplateType,
      isCollaborationEnabled:
          isCollaborationEnabled ?? this.isCollaborationEnabled,
      isGlobalSyncing: isGlobalSyncing ?? this.isGlobalSyncing,
      myUserId: myUserId ?? this.myUserId,
      tearingPageClientIds: tearingPageClientIds ?? this.tearingPageClientIds,
      canUndo: canUndo ?? this.canUndo,
      canRedo: canRedo ?? this.canRedo,
      isLoading: isLoading ?? this.isLoading,
      uploadingAttachmentIds:
          uploadingAttachmentIds ??
          (this.uploadingAttachmentIds as Set<String>?) ??
          const {},
      attachmentUploadErrors:
          attachmentUploadErrors ??
          (this.attachmentUploadErrors as Set<String>?) ??
          const {},
      downloadingAttachmentIds:
          downloadingAttachmentIds ??
          (this.downloadingAttachmentIds as Set<String>?) ??
          const {},
    );
  }
}

class CanvasDocumentNotifier extends Notifier<CanvasDocumentState> {
  late CanvasRepository _repository;
  late RealtimeService _realtimeService;
  late SyncService _syncService;
  late AudioSessionService _audioService;
  late CollaborationRoomService _collabService;
  late CollaborationHistoryManager _historyManager;
  late UndoRedoManager _undoRedoManager;
  StreamSubscription? _pagesSubscription;

  void _clearCollabServiceCallbacks() {
    _autoPushDebouncer?.cancel();
    _autoPushDebouncer = null;
    _pagesSubscription?.cancel();
    _pagesSubscription = null;
    _collabService.onSyncRequested = null;
    _collabService.onExecuteAction = null;
    _collabService.onPageEvent = null;
    _collabService.onFullStateRequested = null;
    _collabService.onFullStateReceived = null;
    _collabService.onHistoryRequested = null;
    _collabService.onHistoryDelivered = null;
    _collabService.onCloudSyncSignal = null;
    _collabService.onSmoothTransition = null;
    _collabService.onPageNavigationRequested = null;
    _collabService.onAutoNavigateAfterDeletion = null;
    _collabService.onNotebookStructureUpdated = null;
    _collabService.onApplyRemoteChange = null;
    _audioService.onAudioMessageProcessed = null;
    _collectiveSyncDebouncer?.cancel();
  }

  @override
  CanvasDocumentState build() {
    _repository = ref.read(canvasRepositoryProvider);
    _realtimeService = ref.read(realtimeServiceProvider);
    _syncService = ref.read(appSyncServiceProvider);
    _audioService = ref.read(audioSessionServiceProvider);
    _collabService = ref.read(collaborationRoomServiceProvider);
    _historyManager = ref.read(collaborationHistoryManagerProvider);
    _undoRedoManager = UndoRedoManager();
    ref.onDispose(() {
      _clearCollabServiceCallbacks();
    });
    return CanvasDocumentState();
  }

  Future<void> initNotebook(
    int notebookId,
    int? notebookSid,
    String role,
    String? userId, {
    String? templateType,
  }) async {
    ref.invalidate(canvasInteractionProvider);
    ref.read(canvasViewportProvider.notifier).reset();
    ref.invalidate(canvasUiProvider);
    _undoRedoManager.clear();
    state = state.copyWith(
      isLoading: false,
      pages: [],
      currentNotebookId: notebookId,
      liveNotebookSid: notebookSid,
      currentUserRole: role,
      currentTemplateType: templateType ?? 'study',
      myUserId: userId ?? '',
      canUndo: false,
      canRedo: false,
    );
    _audioService.loadLessonRecordings(notebookId);

    // 🚀 RESTAURANDO BINDINGS FALTANTES DA REESTRUTURAÇÃO
    _collabService.getPages = () => state.pages.cast<LocalPage>().toList();
    _collabService.getCurrentPageIndex = () {
      try {
        return ref.read(canvasViewportProvider).currentPageIndex;
      } catch (_) {
        return 0;
      }
    };
    _collabService.getCurrentScale = () {
      try {
        return ref.read(canvasViewportProvider.notifier).currentScale;
      } catch (_) {
        return 1.0;
      }
    };

    _collabService.onSyncRequested = () => _performCollectiveSync();
    _collabService.onExecuteAction = (d) => _handleRemoteAction(d);
    _collabService.onPageEvent = (d) => _handlePageEvent(d);
    _collabService.onFullStateRequested = (d) => _handleFullStateRequest(d);
    _collabService.onFullStateReceived = (d) => _handleFullStateReceived(d);

    _collabService.onCloudSyncSignal = (d) async {
      if (notebookSid != null) {
        await _syncService.pullSpecificPage(notebookSid, d['page_number']);
      }
    };
    _collabService.onSmoothTransition = (m) => _startSmoothTransition(m);
    _collabService.onPageNavigationRequested = (i) {
      try {
        ref.read(canvasViewportProvider.notifier).jumpToPage(i);
      } catch (e) {
        AppLog.canvas(
          '⚠️ [CanvasDocument] onPageNavigationRequested post-dispose: $e',
        );
      }
    };
    _collabService.onAutoNavigateAfterDeletion = () =>
        _autoNavigateAfterDeletion();
    _collabService.onNotebookStructureUpdated = (d) => _performCollectiveSync();
    _collabService.onApplyRemoteChange = (pcid, newObjects, remoteTs) async {
      final idx = state.pages.indexWhere((p) => p.clientId == pcid);
      if (idx == -1) return;
      final updatedPage = state.pages[idx].copyWith(
        objects: newObjects,
        updatedAt: remoteTs,
      );
      state = state.copyWith(
        pages: state.pages
            .map((p) => p.clientId == pcid ? updatedPage : p)
            .toList(),
      );
      _collabService
          .clearAllObjectTransforms(); // Limpar transforms porque os dados oficiais chegaram
    };
    _audioService.onAudioMessageProcessed = (d) =>
        _collabService.chatMessages.add(d);
    _pagesSubscription?.cancel();
    _pagesSubscription = _repository.watchPagesByNotebook(notebookId).listen((
      newPagesFromDb,
    ) {
      if (_pagesSubscription == null) return;
      final List<LocalPage> activePages = newPagesFromDb
          .where((p) => !p.isDeleted)
          .toList();
      activePages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
      if (state.pages.length == activePages.length) {
        bool listIdentical = true;
        for (int i = 0; i < activePages.length; i++) {
          if (activePages[i].clientId != state.pages[i].clientId ||
              activePages[i].updatedAt != state.pages[i].updatedAt ||
              activePages[i].syncedWithCloud !=
                  state.pages[i].syncedWithCloud) {
            listIdentical = false;
            break;
          }
        }
        if (listIdentical) return;
      }
      final Map<String, LocalPage> existingPagesMap = {
        for (var p in state.pages) p.clientId: p,
      };
      final List<LocalPage> finalPages = [];
      for (var i = 0; i < activePages.length; i++) {
        final newPage = activePages[i];
        final existing = existingPagesMap[newPage.clientId];
        if (existing != null && existing.isContentLoaded) {
          final bool isPushConfirmation =
              newPage.syncedWithCloud == 1 &&
              existing.syncedWithCloud == 0 &&
              (newPage.updatedAt - existing.updatedAt).abs() <= 5000;

          final bool isRemoteChange =
              newPage.updatedAt > (existing.updatedAt + 1000);

          if (isRemoteChange &&
              !isPushConfirmation &&
              newPage.syncedWithCloud == 1) {
            // 🚀 MUDAÇAS REMOTAS REAIS: Preserva isContentLoaded: true e recarrega objetos em segundo plano sem piscar a tela
            finalPages.add(
              newPage.copyWith(
                title: newPage.title.isNotEmpty
                    ? newPage.title
                    : existing.title,
                sectionTitle: newPage.sectionTitle ?? existing.sectionTitle,
                sectionColor: newPage.sectionColor ?? existing.sectionColor,
                objects: existing.objects,
                viewportMatrix: existing.viewportMatrix,
                backgroundConfig: existing.backgroundConfig,
                isContentLoaded: true,
                version: newPage.version,
              ),
            );
            try {
              final currentIndex = ref
                  .read(canvasViewportProvider)
                  .currentPageIndex;
              if (i == currentIndex) unawaited(reloadPageContent(i));
            } catch (_) {}
          } else {
            // 🚀 CONFIRMAÇÃO DO PUSH PRÓPRIO / ATUALIZAÇÃO DE METADADOS:
            // Atualiza flags e títulos em memória mantendo isContentLoaded: true e objetos visíveis intactos
            finalPages.add(
              newPage.copyWith(
                title: newPage.title.isNotEmpty
                    ? newPage.title
                    : existing.title,
                sectionTitle: newPage.sectionTitle ?? existing.sectionTitle,
                sectionColor: newPage.sectionColor ?? existing.sectionColor,
                objects: existing.objects,
                viewportMatrix: existing.viewportMatrix,
                backgroundConfig: existing.backgroundConfig,
                isContentLoaded: true,
                version: existing.version,
              ),
            );
          }
        } else {
          finalPages.add(newPage);
        }
      }
      if (_pagesSubscription == null) return;
      state = state.copyWith(pages: finalPages, isLoading: false);
      if (finalPages.isNotEmpty) {
        try {
          final currentIndex = ref
              .read(canvasViewportProvider)
              .currentPageIndex;
          final targetIndex =
              (currentIndex >= 0 && currentIndex < finalPages.length)
              ? currentIndex
              : 0;
          if (!finalPages[targetIndex].isContentLoaded) {
            unawaited(ensurePageLoaded(targetIndex));
          }
        } catch (_) {}
      }
    });
  }

  Future<void> reloadPageContent(int index) async {
    if (index < 0 || index >= state.pages.length) return;
    final page = state.pages[index];
    if (page.id == null) return;
    try {
      final content = await _repository.loadPageContent(page.id!);
      final List<PageObject> loadedObjects = [
        ...content['strokes'],
        ...content['textBlocks'],
        ...content['imageBlocks'],
        ...content['shapes'],
        ...content['audios'],
        ...content['animations'],
        ...content['tables'],
        ...content['links'],
        ...content['attachments'],
      ];

      final List<PageObject> migratedObjects = [];
      for (var obj in loadedObjects) {
        if (obj.zIndex <= 0) {
          final baseZ = getNaturalBaseZIndex(obj);
          migratedObjects.add(obj.copyWith(zIndex: baseZ));
        } else {
          migratedObjects.add(obj);
        }
      }

      migratedObjects.sort((a, b) => a.zIndex.compareTo(b.zIndex));

      final updatedPages = List<LocalPage>.from(state.pages);
      updatedPages[index] = page.copyWith(
        objects: migratedObjects,
        isContentLoaded: true,
      );
      state = state.copyWith(pages: updatedPages);

      // 🚀 v10.99: Limpar transforms locais ao carregar dados oficiais para evitar que objetos
      // sejam desenhados em duplicado ou saltem na tela.
      _collabService.clearAllObjectTransforms();
    } catch (e) {
      AppLog.canvas('🚨 ReloadPageContent Error: $e');
    }
  }

  static int getNaturalBaseZIndex(PageObject object) {
    if (object is ImageBlock) return 2000;
    if (object is TableObject) return 3000;
    if (object is TextBlock) return 4000;
    if (object is AudioBlock ||
        object is AnimationObject ||
        object is ExplanationModel ||
        object is LinkObject ||
        object is AttachmentObject)
      return 5000;
    if (object is Stroke || object is ShapeObject) return 6000;
    return 0;
  }

  static int calculateNextZIndex(LocalPage page, PageObject object) {
    if (object.zIndex > 0) return object.zIndex;
    final baseTier = getNaturalBaseZIndex(object);
    int maxInTier = baseTier;
    for (var o in page.objects) {
      if (getNaturalBaseZIndex(o) == baseTier) {
        if (o.zIndex > maxInTier) {
          maxInTier = o.zIndex;
        }
      }
    }
    return maxInTier + 1;
  }

  Future<void> ensurePageLoaded(int index) async {
    if (index < 0 || index >= state.pages.length) return;
    final page = state.pages[index];
    if (page.isContentLoaded || page.id == null) return;
    try {
      final content = await _repository.loadPageContent(page.id!);
      final List<PageObject> loadedObjects = [
        ...content['strokes'],
        ...content['textBlocks'],
        ...content['imageBlocks'],
        ...content['shapes'],
        ...content['audios'],
        ...content['animations'],
        ...content['tables'],
        ...content['links'],
        ...content['attachments'],
      ];

      // 🚀 Auto-migrar Z-Index legados (zIndex <= 0) para o seu nível natural
      final List<PageObject> migratedObjects = [];
      for (var obj in loadedObjects) {
        if (obj.zIndex <= 0) {
          final baseZ = getNaturalBaseZIndex(obj);
          migratedObjects.add(obj.copyWith(zIndex: baseZ));
        } else {
          migratedObjects.add(obj);
        }
      }

      // Ordenar rigorosamente por zIndex
      migratedObjects.sort((a, b) => a.zIndex.compareTo(b.zIndex));

      final updatedPages = List<LocalPage>.from(state.pages);
      updatedPages[index] = page.copyWith(
        objects: migratedObjects,
        isContentLoaded: true,
      );
      state = state.copyWith(pages: updatedPages);

      // 🚀 Offline-First: Pre-carregar automaticamente anexos da página
      preloadAttachmentsForPage(updatedPages[index]);

      // 🚀 v10.99: Limpar transforms locais ao carregar dados oficiais para evitar que objetos
      // sejam desenhados em duplicado ou saltem na tela.
      _collabService.clearAllObjectTransforms();
    } catch (e) {
      AppLog.canvas('🚨 LazyLoad Error: $e');
    }
  }

  Future<void> addStroke(LocalPage p, Stroke s) async {
    final int z = calculateNextZIndex(p, s);
    final ns = s.copyWith(
      creatorId: state.myUserId,
      pageNumber: p.pageNumber,
      layerId: s.layerId ?? 'drawings',
      zIndex: z,
    );
    await _executeAction(
      AddStrokeAction(
        pageClientId: p.clientId,
        pageNumber: p.pageNumber,
        stroke: ns,
      ),
      targetPage: p,
    );
  }

  Future<void> addTextBlock(LocalPage page, TextBlock block) async {
    final int z = calculateNextZIndex(page, block);
    await _executeAction(
      AddTextAction(
        pageClientId: page.clientId,
        pageNumber: page.pageNumber,
        block: block.copyWith(layerId: 'text', zIndex: z),
      ),
      targetPage: page,
    );
  }

  Future<void> addShape(LocalPage page, ShapeObject shape) async {
    final int z = calculateNextZIndex(page, shape);
    await _executeAction(
      AddShapeAction(
        pageClientId: page.clientId,
        pageNumber: page.pageNumber,
        shape: shape.copyWith(layerId: 'drawings', zIndex: z),
      ),
      targetPage: page,
    );
  }

  Future<void> addAudioBlock(LocalPage page, AudioBlock audio) async {
    final int z = calculateNextZIndex(page, audio);
    await _executeAction(
      AddAudioAction(
        pageClientId: page.clientId,
        pageNumber: page.pageNumber,
        audio: audio.copyWith(layerId: 'default', zIndex: z),
      ),
      targetPage: page,
    );
  }

  Future<void> addAnimation(LocalPage page, AnimationObject anim) async {
    final int z = calculateNextZIndex(page, anim);
    await _executeAction(
      AddAnimationAction(
        pageClientId: page.clientId,
        pageNumber: page.pageNumber,
        animation: anim.copyWith(layerId: 'drawings', zIndex: z),
      ),
      targetPage: page,
    );
  }

  Future<void> addExplanation(LocalPage page, ExplanationModel exp) async {
    final int z = calculateNextZIndex(page, exp);
    await _executeAction(
      AddExplanationAction(
        pageClientId: page.clientId,
        pageNumber: page.pageNumber,
        explanation: exp.copyWith(layerId: 'drawings', zIndex: z),
      ),
      targetPage: page,
    );
  }

  Future<void> addTable(LocalPage page, TableObject table) async {
    final int z = calculateNextZIndex(page, table);
    await _executeAction(
      AddTableAction(
        pageClientId: page.clientId,
        pageNumber: page.pageNumber,
        table: table.copyWith(layerId: 'default', zIndex: z),
      ),
      targetPage: page,
    );
  }

  Future<void> addLink(LocalPage page, LinkObject link) async {
    final int z = calculateNextZIndex(page, link);
    await _executeAction(
      AddLinkAction(
        pageClientId: page.clientId,
        pageNumber: page.pageNumber,
        link: link.copyWith(layerId: 'default', zIndex: z),
      ),
      targetPage: page,
    );
  }

  Future<void> addAttachment(LocalPage page, AttachmentObject attach) async {
    final int z = calculateNextZIndex(page, attach);
    final attachWithZ = attach.copyWith(
      creatorId: attach.creatorId ?? state.myUserId,
      layerId: 'default',
      zIndex: z,
      pageNumber: page.pageNumber,
    );

    // Dispara imediatamente para o canvas local e transmite o AddAttachmentAction para a sala exatamente como os outros objetos
    await _executeAction(
      AddAttachmentAction(
        pageClientId: page.clientId,
        pageNumber: page.pageNumber,
        attach: attachWithZ,
      ),
      targetPage: page,
    );

    // Começar o processo de upload assíncrono em plano de fundo sem bloquear a interface.
    _uploadAttachmentInBackground(page.clientId, page.pageNumber, attachWithZ);
  }

  Future<void> retryAttachmentUpload(
    LocalPage page,
    AttachmentObject attach,
  ) async {
    if (state.uploadingAttachmentIds.contains(attach.id))
      return; // Already uploading
    _uploadAttachmentInBackground(page.clientId, page.pageNumber, attach);
  }

  Future<void> _uploadAttachmentInBackground(
    String pageClientId,
    int pageNumber,
    AttachmentObject attach,
  ) async {
    final int? targetSid =
        _collabService.liveNotebookSid ??
        state.liveNotebookSid ??
        state.currentNotebookId;

    if (targetSid == null || targetSid == 0)
      return; // O caderno é apenas local, sem ID no servidor cloud

    // 🚀 Se o anexo já possui remoteUrl na cloud, não precisa de upload
    if (attach.remoteUrl != null &&
        attach.remoteUrl!.isNotEmpty &&
        attach.remoteUrl!.startsWith('http')) {
      return;
    }

    // 1. Marcar como "a carregar"
    state = state.copyWith(
      uploadingAttachmentIds: {...state.uploadingAttachmentIds, attach.id},
      attachmentUploadErrors: {...state.attachmentUploadErrors}
        ..remove(attach.id),
    );

    try {
      Uint8List? bytes;
      if (!kIsWeb &&
          attach.localPath.isNotEmpty &&
          io.File(attach.localPath).existsSync()) {
        bytes = await io.File(attach.localPath).readAsBytes();
      } else if (attach.remoteUrl != null &&
          attach.remoteUrl!.isNotEmpty &&
          !attach.remoteUrl!.startsWith('http')) {
        // Suporte Web/Base64 se armazenado temporariamente em remoteUrl
        try {
          bytes = base64Decode(attach.remoteUrl!);
        } catch (_) {}
      }

      if (bytes == null || bytes.isEmpty) {
        throw Exception("Ficheiro do anexo não foi encontrado localmente.");
      }

      final String? remoteUrl = await _repository.uploadFile(
        targetSid,
        'attach_${attach.id}.${attach.fileExtension}',
        bytes,
      );

      if (remoteUrl != null && remoteUrl.isNotEmpty) {
        // Upload sucesso!
        final updatedAttach = attach.copyWith(
          remoteUrl: remoteUrl,
          syncedWithCloud: true,
          updatedAt: TimeService().nowMs(),
        );

        // Retirar do modo uploading
        state = state.copyWith(
          uploadingAttachmentIds: {...state.uploadingAttachmentIds}
            ..remove(attach.id),
        );

        // Atualizar o objeto na memória e na DB localmente e transmitir UpdateObjectAction com remoteUrl
        final targetPage = state.pages.cast<LocalPage?>().firstWhere(
          (p) =>
              p?.clientId == pageClientId ||
              (p != null && p.pageNumber == pageNumber),
          orElse: () => null,
        );
        if (targetPage != null) {
          await updateObject(targetPage, updatedAttach, isRemote: false);
        }
      } else {
        throw Exception("Upload falhou ou URL remoto é inválido");
      }
    } catch (e) {
      AppLog.canvas(
        '⚠️ [CanvasDocument] Erro ao carregar anexo para servidor de colaboração: $e',
      );
      // Upload falhou, marcar erro
      state = state.copyWith(
        uploadingAttachmentIds: {...state.uploadingAttachmentIds}
          ..remove(attach.id),
        attachmentUploadErrors: {...state.attachmentUploadErrors, attach.id},
      );
    }
  }

  /// 🚀 Offline-First: Pre-carrega automaticamente anexos em segundo plano para acesso offline no telemóvel
  void preloadAttachmentsForPage(LocalPage page) {
    if (kIsWeb) return;
    for (var obj in page.objects) {
      if (obj is AttachmentObject) {
        final hasRemote =
            obj.remoteUrl != null &&
            obj.remoteUrl!.isNotEmpty &&
            obj.remoteUrl!.startsWith('http');
        final hasLocal =
            obj.localPath.isNotEmpty && io.File(obj.localPath).existsSync();

        if (hasRemote && !hasLocal) {
          _downloadAttachmentFileInBackground(page, obj);
        }
      }
    }
  }

  Future<void> _downloadAttachmentFileInBackground(
    LocalPage page,
    AttachmentObject attach,
  ) async {
    if (kIsWeb) return;
    if (state.downloadingAttachmentIds.contains(attach.id)) return;
    final remoteUrl = attach.remoteUrl;
    if (remoteUrl == null || !remoteUrl.startsWith('http')) return;

    if (attach.localPath.isNotEmpty && io.File(attach.localPath).existsSync()) {
      return;
    }

    state = state.copyWith(
      downloadingAttachmentIds: {...state.downloadingAttachmentIds, attach.id},
    );

    try {
      final appDir = await getApplicationDocumentsDirectory();
      final attachDir = io.Directory('${appDir.path}/attachments');
      if (!await attachDir.exists()) await attachDir.create(recursive: true);

      final localSavePath = '${attachDir.path}/${attach.fileName}';
      final success = await _repository.downloadFile(remoteUrl, localSavePath);

      if (success) {
        final updatedAttach = attach.copyWith(localPath: localSavePath);

        final targetPage = state.pages.cast<LocalPage?>().firstWhere(
          (p) =>
              p?.clientId == page.clientId ||
              (p != null && p.pageNumber == page.pageNumber),
          orElse: () => null,
        );
        if (targetPage != null) {
          final updatedObjects = targetPage.objects
              .map((o) => o.id == updatedAttach.id ? updatedAttach : o)
              .toList();
          final updatedPage = targetPage.copyWith(objects: updatedObjects);
          state = state.copyWith(
            pages: state.pages
                .map((p) => p.clientId == targetPage.clientId ? updatedPage : p)
                .toList(),
          );
          await _repository.saveSingleAttachment(
            targetPage.clientId,
            updatedAttach,
            pageId: targetPage.id,
          );
        }
      }
    } catch (e) {
      AppLog.canvas(
        '⚠️ [CanvasDocument] Erro ao descarregar anexo para offline: $e',
      );
    } finally {
      state = state.copyWith(
        downloadingAttachmentIds: {...state.downloadingAttachmentIds}
          ..remove(attach.id),
      );
    }
  }

  Future<void> addImage(LocalPage page, ImageBlock image) async {
    final int z = calculateNextZIndex(page, image);
    await _executeAction(
      AddImageAction(
        pageClientId: page.clientId,
        pageNumber: page.pageNumber,
        block: image.copyWith(layerId: 'default', zIndex: z),
      ),
      targetPage: page,
    );
  }

  Future<void> addObject(LocalPage page, PageObject obj) async {
    if (obj is Stroke)
      await addStroke(page, obj);
    else if (obj is TextBlock)
      await addTextBlock(page, obj);
    else if (obj is ImageBlock)
      await addImage(page, obj);
    else if (obj is ShapeObject)
      await addShape(page, obj);
    else if (obj is AudioBlock)
      await addAudioBlock(page, obj);
    else if (obj is AnimationObject)
      await addAnimation(page, obj);
    else if (obj is ExplanationModel)
      await addExplanation(page, obj);
    else if (obj is TableObject)
      await addTable(page, obj);
    else if (obj is LinkObject)
      await addLink(page, obj);
    else if (obj is AttachmentObject)
      await addAttachment(page, obj);
  }

  Future<void> deleteObjects(LocalPage page, List<String> objectIds) async {
    if (objectIds.isEmpty) return;
    await _executeAction(
      DeleteAction(
        pageClientId: page.clientId,
        pageNumber: page.pageNumber,
        objectIds: objectIds,
      ),
      targetPage: page,
    );
  }

  Future<void> deleteAttachmentLocalFile(
    LocalPage page,
    AttachmentObject attach,
  ) async {
    if (attach.localPath.isNotEmpty) {
      final file = io.File(attach.localPath);
      if (file.existsSync()) {
        try {
          await file.delete();
        } catch (e) {
          AppLog.canvas('Error deleting local file: $e');
        }
      }
    }
    // Atualizar objecto localmente sem enviar para os colegas
    final updatedAttach = attach.copyWith(localPath: '');
    await updateObject(
      page,
      updatedAttach,
      isRemote: true,
    ); // isRemote = true para não enviar
  }

  Future<void> updateObject(
    LocalPage page,
    PageObject obj, {
    bool isRemote = false,
  }) async {
    final oldObj = page.objects.firstWhere((o) => o.id == obj.id);
    await _executeAction(
      UpdateObjectAction(
        pageClientId: page.clientId,
        pageNumber: page.pageNumber,
        objectId: obj.id,
        oldState: oldObj.toJson(),
        newState: obj.toJson(),
      ),
      targetPage: page,
      isRemote: isRemote,
    );
  }

  // 🚀 v10.27: Movimentação de Camadas Relativa
  Future<void> moveForward(LocalPage page, String objectId) async {
    final idx = page.objects.indexWhere((o) => o.id == objectId);
    if (idx == -1 || idx >= page.objects.length - 1) return;
    await reorderObject(page, idx, idx + 1);
  }

  Future<void> moveBackward(LocalPage page, String objectId) async {
    final idx = page.objects.indexWhere((o) => o.id == objectId);
    if (idx <= 0) return;
    await reorderObject(page, idx, idx - 1);
  }

  Future<void> executeInteractionAction(CanvasAction action) async {
    await _executeAction(action);
  }

  Future<void> reorderObject(LocalPage page, int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final objects = List<PageObject>.from(page.objects);
    final item = objects.removeAt(oldIndex);
    objects.insert(newIndex, item);
    final List<PageObject> finalObjects = [];
    for (int i = 0; i < objects.length; i++)
      finalObjects.add(objects[i].copyWith(zIndex: i));
    final updatedPage = page.copyWith(
      objects: finalObjects,
      syncedWithCloud: 0,
    );
    await _repository.savePage(updatedPage, state.liveNotebookSid);
    await _repository.markPageAsUnsynced(page.clientId); // 🚀 v10.55
    state = state.copyWith(
      pages: state.pages
          .map((p) => p.clientId == page.clientId ? updatedPage : p)
          .toList(),
    );
  }

  Future<void> applyNaturalSort(LocalPage page) async {
    final objects = List<PageObject>.from(page.objects);
    objects.sort((a, b) {
      final wA = getNaturalBaseZIndex(a);
      final wB = getNaturalBaseZIndex(b);
      if (wA != wB) return wA.compareTo(wB);
      return a.zIndex.compareTo(b.zIndex);
    });

    final Map<int, int> tierCounters = {};
    final List<PageObject> finalObjects = [];
    for (var o in objects) {
      final baseZ = getNaturalBaseZIndex(o);
      final count = tierCounters[baseZ] ?? 0;
      tierCounters[baseZ] = count + 1;
      finalObjects.add(o.copyWith(zIndex: baseZ + count));
    }

    final updatedPage = page.copyWith(
      objects: finalObjects,
      syncedWithCloud: 0,
    );
    await _repository.savePage(updatedPage, state.liveNotebookSid);
    await _repository.markPageAsUnsynced(page.clientId); // 🚀 v10.55
    state = state.copyWith(
      pages: state.pages
          .map((p) => p.clientId == page.clientId ? updatedPage : p)
          .toList(),
    );
  }

  Future<void> cleanupIfEmpty(LocalPage page, String? blockId) async {
    if (blockId == null || blockId.startsWith('proxy_')) return;
    final block = page.objects.cast<PageObject?>().firstWhere(
      (o) => o?.id == blockId,
      orElse: () => null,
    );
    if (block is TextBlock && block.text.trim().isEmpty)
      await deleteObjects(page, [blockId]);
  }

  Future<void> updateLayerVisibility(
    LocalPage page,
    String layerId,
    bool isVisible,
  ) async {
    final updatedLayers = page.layers
        .map((l) => l.id == layerId ? l.copyWith(isVisible: isVisible) : l)
        .toList();
    _applyLayerChange(page, updatedLayers);
  }

  Future<void> updateLayerLock(
    LocalPage page,
    String layerId,
    bool isLocked,
  ) async {
    final updatedLayers = page.layers
        .map((l) => l.id == layerId ? l.copyWith(isLocked: isLocked) : l)
        .toList();
    _applyLayerChange(page, updatedLayers);
  }

  Future<void> addNewLayer(LocalPage page, String name) async {
    final newLayer = LayerDefinition(id: const Uuid().v4(), name: name);
    final updatedLayers = List<LayerDefinition>.from(page.layers)
      ..add(newLayer);
    _applyLayerChange(page, updatedLayers);
  }

  Future<void> _applyLayerChange(
    LocalPage page,
    List<LayerDefinition> layers,
  ) async {
    final updatedPage = page.copyWith(layers: layers, syncedWithCloud: 0);
    await _repository.savePage(updatedPage, state.liveNotebookSid);
    await _repository.markPageAsUnsynced(page.clientId);
    state = state.copyWith(
      pages: state.pages
          .map((p) => p.clientId == page.clientId ? updatedPage : p)
          .toList(),
    );
  }

  Future<void> updateStrokesColor(
    LocalPage page,
    Set<String> strokeIds,
    String colorHex,
  ) async {
    final List<Stroke> updatedStrokes = [];
    final now = TimeService().nowMs();
    final newObjects = page.objects.map((o) {
      if (o is Stroke && strokeIds.contains(o.id)) {
        final updated = o.copyWith(color: colorHex, updatedAt: now);
        updatedStrokes.add(updated);
        return updated;
      }
      return o;
    }).toList();
    if (updatedStrokes.isNotEmpty) {
      final updatedPage = page.copyWith(
        objects: newObjects,
        updatedAt: now,
        syncedWithCloud: 0,
      );
      state = state.copyWith(
        pages: state.pages
            .map((p) => p.clientId == page.clientId ? updatedPage : p)
            .toList(),
      );
      for (var s in updatedStrokes) {
        await _repository.saveSingleStroke(
          page.clientId,
          s,
          pageId: page.id,
          updatedAt: now,
        );
        _realtimeService.broadcastStroke(
          notebookId: state.liveNotebookSid!,
          myUserId: state.myUserId,
          strokeData: {
            'page_client_id': page.clientId,
            'page_number': page.pageNumber,
            'strokes': [s.toJson()],
          },
        );
      }

      await _repository.markPageAsUnsynced(page.clientId, updatedAt: now);
    }
  }

  Future<void> pixelErase(
    LocalPage page,
    Offset eraserPos,
    double radius,
  ) async {
    bool changed = false;
    final List<Stroke> toAdd = [];
    final List<String> toDelete = [];
    final now = TimeService().nowMs();
    final newObjects = page.objects.map((o) {
      if (o is Stroke && !o.isDeleted) {
        final result = StrokeUtils.erasePartOfStroke(o, eraserPos, radius);
        if (result.length == 1 && listEquals(result.first.points, o.points))
          return o;
        changed = true;
        toDelete.add(o.id);
        toAdd.addAll(result);
        return o.copyWith(isDeleted: true, updatedAt: now);
      }
      return o;
    }).toList();
    if (changed) {
      newObjects.addAll(toAdd);
      final updatedPage = page.copyWith(objects: newObjects, updatedAt: now);
      state = state.copyWith(
        pages: state.pages
            .map((p) => p.clientId == page.clientId ? updatedPage : p)
            .toList(),
      );
    }
  }

  Future<void> commitPixelErase(
    LocalPage page,
    List<String> deletedIds,
    List<Stroke> addedStrokes,
  ) async {
    if (deletedIds.isEmpty && addedStrokes.isEmpty) return;
    final action = PixelEraseAction(
      pageClientId: page.clientId,
      pageNumber: page.pageNumber,
      deletedStrokeIds: deletedIds.toSet().toList(),
      addedStrokes: addedStrokes,
    );
    await _executeAction(action, targetPage: page);
  }

  Future<void> _executeAction(
    CanvasAction action, {
    bool isRemote = false,
    LocalPage? targetPage,
  }) async {
    final target =
        targetPage ??
        state.pages.cast<LocalPage?>().firstWhere(
          (p) =>
              p?.clientId == action.pageClientId ||
              (p != null &&
                  action.pageNumber != null &&
                  p.pageNumber == action.pageNumber),
          orElse: () => null,
        );
    if (target == null || (target.isFrozen && !isRemote)) return;
    final updatedTarget = action.execute(target);
    if (!isRemote) _undoRedoManager.addAction(action);

    // 🚀 Grava a ação no log P2P independentemente de ser remota ou local
    _historyManager.recordAction(action);

    state = state.copyWith(
      pages: state.pages
          .map((p) => p.clientId == target.clientId ? updatedTarget : p)
          .toList(),
      canUndo: _undoRedoManager.canUndo,
      canRedo: _undoRedoManager.canRedo,
    );
    unawaited(
      _persistIncrementalAction(
        updatedTarget,
        action,
        updatedAt: isRemote ? null : updatedTarget.updatedAt,
        isRemote: isRemote,
      ),
    );
    if (!isRemote) _broadcastAction(action);
  }

  Future<void> undo(LocalPage page) async {
    final result = _undoRedoManager.undoResult(page);
    if (result != null) {
      final updatedTarget = result.page;
      state = state.copyWith(
        pages: state.pages
            .map((p) => p.clientId == page.clientId ? updatedTarget : p)
            .toList(),
        canUndo: _undoRedoManager.canUndo,
        canRedo: _undoRedoManager.canRedo,
      );
      await _repository.savePage(updatedTarget, state.liveNotebookSid);
      await _repository.markPageAsUnsynced(page.clientId);

      final bool isCollab =
          _collabService.isCollaborationEnabled || state.isCollaborationEnabled;
      final int? targetSid =
          _collabService.liveNotebookSid ?? state.liveNotebookSid;
      if (isCollab && targetSid != null) {
        _realtimeService.broadcastGlobalAction(
          notebookId: targetSid,
          actionData: {
            'sender_id': state.myUserId.isNotEmpty
                ? state.myUserId
                : _collabService.myUserId,
            'action_type': 'sync_undo_action',
            'data': {
              'page_client_id': page.clientId,
              'page_number': page.pageNumber,
              'action_type': result.action.toMap()['type'],
              'action_data': result.action.toMap(),
            },
          },
        );
      }
    }
  }

  Future<void> redo(LocalPage page) async {
    final result = _undoRedoManager.redoResult(page);
    if (result != null) {
      final updatedTarget = result.page;
      state = state.copyWith(
        pages: state.pages
            .map((p) => p.clientId == page.clientId ? updatedTarget : p)
            .toList(),
        canUndo: _undoRedoManager.canUndo,
        canRedo: _undoRedoManager.canRedo,
      );
      await _repository.savePage(updatedTarget, state.liveNotebookSid);
      await _repository.markPageAsUnsynced(page.clientId);

      final bool isCollab =
          _collabService.isCollaborationEnabled || state.isCollaborationEnabled;
      final int? targetSid =
          _collabService.liveNotebookSid ?? state.liveNotebookSid;
      if (isCollab && targetSid != null) {
        _realtimeService.broadcastGlobalAction(
          notebookId: targetSid,
          actionData: {
            'sender_id': state.myUserId.isNotEmpty
                ? state.myUserId
                : _collabService.myUserId,
            'action_type': 'sync_redo_action',
            'data': {
              'page_client_id': page.clientId,
              'page_number': page.pageNumber,
              'action_type': result.action.toMap()['type'],
              'action_data': result.action.toMap(),
            },
          },
        );
      }
    }
  }

  Future<void> _persistIncrementalAction(
    LocalPage target,
    CanvasAction action, {
    int? updatedAt,
    bool isRemote = false,
  }) async {
    final String cid = target.clientId;
    final int? pid = target.id;
    try {
      if (action is GroupAction) {
        for (var oid in action.objectIds) {
          final obj = target.objects.cast<PageObject?>().firstWhere(
            (o) => o?.id == oid,
            orElse: () => null,
          );
          if (obj == null) continue;
          if (obj is Stroke)
            await _repository.saveSingleStroke(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is TextBlock)
            await _repository.saveSingleTextBlock(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is ImageBlock)
            await _repository.saveSingleImageBlock(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is ShapeObject)
            await _repository.saveSingleShape(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is TableObject)
            await _repository.saveSingleTable(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is LinkObject)
            await _repository.saveSingleLink(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is AttachmentObject)
            await _repository.saveSingleAttachment(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is AudioBlock)
            await _repository.saveSingleAudioBlock(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is AnimationObject)
            await _repository.saveSingleAnimationObject(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is ExplanationModel)
            await _repository.saveSingleExplanationObject(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
        }
      } else if (action is AddStrokeAction)
        await _repository.saveSingleStroke(
          cid,
          action.stroke,
          pageId: pid,
          updatedAt: updatedAt,
        );
      else if (action is AddTextAction)
        await _repository.saveSingleTextBlock(
          cid,
          action.block,
          pageId: pid,
          updatedAt: updatedAt,
        );
      else if (action is AddImageAction)
        await _repository.saveSingleImageBlock(
          cid,
          action.block,
          pageId: pid,
          updatedAt: updatedAt,
        );
      else if (action is AddShapeAction)
        await _repository.saveSingleShape(
          cid,
          action.shape,
          pageId: pid,
          updatedAt: updatedAt,
        );
      else if (action is AddAudioAction)
        await _repository.saveSingleAudioBlock(
          cid,
          action.audio,
          pageId: pid,
          updatedAt: updatedAt,
        );
      else if (action is AddAnimationAction)
        await _repository.saveSingleAnimationObject(
          cid,
          action.animation,
          pageId: pid,
          updatedAt: updatedAt,
        );
      else if (action is AddExplanationAction)
        await _repository.saveSingleExplanationObject(
          cid,
          action.explanation,
          pageId: pid,
          updatedAt: updatedAt,
        );
      else if (action is AddTableAction)
        await _repository.saveSingleTable(
          cid,
          action.table,
          pageId: pid,
          updatedAt: updatedAt,
        );
      else if (action is AddLinkAction)
        await _repository.saveSingleLink(
          cid,
          action.link,
          pageId: pid,
          updatedAt: updatedAt,
        );
      else if (action is AddAttachmentAction)
        await _repository.saveSingleAttachment(
          cid,
          action.attach,
          pageId: pid,
          updatedAt: updatedAt,
        );
      else if (action is MoveAction || action is UpdateObjectAction) {
        for (var oid
            in (action is MoveAction
                ? action.objectIds
                : [(action as UpdateObjectAction).objectId])) {
          final obj = target.objects.cast<PageObject?>().firstWhere(
            (o) => o?.id == oid,
            orElse: () => null,
          );
          if (obj == null) continue;
          if (obj is Stroke)
            await _repository.saveSingleStroke(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is TextBlock)
            await _repository.saveSingleTextBlock(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is ImageBlock)
            await _repository.saveSingleImageBlock(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is ShapeObject)
            await _repository.saveSingleShape(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is TableObject)
            await _repository.saveSingleTable(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is LinkObject)
            await _repository.saveSingleLink(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is AttachmentObject)
            await _repository.saveSingleAttachment(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is AudioBlock)
            await _repository.saveSingleAudioBlock(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is AnimationObject)
            await _repository.saveSingleAnimationObject(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
          else if (obj is ExplanationModel)
            await _repository.saveSingleExplanationObject(
              cid,
              obj,
              pageId: pid,
              updatedAt: updatedAt,
            );
        }
      } else if (action is DeleteAction) {
        for (var oid in action.objectIds)
          await _repository.deleteObjectById(oid);
      } else if (action is PixelEraseAction) {
        for (var oid in action.deletedStrokeIds) {
          await _repository.deleteObjectById(oid);
        }
        for (var stroke in action.addedStrokes) {
          await _repository.saveSingleStroke(
            cid,
            stroke,
            pageId: pid,
            updatedAt: updatedAt,
          );
        }
      }

      if (!isRemote) {
        // 🚀 v10.55: Garantir que a página é marcada como "suja" para o SyncService
        await _repository.markPageAsUnsynced(cid, updatedAt: updatedAt);
        scheduleAutoPush();
      }
    } catch (e) {
      AppLog.canvas('');
    }
  }

  // 🚀 v10.90: Map para Debounce de envios de texto em colaboração
  static final Map<String, Timer> _textBroadcastDebouncers = {};

  void _broadcastAction(CanvasAction action) {
    final bool isCollab =
        _collabService.isCollaborationEnabled || state.isCollaborationEnabled;
    final int? targetSid =
        _collabService.liveNotebookSid ?? state.liveNotebookSid;

    AppLog.canvas(
      '📣 [CanvasDocument] _broadcastAction isCollab: $isCollab, targetSid: $targetSid',
    );

    if (!isCollab || targetSid == null) return;

    final String effectiveUserId = state.myUserId.isNotEmpty
        ? state.myUserId
        : _collabService.myUserId;

    if (action is AddStrokeAction) {
      final strokeJson = action.stroke.toJson(
        includePoints: false,
      ); // Não inclui pontos originais formatados
      strokeJson['is_final'] =
          true; // 🚀 Garantir que o receptor sabe que o traço está concluído

      // Flatten and Delta Encode points to save space. Since the server limit is now 256KB,
      // we can safely send high-fidelity strokes (e.g., up to 4000 points).
      final ptsList = action.stroke.points;
      final maxPts = 4000;
      final int step = ptsList.length > maxPts
          ? (ptsList.length / maxPts).ceil()
          : 1;
      final encodedPts = <int>[];

      if (ptsList.isNotEmpty) {
        int lastX = (ptsList[0].dx * 10).round();
        int lastY = (ptsList[0].dy * 10).round();
        encodedPts.add(lastX);
        encodedPts.add(lastY);

        for (int i = step; i < ptsList.length; i += step) {
          int curX = (ptsList[i].dx * 10).round();
          int curY = (ptsList[i].dy * 10).round();
          encodedPts.add(curX - lastX);
          encodedPts.add(curY - lastY);
          lastX = curX;
          lastY = curY;
        }
      }
      strokeJson['pts_enc'] = 'd1'; // Indicate Delta Encoding
      strokeJson['points'] = encodedPts;

      _realtimeService.broadcastStroke(
        notebookId: targetSid,
        myUserId: effectiveUserId,
        strokeData: {
          'page_client_id': action.pageClientId,
          'page_number': action.pageNumber,
          'strokes': [strokeJson],
        },
      );
    } else if (action is AddTextAction) {
      _realtimeService.broadcastTextBlock(
        notebookId: targetSid,
        textData: {
          'sender_id': effectiveUserId,
          'page_number': action.pageNumber,
          'block': action.block.toJson(),
          'is_editing': false,
        },
      );
    } else if (action is UpdateObjectAction &&
        action.newState['text'] != null) {
      // 🚀 Debounce muito agressivo para texto em tempo real parecer live writing
      final String blockId = action.objectId;
      _textBroadcastDebouncers[blockId]?.cancel();
      _textBroadcastDebouncers[blockId] = Timer(
        const Duration(milliseconds: 80),
        () {
          _realtimeService.broadcastTextBlock(
            notebookId: targetSid,
            textData: {
              'sender_id': effectiveUserId,
              'page_number': action.pageNumber,
              'block': action.newState,
              'is_editing': true,
            },
          );
        },
      );
    } else {
      _realtimeService.broadcastGlobalAction(
        notebookId: targetSid,
        actionData: {
          'sender_id': effectiveUserId,
          'action_type': action.toMap()['type'],
          'data': action.toMap(),
        },
      );
    }

    // 🚀 GRAVAR AÇÃO NO REDIS DO SERVIDOR (Server-Authoritative)
    // As ações transmitidas em broadcast acima mostram na UI dos colegas ao vivo,
    // mas também enviamos via HTTP para ficar na memória de longo prazo (Redis) e
    // os utilizadores que regressem de hibernação consigam fazer download!
    _syncService.recordActionToCloud(targetSid, {
      'sender_id': effectiveUserId,
      'action_type': action.toMap()['type'],
      'data': action.toMap(),
    });
  }

  // Gestão de Páginas
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
    if (insertIndex != null && insertIndex < state.pages.length)
      await _repository.shiftPageNumbers(
        state.currentNotebookId,
        insertIndex,
        count,
      );
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
      // 🚀 v10.56: Marcação imediata para sincronismo de nova página
      await _repository.markPageAsUnsynced(np.clientId);
    }
    await _repository.reindexPages(state.currentNotebookId);

    final bool isCollab =
        _collabService.isCollaborationEnabled || state.isCollaborationEnabled;
    final int? targetSid =
        _collabService.liveNotebookSid ??
        state.liveNotebookSid ??
        state.currentNotebookId;
    if (isCollab && targetSid != null && targetSid > 0) {
      _realtimeService.broadcastPageEvent(
        notebookId: targetSid,
        pageData: {'action': 'add'},
        myUserId: state.myUserId.isNotEmpty
            ? state.myUserId
            : _collabService.myUserId,
      );
      scheduleAutoPush();
    }
  }

  Future<void> duplicatePage(LocalPage source) async {
    if (!source.isContentLoaded && source.id != null) {
      final content = await _repository.loadPageContent(
        source.id!,
        pageNumber: source.pageNumber,
      );
      source = source.copyWith(
        objects: [
          ...content['strokes'],
          ...content['textBlocks'],
          ...content['imageBlocks'],
        ],
        isContentLoaded: true,
      );
    }
    final clonedPage = source.clone(
      newClientId: const Uuid().v4(),
      newPageNumber: source.pageNumber + 1,
    );
    await _repository.savePage(clonedPage, state.liveNotebookSid);
    await _repository.markPageAsUnsynced(clonedPage.clientId); // 🚀 v10.56

    for (var obj in clonedPage.objects) {
      if (obj is Stroke)
        await _repository.saveSingleStroke(clonedPage.clientId, obj);
      else if (obj is TextBlock)
        await _repository.saveSingleTextBlock(clonedPage.clientId, obj);
      else if (obj is ImageBlock)
        await _repository.saveSingleImageBlock(clonedPage.clientId, obj);
      else if (obj is ShapeObject)
        await _repository.saveSingleShape(clonedPage.clientId, obj);
      else if (obj is TableObject)
        await _repository.saveSingleTable(clonedPage.clientId, obj);
      else if (obj is LinkObject)
        await _repository.saveSingleLink(clonedPage.clientId, obj);
      else if (obj is AttachmentObject)
        await _repository.saveSingleAttachment(clonedPage.clientId, obj);
      else if (obj is AudioBlock)
        await _repository.saveSingleAudioBlock(clonedPage.clientId, obj);
      else if (obj is AnimationObject)
        await _repository.saveSingleAnimationObject(clonedPage.clientId, obj);
      else if (obj is ExplanationModel)
        await _repository.saveSingleExplanationObject(clonedPage.clientId, obj);
    }
    await _repository.reindexPages(state.currentNotebookId);

    final bool isCollab =
        _collabService.isCollaborationEnabled || state.isCollaborationEnabled;
    final int? targetSid =
        _collabService.liveNotebookSid ??
        state.liveNotebookSid ??
        state.currentNotebookId;
    if (isCollab && targetSid != null && targetSid > 0) {
      _realtimeService.broadcastPageEvent(
        notebookId: targetSid,
        pageData: {'action': 'add'},
        myUserId: state.myUserId.isNotEmpty
            ? state.myUserId
            : _collabService.myUserId,
      );
      scheduleAutoPush();
    }
  }

  Future<void> duplicatePages(List<LocalPage> sources) async {
    for (var s in sources) await duplicatePage(s);
  }

  Future<void> reorderPage(int oldIndex, int newIndex) async {
    if (oldIndex == newIndex) return;
    final list = List<LocalPage>.from(state.pages);
    final item = list.removeAt(oldIndex);
    list.insert(newIndex, item);
    state = state.copyWith(pages: list);
    final pageIds = list.map((p) => p.id).whereType<int>().toList();
    await _repository.updatePageNumbersBatch(pageIds);
    // 🚀 v10.56: Todas as páginas reordenadas precisam de sincronizar o novo pageNumber
    for (var p in list) await _repository.markPageAsUnsynced(p.clientId);
  }

  Future<void> updatePageSettings(
    LocalPage page,
    NotebookConfiguration newConfig, {
    bool isRemote = false,
    int? remoteTimestamp,
  }) async {
    final targetPage =
        state.pages.cast<LocalPage?>().firstWhere(
          (p) =>
              p?.clientId == page.clientId ||
              (p != null && page.id != null && p.id == page.id),
          orElse: () => page,
        ) ??
        page;

    if (targetPage.id == null && targetPage.clientId.isEmpty) return;
    final int effectiveTs = math.max(
      remoteTimestamp ?? TimeService().nowMs(),
      targetPage.updatedAt + 1,
    );

    // Rejeitar se a alteração remota for mais antiga que o estado atual local
    if (isRemote &&
        remoteTimestamp != null &&
        targetPage.updatedAt > remoteTimestamp) {
      AppLog.canvas(
        '🛡️ [CanvasDocument] Ignorando update_page_settings remoto desatualizado ($remoteTimestamp < ${targetPage.updatedAt}).',
      );
      return;
    }

    final updated = targetPage.copyWith(
      isLandscape: newConfig.page.orientation == 'landscape',
      paperSize: newConfig.page.paperSize,
      isInfinite: newConfig.page.isInfinite,
      backgroundConfig: newConfig.background,
      lineType: newConfig.background.type,
      lineSpacing: newConfig.background.spacing,
      title: newConfig.header.enabled
          ? (newConfig.header.fields.isNotEmpty
                ? newConfig.header.fields.join(' / ')
                : targetPage.title)
          : targetPage.title,
      footer: newConfig.footer.enabled
          ? (newConfig.footer.fields.isNotEmpty
                ? newConfig.footer.fields.join(' / ')
                : targetPage.footer)
          : targetPage.footer,
      updatedAt: effectiveTs,
    );

    await _repository.savePage(updated, state.liveNotebookSid);

    if (!isRemote) {
      await _repository.markPageAsUnsynced(targetPage.clientId);
      scheduleAutoPush();
    }

    state = state.copyWith(
      pages: state.pages
          .map((p) => p.clientId == targetPage.clientId ? updated : p)
          .toList(),
    );

    if (!isRemote) {
      final bool isCollab =
          _collabService.isCollaborationEnabled || state.isCollaborationEnabled;
      final int? targetSid =
          _collabService.liveNotebookSid ?? state.liveNotebookSid;
      if (isCollab && targetSid != null) {
        _realtimeService.broadcastGlobalAction(
          notebookId: targetSid,
          actionData: {
            'sender_id': state.myUserId.isNotEmpty
                ? state.myUserId
                : _collabService.myUserId,
            'action_type': 'update_page_settings',
            'data': {
              'page_client_id': targetPage.clientId,
              'page_number': targetPage.pageNumber,
              'config': newConfig.toJson(),
              'timestamp': effectiveTs,
            },
          },
        );
      }
    }
  }

  Future<void> renamePage(LocalPage page, String newTitle) async {
    if (page.id == null) return;
    final updated = page.copyWith(
      title: newTitle,
      updatedAt: TimeService().nowMs(),
    );
    await _repository.savePage(updated, state.liveNotebookSid);
    await _repository.markPageAsUnsynced(page.clientId); // 🚀 v10.56
    state = state.copyWith(
      pages: state.pages
          .map((p) => p.clientId == page.clientId ? updated : p)
          .toList(),
    );
  }

  Future<void> setPageBackgroundImage(
    LocalPage page,
    String? imagePath, {
    bool applyToAll = false,
  }) async {
    final int? targetSid =
        _collabService.liveNotebookSid ??
        state.liveNotebookSid ??
        state.currentNotebookId;
    String finalPath = imagePath ?? '';

    // Fazer upload da imagem se for local e estivermos num caderno na nuvem
    if (finalPath.isNotEmpty &&
        !finalPath.startsWith('http') &&
        targetSid != null &&
        targetSid > 0) {
      try {
        final bytes = await io.File(finalPath).readAsBytes();
        final String fileName = 'bg_${TimeService().nowMs()}.jpg';
        final String? remoteUrl = await _repository.uploadImage(
          targetSid,
          fileName,
          bytes,
        );
        if (remoteUrl != null && remoteUrl.isNotEmpty) {
          finalPath = remoteUrl;
        }
      } catch (e) {
        AppLog.canvas('⚠️ Erro no upload da imagem de fundo: $e');
      }
    }

    final pagesToUpdate = applyToAll ? state.pages : [page];
    final int now = TimeService().nowMs();

    List<LocalPage> updatedPagesList = List.from(state.pages);

    for (var p in pagesToUpdate) {
      final updated = p.copyWith(
        backgroundPdfPath: finalPath.isEmpty
            ? ''
            : finalPath, // String vazia para limpar a imagem, de forma que copyWith aceite e anule a anterior
        updatedAt: now,
      );

      await _repository.savePage(updated, targetSid);
      await _repository.markPageAsUnsynced(p.clientId);

      final idx = updatedPagesList.indexWhere(
        (element) => element.clientId == p.clientId,
      );
      if (idx != -1) {
        updatedPagesList[idx] = updated;
      }
    }

    state = state.copyWith(pages: updatedPagesList);
    scheduleAutoPush();

    final bool isCollab =
        _collabService.isCollaborationEnabled || state.isCollaborationEnabled;
    if (isCollab) {
      // 🚀 Forçar sincronismo imediato para partilhar o URL da imagem recém carregada
      _performCollectiveSync(immediate: true);
    }
  }

  Future<void> updatePageViewport(String clientId, Matrix4 matrix) async {
    final idx = state.pages.indexWhere((p) => p.clientId == clientId);
    if (idx == -1) return;
    final updated = state.pages[idx].copyWith(
      viewportMatrix: matrix,
      updatedAt: TimeService().nowMs(),
    );
    state = state.copyWith(
      pages: state.pages
          .map((p) => p.clientId == clientId ? updated : p)
          .toList(),
    );
    await _repository.savePage(updated, state.liveNotebookSid);
    // 🚀 v10.56: Viewport (Zoom/Pan da folha) também sincroniza
    await _repository.markPageAsUnsynced(clientId);
  }

  Future<void> updatePageSection(
    LocalPage page,
    String? sectionTitle, {
    String? sectionColor,
  }) async {
    if (page.id == null) return;
    final updated = page.copyWith(
      sectionTitle: sectionTitle,
      sectionColor: sectionColor,
      clearSection: sectionTitle == null || sectionTitle.isEmpty,
      updatedAt: TimeService().nowMs(),
    );
    await _repository.savePage(updated, state.liveNotebookSid);
    await _repository.markPageAsUnsynced(page.clientId); // 🚀 v10.56
    state = state.copyWith(
      pages: state.pages
          .map((p) => p.clientId == page.clientId ? updated : p)
          .toList(),
    );
  }

  Future<void> toggleFavorite(LocalPage page) async {
    if (page.id == null) return;
    final updated = page.copyWith(
      isFavorite: !page.isFavorite,
      updatedAt: TimeService().nowMs(),
    );
    await _repository.savePage(updated, state.liveNotebookSid);
    await _repository.markPageAsUnsynced(page.clientId); // 🚀 v10.56
    state = state.copyWith(
      pages: state.pages
          .map((p) => p.clientId == page.clientId ? updated : p)
          .toList(),
    );
  }

  Future<void> setLineType(LocalPage page, String type) async {
    final currentConfig =
        page.backgroundConfig ??
        BackgroundConfig(type: type, spacing: page.lineSpacing ?? 30.0);
    final updatedBackground = currentConfig.copyWith(type: type);

    final currentOrientation = page.isLandscape ? 'landscape' : 'portrait';
    final pageConfig = PageConfig(
      width: 210,
      height: 297,
      unit: 'mm',
      paperSize: page.paperSize,
      orientation: currentOrientation,
      isInfinite: page.isInfinite,
    );

    final newConfig = NotebookConfiguration(
      page: pageConfig,
      background: updatedBackground,
      margins: MarginsConfig(),
      header: HeaderFooterConfig(
        enabled: page.title != null && page.title!.isNotEmpty,
        fields: page.title != null && page.title!.isNotEmpty
            ? [page.title!]
            : [],
      ),
      footer: HeaderFooterConfig(
        enabled: page.footer != null && page.footer!.isNotEmpty,
        fields: page.footer != null && page.footer!.isNotEmpty
            ? [page.footer!]
            : [],
      ),
      numbering: NumberingConfig(),
    );

    await updatePageSettings(page, newConfig, isRemote: false);
  }

  Future<void> deletePages(List<LocalPage> pagesToDelete) async {
    final clientIds = pagesToDelete.map((p) => p.clientId).toSet();
    state = state.copyWith(
      tearingPageClientIds: {...state.tearingPageClientIds, ...clientIds},
    );
    await Future.delayed(const Duration(milliseconds: 400));
    final pageIds = pagesToDelete.map((p) => p.id).whereType<int>().toList();
    await _repository.deletePagesBatch(pageIds);
    await _repository.reindexPages(state.currentNotebookId);
    state = state.copyWith(
      pages: state.pages.where((p) => !clientIds.contains(p.clientId)).toList(),
      tearingPageClientIds: state.tearingPageClientIds
          .where((id) => !clientIds.contains(id))
          .toSet(),
    );

    final bool isCollab =
        _collabService.isCollaborationEnabled || state.isCollaborationEnabled;
    final int? targetSid =
        _collabService.liveNotebookSid ??
        state.liveNotebookSid ??
        state.currentNotebookId;
    if (isCollab && targetSid != null && targetSid > 0) {
      _realtimeService.broadcastPageEvent(
        notebookId: targetSid,
        pageData: {'action': 'delete'},
        myUserId: state.myUserId.isNotEmpty
            ? state.myUserId
            : _collabService.myUserId,
      );
      scheduleAutoPush();
    }
  }

  Future<void> deletePage(LocalPage page) async {
    await deletePages([page]);
  }

  Future<void> movePageToOtherNotebook(
    LocalPage page,
    int targetNotebookId,
  ) async {
    final targetPages = await _repository.getPagesByNotebook(
      targetNotebookId,
      null,
    );
    final int newPageNumber = targetPages.length + 1;
    await _repository.movePageToNotebook(
      page.clientId,
      targetNotebookId,
      newPageNumber,
    );
    await _repository.reindexPages(state.currentNotebookId);
    await _repository.reindexPages(targetNotebookId);
  }

  Future<void> copyPageToOtherNotebook(
    LocalPage page,
    int targetNotebookId,
  ) async {
    if (!page.isContentLoaded && page.id != null) {
      final content = await _repository.loadPageContent(
        page.id!,
        pageNumber: page.pageNumber,
      );
      page = page.copyWith(
        objects: [
          ...content['strokes'],
          ...content['textBlocks'],
          ...content['imageBlocks'],
        ],
        isContentLoaded: true,
      );
    }
    final targetPages = await _repository.getPagesByNotebook(
      targetNotebookId,
      null,
    );
    final int newPageNumber = targetPages.length + 1;
    final clonedPage = page.clone(
      newNotebookId: targetNotebookId,
      newPageNumber: newPageNumber,
    );
    await _repository.savePage(clonedPage, null);
    for (var obj in clonedPage.objects) {
      if (obj is Stroke)
        await _repository.saveSingleStroke(clonedPage.clientId, obj);
      else if (obj is TextBlock)
        await _repository.saveSingleTextBlock(clonedPage.clientId, obj);
      else if (obj is ImageBlock)
        await _repository.saveSingleImageBlock(clonedPage.clientId, obj);
      else if (obj is ShapeObject)
        await _repository.saveSingleShape(clonedPage.clientId, obj);
      else if (obj is TableObject)
        await _repository.saveSingleTable(clonedPage.clientId, obj);
      else if (obj is LinkObject)
        await _repository.saveSingleLink(clonedPage.clientId, obj);
      else if (obj is AttachmentObject)
        await _repository.saveSingleAttachment(clonedPage.clientId, obj);
      else if (obj is AudioBlock)
        await _repository.saveSingleAudioBlock(clonedPage.clientId, obj);
      else if (obj is AnimationObject)
        await _repository.saveSingleAnimationObject(clonedPage.clientId, obj);
    }
    await _repository.reindexPages(targetNotebookId);
  }

  Future<void> updatePagesSection(
    List<LocalPage> pagesToUpdate,
    String? sectionTitle, {
    String? sectionColor,
  }) async {
    for (var page in pagesToUpdate) {
      if (page.id != null) {
        final hData = {
          'title': page.title,
          'section': sectionTitle,
          'section_color': sectionColor ?? page.sectionColor,
        };
        await _repository.updatePagesSectionBatch([page.id!], hData);
      }
    }
    await _performCollectiveSync();
  }

  Future<List<LocalPage>> getDeletedPages() async {
    return await _repository.getDeletedPages(state.currentNotebookId);
  }

  Future<void> restorePage(LocalPage page) async {
    await _repository.restorePage(page.clientId);
    await _repository.reindexPages(state.currentNotebookId);
  }

  Future<void> pickAndInsertImage(
    LocalPage page, {
    BuildContext? context,
  }) async {
    final pf = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (pf != null) {
      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                ),
                SizedBox(width: 12),
                Text('A processar imagem para o caderno...'),
              ],
            ),
            duration: Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF0F4C5C),
          ),
        );
      }

      final appDir = await getApplicationDocumentsDirectory();
      final String newPath = '${appDir.path}/img_${TimeService().nowMs()}.jpg';
      final imageBytes = await io.File(pf.path).readAsBytes();
      await io.File(newPath).writeAsBytes(imageBytes);

      String finalPath = newPath;

      final int? targetSid =
          _collabService.liveNotebookSid ??
          state.liveNotebookSid ??
          state.currentNotebookId;

      if (targetSid != null && targetSid != 0) {
        try {
          final String fileName = 'img_${TimeService().nowMs()}.jpg';
          final String? remoteUrl = await _repository.uploadImage(
            targetSid,
            fileName,
            imageBytes,
          );
          if (remoteUrl != null && remoteUrl.isNotEmpty) {
            finalPath = remoteUrl;
          }
        } catch (e) {
          AppLog.canvas(
            '⚠️ [CanvasDocument] Erro no upload da imagem para colaboração: $e',
          );
        }
      }

      final nib = ImageBlock(
        id: const Uuid().v4(),
        imagePath: finalPath,
        position: const Offset(100, 150),
        width: 300.0,
        height: 200.0,
        creatorId: state.myUserId,
      );
      await _executeAction(
        AddImageAction(
          pageClientId: page.clientId,
          pageNumber: page.pageNumber,
          block: nib,
        ),
        targetPage: page,
      );

      if (context != null && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                Icon(
                  Icons.check_circle_rounded,
                  color: Colors.greenAccent,
                  size: 18,
                ),
                SizedBox(width: 10),
                Text('Imagem adicionada ao caderno!'),
              ],
            ),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Color(0xFF0F4C5C),
          ),
        );
      }
    }
  }

  Future<void> pickAndInsertAttachment(
    LocalPage page, {
    required PlatformFile file,
    required Offset position,
    BuildContext? context,
  }) async {
    final String fileName = file.name;
    final String extension = fileName.contains('.')
        ? fileName.split('.').last
        : '';
    final int sizeBytes = file.size;

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'A processar "$fileName" para o caderno...',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F4C5C),
        ),
      );
    }

    String localPath = '';
    String? remoteUrl;
    Uint8List? bytes;

    if (!kIsWeb &&
        file.path != null &&
        file.path!.isNotEmpty &&
        io.File(file.path!).existsSync()) {
      bytes = await io.File(file.path!).readAsBytes();
      final appDir = await getApplicationDocumentsDirectory();
      final attachDir = io.Directory('${appDir.path}/attachments');
      if (!await attachDir.exists()) await attachDir.create(recursive: true);

      localPath =
          '${attachDir.path}/attach_${TimeService().nowMs()}.$extension';
      await io.File(localPath).writeAsBytes(bytes);
    } else if (file.bytes != null && file.bytes!.isNotEmpty) {
      bytes = file.bytes;
      if (!kIsWeb) {
        final appDir = await getApplicationDocumentsDirectory();
        final attachDir = io.Directory('${appDir.path}/attachments');
        if (!await attachDir.exists()) await attachDir.create(recursive: true);

        localPath =
            '${attachDir.path}/attach_${TimeService().nowMs()}.$extension';
        await io.File(localPath).writeAsBytes(bytes!);
      } else if (kIsWeb) {
        remoteUrl = base64Encode(bytes!);
      }
    }

    final int? targetSid =
        _collabService.liveNotebookSid ??
        state.liveNotebookSid ??
        state.currentNotebookId;

    if (targetSid != null &&
        targetSid != 0 &&
        bytes != null &&
        bytes.isNotEmpty) {
      try {
        final String uploadName = 'attach_${TimeService().nowMs()}.$extension';
        final String? uploadedUrl = await _repository.uploadFile(
          targetSid,
          uploadName,
          bytes,
        );
        if (uploadedUrl != null && uploadedUrl.isNotEmpty) {
          remoteUrl = uploadedUrl;
        }
      } catch (e) {
        AppLog.canvas('');
      }
    }

    final attachPlaceholder = AttachmentObject(
      id: const Uuid().v4(),
      fileName: fileName,
      fileExtension: extension,
      fileSize: sizeBytes,
      localPath: localPath,
      position: position,
    );

    final int z = calculateNextZIndex(page, attachPlaceholder);

    final attach = AttachmentObject(
      id: const Uuid().v4(),
      fileName: fileName,
      fileExtension: extension,
      fileSize: sizeBytes,
      localPath: localPath,
      remoteUrl: remoteUrl,
      position: position,
      size: const Size(220, 60),
      zIndex: z,
      pageNumber: page.pageNumber,
      creatorId: state.myUserId,
      layerId: 'default',
      syncedWithCloud: remoteUrl != null,
    );

    await _executeAction(
      AddAttachmentAction(
        pageClientId: page.clientId,
        pageNumber: page.pageNumber,
        attach: attach,
      ),
      targetPage: page,
    );

    if (context != null && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.check_circle_rounded,
                color: Colors.greenAccent,
                size: 18,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Anexo "$fileName" adicionado ao caderno!',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          duration: const Duration(seconds: 2),
          behavior: SnackBarBehavior.floating,
          backgroundColor: const Color(0xFF0F4C5C),
        ),
      );
    }
  }

  Future<void> moveSelection(
    LocalPage page, {
    required Set<String> objectIds,
    required Offset delta,
  }) async {
    if (page.isFrozen || delta == Offset.zero || objectIds.isEmpty) return;
    final action = MoveAction(
      pageClientId: page.clientId,
      pageNumber: page.pageNumber,
      objectIds: objectIds.toList(),
      delta: delta,
    );
    await _executeAction(action, targetPage: page);
  }

  void broadcastLiveStroke({
    required String pageClientId,
    required int pageNumber,
    required String strokeId,
    required List<Offset> points,
    required String color,
    required double thickness,
    required bool isHighlighter,
    BrushType brushType = BrushType.gel,
    double opacity = 1.0,
    bool isFinal = false,
  }) {
    final bool isCollab =
        _collabService.isCollaborationEnabled || state.isCollaborationEnabled;
    final int? targetSid =
        _collabService.liveNotebookSid ?? state.liveNotebookSid;

    AppLog.canvas(
      '📣 [CanvasDocument] broadcastLiveStroke isCollab: $isCollab, targetSid: $targetSid',
    );

    if (!isCollab || targetSid == null) return;

    final String effectiveUserId = state.myUserId.isNotEmpty
        ? state.myUserId
        : _collabService.myUserId;

    // Flatten and Delta Encode points to save space. Since the server limit is now 256KB,
    // we can safely send high-fidelity strokes (e.g., up to 4000 points).
    final maxPts = 4000;
    final int step = points.length > maxPts
        ? (points.length / maxPts).ceil()
        : 1;
    final encodedPts = <int>[];

    if (points.isNotEmpty) {
      int lastX = (points[0].dx * 10).round();
      int lastY = (points[0].dy * 10).round();
      encodedPts.add(lastX);
      encodedPts.add(lastY);

      for (int i = step; i < points.length; i += step) {
        int curX = (points[i].dx * 10).round();
        int curY = (points[i].dy * 10).round();
        encodedPts.add(curX - lastX);
        encodedPts.add(curY - lastY);
        lastX = curX;
        lastY = curY;
      }
    }

    final data = {
      'page_client_id': pageClientId,
      'page_number': pageNumber,
      'strokes': [
        {
          'id': strokeId,
          'color': color,
          'thickness': thickness,
          'is_final': isFinal,
          'is_highlighter': isHighlighter ? 1 : 0,
          'brush_type': brushType.name,
          'opacity': opacity,
          'pts_enc': 'd1', // Indicate Delta Encoding (x10)
          'points': encodedPts,
        },
      ],
    };
    _realtimeService.broadcastStroke(
      notebookId: targetSid,
      myUserId: effectiveUserId,
      strokeData: data,
    );
  }

  Timer? _autoPushDebouncer;

  void scheduleAutoPush() {
    _autoPushDebouncer?.cancel();
    _autoPushDebouncer = Timer(const Duration(milliseconds: 1500), () {
      flushUnsyncedPages();
    });
  }

  Future<void> flushUnsyncedPages() async {
    _autoPushDebouncer?.cancel();

    // 🚀 v10.90: Bloquear HTTP Pushes Automáticos durante a Colaboração.
    // A Colaboração usa exclusivamente o Laravel Reverb (WebSockets) para
    // manter os clientes sincronizados em tempo real com alta performance.
    if (_collabService.isCollaborationEnabled || state.isCollaborationEnabled) {
      AppLog.canvas(
        '🛡️ [CanvasDocument] HTTP Push ignorado. Sala de colaboração ativa (Reverb gere o tráfego).',
      );
      return;
    }

    final nbId = state.currentNotebookId;
    if (nbId != 0 && nbId != null) {
      try {
        await _syncService.pushPages(onlyNotebookId: nbId);
      } catch (e) {
        AppLog.canvas('');
      }
    }
  }

  void reset() {
    _clearCollabServiceCallbacks();
    _collabService.leaveSession();
    _historyManager.clear();
    state = CanvasDocumentState();
  }

  void markAsDisconnected() {
    _historyManager.markDisconnected();
  }

  /// 🚀 Offline-to-Collab Merge:
  /// Transmite e grava no Redis qualquer objeto/edição criada offline antes de se juntar à sala.
  Future<void> mergeOfflineWorkIntoCollaborationSession() async {
    final bool isCollab =
        _collabService.isCollaborationEnabled || state.isCollaborationEnabled;
    final int? targetSid =
        _collabService.liveNotebookSid ??
        state.liveNotebookSid ??
        state.currentNotebookId;

    if (!isCollab || targetSid == null || targetSid == 0) return;

    bool foundUnsynced = false;

    for (var page in state.pages) {
      final unsyncedObjects = page.objects
          .where((o) => !o.syncedWithCloud)
          .toList();
      final List<String> idsToDelete = [];

      for (var obj in unsyncedObjects) {
        foundUnsynced = true;
        CanvasAction? action;

        if (obj.isDeleted) {
          idsToDelete.add(obj.id);
          continue;
        }

        if (obj is Stroke) {
          action = AddStrokeAction(
            pageClientId: page.clientId,
            pageNumber: page.pageNumber,
            stroke: obj,
          );
        } else if (obj is TextBlock) {
          action = AddTextAction(
            pageClientId: page.clientId,
            pageNumber: page.pageNumber,
            block: obj,
          );
        } else if (obj is ImageBlock) {
          action = AddImageAction(
            pageClientId: page.clientId,
            pageNumber: page.pageNumber,
            block: obj,
          );
        } else if (obj is ShapeObject) {
          action = AddShapeAction(
            pageClientId: page.clientId,
            pageNumber: page.pageNumber,
            shape: obj,
          );
        } else if (obj is AudioBlock) {
          action = AddAudioAction(
            pageClientId: page.clientId,
            pageNumber: page.pageNumber,
            audio: obj,
          );
        } else if (obj is AnimationObject) {
          action = AddAnimationAction(
            pageClientId: page.clientId,
            pageNumber: page.pageNumber,
            animation: obj,
          );
        } else if (obj is ExplanationModel) {
          action = AddExplanationAction(
            pageClientId: page.clientId,
            pageNumber: page.pageNumber,
            explanation: obj,
          );
        } else if (obj is TableObject) {
          action = AddTableAction(
            pageClientId: page.clientId,
            pageNumber: page.pageNumber,
            table: obj,
          );
        } else if (obj is LinkObject) {
          action = AddLinkAction(
            pageClientId: page.clientId,
            pageNumber: page.pageNumber,
            link: obj,
          );
        } else if (obj is AttachmentObject) {
          action = AddAttachmentAction(
            pageClientId: page.clientId,
            pageNumber: page.pageNumber,
            attach: obj,
          );
        }

        if (action != null) {
          _broadcastAction(action);
        }
      }

      if (idsToDelete.isNotEmpty) {
        _broadcastAction(
          DeleteAction(
            pageClientId: page.clientId,
            pageNumber: page.pageNumber,
            objectIds: idsToDelete,
          ),
        );
      }
    }

    if (foundUnsynced) {
      AppLog.canvas('');
      await _syncService.pushPages(onlyNotebookId: targetSid);
    }
  }

  Future<void> requestMissingHistory({bool forceFromBeginning = false}) async {
    final bool isCollab =
        _collabService.isCollaborationEnabled || state.isCollaborationEnabled;
    final int? targetSid =
        _collabService.liveNotebookSid ??
        state.liveNotebookSid ??
        state.currentNotebookId;
    final lastTs = forceFromBeginning
        ? 0
        : _historyManager.lastDisconnectTimestamp;

    if (isCollab && targetSid != null && (forceFromBeginning || lastTs > 0)) {
      AppLog.canvas(
        '🔄 [CanvasDocument] Pedindo histórico de colaboração no Redis desde $lastTs (Force: $forceFromBeginning)',
      );

      // Primeiro: Funde edições offline pendentes no Redis e Reverb da sala
      await mergeOfflineWorkIntoCollaborationSession();

      _collabService.isRecoveringHistory = true;
      _collabService.notifyListeners();

      try {
        final actions = await _syncService.pullSessionHistory(
          targetSid,
          lastTs,
        );
        if (actions.isNotEmpty) {
          AppLog.canvas('');
          for (var rawAction in actions) {
            if (rawAction is Map<String, dynamic>) {
              await _handleRemoteAction(rawAction);
            }
          }
        }
      } finally {
        _collabService.isRecoveringHistory = false;
        _collabService.notifyListeners();
      }
    }
  }

  Timer? _collectiveSyncDebouncer;

  Future<void> _performCollectiveSync({bool immediate = false}) async {
    _collectiveSyncDebouncer?.cancel();
    if (immediate) {
      await _executeCollectiveSync();
      return;
    }
    _collectiveSyncDebouncer = Timer(
      const Duration(milliseconds: 1500),
      () async {
        await _executeCollectiveSync();
      },
    );
  }

  Future<void> _executeCollectiveSync() async {
    if (state.isGlobalSyncing) return;
    state = state.copyWith(isGlobalSyncing: true);
    try {
      await requestMissingHistory(
        forceFromBeginning: true,
      ); // 🚀 Pede histórico completo da sessão ao Redis e funde trabalho offline
      if (state.currentUserRole == 'owner' ||
          state.currentUserRole == 'editor') {
        await _syncService.pushPages(onlyNotebookId: state.currentNotebookId);
      }
      await _syncService.pullPages(
        forceFull: true,
        onlyNotebookId: state.liveNotebookSid,
      );
    } finally {
      state = state.copyWith(isGlobalSyncing: false);
    }
  }

  Future<void> _handleRemoteAction(Map<String, dynamic> d) async {
    try {
      final String type = d['action_type'] ?? d['type'] ?? '';

      // 🚀 v11: Intercetar configuração da página em tempo real
      if (type == 'update_page_settings') {
        final String? clientId = d['data']?['page_client_id'];
        final int? pageNumber = d['data']?['page_number'];
        final int remoteTs =
            (d['data']?['timestamp'] ?? d['data']?['updated_at'] ?? 0) as int;
        if (d['data']?['config'] != null) {
          final config = NotebookConfiguration.fromJson(d['data']['config']);
          final target = state.pages.cast<LocalPage?>().firstWhere(
            (p) =>
                p?.clientId == clientId ||
                (p != null && pageNumber != null && p.pageNumber == pageNumber),
            orElse: () => null,
          );
          if (target != null) {
            await updatePageSettings(
              target,
              config,
              isRemote: true,
              remoteTimestamp: remoteTs > 0 ? remoteTs : null,
            );
          }
        }
        return;
      }

      // 🚀 v11: Intercetar Undo / Redo remoto especificando a ação exata
      if (type == 'sync_undo_action' ||
          type == 'sync_redo_action' ||
          type == 'sync_undo' ||
          type == 'sync_redo') {
        final String? clientId = d['data']?['page_client_id'];
        final int? pageNumber = d['data']?['page_number'];
        final String? actionType = d['data']?['action_type'];
        final Map<String, dynamic>? actionData =
            d['data']?['action_data'] != null
            ? Map<String, dynamic>.from(d['data']['action_data'])
            : null;

        if (actionType != null && actionData != null) {
          final target = state.pages.cast<LocalPage?>().firstWhere(
            (p) =>
                p?.clientId == clientId ||
                (p != null && pageNumber != null && p.pageNumber == pageNumber),
            orElse: () => null,
          );
          if (target != null) {
            final action = CanvasAction.fromMap(actionType, actionData);
            if (action != null) {
              final updatedTarget =
                  (type == 'sync_undo_action' || type == 'sync_undo')
                  ? action.undo(target)
                  : action.execute(target);
              // 🚀 v11.0: Limpar transforms ANTES de atualizar o estado para evitar piscadela/salto
              _collabService.clearAllObjectTransforms();

              state = state.copyWith(
                pages: state.pages
                    .map(
                      (p) => p.clientId == target.clientId ? updatedTarget : p,
                    )
                    .toList(),
              );

              await _persistIncrementalAction(
                updatedTarget,
                action,
                updatedAt: action.timestamp,
                isRemote: true,
              );
            }
          }
        }
        return;
      }

      final action = CanvasAction.fromMap(type, d['data']);
      if (action != null) {
        final target = state.pages.cast<LocalPage?>().firstWhere(
          (p) =>
              p?.clientId == action.pageClientId ||
              (p != null &&
                  action.pageNumber != null &&
                  p.pageNumber == action.pageNumber),
          orElse: () => null,
        );
        if (target != null) {
          final updatedTarget = (d['type'] == 'sync_undo')
              ? action.undo(target)
              : action.execute(target);

          // 🚀 v11.0: Limpar o transform temporário do objeto ANTES de atualizar o estado e salvar no DB!
          // Isso impede que durante o tempo de I/O do SQLite haja 1-2 frames com salto duplo de posição!
          if (action is MoveAction) {
            for (var oid in action.objectIds) {
              _collabService.clearObjectTransform(oid);
            }
          } else if (action is UpdateObjectAction) {
            _collabService.clearObjectTransform(action.objectId);
          } else {
            _collabService.clearAllObjectTransforms();
          }

          state = state.copyWith(
            pages: state.pages
                .map((p) => p.clientId == target.clientId ? updatedTarget : p)
                .toList(),
          );

          // 🚀 Offline-First: Tenta pre-carregar automaticamente qualquer anexo recebido remotamente
          preloadAttachmentsForPage(updatedTarget);

          // 🚀 Persist action in local DB to prevent data loss
          await _persistIncrementalAction(
            updatedTarget,
            action,
            updatedAt: action.timestamp,
            isRemote: true,
          );
        }
      }
    } catch (e, stack) {
      AppLog.canvas(
        '⚠️ [CanvasDocument] Erro ao executar ação remota: $e\n$stack',
      );
    }
  }

  Future<void> _handlePageEvent(Map<String, dynamic> d) async {
    if (d['action'] == 'add' ||
        d['action'] == 'delete' ||
        d['action'] == 'reorder')
      await _performCollectiveSync();
  }

  Future<void> _handleFullStateRequest(Map<String, dynamic> d) async {
    final idx = state.pages.indexWhere((p) => p.pageNumber == d['page_number']);
    if (idx != -1 && state.liveNotebookSid != null)
      _realtimeService.deliverFullState(
        notebookId: state.liveNotebookSid!,
        targetUserId: d['sender_id'].toString(),
        pageData: state.pages[idx].toJson(),
      );
  }

  Future<void> _handleFullStateReceived(Map<String, dynamic> d) async {
    final Map<String, dynamic> pageData = d['page_data'];
    final idx = state.pages.indexWhere(
      (p) => p.pageNumber == pageData['page_number'],
    );
    if (idx != -1) {
      final np = LocalPage.fromJson(pageData).copyWith(id: state.pages[idx].id);
      final updatedPages = List<LocalPage>.from(state.pages);
      updatedPages[idx] = np;
      await _repository.savePage(np, state.liveNotebookSid);
      state = state.copyWith(pages: updatedPages);
    }
  }

  void _autoNavigateAfterDeletion() {
    if (state.pages.isEmpty) return;
    try {
      final viewportNotifier = ref.read(canvasViewportProvider.notifier);
      final currentIndex = ref.read(canvasViewportProvider).currentPageIndex;
      int targetIndex = (currentIndex >= state.pages.length)
          ? state.pages.length - 1
          : currentIndex;
      viewportNotifier.jumpToPage(targetIndex < 0 ? 0 : targetIndex);
    } catch (e) {
      AppLog.canvas(
        '⚠️ [CanvasDocument] _autoNavigateAfterDeletion post-dispose: $e',
      );
    }
  }

  void _startSmoothTransition(Matrix4 target) {
    try {
      final viewportState = ref.read(canvasViewportProvider);
      if (viewportState.currentPageClientId == null) return;

      final controller = ref
          .read(canvasViewportProvider.notifier)
          .getControllerFor(viewportState.currentPageClientId!);

      Timer.periodic(const Duration(milliseconds: 16), (t) {
        try {
          if (!ref
              .read(canvasViewportProvider.notifier)
              .isPageInitialized(viewportState.currentPageClientId!)) {
            t.cancel();
            return;
          }

          final current = controller.value;
          final next = Matrix4.identity();
          for (int i = 0; i < 16; i++) {
            next.storage[i] =
                current.storage[i] +
                (target.storage[i] - current.storage[i]) * 0.04;
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
        } catch (e) {
          t.cancel();
        }
      });
    } catch (e) {
      AppLog.canvas('⚠️ [CanvasDocument] _startSmoothTransition post-dispose: $e');
    }
  }
}

final canvasDocumentProvider =
    NotifierProvider<CanvasDocumentNotifier, CanvasDocumentState>(() {
      return CanvasDocumentNotifier();
    });
