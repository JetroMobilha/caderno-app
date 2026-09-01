import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:caderno_digital_app/features/notebooks/repositories/notebook_repository.dart';
import 'package:caderno_digital_app/features/notebooks/repositories/shared_notebook_repository.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';
import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_template.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'package:uuid/uuid.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../subjects/controllers/subjects_controller.dart';

class NotebooksState {
  final List<Notebook> notebooks;
  final bool isLoading;

  NotebooksState({required this.notebooks, this.isLoading = false});

  NotebooksState copyWith({List<Notebook>? notebooks, bool? isLoading}) {
    return NotebooksState(
      notebooks: notebooks ?? this.notebooks,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class NotebooksController extends Notifier<NotebooksState> {
  StreamSubscription? _subscription;

  int? _currentSubjectId;
  bool _isShowingShared = false;
  bool _hasStreamEmitted = false; // 🚩 Flag para saber se o banco já respondeu
  List<Notebook> _lastData = [];

  @override
  NotebooksState build() {
    // 📡 REATIVIDADE MÁXIMA: Escuta a disciplina ativa e troca o stream automaticamente!
    final activeSubject = ref.watch(activeSubjectProvider);
    // Escuta mudanças no utilizador (Login/Logout/Update)
    final auth = ref.watch(authProvider);

    if (!auth.isAuthenticated || activeSubject == null || activeSubject.id == null) {
      _currentSubjectId = null;
      _subscription?.cancel();
      _lastData = [];
      _hasStreamEmitted = false;
      return NotebooksState(notebooks: [], isLoading: false);
    }

    // 🚀 LÓGICA DE CARREGAMENTO SEGURO
    if (activeSubject.id == -1) {
      _loadSharedStream(fromBuild: true);
    } else {
      _loadNormalStream(activeSubject.id!, fromBuild: true);
    }

    // Só é loading se ainda não recebemos NADA do stream desta matéria E o subject é válido
    bool stillLoading = !_hasStreamEmitted && _currentSubjectId != null;
    
    return NotebooksState(notebooks: _lastData, isLoading: stillLoading);
  }

  NotebookRepository get _repository => ref.read(notebookRepositoryProvider);
  SharedNotebookRepository get _sharedRepository => ref.read(sharedNotebookRepositoryProvider);
  CanvasRepository get _canvasRepository => ref.read(canvasRepositoryProvider);

  void _loadNormalStream(int subjectId, {bool fromBuild = false}) {
    if (_currentSubjectId == subjectId && !_isShowingShared) return;

    _isShowingShared = false;
    _currentSubjectId = subjectId;
    _hasStreamEmitted = false; // Reset ao mudar de matéria
    _subscription?.cancel();
    
    // Se mudou de matéria, limpamos o cache para não mostrar cadernos da matéria anterior
    _lastData = [];
    if (!fromBuild) {
      state = NotebooksState(notebooks: [], isLoading: true);
    }

    _subscription = _repository.watchNotebooksBySubject(subjectId).listen((list) {
      debugPrint('📡 [Notebooks] Stream emitiu ${list.length} cadernos para subject $subjectId');
      _lastData = list;
      _hasStreamEmitted = true;
      // 🚀 SEGURANÇA TOTAL: Sempre agendar a atualização para evitar conflitos de ciclo de vida
      Future.microtask(() {
        if (_currentSubjectId == subjectId) {
          state = NotebooksState(notebooks: list, isLoading: false);
        }
      });
    });

    // 🛡️ FAILSAFE: Se o banco demorar mais de 500ms (raro), paramos o spinner para não prender o utilizador
    Future.delayed(const Duration(milliseconds: 500), () {
      if (!_hasStreamEmitted && _currentSubjectId == subjectId) {
        debugPrint('⚠️ [Notebooks] Failsafe ativado: Parando spinner por timeout.');
        _hasStreamEmitted = true;
        // Só atualizamos o estado se o controlador ainda estiver montado
        try {
          state = NotebooksState(notebooks: _lastData, isLoading: false);
        } catch (_) {}
      }
    });
  }

  void _loadSharedStream({bool fromBuild = false}) {
    if (_isShowingShared) return;

    _isShowingShared = true;
    _currentSubjectId = -1;
    _hasStreamEmitted = false;
    _subscription?.cancel();

    _lastData = [];
    if (!fromBuild) {
      state = NotebooksState(notebooks: [], isLoading: true);
    }

    final currentUser = ref.read(authProvider).currentUser;
    if (currentUser == null || currentUser.id == null) {
      _hasStreamEmitted = true;
      if (!fromBuild) {
        state = NotebooksState(notebooks: [], isLoading: false);
      }
      return;
    }

    _subscription = _sharedRepository
        .watchSharedNotebooks(currentUser.id!)
        .listen((list) {
      _lastData = list;
      _hasStreamEmitted = true;
      Future.microtask(() {
        state = NotebooksState(notebooks: list, isLoading: false);
      });
    });
  }

  Future<int> addNotebook(Notebook notebook, int? subjectServerId) async {
    final int generatedId = await _repository.insertNotebook(notebook);
    
    // 🚀 AUTOMAÇÃO DE TEMPLATE: Criar a primeira folha baseada no template ou config
    try {
      final config = notebook.configuration ?? (() {
        final templateType = NotebookTemplateType.values.firstWhere(
          (e) => e.name == notebook.templateType,
          orElse: () => NotebookTemplateType.blank,
        );
        return NotebookTemplateConfig.templates[templateType]!.config;
      })();
      
      final firstPage = LocalPage(
        notebookId: generatedId,
        pageNumber: 1,
        isLandscape: config.page.orientation == 'landscape',
        paperSize: config.page.paperSize,
        lineType: config.background.type == 'blank' ? null : config.background.type,
        lineSpacing: config.background.spacing,
        backgroundConfig: config.background, // 🚀 NOVO
        title: config.header.enabled ? (config.header.fields.isNotEmpty ? config.header.fields.join(' / ') : '') : '',
        footer: config.footer.enabled ? (config.footer.fields.isNotEmpty ? config.footer.fields.join(' / ') : '') : '',
        updatedAt: TimeService().nowMs(),
      );

      await _canvasRepository.savePage(firstPage, notebook.serverId);
      debugPrint('📄 [Notebooks] Primeira folha criada automaticamente (${config.background.type}/${config.background.subType})');
    } catch (e) {
      debugPrint('⚠️ [Notebooks] Falha ao criar folha inicial automática: $e');
    }

    return generatedId;
  }

  /// 🚀 Insere um caderno vindo do Marketplace (já com serverId)
  Future<void> insertExternalNotebook(Notebook notebook) async {
    await _repository.insertNotebook(notebook);
  }

  Future<void> updateNotebook(Notebook notebook) async {
    if (notebook.role == 'viewer' || notebook.role == 'student') return;
    await _repository.updateNotebook(notebook);
  }

  Future<void> deleteNotebook(Notebook notebook) async {
    if (notebook.role != 'owner') return;
    await _repository.deleteNotebook(notebook);
  }

  Future<void> restoreNotebook(Notebook notebook) async {
    if (notebook.id == null) return;
    await _repository.restoreNotebook(notebook.id!);
    // 🚀 O sync cuidará de avisar o servidor
    ref.read(subjectsProvider.notifier).syncManuallyWithCloud();
  }

  Future<List<Notebook>> getTrashItems() async {
    return await _repository.getDeletedNotebooks();
  }

  Future<void> emptyTrash() async {
    final deleted = await _repository.getDeletedNotebooks();
    for (var nb in deleted) {
      if (nb.id != null) await _repository.hardDeleteNotebook(nb.id!);
    }
  }

  Future<void> moveNotebook(Notebook notebook, int targetSubjectId) async {
    final updated = notebook.copyWith(subjectId: targetSubjectId);
    await _repository.updateNotebook(updated);
  }

  Future<bool> shareNotebook(int notebookServerId, String email, String role, {String? alternativeTitle, String? sharingType, List<int>? pageIds}) async {
    final bool success = await _repository.shareNotebookWithFriend(
      notebookId: notebookServerId, 
      email: email, 
      role: role,
      alternativeTitle: alternativeTitle,
      sharingType: sharingType,
      pageIds: pageIds,
    );
    return success;
  }

  Future<List<String>> getEmailSuggestions(String query) async {
    return await _repository.searchEmails(query);
  }

  Future<List<Map<String, String>>> loadCollaborators(int notebookServerId) async {
    return await _repository.fetchCollaborators(notebookServerId);
  }

  Future<bool> revokeAccess(int notebookServerId, String email) async {
    final bool success = await _repository.removeShareWithFriend(notebookId: notebookServerId, email: email);
    return success;
  }

  Future<bool> leaveNotebook(Notebook notebook) async {
    if (notebook.serverId == null) return false;
    final currentUser = ref.read(authProvider).currentUser;
    if (currentUser == null) return false;

    final bool success = await _repository.leaveSharedNotebook(notebook.serverId!, currentUser.email);
    if (success) {
      // 🚀 REMOÇÃO IMEDIATA LOCAL: Não esperar pelo próximo sync
      await _repository.deleteNotebook(notebook);
      // Opcional: forçar sync para limpar qualquer resíduo
      ref.read(subjectsProvider.notifier).syncManuallyWithCloud();
    }
    return success;
  }

  Future<bool> updateSessionSettings({
    required int notebookId,
    required String sharingType,
    String? alternativeTitle,
    List<int>? pageIds,
  }) async {
    return await _repository.updateSessionSettings(
      notebookId: notebookId,
      sharingType: sharingType,
      alternativeTitle: alternativeTitle,
      pageIds: pageIds,
    );
  }

  Future<bool> updateUserRole(int notebookServerId, String email, String role, {String? targetUserId}) async {
    // 🚀 REUTILIZAR LÓGICA DE SHARE (que faz updateOrInsert no Laravel)
    final bool success = await _repository.shareNotebookWithFriend(
      notebookId: notebookServerId, 
      email: email, 
      role: role,
    );

    if (success && targetUserId != null) {
      // 🚀 AVISAR EM TEMPO REAL VIA WEBSOCKET
      ref.read(realtimeServiceProvider).broadcastRoleUpdate(
        notebookId: notebookServerId, 
        targetUserId: targetUserId, 
        newRole: role,
      );
    }
    return success;
  }

  Future<Map<String, dynamic>?> getSessionStatus(int notebookServerId) async {
    return await _repository.fetchSessionStatus(notebookServerId);
  }

  Future<void> duplicateNotebook(Notebook source, int targetSubjectId) async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Criar o novo caderno local usando Clonagem
      final newNotebook = source.clone(newSubjectId: targetSubjectId);
      
      // Ajuste opcional para o título da cópia se não for o dono
      if (source.role != 'owner') {
        newNotebook.title = '${source.title} (Minha Cópia)';
        newNotebook.authorName = 'Eu (Original: ${source.authorName ?? "Colega"})'; // Se precisarmos editar campos finais
      }

      final int newId = await _repository.insertNotebook(newNotebook);
      newNotebook.id = newId;

      // 2. Buscar páginas do original COM CONTEÚDO COMPLETO
      // 🚀 Forçamos a leitura fresca do disco para garantir que strokes/textos estão presentes
      final sourcePages = await _canvasRepository.getPagesByNotebook(source.id!, source.serverId);
      debugPrint('📋 [Duplicate] Iniciando cópia de ${sourcePages.length} páginas para o caderno $newId');

      // 3. Copiar cada página usando Clonagem Profunda
      for (var page in sourcePages) {
        final clonedPage = page.clone(
          newNotebookId: newId,
          newPageNumber: page.pageNumber, // Mantém o número original no novo caderno
        );
        
        // Salvar a folha primeiro (gera o ID local correto no SQLite)
        final int newLocalPageId = await _canvasRepository.savePage(clonedPage, null);
        debugPrint('📄 [Duplicate] Folha original (localId: ${page.id}) copiada para nova localId $newLocalPageId');
        
        for (var stroke in clonedPage.strokes) {
          await _canvasRepository.saveSingleStroke(clonedPage.clientId, stroke);
        }

        for (var text in clonedPage.textBlocks) {
          await _canvasRepository.saveSingleTextBlock(clonedPage.clientId, text);
        }

        for (var img in clonedPage.imageBlocks) {
          await _canvasRepository.saveSingleImageBlock(clonedPage.clientId, img);
        }
        
        debugPrint('✅ [Duplicate] Conteúdo da folha ${page.pageNumber} duplicado com Clonagem Real');
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final notebooksProvider = NotifierProvider<NotebooksController, NotebooksState>(() {
  return NotebooksController();
});
