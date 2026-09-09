# Plano de Implementação - Refinamento Profissional de Tabelas (v10.25)

Este plano foca em transformar a ferramenta de Tabelas numa experiência fluida e poderosa, alinhada com o novo design ultra-fino e categorizado do sistema.

## Mudanças Propostas

### 1. Sistema de Redimensionamento Bidimensional
- **[MODIFY] [table_tool.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/tools/table_tool.dart)**:
    - Expandir `_detectBorderHit` para detectar também as bordas horizontais (linhas).
    - Implementar `_handleRowResize` para ajustar a altura das linhas dinamicamente.
    - Adicionar suporte a `HandleType.tableRowResize` no `onPanUpdate`.

### 2. Interface Contextual Ultra-Fina
- **[MODIFY] [canvas_toolbar.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/canvas_toolbar.dart)**:
    - Refinar `_buildTableContextZone` para ser mais compacta (remover divisores desnecessários).
    - Garantir que as abas (`Estrutura`, `Célula`, `Estilo`, `Ações`) ocupam o mínimo de espaço vertical.
    - Adicionar botões rápidos para **Mesclar** e **Dividir** na aba de `Estrutura` ou `Ações`.

### 3. Melhoria na Renderização e Seleção
- **[MODIFY] [object_renderer.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/object_renderer.dart)**:
    - Melhorar o feedback visual da grelha de seleção.
    - Garantir que o `IgnorePointer` no overlay de seleção de intervalo não bloqueia edições rápidas.
- **[MODIFY] [selection_overlay.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/layers/selection_overlay.dart)**:
    - Adicionar alças visuais específicas para redimensionamento de linhas/colunas quando a ferramenta de Tabela está ativa.

### 4. Gestão de Dados e Performance
- Otimizar o `TableObject.copyWith` para evitar recriações profundas desnecessárias durante o redimensionamento live.

## Verificação
- **Redimensionamento**: Arrastar a borda de uma coluna e de uma linha para verificar se a tabela se ajusta suavemente.
- **Edição Multi-Célula**: Selecionar várias células e aplicar uma cor de fundo simultaneamente.
- **Mesclagem**: Criar uma tabela, selecionar 2x2 células e mesclá-las numa única.
