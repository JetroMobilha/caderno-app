import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/explanation_model.dart';
import 'base_animator.dart';

class MathAnimator implements BaseAnimator {
  @override
  void paint(Canvas canvas, Size size, ExplanationModel model, double time) {
    if (model is! MathExplanation) return;

    final paint = Paint()
      ..color = model.color
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool first = true;

    // Simulação simples de uma função senoide para a base do motor
    // No futuro usaremos um parser de expressões para model.expression
    for (double x = 0; x < 200; x++) {
      // f(x) = sin(x * frequencia + tempo) * amplitude
      final double y = math.sin(x * 0.05) * 50;
      
      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }

    canvas.drawPath(path, paint);
    
    // Desenhar um ponto "seguidor" para ilustrar o movimento
    // Usando o parâmetro 'time' que vem do AnimationController (0.0 a 1.0)
    final double followX = time * 200.0;
    final double followY = math.sin(followX * 0.05) * 50;
    canvas.drawCircle(Offset(followX, followY), 5, paint..style = PaintingStyle.fill);
  }
}
