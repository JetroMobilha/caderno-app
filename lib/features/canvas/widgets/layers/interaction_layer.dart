import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/table_model.dart';
import '../../models/table_types.dart'; // 🚀 v9.7
import '../../providers/canvas_tool_provider.dart';
import '../../providers/canvas_document_provider.dart';
import '../../providers/canvas_viewport_provider.dart';
import '../../models/local_page_model.dart';
import '../../models/stroke_model.dart';
import '../../models/canvas_enums.dart';
import '../../providers/canvas_ui_provider.dart';
import '../../widgets/canvas_painter.dart';
import '../../services/transform_service.dart'; // 🚀 v10
import '../../models/page_object.dart';
import '../../models/text_block_model.dart';

class InteractionLayer extends ConsumerStatefulWidget {
  final LocalPage page;
  final bool isBlocked;
  final VoidCallback onFinishEditing;
  final Function(Offset) onAddTextBlock;
  final VoidCallback onTitleTap;

  const InteractionLayer({
    super.key,
    required this.page,
    required this.isBlocked,
    required this.onFinishEditing,
    required this.onAddTextBlock,
    required this.onTitleTap,
  });

  @override
  ConsumerState<InteractionLayer> createState() => _InteractionLayerState();
}

class _InteractionLayerState extends ConsumerState<InteractionLayer> {
  String? _liveStrokeId;
  final ValueNotifier<List<Offset>> _activePoints = ValueNotifier([]);
  Timer? _broadcastThrottle;

  void _throttledBroadcast(String id, List<Offset> points, CanvasToolState toolState) {
    if (_broadcastThrottle?.isActive ?? false) return;
    _broadcastThrottle = Timer(const Duration(milliseconds: 50), () {
      ref.read(canvasDocumentProvider.notifier).broadcastLiveStroke(
        pageClientId: widget.page.clientId,
        pageNumber: widget.page.pageNumber,
        strokeId: id,
        points: points,
        color: toolState.selectedColorHex,
        thickness: toolState.selectedThickness,
        isHighlighter: toolState.isHighlighter,
        brushType: toolState.selectedBrushType,
        isSmoothed: toolState.isSmoothingEnabled,
      );
    });
  }

  HandleType _detectHandleHit(Offset localPos, CanvasToolState toolState) {
    final selectedIds = {...toolState.selectedTextIds, ...toolState.selectedImageIds, ...toolState.selectedTableIds};
    if (selectedIds.length != 1) return HandleType.none;
    final obj = widget.page.objects.where((o) => selectedIds.contains(o.id)).firstOrNull;
    if (obj == null) return HandleType.none;
    final center = (obj.position & obj.size).center;
    final rotatedHitPoint = _rotatePoint(localPos, center, -obj.rotation);
    final bounds = obj.position & obj.size;
    const double hSize = 35.0; 
    if ((rotatedHitPoint - bounds.topLeft).distance < hSize) return HandleType.topLeft;
    if ((rotatedHitPoint - bounds.topRight).distance < hSize) return HandleType.topRight;
    if ((rotatedHitPoint - bounds.bottomLeft).distance < hSize) return HandleType.bottomLeft;
    if ((rotatedHitPoint - bounds.bottomRight).distance < hSize) return HandleType.bottomRight;
    if ((rotatedHitPoint - Offset(bounds.center.dx, bounds.top)).distance < hSize) return HandleType.topCenter;
    if ((rotatedHitPoint - Offset(bounds.center.dx, bounds.bottom)).distance < hSize) return HandleType.bottomCenter;
    if ((rotatedHitPoint - Offset(bounds.left, bounds.center.dy)).distance < hSize) return HandleType.middleLeft;
    if ((rotatedHitPoint - Offset(bounds.right, bounds.center.dy)).distance < hSize) return HandleType.middleRight;
    if ((rotatedHitPoint - Offset(bounds.center.dx, bounds.top - 40)).distance < hSize) return HandleType.rotate;
    return HandleType.none;
  }

