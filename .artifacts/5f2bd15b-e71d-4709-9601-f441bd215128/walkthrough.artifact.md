# Walkthrough - Alinhamento Backend e Visibilidade de Partilhados

Implementei correções profundas tanto no **App** como no **Backend (Servidor)** para garantir que os cadernos partilhados apareçam corretamente, com as permissões certas e com suporte a estados pessoais (arquivo/favorito).

## Alterações Realizadas

### 1. Correções no Backend (Laravel)
- **Migração de Base de Dados**: Criei uma migração no servidor para adicionar as colunas `is_archived` e `is_favorite` à tabela de partilhas (`notebook_user`). Isto permite que cada utilizador tenha o seu próprio estado de arquivo num caderno partilhado, sem afetar o dono ou outros convidados.
- **Fix no `SyncController.pullNotebooks`**: Corrigi um bug onde o servidor forçava a role `viewer` para todos os convidados durante a sincronização total. Agora, o servidor consulta a role real (editor/viewer) no banco de dados.
- **Lógica de Sincronização Inteligente**: Atualizei o `pushNotebooks` no servidor para distinguir entre atualizações do dono e de convidados.
    - Se fores o **dono**, atualizas os dados globais do caderno.
    - Se fores um **convidado**, as tuas alterações de "arquivar" ou "favoritar" são guardadas apenas no teu perfil pessoal (tabela de pivô).

### 2. Melhorias no App (Flutter)
- **Sincronização de Roles**: O `SyncService` foi validado para processar corretamente as roles vindas do servidor.
- **Persistência Local**: Garanti que os estados de arquivo e favorito são lidos e gravados na tabela `notebook_user` local para cadernos que não nos pertencem.

### 3. Interface (Canvas)
- **Desbloqueio de Ferramentas**: Corrigi o `CanvasToolbar` para que utilizadores com a role `editor` tenham acesso às ferramentas de desenho, que anteriormente estavam restritas apenas ao `owner`.

## Verificação Realizada
- **Migração Servidor**: Executada com sucesso via `php artisan migrate`.
- **Fluxo de Dados**: Testada a comunicação entre App e Servidor; os campos de role e estados pessoais estão agora em total harmonia.
- **Permissões**: Confirmado que convidados com permissão de edição já conseguem desenhar nos cadernos partilhados.
