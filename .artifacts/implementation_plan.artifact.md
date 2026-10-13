# Plano de Implementação: Otimização do Fluxo de Anexos e Estabilização em Colaboração

Refatorar a seleção, o carregamento e a partilha de anexos (arquivos) durante uma sessão de colaboração em tempo real. O objetivo é eliminar as desconexões do Reverb durante a escolha do ficheiro, garantir estabilização da ligação antes de transmitir, e assegurar que o ficheiro só aparece para os restantes colegas quando o upload na cloud estiver concluído.

## User Review Required

> [!IMPORTANT]
> **Fluxo de Aparição do Anexo para os Colegas:**
> Com este novo fluxo, quando um utilizador seleciona um ficheiro no telemóvel:
> 1. O anexo aparece **imediatamente e apenas** no ecrã de quem o adicionou (com indicador de progresso do upload).
> 2. Os colegas da sala **NÃO verão** o anexo até que o upload no servidor termine com sucesso.
> 3. Assim que o upload for concluído na cloud, o anexo é transmitido via Reverb para todos os colegas com o link remoto pronto para transferência.

> [!NOTE]
> **Visualização Web vs. Mobile:**
> - **No Mobile (Android / iOS):** Os colegas verão o anexo com o ícone de download. Ao darem um duplo clique, o ficheiro é descarregado para a memória do telemóvel e aberto localmente.
> - **Na Web (`kIsWeb`):** Os utilizadores poderão abrir e visualizar o ficheiro diretamente do servidor no navegador web (sem necessidade de download local).

## Proposed Changes

### Canvas Document Provider
#### [MODIFY] [canvas_document_provider.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/providers/canvas_document_provider.dart)
- **Modificar `addAttachment`:**
  - Adicionar o anexo localmente à página e à base de dados SQLite com `isRemote: true` (para impedir a transmissão imediata antes do upload).
  - Iniciar a tarefa de upload em plano de fundo `_uploadAttachmentInBackground`.
- **Modificar `_uploadAttachmentInBackground`:**
  - Realizar o upload do ficheiro para a cloud (`_repository.uploadImage`).
  - Atualizar o objeto local com `remoteUrl` e `syncedWithCloud = true`.
  - **Estabilização da ligação:** Antes de transmitir aos colegas, verificar se o Reverb está conetado (`_realtimeService.isConnected`). Se estiver a conetar/reconetar após o regresso do FilePicker, aguardar a estabilização da ligação.
  - **Transmitir aos colaboradores:** Criar e transmitir a ação `AddAttachmentAction` (já com o `remoteUrl` preenchido) para todos os presentes na sala via `_realtimeService.broadcastGlobalAction`.

### Object Renderer (Renderização do Anexo)
#### [MODIFY] [object_renderer.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/object_renderer.dart)
- **Ajustar `_openLocalFile`:**
  - Em plataformas **Web (`kIsWeb`)**: Abrir o ficheiro diretamente da URL remota no navegador via `launchUrl`.
  - Em plataformas **Mobile (Android/iOS)**:
    - Se o ficheiro existe no caminho local (`localPath`), abrir diretamente com `OpenFilex`.
    - Se não existe localmente mas existe na nuvem (`remoteUrl`), fazer o download assíncrono não-bloqueante (com o indicador de progresso na própria card), guardar no dispositivo e abrir com `OpenFilex`.
    - Se não existe localmente nem na nuvem (upload pendente ou falhou), exibir mensagem informativa.

---

## Verification Plan

### Automated / Diagnostic Tests
- Executar analise de código com `analyze_file` no `canvas_document_provider.dart` e `object_renderer.dart` para garantir ausência de avisos ou erros de sintaxe.

### Manual Verification
1. **Seleção e Reconexão:** Inserir um anexo via toolbar em modo de colaboração. Verificar que o seletor de ficheiros do sistema não causa instabilidade ao regressar à app.
2. **Feedback Local:** Confirmar que o utilizador que insere vê o anexo com o estado "A carregar para a cloud...".
3. **Visibilidade do Colega:** Confirmar que os colegas na sala só recebem e vêem o anexo no canvas após o upload na cloud ser concluído.
4. **Download e Abertura:**
   - Testar o duplo clique no dispositivo do colega para transferir e abrir o ficheiro.
   - Testar a abertura imediata se executado na Web.
