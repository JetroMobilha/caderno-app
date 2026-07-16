import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:caderno_digital_app/features/notebooks/repositories/notebook_repository.dart';
import 'package:caderno_digital_app/features/notebooks/repositories/shared_notebook_repository.dart';

import '../../auth/controllers/auth_controller.dart';

class NotebooksController extends Notifier<List<Notebook>> {
  final NotebookRepository _repository = NotebookRepository();
  final SharedNotebookRepository _sharedRepository = SharedNotebookRepository();

  int? _currentSubjectId;
  int? _currentSubjectServerId;
  int? _currentUserId;
  bool _isShowingShared = false; // 🚀 O "Disjuntor" da memória

  @override
  List<Notebook> build() {
    return [];
  }

  Future<void> loadNotebooks(int subjectId, {int? subjectServerId}) async {
    _isShowingShared = false;
    _currentSubjectId = subjectId;
    _currentSubjectServerId = subjectServerId;
    state = await _repository.getNotebooksBySubject(subjectId, subjectServerId);
  }

  Future<void> loadSharedNotebooks() async {
    state = [];

    // 🚀 LIGA O DISJUNTOR DA MEMÓRIA PARA SOBREVIVER AO SYNC!
    _isShowingShared = true;
    _currentSubjectId = -1;

    final currentUser = ref.read(authProvider).currentUser;
    if (currentUser == null) return;

    final int localUserId = currentUser.id ?? 0;
    final int? serverId = currentUser.serverId;

    _currentUserId = localUserId; // Guarda quem somos na memória

    final sharedNotebooks = await SharedNotebookRepository().getSharedNotebooks(
        localUserId,
        serverUserId: serverId
    );

    state = sharedNotebooks;
  }

  Future<void> refreshCurrent() async {
    try {
      if (_isShowingShared && _currentUserId != null) {
        // 🚀 RECUPERA O SERVER ID ATUALIZADO (Caso a sync tenha trazido um novo)
        final currentUser = ref.read(authProvider).currentUser;
        state = await _sharedRepository.getSharedNotebooks(
            _currentUserId!,
            serverUserId: currentUser?.serverId
        );
      } else if (_currentSubjectId != null && _currentSubjectId != -1) {
        state = await _repository.getNotebooksBySubject(_currentSubjectId!, _currentSubjectServerId);
      }
    } catch (e, stack) {
      debugPrint('🚨 ERRO AO RENDERIZAR CADERNOS APÓS SYNC: $e\n$stack');
    }
  }

  Future<int> addNotebook(Notebook notebook, int? subjectServerId) async {
    final int generatedId = await _repository.insertNotebook(notebook);
    final newNotebookWithId = notebook.copyWith(id: generatedId, syncedWithCloud: 0);

    if (!_isShowingShared) {
      state = [newNotebookWithId, ...state];
    }
    return generatedId;
  }

  Future<void> updateNotebook(Notebook notebook) async {
    if (notebook.role == 'viewer' || notebook.role == 'student') return;

    await _repository.updateNotebook(notebook);
    state = state.map((n) => n.id == notebook.id ? notebook : n).toList();
  }

  Future<void> deleteNotebook(Notebook notebook) async {
    if (notebook.role != 'owner') return;

    await _repository.deleteNotebook(notebook);
    state = state.where((n) => n.id != notebook.id).toList();
  }

  Future<bool> shareNotebook(int notebookServerId, String email, String role) async {
    final bool success = await _repository.shareNotebookWithFriend(notebookId: notebookServerId, email: email, role: role);
    if (success) await refreshCurrent();
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
    if (success) await refreshCurrent();
    return success;
  }
}

final notebooksProvider = NotifierProvider<NotebooksController, List<Notebook>>(() {
  return NotebooksController();
});