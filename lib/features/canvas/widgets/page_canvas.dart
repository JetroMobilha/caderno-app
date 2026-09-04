import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/local_page_model.dart';
import '../models/page_object.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../models/image_block_model.dart';
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
                selectedStrokeIds: const {}, // Handled by SelectionOverlay or Controller
                selectionRect: null,
                pageVersion: page.version,
                selectionDelta: Offset.zero,
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
        renderList.add(ObjectRenderer(object: obj, isReadOnly: isReadOnly));
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
