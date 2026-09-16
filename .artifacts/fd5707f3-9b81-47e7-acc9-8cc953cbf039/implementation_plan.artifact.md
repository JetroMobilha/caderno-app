# Arena de Palmas v2: Duelo Visual de Latência Zero

Este plano implementa uma estratégia de "Múltiplos Vencedores Provisórios" onde todos os toques desenham instantaneamente, mas apenas o toque com intenção real sobrevive após uma breve avaliação.

## User Review Required

> [!IMPORTANT]
> Esta funcionalidade exige que o motor de renderização `live` suporte múltiplos traços simultâneos. Isso aumentará ligeiramente o uso de CPU durante os primeiros 150ms de um toque duplo, mas garantirá a melhor fluidez possível.

## Proposta de Mudança

### 1. Motor de Desenho Multi-ID (`LiveStrokeNotifier`)

#### [MODIFY] [live_stroke_provider.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/providers/live_stroke_provider.dart)
*   Alterar de um único traço para um `Map<int, List<Offset>> _activeStrokes`.
*   Permitir que vários ponteiros adicionem pontos em paralelo.
*   Adicionar método `removeStroke(int pointerId)` para fazer as linhas "duvidosas" sumirem.

### 2. Camada de Interação Inteligente (`InteractionLayer`)

#### [MODIFY] [interaction_layer.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/layers/interaction_layer.dart)
*   **Início Instantâneo:** Ao detetar `PointerDown` (até 2 dedos), inicia-se um traço `live` para cada um imediatamente.
*   **Janela de Julgamento:**
    *   Manter um timer e buffer de pontos para cada ID.
    *   Critério de Vitória: O ponteiro que percorrer **15px** com movimento fluido primeiro, ou o que tiver a maior **velocidade média** após **150ms**.
*   **Execução da Sentença:**
    *   O perdedor é removido do `LiveStrokeNotifier` (a linha some do ecrã).
    *   O vencedor é promovido a `_activeDrawingPointerId` e o seu traço é mantido.
    *   O Stylus continua a ter "Vitória Instantânea" sobre qualquer dedo.

### 3. Renderização Isolada (`InteractionLayer` Consumer)

#### [MODIFY] [interaction_layer.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/layers/interaction_layer.dart)
*   Atualizar o `ActiveStrokePainter` para desenhar todos os traços contidos no mapa do `LiveStrokeNotifier`.

## Plano de Verificação

### Testes Manuais
1.  **Toque Duplo (Palma + Dedo):** Apoie a palma e desenhe com o dedo ao mesmo tempo. Verá dois traços a começar; após uma fração de segundo, o traço da palma deve sumir e apenas o do dedo continuar.
2.  **Escrita Veloz:** Escreva palavras rápidas. A latência deve ser zero, como se não houvesse filtro.
3.  **Prioridade Stylus:** Comece a desenhar com o dedo, depois encoste a caneta. O traço do dedo deve sumir (ou parar) e a caneta deve assumir o controlo total.
