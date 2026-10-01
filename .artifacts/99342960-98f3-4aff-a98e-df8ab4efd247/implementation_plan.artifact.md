# Plano de Implementação: Correção de Erro de Modificação de Provider Durante o Descarte da Widget Tree

Foi identificado um erro nos logs após sair do ecrã de um caderno:
```
The following assertion was thrown while dispatching notifications for CollaborationRoomService:
Tried to modify a provider while the widget tree was building.
...
#7      CollaborationRoomService.leaveSession
#8      _CanvasScreenState.dispose
```
E também para o reset do documento:
```
#5      CanvasDocumentNotifier.reset
#6      _CanvasScreenState.dispose
```

## Análise do Problema
O erro `Tried to modify a provider while the widget tree was building` ocorre quando é invocado `notifyListeners()` (ou alterado o `state` num `StateNotifier`) dentro de métodos relacionados com o ciclo de vida da árvore de widgets, nomeadamente o `dispose()`.

Na classe `_CanvasScreenState` no ficheiro `canvas_screen.dart`, o método `dispose()` chama:
1. `_collabService!.leaveSession()` -> Que invoca internamente `_safeNotify()`.
2. `_container!.read(canvasDocumentProvider.notifier).reset()` -> Que altera o `state`.
3. `_container!.read(canvasViewportProvider.notifier).reset()` -> Que altera o `state`.

Quando a navegação ocorre (ex: fechar o ecrã com o botão de voltar), a árvore de widgets está a ser destruída e repintada noutro lugar, e o Riverpod proíbe que se altere o estado (que dispara reconstruções) nesses exatos momentos sem um "delay" (`Future.microtask`).

## Mudanças Propostas

### 1. `_CanvasScreenState.dispose()` em `canvas_screen.dart`
Para garantir que as ações de limpeza (que modificam Providers) ocorram em segurança após a finalização da árvore de widgets, vamos envolver estas limpezas num `Future.microtask`.

#### [MODIFY] [canvas_screen.dart](file:///C:/Users/HP/StudioProjects/caderno-app/lib/features/canvas/views/canvas_screen.dart)
```dart
  @override
  void dispose() {
    final collabService = _collabService;
    final container = _container;

    if (collabService != null) {
      collabService.getPages = null;
      collabService.getCurrentPageIndex = null;
      collabService.getCurrentScale = null;
    }

    // 🚀 Atrasar a limpeza de estado que dispara notificações para evitar colisões no unmount da widget tree
    Future.microtask(() {
      collabService?.leaveSession();
      if (container != null) {
        container.read(canvasDocumentProvider.notifier).flushUnsyncedPages();
        container.read(canvasDocumentProvider.notifier).reset();
        container.read(canvasViewportProvider.notifier).reset();
      }
    });

    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }
```

Deste modo as referências são limpas de imediato na classe mas a chamada das funções que disparam `notifyListeners()` é delegada para o final do loop de eventos.

## Plano de Verificação
Após efetuar a alteração, pedir ao utilizador que:
1. Abra um caderno.
2. Ative a colaboração se desejado.
3. Volte para o ecrã anterior.
4. Confirme que não aparecem mais blocos vermelhos de erro (`Exception caught by foundation library`) nos logs.