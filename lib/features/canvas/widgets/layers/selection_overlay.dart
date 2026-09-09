import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../providers/canvas_viewport_provider.dart';
import '../../models/local_page_model.dart';
import '../../models/page_object.dart';
import '../../models/table_model.dart';
import '../../models/canvas_enums.dart';
import '../../services/transform_service.dart';

/// 🚀 v10.10: Camada Visual de Seleção Polida e Zoom-Aware.
class CanvasSelectionOverlay extends ConsumerWidget {
  final LocalPage page;

  const CanvasSelectionOverlay({super.key, required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolState = ref.watch(canvasToolProvider);

    if (toolState.selectedObjectIds.isEmpty) return const SizedBox.shrink();

    final List<PageObject> selectedObjects = page.objects
        .where((o) => toolState.selectedObjectIds.contains(o.id))
        .toList();

    if (selectedObjects.isEmpty) return const SizedBox.shrink();

    final Rect baseBounds = TransformService.getCombinedBounds(selectedObjects);
    final bool isSingle = selectedObjects.length == 1;
    final PageObject? firstObj = isSingle ? selectedObjects.first : null;

    final Offset position = baseBounds.topLeft + toolState.totalSelectionDelta;
    final double rotation = (isSingle ? firstObj!.rotation : 0.0) + toolState.liveRotation;
    final Size size = Size(
      baseBounds.width * toolState.liveScale.width,
      baseBounds.height * toolState.liveScale.height,
    );

    final bool isLocked = selectedObjects.any((o) => o.isLocked);
    final Color primaryColor = isLocked ? Colors.orange : const Color(0xFF0F4C5C);

    // Ajuste de escala visual
    final viewportState = ref.watch(canvasViewportProvider);
    final double currentScale = viewportState.currentPageClientId != null 
        ? ref.read(canvasViewportProvider.notifier).getControllerFor(viewportState.currentPageClientId!).value.getMaxScaleOnAxis()
        : 1.0;
    
    final double handleSize = 14.0 / currentScale;
    final double borderThickness = 1.5 / currentScale;

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              child: Transform.rotate(
                angle: rotation,
                alignment: Alignment.center,
                child: Container(
                  width: size.width,
                  height: size.height,
                  decoration: BoxDecoration(
                    border: Border.all(color: primaryColor, width: borderThickness),
                    color: primaryColor.withOpacity(0.02),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (isLocked) 
                        Center(child: Icon(Icons.lock_outline_rounded, color: Colors.orange, size: 24 / currentScale)),
                        
                      if (!isLocked && toolState.isTransformMode) ...[
                        _buildHandle(HandleType.topLeft, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.topCenter, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.topRight, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.middleLeft, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.middleRight, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.bottomLeft, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.bottomCenter, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.bottomRight, primaryColor, handleSize, borderThickness),
                        _buildRotationKnob(primaryColor, handleSize, borderThickness, currentScale),
                      ],

                      if (!isLocked && isSingle && firstObj is TableObject && toolState.activeTool == ToolMode.table)
                        ..._buildTableSpecificHandles(firstObj as TableObject, primaryColor, currentScale),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(HandleType type, Color color, double size, double thickness) {
    Alignment alignment;
    switch (type) {
      case HandleType.topLeft: alignment = Alignment.topLeft; break;
      case HandleType.topCenter: alignment = Alignment.topCenter; break;
      case HandleType.topRight: alignment = Alignment.topRight; break;
      case HandleType.middleLeft: alignment = Alignment.centerLeft; break;
      case HandleType.middleRight: alignment = Alignment.centerRight; break;
      case HandleType.bottomLeft: alignment = Alignment.bottomLeft; break;
      case HandleType.bottomCenter: alignment = Alignment.bottomCenter; break;
      case HandleType.bottomRight: alignment = Alignment.bottomRight; break;
      default: alignment = Alignment.center;
    }

    return Align(
      alignment: alignment,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: color, width: thickness * 1.2),
          borderRadius: BorderRadius.circular(size * 0.15),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 2 / thickness)],
        ),
      ),
    );
  }

  Widget _buildRotationKnob(Color color, double size, double thickness, double scale) {
    return Align(
      alignment: const Alignment(0, -1.25),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: thickness, height: 20 / scale, color: color),
          Container(
            width: size * 1.6, height: size * 1.6,
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: color, width: thickness * 1.2),
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4 / scale)],
            ),
            child: Icon(Icons.sync_rounded, size: size * 0.9, color: color),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildTableSpecificHandles(TableObject table, Color color, double scale) {
    final List<Widget> handles = [];
    double currentX = 0;
    for (int i = 0; i < table.columnWidths.length; i++) {
      currentX += table.columnWidths[i];
      handles.add(Positioned(left: currentX - (4 / scale), top: 0, bottom: 0, width: 8 / scale, child: Container(decoration: BoxDecoration(border: Border(right: BorderSide(color: color.withOpacity(0.4), width: 2 / scale))))));
    }
    return handles;
  }
}
