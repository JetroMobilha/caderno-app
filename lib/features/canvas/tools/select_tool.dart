import 'package:flutter/material.dart';
import '../models/local_page_model.dart';
import '../models/canvas_enums.dart';
import '../models/table_model.dart'; 
import '../models/image_block_model.dart'; 
import '../models/stroke_model.dart';
import '../models/page_object.dart';
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
    
    if (_detectHandleHit(localPos, toolState, page, ref) != HandleType.none) return;

    if (toolState.selectedObjectIds.length == 1) {
      final obj = page.objects.firstWhere((o) => o.id == toolState.selectedObjectIds.first);
      if (obj is TableObject && toolState.isTableStructuralMode) {
        if (_detectTableBorderHit(localPos, obj, ref) != null) return;
      }
    }

    toolNotifier.selectAt(localPos, page, includeLocked: mode == ToolMode.organizer);
  }

  @override
  void onPanStart(Offset localPos, dynamic ref, LocalPage page, [double pressure = 0.5]) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasToolProvider);

    if (toolState.selectedObjectIds.length == 1) {
      final obj = page.objects.firstWhere((o) => o.id == toolState.selectedObjectIds.first);
      if (obj is TableObject && !obj.isLocked) {
        final hit = _detectTableBorderHit(localPos, obj, ref);
        if (hit != null) {
          toolNotifier.startTableResize(hit.isVertical ? HandleType.tableColResize : HandleType.tableRowResize, hit.index, localPos);
          return;
        }
        if (toolState.isTableStructuralMode) return; 
      }
    }

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

    if (toolState.activeTableResizeIndex != null) {
      final obj = page.objects.firstWhere((o) => o.id == toolState.selectedObjectIds.first);
      if (obj is TableObject) {
        if (toolState.activeHandle == HandleType.tableColResize) _handleTableColumnResize(obj, toolState.activeTableResizeIndex!, docDelta.dx, ref, page);
        else if (toolState.activeHandle == HandleType.tableRowResize) _handleTableRowResize(obj, toolState.activeTableResizeIndex!, docDelta.dy, ref, page);
        return;
      }
    }

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
    if (toolState.activeTableResizeIndex != null) { toolNotifier.endTableResize(); }
    else if (toolState.activeHandle != HandleType.none) { _finalizeTransform(toolState, ref, toolNotifier, page); toolNotifier.endHandleTransform(); }
    else if (toolState.totalSelectionDelta != Offset.zero) { ref.read(canvasDocumentProvider.notifier).moveSelection(page, objectIds: toolState.selectedObjectIds, delta: toolState.totalSelectionDelta); toolNotifier.resetSelectionDelta(); }
    toolNotifier.setSelectionRect(null, null);
  }

  _TableBorderHit? _detectTableBorderHit(Offset localPos, TableObject table, dynamic ref) {
    final toolState = ref.read(canvasInteractionProvider);
    if (!toolState.isTableStructuralMode) return null;

    final center = (table.position & table.size).center;
    final relPos = TransformService.rotatePoint(localPos, center, -table.rotation) - table.position;
    
    final viewportState = ref.read(canvasViewportProvider);
    final double currentScale = viewportState.currentPageClientId != null 
        ? ref.read(canvasViewportProvider.notifier).getControllerFor(viewportState.currentPageClientId!).value.getMaxScaleOnAxis()
        : 1.0;
    
    final double tolerance = 35.0 / currentScale;

    double currentX = 0;
    for (int i = 0; i < table.columnWidths.length - 1; i++) {
      currentX += table.columnWidths[i];
      if ((relPos.dx - currentX).abs() < tolerance && (relPos.dy + 35 / currentScale).abs() < tolerance) {
        return _TableBorderHit(i, true);
      }
    }

    double currentY = 0;
    for (int i = 0; i < table.rowHeights.length - 1; i++) {
      currentY += table.rowHeights[i];
      if ((relPos.dy - currentY).abs() < tolerance && (relPos.dx + 35 / currentScale).abs() < tolerance) {
        return _TableBorderHit(i, false);
      }
    }
    return null;
  }

  void _handleTableColumnResize(TableObject table, int index, double deltaX, dynamic ref, LocalPage page) {
    if (deltaX == 0) return;
    final List<double> newWidths = List.from(table.columnWidths);
    newWidths[index] = (newWidths[index] + deltaX).clamp(30.0, 1500.0);
    ref.read(canvasDocumentProvider.notifier).updateObject(page, table.copyWith(columnWidths: newWidths));
  }

  void _handleTableRowResize(TableObject table, int index, double deltaY, dynamic ref, LocalPage page) {
    if (deltaY == 0) return;
    final List<double> newHeights = List.from(table.rowHeights);
    newHeights[index] = (newHeights[index] + deltaY).clamp(20.0, 1000.0);
    ref.read(canvasDocumentProvider.notifier).updateObject(page, table.copyWith(rowHeights: newHeights));
  }

  HandleType _detectHandleHit(Offset localPos, CanvasToolState toolState, LocalPage page, dynamic ref) {
    if (toolState.selectedObjectIds.isEmpty || toolState.isTableStructuralMode) return HandleType.none;
    final selectedObjects = page.objects.where((o) => toolState.selectedObjectIds.contains(o.id)).toList();
    if (selectedObjects.isEmpty || (selectedObjects.any((o) => o.isLocked) && mode != ToolMode.organizer)) return HandleType.none;
    
    final bool canResize = selectedObjects.length == 1 && (selectedObjects.first.type == 'image' || 
                           selectedObjects.first.type == 'shape' || 
                           selectedObjects.first.type == 'table');
                           
    if (selectedObjects.length != 1 || !canResize) return HandleType.none;

    final Rect bounds = TransformService.getCombinedBounds(selectedObjects);
    final double rotation = selectedObjects.first.rotation;
    
    final viewportState = ref.read(canvasViewportProvider);
    final double currentScale = viewportState.currentPageClientId != null 
        ? ref.read(canvasViewportProvider.notifier).getControllerFor(viewportState.currentPageClientId!).value.getMaxScaleOnAxis()
        : 1.0;
    
    final double hSize = 35.0 / currentScale; 
    
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
    // Corrigido distanceTo para distance
    if ((rotatedHitPoint - Offset(bounds.center.dx, bounds.top - (45 / currentScale))).distance < hSize) return HandleType.rotate;

    if (toolState.isImageCropping) {
      if ((rotatedHitPoint - bounds.topLeft).distance < hSize) return HandleType.cropTopLeft;
      if ((rotatedHitPoint - bounds.topRight).distance < hSize) return HandleType.cropTopRight;
      if ((rotatedHitPoint - bounds.bottomLeft).distance < hSize) return HandleType.cropBottomLeft;
      if ((rotatedHitPoint - bounds.bottomRight).distance < hSize) return HandleType.cropBottomRight;
      if ((rotatedHitPoint - Offset(bounds.center.dx, bounds.top)).distance < hSize) return HandleType.cropTopCenter;
      if ((rotatedHitPoint - Offset(bounds.center.dx, bounds.bottom)).distance < hSize) return HandleType.cropBottomCenter;
      if ((rotatedHitPoint - Offset(bounds.left, bounds.center.dy)).distance < hSize) return HandleType.cropMiddleLeft;
      if ((rotatedHitPoint - Offset(bounds.right, bounds.center.dy)).distance < hSize) return HandleType.cropMiddleRight;
    }

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

    if ([HandleType.cropTopLeft, HandleType.cropTopCenter, HandleType.cropTopRight, 
         HandleType.cropMiddleLeft, HandleType.cropMiddleRight, 
         HandleType.cropBottomLeft, HandleType.cropBottomCenter, HandleType.cropBottomRight].contains(toolState.activeHandle)) {
      _performCropTransform(delta, toolState, toolNotifier, page, ref);
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

  void _performCropTransform(Offset delta, CanvasToolState toolState, CanvasToolNotifier toolNotifier, LocalPage page, dynamic ref) {
    if (toolState.selectedObjectIds.length != 1) return;
    final obj = page.objects.firstWhere((o) => o.id == toolState.selectedObjectIds.first);
    if (obj is! ImageBlock) return;

    Rect crop = obj.cropRect ?? const Rect.fromLTWH(0, 0, 1, 1);
    double nDX = delta.dx * crop.width / obj.width;
    double nDY = delta.dy * crop.height / obj.height;

    double l = crop.left, t = crop.top, w = crop.width, h = crop.height;
    double dx = 0, dy = 0, dw = 0, dh = 0;

    final hType = toolState.activeHandle;
    if (hType == HandleType.cropTopLeft || hType == HandleType.cropMiddleLeft || hType == HandleType.cropBottomLeft) {
      double actualNDX = nDX.clamp(-l, w - 0.1);
      l += actualNDX; w -= actualNDX; dx = actualNDX * obj.width / crop.width; dw = -dx;
    }
    if (hType == HandleType.cropTopRight || hType == HandleType.cropMiddleRight || hType == HandleType.cropBottomRight) {
      double actualNDX = nDX.clamp(-(w - 0.1), 1.0 - (l + w));
      w += actualNDX; dw = actualNDX * obj.width / crop.width;
    }
    if (hType == HandleType.cropTopLeft || hType == HandleType.cropTopCenter || hType == HandleType.cropTopRight) {
      double actualNDY = nDY.clamp(-t, h - 0.1);
      t += actualNDY; h -= actualNDY; dy = actualNDY * obj.height / crop.height; dh = -dy;
    }
    if (hType == HandleType.cropBottomLeft || hType == HandleType.cropBottomCenter || hType == HandleType.cropBottomRight) {
      double actualNDY = nDY.clamp(-(h - 0.1), 1.0 - (t + h));
      h += actualNDY; dh = actualNDY * obj.height / crop.height;
    }

    final updated = obj.copyWith(
      cropRect: Rect.fromLTWH(l, t, w, h),
      position: obj.position + Offset(dx, dy),
      size: Size(obj.width + dw, obj.height + dh),
    );
    ref.read(canvasDocumentProvider.notifier).updateObject(page, updated);
  }

  bool _isAnySelectedLocked(CanvasToolState toolState, LocalPage page) => page.objects.any((o) => toolState.selectedObjectIds.contains(o.id) && o.isLocked);
}

class _TableBorderHit {
  final int index;
  final bool isVertical; 
  _TableBorderHit(this.index, this.isVertical);
}
