import 'package:caderno_digital_app/features/canvas/providers/live_stroke_provider.dart'; // 🚀 v10.50
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../providers/canvas_viewport_provider.dart';
import '../../models/local_page_model.dart';
import '../../providers/canvas_ui_provider.dart';
import '../../widgets/canvas_painter.dart';
import '../../models/canvas_enums.dart';
import 'selection_overlay.dart';

/// 🚀 v10.43: Camada de Interação de Alta Fidelidade.
/// 
/// Esta classe é o ponto de entrada central para todos os gestos do usuário no canvas.
/// Ela utiliza uma arquitetura híbrida para maximizar a performance:
/// 
/// 1. **Alta Frequência (`Listener`)**: Captura eventos de hardware (`PointerEvents`)
///    diretamente para ferramentas de precisão como Caneta, Borracha e Laço. Isso
///    ignora as latências inerentes ao [GestureDetector] do Flutter.
/// 2. **Feedback Isolado**: Utiliza um [Consumer] dedicado para o traço "ao vivo",
///    garantindo que o resto da interface (menus, botões) não sofra rebuilds inúteis.
/// 3. **Palm Rejection**: Gere automaticamente o bloqueio de toques acidentais
///    quando um Stylus é detetado.
class InteractionLayer extends ConsumerStatefulWidget {
  final LocalPage page;
  final bool isBlocked;
  final VoidCallback onFinishEditing;
  final Function(Offset) onAddTextBlock;
  final VoidCallback onTitleTap;

  const InteractionLayer({
    super.key,
    required this.page,
    required this.isBlocked,
    required this.onFinishEditing,
    required this.onAddTextBlock,
    required this.onTitleTap,
  });

  @override
  ConsumerState<InteractionLayer> createState() => _InteractionLayerState();
}

class _InteractionLayerState extends ConsumerState<InteractionLayer> {
  bool _isStylusActive = false;
  bool _rejectCurrentGesture = false;

  void _handlePointerEvent(PointerEvent event, PalmRejectionMode mode) {
    if (mode == PalmRejectionMode.disabled) {
      _rejectCurrentGesture = false;
      return;
    }
    
    final bool isTouch = event.kind == PointerDeviceKind.touch;
    final bool isStylus = event.kind == PointerDeviceKind.stylus || event.kind == PointerDeviceKind.invertedStylus;

    if (isStylus && !_isStylusActive) {
      setState(() => _isStylusActive = true);
    }

    if (event is PointerDownEvent) {
      if (mode == PalmRejectionMode.enabled) {
        _rejectCurrentGesture = isTouch;
      } else if (mode == PalmRejectionMode.auto) {
        _rejectCurrentGesture = isTouch && _isStylusActive;
      } else {
        _rejectCurrentGesture = false;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final toolState = ref.watch(canvasInteractionProvider);
    final toolNotifier = ref.read(canvasInteractionProvider.notifier);
    final viewportState = ref.watch(canvasViewportProvider);

    final bool isDrawingTool = toolState.activeTool == ToolMode.draw || 
                               toolState.activeTool == ToolMode.eraser || 
                               toolState.activeTool == ToolMode.pixelEraser || 
                               toolState.activeTool == ToolMode.lasso;

    return Positioned.fill(
      child: Stack(
        children: [
          // 1. O Detector de Gestos com Bloqueio de Palma e Alta Frequência
          Positioned.fill(
            child: Listener(
              onPointerDown: (e) {
                _handlePointerEvent(e, toolState.palmRejectionMode);
                if (!widget.isBlocked && isDrawingTool && !_rejectCurrentGesture) {
                  ref.read(canvasUiProvider.notifier).setHudMode(true);
                  toolNotifier.activeToolLogic.onPanStart(e.localPosition, ref, widget.page);
                }
              },
              onPointerMove: (e) {
                _handlePointerEvent(e, toolState.palmRejectionMode);
                if (!widget.isBlocked && isDrawingTool && !_rejectCurrentGesture) {
                  toolNotifier.activeToolLogic.onPanUpdate(e.localPosition, e.delta, ref, widget.page);
                }
              },
              onPointerUp: (e) {
                if (!widget.isBlocked && isDrawingTool && !_rejectCurrentGesture) {
                  ref.read(canvasUiProvider.notifier).setHudMode(false);
                  toolNotifier.activeToolLogic.onPanEnd(ref, widget.page);
                }
              },
              onPointerCancel: (e) {
                if (!widget.isBlocked && isDrawingTool) {
                  ref.read(canvasUiProvider.notifier).setHudMode(false);
                  toolNotifier.activeToolLogic.onPanEnd(ref, widget.page);
                }
              },
              behavior: HitTestBehavior.translucent,
              child: AbsorbPointer(
                absorbing: _rejectCurrentGesture || 
                          toolState.activeTool == ToolMode.pan || 
                          isDrawingTool || // 🚀 v10.43: Gestão centralizada via Listener
                          viewportState.activePointerCount > 1,
                child: GestureDetector(
                  key: ValueKey('gesture_${viewportState.activePointerCount > 1}'),
                  behavior: HitTestBehavior.translucent,
                  onTapDown: !widget.isBlocked ? (details) {
                    toolNotifier.activeToolLogic.onTapDown(details.localPosition, ref, widget.page);
                  } : null,
                  onPanStart: !widget.isBlocked && !isDrawingTool ? (d) {
                    ref.read(canvasUiProvider.notifier).setHudMode(true);
                    toolNotifier.activeToolLogic.onPanStart(d.localPosition, ref, widget.page);
                  } : null,
                  onPanUpdate: !widget.isBlocked && !isDrawingTool ? (d) {
                    toolNotifier.activeToolLogic.onPanUpdate(d.localPosition, d.delta, ref, widget.page);
                  } : null,
                  onPanEnd: !widget.isBlocked && !isDrawingTool ? (_) {
                    ref.read(canvasUiProvider.notifier).setHudMode(false);
                    toolNotifier.activeToolLogic.onPanEnd(ref, widget.page);
                  } : null,
                ),
              ),
            ),
          ),

          // 2. Overlays Visuais
          IgnorePointer(
            child: Stack(
              children: [
                CanvasSelectionOverlay(page: widget.page),
                
                // 🚀 v10.50: Renderização de Desenho com Latência Zero
                // O Consumer isolado garante que apenas o CustomPaint reconstrói durante o desenho
                Consumer(
                  builder: (context, ref, _) {
                    final liveStroke = ref.watch(liveStrokeProvider);
                    if (liveStroke.isEmpty) return const SizedBox.shrink();

                    return RepaintBoundary(
                      child: CustomPaint(
                        size: Size.infinite,
                        painter: liveStroke.lassoPath != null
                          ? LiveLassoPainter(liveStroke.lassoPath!)
                          : ActiveStrokePainter(
                              currentPoints: liveStroke.points,
                              visualColor: Color(int.parse(liveStroke.colorHex.replaceFirst('#', '0xFF'))),
                              currentThickness: liveStroke.thickness,
                              opacity: liveStroke.opacity,
                              isHighlighter: liveStroke.isHighlighter,
                              brushType: liveStroke.brushType,
                            ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
