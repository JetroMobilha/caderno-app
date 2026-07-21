# Plano de Implementação: Otimização de Colaboração e Voz (WebRTC)

Este plano visa resolver as falhas na borracha compartilhada, sincronização de imagens, indicadores de upload global e a ausência de áudio nas chamadas de voz.

## Problemas Identificados
1.  **Borracha Restrita:** Usuários não conseguem apagar traços de colegas e as remoções locais não sincronizam.
2.  **Imagens "Quebradas":** Redimensionar uma imagem antes do upload terminar envia um path local para os colegas, resultando num quadrado vazio.
3.  **Falta de Feedback:** Os colegas não sabem quando alguém está a carregar uma imagem pesada.
4.  **WebRTC Silencioso:** As conexões Peer-to-Peer são estabelecidas, mas os fluxos de áudio remotos não estão a ser "ouvidos" (falta o `onTrack`).

## Mudanças Propostas

### 1. Borracha Universal e Broadcast Consistente
*   **[RealtimeService](file:///C:/Users/Jetro.Domingos/StudioProjects/caderno_digital_app/lib/core/network/realtime_service.dart):** Garantir que todos os métodos de broadcast incluem o `sender_id` para evitar auto-echo e permitir validação no receptor.
*   **[CanvasController](file:///C:/Users/Jetro.Domingos/StudioProjects/caderno_digital_app/lib/features/canvas/controllers/canvas_controller.dart):** Garantir que o `eraseAtPosition` envia o `myUserId`. Remover qualquer barreira lógica que impeça a remoção de elementos de terceiros (desde que o usuário seja editor).

### 2. Sincronização Inteligente de Imagens
*   **Filtro de Path:** Alterar `broadcastImageBlockUpdate` para apenas disparar o evento se a imagem já possuir um URL remoto (`http://...`). Se for um path local, o broadcast aguarda o fim do upload.
*   **Indicador de Upload:**
    *   Criar evento `client-image-uploading` no Reverb.
    *   No `CanvasController`, adicionar uma lista `remoteUploadingUsers`.
    *   **[CanvasScreen](file:///C:/Users/Jetro.Domingos/StudioProjects/caderno_digital_app/lib/features/canvas/views/canvas_screen.dart):** Exibir um pequeno aviso (Toast ou Badge) quando um colega estiver a carregar ficheiros.

### 3. Ativação de Áudio WebRTC
*   **[WebRTCService](file:///C:/Users/Jetro.Domingos/StudioProjects/caderno_digital_app/lib/core/network/webrtc_service.dart):**
    *   Implementar o listener `pc.onTrack`.
    *   Capturar o `MediaStream` remoto e garantir que a track de áudio é ativada.
    *   Configurar a categoria de áudio para `playAndRecord` no Android/iOS (via `flutter_webrtc` helper) para garantir saída pelo altifalante.

## Plano de Verificação

### Manual Verification
*   **Borracha:** Apagar um traço feito por outro telemóvel e confirmar que desaparece em ambos.
*   **Imagem:** Inserir imagem, redimensionar imediatamente e confirmar que o colega só vê a imagem quando o upload termina (evitando o quadrado vazio).
*   **Voz:** Iniciar chamada entre dois dispositivos e confirmar que o som sai pelos altifalantes.
