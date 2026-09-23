import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/explanation_model.dart';
import 'base_animator.dart';

class MathAnimator implements BaseAnimator {
  @override
  void paint(Canvas canvas, Size size, ExplanationModel model, double time) {
    if (model is! MathExplanation) return;

    switch (model.kind) {
      case MathKind.sineWave:
      case MathKind.polynomial:
        _paintFunctionGraph(canvas, model, time);
        break;
      case MathKind.trigCircle:
        _paintTrigCircle(canvas, model, time);
        break;
    }
  }

  void _paintFunctionGraph(Canvas canvas, MathExplanation model, double time) {
    const double width = 280.0;
    const double height = 160.0;
    final Offset center = Offset.zero;

    // 1. Eixos Cartesianos
    if (model.showAxes) {
      final axisPaint = Paint()
        ..color = Colors.black45
        ..strokeWidth = 1.5;
      
      // Eixo X
      canvas.drawLine(Offset(-width / 2, 0), Offset(width / 2, 0), axisPaint);
      // Eixo Y
      canvas.drawLine(Offset(0, -height / 2), Offset(0, height / 2), axisPaint);

      // Seta X
      canvas.drawLine(Offset(width / 2, 0), Offset(width / 2 - 8, -4), axisPaint);
      canvas.drawLine(Offset(width / 2, 0), Offset(width / 2 - 8, 4), axisPaint);

      // Seta Y
      canvas.drawLine(Offset(0, -height / 2), Offset(-4, -height / 2 + 8), axisPaint);
      canvas.drawLine(Offset(0, -height / 2), Offset(4, -height / 2 + 8), axisPaint);
    }

    // 2. Gráfico da Função
    final curvePaint = Paint()
      ..color = model.color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    final path = Path();
    bool first = true;

    const double step = 2.0;
    for (double xPx = -width / 2; xPx <= width / 2; xPx += step) {
      final double normalizedX = xPx * 0.04 * model.frequency;
      
      double normalizedY;
      if (model.kind == MathKind.sineWave) {
        normalizedY = math.sin(normalizedX);
      } else {
        // Polinomial simples f(x) = 0.5 * x^2 - 1 ou similar escalonado
        normalizedY = 0.08 * (normalizedX * normalizedX) - 1.0;
      }

      final double yPx = -normalizedY * model.amplitude;

      if (yPx.abs() <= height / 2 + 20) {
        if (first) {
          path.moveTo(xPx, yPx);
          first = false;
        } else {
          path.lineTo(xPx, yPx);
        }
      }
    }

    canvas.drawPath(path, curvePaint);

    // 3. Ponto Seguidor Animado
    if (model.isPlaying) {
      final double cycleX = (-width / 2) + (time * width);
      final double normX = cycleX * 0.04 * model.frequency;
      
      final double normY = model.kind == MathKind.sineWave
          ? math.sin(normX)
          : (0.08 * (normX * normX) - 1.0);
      
      final double cycleY = -normY * model.amplitude;

      // Ponto sobre a curva
      canvas.drawCircle(Offset(cycleX, cycleY), 6.0, Paint()..color = Colors.redAccent);
      canvas.drawCircle(Offset(cycleX, cycleY), 3.0, Paint()..color = Colors.white);

      // Linhas projetadas nos eixos
      if (model.showAxes) {
        final projPaint = Paint()
          ..color = Colors.redAccent.withValues(alpha: 0.5)
          ..strokeWidth = 1.0
          ..style = PaintingStyle.stroke;

        canvas.drawLine(Offset(cycleX, cycleY), Offset(cycleX, 0), projPaint);
        canvas.drawLine(Offset(cycleX, cycleY), Offset(0, cycleY), projPaint);
      }
    }
  }

  void _paintTrigCircle(Canvas canvas, MathExplanation model, double time) {
    const double radius = 70.0;

    // 1. Círculo Unitário
    final circlePaint = Paint()
      ..color = Colors.indigo.shade300
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final axisPaint = Paint()
      ..color = Colors.black38
      ..strokeWidth = 1.0;

    canvas.drawCircle(Offset.zero, radius, circlePaint);
    canvas.drawLine(const Offset(-radius - 20, 0), const Offset(radius + 20, 0), axisPaint);
    canvas.drawLine(const Offset(0, -radius - 20), const Offset(0, radius + 20), axisPaint);

    // 2. Ângulo Animado theta (0 a 2pi)
    final double theta = time * 2 * math.pi * model.frequency;
    final double px = radius * math.cos(theta);
    final double py = -radius * math.sin(theta); // Y invertido no Canvas

    // Linha do raio (hipotenusa)
    canvas.drawLine(Offset.zero, Offset(px, py), Paint()..color = Colors.black87..strokeWidth = 2.5);

    // Projetar Seno (linha vertical vermelha)
    canvas.drawLine(Offset(px, 0), Offset(px, py), Paint()..color = Colors.redAccent..strokeWidth = 2.5);

    // Projetar Cosseno (linha horizontal azul)
    canvas.drawLine(Offset.zero, Offset(px, 0), Paint()..color = Colors.blueAccent..strokeWidth = 2.5);

    // Ponto na circunferência
    canvas.drawCircle(Offset(px, py), 5.0, Paint()..color = Colors.purple);

    // Arco do Ângulo
    final arcRect = Rect.fromCircle(center: Offset.zero, radius: 20.0);
    canvas.drawArc(arcRect, 0, -theta, false, Paint()..color = Colors.orange..strokeWidth = 2.0..style = PaintingStyle.stroke);
  }
}
