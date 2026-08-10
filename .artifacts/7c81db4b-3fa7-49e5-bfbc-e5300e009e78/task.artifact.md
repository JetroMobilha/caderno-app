# Tarefas: Unificação de Permissões e Controles de Sessão

- `[ ]` **Refatoração do Controlador (CanvasController)**
    - `[ ]` Remover `LiveRoomType`.
    - `[ ]` Adicionar flags `isSessionLocked` e `isAuthorColorEnabled`.
    - `[ ]` Implementar métodos `toggleSessionLock` e `toggleAuthorColors`.
    - `[ ]` Atualizar lógica de persistência e broadcast das flags.
- `[ ]` **Atualização da Toolbar (CanvasToolbar)**
    - `[ ]` Adaptar lógica de bloqueio de ferramentas.
    - `[ ]` Melhorar mensagem de estado para o aluno.
- `[ ]` **Centro de Colaboração (CollaborationCenterSheet)**
    - `[ ]` Remover seletor de dinâmica antigo.
    - `[ ]` Adicionar novos switches para o Dono.
- `[ ]` **Pintura e Visualização (CanvasPainter)**
    - `[ ]` Atualizar pintores para usar `isAuthorColorEnabled`.
- `[ ]` **Verificação**
    - `[ ]` Validar persistência entre reinícios.
    - `[ ]` Validar sincronização WebSocket em tempo real.
