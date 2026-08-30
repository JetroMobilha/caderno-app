import 'package:flutter_riverpod/flutter_riverpod.dart';

class CanvasUiState {
  final bool isGridView;
  final Set<String> collapsedSections;

  CanvasUiState({
    this.isGridView = false,
    this.collapsedSections = const {},
  });

  CanvasUiState copyWith({
    bool? isGridView,
    Set<String>? collapsedSections,
  }) {
    return CanvasUiState(
      isGridView: isGridView ?? this.isGridView,
      collapsedSections: collapsedSections ?? this.collapsedSections,
    );
  }
}

class CanvasUiNotifier extends AutoDisposeNotifier<CanvasUiState> {
  @override
  CanvasUiState build() {
    return CanvasUiState();
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
