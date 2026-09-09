import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/stroke_model.dart';
import 'canvas_document_provider.dart';
import 'canvas_tool_provider.dart';

/// 🚀 v9.0: Modelo de Item de Renderização Pré-Calculado.
abstract class RenderItem {}

class StrokesRenderItem extends RenderItem {
  final List<Stroke> strokes;
  StrokesRenderItem(this.strokes);
}

class ObjectRenderItem extends RenderItem {
  final dynamic object;
  final bool isSelected;
  ObjectRenderItem(this.object, {required this.isSelected});
}

/// Provider especializado em calcular a ordem e o agrupamento de renderização do canvas.
final canvasRenderProvider = Provider.family.autoDispose<List<RenderItem>, String>((ref, pageClientId) {
  final docState = ref.watch(canvasDocumentProvider);
  final toolState = ref.watch(canvasInteractionProvider);
  
  final pageIdx = docState.pages.indexWhere((p) => p.clientId == pageClientId);
  if (pageIdx == -1) return const [];
  final page = docState.pages[pageIdx];

  final Map<String, bool> layerVisibility = {
    for (var l in page.layers) l.id: l.isVisible
  };

  final sortedObjects = page.objects.where((o) {
    if (o.isDeleted) return false;
    final bool layerVisible = layerVisibility[o.layerId ?? 'default'] ?? true;
    return layerVisible && o.isVisible;
  }).toList()
    ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

  final List<RenderItem> renderList = [];
  List<Stroke> currentStrokeGroup = [];
  final selectedIds = toolState.selectedObjectIds;

  void flushStrokes() {
    if (currentStrokeGroup.isNotEmpty) {
      renderList.add(StrokesRenderItem(List<Stroke>.from(currentStrokeGroup)));
      currentStrokeGroup = [];
    }
  }

  for (var obj in sortedObjects) {
    if (obj is Stroke) {
      currentStrokeGroup.add(obj);
    } else {
      flushStrokes();
      renderList.add(ObjectRenderItem(obj, isSelected: selectedIds.contains(obj.id)));
    }
  }
  flushStrokes();

  return renderList;
});
