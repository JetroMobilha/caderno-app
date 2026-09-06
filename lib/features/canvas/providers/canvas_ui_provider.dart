import 'package:flutter_riverpod/flutter_riverpod.dart';

class CanvasUiState {
  final bool isGridView;
  final Set<String> collapsedSections;
  final bool isHudMode; // 🚀 v2: Oculta toolbar durante movimento

  CanvasUiState({
    this.isGridView = false,
    this.collapsedSections = const {},
    this.isHudMode = false,
  });

  CanvasUiState copyWith({
    bool? isGridView,
    Set<String>? collapsedSections,
    bool? isHudMode,
  }) {
    return CanvasUiState(
      isGridView: isGridView ?? this.isGridView,
      collapsedSections: collapsedSections ?? this.collapsedSections,
      isHudMode: isHudMode ?? this.isHudMode,
    );
  }
}

class CanvasUiNotifier extends AutoDisposeNotifier<CanvasUiState> {
  @override
  CanvasUiState build() => CanvasUiState();

  void setHudMode(bool value) {
    if (state.isHudMode != value) state = state.copyWith(isHudMode: value);
  }

  void toggleGridView(bool isGrid) {
    state = state.copyWith(isGridView: isGrid);
  }

  void toggleSection(String sectionTitle) {
    final newCollapsed = Set<String>.from(state.collapsedSections);
    if (newCollapsed.contains(sectionTitle)) {
      newCollapsed.remove(sectionTitle);
    } else {
      newCollapsed.add(sectionTitle);
    }
    state = state.copyWith(collapsedSections: newCollapsed);
  }
}

final canvasUiProvider = NotifierProvider.autoDispose<CanvasUiNotifier, CanvasUiState>(() {
  return CanvasUiNotifier();
});
