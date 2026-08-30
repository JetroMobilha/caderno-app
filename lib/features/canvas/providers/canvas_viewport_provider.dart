import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CanvasViewportState {
  final int currentPageIndex;
  final String? currentPageClientId; // 🚀 ÂNCORA: Identidade da folha atual
  final bool isFocusMode;
  final int activePointerCount;
  final Size? lastScreenSize;
  final Offset? currentViewportCenter;
  final double? currentVisibleWidth;

  CanvasViewportState({
    this.currentPageIndex = 0,
    this.currentPageClientId,
    this.isFocusMode = false,
    this.activePointerCount = 0,
    this.lastScreenSize,
    this.currentViewportCenter,
    this.currentVisibleWidth,
  });

  CanvasViewportState copyWith({
    int? currentPageIndex,
    String? currentPageClientId,
    bool? isFocusMode,
    int? activePointerCount,
    Size? lastScreenSize,
    Offset? currentViewportCenter,
    double? currentVisibleWidth,
  }) {
    return CanvasViewportState(
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      currentPageClientId: currentPageClientId ?? this.currentPageClientId,
      isFocusMode: isFocusMode ?? this.isFocusMode,
      activePointerCount: activePointerCount ?? this.activePointerCount,
      lastScreenSize: lastScreenSize ?? this.lastScreenSize,
      currentViewportCenter: currentViewportCenter ?? this.currentViewportCenter,
      currentVisibleWidth: currentVisibleWidth ?? this.currentVisibleWidth,
    );
  }
}

class CanvasViewportNotifier extends AutoDisposeNotifier<CanvasViewportState> {
  late final TransformationController transformationController;
  late final PageController pageController;

  @override
  CanvasViewportState build() {
    transformationController = TransformationController();
    pageController = PageController(initialPage: 0);
    
    ref.onDispose(() {
      transformationController.dispose();
      pageController.dispose();
    });

    return CanvasViewportState();
  }

  void setPageIndex(int index, {String? clientId}) {
    if (state.currentPageIndex == index && state.currentPageClientId == clientId) return;
    state = state.copyWith(currentPageIndex: index, currentPageClientId: clientId);
  }

  void jumpToPage(int index, {String? clientId}) {
    if (state.currentPageIndex == index && state.currentPageClientId == clientId && pageController.hasClients && pageController.page?.round() == index) return;
    setPageIndex(index, clientId: clientId);
    if (pageController.hasClients) {
      Future.microtask(() {
        pageController.jumpToPage(index);
      });
    }
  }

  /// 🚀 SINCRONIA ESTRUTURAL: Ajusta o índice se as páginas mudarem de lugar
  void syncIndexWithId(List<String> allClientIds) {
    if (state.currentPageClientId == null) {
       if (allClientIds.isNotEmpty && state.currentPageIndex < allClientIds.length) {
         state = state.copyWith(currentPageClientId: allClientIds[state.currentPageIndex]);
       }
       return;
    }

    final int newIndex = allClientIds.indexOf(state.currentPageClientId!);
    if (newIndex != -1 && newIndex != state.currentPageIndex) {
      debugPrint('⚓ [Viewport] Ajustando índice por ID: ${state.currentPageIndex} -> $newIndex');
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
      state = newState;
    }
  }

  void zoom(double factor) {
    if (state.lastScreenSize == null) return;
    
    final currentScale = transformationController.value.getMaxScaleOnAxis();
    final targetScale = (currentScale * factor).clamp(0.1, 6.0);
    
    final screenCenter = Offset(state.lastScreenSize!.width / 2, state.lastScreenSize!.height / 2);
    
    transformationController.value = Matrix4.identity()
      ..translate(screenCenter.dx, screenCenter.dy)
      ..scale(targetScale, targetScale, 1.0)
      ..translate(-screenCenter.dx / currentScale, -screenCenter.dy / currentScale);
  }
}

final canvasViewportProvider = NotifierProvider.autoDispose<CanvasViewportNotifier, CanvasViewportState>(() {
  return CanvasViewportNotifier();
});
