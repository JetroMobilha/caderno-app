# Plano de Correção de Fantasmas e Otimização de Seleção

O objetivo é eliminar os "desenhos fantasmas" (duplicados) que aparecem para outros colegas durante o uso da ferramenta de seleção e tornar o movimento dos objetos muito mais fluido para todos.

## User Review Required

> [!IMPORTANT]
> - O movimento de objetos selecionados passará a usar a **Camada Live** (como se fosse um desenho em curso). Isto significa que os teus colegas verão os objetos a deslizar suavemente, em vez de "saltarem" de posição em posição.
> - Implementaremos uma limpeza automática de IDs duplicados em todas as folhas. Se um desenho for movido ou atualizado, o sistema garante que ele desaparece de qualquer outra página onde pudesse estar "preso" por erro.

## Proposed Changes

### [CanvasController]

#### [MODIFY] [canvas_controller.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/controllers/canvas_controller.dart)

1.  **Movimento Híbrido**:
    - No `moveSelectedStrokes`, passaremos a enviar os dados com `is_final: false` durante o arrasto.
    - Incrementaremos `page.version++` localmente a cada passo do movimento para que o criador veja o objeto a mover-se sem atrasos.
2.  **Finalização de Seleção**:
    - Criar o método `_finalizeSelectionMovement` para enviar o estado definitivo (`is_final: true`) apenas quando o utilizador larga o objeto.
3.  **Saneamento de IDs (Anti-Ghost)**:
    - No `onStrokeReceived`, ao receber um traço (seja live ou final), vamos garantir que esse ID é removido de todas as outras páginas do caderno, evitando que o mesmo desenho apareça em duas folhas ao mesmo tempo.
4.  **Navegação Segura**:
    - Limpar a seleção (`selectedStrokeIds.clear()`, etc.) ao mudar de página para evitar que objetos de páginas anteriores sejam afetados por movimentos na página atual.

## Verification Plan

### Manual Verification
- **Teste de Fantasmas**: Mover um desenho no Dispositivo A. Verificar no Dispositivo B se o desenho se move suavemente e se não deixa um "rastro" ou cópia na posição original ou noutras páginas.
- **Mudança de Página**: Selecionar um objeto na Página 1, mudar para a Página 2 e verificar se a seleção foi limpa.
- **Fidelidade**: Confirmar que os objetos mantêm a sua forma original após o movimento.
