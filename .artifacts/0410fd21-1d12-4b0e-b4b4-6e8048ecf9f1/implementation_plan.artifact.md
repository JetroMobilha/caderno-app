# Refinamento de UX de Imagem, Texto e Histórico Colaborativo

Este plano visa corrigir a persistência de formatação no Undo, restaurar a criação de texto, implementar uma edição de imagem por seleção individual e transformar o Histórico (Undo/Redo) num sistema verdadeiramente partilhado entre todos os colegas.

## User Review Required

> [!IMPORTANT]
> **Histórico Colaborativo:** O sistema de Undo/Redo passará a ser global. Se o Utilizador A desenha e o Utilizador B clica em "Desfazer", o desenho do Utilizador A desaparecerá para todos. Todos partilham a mesma "pilha" de ações recentes.

> [!TIP]
> **Edição de Imagem:** Já não verá botões em todas as imagens ao mesmo tempo. Agora, deve clicar na imagem que deseja editar para que os controlos apareçam. Haverá um botão "✅" para confirmar as alterações.

## Proposed Changes

### [Component] Canvas Controller (Lógica de Histórico e Seleção)

#### [MODIFY] [canvas_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/controllers/canvas_controller.dart)
- **Estado de Edição:** Adicionar `String? selectedEditingImageId`.
- **Deep Copy no Undo:** Alterar as classes `CanvasAction` para armazenar uma cópia (clone) do estado do objeto (ex: `Stroke`, `TextBlock`, `ImageBlock`) no momento da ação, garantindo que o Undo restaure a posição e tamanho corretos.
- **Broadcast de Ações:** Criar um novo evento `client-action-sync` para enviar a estrutura da ação (ID, tipo, dados) para todos os colegas.
- **Undo Global:** Implementar o broadcast do comando Undo. Quando recebido, todos os clientes executam o `undo()` na sua pilha local de forma sincronizada.

---

### [Component] Canvas Screen (UX e Criação)

#### [MODIFY] [canvas_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/views/canvas_screen.dart)
- **Criação de Texto:** Corrigir o `onTapUp` para garantir que o clique na camada superior de tinta consiga disparar a criação de um novo bloco de texto quando a ferramenta está ativa.
- **Seleção de Imagem:** No loop de imagens, adicionar um `GestureDetector` que define o `selectedEditingImageId` ao clicar.
- **Handles Condicionais:** Mostrar os botões de redimensionar e remover apenas se `img.id == controller.selectedEditingImageId`.
- **Botão de Confirmação:** Adicionar um botão de "Check" flutuante sobre a imagem em edição para concluir a manipulação.

---

### [Component] Realtime Service

#### [MODIFY] [realtime_service.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/core/network/realtime_service.dart)
- Adicionar suporte para o evento `client-action-sync` e `client-global-undo-redo`.

## Verification Plan

### Manual Verification
1.  **Undo de Formatação:** Mover uma imagem, redimensionar, apagar e fazer Undo. Verificar se ela volta com o tamanho e posição exatos de antes de ser apagada.
2.  **Inserção de Texto:** Clicar com a ferramenta de texto e verificar se o teclado abre e o cursor aparece.
3.  **Seleção de Imagem:** Inserir duas imagens. Verificar que os botões de edição só aparecem na que for clicada.
4.  **Undo Partilhado:**
    *   Dispositivo A desenha.
    *   Dispositivo B clica em Undo.
    *   O desenho deve sumir em ambos os ecrãs.
5.  **Performance de Imagem:** Verificar se o carregamento em colaboração está mais estável (evitar múltiplas tentativas de download se já estiver em cache).
