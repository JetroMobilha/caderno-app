import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/explanation_model.dart';
import 'base_animator.dart';

class PhysicsAnimator implements BaseAnimator {
  @override
  void paint(Canvas canvas, Size size, ExplanationModel model, double time) {
    if (model is! PhysicsExplanation) return;

    switch (model.kind) {
      case PhysicsKind.inclinedPlane:
        _paintInclinedPlane(canvas, model, time);
        break;
      case PhysicsKind.simplePendulum:
        _paintSimplePendulum(canvas, model, time);
        break;
      case PhysicsKind.massSpring:
        _paintMassSpring(canvas, model, time);
        break;
    }
  }

  void _paintInclinedPlane(Canvas canvas, PhysicsExplanation model, double time) {
    final double angleRad = model.angleDegrees * math.pi / 180.0;
    const double rampWidth = 200.0;
    final double rampHeight = rampWidth * math.tan(angleRad);

    // 1. Rampa (Triângulo)
    final rampPath = Path()
      ..moveTo(-rampWidth / 2, rampHeight / 2)
      ..lineTo(rampWidth / 2, rampHeight / 2)
      ..lineTo(rampWidth / 2, -rampHeight / 2)
      ..close();

    canvas.drawPath(rampPath, Paint()..color = Colors.grey.shade300..style = PaintingStyle.fill);
    canvas.drawPath(rampPath, Paint()..color = Colors.grey.shade700..strokeWidth = 2.0..style = PaintingStyle.stroke);

    // 2. Bloco sobre a rampa
    canvas.save();
    // Posicionar no meio da rampa e rodar pelo ângulo
    canvas.translate(0, 0);
    canvas.rotate(-angleRad);

    const double blockW = 40.0;
    const double blockH = 25.0;

    // Deslocamento de deslizamento animado ao longo do plano
    double slideOffset = 0.0;
    if (model.isPlaying) {
      slideOffset = math.sin(time * 2 * math.pi) * 30.0;
    }

    final blockRect = Rect.fromLTWH(-blockW / 2 + slideOffset, -blockH, blockW, blockH);
    canvas.drawRect(blockRect, Paint()..color = Colors.orangeAccent..style = PaintingStyle.fill);
    canvas.drawRect(blockRect, Paint()..color = Colors.orange.shade900..strokeWidth = 2.0..style = PaintingStyle.stroke);

    // 3. Vetores de Força no Bloco
    final Offset blockCenter = Offset(slideOffset, -blockH / 2);

    // Vetor Normal (Perpendicular à superfície - para cima)
    _drawArrow(canvas, blockCenter, const Offset(0, -45), Paint()..color = Colors.blue..strokeWidth = 2.5);

    // Vetor Peso (Vertical para baixo no referencial global - rotacionado de volta)
    final Offset gravityInRotated = Offset(45 * math.sin(angleRad), 45 * math.cos(angleRad));
    _drawArrow(canvas, blockCenter, gravityInRotated, Paint()..color = Colors.redAccent..strokeWidth = 2.5);

    // Vetor Atrito / Paralelo
    _drawArrow(canvas, blockCenter, const Offset(-30, 0), Paint()..color = Colors.green..strokeWidth = 2.0);

    canvas.restore();
  }

  void _paintSimplePendulum(Canvas canvas, PhysicsExplanation model, double time) {
    const Offset pivot = Offset(0, -80);
    final double maxAngleRad = 30.0 * math.pi / 180.0;

    // Ângulo oscilante MHS: theta = theta_max * cos(w * t)
    final double theta = model.isPlaying 
        ? maxAngleRad * math.cos(time * 2 * math.pi)
        : maxAngleRad;

    final double length = model.length;
    final Offset bobPos = pivot + Offset(length * math.sin(theta), length * math.cos(theta));

    // Support Suporte do topo
    canvas.drawLine(pivot + const Offset(-30, 0), pivot + const Offset(30, 0), Paint()..color = Colors.black87..strokeWidth = 4.0);

    // Trajetória pontilhada do arco
    final arcPath = Path();
    arcPath.addArc(Rect.fromCircle(center: pivot, radius: length), (math.pi / 2) - maxAngleRad, maxAngleRad * 2);
    canvas.drawPath(arcPath, Paint()..color = Colors.black26..strokeWidth = 1.0..style = PaintingStyle.stroke);

    // Haste / Corda do Pêndulo
    canvas.drawLine(pivot, bobPos, Paint()..color = Colors.black87..strokeWidth = 2.0);

    // Esfera (Bob)
    const double bobRadius = 18.0;
    canvas.drawCircle(bobPos, bobRadius, Paint()..color = Colors.amber.shade700..style = PaintingStyle.fill);
    canvas.drawCircle(bobPos, bobRadius, Paint()..color = Colors.brown..strokeWidth = 2.0..style = PaintingStyle.stroke);

    // Vetor Peso no Pêndulo
    _drawArrow(canvas, bobPos, const Offset(0, 35), Paint()..color = Colors.redAccent..strokeWidth = 2.0);
  }

  void _paintMassSpring(Canvas canvas, PhysicsExplanation model, double time) {
    const double wallX = -120.0;
    final double displacement = model.isPlaying ? math.sin(time * 2 * math.pi) * 35.0 : 0.0;
    final double blockX = displacement + 20.0;

    // Parede
    canvas.drawLine(const Offset(wallX, -40), const Offset(wallX, 40), Paint()..color = Colors.black87..strokeWidth = 4.0);
    // Solo
    canvas.drawLine(const Offset(wallX, 20), const Offset(120, 20), Paint()..color = Colors.black45..strokeWidth = 2.0);

    // Mola Helicoidal (Zigzag)
    final springPath = Path();
    springPath.moveTo(wallX, 0);

    const int turns = 10;
    final double springLength = (blockX - 20.0) - wallX;
    final double stepX = springLength / turns;

    for (int i = 0; i < turns; i++) {
      final double x1 = wallX + (i * stepX) + (stepX / 4);
      final double y1 = (i % 2 == 0) ? -12.0 : 12.0;
      final double x2 = wallX + (i * stepX) + (3 * stepX / 4);
      final double y2 = (i % 2 == 0) ? 12.0 : -12.0;

      springPath.lineTo(x1, y1);
      springPath.lineTo(x2, y2);
    }
    springPath.lineTo(blockX - 20.0, 0);

    canvas.drawPath(springPath, Paint()..color = Colors.grey.shade800..strokeWidth = 2.0..style = PaintingStyle.stroke);

    // Bloco
    const double blockW = 40.0;
    const double blockH = 40.0;
    final blockRect = Rect.fromLTWH(blockX - blockW / 2, -blockH / 2, blockW, blockH);

    canvas.drawRect(blockRect, Paint()..color = Colors.tealAccent.shade400..style = PaintingStyle.fill);
    canvas.drawRect(blockRect, Paint()..color = Colors.teal.shade900..strokeWidth = 2.0..style = PaintingStyle.stroke);

    // Vetor Força Restauradora (F = -kx)
    final Offset forceVec = Offset(-displacement * 0.8, 0);
    if (forceVec.distance > 2.0) {
      _drawArrow(canvas, Offset(blockX, 0), forceVec, Paint()..color = Colors.redAccent..strokeWidth = 2.5);
    }
  }

  void _drawArrow(Canvas canvas, Offset start, Offset vector, Paint paint) {
    if (vector.distance < 1.0) return;

    const double headSize = 8.0;
    final Offset end = start + vector;
    
    canvas.drawLine(start, end, paint);

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
