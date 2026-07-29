# Plano de Implementação - Estabilização WebRTC e Depuração Visual

Este plano visa resolver a falha de áudio persistente (ICE Failed) através da introdução de uma camada de vídeo de depuração que servirá como "Ping Visual" para confirmar a conectividade P2P.

## User Review Required

> [!IMPORTANT]
> A ativação do vídeo exigirá permissões de câmara em ambos os dispositivos. O objetivo não é uma funcionalidade final de vídeo, mas sim isolar se o problema é de **Rede (ICE)** ou de **Hardware/Codec de Áudio**.

## Proposed Changes

### Fase 3: Depuração Visual (Ping Visual)

#### [MODIFY] [webrtc_service.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/webrtc_service.dart)
- **Ativar Vídeo Local**: Alterar `getUserMedia` para capturar vídeo.
- **Gestão de Renderizadores**: Introduzir `RTCVideoRenderer` para o vídeo local e um para cada peer remoto.
- **Unified Plan Video**: Mudar transceivers de vídeo para `SendRecv`.
- **Exposição de Streams**: Criar streams para que a UI saiba quando um novo vídeo está disponível.

#### [NEW] [webrtc_debug_overlay.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/webrtc_debug_overlay.dart)
- Widget flutuante que mostra miniaturas dos vídeos e o estado detalhado da ligação (IPs, RTT, Codecs).

#### [MODIFY] [canvas_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/views/canvas_screen.dart)
- Integrar o overlay de depuração no topo da pilha do Canvas.

## Verification Plan

### Manual Verification
1. Entrar na sala de voz.
2. Confirmar se a minha câmara liga (Self-view).
3. Verificar se o vídeo do colega aparece ao conectar.
4. **Diagnóstico**:
   - Se houver vídeo mas não áudio -> Problema de Configuração de Áudio/Codecs.
   - Se não houver vídeo e o estado for `Failed` -> Problema de Rede (Necessário TURN).
