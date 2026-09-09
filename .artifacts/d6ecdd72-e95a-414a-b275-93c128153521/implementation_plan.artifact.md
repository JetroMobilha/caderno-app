# Plano de Implementação - Sistema de Grupos e Hierarquia (v10.1)

Este plano descreve a implementação da funcionalidade de agrupamento de objetos, permitindo manipular múltiplos elementos como uma única entidade.

## Mudanças Propostas

### 1. Persistência de Metadados (Database)
- **Modificar [app_database.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/database/app_database.dart)**:
    - Adicionar colunas `parentId` (TEXT), `isVisible` (INT), `isLocked` (INT), `opacity` (REAL) às tabelas:
        - `CanvasStrokes`, `CanvasTextBlocks`, `CanvasImageBlocks`, `CanvasShapes`, `CanvasAudioBlocks`, `CanvasAnimations`, `CanvasTables`, `CanvasLinks`, `CanvasAttachments`.
    - Incrementar a versão do esquema para `31`.

### 2. Repositório de Dados (Data Layer)
- **Modificar [canvas_repository.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/repositories/canvas_repository.dart)**:
    - Atualizar os métodos de leitura (`getPageByClientId`, `loadPageContent`) para extrair os novos campos das linhas do banco.
    - Atualizar os métodos de gravação (`saveSingleStroke`, `saveSingleTextBlock`, etc.) para persistir os metadados de grupo, visibilidade e bloqueio.

### 3. Lógica de Agrupamento (Interaction Provider)
- **Modificar [canvas_tool_provider.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/providers/canvas_tool_provider.dart)**:
    - Implementar `groupSelectedObjects()`: gera um novo UUID e atribui como `parentId` de todos os objetos selecionados.
    - Implementar `ungroupSelectedObjects()`: remove o `parentId` dos objetos selecionados que pertençam a um grupo.
    - **Seleção Inteligente**: Atualizar `selectAt` para que, ao tocar num objeto com `parentId`, todos os "irmãos" (objetos com o mesmo parent) sejam selecionados automaticamente.

### 4. Interface (UI)
- **Modificar [canvas_toolbar.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/canvas_toolbar.dart)**:
    - Adicionar botão "Agrupar" (Icons.group_work) na **Zona Contextual** quando > 1 objeto estiver selecionado.
    - Adicionar botão "Desagrupar" quando o objeto selecionado tiver um `parentId`.
- **Modificar [layer_manager_sheet.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/dialogs/layer_manager_sheet.dart)**:
    - Visualizar grupos na lista (opcional nesta fase, ou apenas indicar o ID do grupo no subtítulo).

## Plano de Verificação

### Testes de Funcionalidade
1. **Agrupar**: Selecionar um desenho e um texto, clicar em "Agrupar". Tentar mover um deles; ambos devem mover-se juntos.
2. **Persistência**: Agrupar objetos, fechar o caderno e reabrir. O vínculo de grupo deve ser mantido.
3. **Desagrupar**: Selecionar um grupo, clicar em "Desagrupar". Verificar se os objetos voltam a ser independentes.
4. **Cadeado de Grupo**: Bloquear um dos membros do grupo. O grupo inteiro deve ficar protegido ou apenas o membro? (Padrão: O bloqueio de um membro impede a transformação do grupo).

---

**Podemos avançar com a atualização da base de dados e lógica de grupos?**
