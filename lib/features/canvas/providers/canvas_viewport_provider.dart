import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class CanvasViewportState {
  final int currentPageIndex;
  final bool isFocusMode;
  final int activePointerCount;
  final Size? lastScreenSize;
  final Offset? currentViewportCenter;
  final double? currentVisibleWidth;

  CanvasViewportState({
    this.currentPageIndex = 0,
    this.isFocusMode = false,
    this.activePointerCount = 0,
    this.lastScreenSize,
    this.currentViewportCenter,
    this.currentVisibleWidth,
  });

  CanvasViewportState copyWith({
    int? currentPageIndex,
    bool? isFocusMode,
    int? activePointerCount,
    Size? lastScreenSize,
    Offset? currentViewportCenter,
    double? currentVisibleWidth,
  }) {
    return CanvasViewportState(
      currentPageIndex: currentPageIndex ?? this.currentPageIndex,
      isFocusMode: isFocusMode ?? this.isFocusMode,
      activePointerCount: activePointerCount ?? this.activePointerCount,
      lastScreenSize: lastScreenSize ?? this.lastScreenSize,
      currentViewportCenter: currentViewportCenter ?? this.currentViewportCenter,
      currentVisibleWidth: currentVisibleWidth ?? this.currentVisibleWidth,
    );
  }
}

class CanvasViewportNotifier extends Notifier<CanvasViewportState> {
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

  void setPageIndex(int index) {
    if (state.currentPageIndex == index) return;
    state = state.copyWith(currentPageIndex: index);
  }

  void jumpToPage(int index) {
    setPageIndex(index);
    pageController.jumpToPage(index);
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

final canvasViewportProvider = NotifierProvider<CanvasViewportNotifier, CanvasViewportState>(() {
  return CanvasViewportNotifier();
});
