# Walkthrough - Prioridade de Navegação Multi-Toque (v7.4)

Implementei um sistema de detecção de dedos que garante que gestos de zoom e pan (deslocamento) tenham prioridade total sobre o desenho ou seleção sempre que mais do que um dedo estiver no ecrã.

## Mudanças Realizadas

### 1. Rastreamento de Dedos em Tempo Real (v7.4)
- **CanvasScreen**: Adicionei um `Listener` em torno da página do canvas. Este componente conta exatamente quantos dedos estão a tocar no ecrã em cada instante.
- **Estado Global**: O número de toques ativos é enviado para o `canvasViewportProvider`, permitindo que todas as camadas do aplicativo saibam se o utilizador está a tentar navegar ou a desenhar.

### 2. Bloqueio Dinâmico de Desenho
- **InteractionLayer**: Atualizei a lógica de "IgnorePointer".
- **Comportamento**: Se o sistema detetar 2 ou mais dedos, a camada de desenho torna-se "transparente". Isto permite que o gesto de "pinça" (zoom) ou arraste com dois dedos passe diretamente para o motor do `InteractiveViewer` sem criar traços de tinta ou blocos de texto acidentais.

### 3. Fluidez no Android
- Esta alteração resolve um problema comum em dispositivos touch onde, ao tentar fazer zoom, o utilizador acabava por desenhar uma linha pequena por engano. Agora, o sistema "tranca" o desenho mal o segundo dedo toca no vidro.

## Como Verificar
1. **Zoom**: Toque na folha com dois dedos e faça o movimento de abrir/fechar. Verifique se o zoom é suave e se **nenhum** traço é desenhado durante o processo.
2. **Pan**: Arraste a folha usando dois dedos. O canvas deve mover-se livremente sem ativar a ferramenta de seleção ou caneta.
3. **Desenho**: Use apenas um dedo. A caneta, o texto e as tabelas devem funcionar exatamente como antes.
