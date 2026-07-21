# Plano de Implementação: Robustez da Colaboração em Tempo Real e Testes

Este plano foca em melhorar a estabilidade da colaboração em tempo real (WebSockets/Reverb) e introduzir testes unitários para garantir que o fluxo de dados entre utilizadores não se quebre durante o desenvolvimento.

## Problemas Identificados
1. **Conectividade Instável:** Logs mostram tentativas repetidas de reconexão.
2. **Dificuldade de Teste:** O `RealtimeService` é um Singleton difícil de mockar, impossibilitando testes automatizados do `CanvasController`.
3. **Gestão de Estado de Conexão:** A UI não reflete claramente se o utilizador está realmente "online" na sala ou se a ligação caiu.

## Mudanças Propostas

### 1. Refatoração para Testabilidade (Injeção de Dependência)
* **[RealtimeService](file:///C:/Users/Jetro.Domingos/StudioProjects/caderno_digital_app/lib/core/network/realtime_service.dart):**
    * Criar uma interface `IRealtimeService` (opcional) ou permitir a injeção do cliente Pusher.
    * Criar o `realtimeServiceProvider` no Riverpod para gerir a instância.
* **[CanvasController](file:///C:/Users/Jetro.Domingos/StudioProjects/caderno_digital_app/lib/features/canvas/controllers/canvas_controller.dart):**
    * Refatorar para receber o `RealtimeService` no construtor ou via provider.
    * Isto permitirá injetar um `MockRealtimeService` nos testes.

### 2. Melhoria na Estabilidade do Realtime
* **Reconexão Inteligente:** Adicionar um estado de conexão observável (`ConnectionState`) para que a UI possa mostrar avisos.
* **Throttling e Buffering:** Otimizar o envio de traços para evitar saturação do socket em redes lentas.
* **Keep-Alive:** Garantir que o canal de presença não "caduca" por inatividade.

### 3. Testes Unitários e de Fluxo
* **[NEW] [canvas_controller_test.dart](file:///C:/Users/Jetro.Domingos/StudioProjects/caderno_digital_app/test/features/canvas/controllers/canvas_controller_test.dart):**
    * Testar receção de traços remotos.
    * Testar broadcast de eventos ao desenhar localmente.
    * Validar se o `currentPageIndex` muda corretamente ao seguir um utilizador.

## Plano de Verificação

### Automated Tests
* Executar `flutter test test/features/canvas/controllers/canvas_controller_test.dart`.
* Validar 100% de cobertura na lógica de sincronização de traços.

### Manual Verification
* Abrir a app em dois dispositivos (ou browser + mobile).
* Desenhar em simultâneo e verificar se o atraso é mínimo e se não ocorrem quedas de ligação.
* Forçar a queda da internet e verificar se a app tenta reconectar de forma graciosa.
