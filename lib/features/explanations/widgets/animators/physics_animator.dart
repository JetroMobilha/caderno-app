import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/explanation_model.dart';
import 'base_animator.dart';

class PhysicsAnimator implements BaseAnimator {
  @override
  void paint(Canvas canvas, Size size, ExplanationModel model, double time) {
    if (model is! PhysicsExplanation) return;

    // Calcular deslocamento baseado na velocidade e tempo se estiver a correr
    Offset effectiveOffset = Offset.zero;
    if (model.isPlaying) {
      // Simulação visual simples: s = v * t
      // Como o 'time' do AnimationController vai de 0 a 1 em 1 segundo
      effectiveOffset = model.velocity * time;
    }

    canvas.save();
    canvas.translate(effectiveOffset.dx, effectiveOffset.dy);

    final bodyPaint = Paint()
      ..color = Colors.orange.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    final borderPaint = Paint()
      ..color = Colors.orange.shade900
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final vectorPaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // 1. Desenhar o Corpo (Representado por um Bloco/Retângulo)
    const double bodyWidth = 60.0;
    const double bodyHeight = 40.0;
    final Rect rect = Rect.fromLTWH(-bodyWidth / 2, -bodyHeight / 2, bodyWidth, bodyHeight);
    
    canvas.drawRect(rect, bodyPaint);
    canvas.drawRect(rect, borderPaint);

    // 2. Desenhar Centro de Massa
    canvas.drawCircle(Offset.zero, 3, Paint()..color = Colors.black);

    // 3. Desenhar Vetores de Força
    for (var force in model.forces) {
      _drawArrow(canvas, Offset.zero, force, vectorPaint);
    }

    // 4. Desenhar Vetor Velocidade (se existir)
    if (model.velocity != Offset.zero) {
      _drawArrow(canvas, Offset.zero, model.velocity, Paint()
        ..color = Colors.blue
        ..strokeWidth = 2.0
        ..style = PaintingStyle.stroke);
    }

    canvas.restore();
  }

  void _drawArrow(Canvas canvas, Offset start, Offset vector, Paint paint) {
    if (vector.distance < 1.0) return;

    final double headSize = 10.0;
    final Offset end = start + vector;
    
    // Linha principal
    canvas.drawLine(start, end, paint);

    // Cabeça da seta
    final double angle = math.atan2(vector.dy, vector.dx);
    final Path path = Path();
    path.moveTo(end.dx, end.dy);
    path.lineTo(
      end.dx - headSize * math.cos(angle - math.pi / 6),
      end.dy - headSize * math.sin(angle - math.pi / 6),
    );
    path.lineTo(
      end.dx - headSize * math.cos(angle + math.pi / 6),
      end.dy - headSize * math.sin(angle + math.pi / 6),
    );
    path.close();

    canvas.drawPath(path, Paint()..color = paint.color..style = PaintingStyle.fill);
  }
}
