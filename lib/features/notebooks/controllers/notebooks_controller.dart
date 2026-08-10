import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:caderno_digital_app/features/notebooks/repositories/notebook_repository.dart';
import 'package:caderno_digital_app/features/notebooks/repositories/shared_notebook_repository.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';

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

  Future<bool> shareNotebook(int notebookServerId, String email, String role) async {
    final bool success = await _repository.shareNotebookWithFriend(notebookId: notebookServerId, email: email, role: role);
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

  Future<void> duplicateNotebook(Notebook source, int targetSubjectId) async {
    state = state.copyWith(isLoading: true);
    try {
      // 1. Criar o novo caderno local
      final newNotebook = Notebook(
        subjectId: targetSubjectId,
        title: '${source.title} (Cópia)',
        coverType: source.coverType,
        color: source.color,
        coverImage: source.coverImage,
        lineType: source.lineType,
        paperSize: source.paperSize,
        lineSpacing: source.lineSpacing,
        templateType: source.templateType,
        authorName: source.authorName, // Mantém o autor original
        description: source.description,
      );

      final int newId = await _repository.insertNotebook(newNotebook);
      newNotebook.id = newId;

      // 2. Buscar páginas do original
      final sourcePages = await _canvasRepository.getPagesByNotebook(source.id!, source.serverId);

      // 3. Copiar cada página
      for (var page in sourcePages) {
        final newPage = page.copyWith(
          id: null,
          serverId: null,
          notebookId: newId,
          syncedWithCloud: 0,
        );
        await _canvasRepository.savePage(newPage, null);
      }
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }
}

final notebooksProvider = NotifierProvider<NotebooksController, NotebooksState>(() {
  return NotebooksController();
});
