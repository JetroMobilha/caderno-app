import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/local_page_model.dart';
import '../../models/stroke_model.dart';
import '../../models/canvas_enums.dart';
import '../../widgets/canvas_painter.dart';

class InteractionLayer extends ConsumerStatefulWidget {
  final LocalPage page;
  final bool isBlocked;
  final VoidCallback onFinishEditing;
  final Function(Offset) onAddTextBlock;

  const InteractionLayer({
    super.key,
    required this.page,
    required this.isBlocked,
    required this.onFinishEditing,
    required this.onAddTextBlock,
  });

  @override
  ConsumerState<InteractionLayer> createState() => _InteractionLayerState();
}

class _InteractionLayerState extends ConsumerState<InteractionLayer> {
  String? _liveStrokeId;
  final ValueNotifier<List<Offset>> _activePoints = ValueNotifier([]);
  Timer? _broadcastThrottle;

  @override
  void dispose() {
    _activePoints.dispose();
    _broadcastThrottle?.cancel();
    super.dispose();
  }

  void _throttledBroadcast(String strokeId, List<Offset> points, CanvasToolState toolState) {
    if (_broadcastThrottle?.isActive ?? false) return;
    
    _broadcastThrottle = Timer(const Duration(milliseconds: 50), () {
      ref.read(canvasDocumentProvider.notifier).broadcastLiveStroke(
        pageClientId: widget.page.clientId,
        pageNumber: widget.page.pageNumber,
        strokeId: strokeId,
        points: points,
        color: toolState.selectedColorHex,
        thickness: toolState.selectedThickness,
        isHighlighter: toolState.isHighlighter,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final toolState = ref.watch(canvasToolProvider);
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final docNotifier = ref.read(canvasDocumentProvider.notifier);

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: toolState.currentTool == ToolMode.pan || toolState.currentTool == ToolMode.imageEdit,
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTapDown: !widget.isBlocked
                  ? (details) {
                      if (toolState.activeInlineTarget != InlineTarget.none) {
                        widget.onFinishEditing();
                      }
                      if (toolState.currentTool == ToolMode.text) {
                        widget.onAddTextBlock(details.localPosition);
                      }
                    }
                  : null,
              onPanStart: !widget.isBlocked
                  ? (d) {
                      if (toolState.currentTool == ToolMode.draw) {
                        toolNotifier.selectIds(strokeIds: {}, textIds: {}, imageIds: {});
                        _liveStrokeId = const Uuid().v4();
                        _activePoints.value = [d.localPosition];
                      } else if (toolState.currentTool == ToolMode.select) {
                        toolNotifier.setSelectionRect(d.localPosition, d.localPosition, widget.page);
                      }
                    }
                  : null,
              onPanUpdate: !widget.isBlocked
                  ? (d) {
                      if (toolState.currentTool == ToolMode.draw) {
                        _activePoints.value = [..._activePoints.value, d.localPosition];
                        if (_liveStrokeId != null) {
                          _throttledBroadcast(_liveStrokeId!, _activePoints.value, toolState);
                        }
                      } else if (toolState.currentTool == ToolMode.select) {
                        if (toolState.selectedStrokeIds.isNotEmpty || 
                            toolState.selectedTextIds.isNotEmpty || 
                            toolState.selectedImageIds.isNotEmpty) {
                          toolNotifier.updateSelectionDelta(d.delta);
                        } else {
                          toolNotifier.setSelectionRect(toolState.selectionRectStart, d.localPosition, widget.page);
                        }
                      }
                    }
                  : null,
              onPanEnd: !widget.isBlocked
                  ? (_) {
                      if (toolState.currentTool == ToolMode.draw && _liveStrokeId != null) {
                        if (_activePoints.value.isNotEmpty) {
                          docNotifier.addStroke(
                            widget.page,
                            Stroke(
                              id: _liveStrokeId!,
                              color: toolState.selectedColorHex,
                              thickness: toolState.selectedThickness,
                              points: List.from(_activePoints.value),
                              isHighlighter: toolState.isHighlighter,
                            ),
                          );
                          // Envio final para garantir sincronia
                          docNotifier.broadcastLiveStroke(
                            pageClientId: widget.page.clientId,
                            pageNumber: widget.page.pageNumber,
                            strokeId: _liveStrokeId!,
                            points: _activePoints.value,
                            color: toolState.selectedColorHex,
                            thickness: toolState.selectedThickness,
                            isHighlighter: toolState.isHighlighter,
                            isFinal: true,
                          );
                        }
                        _activePoints.value = [];
                        _liveStrokeId = null;
                        _broadcastThrottle?.cancel();
                      } else if (toolState.currentTool == ToolMode.select) {
                        if (toolState.totalSelectionDelta != Offset.zero) {
                          docNotifier.moveSelection(
                            widget.page,
                            strokeIds: toolState.selectedStrokeIds.toList(),
                            textIds: toolState.selectedTextIds.toList(),
                            imageIds: toolState.selectedImageIds.toList(),
                            delta: toolState.totalSelectionDelta,
                          );
                          toolNotifier.resetSelectionDelta();
                        }
                      }
                    }
                  : null,
            ),
            // Renderização do traço ativo em alta frequência (ISOLADA)
            RepaintBoundary(
              child: ValueListenableBuilder<List<Offset>>(
                valueListenable: _activePoints,
                builder: (context, points, _) {
                  if (points.isEmpty) return const SizedBox.shrink();
                  return CustomPaint(
                    size: Size.infinite,
                    painter: ActiveStrokePainter(
                      currentPoints: points,
                      visualColor: Color(int.parse(toolState.selectedColorHex.replaceFirst('#', '0xFF'))),
                      currentThickness: toolState.selectedThickness,
                      isHighlighter: toolState.isHighlighter,
                    ),
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }
}
