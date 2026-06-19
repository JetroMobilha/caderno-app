import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';

// Simulação estrita do repositório em memória para o teste relacional
class MockWebNotebookRepository {
  final List<Notebook> _mockDb = [];

  Future<List<Notebook>> fetchNotebooksBySubject(int subjectId) async {
    return _mockDb.where((notebook) => notebook.subject_id == subjectId).toList();
  }

  Future<void> saveNotebook(Notebook notebook) async {
    _mockDb.add(notebook);
  }
}

void main() {
  test('Deve filtrar e retornar apenas os cadernos pertencentes ao subject_id correto', () async {
    final repository = MockWebNotebookRepository();

    // Cadernos da Disciplina 1 (ex: Matemática)
    await repository.saveNotebook(Notebook(subject_id: 1, title: 'Álgebra', coverType: 'ruled'));
    await repository.saveNotebook(Notebook(subject_id: 1, title: 'Geometria', coverType: 'grid'));

    // Caderno da Disciplina 2 (ex: História)
    await repository.saveNotebook(Notebook(subject_id: 2, title: 'Idade Média', coverType: 'blank'));

    // Act: Buscamos apenas os cadernos da disciplina 1
    final notebooksSubject1 = await repository.fetchNotebooksBySubject(1);

    // Assert
    expect(notebooksSubject1.length, 2);
    expect(notebooksSubject1.any((n) => n.title == 'Idade Média'), isFalse);
    expect(notebooksSubject1.any((n) => n.title == 'Álgebra'), isTrue);
  });
}