# Walkthrough: Reconciliação Colaborativa (Handshake Coletivo)

Nesta tarefa, implementamos um mecanismo de "aperto de mão" (handshake) para garantir que todos os participantes de uma sessão colaborativa fundam os seus dados locais pendentes numa única verdade no servidor, eliminando lacunas de sincronização.

## Alterações Realizadas

### 1. Filtro de Sincronização por Caderno
- [sync_service.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/sync_service.dart): Atualizamos o método `pushPages` para aceitar um parâmetro opcional `onlyNotebookId`. Isto permite que o App envie apenas as páginas do caderno aberto, tornando a sincronização em tempo real muito mais rápida e eficiente.

### 2. Ciclo de Handshake Colaborativo
- [canvas_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/controllers/canvas_controller.dart): Refatoramos o método `_performCollectiveSync` para seguir um protocolo de 3 passos:
    1. **Contribuição**: Todos os utilizadores com permissão de escrita (`owner` ou `editor`) enviam imediatamente os seus dados locais para o servidor.
    2. **Consolidação**: O App aguarda 1.5 segundos enquanto o servidor Laravel utiliza a lógica `mergeJsonItems` para unir todos os UUIDs únicos num só estado de página.
    3. **Distribuição**: Todos os utilizadores (incluindo visualizadores) fazem um `pullPages` para receber o estado final fundido.

## Benefícios da Fusão Coletiva
- **Estado Global Unificado**: Garante que se três pessoas desenharem objetos diferentes enquanto estiverem offline ou com falhas de sinal, mal o Sync Coletivo seja disparado, todos vejam a união de todos os desenhos.
- **Resiliência a Falhas de Rede**: Se um evento de tempo real (Pusher) falhar, o Handshake serve como rede de segurança para recuperar os dados perdidos.
- **Sincronização Inteligente**: O uso de filtros por caderno reduz o tráfego de dados e acelera a resposta da UI.

> [!TIP]
> Este mecanismo é disparado automaticamente quando um novo membro entra na sala ou quando o proprietário deteta uma divergência de "fingerprint".