  void _performHandleTransform(Offset localPos, Offset delta, CanvasToolState toolState, CanvasToolNotifier toolNotifier) {
    final selectedIds = toolState.selectedObjectIds;
    if (selectedIds.length != 1) return;
    final obj = widget.page.objects.where((o) => selectedIds.contains(o.id)).firstOrNull;
    if (obj == null) return;

    if (toolState.activeHandle == HandleType.rotate) {
      final double newRotation = TransformService.calculateRotation(object: obj, currentLocalPos: localPos);
      toolNotifier.updateLiveTransform(rotation: newRotation - obj.rotation);
      return;
    }

    final totalDelta = localPos - toolState.initialPosition;
    if (toolState.activeHandle == HandleType.bottomRight) {
       toolNotifier.updateLiveTransform(scale: Size(((toolState.initialSize.width + totalDelta.dx) / toolState.initialSize.width).clamp(0.1, 10.0), ((toolState.initialSize.height + totalDelta.dy) / toolState.initialSize.height).clamp(0.1, 10.0)));
    } else {
       final updatedObj = TransformService.calculateResize(object: obj, handle: toolState.activeHandle, delta: delta, keepAspectRatio: false);
       if (updatedObj != null) ref.read(canvasDocumentProvider.notifier).updateObject(widget.page, updatedObj);
    }
  }

  Offset _rotatePoint(Offset point, Offset center, double angle) => TransformService.rotatePoint(point, center, angle);

