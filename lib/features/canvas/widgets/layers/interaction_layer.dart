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

/// 🚀 v10.80: Camada de Interação de Alta Fidelidade com Duelo de Intenções.
/// 
/// Implementa uma arena de arbitragem onde múltiplos toques podem desenhar 
/// simultaneamente (latência zero), mas apenas o toque com maior intenção cinética 
/// sobrevive à fase de validação.
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
  int? _activeDrawingPointerId; 
  
  // 🛡️ Estados de Arbitragem
  bool _isKingValidated = false; // Se o rei atual é inquestionável (Sénior)
  final Set<int> _allActivePointers = {};
  final Map<int, _PointerValidation> _pendingPointers = {};
  
  static const double kValidationThreshold = 80.0; // Distância para consolidar o trono
  static const double kOverthrowRatio = 1.8; // Quão melhor o desafiante deve ser para roubar o trono

  void _handlePointerEvent(PointerEvent event, PalmRejectionMode mode) {
    final bool isTouch = event.kind == PointerDeviceKind.touch;
    final bool isStylus = event.kind == PointerDeviceKind.stylus || event.kind == PointerDeviceKind.invertedStylus;
    final bool isMouse = event.kind == PointerDeviceKind.mouse;
    
    final toolNotifier = ref.read(canvasInteractionProvider.notifier);
    final toolState = ref.read(canvasInteractionProvider);
    final bool isDrawingTool = toolState.activeTool == ToolMode.draw || 
                               toolState.activeTool == ToolMode.eraser || 
                               toolState.activeTool == ToolMode.pixelEraser;

    if (isStylus && !_isStylusActive) {
      setState(() => _isStylusActive = true);
    }

    if (event is PointerDownEvent) {
      _allActivePointers.add(event.pointer);

      // 1. Regra de Navegação: 3 dedos cancelam qualquer desenho em curso
      if (_allActivePointers.length >= 3) {
        _abortAllDrawing();
        return;
      }

      // 2. Prioridade Máxima: Stylus ou Mouse (Ganham o trono e validam na hora)
      if (isStylus || isMouse) {
        if (_activeDrawingPointerId != null && _activeDrawingPointerId != event.pointer) {
          debugPrint('👑 [Palm-Arena] ${isStylus ? "Stylus" : "Mouse"} assumiu o trono por prioridade.');
          ref.read(liveStrokeProvider).removeStroke(_activeDrawingPointerId!);
        }
        _activeDrawingPointerId = event.pointer;
        _isKingValidated = true;
        _pendingPointers.clear();
        _pendingPointers[event.pointer] = _PointerValidation(startPosition: event.localPosition);
        _startDrawingForPointer(event, toolNotifier);
        return;
      }

      // 3. Toque de Dedo: Início do Duelo
      if (isTouch) {
        if (mode == PalmRejectionMode.enabled || (mode == PalmRejectionMode.auto && _isStylusActive)) return;

        if (_allActivePointers.length <= 2) {
           _pendingPointers[event.pointer] = _PointerValidation(startPosition: event.localPosition);
           _startDrawingForPointer(event, toolNotifier);
           
           if (_activeDrawingPointerId == null) {
             _activeDrawingPointerId = event.pointer;
             _isKingValidated = false;
             debugPrint('👑 [Palm-Arena] Ponteiro ${event.pointer} iniciou como Rei Provisório');
           } else {
             debugPrint('⚔️ [Palm-Arena] Ponteiro ${event.pointer} iniciou como Desafiante');
           }
        }
      }
    }

    if (event is PointerMoveEvent && (isTouch || isMouse || isStylus)) {
      final validation = _pendingPointers[event.pointer];
      if (validation != null) {
        validation.currentPosition = event.localPosition;
        
        // A. Desenho Visual (Todos os envolvidos no duelo desenham para latência zero)
        if (event.pointer == _activeDrawingPointerId && !widget.isBlocked && isDrawingTool) {
          toolNotifier.activeToolLogic.onPanUpdate(event.localPosition, event.delta, ref, widget.page, pointerId: event.pointer);
          
          // 🚀 v10.87: Atualizar cursor da borracha
          if (toolState.activeTool == ToolMode.pixelEraser) {
            ref.read(canvasUiProvider.notifier).setEraserPosition(event.localPosition);
          }
        } else {
          ref.read(liveStrokeProvider).update(event.pointer, event.localPosition);
        }

        // B. Lógica de Arbitragem (Apenas para Toque)
        if (isTouch) {
          final double myScore = validation.getScore();

          // 1. Desafiante tenta derrubar Rei Provisório
          if (_activeDrawingPointerId != null && event.pointer != _activeDrawingPointerId && !_isKingValidated) {
            final kingValidation = _pendingPointers[_activeDrawingPointerId];
            final double kingScore = kingValidation?.getScore() ?? 0.0;

            if (myScore > kingScore * kOverthrowRatio && myScore > 0.5) {
               debugPrint('👑 [Palm-Arena] GOLPE! Desafiante ${event.pointer} (Score: ${myScore.toStringAsFixed(2)}) destronou o Rei $_activeDrawingPointerId (Score: ${kingScore.toStringAsFixed(2)})');
               ref.read(liveStrokeProvider).removeStroke(_activeDrawingPointerId!);
               _activeDrawingPointerId = event.pointer;
               // O novo rei herda o estado de provisório até ser legitimado
            }
          }

          // 2. Legitimação do Rei
          if (event.pointer == _activeDrawingPointerId && !_isKingValidated) {
            if (validation.distanceMoved > kValidationThreshold) {
              _isKingValidated = true;
              debugPrint('✅ [Palm-Arena] Rei ${event.pointer} legitimado como Sénior.');
              // Ao legitimar, limpamos os outros desafiantes que perderam
              _pendingPointers.forEach((id, val) {
                if (id != _activeDrawingPointerId) ref.read(liveStrokeProvider).removeStroke(id);
              });
            }
          }

          // 3. Limpeza de ruído se já houver um Rei Sénior
          if (_isKingValidated && event.pointer != _activeDrawingPointerId) {
            ref.read(liveStrokeProvider).removeStroke(event.pointer);
            _pendingPointers.remove(event.pointer);
          }
        }
      }
    }

    if (event is PointerUpEvent || event is PointerCancelEvent) {
      _allActivePointers.remove(event.pointer);
      _pendingPointers.remove(event.pointer);
      
      if (event.pointer == _activeDrawingPointerId) {
         if (!widget.isBlocked && isDrawingTool) {
           toolNotifier.activeToolLogic.onPanEnd(ref, widget.page, pointerId: event.pointer);
         }
         _activeDrawingPointerId = null;
         _isKingValidated = false;
         
         // Limpar cursor da borracha
         ref.read(canvasUiProvider.notifier).setEraserPosition(null);
      } else {
         ref.read(liveStrokeProvider).removeStroke(event.pointer);
      }
    }
  }

  void _abortAllDrawing() {
    _activeDrawingPointerId = null;
    _isKingValidated = false;
    _pendingPointers.clear();
    ref.read(liveStrokeProvider).clear();
  }

  void _startDrawingForPointer(PointerEvent event, dynamic toolNotifier) {
    final toolState = ref.read(canvasInteractionProvider);
    final bool isDrawingTool = toolState.activeTool == ToolMode.draw || 
                               toolState.activeTool == ToolMode.eraser || 
                               toolState.activeTool == ToolMode.pixelEraser;
                               
    if (isDrawingTool && !widget.isBlocked) {
      ref.read(canvasUiProvider.notifier).setHudMode(true);
      toolNotifier.activeToolLogic.onPanStart(event.localPosition, ref, widget.page, pointerId: event.pointer);
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
          Positioned.fill(
            child: Listener(
              onPointerDown: (e) => _handlePointerEvent(e, toolState.palmRejectionMode),
              onPointerMove: (e) => _handlePointerEvent(e, toolState.palmRejectionMode),
              onPointerUp: (e) => _handlePointerEvent(e, toolState.palmRejectionMode),
              onPointerCancel: (e) => _handlePointerEvent(e, toolState.palmRejectionMode),
              behavior: HitTestBehavior.translucent,
              child: AbsorbPointer(
                absorbing: toolState.activeTool == ToolMode.pan || 
                          isDrawingTool || 
                          viewportState.activePointerCount >= 3,
                child: GestureDetector(
                  key: ValueKey('gesture_${viewportState.activePointerCount >= 3}'),
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

          IgnorePointer(
            child: Stack(
              children: [
                CanvasSelectionOverlay(page: widget.page),
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
                              activeStrokes: liveStroke.activeStrokes,
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

                // 3. Cursor da Borracha
                Consumer(
                  builder: (context, ref, _) {
                    final uiState = ref.watch(canvasUiProvider);
                    final toolState = ref.watch(canvasInteractionProvider);
                    if (uiState.eraserPosition == null || toolState.activeTool != ToolMode.pixelEraser) {
                      return const SizedBox.shrink();
                    }

                    return CustomPaint(
                      size: Size.infinite,
                      painter: EraserCursorPainter(
                        position: uiState.eraserPosition!,
                        radius: toolState.selectedThickness * 1.5,
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

class EraserCursorPainter extends CustomPainter {
  final Offset position;
  final double radius;

  EraserCursorPainter({required this.position, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.1)
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.black.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(position, radius, paint);
    canvas.drawCircle(position, radius, borderPaint);
    
    // Pequena cruz no centro para precisão
    canvas.drawLine(position - Offset(4, 0), position + Offset(4, 0), borderPaint);
    canvas.drawLine(position - Offset(0, 4), position + Offset(0, 4), borderPaint);
  }

  @override
  bool shouldRepaint(EraserCursorPainter oldDelegate) => 
      oldDelegate.position != position || oldDelegate.radius != radius;
}

class _PointerValidation {
  final Offset startPosition;
  Offset currentPosition;
  final DateTime startTime;

  _PointerValidation({required this.startPosition}) 
    : currentPosition = startPosition,
      startTime = DateTime.now();

  double get distanceMoved => (currentPosition - startPosition).distance;

  double getScore() {
    final double dist = distanceMoved;
    final int ms = DateTime.now().difference(startTime).inMilliseconds;
    if (ms < 15) return 0.0;
    // Score prioriza vetores de movimento longos em curto espaço de tempo
    return (dist * dist) / ms;
  }
}
