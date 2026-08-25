# Tarefas: Reatividade Drift e Estabilidade de Carga

- [x] Refatorar `CanvasDocumentNotifier`
    - [x] Mudar `ref.watch` para `ref.read` no `build()` para estabilidade
    - [x] Implementar subscrição reativa com lógica de merge de conteúdo
    - [x] Adicionar método `broadcastPageMetadataUpdate` resiliente
    - [x] Implementar `ensurePageLoaded` para Lazy Loading reativo
- [x] Otimizar `CanvasScreen`
    - [x] Adicionar `ref.listen` para carga inicial automática da primeira página
    - [x] Corrigir erro de `LayoutBuilder` com `addPostFrameCallback`
    - [x] Sincronizar `PageView` com carregamento de páginas
- [x] Restaurar Funcionalidades na `DrawingLayer`
    - [x] Restaurar Traços Estáticos com `StaticNotebookPainter`
    - [x] Re-implementar Traços Remotos (Live) via `ValueListenableBuilder`
    - [x] Implementar Traço Ativo na `InteractionLayer` com `ActiveStrokePainter`
- [x] Corrigir Persistência
    - [x] Expor DB no `CanvasRepository`
    - [x] Implementar `deletePage` e `addTextBlock` no Document Notifier
- [x] Validar Fluxo de Sincronização (Análise limpa em `lib/`)
