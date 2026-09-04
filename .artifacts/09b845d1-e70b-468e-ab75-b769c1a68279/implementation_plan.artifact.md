# Plano de Restauro: Processamento de Imagens e Integridade no SyncService

Restaurar a lógica de descodificação Base64 e armazenamento físico de imagens no servidor, garantindo que a unificação de objetos (v29) não comprometa o upload de ficheiros.

## Diagnóstico
Durante a migração para `objects_data`, a lógica que transformava `image_base64` em ficheiros `.png` no disco do servidor foi omitida. Isso faria com que as imagens inseridas no App não fossem guardadas corretamente no backend, resultando em links quebrados ou perda de dados.

## Mudanças Propostas - Backend (Laravel)

### 1. Serviço de Sincronização (`SyncService.php`)

#### [MODIFY] [SyncService.php](file:///C:/xampp/htdocs/caderno-backend/app/Services/SyncService.php)
- **Implementar `processBase64Objects`**: Um novo método privado que percorre a lista de objetos (`objects_data`) e, para cada item do tipo `image`, verifica se existe conteúdo Base64.
- **Restaurar Armazenamento**: Reintroduzir o uso de `Storage::disk('public')->put()` e a geração de URLs via `asset()`.
- **Integrar no Fluxo Principal**: Chamar este processador antes de realizar o merge final dos objetos.

### 2. Modelo de Página (`Page.php`)

#### [MODIFY] [Page.php](file:///C:/xampp/htdocs/caderno-backend/app/Models/Page.php)
- **Sincronia de Atributos**: Garantir que o atributo `unified_objects` (appends) reflita as alterações nos caminhos das imagens processadas pelo serviço.

## Plano de Verificação

### Verificação Manual
1. **Upload de Imagem**: Inserir uma foto nova no App Flutter e sincronizar.
2. **Confirmação de Ficheiro**: Verificar na pasta `C:\xampp\htdocs\caderno-backend\storage\app\public\notebook_images` se o novo ficheiro `.png` foi criado.
3. **Persistência Multi-dispositivo**: Limpar os dados do App e fazer login noutro dispositivo. Confirmar que a imagem aparece carregada através da URL do servidor.
