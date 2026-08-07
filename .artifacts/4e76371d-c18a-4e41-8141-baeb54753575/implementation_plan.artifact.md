# Reconciliação Colaborativa: Sincronização Coletiva em Tempo Real

Implementar um mecanismo de "aperto de mão" (handshake) para sessões colaborativas, onde todos os participantes com permissão de escrita contribuem com os seus dados locais para o servidor, garantindo uma "fusão" total e imediata do estado do caderno.

## Revisão do Usuário Necessária

> [!IMPORTANT]
> Esta lógica fará com que, ao iniciar uma colaboração ou detectar uma divergência, todos os editores online enviem as suas páginas pendentes simultaneamente. O servidor Laravel (via `mergeJsonItems`) tratará de unir todos os UUIDs únicos num só estado.

## Alterações Propostas

### 1. App (Flutter/Dart)

#### [MODIFY] [sync_service.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/sync_service.dart)
- **`pushPages`**: Adicionar um parâmetro opcional `notebookId` para permitir sincronizar apenas o caderno atual, tornando o processo muito mais rápido durante sessões live.
- **`pullPages`**: Garantir que a lógica de "Adoção de Folha Vazia" seja aplicada consistentemente.

#### [MODIFY] [canvas_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/controllers/canvas_controller.dart)
- **`_performCollectiveSync`**:
    1. Notificar os outros utilizadores que um Sync Coletivo começou.
    2. Se o utilizador local for um contribuidor (`owner` ou `editor`), disparar `pushPages(currentNotebookId)`.
    3. Aguardar um breve intervalo (ex: 1.5s) para o servidor processar todas as entradas.
    4. Todos os utilizadores (incluindo `viewers`) disparam `pullPages()` para receber a "verdade fundida".
- **Trigger**: Disparar automaticamente este handshake quando um novo membro entra na sala ou quando o dono detecta uma falha de "fingerprint".

### 2. Servidor (Laravel/PHP)

#### [MODIFY] [Page.php](file:///C:/xampp/htdocs/caderno-backend/app/Models/Page.php)
- **`mergeJsonItems`**: Verificar se a lógica atual preserva todos os itens com IDs diferentes (deve ser puramente aditiva para novos UUIDs).

## Plano de Verificação

### Teste de Colaboração em Grupo
1. **Três Dispositivos**: Usuário A, B e C entram no mesmo caderno.
2. **Modo Offline**: A desenha um círculo, B escreve um texto, C insere uma imagem (todos em modo avião).
3. **Reconexão**: Todos voltam online e um deles clica em "Sincronizar".
4. **Resultado**: O servidor deve fundir os 3 objetos na mesma folha e todos os dispositivos devem exibir o círculo, o texto e a imagem simultaneamente.
