# Plano de Implementação - Refatoração para Riverpod 2.0 (Canvas)

Este plano detalha a migração da gestão de estado do Canvas de um `ChangeNotifier` único para múltiplos `Notifier`s do Riverpod 2.0. Esta mudança visa otimizar o desempenho (reduzindo rebuilds) e melhorar a testabilidade.

## Revisão do Usuário Necessária

> [!IMPORTANT]
> A `CanvasController` será descontinuada em favor de três novos providers. Todos os widgets que dependem de `canvasProvider` terão de ser atualizados para consumir os novos providers específicos.
>
> **Arquitetura Riverpod 2.0**: Utilizaremos classes `Notifier` e `AsyncNotifier` com codegen (`@riverpod`) onde possível, ou definições manuais se o codegen não estiver configurado no projeto. Dado o estado atual do projeto, utilizarei definições manuais compatíveis com o que já existe.

## Alterações Propostas

### 1. Estado de Ferramentas (`CanvasToolNotifier`)
Gere a interface de interação e o estado das ferramentas.
- **Local**: `lib/features/canvas/providers/canvas_tool_provider.dart`
- **Responsabilidades**: `ToolMode`, cores, espessura, seleção de objetos, retângulos de seleção.

### 2. Estado de Visualização (`CanvasViewportNotifier`)
Gere o zoom, posição da câmara e navegação entre páginas.
- **Local**: `lib/features/canvas/providers/canvas_viewport_provider.dart`
- **Responsabilidades**: `TransformationController`, `PageController`, zoom level, index da página atual.

### 3. Estado do Documento (`CanvasDocumentNotifier`)
Gere o conteúdo real do caderno e a lógica de persistência/sincronização.
- **Local**: `lib/features/canvas/providers/canvas_document_provider.dart`
- **Responsabilidades**: Lista de páginas, manipulação de traços/textos/imagens, Undo/Redo, integração com `RealtimeService` e `SyncService`.

### 4. Refatoração da UI
- **[MODIFY] [canvas_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/views/canvas_screen.dart)**: Atualizar para injetar e ler os novos providers.
- **[MODIFY] Camadas e Widgets**: `InteractionLayer`, `DrawingLayer`, `TextLayer`, `ImageLayer`, `CanvasToolbar` e `CanvasAppBar` serão atualizados para observar apenas o estado de que necessitam.

---

## Verificação Plan

### Testes Automatizados
- Criar novos testes unitários para cada Notifier.
- Validar se a mutação de uma ferramenta não dispara rebuilds na `DrawingLayer` (se não houver mudança no documento).

### Manual Verification
1. Abrir um caderno e verificar se as páginas carregam corretamente.
2. Testar desenho com diferentes cores e espessuras.
3. Testar zoom e navegação entre páginas.
4. Validar se o Undo/Redo continua a funcionar através do `CanvasDocumentNotifier`.
5. Verificar se a colaboração em tempo real permanece funcional.

---
**Estás pronto para começar a execução?**
