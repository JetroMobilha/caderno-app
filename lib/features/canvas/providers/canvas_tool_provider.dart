import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../models/local_page_model.dart';
import '../models/table_model.dart';
import '../models/page_object.dart';
import '../models/table_types.dart';
import '../models/canvas_enums.dart';
import '../models/canvas_action_model.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_viewport_provider.dart';

enum HandleType { none, topLeft, topCenter, topRight, middleRight, bottomRight, bottomCenter, bottomLeft, middleLeft, rotate }

/// 🚀 v10.1: Estado de Interação com Suporte a Grupos e Hierarquia.
class CanvasInteractionState {
  final ToolMode activeTool;
  final ToolMode? previousTool;
  final CanvasInteractionStateMode interactionMode;
  
  final String selectedColorHex;
  final double selectedThickness;
  final BrushType selectedBrushType;
  final bool isHighlighter;
  final bool isSmoothingEnabled;

  final Set<String> selectedObjectIds;
  final Set<TableCellKey> selectedTableCells;
  
  final InlineTarget activeInlineTarget;
  final TextBlock? activeTextBlock;
  final String? activeTableId;
  final TableCellKey? activeTableCell;
  
  final TableCellKey? tableSelectionStart;
  final TableCellKey? tableSelectionEnd;

  final Offset? selectionRectStart;
  final Offset? selectionRectEnd;
  final List<Offset>? lassoPath; 

  final bool isTransformMode;
  final bool isMovingSelection;
  final Offset totalSelectionDelta;
  final Size liveScale; 
  final double liveRotation; 
  final String? selectedEditingImageId;
  final HandleType activeHandle; 
  final Offset initialPosition; 
  final Size initialSize; 
  final double initialRotation;

  CanvasInteractionState({
    this.activeTool = ToolMode.draw,
    this.previousTool,
    this.interactionMode = CanvasInteractionStateMode.idle,
    this.selectedColorHex = '#2C3E50',
    this.selectedThickness = 3.0,
    this.selectedBrushType = BrushType.gel,
    this.isHighlighter = false,
    this.isSmoothingEnabled = false,
    this.selectedObjectIds = const {},
    this.selectedTableCells = const {},
    this.activeInlineTarget = InlineTarget.none,
    this.activeTextBlock,
    this.activeTableId,
    this.activeTableCell,
    this.tableSelectionStart,
    this.tableSelectionEnd,
    this.selectionRectStart,
    this.selectionRectEnd,
    this.lassoPath, 
    this.isTransformMode = false,
    this.isMovingSelection = false,
    this.totalSelectionDelta = Offset.zero,
    this.liveScale = const Size(1, 1),
    this.liveRotation = 0.0,
    this.selectedEditingImageId,
    this.activeHandle = HandleType.none,
    this.initialPosition = Offset.zero,
    this.initialSize = Size.zero,
    this.initialRotation = 0.0,
  });

