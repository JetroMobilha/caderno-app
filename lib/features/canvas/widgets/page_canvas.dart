import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/local_page_model.dart';
import '../models/page_object.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../models/image_block_model.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_render_provider.dart'; // 🚀 NOVO
import 'canvas_painter.dart';
import 'object_renderer.dart';

/// 🚀 v9.0: Widget de renderização pura da folha.
/// Agora é um "Pure Consumer" que recebe a lista de renderização pré-calculada.
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
    final renderList = ref.watch(canvasRenderProvider(page.clientId)); // 🚀 v9.0

    final List<Widget> widgets = [];

    for (var item in renderList) {
      if (item is StrokesRenderItem) {
        widgets.add(
          RepaintBoundary(
            child: CustomPaint(
              size: pageSize,
              painter: StrokesPainter(
                strokes: item.strokes,
                selectedStrokeIds: toolState.selectedStrokeIds, 
                selectionRect: null,
                pageVersion: page.version,
                selectionDelta: toolState.totalSelectionDelta,
              ),
            ),
          ),
        );
      } else if (item is ObjectRenderItem) {
        widgets.add(ObjectRenderer(
          object: item.object, 
          isReadOnly: isReadOnly,
          movementDelta: item.isSelected ? toolState.totalSelectionDelta : null,
          liveScale: item.isSelected ? toolState.liveScale : null,
          liveRotation: item.isSelected ? toolState.liveRotation : null,
        ));
      }
    }

    return Container(
      width: pageSize.width,
      height: pageSize.height,
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand, 
        children: [
          CustomPaint(
            size: pageSize,
            painter: BackgroundPainter(
              notebookConfig: page.toConfig, 
              bgConfig: page.backgroundConfig,
              lineType: page.lineType,
              lineSpacing: page.lineSpacing,
            ),
          ),
          ...widgets,
        ],
      ),
    );
  }
}
