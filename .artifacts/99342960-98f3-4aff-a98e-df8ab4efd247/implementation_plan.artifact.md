# Plano de Implementação: Bloqueio de Movimento Simultâneo e Upload Server de Anexos/Âncoras

Este plano especifica a solução técnica para:
1. Eliminar o conflito de coordenadas quando dois utilizadores tentam mover o mesmo objeto ao mesmo tempo.
2. Garantir o upload dos ficheiros das âncoras/anexos para o servidor Laravel (`caderno-backend`), permitindo que qualquer colaborador descarregue e abra o anexo.

---

## 1. Bloqueio de Movimento Simultâneo (Duelo de Intenções)

> [!IMPORTANT]
> **Causa do Conflito**: Quando o Utilizador A e o Utilizador B arrastam o mesmo objeto em simultâneo, ambos alteram o deslocamento (`delta`) localmente e enviam comandos de movimento via WebSocket. Os dois motores visuais entram em conflito ("coordenada doida").

### Solução Proposta
- **Lock Temporário no Servidor de Estado (`collaboration_room_service.dart`)**:
  - Criar um conjunto reativo `final Set<String> remoteMovingObjectIds = {};`.
  - Ao receber um evento `client-object-transform` com a flag `is_moving: true`, adicionar o `objectId` a este conjunto. Quando `is_moving: false` for recebido (ao soltar o objeto), remover o ID.
- **Proteção do Seletor (`select_tool.dart`)**:
  - No método `onPanStart` / `onTapDown` do `SelectTool`, verificar se o objeto clicado pertence ao `remoteMovingObjectIds`.
  - Se outro colaborador já estiver a arrastar o objeto nesse momento, impedir a seleção e o movimento local, ignorando o toque naquele objeto até o colega o soltar.
- **Emissão da Intenção de Movimento**:
  - Em `SelectTool.onPanUpdate`, enviar `is_moving: true` na chamada do `_throttleTransformBroadcast`.
  - Em `SelectTool.onPanEnd`, enviar um pacote final com `is_moving: false` para libertar o lock para os restantes membros da sala.

---

## 2. Upload de Ficheiros de Âncoras / Anexos para o Servidor Laravel

> [!IMPORTANT]
> **Causa**: Ao anexar um PDF/documento numa âncora, o ficheiro fica guardado apenas no caminho local do ecrã de quem o criou (`localPath: /data/user/0/.../attach_123.pdf`). Os outros colaboradores recebem o objeto, mas não conseguem abrir o ficheiro por este não existir nos seus telemóveis nem no servidor.

### Solução Proposta
- **Upload para o Backend Laravel**:
  - Em `canvas_document_provider.dart` (`addAttachment`), se a colaboração estiver ativa, efetuar o upload do ficheiro do anexo para o servidor (`_repository.uploadImage` ou `uploadAttachment`) e obter o URL remoto `remoteUrl` (`https://...:9000/storage/attachments/...`).
  - Preencher a propriedade `remoteUrl` do `AttachmentObject` antes de transmitir o `AddAttachmentAction` para a sala.
- **Abertura Inteligente no Recetor (`object_renderer.dart`)**:
  - Na função `_openLocalFile` do `_buildAttachment`:
    - Verificar se o ficheiro existe no caminho local (`localPath`). Se sim, abrir via `OpenFilex`.
    - Se o ficheiro local não existir no dispositivo do utilizador atual, mas existir um `remoteUrl` válido, abrir o ficheiro do servidor através do navegador/visualizador do sistema (`launchUrl(Uri.parse(attach.remoteUrl!))`).

---

## Ficheiros a Modificar

1. `lib/features/canvas/services/collaboration_room_service.dart`
2. `lib/core/network/realtime_service.dart`
3. `lib/features/canvas/tools/select_tool.dart`
4. `lib/features/canvas/providers/canvas_document_provider.dart`
5. `lib/features/canvas/widgets/object_renderer.dart`

---

## Plano de Verificação

1. **Teste de Movimento Simultâneo**:
   - Abrir o mesmo caderno em dois dispositivos em colaboração.
   - O Utilizador A clica e começa a arrastar uma imagem.
   - O Utilizador B tenta arrastar a mesma imagem ao mesmo tempo.
   - **Resultado Esperado**: O Utilizador B não consegue mover o objeto enquanto A o segura. As coordenadas mantêm-se estáveis sem qualquer salto imprevisível. Assim que A solta o objeto, B pode arrastá-lo.

2. **Teste de Abertura de Anexos/Âncoras**:
   - O Utilizador A anexa um ficheiro PDF/imagem no caderno.
   - O Utilizador B (noutro dispositivo) duplica o toque na Âncora Néon/Laranja.
   - **Resultado Esperado**: O ficheiro abre perfeitamente através do `remoteUrl` descarregado do servidor Laravel!

Aguardamos a tua confirmação (**"avança"**) para iniciar a implementação!