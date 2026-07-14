import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/notebook_model.dart';
import '../repositories/notebook_repository.dart';

// ============================================================================
// 🧠 CONTROLADOR DE CADERNOS: GERE A ESTANTE E O FOCO DO RADAR
// ============================================================================
class NotebooksController extends Notifier<List<Notebook>> {
  final _repository = NotebookRepository();

  // 🚀 O ALVO DE FOCO: Guarda o ID da disciplina que está aberta no ecrã
  int? _currentSubjectId;

  @override
  List<Notebook> build() {
    return []; // Estado inicial vazio
  }

  // 1. CARREGA OS CADERNOS FILTRADOS POR DISCIPLINA
  Future<void> loadNotebooks(int subjectId, {int? subjectServerId}) async {
    _currentSubjectId = subjectId; // 🎯 Bloqueia o foco do radar neste ID!
    state = await _repository.getNotebooksBySubject(subjectId, subjectServerId);
  }

  // 2. O SINAL DE REFORÇO: Força a interface a reler se o radar de fundo achar novidades
  Future<void> refreshCurrent() async {
    if (_currentSubjectId != null) {
      state = await _repository.getNotebooksBySubject(_currentSubjectId!, null);
    }
  }

  // 3. ADICIONAR NOVO CADERNO COM ID OTIMISTA NA RAM
  Future<int> addNotebook(Notebook notebook, int? subjectServerId) async {
    // 1. Grava no disco (SQLite) ou Nuvem (API) através do teu repositório
    final int generatedId = await _repository.insertNotebook(notebook);

    // 2. Cria uma cópia otimista do caderno já com o ID real atribuído
    final newNotebookWithId = Notebook(
      id: generatedId,
      serverId: notebook.serverId,
      subjectId: notebook.subjectId,
      title: notebook.title,
      coverType: notebook.coverType,
      color: notebook.color,
      lineType: notebook.lineType,
      paperSize: notebook.paperSize,
      syncedWithCloud: 0,
    );

    // 3. Atualiza a estante de imediato na memória RAM
    state = [...state, newNotebookWithId];
    return generatedId;
  }

  // 4. APAGAR CADERNO
  Future<void> deleteNotebook(Notebook notebook) async {
    await _repository.deleteNotebook(notebook);
    state = state.where((n) => n.id != notebook.id && (n.serverId == null || n.serverId != notebook.serverId)).toList();
  }
}

// ============================================================================
// 🚀 ANTENA GLOBAL DO RIVERPOD PARA OS CADERNOS (PLURAL)
// ============================================================================
final notebooksProvider = NotifierProvider<NotebooksController, List<Notebook>>(() {
  return NotebooksController();
});