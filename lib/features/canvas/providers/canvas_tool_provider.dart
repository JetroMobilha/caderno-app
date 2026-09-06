import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/animation_object_model.dart';
import '../models/audio_block_model.dart';
import '../models/canvas_enums.dart';
import '../models/image_block_model.dart';
import '../models/shape_model.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../models/local_page_model.dart';
import '../models/table_model.dart';
import '../models/link_model.dart';
import '../models/attachment_model.dart';
import '../models/page_object.dart';

enum HandleType { none, topLeft, topCenter, topRight, middleRight, bottomRight, bottomCenter, bottomLeft, middleLeft, rotate }

class CanvasToolState {
  final ToolMode currentTool;
  final String selectedColorHex;
  final double selectedThickness;
  final InlineTarget activeInlineTarget;
  final TextBlock? activeTextBlock;
  final String? activeTableId; // 🚀 v3.2
  final String? activeTableCell; // 🚀 v3.2 (format: "row,col")
  final Set<String> selectedStrokeIds;
  final Set<String> selectedTextIds;
  final Set<String> selectedImageIds;
  final Set<String> selectedShapeIds; 
  final Set<String> selectedAudioIds; 
  final Set<String> selectedAnimationIds; 
  final Set<String> selectedTableIds; 
  final Set<String> selectedLinkIds; 
  final Set<String> selectedAttachmentIds; 
  final Offset? selectionRectStart;
  final Offset? selectionRectEnd;
  final List<Offset>? lassoPath; 
  final bool isTransformMode;
  final bool isHighlighter;
  final BrushType selectedBrushType; // 🚀 v1.2
  final bool isSmoothingEnabled;    // 🚀 v1.2
  final Offset totalSelectionDelta;
  final Size liveScale; 
  final double liveRotation; 
  final bool isMovingSelection; 
  final String? selectedEditingImageId;
  final HandleType activeHandle; 
  final Offset initialPosition; 
  final Size initialSize; 
  final double initialRotation;

  CanvasToolState({
    this.currentTool = ToolMode.draw,
    this.selectedColorHex = '#2C3E50',
    this.selectedThickness = 3.0,
    this.activeInlineTarget = InlineTarget.none,
    this.activeTextBlock,
    this.activeTableId,
    this.activeTableCell,
    this.selectedStrokeIds = const {},
    this.selectedTextIds = const {},
    this.selectedImageIds = const {},
    this.selectedShapeIds = const {},
    this.selectedAudioIds = const {},
    this.selectedAnimationIds = const {},
    this.selectedTableIds = const {},
    this.selectedLinkIds = const {},
    this.selectedAttachmentIds = const {},
    this.selectionRectStart,
    this.selectionRectEnd,
    this.lassoPath, 
    this.isTransformMode = false,
    this.isHighlighter = false,
    this.selectedBrushType = BrushType.gel,
    this.isSmoothingEnabled = false,
    this.totalSelectionDelta = Offset.zero,
    this.liveScale = const Size(1, 1),
    this.liveRotation = 0.0,
    this.isMovingSelection = false,
    this.selectedEditingImageId,
    this.activeHandle = HandleType.none,
    this.initialPosition = Offset.zero,
    this.initialSize = Size.zero,
    this.initialRotation = 0.0,
  });