  CanvasInteractionState copyWith({
    ToolMode? activeTool,
    ToolMode? Function()? previousTool,
    CanvasInteractionStateMode? interactionMode,
    String? selectedColorHex,
    double? selectedThickness,
    BrushType? selectedBrushType,
    bool? isHighlighter,
    bool? isSmoothingEnabled,
    Set<String>? selectedObjectIds,
    Set<TableCellKey>? selectedTableCells,
    InlineTarget? activeInlineTarget,
    TextBlock? Function()? activeTextBlock,
    String? Function()? activeTableId,
    TableCellKey? Function()? activeTableCell,
    TableCellKey? Function()? tableSelectionStart,
    TableCellKey? Function()? tableSelectionEnd,
    Offset? Function()? selectionRectStart,
    Offset? Function()? selectionRectEnd,
    List<Offset>? Function()? lassoPath, 
    bool? isTransformMode,
    bool? isMovingSelection,
    Offset? totalSelectionDelta,
    Size? liveScale,
    double? liveRotation,
    String? Function()? selectedEditingImageId,
    HandleType? activeHandle,
    Offset? initialPosition,
    Size? initialSize,
    double? initialRotation,
  }) {
    return CanvasInteractionState(
      activeTool: activeTool ?? this.activeTool,
      previousTool: previousTool != null ? previousTool() : this.previousTool,
      interactionMode: interactionMode ?? this.interactionMode,
      selectedColorHex: selectedColorHex ?? this.selectedColorHex,
      selectedThickness: selectedThickness ?? this.selectedThickness,
      selectedBrushType: selectedBrushType ?? this.selectedBrushType,
      isHighlighter: isHighlighter ?? this.isHighlighter,
      isSmoothingEnabled: isSmoothingEnabled ?? this.isSmoothingEnabled,
      selectedObjectIds: selectedObjectIds ?? this.selectedObjectIds,
      selectedTableCells: selectedTableCells ?? this.selectedTableCells,
      activeInlineTarget: activeInlineTarget ?? this.activeInlineTarget,
      activeTextBlock: activeTextBlock != null ? activeTextBlock() : this.activeTextBlock,
      activeTableId: activeTableId != null ? activeTableId() : this.activeTableId,
      activeTableCell: activeTableCell != null ? activeTableCell() : this.activeTableCell,
      tableSelectionStart: tableSelectionStart != null ? tableSelectionStart() : this.tableSelectionStart,
      tableSelectionEnd: tableSelectionEnd != null ? tableSelectionEnd() : this.tableSelectionEnd,
      selectionRectStart: selectionRectStart != null ? selectionRectStart() : this.selectionRectStart,
      selectionRectEnd: selectionRectEnd != null ? selectionRectEnd() : this.selectionRectEnd,
      lassoPath: lassoPath != null ? lassoPath() : this.lassoPath, 
      isTransformMode: isTransformMode ?? this.isTransformMode,
      isMovingSelection: isMovingSelection ?? this.isMovingSelection,
      totalSelectionDelta: totalSelectionDelta ?? this.totalSelectionDelta,
      liveScale: liveScale ?? this.liveScale,
      liveRotation: liveRotation ?? this.liveRotation,
      selectedEditingImageId: selectedEditingImageId != null ? selectedEditingImageId() : this.selectedEditingImageId,
      activeHandle: activeHandle ?? this.activeHandle,
      initialPosition: initialPosition ?? this.initialPosition,
      initialSize: initialSize ?? this.initialSize,
      initialRotation: initialRotation ?? this.initialRotation,
    );
  }
}

class CanvasInteractionNotifier extends AutoDisposeNotifier<CanvasInteractionState> {
  @override
  CanvasInteractionState build() => CanvasInteractionState();

  void switchTool(ToolMode tool) {
    if (state.activeTool == tool && (state.activeTextBlock != null || state.activeTableCell != null)) return;
    if (state.activeTextBlock != null || state.activeTableCell != null) exitWritingMode();
    final bool canKeepTransform = tool == ToolMode.text || tool == ToolMode.table || tool == ToolMode.select || tool == ToolMode.lasso || tool == ToolMode.organizer;
    state = state.copyWith(activeTool: tool, isTransformMode: canKeepTransform ? state.isTransformMode : false, interactionMode: CanvasInteractionStateMode.idle, selectionRectStart: () => null, selectionRectEnd: () => null, lassoPath: () => null, activeInlineTarget: InlineTarget.none, activeTextBlock: () => null, activeTableId: () => null, activeTableCell: () => null, selectedTableCells: {});
  }

  void enterTemporaryPan() { if (state.activeTool == ToolMode.pan) return; state = state.copyWith(previousTool: () => state.activeTool, activeTool: ToolMode.pan, interactionMode: CanvasInteractionStateMode.panning); }
  void exitTemporaryPan() { if (state.previousTool == null) return; state = state.copyWith(activeTool: state.previousTool, previousTool: () => null, interactionMode: CanvasInteractionStateMode.idle); }

