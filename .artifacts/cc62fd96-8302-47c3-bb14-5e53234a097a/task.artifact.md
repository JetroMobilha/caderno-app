# Tarefas: Implementação de Informação Detalhada e Nova UI em Cadernos

## Backend (Laravel)
- `[x]` Criar migração para novos campos em `notebooks` (origin, participants_preview, last_updated_by_name)
- `[x]` Atualizar o modelo `Notebook.php` (`$fillable` e `$casts` JSON)
- `[x]` Atualizar `SyncController.php` para injetar preview de participantes no sync
- `[x]` Injetar `online_count` dinâmico no `participants_preview` (Notebook.php)

## Frontend (Flutter)
- `[x]` Atualizar `app_database.dart` (Tabela Notebooks e Migração v24 com JSON)
- `[x]` Atualizar `notebook_model.dart` (Adicionado `ParticipantPreview` e `onlineCount`)
- `[x]` Implementar contagem dinâmica em `notebook_repository.dart` e `shared_notebook_repository.dart`
- `[x]` Redesenhar `notebook_cover.dart` com nova estrutura de rodapé distribuída
- `[x]` Simplificar Presence UI: Substituir avatares por contagem numérica e status online

## Refinamento de Layout e Sincronização
- `[x]` Garantir que edição de página atualiza tempo do caderno (`CanvasRepository`)
- `[x]` Corrigir mapeamento de `participantsPreview` no `SyncService.dart`
- `[x]` Remover fundo circular do menu de contexto no `NotebookGridItem.dart`
