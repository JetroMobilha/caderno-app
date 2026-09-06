# Plano: Fase 4.4 - Refinamento de Interatividade e Persistência do Organizador

Resolver a falta de persistência de movimentos no modo Organizador e garantir que a edição de texto seja fluida e sem sobreposição de blocos vazios.

## Mudanças Propostas

### 1. Persistência de Movimento no Organizador (`InteractionLayer`)
- **Problema**: Atualmente, o modo Organizador permite mover objetos visualmente, mas os movimentos não estão a ser confirmados no banco de dados ao soltar o objeto (`onPanEnd`).
- **[MODIFY] [interaction_layer.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/layers/interaction_layer.dart)**:
    - Garantir que o `onPanEnd` deteta o modo `ToolMode.organizer`.
    - Chamar `docNotifier.moveSelection` para persistir a posição final de todos os objetos selecionados no banco de dados e sincronizar com o servidor.

### 2. Edição de Texto Inteligente (`InteractionLayer`)
- **Problema**: O utilizador quer que, ao tocar num texto existente com a ferramenta "T", o editor abra esse texto em vez de criar um novo.
- **[MODIFY] [interaction_layer.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/layers/interaction_layer.dart)**:
    - No `onTapDown`, se a ferramenta for `ToolMode.text`, realizar um hit-test prioritário em `TextBlock`s existentes.
    - Se encontrar um bloco, ativar a edição (`toolNotifier.setTextEditing`).
    - Se não encontrar, criar um novo bloco apenas se o utilizador não estivesse já em modo de edição (evitando blocos vazios em série).

### 3. Melhoria Ergonómica da Toolbar de Texto (`TextEditToolbar`)
- **Seta no Topo**: Reorganizar o layout da `TextEditToolbar` para colocar a seta de "Voltar" na linha das abas de categoria.
- **Centralização**: Ajustar o alinhamento central da linha de ferramentas de formatação para ecrãs de tablets e desktops.

### 4. Checklists em Objetos Bloqueados
- Garantir que o cálculo de toque em checklists ignore o estado `isLocked`, permitindo marcar tarefas sem precisar de "destrancar" o bloco de texto.

## Plano de Tarefas

- [ ] **T1: Persistência Organizador** (Save de movimento ao soltar)
- [ ] **T2: Hit-Test Prioritário de Texto** (Editar existente vs Criar novo)
- [ ] **T3: Refactor Ergonomia Toolbar** (Botão voltar no topo)
- [ ] **T4: Ajuste Final de Checklists** (Acesso mesmo com bloqueio ativo)

---
**Conclusão**: Estas mudanças tornam as ferramentas do caderno ferramentas "vivas" que entendem o contexto e protegem o trabalho do utilizador. Posso avançar?
