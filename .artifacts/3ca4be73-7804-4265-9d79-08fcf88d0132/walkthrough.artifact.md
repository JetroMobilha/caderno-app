# Walkthrough: Sincronização Reativa Leve e Segura

Implementámos uma melhoria crítica na forma como o App e o Servidor comunicam alterações autoritativas. O foco foi reduzir a carga no servidor de WebSocket (Reverb) e garantir que a colaboração respeite as permissões dos utilizadores.

## Mudanças Realizadas

### 🚀 Backend: Sinalização Leve (Ping-only)
- **`PageUpdated.php`**: O evento de broadcast agora envia apenas os metadados identificadores (`notebook_id`, `page_number`, `client_id`). O conteúdo pesado (desenhos, imagens) foi removido do payload do WebSocket.
- **`SyncController.php`**:
    - Agora dispara o evento `PageUpdated` sempre que uma página é salva via API REST.
    - Implementada validação de permissões no `pushNotebooks`, impedindo que utilizadores com role `viewer` ou `student` alterem metadados globais do caderno.

### 📱 Frontend: Recepção Inteligente
- **`canvas_controller.dart`**: Atualizámos o listener para reagir à nova sinalização leve.
    - Quando o App recebe um sinal `PageUpdated`, ele identifica a página exata e faz um `pullSpecificPage` via REST.
    - Isso garante que os dados cheguem com integridade total (via HTTP) sem sobrecarregar o túnel de WebSocket.

## Benefícios
1. **Estabilidade:** O servidor Reverb não corre o risco de cair por processar pacotes JSON gigantes (páginas complexas).
2. **Consistência:** Garante que todos os utilizadores online vejam a mesma "verdade" autoritativa do MySQL quase instantaneamente.
3. **Segurança:** Bloqueio de escritas não autorizadas no nível do servidor.

## Como Testar
1. Abra o mesmo caderno em dois dispositivos.
2. Desenhe num dispositivo e aguarde o auto-save (ou force um sync).
3. Observe que o segundo dispositivo receberá uma notificação interna e atualizará a folha automaticamente, sem que o app precise de transmitir o desenho inteiro via WebSocket.

> [!TIP]
> Podes ver os logs no console do Flutter procurando por `🔔 [Sync] Sinal de atualização da Nuvem recebido`.
