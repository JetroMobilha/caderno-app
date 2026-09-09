import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../../../core/utils/rdp_simplifier.dart';
import '../models/local_page_model.dart';
import '../models/stroke_model.dart';
import '../models/canvas_enums.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_document_provider.dart';
import 'canvas_tool.dart';

class BrushTool extends CanvasTool {
  static Timer? _broadcastThrottle;
  static bool _isCorrupted = false; // 🚀 v10.22
  static const double _maxAllowedJump = 400.0; // 🚀 v10.22

  const BrushTool() : super(ToolMode.draw);

  @override
  void onTapDown(Offset localPos, dynamic ref, LocalPage page) {
    ref.read(canvasToolProvider.notifier).clearSelection();
  }

  @override
  void onPanStart(Offset localPos, dynamic ref, LocalPage page) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    toolNotifier.clearSelection();
    _isCorrupted = false; // Reset flag
    final String id = const Uuid().v4();
    toolNotifier.startLiveStroke(id, localPos);
  }

  @override
  void onPanUpdate(Offset localPos, Offset delta, dynamic ref, LocalPage page) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasInteractionProvider);
    
    if (toolState.liveStrokeId == null || _isCorrupted) return;
    
    if (toolState.livePoints.isNotEmpty) {
      final double dist = (localPos - toolState.livePoints.last).distance;
      
      // 🚀 v10.22: Trava anti-salto (Ghost touch detection)
      if (dist > _maxAllowedJump) {
        debugPrint('⚠️ [BrushTool] Salto anómalo detectado ($dist px). Traço corrompido.');
        _isCorrupted = true;
        return;
      }

      // Filtro de densidade (Distância Mínima de 1.5px)
      if (dist < 1.5) return; 
    }
    
    toolNotifier.updateLiveStroke(localPos);
    _throttledBroadcast(ref, page, toolState.liveStrokeId!, toolState.livePoints, toolState);
  }

  @override
  void onPanEnd(dynamic ref, LocalPage page) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasInteractionProvider);
    
    if (toolState.liveStrokeId != null && toolState.livePoints.isNotEmpty && !_isCorrupted) {
      // Simplificação RDP Automática baseada no smoothingLevel
      // Se smoothingLevel = 1.0 (100%), usamos epsilon de 1.5. 
      // Se for 0.0, usamos 0.1 (mínimo).
      final double epsilon = 0.1 + (toolState.smoothingLevel * 1.4);
      final simplifiedPoints = RdpSimplifier.simplify(toolState.livePoints, epsilon);

      ref.read(canvasDocumentProvider.notifier).addStroke(
        page, 
        Stroke(
          id: toolState.liveStrokeId!,
          color: toolState.selectedColorHex,
          thickness: toolState.selectedThickness,
          points: simplifiedPoints,
          isHighlighter: toolState.isHighlighter,
          brushType: toolState.selectedBrushType,
          smoothingLevel: toolState.smoothingLevel,
        ),
      );
    }
    toolNotifier.endLiveStroke();
  }

  void _throttledBroadcast(dynamic ref, LocalPage page, String id, List<Offset> points, CanvasToolState toolState) {
    if (_broadcastThrottle?.isActive ?? false) return;
    _broadcastThrottle = Timer(const Duration(milliseconds: 50), () {
      ref.read(canvasDocumentProvider.notifier).broadcastLiveStroke(
        pageClientId: page.clientId, pageNumber: page.pageNumber, strokeId: id,
        points: points, color: toolState.selectedColorHex, thickness: toolState.selectedThickness,
        isHighlighter: toolState.isHighlighter, brushType: toolState.selectedBrushType, 
        smoothingLevel: toolState.smoothingLevel,
      );
    });
  }
}
