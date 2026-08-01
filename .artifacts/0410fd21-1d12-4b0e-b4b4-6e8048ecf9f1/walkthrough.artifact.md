# Walkthrough: Sincronização Robusta e Alinhamento Coletivo

Implementei melhorias críticas na sincronização do Canvas para garantir que todos os colaboradores tenham sempre a mesma visão e que artefatos visuais indesejados desapareçam.

## Mudanças Principais

### 1. Fim dos "Traços Fantasmas"
- Corrigi o problema onde uma linha reta aparecia ligando o início e o fim do desenho sincronizado.
- **Lógica:** Agora, o Payload final de um traço substitui completamente a versão temporária no dispositivo de quem recebe, eliminando a duplicação de pontos que causava o erro.

### 2. Rasgar Folha Sincronizado (Soft Delete)
- A exclusão de páginas agora é persistente e sincronizada entre todos os utilizadores.
- **Funcionamento:** Quando rasga uma folha (mesmo offline), ela é marcada como excluída no SQLite. Ao sincronizar, o sinal é enviado ao servidor, que por sua vez avisa todos os outros dispositivos para removerem essa folha das suas estantes locais.

### 3. Ciclo de Alinhamento Coletivo com Trava (Lock)
- Para garantir que todos tenham o mesmo conteúdo ao iniciar uma sessão, implementei um mecanismo de alinhamento global.
- **Disparador:** Quando um novo colega entra na sala, todos os participantes recebem uma ordem automática para sincronizar.
- **Trava de Segurança:** Durante este alinhamento (que dura poucos segundos), a interface é bloqueada com um aviso: *"A alinhar caderno..."*. Isto evita conflitos de escrita enquanto os dados estão a ser unificados.

### 4. Gestão de Utilizadores
- A lista de utilizadores no cockpit é atualizada instantaneamente quando alguém entra ou sai da sala.
- Removi a possibilidade de um utilizador tentar "assistir a si próprio" na visão compartilhada.

## Arquivos Modificados

- [canvas_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/controllers/canvas_controller.dart): Lógica de alinhamento coletivo, trava e correção de traços.
- [canvas_repository.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/repositories/canvas_repository.dart): Implementação de Soft Delete e filtragem de páginas.
- [sync_service.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/sync_service.dart): Suporte à sincronização do estado de deleção.
- [realtime_service.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/realtime_service.dart): Novos eventos de sinalização global.
- [canvas_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/views/canvas_screen.dart): Overlay visual de bloqueio durante a sincronização.

## Como Testar
1.  **Traços:** Desenhe em dois dispositivos e note que o desenho termina de forma limpa sem linhas extras.
2.  **Entrada na Sala:** Ao entrar num caderno compartilhado, observe a mensagem de alinhamento e confirme que ambos os ecrãs mostram exatamente os mesmos desenhos.
3.  **Rasgar Folha:** Apague uma folha e veja-a desaparecer automaticamente no dispositivo do colega.
