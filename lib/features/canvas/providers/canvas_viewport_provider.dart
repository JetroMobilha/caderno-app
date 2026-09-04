import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/local_page_model.dart';

class CanvasViewportState {
  final int currentPageIndex;
  final String? currentPageClientId; 
  final bool isFocusMode;
  final int activePointerCount;
  final Size? lastScreenSize;
  final Offset? currentViewportCenter;
  final double? currentVisibleWidth;
  final bool isStickyZoomPending; 

  CanvasViewportState({
    this.currentPageIndex = 0,
    this.currentPageClientId,
    this.isFocusMode = false,
    this.activePointerCount = 0,
    this.lastScreenSize,
    this.currentViewportCenter,
    this.currentVisibleWidth,
    this.isStickyZoomPending = false, 
  });

  CanvasViewportState copyWith({
    int? currentPageIndex,
    String? currentPageClientId,
    bool? isFocusMode,
    int? activePointerCount,
    Size? lastScreenSize,
    Offset? currentViewportCenter,
    double? currentVisibleWidth,
    bool? isStickyZoomPending,
  }) {
    return CanvasViewportState(
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      currentPageClientId: currentPageClientId ?? this.currentPageClientId,
      isFocusMode: isFocusMode ?? this.isFocusMode,
      activePointerCount: activePointerCount ?? this.activePointerCount,
      lastScreenSize: lastScreenSize ?? this.lastScreenSize,
      currentViewportCenter: currentViewportCenter ?? this.currentViewportCenter,
      currentVisibleWidth: currentVisibleWidth ?? this.currentVisibleWidth,
      isStickyZoomPending: isStickyZoomPending ?? this.isStickyZoomPending,
    );
  }
}

class CanvasViewportNotifier extends AutoDisposeNotifier<CanvasViewportState> {
  // 🚀 GESTÃO DE CONTROLLERS POR PÁGINA (Isolamento total)
  final Map<String, TransformationController> _controllers = {};
  final Set<String> _initializedPages = {}; 
  late final PageController pageController;

  @override
  CanvasViewportState build() {
    pageController = PageController(initialPage: 0);
    
    ref.onDispose(() {
      for (var c in _controllers.values) {
        c.dispose();
      }
      pageController.dispose();
    });

    return CanvasViewportState();
  }

  bool isPageInitialized(String clientId) => _initializedPages.contains(clientId);

  TransformationController getControllerFor(String clientId) {
    return _controllers.putIfAbsent(clientId, () => TransformationController());
  }

  void setPageIndex(int index, {String? clientId, Matrix4? initialMatrix}) {
    if (state.currentPageIndex == index && state.currentPageClientId == clientId) return;
    
    if (clientId != null && initialMatrix != null && !_controllers.containsKey(clientId)) {
      getControllerFor(clientId).value = initialMatrix;
    }
    
    // 🚀 USAR MICROTASK PARA EVITAR REBUILDS DURANTE O BUILD
    Future.microtask(() {
      state = state.copyWith(
        currentPageIndex: index, 
        currentPageClientId: clientId,
        isStickyZoomPending: false,
      );
    });
  }

  void jumpToPage(int index, {String? clientId}) {
    if (pageController.hasClients) {
      pageController.jumpToPage(index);
    }
    setPageIndex(index, clientId: clientId);
  }

  void syncIndexWithId(List<String> allClientIds) {
    if (state.currentPageClientId == null) {
       if (allClientIds.isNotEmpty && state.currentPageIndex < allClientIds.length) {
         state = state.copyWith(currentPageClientId: allClientIds[state.currentPageIndex]);
       }
       return;
    }

    final int newIndex = allClientIds.indexOf(state.currentPageClientId!);
    if (newIndex != -1 && newIndex != state.currentPageIndex) {
      state = state.copyWith(currentPageIndex: newIndex);
      if (pageController.hasClients) {
        Future.microtask(() {
          pageController.jumpToPage(newIndex);
        });
      }
    }
  }

  void toggleFocusMode() {
    state = state.copyWith(isFocusMode: !state.isFocusMode);
  }

  void updatePointerCount(int count) {
    state = state.copyWith(activePointerCount: count);
  }

  void updateViewport({
    Size? screenSize,
    Offset? center,
    double? visibleWidth,
  }) {
    final newState = state.copyWith(
      lastScreenSize: screenSize ?? state.lastScreenSize,
      currentViewportCenter: center ?? state.currentViewportCenter,
      currentVisibleWidth: visibleWidth ?? state.currentVisibleWidth,
    );
    
    if (newState.lastScreenSize != state.lastScreenSize ||
        newState.currentViewportCenter != state.currentViewportCenter ||
        newState.currentVisibleWidth != state.currentVisibleWidth) {
      Future.microtask(() => state = newState);
    }
  }

  void zoom(String clientId, double factor) {
    if (state.lastScreenSize == null) return;
    final controller = getControllerFor(clientId);
    
    final Matrix4 currentMatrix = controller.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();
    
    // 🚀 AMPLITUDE DE ZOOM AUMENTADA (De 5% a 600%)
    final double targetScale = (currentScale * factor).clamp(0.05, 6.0);
    final double effectiveFactor = targetScale / currentScale;

    if (effectiveFactor == 1.0) return;

    final screenCenter = Offset(state.lastScreenSize!.width / 2, state.lastScreenSize!.height / 2);
    
    final Matrix4 transformation = Matrix4.identity()
      ..translate(screenCenter.dx, screenCenter.dy)
      ..scale(effectiveFactor, effectiveFactor, 1.0)
      ..translate(-screenCenter.dx, -screenCenter.dy);

    controller.value = transformation * currentMatrix;
  }

  Matrix4 getCenteredMatrix(LocalPage page, Size screenSize) {
    final double pageW = page.pageWidthPx;
    final double pageH = page.pageHeightPx;

    final double scaleX = (screenSize.width * 0.8) / pageW;
    final double scaleY = (screenSize.height * 0.8) / pageH;
    
    // 🚀 CLAMP PARA PERMITIR ZOOM OUT INICIAL SE NECESSÁRIO
    final double initialScale = (scaleX < scaleY ? scaleX : scaleY).clamp(0.05, 1.0);

    final double tx = (screenSize.width - pageW * initialScale) / 2;
    final double ty = (screenSize.height - pageH * initialScale) / 2;

    return Matrix4.identity()
      ..translate(tx, ty)
      ..scale(initialScale);
  }

  void restorePageMatrix(LocalPage page, Size screenSize) {
    // 🚀 SÓ RESTAURAR UMA VEZ POR SESSÃO (RAM FIRST)
    if (_initializedPages.contains(page.clientId)) return;

    final controller = getControllerFor(page.clientId);
    if (page.viewportMatrix != null) {
      controller.value = page.viewportMatrix!;
    } else {
      controller.value = getCenteredMatrix(page, screenSize);
    }
    
    _initializedPages.add(page.clientId);
  }

  void resetZoom(String clientId, LocalPage page) {
    if (state.lastScreenSize == null) return;
    final controller = getControllerFor(clientId);
    controller.value = getCenteredMatrix(page, state.lastScreenSize!);
  }
}

final canvasViewportProvider = NotifierProvider.autoDispose<CanvasViewportNotifier, CanvasViewportState>(() {
  return CanvasViewportNotifier();
});
