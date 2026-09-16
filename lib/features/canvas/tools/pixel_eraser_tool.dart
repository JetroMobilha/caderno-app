import 'package:caderno_digital_app/features/canvas/providers/canvas_tool_provider.dart';
import 'package:flutter/material.dart';
import '../models/local_page_model.dart';
import '../models/stroke_model.dart';
import '../models/canvas_enums.dart';
import '../providers/canvas_document_provider.dart';
import 'canvas_tool.dart';

class PixelEraserTool extends CanvasTool {
  static final List<String> _deletedIds = [];
  static final List<Stroke> _addedStrokes = [];
  const PixelEraserTool() : super(ToolMode.pixelEraser);

  @override
  void onTapDown(Offset localPos, dynamic ref, LocalPage page) {
    _deletedIds.clear(); _addedStrokes.clear();
    _performPixelErase(localPos, ref, page);
    if (_deletedIds.isNotEmpty || _addedStrokes.isNotEmpty) {
      ref.read(canvasDocumentProvider.notifier).commitPixelErase(
        page, 
        List<String>.from(_deletedIds), 
        List<Stroke>.from(_addedStrokes)
      );
    }
  }

  @override
  void onPanStart(Offset localPos, dynamic ref, LocalPage page, {int? pointerId}) {
    _deletedIds.clear(); _addedStrokes.clear();
    _performPixelErase(localPos, ref, page);
  }

  @override
  void onPanUpdate(Offset localPos, Offset delta, dynamic ref, LocalPage page, {int? pointerId}) {
    _performPixelErase(localPos, ref, page);
  }

  @override
  void onPanEnd(dynamic ref, LocalPage page, {int? pointerId}) {
    if (_deletedIds.isNotEmpty || _addedStrokes.isNotEmpty) {
      ref.read(canvasDocumentProvider.notifier).commitPixelErase(
        page, 
        List<String>.from(_deletedIds), 
        List<Stroke>.from(_addedStrokes)
      );
    }
  }

  void _performPixelErase(Offset localPos, dynamic ref, LocalPage page) {
    final thickness = ref.read(canvasInteractionProvider).selectedThickness;
    ref.read(canvasDocumentProvider.notifier).pixelErase(
      page, 
      localPos, 
      thickness * 1.5, // Fator de escala para a borracha ser ligeiramente maior que o traço
      deletedAccumulator: _deletedIds, 
      addedAccumulator: _addedStrokes
    );
  }
}
