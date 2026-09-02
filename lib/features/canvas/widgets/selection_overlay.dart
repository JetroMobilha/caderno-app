import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/canvas_tool_provider.dart';
import '../models/local_page_model.dart';
import '../models/page_object.dart';
import '../models/stroke_model.dart';

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
    };

    if (selectedIds.isEmpty) return const SizedBox.shrink();

    // Encontrar objetos selecionados
    final selectedObjects = page.objects.where((o) => selectedIds.contains(o.id)).toList();

    return Stack(
      children: selectedObjects.map((obj) {
        final Rect bounds = _getObjectBounds(obj);
        
        return Positioned(
          left: bounds.left - 4,
          top: bounds.top - 4,
          child: Transform.rotate(
            angle: obj.rotation,
            child: Container(
              width: bounds.width + 8,
              height: bounds.height + 8,
              decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFF1976D2), width: 1.5),
                color: const Color(0x191976D2),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  // Alças de redimensionamento (simplificado)
                  if (obj.type != 'stroke') ...[
                    Positioned(
                      right: -10, bottom: -10,
                      child: _buildHandle(Icons.open_in_full),
                    ),
                    Positioned(
                      top: -30, left: (bounds.width / 2),
                      child: _buildHandle(Icons.rotate_right),
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

  Widget _buildHandle(IconData icon) {
    return Container(
      width: 24, height: 24,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4)],
      ),
      child: Icon(icon, size: 14, color: const Color(0xFF1976D2)),
    );
  }
}