  @override
  Widget build(BuildContext context) {
    final toolState = ref.watch(canvasToolProvider);
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final docNotifier = ref.read(canvasDocumentProvider.notifier);
    final viewportState = ref.watch(canvasViewportProvider);

    // 🚀 v9.9: Limpeza agressiva se detetado multi-toque
    if (viewportState.activePointerCount > 1 && _liveStrokeId != null) {
      _liveStrokeId = null;
      _activePoints.value = [];
    }

    // 🚀 v9.8: Limpeza de segurança se o Pan foi ativado durante um traço
    if (toolState.currentTool == ToolMode.pan && _liveStrokeId != null) {
      Future.microtask(() {
        if (mounted) {
          setState(() {
            _activePoints.value = [];
            _liveStrokeId = null;
          });
        }
      });
    }

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: toolState.currentTool == ToolMode.pan || toolState.currentTool == ToolMode.imageEdit || viewportState.activePointerCount > 1,
        child: Stack(
          children: [
            GestureDetector(
              key: ValueKey('gesture_${viewportState.activePointerCount > 1}'), // 🚀 v9.9: Key dinâmica mata o recognizer no multi-toque
              behavior: HitTestBehavior.translucent,
              onPanCancel: () {
                ref.read(canvasUiProvider.notifier).setHudMode(false);
              },
              onTapDown: !widget.isBlocked && viewportState.activePointerCount <= 1 ? (details) {
                final bool wasEditing = toolState.activeInlineTarget != InlineTarget.none || toolState.activeTableCell != null;
                if (toolState.isTransformMode) {
                  final hit = _findHitObject(details.localPosition, toolNotifier);
                  if (hit != null) {
                     if (!(toolState.selectedTableIds.contains(hit.id) || toolState.selectedTextIds.contains(hit.id))) toolNotifier.selectAt(details.localPosition, widget.page);
                     return;
                  } else if (_detectHandleHit(details.localPosition, toolState) == HandleType.none) return;
                }
                if (_isTitleHit(details.localPosition)) { widget.onTitleTap(); return; }
                final hitObj = _findHitObject(details.localPosition, toolNotifier, includeLocked: toolState.currentTool == ToolMode.organizer || toolState.currentTool == ToolMode.text);
                if (hitObj is TextBlock && hitObj.listType == ListType.checklist) {
                  if (_tryToggleChecklist(hitObj, details.localPosition)) { docNotifier.updateObject(widget.page, hitObj); return; }
                }
                if (toolState.currentTool == ToolMode.select || toolState.currentTool == ToolMode.lasso || toolState.currentTool == ToolMode.organizer) {
                   if (toolState.currentTool != ToolMode.organizer && _detectHandleHit(details.localPosition, toolState) != HandleType.none) return;
                   toolNotifier.selectAt(details.localPosition, widget.page, includeLocked: toolState.currentTool == ToolMode.organizer);
                }
                if (toolState.currentTool == ToolMode.eraser) _handleObjectEraser(details.localPosition, toolState, toolNotifier, docNotifier);
                if (toolState.currentTool == ToolMode.text) {
                  if (toolState.isTransformMode) return;
                  if (hitObj is TextBlock) toolNotifier.setTextEditing(InlineTarget.block, hitObj);
                  else if (hitObj is TableObject) {
                     final coords = _findCellAt(details.localPosition, hitObj);
                     if (coords != null) toolNotifier.setTableCellEditing(hitObj, coords);
                  } else if (!wasEditing) widget.onAddTextBlock(details.localPosition);
                }
                if (toolState.currentTool == ToolMode.table) {
                  if (hitObj is TableObject) {
                    toolNotifier.selectIds(tableIds: {hitObj.id});
                    final coords = _findCellAt(details.localPosition, hitObj);
                    if (coords != null) toolNotifier.setTableCellEditing(hitObj, coords);
                  }
                }
              } : null,
              onPanStart: !widget.isBlocked && viewportState.activePointerCount <= 1 ? (d) {
                ref.read(canvasUiProvider.notifier).setHudMode(true);
                final hitHandle = toolState.currentTool == ToolMode.organizer ? HandleType.none : _detectHandleHit(d.localPosition, toolState);
                if (toolState.isTransformMode && hitHandle == HandleType.none) {
                   final hit = _findHitObject(d.localPosition, toolNotifier, includeLocked: true);
                   if (hit != null) {
                      if (!(toolState.selectedTableIds.contains(hit.id) || toolState.selectedTextIds.contains(hit.id))) toolNotifier.selectAt(d.localPosition, widget.page, includeLocked: true);
                      toolNotifier.setMovingSelection(true); return;
                   }
                }
                if (hitHandle != HandleType.none) {
                  final obj = widget.page.objects.where((o) => (o.id == toolState.activeTableId || toolState.selectedTextIds.contains(o.id) || toolState.selectedImageIds.contains(o.id))).firstOrNull;
                  if (obj != null && !obj.isLocked) toolNotifier.startHandleTransform(hitHandle, obj.position, obj.size, obj.rotation);
                  return;
                }
                if ((toolState.isTransformMode || (toolState.selectedTableIds.isEmpty && toolState.selectedTextIds.isEmpty)) && toolNotifier.isPointInSelection(d.localPosition, widget.page)) {
                  if (toolState.currentTool == ToolMode.eraser) { _handleObjectEraser(d.localPosition, toolState, toolNotifier, docNotifier); return; }
                  if (!_isAnySelectedLocked(toolState, widget.page) || toolState.currentTool == ToolMode.organizer) { toolNotifier.setMovingSelection(true); return; }
                }
                if (toolState.currentTool == ToolMode.draw) { toolNotifier.clearSelection(); _liveStrokeId = const Uuid().v4(); _activePoints.value = [d.localPosition]; }
                else if (toolState.currentTool == ToolMode.select) toolNotifier.setSelectionRect(d.localPosition, d.localPosition, widget.page);
                else if (toolState.currentTool == ToolMode.lasso) { toolNotifier.clearSelection(); toolNotifier.setLassoPath([d.localPosition], widget.page); }
                else if (toolState.currentTool == ToolMode.organizer) {
                  final hit = _findHitObject(d.localPosition, toolNotifier, includeLocked: true);
                  if (hit != null) { toolNotifier.selectAt(d.localPosition, widget.page, includeLocked: true); toolNotifier.setMovingSelection(true); }
                }
                else if ((toolState.currentTool == ToolMode.table || (toolState.currentTool == ToolMode.select && !toolState.isTransformMode)) && !toolState.isTransformMode) {
                  final table = widget.page.objects.whereType<TableObject>().where((t) => toolState.selectedTableIds.contains(t.id)).firstOrNull;
                  if (table != null) {
                    final coords = _findCellAt(d.localPosition, table);
                    if (coords != null) toolNotifier.updateTableSelectionRange(coords, table);
                  }
                }
              } : null,
              onPanUpdate: !widget.isBlocked && viewportState.activePointerCount <= 1 ? (d) {
                if (toolState.activeHandle != HandleType.none) { _performHandleTransform(d.localPosition, d.delta, toolState, toolNotifier); return; }
                if (toolState.isMovingSelection) { toolNotifier.updateSelectionDelta(d.delta); return; }
                if (toolState.currentTool == ToolMode.draw) {
                  _activePoints.value = [..._activePoints.value, d.localPosition];
                  if (_liveStrokeId != null) _throttledBroadcast(_liveStrokeId!, _activePoints.value, toolState);
                } else if (toolState.currentTool == ToolMode.select) {
                  if (toolState.selectedStrokeIds.isNotEmpty || toolState.selectedTextIds.isNotEmpty || toolState.selectedTableIds.isNotEmpty) toolNotifier.updateSelectionDelta(d.delta);
                  else toolNotifier.setSelectionRect(toolState.selectionRectStart, d.localPosition, widget.page);
                } else if (toolState.currentTool == ToolMode.lasso) { toolNotifier.setLassoPath([...(toolState.lassoPath ?? []), d.localPosition], widget.page); }
                else if ((toolState.currentTool == ToolMode.table || (toolState.currentTool == ToolMode.select && !toolState.isTransformMode)) && !toolState.isTransformMode) {
                  final TableObject? table = widget.page.objects.whereType<TableObject>().where((t) => toolState.selectedTableIds.contains(t.id)).firstOrNull;
                  if (table != null) {
                    final coords = _findCellAt(d.localPosition, table);
                    if (coords != null) toolNotifier.updateTableSelectionRange(coords, table);
                  }
                }
              } : null,
              onPanEnd: !widget.isBlocked ? (_) {
                ref.read(canvasUiProvider.notifier).setHudMode(false);
                if (toolState.activeHandle != HandleType.none) {
                  final selectedIds = {...toolState.selectedTextIds, ...toolState.selectedImageIds, ...toolState.selectedTableIds};
                  if (selectedIds.length == 1) {
                    final obj = widget.page.objects.firstWhere((o) => selectedIds.contains(o.id));
                    docNotifier.updateObject(widget.page, obj.copyWith(rotation: obj.rotation + toolState.liveRotation, size: toolState.liveScale != const Size(1, 1) ? Size(obj.size.width * toolState.liveScale.width, obj.size.height * toolState.liveScale.height) : obj.size));
                  }
                  toolNotifier.endHandleTransform(); return;
                }
                if (toolState.currentTool == ToolMode.draw && _liveStrokeId != null && _activePoints.value.isNotEmpty) {
                  docNotifier.addStroke(widget.page, Stroke(id: _liveStrokeId!, color: toolState.selectedColorHex, thickness: toolState.selectedThickness, points: List.from(_activePoints.value), isHighlighter: toolState.isHighlighter, brushType: toolState.selectedBrushType, isSmoothed: toolState.isSmoothingEnabled));
                  _activePoints.value = []; _liveStrokeId = null;
                } else if (toolState.totalSelectionDelta != Offset.zero) {
                    docNotifier.moveSelection(widget.page, strokeIds: toolState.selectedStrokeIds.toList(), textIds: toolState.selectedTextIds.toList(), imageIds: toolState.selectedImageIds.toList(), shapeIds: toolState.selectedShapeIds.toList(), audioIds: toolState.selectedAudioIds.toList(), animationIds: toolState.selectedAnimationIds.toList(), tableIds: toolState.selectedTableIds.toList(), linkIds: toolState.selectedLinkIds.toList(), attachmentIds: toolState.selectedAttachmentIds.toList(), delta: toolState.totalSelectionDelta);
                    toolNotifier.resetSelectionDelta();
                }
              } : null,
            ),
            RepaintBoundary(
              child: ValueListenableBuilder<List<Offset>>(
                valueListenable: _activePoints,
                builder: (context, points, _) => points.isEmpty ? const SizedBox.shrink() : CustomPaint(size: Size.infinite, painter: ActiveStrokePainter(currentPoints: points, visualColor: Color(int.parse(toolState.selectedColorHex.replaceFirst('#', '0xFF'))), currentThickness: toolState.selectedThickness, isHighlighter: toolState.isHighlighter, brushType: toolState.selectedBrushType, isSmoothed: toolState.isSmoothingEnabled)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isAnySelectedLocked(CanvasToolState toolState, LocalPage page) {
    final selectedIds = {...toolState.selectedStrokeIds, ...toolState.selectedTextIds, ...toolState.selectedTableIds};
    return page.objects.any((o) => selectedIds.contains(o.id) && o.isLocked);
  }

  bool _tryToggleChecklist(TextBlock block, Offset localPos) {
    final center = (block.position & block.size).center;
    final relPos = _rotatePoint(localPos, center, -block.rotation) - block.position;
    if (relPos.dx < -10 || relPos.dx > 45) return false;
    final int lineIdx = (relPos.dy / (block.fontSize * block.lineHeight)).floor();
    final lines = block.text.split('\n');
    if (lineIdx >= 0 && lineIdx < lines.length) {
      final List<int> newIndices = List.from(block.checkedLineIndices);
      if (newIndices.contains(lineIdx)) newIndices.remove(lineIdx); else newIndices.add(lineIdx);
      ref.read(canvasDocumentProvider.notifier).updateObject(widget.page, block.copyWith(checkedLineIndices: newIndices));
      return true;
    }
    return false;
  }

  bool _isTitleHit(Offset localPos) => localPos.dy > 20 && localPos.dy < 90 && localPos.dx > (widget.page.pageWidthPx * 0.2) && localPos.dx < (widget.page.pageWidthPx * 0.8);

  PageObject? _findHitObject(Offset localPos, CanvasToolNotifier toolNotifier, {bool includeLocked = false}) {
    final objects = widget.page.objects.where((o) => !o.isDeleted).toList()..sort((a, b) => b.zIndex.compareTo(a.zIndex));
    for (var obj in objects) {
      if ((!includeLocked && obj.isLocked) || !obj.isVisible) continue;
      if (toolNotifier.checkHit(localPos, obj) || (obj is TextBlock && Rect.fromCenter(center: (obj.position & obj.size).center, width: obj.size.width + 20, height: obj.size.height + 20).contains(localPos))) return obj;
    }
    return null;
  }

  CellCoordinate? _findCellAt(Offset localPos, TableObject table) {
    final center = (table.position & table.size).center;
    final relPos = _rotatePoint(localPos, center, -table.rotation) - table.position;
    if (relPos.dx < -25 || relPos.dx > table.size.width + 25 || relPos.dy < -25 || relPos.dy > table.size.height + 25) return null;
    final double cx = relPos.dx.clamp(0.0, table.size.width - 0.1), cy = relPos.dy.clamp(0.0, table.size.height - 0.1);
    double cw = 0; int col = -1; for (int i = 0; i < table.columnWidths.length; i++) { cw += table.columnWidths[i]; if (cx <= cw) { col = i; break; } }
    double ch = 0; int row = -1; for (int i = 0; i < table.rowHeights.length; i++) { ch += table.rowHeights[i]; if (cy <= ch) { row = i; break; } }
    return (row != -1 && col != -1) ? table.resolveMasterCell(row, col) : null;
  }

  void _handleObjectEraser(Offset localPos, CanvasToolState toolState, CanvasToolNotifier toolNotifier, CanvasDocumentNotifier docNotifier) {
    if (toolNotifier.isPointInSelection(localPos, widget.page)) {
      final selectedIds = {...toolState.selectedStrokeIds, ...toolState.selectedTextIds, ...toolState.selectedTableIds};
      if (selectedIds.isNotEmpty) { docNotifier.deleteObjects(widget.page, selectedIds.toList()); toolNotifier.clearSelection(); return; }
    }
    final objects = widget.page.objects.where((o) => !o.isDeleted).toList()..sort((a, b) => b.zIndex.compareTo(a.zIndex));
    for (var obj in objects) { if (!obj.isLocked && obj.isVisible && toolNotifier.checkHit(localPos, obj)) { docNotifier.deleteObjects(widget.page, [obj.id]); return; } }
  }
}
