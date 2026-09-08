# Plano de Implementação - Seleção de Estrutura e Ferramenta de Redimensionamento em Tabelas

Este plano visa facilitar a manipulação de linhas e colunas (seleção e eliminação) e integrar a ferramenta de Seleção diretamente na barra de tabelas para redimensionamento rápido.

## User Review Required

> [!IMPORTANT]
> **Ferramenta de Seleção na Tabela**: Adicionaremos um ícone de "Seleção" na `TableEditToolbar`. Ao ativá-lo, as hastes de redimensionamento aparecerão imediatamente, permitindo ajustar o tamanho da tabela sem sair do contexto de edição.
>
> **Gestão de Estrutura**: Adicionaremos botões na categoria "Estrutura" para selecionar a linha ou coluna atual com um único clique, facilitando a aplicação de estilos em massa ou a eliminação das mesmas.

## Mudanças Propostas

### 1. Barra de Ferramentas de Tabela
#### [MODIFY] [table_edit_toolbar.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/toolbars/table_edit_toolbar.dart)
- Adicionar o botão da ferramenta de **Seleção** junto ao botão de concluir.
- Na categoria **Estrutura**, adicionar botões para:
    - "Selecionar Linha" (baseado na célula ativa ou selecionada).
    - "Selecionar Coluna".
- Garantir que a eliminação de linha/coluna utilize as chaves de seleção no novo formato (`id:r,c`).

### 2. Motor de Renderização
#### [MODIFY] [object_renderer.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/object_renderer.dart)
- Corrigir os handles de seleção de linha/coluna (setas) para usarem o formato de chave único `${table.id}:r,c`.
- Ajustar a visibilidade das alças para considerar o novo fluxo de trabalho.

### 3. Lógica de Toolbar Principal
#### [MODIFY] [canvas_toolbar.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/canvas_toolbar.dart)
- Ajustar a condição `isTableDesignMode` para que a `TableEditToolbar` permaneça visível se a ferramenta for "Seleção" mas houver uma tabela selecionada.

## Plano de Verificação

### Testes Manuais
1. **Redimensionamento Rápido**: Clique numa tabela -> Na barra de tabela, clique no ícone de Seleção -> Verifique se as hastes aparecem -> Redimensione -> Volte à ferramenta de Tabela (ou Texto).
2. **Seleção de Linha/Coluna**: Clique numa célula -> Na categoria Estrutura, clique em "Selecionar Linha" -> Verifique se todas as células da linha ficam azuis -> Clique em "Eliminar Linha" -> Verifique se a linha correta foi removida.
3. **Formatos de Chave**: Verifique se o log não apresenta erros de "Bad state" ao manipular a estrutura.
