# Plano de Implementação - Testes Unitários para Configuração de Páginas

Criar um conjunto robusto de testes unitários para diagnosticar e prevenir problemas na evolução da estrutura de páginas e nas suas configurações em tempo real.

## Revisão do Utilizador Necessária

> [!IMPORTANT]
> **Foco do Diagnóstico**: Os testes focarão na integridade da lista unificada de objetos, na conversão entre unidades (mm/pixels) e na persistência de configurações de layout (orientação, modo infinito).

## Mudanças Propostas

### 1. Testes de Modelo (`LocalPage`)

#### [NEW] [page_model_test.dart](file:///C:/Users/HP/StudioProjects/caderno-app/test/features/canvas/models/page_model_test.dart)
- Testar serialização JSON para garantir que a lista `objects` é preservada.
- Testar `copyWith` e `clone` para validar se campos como `isInfinite` e `backgroundConfig` são copiados corretamente.
- Validar os getters `pageWidthPx` e `pageHeightPx` em diferentes orientações.

### 2. Testes de Provedor (`CanvasDocumentNotifier`)

#### [MODIFY] [canvas_document_test.dart](file:///C:/Users/HP/StudioProjects/caderno-app/test/features/canvas/providers/canvas_document_test.dart)
- Adicionar teste para `updatePageSettings`, verificando se o estado da página em memória é atualizado imediatamente.
- Adicionar teste para `addNewPage` com o parâmetro `isInfinite`.

### 3. Testes de Configuração (`NotebookConfiguration`)

#### [NEW] [config_logic_test.dart](file:///C:/Users/HP/StudioProjects/caderno-app/test/features/notebooks/models/config_logic_test.dart)
- Validar a lógica de inferência de `paperSize` baseada em dimensões.
- Testar a consistência do `BackgroundConfig` rico.

## Plano de Verificação

### Execução de Testes
- Correr `flutter test test/features/canvas/models/page_model_test.dart`
- Correr `flutter test test/features/canvas/providers/canvas_document_test.dart`
- Correr `flutter test test/features/notebooks/models/config_logic_test.dart`

O resultado de cada teste ajudará a identificar se o problema está na **Lógica de Memória**, na **Persistência** ou na **Renderização**.
