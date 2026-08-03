# Implementação de Exportação e Cópia de Texto

Este plano visa permitir que o utilizador consiga copiar blocos de texto individuais e exportar todo o conteúdo textual de uma página (incluindo o resultado do OCR).

## Proposed Changes

### [Component] Canvas Controller (Lógica de Clipboard)

#### [MODIFY] [canvas_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/controllers/canvas_controller.dart)
- Adicionar import `package:flutter/services.dart`.
- Criar método `copyToClipboard(String text, BuildContext context)` para centralizar a lógica de cópia com feedback visual (SnackBar).
- Criar método `exportPageText(LocalPage page, BuildContext context)` que compila o título, o texto extraído (OCR) e as anotações digitais numa única string para cópia.

---

### [Component] Canvas Screen (Interação de Cópia)

#### [MODIFY] [canvas_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/views/canvas_screen.dart)
- Adicionar `onLongPress` aos blocos de texto para permitir a cópia individual do seu conteúdo.

---

### [Component] Canvas Toolbar (Interface de Exportação)

#### [MODIFY] [canvas_toolbar.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/canvas_toolbar.dart)
- Adicionar a opção "Exportar Texto" ao menu de opções (três pontos) em ecrãs pequenos.
- Adicionar um botão direto de "Exportar Texto" na barra de ferramentas para ecrãs grandes (Desktop/Tablet).

## Verification Plan

### Manual Verification
1. **Cópia Individual:** Pressionar longamente um bloco de texto digital e verificar se o SnackBar de confirmação aparece e o texto é colado noutra app.
2. **Exportação Completa:** Clicar no menu de opções da barra de ferramentas e selecionar "Exportar Todo o Texto". Verificar se o texto compilado (Título + OCR + Notas) é copiado corretamente.
3. **Feedback Visual:** Garantir que o SnackBar aparece com a cor padrão do projeto (`0xFF0F4C5C`).
