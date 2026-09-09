import 'package:flutter/material.dart';
import '../models/canvas_enums.dart';

/// 🚀 v10.15: Pintor compartilhado para visualização do efeito de cada ponta de pincel.
class BrushPreviewPainter extends CustomPainter {
  final BrushType type;
  final Color color;
  final double strokeWidth;

  BrushPreviewPainter({
    required this.type, 
    required this.color,
    this.strokeWidth = 3.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path()
      ..moveTo(size.width * 0.1, size.height * 0.8)
      ..quadraticBezierTo(size.width * 0.5, size.height * 0.1, size.width * 0.9, size.height * 0.8);

    if (type == BrushType.neon) {
      canvas.drawPath(path, paint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0)..strokeWidth = strokeWidth * 2);
      canvas.drawPath(path, Paint()..color = Colors.white..strokeWidth = 1.5..style = PaintingStyle.stroke..strokeCap = StrokeCap.round);
    } else if (type == BrushType.watercolor) {
      canvas.drawPath(path, paint..color = color.withValues(alpha: 0.4)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0)..strokeWidth = strokeWidth * 2.5);
    } else if (type == BrushType.marker) {
      canvas.drawPath(path, paint..strokeCap = StrokeCap.square..strokeWidth = strokeWidth * 1.6);
    } else if (type == BrushType.pencil) {
      canvas.drawPath(path, paint..color = color.withValues(alpha: 0.7)..strokeWidth = strokeWidth * 0.6);
    } else if (type == BrushType.calligraphy) {
       canvas.drawPath(path, paint..strokeCap = StrokeCap.butt..strokeWidth = strokeWidth * 2);
    } else if (type == BrushType.crayon) {
       canvas.drawPath(path, paint..strokeWidth = strokeWidth * 1.6..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.0));
    } else if (type == BrushType.airbrush) {
       canvas.drawPath(path, paint..color = color.withValues(alpha: 0.3)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6.0)..strokeWidth = strokeWidth * 3);
    } else if (type == BrushType.fineliner) {
       canvas.drawPath(path, paint..strokeWidth = 1.2..strokeCap = StrokeCap.butt);
    } else if (type == BrushType.monoline) {
       canvas.drawPath(path, paint..strokeWidth = strokeWidth * 1.3..strokeCap = StrokeCap.round);
    } else {
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(covariant BrushPreviewPainter oldDelegate) => 
    oldDelegate.type != type || oldDelegate.color != color || oldDelegate.strokeWidth != strokeWidth;
}

class BrushPreviewWidget extends StatelessWidget {
  final BrushType type;
  final Color color;
  final Size size;

  const BrushPreviewWidget({
    super.key, 
    required this.type, 
    required this.color, 
    this.size = const Size(30, 20)
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: size,
      painter: BrushPreviewPainter(type: type, color: color),
    );
  }
}
