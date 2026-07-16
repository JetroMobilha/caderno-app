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
  bool _isShowingShared = false;

  @override
  List<Notebook> build() {
    return [];
  }

  Future<void> loadNotebooks(int subjectId, {int? subjectServerId}) async {
    _isShowingShared = false;
    _currentSubjectId = subjectId;
    _currentSubjectServerId = subjectServerId; // 🚀 Guarda na memória
    state = await _repository.getNotebooksBySubject(subjectId, subjectServerId);
  }

  // 🚀 MÉTODO LIMPO: Não pede parâmetros à UI! Ele próprio descobre quem está logado.
  Future<void> loadSharedNotebooks() async {
    state = []; // Limpa o estado para evitar fantasmas visuais

    // 🧠 O Controlador vai ao AuthProvider buscar o utilizador sozinho
    final currentUser = ref.read(authProvider).currentUser;

    // Se por acaso não houver utilizador, aborta em segurança
    if (currentUser == null) return;

    final int localUserId = currentUser.id ?? 0;
    final int? serverId = currentUser.serverId;

    // Instancia o repositório passando os IDs capturados internamente
    final sharedNotebooks = await SharedNotebookRepository().getSharedNotebooks(
        localUserId,
        serverUserId: serverId
    );

    state = sharedNotebooks;
  }
  // =========================================================================
  // 🔄 RECARREGAR ESTADO (Usado pelo SyncService e Partilhas)
  // =========================================================================
  Future<void> refreshCurrent() async {
    try {
      if (_isShowingShared && _currentUserId != null) {
        state = await _sharedRepository.getSharedNotebooks(_currentUserId!);
      } else if (_currentSubjectId != null) {
        // 🚀 AGORA PASSA O SERVER ID TAMBÉM!
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
    if (notebook.role == 'viewer' || notebook.role == 'student') {
      debugPrint('🚨 [SEGURANÇA LOCAL] Edição bloqueada! O utilizador é apenas um ${notebook.role}.');
      return;
    }

    await _repository.updateNotebook(notebook);
    // 🛡️ PREVINE O DESAPARECIMENTO: Atualiza apenas o item modificado mantendo o resto da lista intacto!
    state = state.map((n) => n.id == notebook.id ? notebook : n).toList();
  }

  Future<void> deleteNotebook(Notebook notebook) async {
    if (notebook.role != 'owner') {
      debugPrint('🚨 [SEGURANÇA LOCAL] Exclusão bloqueada! Apenas o owner pode apagar o caderno.');
      return;
    }

    await _repository.deleteNotebook(notebook);
    state = state.where((n) => n.id != notebook.id).toList();
  }

  // =========================================================================
  // 🤝 EFETUAR PARTILHA E ATUALIZAR ACESSOS IMEDIATAMENTE
  // =========================================================================
  Future<bool> shareNotebook(int notebookServerId, String email, String role) async {
    final bool success = await _repository.shareNotebookWithFriend(
      notebookId: notebookServerId,
      email: email,
      role: role,
    );

    if (success) {
      // 🚀 FORÇA O REFRESH: Atualiza os carimbos de tempo locais para que as abas se mantenham vivas e estáveis
      await refreshCurrent();
    }
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
    if (success) {
      await refreshCurrent();
    }
    return success;
  }
}

final notebooksProvider = NotifierProvider<NotebooksController, List<Notebook>>(() {
  return NotebooksController();
});