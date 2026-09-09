import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../models/canvas_enums.dart';

class BrushStyleSheet extends ConsumerWidget {
  const BrushStyleSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolState = ref.watch(canvasInteractionProvider);
    final toolNotifier = ref.read(canvasInteractionProvider.notifier);

    final List<Map<String, dynamic>> brushes = [
      {'type': BrushType.gel, 'name': 'Caneta Gel', 'icon': Icons.edit_rounded},
      {'type': BrushType.fountain, 'name': 'Tinteiro', 'icon': Icons.history_edu_rounded},
      {'type': BrushType.pencil, 'name': 'Lápis Grafite', 'icon': Icons.create_rounded},
      {'type': BrushType.marker, 'name': 'Marcador', 'icon': Icons.brush_rounded},
      {'type': BrushType.watercolor, 'name': 'Aguarela', 'icon': Icons.opacity_rounded},
      {'type': BrushType.crayon, 'name': 'Giz / Crayon', 'icon': Icons.gesture_rounded},
      {'type': BrushType.airbrush, 'name': 'Aerógrafo', 'icon': Icons.air_rounded},
      {'type': BrushType.neon, 'name': 'Neon / Glow', 'icon': Icons.wb_incandescent_outlined},
      {'type': BrushType.calligraphy, 'name': 'Caligrafia', 'icon': Icons.auto_fix_normal_rounded},
      {'type': BrushType.ribbon, 'name': 'Fita Ribbon', 'icon': Icons.strikethrough_s_rounded},
      {'type': BrushType.fineliner, 'name': 'Fineliner', 'icon': Icons.architecture_rounded},
      {'type': BrushType.monoline, 'name': 'Monoline', 'icon': Icons.fiber_manual_record_rounded},
    ];

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 20),
          Text('ESTÚDIO DE CANETAS', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold, letterSpacing: 1.2)),
          const SizedBox(height: 24),
          
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(color: Colors.black.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(16)),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_rounded, size: 18, color: Colors.blueAccent),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Suavização Bézier', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      Text('Arredonda traços automaticamente', style: TextStyle(fontSize: 11, color: Colors.black.withValues(alpha: 0.4))),
                    ],
                  ),
                ),
                Switch(
                  value: toolState.isSmoothingEnabled, 
                  onChanged: (v) => toolNotifier.setSmoothing(v),
                  activeColor: Colors.blueAccent,
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          SizedBox(
            height: 320,
            child: GridView.builder(
              shrinkWrap: true,
              physics: const BouncingScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                mainAxisSpacing: 12,
                crossAxisSpacing: 8,
                childAspectRatio: 0.7,
              ),
              itemCount: brushes.length,
              itemBuilder: (context, index) {
                final brush = brushes[index];
                final isSelected = toolState.selectedBrushType == brush['type'];
                
                return GestureDetector(
                  onTap: () {
                    toolNotifier.setBrushType(brush['type']);
                    Navigator.pop(context);
                  },
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        width: 48, height: 48,
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF0F4C5C) : Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: isSelected ? const Color(0xFF0F4C5C) : Colors.black12, width: 1.5),
                          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 3))],
                        ),
                        child: Center(
                          child: CustomPaint(
                            size: const Size(26, 26),
                            painter: _BrushPreviewPainter(
                              type: brush['type'], 
                              color: isSelected ? Colors.white : const Color(0xFF0F4C5C)
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Flexible(
                        child: Text(brush['name'], 
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(fontSize: 9, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? const Color(0xFF0F4C5C) : Colors.black87)
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}

class _BrushPreviewPainter extends CustomPainter {
  final BrushType type;
  final Color color;

  _BrushPreviewPainter({required this.type, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(5, size.height - 5)
      ..quadraticBezierTo(size.width / 2, -5, size.width - 5, size.height - 5);

    if (type == BrushType.neon) {
      canvas.drawPath(path, paint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)..strokeWidth = 6);
      canvas.drawPath(path, Paint()..color = Colors.white..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    } else if (type == BrushType.watercolor) {
      canvas.drawPath(path, paint..color = color.withValues(alpha: 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)..strokeWidth = 8);
    } else if (type == BrushType.marker) {
      canvas.drawPath(path, paint..strokeCap = StrokeCap.square..strokeWidth = 5);
    } else if (type == BrushType.pencil) {
      canvas.drawPath(path, paint..color = color.withValues(alpha: 0.7)..strokeWidth = 2);
    } else if (type == BrushType.calligraphy) {
       canvas.drawPath(path, paint..strokeCap = StrokeCap.butt..strokeWidth = 6);
    } else if (type == BrushType.crayon) {
       canvas.drawPath(path, paint..strokeWidth = 5..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.0));
    } else if (type == BrushType.airbrush) {
       canvas.drawPath(path, paint..color = color.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)..strokeWidth = 10);
    } else if (type == BrushType.fineliner) {
       canvas.drawPath(path, paint..strokeWidth = 1.2..strokeCap = StrokeCap.butt);
    } else if (type == BrushType.monoline) {
       canvas.drawPath(path, paint..strokeWidth = 4..strokeCap = StrokeCap.round);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
