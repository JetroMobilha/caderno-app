import 'package:flutter/material.dart';
import '../models/local_page_model.dart';
import '../models/canvas_enums.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/live_stroke_provider.dart'; // 🚀 v10.50
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
    final liveNotifier = ref.read(liveStrokeProvider);
    
    toolNotifier.clearSelection();
    // 🚀 v10.50: Gerir caminho do laço no provedor de latência zero
    liveNotifier.startLasso(localPos);
  }

  @override
  void onPanUpdate(Offset localPos, Offset delta, dynamic ref, LocalPage page, [double pressure = 0.5]) {
    final liveNotifier = ref.read(liveStrokeProvider);
    if (liveNotifier.lassoPath != null) {
      liveNotifier.updateLasso(localPos);
    }
  }

  @override
  void onPanEnd(dynamic ref, LocalPage page) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final liveNotifier = ref.read(liveStrokeProvider);
    
    if (liveNotifier.lassoPath != null && liveNotifier.lassoPath!.length > 3) {
      // 🚀 v10.50: Executar a seleção final
      toolNotifier.selectByLasso(List.from(liveNotifier.lassoPath!), page);
    }
    
    liveNotifier.clear();
  }
}
