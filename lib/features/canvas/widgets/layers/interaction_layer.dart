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

  @override
  void dispose() {
    _activePoints.dispose();
    super.dispose();
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
                        toolNotifier.selectIds(textIds: {});
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
                        // TODO: Enviar update remoto (throttle)
                      } else if (toolState.currentTool == ToolMode.select) {
                        toolNotifier.setSelectionRect(toolState.selectionRectStart, d.localPosition, widget.page);
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
                        }
                        _activePoints.value = [];
                        _liveStrokeId = null;
                      }
                    }
                  : null,
            ),
            // Renderização do traço ativo em alta frequência
            ValueListenableBuilder<List<Offset>>(
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
          ],
        ),
      ),
    );
  }
}
