# Plano de Implementação - Estabilização de Presença e Testes Automatizados

Este plano visa resolver o problema de visibilidade onde o primeiro utilizador a entrar na sala não deteta a entrada do segundo, além de introduzir testes para garantir a robustez da lógica.

## User Review Required

> [!IMPORTANT]
> Vamos redesenhar o ciclo de vida do canal de presença no `RealtimeService`. A falha observada indica que o ouvinte de "Membro Adicionado" (`whenMemberAdded`) está a ser perdido ou não é registado corretamente devido a subscrições anteriores não finalizadas.

## Proposed Changes

### Fase 1: Estabilização da Presença (AGORA)

#### [MODIFY] [realtime_service.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/realtime_service.dart)
- **Unsubscribe Preventivo**: Garantir que qualquer subscrição anterior ao canal é cancelada e o canal antigo é destruído antes de iniciar uma nova ligação.
- **Deteção de Membros Robusta**: Adicionar logs para o evento bruto `pusher:member_added` e garantir que o processamento do mapa `_estudantesNaSala` é imutável para evitar erros de concorrência.
- **Exposição de Estado**: Criar um método `getConnectedUsers()` para permitir que o controlador peça a lista atual a qualquer momento.

#### [MODIFY] [canvas_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/controllers/canvas_controller.dart)
- **Gatilho de Entrada**: Ao entrar na sala, disparar um pedido explícito de atualização da lista de utilizadores.

#### [NEW] [presence_logic_test.dart](file:///C:/Users/HP/StudioProjects/caderno-app/test/core/network/presence_logic_test.dart)
- Testar a lógica de adição e remoção de membros no mapa interno do serviço.

### Fase 2: Testes WebRTC
- Implementar o teste de sinalização WebRTC anteriormente proposto para validar o handshake.

## Verification Plan

### Automated Tests
- `flutter test test/core/network/presence_logic_test.dart`

### Manual Verification
1. Entrar com o Utilizador 1.
2. Entrar com o Utilizador 2.
3. Verificar no Utilizador 1 se aparece o log: `🟢 [Realtime] EVENTO MEMBER_ADDED RECEBIDO: 2`.
4. Confirmar se o avatar aparece na barra superior.