  void selectAt(Offset localPos, LocalPage page, {bool includeLocked = false}) {
    if (isPointInSelection(localPos, page)) return;
    final objects = page.objects.where((o) => !o.isDeleted).toList()..sort((a, b) => b.zIndex.compareTo(a.zIndex));
    for (var obj in objects) {
      if ((!includeLocked && obj.isLocked) || !obj.isVisible) continue;
      if (checkHit(localPos, obj)) {
        clearSelection();
        if (obj.parentId != null) {
          final groupIds = page.objects.where((o) => o.parentId == obj.parentId).map((o) => o.id).toSet();
          state = state.copyWith(selectedObjectIds: groupIds);
        } else { state = state.copyWith(selectedObjectIds: {obj.id}); }
        return;
      }
    }
    clearSelection();
  }

  void clearSelection() => state = state.copyWith(selectedObjectIds: {}, selectedTableCells: {}, selectionRectStart: () => null, selectionRectEnd: () => null, lassoPath: () => null, isMovingSelection: false, totalSelectionDelta: Offset.zero, liveScale: const Size(1, 1), liveRotation: 0.0);

  void selectIds({Set<String>? objectIds, Set<TableCellKey>? tableCells, Set<String>? tableIds}) {
    Set<String> finalIds = objectIds ?? (tableIds ?? state.selectedObjectIds);
    if (finalIds.isNotEmpty) {
      final pageClientId = ref.read(canvasViewportProvider).currentPageClientId;
      if (pageClientId != null) {
        final page = ref.read(canvasDocumentProvider).pages.firstWhere((p) => p.clientId == pageClientId);
        final Set<String> expandedIds = {};
        for (var id in finalIds) {
          final obj = page.objects.where((o) => o.id == id).firstOrNull;
          if (obj?.parentId != null) expandedIds.addAll(page.objects.where((o) => o.parentId == obj!.parentId).map((o) => o.id));
          else expandedIds.add(id);
        }
        finalIds = expandedIds;
      }
    }
    state = state.copyWith(selectedObjectIds: finalIds, selectedTableCells: tableCells ?? state.selectedTableCells);
  }

  void groupSelectedObjects(LocalPage page) {
    if (state.selectedObjectIds.length < 2) return;
    final newGroupId = const Uuid().v4();
    final Map<String, String?> oldParentIds = {};
    for (var id in state.selectedObjectIds) {
      final obj = page.objects.where((o) => o.id == id).firstOrNull;
      if (obj != null) oldParentIds[id] = obj.parentId;
    }
    final action = GroupAction(pageClientId: page.clientId, pageNumber: page.pageNumber, objectIds: state.selectedObjectIds.toList(), newParentId: newGroupId, oldParentIds: oldParentIds);
    ref.read(canvasDocumentProvider.notifier).executeInteractionAction(action);
    state = state.copyWith(selectedObjectIds: Set.from(action.objectIds));
  }

  void ungroupSelectedObjects(LocalPage page) {
    if (state.selectedObjectIds.isEmpty) return;
    final Map<String, String?> oldParentIds = {};
    final Set<String> targets = {};
    for (var id in state.selectedObjectIds) {
      final obj = page.objects.where((o) => o.id == id).firstOrNull;
      if (obj?.parentId != null) {
        final groupMembers = page.objects.where((o) => o.parentId == obj!.parentId);
        for (var m in groupMembers) { targets.add(m.id); oldParentIds[m.id] = m.parentId; }
      }
    }
    if (targets.isEmpty) return;
    final action = GroupAction(pageClientId: page.clientId, pageNumber: page.pageNumber, objectIds: targets.toList(), newParentId: null, oldParentIds: oldParentIds);
    ref.read(canvasDocumentProvider.notifier).executeInteractionAction(action);
    state = state.copyWith(selectedObjectIds: Set.from(action.objectIds));
  }

  void setTextEditing(InlineTarget target, [TextBlock? block]) {
    final bool isProxy = block?.id.startsWith('proxy_') ?? false;
    state = state.copyWith(activeInlineTarget: target, activeTextBlock: () => block, interactionMode: CanvasInteractionStateMode.textEditing, selectedObjectIds: isProxy ? state.selectedObjectIds : {}, activeTableId: () => isProxy ? state.activeTableId : null, activeTableCell: () => isProxy ? state.activeTableCell : null);
  }

