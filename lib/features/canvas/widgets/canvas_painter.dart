import 'package:flutter/material.dart';
import '../models/stroke_model.dart';

Path buildSmoothPath(List<Offset> points) {
  final path = Path();
  if (points.isEmpty) return path;
  path.moveTo(points.first.dx, points.first.dy);
  if (points.length == 1) {
    path.addOval(Rect.fromCircle(center: points.first, radius: 0.5));
    return path;
  }
  for (int i = 1; i < points.length; i++) { path.lineTo(points[i].dx, points[i].dy); }
  return path;
}

class StaticNotebookPainter extends CustomPainter {
  final List<Stroke> strokes;
  final String lineType;
  final Set<String> selectedStrokeIds; // 🚀 RESTAURADO
  final Rect? selectionRect;            // 🚀 RESTAURADO

  StaticNotebookPainter({
    required this.strokes,
    required this.lineType,
    required this.selectedStrokeIds,
    required this.selectionRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final bgPaint = Paint()..color = const Color(0xFF1B365D).withOpacity(0.18)..strokeWidth = 1.0;

    // Desenho das Grelhas de Fundo
    if (lineType == 'ruled') {
      canvas.drawLine(const Offset(60, 0), Offset(60, size.height), Paint()..color = Colors.redAccent.withOpacity(0.4)..strokeWidth = 1.5);
      for (double y = 90; y < size.height - 60; y += 28) {
        canvas.drawLine(Offset(60, y), Offset(size.width - 20, y), bgPaint);
      }
    } else if (lineType == 'grid') {
      for (double y = 90; y < size.height - 60; y += 25) canvas.drawLine(Offset(marginCalculate(size), y), Offset(size.width - 20, y), bgPaint);
      for (double x = 20; x < size.width - 20; x += 25) canvas.drawLine(Offset(x, 90), Offset(x, size.height - 60), bgPaint);
    }

    // Renderização dos Traços + Neon de Foco de Seleção
    for (final stroke in strokes) {
      final bool isSelected = selectedStrokeIds.contains(stroke.id);

      final paint = Paint()
        ..color = Color(int.parse(stroke.color.replaceFirst('#', '0xFF')))
        ..strokeWidth = stroke.thickness
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (isSelected && stroke.points.isNotEmpty) {
        double minX = stroke.points.first.dx, maxX = stroke.points.first.dx;
        double minY = stroke.points.first.dy, maxY = stroke.points.first.dy;
        for (var pt in stroke.points) {
          if (pt.dx < minX) minX = pt.dx; if (pt.dx > maxX) maxX = pt.dx;
          if (pt.dy < minY) minY = pt.dy; if (pt.dy > maxY) maxY = pt.dy;
        }
        final Rect bounds = Rect.fromLTRB(minX - 6, minY - 6, maxX + 6, maxY + 6);
        canvas.drawRect(bounds, Paint()..color = const Color(0x1F1976D2)..style = PaintingStyle.fill);
        canvas.drawRect(bounds, Paint()..color = const Color(0xFF1976D2)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      }

      canvas.drawPath(buildSmoothPath(stroke.points), paint);
    }

    // Desenho da caixa de arrasto do Laço Azul
    if (selectionRect != null) {
      canvas.drawRect(selectionRect!, Paint()..color = const Color(0x190F4C5C)..style = PaintingStyle.fill);
      canvas.drawRect(selectionRect!, Paint()..color = const Color(0xFF0F4C5C)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  double marginCalculate(Size size) => 20.0;

  @override
  bool shouldRepaint(StaticNotebookPainter oldDelegate) => true;
}

class ActiveStrokePainter extends CustomPainter {
  final List<Offset> currentPoints;
  final String currentColor;
  final double currentThickness;

  ActiveStrokePainter({required this.currentPoints, required this.currentColor, required this.currentThickness});

  @override
  void paint(Canvas canvas, Size size) {
    if (currentPoints.isEmpty) return;
    final paint = Paint()
      ..color = Color(int.parse(currentColor.replaceFirst('#', '0xFF')))
      ..strokeWidth = currentThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(buildSmoothPath(currentPoints), paint);
  }

  @override
  bool shouldRepaint(ActiveStrokePainter oldDelegate) => true;
}