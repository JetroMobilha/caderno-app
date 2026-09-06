import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/canvas_tool_provider.dart';
import '../models/local_page_model.dart';
import '../models/page_object.dart';
import '../models/stroke_model.dart';
import '../models/canvas_enums.dart';

class SelectionOverlay extends ConsumerWidget {
  final LocalPage page;
  final Size pageSize;

  const SelectionOverlay({
    super.key,
    required this.page,
    required this.pageSize,
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

    if (selectedIds.isEmpty) return const SizedBox.shrink();

    // 🚀 v3.1: Filtro robusto para evitar Bad state
    final selectedObjects = page.objects.where((o) => selectedIds.contains(o.id)).toList();
    if (selectedObjects.isEmpty) return const SizedBox.shrink();

    return Stack(
      clipBehavior: Clip.none,
      children: selectedObjects.map((obj) {
        final Rect baseBounds = _getObjectBounds(obj);
        
        // 🚀 v3.1: SINCRONIZAÇÃO TOTAL - Delta e Escala em tempo real
        final Rect bounds = baseBounds.shift(toolState.totalSelectionDelta);
        final double rotation = obj.rotation + toolState.liveRotation;
        
        // 🚀 Aplicar escala à moldura azul para feedback imersivo
        final double finalW = bounds.width * toolState.liveScale.width;
        final double finalH = bounds.height * toolState.liveScale.height;

        final bool isSingleSelection = selectedObjects.length == 1;
        // 🚀 v4.4: Ocultar alças no modo Organizador
        final bool showHandles = isSingleSelection && obj.type != 'stroke' && toolState.currentTool != ToolMode.organizer;
        
        return Positioned(
          left: bounds.left - 10,
          top: bounds.top - 10,
          child: Transform.rotate(
            angle: rotation,
            alignment: Alignment.center, 
            child: Container(
              width: finalW + 20,
              height: finalH + 20,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1976D2), width: 2.0),
                color: const Color(0x191976D2),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  if (showHandles) ...[
                    // 8 Alças - Acompanham a escala
                    _buildHandleItem(0, 0),
                    _buildHandleItem((finalW + 20) / 2, 0),
                    _buildHandleItem(finalW + 20, 0),
                    _buildHandleItem(finalW + 20, (finalH + 20) / 2),
                    _buildHandleItem(finalW + 20, finalH + 20),
                    _buildHandleItem((finalW + 20) / 2, finalH + 20),
                    _buildHandleItem(0, finalH + 20),
                    _buildHandleItem(0, (finalH + 20) / 2),

                    // Alça de Rotação
                    Positioned(
                      top: -55,
                      left: (finalW + 20) / 2 - 15,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _buildHandleCircle(icon: Icons.rotate_right_rounded, isRotate: true),
                          Container(width: 2, height: 26, color: const Color(0xFF1976D2)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildHandleItem(double x, double y) {
    return Positioned(
      left: x - 12,
      top: y - 12,
      child: _buildHandleCircle(),
    );
  }

  Widget _buildHandleCircle({IconData? icon, bool isRotate = false}) {
    return Container(
      width: isRotate ? 30 : 24, 
      height: isRotate ? 30 : 24,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF1976D2), width: 2.5),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
      ),
      child: Center(
        child: icon != null 
          ? Icon(icon, size: isRotate ? 18 : 14, color: const Color(0xFF1976D2)) 
          : Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1976D2), shape: BoxShape.circle)),
      ),
    );
  }

  Rect _getObjectBounds(PageObject obj) {
    if (obj is Stroke) {
      final s = obj;
      if (s.points.isEmpty) return Rect.zero;
      double minX = s.points.first.dx, maxX = s.points.first.dx;
      double minY = s.points.first.dy, maxY = s.points.first.dy;
      for (var pt in s.points) {
        if (pt.dx < minX) minX = pt.dx;
        if (pt.dx > maxX) maxX = pt.dx;
        if (pt.dy < minY) minY = pt.dy;
        if (pt.dy > maxY) maxY = pt.dy;
      }
      return Rect.fromLTRB(minX, minY, maxX, maxY);
    }
    return obj.position & obj.size;
  }
}
