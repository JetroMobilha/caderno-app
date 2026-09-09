import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/local_page_model.dart';
import '../models/canvas_enums.dart';
import '../models/table_types.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_document_provider.dart';
import '../models/text_block_model.dart';
import '../models/table_model.dart';
import '../services/transform_service.dart';
import 'canvas_tool.dart';

class TextTool extends CanvasTool {
  const TextTool() : super(ToolMode.text);

  @override
  void onTapDown(Offset localPos, dynamic ref, LocalPage page) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasToolProvider);
    if (toolState.isTransformMode) { toolNotifier.selectAt(localPos, page); return; }
    
    final hitObj = _findHitObject(localPos, toolNotifier, page);

    if (hitObj is TextBlock) { 
      toolNotifier.setTextEditing(InlineTarget.block, hitObj); 
    } else if (hitObj is TableObject) {
      final coords = _findCellAt(localPos, hitObj);
      if (coords != null) toolNotifier.setTableCellEditing(hitObj, coords);
    } else {
      // 🚀 v10.24: Se já estivermos a editar algo e clicarmos no vazio, 
      // fechamos o atual e criamos um novo imediatamente.
      if (toolState.activeInlineTarget != InlineTarget.none) {
        if (toolState.activeTextBlock != null) {
          ref.read(canvasDocumentProvider.notifier).cleanupIfEmpty(page, toolState.activeTextBlock!.id);
        }
        toolNotifier.exitWritingMode();
      }
      _createNewTextBlock(localPos, ref, page); 
    }
  }

  @override void onPanStart(Offset localPos, dynamic ref, LocalPage page, [double pressure = 0.5]) {}
  @override void onPanUpdate(Offset localPos, Offset delta, dynamic ref, LocalPage page, [double pressure = 0.5]) {}
  @override void onPanEnd(dynamic ref, LocalPage page) {}

  void _createNewTextBlock(Offset pos, dynamic ref, LocalPage page) {
    final toolState = ref.read(canvasToolProvider);
    final newBlock = TextBlock(id: const Uuid().v4(), text: '', position: pos, fontSize: 18.0, textColorHex: toolState.selectedColorHex, zIndex: page.objects.length);
    ref.read(canvasDocumentProvider.notifier).addTextBlock(page, newBlock);
    ref.read(canvasToolProvider.notifier).setTextEditing(InlineTarget.block, newBlock);
  }

  dynamic _findHitObject(Offset localPos, CanvasToolNotifier toolNotifier, LocalPage page) {
    final objects = page.objects.where((o) => !o.isDeleted).toList()..sort((a, b) => b.zIndex.compareTo(a.zIndex));
    for (var obj in objects) {
      if (!obj.isVisible) continue;
      if (toolNotifier.checkHit(localPos, obj)) return obj;
      if (obj is TextBlock && Rect.fromCenter(center: (obj.position & obj.size).center, width: obj.size.width + 20, height: obj.size.height + 20).contains(localPos)) return obj;
    }
    return null;
  }

  CellCoordinate? _findCellAt(Offset localPos, TableObject table) {
    final center = (table.position & table.size).center;
    final relPos = TransformService.rotatePoint(localPos, center, -table.rotation) - table.position;
    if (relPos.dx < -25 || relPos.dx > table.size.width + 25 || relPos.dy < -25 || relPos.dy > table.size.height + 25) return null;
    final double cx = relPos.dx.clamp(0.0, table.size.width - 0.1), cy = relPos.dy.clamp(0.0, table.size.height - 0.1);
    double cw = 0; int col = -1; for (int i = 0; i < table.columnWidths.length; i++) { cw += table.columnWidths[i]; if (cx <= cw) { col = i; break; } }
    double ch = 0; int row = -1; for (int i = 0; i < table.rowHeights.length; i++) { ch += table.rowHeights[i]; if (cy <= ch) { row = i; break; } }
    return (row != -1 && col != -1) ? table.resolveMasterCell(row, col) : null;
  }
}
