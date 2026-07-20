# Otimização de Imagens: Upload Prévio e Partilha via URL

Este plano visa substituir o envio de imagens pesadas (Base64) pelo canal de Realtime por um fluxo mais leve: fazer o upload para o servidor Laravel e partilhar apenas o URL resultante.

## User Review Required

> [!IMPORTANT]
> **Backend:** Este plano assume que o servidor Laravel possui (ou terá) uma rota `POST /notebooks/{id}/upload-image` que retorna um JSON com o campo `url`.
> **Performance:** A imagem só aparecerá para os outros utilizadores após o upload completo (depende da velocidade da internet de quem envia).

## Mudanças Propostas

### 1. Camada de Dados (Repository)
- **[MODIFY] [canvas_repository.dart](file:///C:/Users/Jetro.Domingos/StudioProjects/caderno_digital_app/lib/features/canvas/repositories/canvas_repository.dart)**:
    - Adicionar método `uploadImage(int notebookId, File image)` usando `http.MultipartRequest`.
    - Integrar com o token de autenticação Sanctum.

### 2. Lógica de Negócio (Controller)
- **[MODIFY] [canvas_controller.dart](file:///C:/Users/Jetro.Domingos/StudioProjects/caderno_digital_app/lib/features/canvas/controllers/canvas_controller.dart)**:
    - Atualizar `pickAndInsertImage` para ser assíncrono e aguardar o upload.
    - Adicionar estado de `isUploading` para mostrar feedback na UI.
    - Modificar `broadcastImageBlockUpdate` para nunca enviar Base64, apenas o `imagePath` (que agora será o URL remoto).

### 3. Modelo de Dados
- **[MODIFY] [image_block_model.dart](file:///C:/Users/Jetro.Domingos/StudioProjects/caderno_digital_app/lib/features/canvas/models/image_block_model.dart)**:
    - Simplificar o `toMap` para remover a geração de Base64.
    - Manter apenas o essencial para a sincronização leve.

---

## Plano de Verificação

### Testes Manuais
1. Inserir uma imagem no computador.
2. Verificar se aparece um indicador de progresso (opcional, mas recomendado).
3. Confirmar que a imagem aparece no telemóvel do assistente.
4. Inspecionar o tráfego de rede (ou logs) para garantir que o sinal de Realtime não contém dados binários.
