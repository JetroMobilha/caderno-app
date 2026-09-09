import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../providers/canvas_viewport_provider.dart';
import '../../models/local_page_model.dart';
import '../../providers/canvas_ui_provider.dart';
import '../../widgets/canvas_painter.dart';
import '../../models/canvas_enums.dart';
import '../../models/table_model.dart';
import '../toolbars/table_context_menu.dart';
import 'selection_overlay.dart';

/// 🚀 v10.16: Camada de Interação Profissional com Palm Rejection Ativo.
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
      if (mode == PalmRejectionMode.enabled) _rejectCurrentGesture = isTouch;
      else if (mode == PalmRejectionMode.auto) _rejectCurrentGesture = isTouch && _isStylusActive;
      else _rejectCurrentGesture = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final toolState = ref.watch(canvasInteractionProvider);
    final toolNotifier = ref.read(canvasInteractionProvider.notifier);
    final viewportState = ref.watch(canvasViewportProvider);

    return Positioned.fill(
      child: Stack(
        children: [
          // 1. O Detector de Gestos com Bloqueio de Palma
          Positioned.fill(
            child: Listener(
              onPointerDown: (e) => _handlePointerEvent(e, toolState.palmRejectionMode),
              onPointerMove: (e) => _handlePointerEvent(e, toolState.palmRejectionMode),
              behavior: HitTestBehavior.translucent,
              child: AbsorbPointer(
                absorbing: _rejectCurrentGesture || toolState.activeTool == ToolMode.pan || viewportState.activePointerCount > 1,
                child: GestureDetector(
                  key: ValueKey('gesture_${viewportState.activePointerCount > 1}'),
                  behavior: HitTestBehavior.translucent,
                  onTapDown: !widget.isBlocked ? (details) {
                    toolNotifier.activeToolLogic.onTapDown(details.localPosition, ref, widget.page);
                  } : null,
                  onPanStart: !widget.isBlocked ? (d) {
                    ref.read(canvasUiProvider.notifier).setHudMode(true);
                    toolNotifier.activeToolLogic.onPanStart(d.localPosition, ref, widget.page);
                  } : null,
                  onPanUpdate: !widget.isBlocked ? (d) {
                    toolNotifier.activeToolLogic.onPanUpdate(d.localPosition, d.delta, ref, widget.page);
                  } : null,
                  onPanEnd: !widget.isBlocked ? (_) {
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
                if (toolState.livePoints.isNotEmpty)
                  RepaintBoundary(
                    child: CustomPaint(
                      size: Size.infinite, 
                      painter: ActiveStrokePainter(
                        currentPoints: toolState.livePoints, 
                        visualColor: Color(int.parse(toolState.selectedColorHex.replaceFirst('#', '0xFF'))), 
                        currentThickness: toolState.selectedThickness, 
                        opacity: toolState.brushOpacity,
                        isHighlighter: toolState.isHighlighter, 
                        brushType: toolState.selectedBrushType, 
                        smoothingLevel: toolState.smoothingLevel
                      )
                    ),
                  ),
              ],
            ),
          ),
          
          // 3. Menus Interactivos (Fora do IgnorePointer)
          _buildInteractiveTableMenu(ref, toolState),
        ],
      ),
    );
  }

  Widget _buildInteractiveTableMenu(WidgetRef ref, CanvasInteractionState toolState) {
    if (toolState.selectedObjectIds.length != 1) return const SizedBox.shrink();
    if (toolState.activeHandle != HandleType.none) return const SizedBox.shrink();

    final obj = widget.page.objects.whereType<TableObject>().where(
      (o) => o.id == toolState.selectedObjectIds.first,
    ).firstOrNull;

    if (obj != null && (toolState.activeTool == ToolMode.table || toolState.activeTool == ToolMode.select || toolState.activeTool == ToolMode.organizer)) {
      return Positioned(
        left: obj.position.dx,
        top: math.max(10.0, obj.position.dy - 60.0),
        child: TableContextMenu(table: obj, position: obj.position),
      );
    }
    return const SizedBox.shrink();
  }
}
