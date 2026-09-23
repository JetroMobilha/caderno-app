# Plano de Implementação: Correção de Precisão e Feedback Visual de Transformação

Este plano aborda três problemas críticos na manipulação de objetos: a área de seleção de animações, a velocidade acelerada de movimento e o "salto" visual durante o redimensionamento.

## Mudanças Propostas

### 1. [Renderização: ObjectRenderer](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/widgets/object_renderer.dart)
- **Escala Live Real**: Atualizar `_buildImage`, `_buildAnimation`, `_buildShape` e `_buildTable` para aceitar e utilizar o `Size` calculado em tempo real.
- **Correção do Salto**: Ao passar o tamanho escalonado diretamente para os widgets internos, o objeto irá se deformar visualmente junto com a moldura azul, eliminando a discrepância entre a prévia e o estado final.

### 2. [Modelo: Stroke](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/models/stroke_model.dart)
- **Ordem de Transformação**: Refatorar `copyWith` para garantir que o redimensionamento ocorra ANTES do reposicionamento quando ambos são fornecidos. Isso evita erros acumulados de offset que causavam o "salto" em desenhos manuais.

### 3. [Serviço: TransformService](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/services/transform_service.dart)
- **Área de Animação**: Aumentar a inflação visual de `AnimationObject` de 2.0 para 8.0 pixels para garantir que a moldura envolva confortavelmente o conteúdo.

### 4. [Ferramenta e Estado: SelectTool e CanvasToolProvider](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/providers/canvas_tool_provider.dart)
- **Movimento 1:1**: Adicionar `lastLocalPosition` ao estado.
- Na `SelectTool`, calcular o deslocamento usando a diferença entre `localPosition` atual e anterior. Como `localPosition` já é transformado pelo Flutter (levando em conta o zoom do `InteractiveViewer`), isso garante que o objeto siga o dedo exatamente na mesma velocidade, sem acelerações erradas.

## Plano de Verificação

### Verificação Manual
1.  **Movimento**: Arrastar qualquer objeto com zoom de 50% e 200%. O objeto deve "colar" no dedo em ambas as situações.
2.  **Redimensionamento de Animação**: Confirmar que a moldura azul tem uma margem generosa e que a animação estica/encolhe suavemente durante o arraste.
3.  **Consistência Final**: Redimensionar um traço grosso e verificar se, ao soltar, ele permanece exatamente na posição da prévia azul.
