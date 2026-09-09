import 'package:flutter/material.dart';
import '../models/local_page_model.dart';
import '../models/canvas_enums.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_document_provider.dart';
import 'canvas_tool.dart';

class EraserTool extends CanvasTool {
  const EraserTool() : super(ToolMode.eraser);

  @override
  void onTapDown(Offset localPos, dynamic ref, LocalPage page) {
    _eraseAt(localPos, ref, page);
  }

  @override
  void onPanStart(Offset localPos, dynamic ref, LocalPage page, [double pressure = 0.5]) {
    _eraseAt(localPos, ref, page);
  }

  @override
  void onPanUpdate(Offset localPos, Offset delta, dynamic ref, LocalPage page, [double pressure = 0.5]) {
    _eraseAt(localPos, ref, page);
  }

  @override
  void onPanEnd(dynamic ref, LocalPage page) {}

  void _eraseAt(Offset localPos, dynamic ref, LocalPage page) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasToolProvider);
    final docNotifier = ref.read(canvasDocumentProvider.notifier);
    if (toolNotifier.isPointInSelection(localPos, page)) {
      if (toolState.selectedObjectIds.isNotEmpty) {
        docNotifier.deleteObjects(page, toolState.selectedObjectIds.toList());
        toolNotifier.clearSelection();
        return;
      }
    }
    final objects = page.objects.where((o) => !o.isDeleted).toList()..sort((a, b) => b.zIndex.compareTo(a.zIndex));
    for (var obj in objects) {
      if (!obj.isLocked && obj.isVisible && toolNotifier.checkHit(localPos, obj)) {
        docNotifier.deleteObjects(page, [obj.id]);
        return;
      }
    }
  }
}