  void exitWritingMode() {
    final bool wasInTable = state.activeTableId != null || state.activeTool == ToolMode.table;
    state = state.copyWith(activeTool: wasInTable ? ToolMode.table : ToolMode.draw, interactionMode: wasInTable ? CanvasInteractionStateMode.tableEditing : CanvasInteractionStateMode.idle, activeInlineTarget: InlineTarget.none, activeTextBlock: () => null, activeTableCell: () => null, activeTableId: () => wasInTable ? state.activeTableId : null, selectedTableCells: {}, isTransformMode: false);
  }

  void stopEditing() => state = state.copyWith(activeInlineTarget: InlineTarget.none, activeTextBlock: () => null, activeTableCell: () => null, tableSelectionStart: () => null, tableSelectionEnd: () => null, selectedTableCells: {});
  void clearTextEditing() => exitWritingMode();

  bool isPointInSelection(Offset localPos, LocalPage page) {
    if (state.selectedObjectIds.isEmpty) return false;
    for (var id in state.selectedObjectIds) {
      final obj = page.objects.where((o) => o.id == id).firstOrNull;
      if (obj != null && checkHit(localPos, obj)) return true;
    }
    return false;
  }

  bool checkHit(Offset localPos, PageObject obj) {
    if (obj is Stroke) return obj.points.any((pt) => (pt - localPos).distance < (obj.thickness + 15));
    final hitBounds = Rect.fromCenter(center: (obj.position & obj.size).center, width: math.max(44, obj.size.width), height: math.max(44, obj.size.height));
    if (obj.rotation != 0) return hitBounds.contains(_rotatePoint(localPos, hitBounds.center, -obj.rotation));
    return hitBounds.contains(localPos);
  }

  Offset _rotatePoint(Offset point, Offset center, double angle) {
    final cosA = math.cos(angle), sinA = math.sin(angle);
    final dx = point.dx - center.dx, dy = point.dy - center.dy;
    return Offset(center.dx + dx * cosA - dy * sinA, center.dy + dx * sinA + dy * cosA);
  }

  void setColor(String hex) => state = state.copyWith(selectedColorHex: hex);
  void setThickness(double th) => state = state.copyWith(selectedThickness: th);
  void setBrushType(BrushType t) => state = state.copyWith(selectedBrushType: t);
  void toggleHighlighterMode(bool v) => state = state.copyWith(isHighlighter: v);
  void setSmoothing(bool v) => state = state.copyWith(isSmoothingEnabled: v);

  void setMovingSelection(bool v) => state = state.copyWith(isMovingSelection: v, interactionMode: v ? CanvasInteractionStateMode.moving : CanvasInteractionStateMode.idle);
  void updateSelectionDelta(Offset d) => state = state.copyWith(totalSelectionDelta: state.totalSelectionDelta + d);
  void resetSelectionDelta() => state = state.copyWith(totalSelectionDelta: Offset.zero);
  void toggleTransformMode() => state = state.copyWith(isTransformMode: !state.isTransformMode);
  
  void startHandleTransform(HandleType h, Offset p, Size s, double r) => state = state.copyWith(activeHandle: h, interactionMode: CanvasInteractionStateMode.transforming, initialPosition: p, initialSize: s, initialRotation: r, liveScale: const Size(1, 1), liveRotation: 0);
  void updateLiveTransform({Size? scale, double? rotation}) => state = state.copyWith(liveScale: scale ?? state.liveScale, liveRotation: rotation ?? state.liveRotation);
  void endHandleTransform() => state = state.copyWith(activeHandle: HandleType.none, interactionMode: CanvasInteractionStateMode.idle, liveScale: const Size(1, 1), liveRotation: 0);

  void setTableCellEditing(TableObject table, CellCoordinate coords) {
    final cellKey = TableCellKey(table.id, coords);
    if (state.activeTableCell == cellKey) return;
    final proxyPos = table.position + Offset(coords.col * 100.0, coords.row * 40.0);
    final proxy = TextBlock(id: 'proxy_${table.id}_${coords.row},${coords.col}', text: table.cells[coords]?.value ?? '', position: proxyPos, zIndex: 999, rotation: table.rotation);
    state = state.copyWith(activeInlineTarget: InlineTarget.block, activeTextBlock: () => proxy, activeTableCell: () => cellKey, interactionMode: CanvasInteractionStateMode.tableEditing, activeTableId: () => table.id);
  }

