# Correção de Sincronismo de Tempo e Avatares

Este plano aborda os problemas técnicos onde o tempo de última edição não é atualizado ao desenhar e os avatares dos participantes não são exibidos corretamente.

## User Review Required

> [!IMPORTANT]
> A atualização do tempo de edição do caderno agora será disparada sempre que uma página for alterada.
> A lógica de avatares será tornada mais resiliente para mostrar ícones mesmo quando a lista de preview estiver vazia ou o carregamento de imagem falhar.

## Proposed Changes

### [Componente] Flutter App (caderno-app)

#### [MODIFY] [canvas_repository.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/repositories/canvas_repository.dart)
- No método `markPageAsUnsynced`, adicionar lógica para atualizar também o campo `updatedAt` do caderno pai na tabela `Notebooks`. Isto garantirá que a grid reflita a edição real de conteúdo.

#### [MODIFY] [notebook_cover.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/notebooks/widgets/notebook_cover.dart)
- **Resiliência de Avatares**: Se `participantsTotal > 1` mas a lista `participants` estiver vazia (antes do primeiro sync completo), exibir um ícone genérico de grupo/pessoas.
- **Layout de Rodapé**: Ajustar para garantir que o tempo fique exatamente no centro e as páginas à direita, com os avatares flutuando acima.

#### [MODIFY] [sync_service.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/sync_service.dart)
- Garantir que a atualização de `updatedAt` vinda do servidor seja propagada corretamente para o caderno local.

---

### [Componente] Laravel Backend (caderno-backend)

#### [MODIFY] [SyncController.php](file:///C:/xampp/htdocs/caderno-backend/app/Http/Controllers/Api/SyncController.php)
- Garantir que no `pullNotebooks` o rácio de participantes seja injetado, permitindo que cadernos já existentes recebam os avatares.

## Plano de Verificação

### Verificação Técnica
- Realizar um traço numa folha e voltar à grid: o tempo deve dizer "agora mesmo".
- Verificar se cadernos partilhados mostram os avatares (ou ícones de fallback) no local correto.
