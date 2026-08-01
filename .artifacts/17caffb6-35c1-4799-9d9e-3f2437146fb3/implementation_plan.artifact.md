# Plano de Implementação - Sincronização Híbrida e Persistência Garantida 🛡️☁️

Este plano visa garantir que todos os dados colaborativos sejam preservados, mesmo que utilizadores entrem e saiam da sala em momentos diferentes. A estratégia baseia-se num modelo de **"Nuvem como Fonte da Verdade"** e **"Dispositivo como Cache Persistente"**.

## Estratégia de Sincronização

1.  **Tempo Real (WebSocket)**: Feedback imediato entre quem está na sala. Os dados recebidos via WebSocket são salvos no SQLite local de quem os recebe.
2.  **Persistência na Nuvem (Authoritative Push)**: Quem desenha envia a versão final para o MySQL (via Laravel). O servidor funde (`mergeJsonItems`) os novos dados com os existentes.
3.  **Recuperação (Pull no Entrada)**: Ao entrar numa sala, a App faz um `pullPages` para descarregar tudo o que foi feito enquanto o utilizador estava fora.

## Proposed Changes

### 1. Controller: CanvasController

#### [MODIFY] [canvas_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/controllers/canvas_controller.dart)
- **Garantia de Entrada**: Certificar que o `SyncService().pullPages()` é chamado com prioridade máxima ao abrir um caderno colaborativo.
- **Push de Saída**: Implementar um `savePageToCloud` forçado no `dispose()` ou ao desativar a colaboração para garantir que a última alteração subiu.
- **Tratamento de Conflitos**: Melhorar a lógica de receção de dados do servidor para não duplicar elementos que já foram recebidos via WebSocket.

### 2. Service: SyncService

#### [MODIFY] [sync_service.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/sync_service.dart)
- **Otimização de PULL**: Garantir que o `pullPages` limpa o cache local de elementos deletados no servidor (se aplicável).
- **Consistência de IDs**: Garantir que o mapeamento entre IDs locais e globais (`serverId`) é mantido rigorosamente durante a fusão de dados.

## Resposta à Pergunta do Utilizador

> *"Como garantir que alguém mesmo saindo vai ter os dados que outros colaboraram sem a presença dele?"*

**A solução é a Nuvem Central:**
- Quando o **Utilizador A** desenha, o Laravel guarda isso permanentemente no MySQL.
- O **Utilizador B** não precisa de estar online nesse momento.
- Mal o **Utilizador B** abra o caderno, a função `pullPages` deteta que há dados novos no servidor e descarrega-os para o seu SQLite local.
- **Resultado:** Todos acabam com uma cópia idêntica e completa do caderno no seu bolso, independentemente de quando estiveram online.

## Verification Plan

### Manual Verification
1. **Teste de Ausência**:
   - Utilizador A e B estão na sala.
   - Utilizador B sai da App (mata o processo).
   - Utilizador A desenha 3 círculos e escreve um título.
   - Utilizador A espera pelo log `✅ [Authoritative Push] sincronizada!`.
   - Utilizador B volta a abrir o caderno.
   - **Verificar**: Se os 3 círculos e o título aparecem para B automaticamente.
2. **Teste de Saída Bruta**:
   - Utilizador A desenha e desliga a internet imediatamente.
   - Volta a ligar.
   - **Verificar**: Se o `SyncProvider` deteta os dados não sincronizados e os envia para a nuvem.
