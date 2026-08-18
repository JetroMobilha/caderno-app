# Plano de Implementação: Fluxo Ágil de Colaboração e Papéis em Tempo Real

Este plano visa otimizar a entrada em modo colaborativo, garantindo a memória total das configurações (incluindo o modo de partilha) e permitindo a gestão dinâmica de permissões.

## Proposed Changes

### 1. Entrada Ágil com Memória Total (Skip Configuration)

#### [MODIFY] [canvas_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/views/canvas_screen.dart)
- Ao clicar no ícone da antena, se o utilizador for o dono:
  - Tentar carregar as configurações do servidor (`sharing_type`, `alternative_title`, `authorized_page_ids`).
  - Se existirem configurações (memória do servidor), iniciar a colaboração **diretamente** sem abrir modais.
  - Se for a primeira vez, abrir a `StartCollaborationSheet`.
- Adicionar suporte a **Long Press** no ícone para forçar a abertura do painel de configurações, permitindo mudar o modo (Inteiro vs Seleção) a qualquer altura.

#### [MODIFY] [canvas_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/controllers/canvas_controller.dart)
- Criar método `enableCollaborationWithLastSettings()` que automatiza o processo de `fetchStatus` -> `toggleCollaboration`.

### 2. Gestão de Papéis em Tempo Real (Role Management)

#### [MODIFY] [collaboration_center_sheet.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/collaboration_center_sheet.dart)
- Na lista de utilizadores, se o utilizador atual for o dono:
  - Transformar o badge de Role num `PopupMenuButton`.
  - Permitir trocar entre `Editor`, `Student` e `Viewer`.
  - Ao mudar, invocar a API e disparar um sinal de WebSocket (`SyncRequested`) para o utilizador afetado.

#### [MODIFY] [notebooks_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/notebooks/controllers/notebooks_controller.dart)
- Adicionar método `updateUserRole(int notebookServerId, String email, String role)` para persistência no servidor.

## Verification Plan

### Manual Verification
1. **Memória de Modo**: Abrir caderno -> Antena -> Escolher "Páginas Selecionadas" -> Sair. Clicar na antena novamente. Deve entrar direto no modo "Páginas Selecionadas" sem perguntar nada.
2. **Troca de Papel**: O dono altera um aluno para "Editor". O aluno deve ver a sua borracha e ferramentas de edição aparecerem no momento.
3. **Long Press**: Pressionar a antena por 1s e confirmar que o seletor de modo abre mesmo que já existam configurações.
