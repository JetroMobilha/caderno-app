import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/local_page_model.dart';
import '../models/canvas_enums.dart';
import '../models/table_types.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_viewport_provider.dart';
import '../models/table_model.dart';
import 'canvas_tool.dart';

class TableTool extends CanvasTool {
  const TableTool() : super(ToolMode.table);

  @override
  void onTapDown(Offset localPos, dynamic ref, LocalPage page) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasInteractionProvider);

    // 🚀 v10.60: Sempre finalizar edição de texto ativa ao dar um toque simples (Seleção)
    if (toolState.activeTextBlock != null) {
      ref.read(canvasDocumentProvider.notifier).cleanupIfEmpty(page, toolState.activeTextBlock!.id);
      toolNotifier.stopTextEditing();
    }

    // 🚀 v10.30: Proteção para hastes no onTapDown
    if (toolState.selectedObjectIds.length == 1) {
      final table = page.objects.whereType<TableObject>().where((t) => t.id == toolState.selectedObjectIds.first).firstOrNull;
      if (table != null && toolState.isTableStructuralMode) {
        if (_detectHasteHit(localPos, table, ref) != null) return;
      }
    }

    final hitObj = _findHitObject(localPos, toolNotifier, page);

    if (hitObj is TableObject) {
      toolNotifier.selectIds(objectIds: {hitObj.id});
      final coords = _findCellAt(localPos, hitObj);
      if (coords != null) {
        // 🚀 v10.60: Clique simples apenas seleciona a célula (ferramenta de tabela ativa)
        toolNotifier.selectIds(tableCells: {TableCellKey(hitObj.id, coords)});
      }
    } else {
      toolNotifier.clearSelection();
    }
  }

  @override
  void onDoubleTap(Offset localPos, dynamic ref, LocalPage page) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final hitObj = _findHitObject(localPos, toolNotifier, page);

    if (hitObj is TableObject) {
      final coords = _findCellAt(localPos, hitObj);
      if (coords != null) {
        // 🚀 v10.60: Clique duplo ativa a edição (muda para ferramenta de texto)
        toolNotifier.setTableCellEditing(hitObj, coords);
      }
    }
  }

  @override
  void onPanStart(Offset localPos, dynamic ref, LocalPage page, {int? pointerId}) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasInteractionProvider);

    final table = page.objects.whereType<TableObject>().where((t) => toolState.selectedObjectIds.contains(t.id)).firstOrNull
        ?? page.objects.whereType<TableObject>().firstOrNull;
    if (table == null) return;

    // 🚀 v10.29: Prioridade para hastes externas se modo estrutural ativo
    if (toolState.isTableStructuralMode) {
      final hit = _detectHasteHit(localPos, table, ref);
      if (hit != null) {
        toolNotifier.startTableResize(hit.isVertical ? HandleType.tableColResize : HandleType.tableRowResize, hit.index, localPos);
        return;
      }
      // Se não clicou na haste, permite a seleção normal de células em vez de bloquear
    }

    final coords = _findCellAt(localPos, table);
    if (coords != null) toolNotifier.updateTableSelectionRange(coords, table);
  }

  @override
  void onPanUpdate(Offset localPos, Offset delta, dynamic ref, LocalPage page, {int? pointerId}) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasInteractionProvider);

    final table = page.objects.whereType<TableObject>().where((t) => toolState.selectedObjectIds.contains(t.id)).firstOrNull;
    if (table == null) return;

    if (toolState.activeTableResizeIndex != null) {
      // 🚀 v10.98: O delta já vem escalonado corretamente pelo InteractiveViewer
      final Offset docDelta = delta;
      if (toolState.activeHandle == HandleType.tableColResize) {
        _handleColumnResize(table, toolState.activeTableResizeIndex!, docDelta.dx, ref, page);
      } else if (toolState.activeHandle == HandleType.tableRowResize) {
        _handleRowResize(table, toolState.activeTableResizeIndex!, docDelta.dy, ref, page);
      }
      return;
    }

    final coords = _findCellAt(localPos, table);
    if (coords != null) toolNotifier.updateTableSelectionRange(coords, table);
  }

  @override
  void onPanEnd(dynamic ref, LocalPage page, {int? pointerId}) {
    ref.read(canvasToolProvider.notifier).endTableResize();
  }

  _TableBorderHit? _detectHasteHit(Offset localPos, TableObject table, dynamic ref) {
    final center = (table.position & table.size).center;
    final relPos = _rotatePoint(localPos, center, -table.rotation) - table.position;
    
    final viewportState = ref.read(canvasViewportProvider);
    final double currentScale = viewportState.currentPageClientId != null 
        ? ref.read(canvasViewportProvider.notifier).getControllerFor(viewportState.currentPageClientId!).value.getMaxScaleOnAxis()
        : 1.0;
    
    final double tolerance = 35.0 / currentScale; // 🚀 v10.30: Maior tolerância

    // 1. Colunas (Hastes Superiores)
    double currentX = 0;
    for (int i = 0; i <= table.columnWidths.length; i++) {
      if ((relPos.dx - currentX).abs() < tolerance && (relPos.dy + 35 / currentScale).abs() < tolerance) {
        return _TableBorderHit(i, true);
      }
      if (i < table.columnWidths.length) currentX += table.columnWidths[i];
    }

    // 2. Linhas (Hastes Esquerdas)
    double currentY = 0;
    for (int i = 0; i <= table.rowHeights.length; i++) {
      if ((relPos.dy - currentY).abs() < tolerance && (relPos.dx + 35 / currentScale).abs() < tolerance) {
        return _TableBorderHit(i, false);
      }
      if (i < table.rowHeights.length) currentY += table.rowHeights[i];
    }
    return null;
  }

  void _handleColumnResize(TableObject table, int index, double deltaX, dynamic ref, LocalPage page) {
    if (deltaX == 0) return;
    final List<double> newWidths = List<double>.from(table.columnWidths);
    Offset newPos = table.position;

    if (index == 0) {
      // Redimensionar primeira coluna pela esquerda
      final double oldW = newWidths[0];
      newWidths[0] = (oldW - deltaX).clamp(30.0, 1500.0);
      final double actualDelta = oldW - newWidths[0];
      // Mover a tabela para compensar o redimensionamento da borda esquerda
      newPos += Offset(actualDelta, 0);
    } else {
      // Redimensionar coluna anterior pela direita
      newWidths[index - 1] = (newWidths[index - 1] + deltaX).clamp(30.0, 1500.0);
    }

    ref.read(canvasDocumentProvider.notifier).updateObject(page, table.copyWith(columnWidths: newWidths, position: newPos));
  }

  void _handleRowResize(TableObject table, int index, double deltaY, dynamic ref, LocalPage page) {
    if (deltaY == 0) return;
    final List<double> newHeights = List<double>.from(table.rowHeights);
    Offset newPos = table.position;

    if (index == 0) {
      // Redimensionar primeira linha pelo topo
      final double oldH = newHeights[0];
      newHeights[0] = (oldH - deltaY).clamp(20.0, 1000.0);
      final double actualDelta = oldH - newHeights[0];
      newPos += Offset(0, actualDelta);
    } else {
      // Redimensionar linha anterior pela base
      newHeights[index - 1] = (newHeights[index - 1] + deltaY).clamp(20.0, 1000.0);
    }

    ref.read(canvasDocumentProvider.notifier).updateObject(page, table.copyWith(rowHeights: newHeights, position: newPos));
  }

  dynamic _findHitObject(Offset localPos, CanvasToolNotifier toolNotifier, LocalPage page) {
    final objects = page.objects.where((o) => !o.isDeleted).toList()..sort((a, b) => b.zIndex.compareTo(a.zIndex));
    for (var obj in objects) {
      if (!obj.isVisible) continue;
      if (toolNotifier.checkHit(localPos, obj)) return obj;
    }
    return null;
  }

  CellCoordinate? _findCellAt(Offset localPos, TableObject table) {
    final center = (table.position & table.size).center;
    final relPos = _rotatePoint(localPos, center, -table.rotation) - table.position;
    if (relPos.dx < -10 || relPos.dx > table.size.width + 10 || relPos.dy < -10 || relPos.dy > table.size.height + 10) return null;
    
    double cx = relPos.dx.clamp(0.0, table.size.width - 0.1);
    double cy = relPos.dy.clamp(0.0, table.size.height - 0.1);
    
    double cw = 0; int col = -1; 
    for (int i = 0; i < table.columnWidths.length; i++) { cw += table.columnWidths[i]; if (cx <= cw) { col = i; break; } }
    
    double ch = 0; int row = -1; 
    for (int i = 0; i < table.rowHeights.length; i++) { ch += table.rowHeights[i]; if (cy <= ch) { row = i; break; } }
    
    return (row != -1 && col != -1) ? table.resolveMasterCell(row, col) : null;
  }

  Offset _rotatePoint(Offset point, Offset center, double angle) {
    final cosA = math.cos(angle), sinA = math.sin(angle);
    final dx = point.dx - center.dx, dy = point.dy - center.dy;
    return Offset(center.dx + dx * cosA - dy * sinA, center.dy + dx * sinA + dy * cosA);
  }
}

class _TableBorderHit {
  final int index;
  final bool isVertical; // true para colunas, false para linhas
  _TableBorderHit(this.index, this.isVertical);
}
