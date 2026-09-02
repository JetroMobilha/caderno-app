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
    // 1. Sort objects by zIndex
    final sortedObjects = page.objects.where((o) => !o.isDeleted).toList()
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
        children: [
          // Background Layer
          RepaintBoundary(
            child: CustomPaint(
              size: pageSize,
              painter: BackgroundPainter(
                bgConfig: page.backgroundConfig,
                lineType: page.lineType,
                lineSpacing: page.lineSpacing,
              ),
            ),
          ),
          
          // Objects Layer
          ...renderList,
        ],
      ),
    );
  }
}