  void toggleTableCellSelection(TableCellKey cell) { final newSelection = Set<TableCellKey>.from(state.selectedTableCells); if (newSelection.contains(cell)) newSelection.remove(cell); else newSelection.add(cell); state = state.copyWith(selectedTableCells: newSelection); }
  void clearTableCellSelection() => state = state.copyWith(selectedTableCells: {}, tableSelectionStart: () => null, tableSelectionEnd: () => null);
  void updateTableSelectionRange(CellCoordinate coords, TableObject table) { final cellKey = TableCellKey(table.id, coords); final start = state.tableSelectionStart ?? cellKey; final range = table.getKeysInRange(start.coordinate, coords); state = state.copyWith(tableSelectionStart: () => start, tableSelectionEnd: () => cellKey, selectedTableCells: range.map((c) => TableCellKey(table.id, c)).toSet()); }
  void forceExitTableMode() => state = state.copyWith(activeTableId: () => null, activeTableCell: () => null, selectedTableCells: {}, interactionMode: CanvasInteractionStateMode.idle);

  void setSelectionRect(Offset? start, Offset? end, [LocalPage? page]) {
    state = state.copyWith(selectionRectStart: () => start, selectionRectEnd: () => end, lassoPath: () => null, interactionMode: CanvasInteractionStateMode.selecting);
    if (start != null && end != null && page != null) {
      final rect = Rect.fromPoints(start, end);
      final newIds = <String>{};
      for (var obj in page.objects) {
        if (obj.isDeleted) continue;
        if (obj is Stroke) { if (obj.points.any((pt) => rect.contains(pt))) newIds.add(obj.id); }
        else { if (rect.overlaps(obj.position & obj.size)) newIds.add(obj.id); }
      }
      state = state.copyWith(selectedObjectIds: newIds);
    }
  }

  void setLassoPath(List<Offset>? path, [LocalPage? page]) {
    state = state.copyWith(lassoPath: () => path, selectionRectStart: () => null, selectionRectEnd: () => null, interactionMode: CanvasInteractionStateMode.lassoSelecting);
    if (path != null && path.length > 3 && page != null) {
      final newIds = <String>{};
      for (var obj in page.objects) {
        if (obj.isDeleted) continue;
        if (obj is Stroke) { if (obj.points.any((pt) => _isPointInPolygon(pt, path))) newIds.add(obj.id); }
        else { if (_isPointInPolygon((obj.position & obj.size).center, path)) newIds.add(obj.id); }
      }
      state = state.copyWith(selectedObjectIds: newIds);
    }
  }

  bool _isPointInPolygon(Offset point, List<Offset> polygon) { bool result = false; int j = polygon.length - 1; for (int i = 0; i < polygon.length; i++) { if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) && (point.dx < (polygon[j].dx - polygon[i].dx) * (point.dy - polygon[i].dy) / (polygon[j].dy - polygon[i].dy) + polygon[i].dx)) result = !result; j = i; } return result; }
}

final canvasInteractionProvider = NotifierProvider.autoDispose<CanvasInteractionNotifier, CanvasInteractionState>(() => CanvasInteractionNotifier());
typedef CanvasToolState = CanvasInteractionState;
typedef CanvasToolNotifier = CanvasInteractionNotifier;
final canvasToolProvider = canvasInteractionProvider;

extension CanvasToolStateExt on CanvasInteractionState {
  ToolMode get currentTool => activeTool;
  Set<String> get selectedStrokeIds => selectedObjectIds; 
  Set<String> get selectedTextIds => selectedObjectIds;
  Set<String> get selectedImageIds => selectedObjectIds;
  Set<String> get selectedShapeIds => selectedObjectIds;
  Set<String> get selectedAudioIds => selectedObjectIds;
  Set<String> get selectedAnimationIds => selectedObjectIds;
  Set<String> get selectedTableIds => selectedObjectIds;
  Set<String> get selectedLinkIds => selectedObjectIds;
  Set<String> get selectedAttachmentIds => selectedObjectIds;
}
