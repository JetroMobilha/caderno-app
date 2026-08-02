# Tarefas: Imersão Colaborativa e Refinamento UX

- `[ ]` Refinar Edição de Imagem
    - `[ ]` Implementar "Bring to Front" (trazer para a frente) ao selecionar imagem no `CanvasController.dart`
    - `[ ]` Adicionar botão de confirmação (✅) para salvar alterações e gravar no histórico
- `[ ]` Histórico Colaborativo Total (Undo/Redo para todos)
    - `[ ]` Sincronizar a adição de ações remotas na pilha de `_undoStack` de todos os utilizadores
    - `[ ]` Broadcast de comandos `undo` e `redo` para execução síncrona em todos os dispositivos
- `[ ]` Corrigir Inserção de Texto
    - `[ ]` Ajustar `GestureDetector` e `IgnorePointer` em `CanvasScreen.dart` para permitir criação de blocos de texto
- `[ ]` Otimização de Imagens em Grupo
    - `[ ]` Melhorar a resiliência do carregamento de imagens remotas
- `[ ]` Verificação e Testes
    - `[ ]` Testar se a imagem selecionada fica à frente das outras
    - `[ ]` Validar se o Utilizador B consegue desfazer uma ação do Utilizador A
    - `[ ]` Verificar se a criação de texto voltou a funcionar
