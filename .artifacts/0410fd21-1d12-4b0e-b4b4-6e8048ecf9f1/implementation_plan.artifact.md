# Sincronização Imersiva: Fim das Linhas Fantasmas e Imagens Fluidas

O objetivo é eliminar artefatos visuais durante o desenho em tempo real e tornar a movimentação de imagens suave para todos os colaboradores.

## User Review Required

> [!IMPORTANT]
> **Correção de Desenho:** Descobri que as linhas retas no final do desenho ocorriam porque apenas o último "pedaço" do traço era enviado no sinal final. Vou alterar para que o traço completo seja enviado no momento em que levanta o dedo, garantindo que o desenho fique idêntico em todos os ecrãs.

> [!TIP]
> A movimentação de imagens passará a usar animações leves (interpolação) para que, quando um colega move um objeto, você o veja deslizar suavemente em vez de saltar.

## Proposed Changes

### [Component] Desenho (Canvas Ink)

#### [MODIFY] [canvas_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/views/canvas_screen.dart)
- **Broadcast Final:** Alterar `sendStrokeUpdate` no `onPanEnd` para enviar a lista **completa** de pontos (`allPoints`) em vez de apenas o último segmento. Isto garante que o dispositivo receptor tenha a versão final correta sem falhas de conexão entre pontos.

---

### [Component] Imagens (Image Blocks)

#### [MODIFY] [canvas_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/controllers/canvas_controller.dart)
- **Frequência de Atualização:** Reduzir o throttling de 50ms para 30ms para aproximar-se dos 30 FPS de atualização.
- **Otimização de Performance:** Implementar um `Timer` para adiar a gravação no SQLite de movimentos remotos, evitando travagens (jank) durante a colaboração ativa.

#### [MODIFY] [canvas_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/views/canvas_screen.dart)
- **Movimento Fluido:** Trocar `Positioned` por `AnimatedPositioned` na renderização das imagens.
- **Duração da Interpolação:** Configurar a animação para ~40ms para "preencher os vazios" entre os pacotes de dados recebidos, criando a ilusão de movimento contínuo.

## Verification Plan

### Manual Verification
1.  **Linhas Fantasmas:** Desenhar círculos e formas complexas rapidamente e verificar se o traço final fecha corretamente sem linhas retas atravessadas no dispositivo do colega.
2.  **Imagens:** Arrastar uma imagem num telemóvel e observar no outro telemóvel se o movimento é fluído (cinematográfico) ou se continua "aos saltos".
3.  **Estabilidade:** Confirmar que múltiplas movimentações simultâneas não causam lentidão na aplicação.
