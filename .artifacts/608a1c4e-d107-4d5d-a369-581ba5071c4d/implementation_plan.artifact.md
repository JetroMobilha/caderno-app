# Plano de Implementação: Responsividade e Estabilidade de Layout

Melhorar a experiência do utilizador em ecrãs grandes (Desktop/Web/Tablets) limitando a largura máxima da interface e corrigindo inconsistências de renderização.

## User Review Required

> [!IMPORTANT]
> Vou definir uma largura máxima de **1400px** para o conteúdo principal do Canvas. Em ecrãs maiores que isto, o caderno ficará centrado com margens laterais (fundo cinza), evitando que os elementos fiquem demasiado dispersos.

## Proposed Changes

### Core UI (Responsividade)

#### [MODIFY] [canvas_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/views/canvas_screen.dart)
- Envolver o `body` do `Scaffold` num `Center` + `ConstrainedBox` com `maxWidth: 1400`.
- Garantir que o fundo do `Scaffold` (`0xFFD6D6D6`) preenche as áreas fora do limite de largura.
- Limpar fechos de tags e parênteses remanescentes de edições anteriores.

#### [MODIFY] [canvas_app_bar.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/canvas_app_bar.dart)
- Substituir `.withValues(alpha: 0.05)` por `.withOpacity(0.05)` para garantir compatibilidade com versões anteriores do Flutter (Windows/Mobile).

#### [MODIFY] [canvas_toolbar.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/canvas_toolbar.dart)
- Substituir todos os `.withValues(alpha: ...)` por `.withOpacity(...)`.
- Garantir que a Toolbar se mantém centrada dentro do limite de 1400px.

### Estabilidade de Diálogos

#### [MODIFY] [add_page_dialog.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/dialogs/add_page_dialog.dart)
- Já alterado para `Wrap`, mas vou verificar se há mais algum `.withValues` perdido.

## Verification Plan

### Manual Verification
1.  Abrir a aplicação em modo Janela no Windows.
2.  Maximizar a janela em ecrãs UltraWide ou 4K.
3.  Verificar se o Canvas se mantém centrado e não "esticado" até aos bordos.
4.  Testar a abertura do `AddPageDialog` e confirmar que não ocorre crash de layout.
5.  Confirmar que o Offline First se mantém (criação imediata de página).
