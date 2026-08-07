# Análise e Reforço da Sincronização Colaborativa Reativa

Esta análise cobre a integridade da sincronização entre o Flutter e o Servidor (Laravel), garantindo que múltiplos utilizadores possam trabalhar no mesmo caderno de forma reativa e segura.

## Análise de Situação Atual

O sistema utiliza uma **Estratégia Híbrida**:
1.  **Real-time (Pusher/Reverb):** Envio de traços e textos individuais para feedback imediato (<100ms).
2.  **Cloud Sync (REST):** Persistência autoritativa no MySQL com fusão de itens (merge) para garantir que ninguém perde trabalho após reconexão.
3.  **Resolução de Conflitos:** Baseada em *Last-Write-Wins (LWW)* com precisão de milissegundos.

### Pontos Fortes Detetados
-   **Fusão Inteligente:** O servidor não substitui a página inteira; ele funde os traços (`strokes`) individualmente baseando-se em UUIDs.
-   **Permissões no Item:** O `Page.php` já impede que um `student` apague conteúdo de um `owner`.
-   **Detecção de Divergência:** O Flutter utiliza *Fingerprints* para detetar se a folha local é diferente da remota e disparar uma reconciliação automática.

### Gaps Identificados (A Corrigir)
-   **Falta de Gatilho Reativo no Servidor:** O `SyncController@pushPages` não dispara um evento para avisar os outros utilizadores que uma nova versão autoritativa está disponível.
-   **Mismatch de Nomes de Eventos:** O Laravel usa `page.updated` enquanto o Flutter espera `PageUpdated`.
-   **Segurança nos Cadernos:** O `pushNotebooks` permite atualizações sem validar se o utilizador tem permissão de escrita no caderno.

## Mudanças Propostas

### Backend (Laravel)

#### [MODIFY] [SyncController.php](file:///C:/xampp/htdocs/caderno-backend/app/Http/Controllers/Api/SyncController.php)
-   Adicionar verificação de Role em `pushNotebooks`.
-   Disparar `PageUpdated::dispatch($localPage)` ao final de cada página processada em `pushPages`.

#### [MODIFY] [PageUpdated.php](file:///C:/xampp/htdocs/caderno-backend/app/Events/PageUpdated.php)
-   Alterar `broadcastAs` para `PageUpdated`.
-   **Otimização de Payload:** Enviar apenas `notebook_id`, `page_number` e `client_id` (sinalização), sem o conteúdo pesado da página (`stroke_data`, etc).

### Frontend (Flutter)

#### [MODIFY] [realtime_service.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/realtime_service.dart)
-   Validar se o `bind` de `PageUpdated` está a capturar o evento corretamente após a mudança no backend.

#### [MODIFY] [canvas_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/controllers/canvas_controller.dart)
-   Garantir que o `_performCollectiveSync` lida bem com as atualizações vindas do servidor para evitar loops infinitos.

## Plano de Verificação

### Testes Manuais
1.  **Sincronização Reativa:** Abrir o mesmo caderno em dois dispositivos. Desenhar num. Verificar se o outro recebe o traço imediatamente.
2.  **Persistência e Conflito:** Desenhar em ambos offline. Sincronizar um, depois o outro. Verificar se o servidor fundiu os traços de ambos sem apagar nada.
3.  **Permissões:** Tentar editar um caderno como `viewer` e verificar se o servidor/app bloqueia.
4.  **Adição de Páginas:** Adicionar uma página num dispositivo e verificar se ela aparece "magicamente" no outro sem recarregar.

> [!IMPORTANT]
> A atualização reativa é feita via sinalização. O servidor envia um evento leve (`PageUpdated`) contendo apenas o ID. O App, ao receber este sinal, decide se faz um `pullSpecificPage` ou um `pullPages` geral, evitando o envio de grandes volumes de dados via WebSocket (Reverb).
