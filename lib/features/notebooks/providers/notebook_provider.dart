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

  /// 🚀 ATUALIZADO: Devolve o Future<int> com o ID real gerado pelo SQLite
  Future<int> addNotebook(Notebook notebook) async {
    // 1. O repositório insere na BD e atualiza o notebook.id internamente
    final int generatedId = await _repository.insertNotebook(notebook);

    // 2. Adiciona o novo objeto atualizado com o ID, mantendo a imutabilidade
    state = [...state, notebook];

    // 3. Devolve o ID para que a UI possa abrir o CanvasScreen imediatamente
    return generatedId;
  }
}

/// Provider global para expor e escutar o estado dos cadernos
final notebookProvider = NotifierProvider<NotebookNotifier, List<Notebook>>(() {
  return NotebookNotifier();
});