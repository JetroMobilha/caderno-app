import 'package:flutter/material.dart';
import '../models/local_page_model.dart';
import '../models/canvas_enums.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_viewport_provider.dart';
import '../services/transform_service.dart';
import 'canvas_tool.dart';

class SelectTool extends CanvasTool {
  const SelectTool([super.mode = ToolMode.select]);

  @override
  void onTapDown(Offset localPos, dynamic ref, LocalPage page) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasToolProvider);
    if (toolState.isTransformMode && _detectHandleHit(localPos, toolState, page, ref) != HandleType.none) return;
    toolNotifier.selectAt(localPos, page, includeLocked: mode == ToolMode.organizer);
  }

  @override
  void onPanStart(Offset localPos, dynamic ref, LocalPage page, [double pressure = 0.5]) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasToolProvider);
    final hitHandle = _detectHandleHit(localPos, toolState, page, ref);
    if (hitHandle != HandleType.none) {
      final selectedObjects = page.objects.where((o) => toolState.selectedObjectIds.contains(o.id)).toList();
      final bounds = TransformService.getCombinedBounds(selectedObjects);
      toolNotifier.startHandleTransform(hitHandle, localPos, bounds.size, selectedObjects.length == 1 ? selectedObjects.first.rotation : 0.0);
      return;
    }
    if (toolNotifier.isPointInSelection(localPos, page)) {
      if (!_isAnySelectedLocked(toolState, page) || mode == ToolMode.organizer) {
        toolNotifier.setMovingSelection(true);
      }
      return;
    }
    if (mode != ToolMode.organizer) {
      toolNotifier.clearSelection();
      toolNotifier.setSelectionRect(localPos, localPos, page);
    } else {
      toolNotifier.selectAt(localPos, page, includeLocked: true);
      if (toolNotifier.isPointInSelection(localPos, page)) toolNotifier.setMovingSelection(true);
    }
  }

  @override
  void onPanUpdate(Offset localPos, Offset delta, dynamic ref, LocalPage page, [double pressure = 0.5]) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasToolProvider);
    final Offset docDelta = ref.read(canvasViewportProvider.notifier).screenDeltaToDocumentDelta(delta);
    if (toolState.activeHandle != HandleType.none) { 
      _performHandleTransform(localPos, docDelta, toolState, toolNotifier, page, ref); 
      return; 
    }
    if (toolState.isMovingSelection) { 
      toolNotifier.updateSelectionDelta(docDelta); 
      return; 
    }
    if (toolState.selectionRectStart != null) { 
      toolNotifier.setSelectionRect(toolState.selectionRectStart, localPos, page); 
    }
  }

  @override
  void onPanEnd(dynamic ref, LocalPage page) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasToolProvider);
    if (toolState.activeHandle != HandleType.none) { _finalizeTransform(toolState, ref, toolNotifier, page); toolNotifier.endHandleTransform(); }
    else if (toolState.totalSelectionDelta != Offset.zero) { ref.read(canvasDocumentProvider.notifier).moveSelection(page, objectIds: toolState.selectedObjectIds, delta: toolState.totalSelectionDelta); toolNotifier.resetSelectionDelta(); }
    toolNotifier.setSelectionRect(null, null);
  }

  HandleType _detectHandleHit(Offset localPos, CanvasToolState toolState, LocalPage page, dynamic ref) {
    if (toolState.selectedObjectIds.isEmpty || !toolState.isTransformMode) return HandleType.none;
    final selectedObjects = page.objects.where((o) => toolState.selectedObjectIds.contains(o.id)).toList();
    if (selectedObjects.isEmpty || (selectedObjects.any((o) => o.isLocked) && mode != ToolMode.organizer)) return HandleType.none;
    
    final Rect bounds = TransformService.getCombinedBounds(selectedObjects);
    final double rotation = selectedObjects.length == 1 ? selectedObjects.first.rotation : 0.0;
    
    // 🚀 v10.10: Hit area dinâmica baseada no Zoom
    final viewportState = ref.read(canvasViewportProvider);
    final double currentScale = viewportState.currentPageClientId != null 
        ? ref.read(canvasViewportProvider.notifier).getControllerFor(viewportState.currentPageClientId!).value.getMaxScaleOnAxis()
        : 1.0;
    
    // Queremos 30 pixels físicos de tolerância, convertidos para unidades de documento
    final double hSize = 30.0 / currentScale; 
    
    final center = bounds.center;
    final rotatedHitPoint = TransformService.rotatePoint(localPos, center, -rotation);
    
    if ((rotatedHitPoint - bounds.topLeft).distance < hSize) return HandleType.topLeft;
    if ((rotatedHitPoint - bounds.topRight).distance < hSize) return HandleType.topRight;
    if ((rotatedHitPoint - bounds.bottomLeft).distance < hSize) return HandleType.bottomLeft;
    if ((rotatedHitPoint - bounds.bottomRight).distance < hSize) return HandleType.bottomRight;
    if ((rotatedHitPoint - Offset(bounds.center.dx, bounds.top)).distance < hSize) return HandleType.topCenter;
    if ((rotatedHitPoint - Offset(bounds.center.dx, bounds.bottom)).distance < hSize) return HandleType.bottomCenter;
    if ((rotatedHitPoint - Offset(bounds.left, bounds.center.dy)).distance < hSize) return HandleType.middleLeft;
    if ((rotatedHitPoint - Offset(bounds.right, bounds.center.dy)).distance < hSize) return HandleType.middleRight;
    if ((rotatedHitPoint - Offset(bounds.center.dx, bounds.top - (40 / currentScale))).distance < hSize) return HandleType.rotate;
    return HandleType.none;
  }

  void _performHandleTransform(Offset localPos, Offset delta, CanvasToolState toolState, CanvasToolNotifier toolNotifier, LocalPage page, dynamic ref) {
    if (toolState.activeHandle == HandleType.rotate) {
      final selectedObjects = page.objects.where((o) => toolState.selectedObjectIds.contains(o.id)).toList();
      if (selectedObjects.length != 1) return;
      final obj = selectedObjects.first;
      final double newRotation = TransformService.calculateRotation(object: obj, currentLocalPos: localPos);
      toolNotifier.updateLiveTransform(rotation: newRotation - obj.rotation);
      return;
    }
    final totalDelta = localPos - toolState.initialPosition;
    if (toolState.activeHandle == HandleType.bottomRight) {
       toolNotifier.updateLiveTransform(scale: Size(((toolState.initialSize.width + totalDelta.dx) / toolState.initialSize.width).clamp(0.1, 10.0), ((toolState.initialSize.height + totalDelta.dy) / toolState.initialSize.height).clamp(0.1, 10.0)));
    } else {
       if (toolState.selectedObjectIds.length == 1) {
          final obj = page.objects.firstWhere((o) => o.id == toolState.selectedObjectIds.first);
          final updatedObj = TransformService.calculateResize(object: obj, handle: toolState.activeHandle, delta: delta);
          if (updatedObj != null) ref.read(canvasDocumentProvider.notifier).updateObject(page, updatedObj);
       }
    }
  }

  void _finalizeTransform(CanvasToolState toolState, dynamic ref, CanvasToolNotifier toolNotifier, LocalPage page) {
    if (toolState.selectedObjectIds.length == 1) {
      final obj = page.objects.firstWhere((o) => o.id == toolState.selectedObjectIds.first);
      if (toolState.liveRotation != 0 || toolState.liveScale != const Size(1, 1)) {
        ref.read(canvasDocumentProvider.notifier).updateObject(page, obj.copyWith(rotation: obj.rotation + toolState.liveRotation, size: Size(obj.size.width * toolState.liveScale.width, obj.size.height * toolState.liveScale.height)));
      }
    }
  }

  bool _isAnySelectedLocked(CanvasToolState toolState, LocalPage page) => page.objects.any((o) => toolState.selectedObjectIds.contains(o.id) && o.isLocked);
}
