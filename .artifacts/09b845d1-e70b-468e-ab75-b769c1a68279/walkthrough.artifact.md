# Walkthrough - Evolução da Estrutura de Página

A arquitetura da página foi evoluída de um modelo baseado em listas rígidas para um **Canvas Dinâmico baseado em Objetos**, permitindo uma manipulação muito mais flexível e preparando o terreno para camadas (layers), modo infinito e exportação precisa.

## Principais Mudanças

### 1. Unificação de Objetos (`PageObject`)
Todos os elementos da página (Traços, Textos, Imagens) agora implementam a interface `PageObject`. Isso permite:
- Gestão unificada de **Z-Index** (ordem de empilhamento).
- Propriedades comuns: `position`, `size`, `rotation`, `isVisible`, `isLocked`.
- Manipulação universal por ferramentas de seleção.

### 2. Novo Engine de Renderização (`PageCanvas`)
Substituímos o sistema de camadas fixas por um `PageCanvas` que:
- Renderiza objetos na ordem correta de `zIndex`.
- Agrupa `Strokes` consecutivos para manter a **alta performance** de desenho solicitada.
- Suporta dimensões físicas reais (**A5 a A0**) e orientação (Retrato/Paisagem).

### 3. Fundo Dinâmico e Configurável
O `BackgroundConfig` foi expandido para suportar:
- Cor de fundo e das linhas.
- Espessura das linhas (`lineWidth`) e espaçamento configurável.
- Opacidade dinâmica.

### 4. Ferramenta de Seleção Universal
Implementamos o `SelectionOverlay`, que desenha alças de seleção e caixas de delimitação sobre qualquer tipo de objeto selecionado, centralizando a experiência de edição.

## Restrições de Layout e Segurança de Dados

### 1. Hierarquia de Tamanhos (Nível Superior)
Introduzimos o conceito de "Nível de Papel" em `GeometryUtils`. O sistema agora identifica o maior tamanho de página presente no caderno e impede que novas páginas ou alterações de layout reduzam para tamanhos inferiores.
- Exemplo: Se o caderno tem uma folha A3, o utilizador não poderá criar ou mudar folhas para A4 ou A5. O modo "Infinito" é considerado o nível máximo (0).

### 2. Confirmação de Orientação
Para evitar perda acidental de visibilidade de conteúdo, ao tentar mudar a orientação (Retrato <-> Paisagem) de uma folha que já contenha desenhos, textos ou imagens (`page.hasData`), um diálogo de confirmação é exibido alertando para os riscos.

### 3. Criação com Fundo Rico
O diálogo `AddPageDialog` foi modernizado:
- Removidos os ícones de pauta fixos.
- Integrado o `BackgroundSelectorSheet`, permitindo escolher entre todas as categorias do catálogo rico (Isométrico, Milimetrado, Cornell, etc.) logo na criação da folha.

### 4. Melhorias Visuais na Gaveta e Diálogos
*   **Proporções Reais**: As miniaturas das páginas (`_PageThumbnail`) agora refletem a orientação real (Vertical/Horizontal) e possuem um design especial para o Modo Infinito (formato quadrado com ícone `∞`).
*   **Subtítulos Detalhados**: A lista de páginas agora exibe informações completas de layout, por exemplo: "A4 Vertical • Pautado".
*   **Seletor de Fundo Evidenciado**: No diálogo de nova folha, o fundo selecionado agora é mostrado com uma pré-visualização real do papel e estilo, em vez de apenas um ícone genérico, facilitando a decisão do utilizador.

> [!TIP]
> O "Modo Infinito" pode ser ativado definindo `isInfinite: true` no modelo da página, o que expande o canvas para uma área de 5000x5000 pixels por padrão.

> [!IMPORTANT]
> A migração de dados é automática: ao abrir uma página antiga, o sistema converte as listas `stroke_data`, `text_data` e `image_data` para a nova estrutura `objects_data`.
