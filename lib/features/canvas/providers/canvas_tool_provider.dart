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
  final List<Offset>? lassoPath; // 🚀 Novo
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
    this.lassoPath, // 🚀
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
    List<Offset>? lassoPath, // 🚀
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
      lassoPath: lassoPath ?? this.lassoPath, // 🚀
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
      lassoPath: null, // 🚀
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
      lassoPath: null, // Resetar lasso se usar rect
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

  void setLassoPath(List<Offset>? path, [LocalPage? page]) {
    state = state.copyWith(
      lassoPath: path,
      selectionRectStart: null,
      selectionRectEnd: null,
    );

    if (path != null && path.length > 3 && page != null) {
      final newStrokeIds = <String>{};
      for (var s in page.strokes) {
        if (!s.isDeleted && s.points.any((pt) => _isPointInPolygon(pt, path))) {
          newStrokeIds.add(s.id);
        }
      }
      final newTextIds = <String>{};
      for (var t in page.textBlocks) {
        if (!t.isDeleted && _isPointInPolygon(t.position, path)) {
          newTextIds.add(t.id);
        }
      }
      state = state.copyWith(
        selectedStrokeIds: newStrokeIds,
        selectedTextIds: newTextIds,
      );
    }
  }

  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    bool result = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
          (point.dx < (polygon[j].dx - polygon[i].dx) * (point.dy - polygon[i].dy) / (polygon[j].dy - polygon[i].dy) + polygon[i].dx)) {
        result = !result;
      }
      j = i;
    }
    return result;
  }

  void clearSelection() {
    state = state.copyWith(
      selectedStrokeIds: {},
      selectedTextIds: {},
      selectedImageIds: {},
      selectionRectStart: null,
      selectionRectEnd: null,
      lassoPath: null, // 🚀
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
