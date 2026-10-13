import 'package:caderno_digital_app/features/canvas/providers/canvas_tool_provider.dart';
import 'package:flutter/material.dart';
import '../models/local_page_model.dart';
import '../models/stroke_model.dart';
import '../models/canvas_enums.dart';
import '../providers/canvas_document_provider.dart';
import 'canvas_tool.dart';

class PixelEraserTool extends CanvasTool {
  static final Set<String> _initialStrokeIds = {};
  const PixelEraserTool() : super(ToolMode.pixelEraser);

  @override
  void onTapDown(Offset localPos, dynamic ref, LocalPage page) {
    _initialStrokeIds.clear();
    for (var s in page.strokes) {
      if (!s.isDeleted) _initialStrokeIds.add(s.id);
    }
    _performPixelErase(localPos, ref, page);
    _commitNormalizedErase(ref, page);
  }

  @override
  void onPanStart(Offset localPos, dynamic ref, LocalPage page, {int? pointerId}) {
    _initialStrokeIds.clear();
    for (var s in page.strokes) {
      if (!s.isDeleted) _initialStrokeIds.add(s.id);
    }
    _performPixelErase(localPos, ref, page);
  }

  @override
  void onPanUpdate(Offset localPos, Offset delta, dynamic ref, LocalPage page, {int? pointerId}) {
    _performPixelErase(localPos, ref, page);
  }

  @override
  void onPanEnd(dynamic ref, LocalPage page, {int? pointerId}) {
    _commitNormalizedErase(ref, page);
  }

  void _commitNormalizedErase(dynamic ref, LocalPage initialPage) {
    final docNotifier = ref.read(canvasDocumentProvider.notifier);
    final currentPageState = ref.read(canvasDocumentProvider).pages.firstWhere(
      (p) => p.clientId == initialPage.clientId,
      orElse: () => initialPage,
    );

    // 🚀 Normalização do Gesto:
    // 1. deletedIds = Apenas os traços originais da página que terminaram marcados como deletados
    final List<String> deletedIds = [];
    for (var origId in _initialStrokeIds) {
      final currentStroke = currentPageState.strokes.firstWhere(
        (s) => s.id == origId,
        orElse: () => Stroke(color: '#000000', thickness: 1, points: [], isDeleted: true),
      );
      if (currentStroke.isDeleted) {
        deletedIds.add(origId);
      }
    }

    // 2. addedStrokes = Apenas os novos sub-traços resultantes que estão ativos (não deletados)
    final List<Stroke> addedStrokes = currentPageState.strokes
        .where((s) => !s.isDeleted && !_initialStrokeIds.contains(s.id))
        .toList();

    if (deletedIds.isNotEmpty || addedStrokes.isNotEmpty) {
      docNotifier.commitPixelErase(
        currentPageState,
        deletedIds,
        addedStrokes,
      );
    }
    _initialStrokeIds.clear();
  }

  void _performPixelErase(Offset localPos, dynamic ref, LocalPage page) {
    final thickness = ref.read(canvasInteractionProvider).selectedThickness;
    ref.read(canvasDocumentProvider.notifier).pixelErase(
      page, 
      localPos, 
      thickness * 1.5,
    );
  }
}
