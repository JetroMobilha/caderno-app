# Walkthrough: Integração de Convite de Voz no Modal

Nesta iteração, resolvemos o conflito de interface onde o modal do **Centro de Colaboração** impedia o acesso ao banner de convite de voz.

## Alterações Realizadas

### 🛰️ Centro de Colaboração (`collaboration_center_sheet.dart`)
*   **Integração de Convite**: Adicionámos um alerta interno que aparece automaticamente no topo do modal se houver uma chamada a decorrer.
*   **Controlo Direto**: O utilizador agora pode **Aceitar** ou **Recusar** a conversa de voz sem precisar de fechar o modal.
*   **Estilo Contextual**: O alerta usa um fundo verde suave e ícones de voz para se destacar das outras definições, garantindo que o convite não passe despercebido.

### 🧠 Lógica de Fluxo (`CanvasController`)
*   Garantimos que a aceitação da chamada a partir do modal dispara as mesmas garantias de microfone e sinalização WebRTC que o banner global.

## Como Verificar

1.  Abra o **Centro de Colaboração** (ícone de rede na barra superior).
2.  Peça a um colega para iniciar uma chamada de voz.
3.  Veja o alerta verde aparecer **dentro** do modal aberto.
4.  Clique em **Aceitar** para entrar na conversa imediatamente.

> [!TIP]
> Esta alteração é especialmente útil para utilizadores que estão a configurar as suas permissões online e recebem um convite no mesmo instante, eliminando a fricção de "fechar para aceitar".
