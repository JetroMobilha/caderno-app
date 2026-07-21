import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:caderno_digital_app/features/notebooks/repositories/notebook_repository.dart';
import 'package:caderno_digital_app/features/notebooks/repositories/shared_notebook_repository.dart';

import '../../auth/controllers/auth_controller.dart';
import '../../subjects/controllers/subjects_controller.dart';

class NotebooksController extends Notifier<List<Notebook>> {
  StreamSubscription? _subscription;

  int? _currentSubjectId;
  bool _isShowingShared = false;
  List<Notebook> _lastData = [];

  @override
  List<Notebook> build() {
    // 📡 REATIVIDADE MÁXIMA: Escuta a disciplina ativa e troca o stream automaticamente!
    final activeSubject = ref.watch(activeSubjectProvider);
    // Escuta mudanças no utilizador (Login/Logout/Update)
    final auth = ref.watch(authProvider);

    if (!auth.isAuthenticated || activeSubject == null) {
      _currentSubjectId = null;
      _subscription?.cancel();
      _lastData = [];
      return [];
    }

    if (activeSubject.id == -1) {
      _loadSharedStream();
    } else {
      _loadNormalStream(activeSubject.id!);
    }

    return _lastData;
  }

  NotebookRepository get _repository => ref.read(notebookRepositoryProvider);
  SharedNotebookRepository get _sharedRepository => ref.read(sharedNotebookRepositoryProvider);

  void _loadNormalStream(int subjectId) {
    if (_currentSubjectId == subjectId && !_isShowingShared) return;

    _isShowingShared = false;
    _currentSubjectId = subjectId;
    _subscription?.cancel();
    
    // Se mudou de matéria, limpamos o cache para não mostrar cadernos da matéria anterior
    _lastData = [];

    _subscription = _repository.watchNotebooksBySubject(subjectId).listen((list) {
      _lastData = list;
      state = list;
    });
  }

  void _loadSharedStream() {
    if (_isShowingShared) return;

    _isShowingShared = true;
    _currentSubjectId = -1;
    _subscription?.cancel();

    // Limpar cache ao mudar para partilhados
    _lastData = [];

    final currentUser = ref.read(authProvider).currentUser;
    if (currentUser == null || currentUser.id == null) {
      state = [];
      return;
    }

    _subscription = _sharedRepository
        .watchSharedNotebooks(currentUser.id!, serverUserId: currentUser.serverId)
        .listen((list) {
      _lastData = list;
      state = list;
    });
  }

  Future<int> addNotebook(Notebook notebook, int? subjectServerId) async {
    final int generatedId = await _repository.insertNotebook(notebook);
    return generatedId;
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
}

final notebooksProvider = NotifierProvider<NotebooksController, List<Notebook>>(() {
  return NotebooksController();
});