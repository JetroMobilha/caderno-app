import 'package:flutter/material.dart';
import '../models/local_page_model.dart';
import '../models/canvas_enums.dart';
import '../providers/canvas_tool_provider.dart';
import 'canvas_tool.dart';

class LassoTool extends CanvasTool {
  const LassoTool() : super(ToolMode.lasso);

  @override
  void onTapDown(Offset localPos, dynamic ref, LocalPage page) {
    ref.read(canvasToolProvider.notifier).clearSelection();
  }

  @override
  void onPanStart(Offset localPos, dynamic ref, LocalPage page, [double pressure = 0.5]) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    toolNotifier.clearSelection();
    toolNotifier.setLassoPath([localPos], page);
  }

  @override
  void onPanUpdate(Offset localPos, Offset delta, dynamic ref, LocalPage page, [double pressure = 0.5]) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasToolProvider);
    if (toolState.lassoPath != null) {
      toolNotifier.setLassoPath([...toolState.lassoPath!, localPos], page);
    }
  }

  @override
  void onPanEnd(dynamic ref, LocalPage page) {
    ref.read(canvasToolProvider.notifier).setLassoPath(null, null);
  }
}
