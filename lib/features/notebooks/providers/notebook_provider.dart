import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notebook_model.dart';
import '../repositories/notebook_repository.dart';

class NotebookNotifier extends Notifier<List<Notebook>> {
  final _repository = NotebookRepository();

  // 🚀 O ALVO DE FOCO: Guarda o ID da disciplina que está aberta no ecrã do telemóvel
  int? _currentSubjectId;

  @override
  List<Notebook> build() {
    // Estado inicial começa vazio
    return [];
  }

  /// Carrega os cadernos da base de dados filtrados por uma disciplina específica
  Future<void> loadNotebooks(int subjectId) async {
    _currentSubjectId = subjectId; // 🎯 Bloqueia o foco do radar neste ID!
    state = await _repository.getNotebooksBySubject(subjectId);
  }

  // 🚀 O SINAL DE REFORÇO: Força a interface a reler o SQLite se o radar de fundo achar novidades
  Future<void> refreshCurrent() async {
    if (_currentSubjectId != null) {
      state = await _repository.getNotebooksBySubject(_currentSubjectId!);
    }
  }

  /// Devolve o Future<int> com o ID real gerado pelo SQLite
  Future<int> addNotebook(Notebook notebook) async {
    final int generatedId = await _repository.insertNotebook(notebook);
    state = [...state, notebook];
    return generatedId;
  }
}

/// Provider global para expor e escutar o estado dos cadernos
final notebookProvider = NotifierProvider<NotebookNotifier, List<Notebook>>(() {
  return NotebookNotifier();
});