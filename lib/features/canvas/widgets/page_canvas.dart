import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/local_page_model.dart';
import '../models/page_object.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../models/image_block_model.dart';
import '../providers/canvas_tool_provider.dart';
import 'canvas_painter.dart';
import 'object_renderer.dart';

class PageCanvas extends ConsumerWidget {
  final LocalPage page;
  final Size pageSize;
  final bool isReadOnly;

  const PageCanvas({
    super.key,
    required this.page,
    required this.pageSize,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolState = ref.watch(canvasToolProvider);
    final selectedIds = {
      ...toolState.selectedStrokeIds,
      ...toolState.selectedTextIds,
      ...toolState.selectedImageIds,
      ...toolState.selectedShapeIds,
      ...toolState.selectedAudioIds,
      ...toolState.selectedAnimationIds,
      ...toolState.selectedTableIds,
      ...toolState.selectedLinkIds,
      ...toolState.selectedAttachmentIds,
    };

    // 1. Map de visibilidade/bloqueio das camadas para acesso rápido
    final Map<String, bool> layerVisibility = {
      for (var l in page.layers) l.id: l.isVisible
    };

    // 2. Sort objects by zIndex and filter by visibility
    final sortedObjects = page.objects.where((o) {
      if (o.isDeleted) return false;
      final bool layerVisible = layerVisibility[o.layerId ?? 'default'] ?? true;
      return layerVisible && o.isVisible;
    }).toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    // 🚀 OTIMIZAÇÃO: Agrupar strokes consecutivos para melhor performance
    final List<Widget> renderList = [];
    List<Stroke> currentStrokeGroup = [];

    void flushStrokes() {
      if (currentStrokeGroup.isNotEmpty) {
        final group = List<Stroke>.from(currentStrokeGroup);
        renderList.add(
          RepaintBoundary(
            child: CustomPaint(
              size: pageSize,
              painter: StrokesPainter(
                strokes: group,
                selectedStrokeIds: toolState.selectedStrokeIds, 
                selectionRect: null,
                pageVersion: page.version,
                selectionDelta: toolState.totalSelectionDelta, // 🚀 FLUIDEZ
              ),
            ),
          ),
        );
        currentStrokeGroup = [];
      }
    }

    for (var obj in sortedObjects) {
      if (obj is Stroke) {
        currentStrokeGroup.add(obj);
      } else {
        flushStrokes();
        final bool isSelected = selectedIds.contains(obj.id);
        renderList.add(ObjectRenderer(
          object: obj, 
          isReadOnly: isReadOnly,
          movementDelta: isSelected ? toolState.totalSelectionDelta : null,
          liveScale: isSelected ? toolState.liveScale : null, // 🚀 v3
          liveRotation: isSelected ? toolState.liveRotation : null, // 🚀 v3
        ));
      }
    }
    flushStrokes();

    return Container(
      width: pageSize.width,
      height: pageSize.height,
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand, 
        children: [
          // 🚀 REMOVIDO RepaintBoundary para evitar limites de textura GPU em folhas gigantes
          CustomPaint(
            size: pageSize,
            painter: BackgroundPainter(
              notebookConfig: page.toConfig, 
              bgConfig: page.backgroundConfig,
              lineType: page.lineType,
              lineSpacing: page.lineSpacing,
            ),
          ),
          
          // Layer de Objetos
          ...renderList,
        ],
      ),
    );
  }
}
