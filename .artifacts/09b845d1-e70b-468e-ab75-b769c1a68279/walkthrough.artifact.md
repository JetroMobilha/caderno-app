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

### 5. Zoom Independente e Estabilidade Visual
*   **Isolamento por Página**: Cada folha possui agora o seu próprio motor de zoom independente na memória RAM. Isto permite ter zooms diferentes em cada página (ex: Pág 1 a 50%, Pág 2 a 200%) sem qualquer interferência ou resets ao navegar.
*   **Zero Flicker (Sem Piscadelas)**: Otimizámos a renderização para que os desenhos nunca desapareçam durante o zoom. Ao remover dependências de tempo da chave visual da página, garantimos que o conteúdo permaneça sólido e visível 100% do tempo.
*   **Zoom de Precisão**: Os botões `+` e `-` agora operam com saltos suaves de 10%, mantendo sempre o ponto central do que você está a ver fixo no ecrã.

### 6. Indicador de Zoom Direto e Amplitude Aumentada
*   **Escuta Direta**: O indicador de percentagem (%) agora lê os dados diretamente do motor de zoom da página ativa. Isto elimina qualquer erro de "informação falsa" ao trocar de página ou ao fazer zoom rápido.
*   **Afastamento Livre (Zoom Out)**: Aumentámos a amplitude de zoom para permitir afastar a folha até **5%** do seu tamanho original. Isto resolve o problema do indicador ficar preso nos 22% (A2) ou 63% (A4), permitindo uma visão panorâmica completa do seu trabalho.
*   **Reset Inteligente**: Ao tocar na percentagem na barra de ferramentas, a folha volta instantaneamente ao centro e ao tamanho ideal de leitura, facilitando a navegação rápida em documentos grandes (A2/A1).

### 7. Estabilidade de Dados e Persistência
*   **Sincronização Invisível**: As confirmações de salvamento do servidor agora ocorrem em segundo plano sem invalidar a memória local. Isto garante que a sua escrita nunca seja interrompida por recarregamentos forçados.
*   **Isolamento de Erros**: Implementámos guardas de segurança que evitam erros fatais ao alternar rapidamente entre páginas ou cadernos em sincronização ativa.

> [!TIP]
> O "Modo Infinito" pode ser ativado definindo `isInfinite: true` no modelo da página, o que expande o canvas para uma área de 5000x5000 pixels por padrão.

> [!IMPORTANT]
> A migração de dados é automática: ao abrir uma página antiga, o sistema converte as listas `stroke_data`, `text_data` e `image_data` para a nova estrutura `objects_data`.

## Evolução Fase 2: Objetos Avançados e Camadas

### 1. Formas Geométricas Atómicas (`ShapeObject`)
- Adicionado suporte para **Retângulos, Círculos, Linhas, Setas e Triângulos** perfeitos.
- Estes objetos são independentes dos traços manuais, permitindo redimensionamento e alteração de cores de preenchimento/borda futuramente.

### 2. Integração de Áudio e Animações no Canvas
- **Áudio Blocks**: Agora é possível posicionar ícones de áudio interativos na página. Ao clicar, o sistema reproduz a gravação associada àquele ponto da nota.
- **Animações e Ilustrações**: Criámos o `AnimationObject`, que permite integrar animações interativas (ex: engrenagens de engenharia, funções matemáticas dinâmicas) diretamente na superfície de trabalho.

### 3. Gestão de Camadas (Layers)
- A página agora suporta uma hierarquia de camadas: **Geral, Fundo, Desenhos e Texto**.
- **Controlo de Visibilidade**: Implementámos a lógica para ocultar camadas inteiras (ex: ocultar todos os desenhos para ler apenas o texto).
- **Isolamento**: Novos traços são automaticamente atribuídos à camada "Desenhos" e textos à camada "Texto".