  CanvasToolState copyWith({
    ToolMode? currentTool,
    String? selectedColorHex,
    double? selectedThickness,
    InlineTarget? activeInlineTarget,
    TextBlock? activeTextBlock,
    String? activeTableId,
    String? activeTableCell,
    Set<String>? selectedStrokeIds,
    Set<String>? selectedTextIds,
    Set<String>? selectedImageIds,
    Set<String>? selectedShapeIds,
    Set<String>? selectedAudioIds,
    Set<String>? selectedAnimationIds,
    Set<String>? selectedTableIds,
    Set<String>? selectedLinkIds,
    Set<String>? selectedAttachmentIds,
    Offset? selectionRectStart,
    Offset? selectionRectEnd,
    List<Offset>? lassoPath, 
    bool? isTransformMode,
    bool? isHighlighter,
    BrushType? selectedBrushType,
    bool? isSmoothingEnabled,
    bool? isMovingSelection,
    Offset? totalSelectionDelta,
    Size? liveScale,
    double? liveRotation,
    String? selectedEditingImageId,
    HandleType? activeHandle,
    Offset? initialPosition,
    Size? initialSize,
    double? initialRotation,
  }) {
    return CanvasToolState(
      currentTool: currentTool ?? this.currentTool,
      selectedColorHex: selectedColorHex ?? this.selectedColorHex,
      selectedThickness: selectedThickness ?? this.selectedThickness,
      activeInlineTarget: activeInlineTarget ?? this.activeInlineTarget,
      activeTextBlock: activeTextBlock ?? this.activeTextBlock,
      activeTableId: activeTableId ?? this.activeTableId,
      activeTableCell: activeTableCell ?? this.activeTableCell,
      selectedStrokeIds: selectedStrokeIds ?? this.selectedStrokeIds,
      selectedTextIds: selectedTextIds ?? this.selectedTextIds,
      selectedImageIds: selectedImageIds ?? this.selectedImageIds,
      selectedShapeIds: selectedShapeIds ?? this.selectedShapeIds,
      selectedAudioIds: selectedAudioIds ?? this.selectedAudioIds,
      selectedAnimationIds: selectedAnimationIds ?? this.selectedAnimationIds,
      selectedTableIds: selectedTableIds ?? this.selectedTableIds,
      selectedLinkIds: selectedLinkIds ?? this.selectedLinkIds,
      selectedAttachmentIds: selectedAttachmentIds ?? this.selectedAttachmentIds,
      selectionRectStart: selectionRectStart ?? this.selectionRectStart,
      selectionRectEnd: selectionRectEnd ?? this.selectionRectEnd,
      lassoPath: lassoPath ?? this.lassoPath, 
      isTransformMode: isTransformMode ?? this.isTransformMode,
      isHighlighter: isHighlighter ?? this.isHighlighter,
      selectedBrushType: selectedBrushType ?? this.selectedBrushType,
      isSmoothingEnabled: isSmoothingEnabled ?? this.isSmoothingEnabled,
      isMovingSelection: isMovingSelection ?? this.isMovingSelection,
      totalSelectionDelta: totalSelectionDelta ?? this.totalSelectionDelta,
      liveScale: liveScale ?? this.liveScale,
      liveRotation: liveRotation ?? this.liveRotation,
      selectedEditingImageId: selectedEditingImageId ?? this.selectedEditingImageId,
      activeHandle: activeHandle ?? this.activeHandle,
      initialPosition: initialPosition ?? this.initialPosition,
      initialSize: initialSize ?? this.initialSize,
      initialRotation: initialRotation ?? this.initialRotation,
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
      lassoPath: null,
      // 🚀 v3.6: Limpar edições ativas ao trocar de ferramenta manualmente
      activeInlineTarget: InlineTarget.none,
      activeTextBlock: null,
      activeTableId: null,
      activeTableCell: null,
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

  void setBrushType(BrushType type) {
    state = state.copyWith(selectedBrushType: type);
  }

  void setSmoothing(bool value) {
    state = state.copyWith(isSmoothingEnabled: value);
  }

  void setTextEditing(InlineTarget target, [TextBlock? block]) {
    state = state.copyWith(
      activeInlineTarget: target,
      activeTextBlock: block,
    );
  }

  void setTableCellEditing(String tableId, String cell) {
    state = state.copyWith(
      activeInlineTarget: InlineTarget.none,
      activeTextBlock: null,
      activeTableId: tableId,
      activeTableCell: cell,
    );
  }

  // 🚀 v3.11: RESET TOTAL E SEGURO (Evita erro de null no copyWith)
  void exitWritingMode() {
    debugPrint('🛡️ [CanvasTool] Reset Atómico do Modo de Escrita...');
    
    // Criamos um estado novo preservando apenas as configurações de desenho
    state = CanvasToolState(
      currentTool: ToolMode.draw,
      selectedColorHex: state.selectedColorHex,
      selectedThickness: state.selectedThickness,
      isHighlighter: state.isHighlighter,
      selectedBrushType: state.selectedBrushType,
      isSmoothingEnabled: state.isSmoothingEnabled,
      // Os campos de edição (activeTextBlock, activeTableId, etc.) voltam ao default (null)
    );
  }

  void clearTextEditing() {
    exitWritingMode();
  }

  void toggleTransformMode() {
    state = state.copyWith(isTransformMode: !state.isTransformMode);
  }

  void setSelectionRect(Offset? start, Offset? end, [LocalPage? page]) {
    state = state.copyWith(
      selectionRectStart: start,
      selectionRectEnd: end,
      lassoPath: null,
    );

    if (start != null && end != null && page != null) {
      final rect = Rect.fromPoints(start, end);
      final newStrokeIds = <String>{};
      final newTextIds = <String>{};
      final newImageIds = <String>{};
      final newShapeIds = <String>{};
      final newAudioIds = <String>{};
      final newAnimationIds = <String>{};
      final newTableIds = <String>{};
      final newLinkIds = <String>{};
      final newAttachmentIds = <String>{};
      
      for (var obj in page.objects) {
        if (obj.isDeleted) continue;
        
        final layer = page.layers.cast<LayerDefinition?>().firstWhere((l) => l?.id == (obj.layerId ?? 'default'), orElse: () => null);
        if (layer?.isLocked ?? false) continue;

        bool intersects = false;
        if (obj is Stroke) {
          intersects = obj.points.any((pt) => rect.contains(pt));
          if (intersects) newStrokeIds.add(obj.id);
        } else {
          final objRect = obj.position & obj.size;
          intersects = rect.overlaps(objRect);
          if (intersects) {
            if (obj is TextBlock) newTextIds.add(obj.id);
            else if (obj is ImageBlock) newImageIds.add(obj.id);
            else if (obj is ShapeObject) newShapeIds.add(obj.id);
            else if (obj is AudioBlock) newAudioIds.add(obj.id);
            else if (obj is AnimationObject) newAnimationIds.add(obj.id);
            else if (obj is TableObject) newTableIds.add(obj.id);
            else if (obj is LinkObject) newLinkIds.add(obj.id);
            else if (obj is AttachmentObject) newAttachmentIds.add(obj.id);
          }
        }
      }

      state = state.copyWith(
        selectedStrokeIds: newStrokeIds,
        selectedTextIds: newTextIds,
        selectedImageIds: newImageIds,
        selectedShapeIds: newShapeIds,
        selectedAudioIds: newAudioIds,
        selectedAnimationIds: newAnimationIds,
        selectedTableIds: newTableIds,
        selectedLinkIds: newLinkIds,
        selectedAttachmentIds: newAttachmentIds,
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
      final newTextIds = <String>{};
      final newImageIds = <String>{};
      final newShapeIds = <String>{};
      final newAudioIds = <String>{};
      final newAnimationIds = <String>{};
      final newTableIds = <String>{};
      final newLinkIds = <String>{};
      final newAttachmentIds = <String>{};

      for (var obj in page.objects) {
        if (obj.isDeleted) continue;

        final layer = page.layers.cast<LayerDefinition?>().firstWhere((l) => l?.id == (obj.layerId ?? 'default'), orElse: () => null);
        if (layer?.isLocked ?? false) continue;

        bool intersects = false;
        if (obj is Stroke) {
          intersects = obj.points.any((pt) => _isPointInPolygon(pt, path));
          if (intersects) newStrokeIds.add(obj.id);
        } else {
          final center = obj.position + Offset(obj.size.width / 2, obj.size.height / 2);
          intersects = _isPointInPolygon(obj.position, path) || _isPointInPolygon(center, path);
          
          if (intersects) {
            if (obj is TextBlock) newTextIds.add(obj.id);
            else if (obj is ImageBlock) newImageIds.add(obj.id);
            else if (obj is ShapeObject) newShapeIds.add(obj.id);
            else if (obj is AudioBlock) newAudioIds.add(obj.id);
            else if (obj is AnimationObject) newAnimationIds.add(obj.id);
            else if (obj is TableObject) newTableIds.add(obj.id);
            else if (obj is LinkObject) newLinkIds.add(obj.id);
            else if (obj is AttachmentObject) newAttachmentIds.add(obj.id);
          }
        }
      }

      state = state.copyWith(
        selectedStrokeIds: newStrokeIds,
        selectedTextIds: newTextIds,
        selectedImageIds: newImageIds,
        selectedShapeIds: newShapeIds,
        selectedAudioIds: newAudioIds,
        selectedAnimationIds: newAnimationIds,
        selectedTableIds: newTableIds,
        selectedLinkIds: newLinkIds,
        selectedAttachmentIds: newAttachmentIds,
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

  void setMovingSelection(bool value) {
    state = state.copyWith(isMovingSelection: value);
  }

  void clearSelection() {
    state = state.copyWith(
      selectedStrokeIds: {},
      selectedTextIds: {},
      selectedImageIds: {},
      selectedShapeIds: {},
      selectedAudioIds: {},
      selectedAnimationIds: {},
      selectedTableIds: {}, 
      selectedLinkIds: {}, 
      selectedAttachmentIds: {}, 
      selectionRectStart: null,
      selectionRectEnd: null,
      lassoPath: null, 
      isTransformMode: false,
      isMovingSelection: false, 
      totalSelectionDelta: Offset.zero,
      liveScale: const Size(1, 1), 
      liveRotation: 0.0, 
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
    Set<String>? shapeIds,
    Set<String>? audioIds,
    Set<String>? animationIds,
    Set<String>? tableIds,
    Set<String>? linkIds,
    Set<String>? attachmentIds,
  }) {
    state = state.copyWith(
      selectedStrokeIds: strokeIds ?? state.selectedStrokeIds,
      selectedTextIds: textIds ?? state.selectedTextIds,
      selectedImageIds: imageIds ?? state.selectedImageIds,
      selectedShapeIds: shapeIds ?? state.selectedShapeIds,
      selectedAudioIds: audioIds ?? state.selectedAudioIds,
      selectedAnimationIds: animationIds ?? state.selectedAnimationIds,
      selectedTableIds: tableIds ?? state.selectedTableIds,
      selectedLinkIds: linkIds ?? state.selectedLinkIds,
      selectedAttachmentIds: attachmentIds ?? state.selectedAttachmentIds,
    );
  }

  void selectAt(Offset localPos, LocalPage page, {bool includeLocked = false}) {
    // 🚀 v2: Prioridade total à seleção atual se o clique for dentro dela
    if (isPointInSelection(localPos, page)) return;

    final objects = page.objects.where((o) => !o.isDeleted).toList()
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));

    for (var obj in objects) {
      if (!includeLocked && obj.isLocked) continue;
      if (!obj.isVisible) continue;

      bool hit = checkHit(localPos, obj);

      if (hit) {
        clearSelection();
        _applySelection(obj);
        return;
      }
    }
    clearSelection();
  }

  bool isPointInSelection(Offset localPos, LocalPage page) {
    final selectedIds = {
      ...state.selectedStrokeIds, ...state.selectedTextIds, ...state.selectedImageIds,
      ...state.selectedShapeIds, ...state.selectedAudioIds, ...state.selectedAnimationIds,
      ...state.selectedTableIds, ...state.selectedLinkIds, ...state.selectedAttachmentIds,
    };
    if (selectedIds.isEmpty) return false;

    for (var id in selectedIds) {
      final obj = page.objects.cast<PageObject?>().firstWhere((o) => o?.id == id, orElse: () => null);
      if (obj != null && checkHit(localPos, obj)) return true;
    }
    return false;
  }

  bool checkHit(Offset localPos, PageObject obj) {
    if (obj is Stroke) {
      return obj.points.any((pt) => (pt - localPos).distance < (obj.thickness + 15));
    } else {
      final bounds = obj.position & obj.size;
      // Área de toque mínima padrão indústria (44px)
      final hitBounds = Rect.fromCenter(
        center: bounds.center, 
        width: bounds.width < 44 ? 44 : bounds.width, 
        height: bounds.height < 44 ? 44 : bounds.height
      );

      if (obj.rotation != 0) {
        final center = hitBounds.center;
        final rotatedPoint = _rotatePoint(localPos, center, -obj.rotation);
        return hitBounds.contains(rotatedPoint);
      } else {
        return hitBounds.contains(localPos);
      }
    }
  }

  void _applySelection(PageObject obj) {
    if (obj is Stroke) selectIds(strokeIds: {obj.id});
    else if (obj is TextBlock) selectIds(textIds: {obj.id});
    else if (obj is ImageBlock) selectIds(imageIds: {obj.id});
    else if (obj is ShapeObject) selectIds(shapeIds: {obj.id});
    else if (obj is AudioBlock) selectIds(audioIds: {obj.id});
    else if (obj is AnimationObject) selectIds(animationIds: {obj.id});
    else if (obj is TableObject) selectIds(tableIds: {obj.id});
    else if (obj is LinkObject) selectIds(linkIds: {obj.id});
    else if (obj is AttachmentObject) selectIds(attachmentIds: {obj.id});
  }

  Offset _rotatePoint(Offset point, Offset center, double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    return Offset(
      center.dx + dx * cosA - dy * sinA,
      center.dy + dx * sinA + dy * cosA,
    );
  }

  void startHandleTransform(HandleType handle, Offset currentPos, Size currentSize, double currentRotation) {
    state = state.copyWith(
      activeHandle: handle,
      initialPosition: currentPos,
      initialSize: currentSize,
      initialRotation: currentRotation,
      liveScale: const Size(1, 1),
      liveRotation: 0,
    );
  }

  void updateLiveTransform({Size? scale, double? rotation}) {
    state = state.copyWith(
      liveScale: scale ?? state.liveScale,
      liveRotation: rotation ?? state.liveRotation,
    );
  }

  void endHandleTransform() {
    state = state.copyWith(
      activeHandle: HandleType.none,
      liveScale: const Size(1, 1),
      liveRotation: 0,
    );
  }
}

final canvasToolProvider = NotifierProvider<CanvasToolNotifier, CanvasToolState>(() {
  return CanvasToolNotifier();
});
