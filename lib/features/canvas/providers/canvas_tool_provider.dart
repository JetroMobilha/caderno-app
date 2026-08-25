import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/canvas_enums.dart';
import '../models/text_block_model.dart';
import '../models/local_page_model.dart';

class CanvasToolState {
  final ToolMode currentTool;
  final String selectedColorHex;
  final double selectedThickness;
  final InlineTarget activeInlineTarget;
  final TextBlock? activeTextBlock;
  final Set<String> selectedStrokeIds;
  final Set<String> selectedTextIds;
  final Set<String> selectedImageIds;
  final Offset? selectionRectStart;
  final Offset? selectionRectEnd;
  final bool isTransformMode;
  final bool isHighlighter;
  final Offset totalSelectionDelta;
  final String? selectedEditingImageId;

  CanvasToolState({
    this.currentTool = ToolMode.draw,
    this.selectedColorHex = '#2C3E50',
    this.selectedThickness = 3.0,
    this.activeInlineTarget = InlineTarget.none,
    this.activeTextBlock,
    this.selectedStrokeIds = const {},
    this.selectedTextIds = const {},
    this.selectedImageIds = const {},
    this.selectionRectStart,
    this.selectionRectEnd,
    this.isTransformMode = false,
    this.isHighlighter = false,
    this.totalSelectionDelta = Offset.zero,
    this.selectedEditingImageId,
  });

  CanvasToolState copyWith({
    ToolMode? currentTool,
    String? selectedColorHex,
    double? selectedThickness,
    InlineTarget? activeInlineTarget,
    TextBlock? activeTextBlock,
    Set<String>? selectedStrokeIds,
    Set<String>? selectedTextIds,
    Set<String>? selectedImageIds,
    Offset? selectionRectStart,
    Offset? selectionRectEnd,
    bool? isTransformMode,
    bool? isHighlighter,
    Offset? totalSelectionDelta,
    String? selectedEditingImageId,
  }) {
    return CanvasToolState(
      currentTool: currentTool ?? this.currentTool,
      selectedColorHex: selectedColorHex ?? this.selectedColorHex,
      selectedThickness: selectedThickness ?? this.selectedThickness,
      activeInlineTarget: activeInlineTarget ?? this.activeInlineTarget,
      activeTextBlock: activeTextBlock ?? this.activeTextBlock,
      selectedStrokeIds: selectedStrokeIds ?? this.selectedStrokeIds,
      selectedTextIds: selectedTextIds ?? this.selectedTextIds,
      selectedImageIds: selectedImageIds ?? this.selectedImageIds,
      selectionRectStart: selectionRectStart ?? this.selectionRectStart,
      selectionRectEnd: selectionRectEnd ?? this.selectionRectEnd,
      isTransformMode: isTransformMode ?? this.isTransformMode,
      isHighlighter: isHighlighter ?? this.isHighlighter,
      totalSelectionDelta: totalSelectionDelta ?? this.totalSelectionDelta,
      selectedEditingImageId: selectedEditingImageId ?? this.selectedEditingImageId,
    );
  }
}

class CanvasToolNotifier extends Notifier<CanvasToolState> {
  @override
  CanvasToolState build() => CanvasToolState();

  void switchTool(ToolMode mode) {
    state = state.copyWith(
      currentTool: mode,
      isTransformMode: false,
      selectionRectStart: null,
      selectionRectEnd: null,
    );
  }

  void setColor(String hex) {
    state = state.copyWith(selectedColorHex: hex);
  }

  void setThickness(double thickness) {
    state = state.copyWith(selectedThickness: thickness);
  }

  void toggleHighlighterMode(bool value) {
    state = state.copyWith(isHighlighter: value);
  }

  void setTextEditing(InlineTarget target, [TextBlock? block]) {
    state = state.copyWith(
      activeInlineTarget: target,
      activeTextBlock: block,
    );
  }

  void clearTextEditing() {
    state = state.copyWith(
      activeInlineTarget: InlineTarget.none,
      activeTextBlock: null,
    );
  }

  void toggleTransformMode() {
    state = state.copyWith(isTransformMode: !state.isTransformMode);
  }

  void setSelectionRect(Offset? start, Offset? end, [LocalPage? page]) {
    state = state.copyWith(
      selectionRectStart: start,
      selectionRectEnd: end,
    );

    if (start != null && end != null && page != null) {
      final rect = Rect.fromPoints(start, end);
      final newStrokeIds = <String>{};
      for (var s in page.strokes) {
        if (!s.isDeleted && s.points.any((pt) => rect.contains(pt))) {
          newStrokeIds.add(s.id);
        }
      }
      final newTextIds = <String>{};
      for (var t in page.textBlocks) {
        if (!t.isDeleted && rect.contains(t.position)) {
          newTextIds.add(t.id);
        }
      }
      state = state.copyWith(
        selectedStrokeIds: newStrokeIds,
        selectedTextIds: newTextIds,
      );
    }
  }

  void clearSelection() {
    state = state.copyWith(
      selectedStrokeIds: {},
      selectedTextIds: {},
      selectedImageIds: {},
      selectionRectStart: null,
      selectionRectEnd: null,
      isTransformMode: false,
      totalSelectionDelta: Offset.zero,
    );
  }

  void updateSelectionDelta(Offset delta) {
    state = state.copyWith(totalSelectionDelta: state.totalSelectionDelta + delta);
  }

  void resetSelectionDelta() {
    state = state.copyWith(totalSelectionDelta: Offset.zero);
  }

  void selectIds({
    Set<String>? strokeIds,
    Set<String>? textIds,
    Set<String>? imageIds,
  }) {
    state = state.copyWith(
      selectedStrokeIds: strokeIds ?? state.selectedStrokeIds,
      selectedTextIds: textIds ?? state.selectedTextIds,
      selectedImageIds: imageIds ?? state.selectedImageIds,
    );
  }
}

final canvasToolProvider = NotifierProvider<CanvasToolNotifier, CanvasToolState>(() {
  return CanvasToolNotifier();
});
