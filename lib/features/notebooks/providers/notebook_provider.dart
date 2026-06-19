import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notebook_model.dart';
import '../repositories/notebook_repository.dart';

/// Classe encarregue de gerir o estado da lista de cadernos exibida na UI
class NotebookNotifier extends Notifier<List<Notebook>> {
  final _repository = NotebookRepository();

  @override
  List<Notebook> build() {
    // Estado inicial começa vazio e aguarda a chamada do filtro por disciplina
    return [];
  }

  /// Carrega os cadernos da base de dados filtrados por uma disciplina específica
  Future<void> loadNotebooks(int subjectId) async {
    state = await _repository.getNotebooksBySubject(subjectId);
  }

  /// Cria um novo caderno associado a uma disciplina e atualiza o estado da UI
  Future<void> addNotebook(Notebook notebook) async {
    await _repository.insertNotebook(notebook);
    // Adiciona o novo objeto mantendo a imutabilidade do estado
    state = [...state, notebook];
  }
}

/// Provider global para expor e escutar o estado dos cadernos
final notebookProvider = NotifierProvider<NotebookNotifier, List<Notebook>>(() {
  return NotebookNotifier();
});