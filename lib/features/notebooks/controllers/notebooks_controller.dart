import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:caderno_digital_app/features/notebooks/repositories/notebook_repository.dart';
import 'package:caderno_digital_app/features/notebooks/repositories/shared_notebook_repository.dart';

class NotebooksController extends Notifier<List<Notebook>> {
  final NotebookRepository _repository = NotebookRepository();
  final SharedNotebookRepository _sharedRepository = SharedNotebookRepository();

  int? _currentSubjectId;
  int? _currentUserId;
  bool _isShowingShared = false;

  @override
  List<Notebook> build() {
    return [];
  }

  Future<void> loadNotebooks(int subjectId, {int? subjectServerId}) async {
    _isShowingShared = false;
    _currentSubjectId = subjectId;
    state = await _repository.getNotebooksBySubject(subjectId, subjectServerId);
  }

  Future<void> loadSharedNotebooks(int currentUserId) async {
    _isShowingShared = true;
    _currentSubjectId = null;
    _currentUserId = currentUserId;
    state = await _sharedRepository.getSharedNotebooks(currentUserId);
  }

  Future<void> refreshCurrent() async {
    if (_isShowingShared && _currentUserId != null) {
      state = await _sharedRepository.getSharedNotebooks(_currentUserId!);
    } else if (_currentSubjectId != null) {
      state = await _repository.getNotebooksBySubject(_currentSubjectId!, null);
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

  // =========================================================================
  // 🛡️ BLINDAGEM DE EDIÇÃO: Apenas Donos e Editores alteram a capa/título
  // =========================================================================
  Future<void> updateNotebook(Notebook notebook) async {
    if (notebook.role == 'viewer' || notebook.role == 'student') {
      debugPrint('🚨 [SEGURANÇA LOCAL] Edição bloqueada! O utilizador é apenas um ${notebook.role}.');
      return; // 🛑 Aborta a operação!
    }

    await _repository.updateNotebook(notebook);
    state = state.map((n) => n.id == notebook.id ? notebook : n).toList();
  }

  // =========================================================================
  // 🛡️ BLINDAGEM DE EXCLUSÃO: Apenas o Dono Absoluto pode destruir o caderno
  // =========================================================================
  Future<void> deleteNotebook(Notebook notebook) async {
    if (notebook.role != 'owner') {
      debugPrint('🚨 [SEGURANÇA LOCAL] Exclusão bloqueada! Apenas o owner pode apagar o caderno.');
      return; // 🛑 Aborta a operação!
    }

    await _repository.deleteNotebook(notebook);
    state = state.where((n) => n.id != notebook.id).toList();
  }
}

final notebooksProvider = NotifierProvider<NotebooksController, List<Notebook>>(() {
  return NotebooksController();
});