import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/explanation_model.dart';
import 'base_animator.dart';

class EngineeringAnimator implements BaseAnimator {
  @override
  void paint(Canvas canvas, Size size, ExplanationModel model, double time) {
    if (model is! EngineeringExplanation) return;

    final double rotation = model.isPlaying ? (time * 2 * math.pi * model.angularVelocity) : 0;

    canvas.save();
    canvas.rotate(rotation);

    final paint = Paint()
      ..color = Colors.blueGrey
      ..style = PaintingStyle.fill;

    final strokePaint = Paint()
      ..color = Colors.black87
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    if (model.isGear) {
      _drawGear(canvas, model.radius, model.toothCount, paint, strokePaint);
    } else {
      _drawPulley(canvas, model.radius, paint, strokePaint);
    }

    // Centro / Eixo
    canvas.drawCircle(Offset.zero, 5, Paint()..color = Colors.black);
    canvas.restore();
  }

  void _drawGear(Canvas canvas, double radius, int teeth, Paint fill, Paint stroke) {
    final Path path = Path();
    final double angleStep = (2 * math.pi) / teeth;
    final double toothHeight = radius * 0.2;

    for (int i = 0; i < teeth; i++) {
      final double angle = i * angleStep;
      
      // Desenhar o contorno do dente da engrenagem
      final double x1 = math.cos(angle - angleStep * 0.25) * radius;
      final double y1 = math.sin(angle - angleStep * 0.25) * radius;
      
      final double x2 = math.cos(angle - angleStep * 0.15) * (radius + toothHeight);
      final double y2 = math.sin(angle - angleStep * 0.15) * (radius + toothHeight);
      
      final double x3 = math.cos(angle + angleStep * 0.15) * (radius + toothHeight);
      final double y3 = math.sin(angle + angleStep * 0.15) * (radius + toothHeight);
      
      final double x4 = math.cos(angle + angleStep * 0.25) * radius;
      final double y4 = math.sin(angle + angleStep * 0.25) * radius;

      if (i == 0) path.moveTo(x1, y1);
      path.lineTo(x1, y1);
      path.lineTo(x2, y2);
      path.lineTo(x3, y3);
      path.lineTo(x4, y4);
    }
    path.close();

    canvas.drawPath(path, fill);
    canvas.drawPath(path, stroke);
    
    // Círculo interno para detalhe
    canvas.drawCircle(Offset.zero, radius * 0.7, stroke);
  }

  void _drawPulley(Canvas canvas, double radius, Paint fill, Paint stroke) {
    canvas.drawCircle(Offset.zero, radius, fill);
    canvas.drawCircle(Offset.zero, radius, stroke);
    canvas.drawCircle(Offset.zero, radius * 0.85, stroke);
    
    // Raios da polia para ver a rotação
    for (int i = 0; i < 4; i++) {
      final double angle = (i * math.pi / 2);
      canvas.drawLine(
        Offset.zero, 
        Offset(math.cos(angle) * radius, math.sin(angle) * radius), 
        stroke
      );
    }
  }
}
