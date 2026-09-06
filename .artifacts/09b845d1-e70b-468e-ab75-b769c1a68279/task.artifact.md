# Tarefa: Fase 4.4 - Refinamento de Interatividade e Persistência do Organizador ✍️💾

- [ ] **T1: Persistência no Organizador**
    - [ ] Atualizar `onPanEnd` no `InteractionLayer` para gravar a posição final no modo `organizer`.
- [ ] **T2: Edição de Texto Inteligente**
    - [ ] Ajustar `onTapDown` no `InteractionLayer` para priorizar a edição de blocos existentes.
    - [ ] Garantir que o "Hit Test" para texto seja preciso mesmo com rotação.
- [ ] **T3: Refactor de Ergonomia da Toolbar**
    - [ ] Mover o botão "Voltar" (Seta) para a linha superior em `TextEditToolbar`.
    - [ ] Refinar a centralização das ferramentas na linha inferior.
- [ ] **T4: Checklists em Objetos Bloqueados**
    - [ ] Ajustar `_tryToggleChecklist` para ignorar a flag `isLocked`.
