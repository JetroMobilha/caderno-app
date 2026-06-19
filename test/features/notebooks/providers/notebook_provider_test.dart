import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:caderno_digital_app/features/notebooks/providers/notebook_provider.dart';

void main() {
  test('Deve inicializar com lista vazia e adicionar cadernos dinamicamente', () async {
    // Container do Riverpod para testes em isolamento
    final container = ProviderContainer();
    addTearDown(container.dispose);

    // Act - Lemos o estado inicial
    var state = container.read(notebookProvider);
    expect(state, isEmpty);

    // Adicionamos um caderno de teste manualmente usando o notifier
    final notifier = container.read(notebookProvider.notifier);
    final newNotebook = Notebook(subject_id: 1, title: 'Álgebra', coverType: 'classic');

    // Atualizamos o estado diretamente para simular a inserção
    notifier.state = [newNotebook];

    // Assert - O estado deve conter o novo caderno
    state = container.read(notebookProvider);
    expect(state.length, 1);
    expect(state.first.title, 'Álgebra');
  });
}