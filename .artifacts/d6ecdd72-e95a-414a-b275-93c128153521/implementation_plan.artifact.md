# Plano de Implementação - Remoção de Filtragem de Desenho (v10.36)

Este plano visa simplificar o processamento de desenhos na aplicação, eliminando a suavização por curvas de Bézier e a filtragem local, uma vez que estas tarefas agora são geridas pelo servidor. Isso resultará em desenhos mais rápidos e com resposta imediata.

## Mudanças Propostas

### 1. Modelo de Dados e Estado
- **[MODIFY] [stroke_model.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/models/stroke_model.dart)**:
    - Remover ou ignorar o campo `smoothingLevel`.
- **[MODIFY] [canvas_tool_provider.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/providers/canvas_tool_provider.dart)**:
    - Remover `smoothingLevel` do `CanvasInteractionState` e o método `setSmoothingLevel`.

### 2. Renderização de Traços
- **[MODIFY] [canvas_painter.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/canvas_painter.dart)**:
    - Eliminar a função `buildSmoothPath`.
    - Atualizar os pintores (`StrokesPainter`, `ActiveStrokePainter`, `RemoteLiveStrokesPainter`) para utilizarem exclusivamente a função `buildPath` (linhas retas entre pontos).

### 3. Captura de Traços
- **[MODIFY] [brush_tool.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/tools/brush_tool.dart)**:
    - Remover a simplificação de pontos RDP (`RdpSimplifier.simplify`) no final do traço.
    - Enviar todos os pontos capturados para garantir a fidelidade máxima exigida pelo servidor.

### 4. Interface de Utilizador (Cleanup)
- **[MODIFY] [canvas_toolbar.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/canvas_toolbar.dart)**:
    - Remover o botão de alternância de suavização (ícone `Icons.auto_awesome_rounded`).
- **[MODIFY] [thickness_studio_dialog.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/dialogs/thickness_studio_dialog.dart)**:
    - Remover o slider de "Suavização do Traço".
- **[MODIFY] [brush_style_sheet.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/dialogs/brush_style_sheet.dart)**:
    - Remover as opções de suavização.

## Verificação
- **Desenho**: Verificar se o traço segue exatamente a ponta da caneta/dedo sem arredondamentos artificiais.
- **Performance**: Validar se o desenho parece mais "leve" e instantâneo.
- **UI**: Confirmar que não restam controlos de suavização na barra de ferramentas ou diálogos.

> [!NOTE]
> Ao remover a filtragem local, a aplicação passará a enviar mais dados de pontos para o servidor, o que é desejado já que o servidor possui filtros mais avançados.
