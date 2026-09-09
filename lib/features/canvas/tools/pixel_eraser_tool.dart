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
    _performPixelErase(localPos, ref, page);
  }

  @override
  void onPanStart(Offset localPos, dynamic ref, LocalPage page, [double pressure = 0.5]) {
    _deletedIds.clear(); _addedStrokes.clear();
    _performPixelErase(localPos, ref, page);
  }

  @override
  void onPanUpdate(Offset localPos, Offset delta, dynamic ref, LocalPage page, [double pressure = 0.5]) {
    _performPixelErase(localPos, ref, page);
  }

  @override
  void onPanEnd(dynamic ref, LocalPage page) {
    if (_deletedIds.isNotEmpty || _addedStrokes.isNotEmpty) {
      ref.read(canvasDocumentProvider.notifier).commitPixelErase(page, List.from(_deletedIds), List.from(_addedStrokes));
    }
  }

  void _performPixelErase(Offset localPos, dynamic ref, LocalPage page) {
    ref.read(canvasDocumentProvider.notifier).pixelErase(page, localPos, 20.0, deletedAccumulator: _deletedIds, addedAccumulator: _addedStrokes);
  }
}
