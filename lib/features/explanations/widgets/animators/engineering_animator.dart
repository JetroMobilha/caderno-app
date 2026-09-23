import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../models/explanation_model.dart';
import 'base_animator.dart';

class EngineeringAnimator implements BaseAnimator {
  @override
  void paint(Canvas canvas, Size size, ExplanationModel model, double time) {
    if (model is! EngineeringExplanation) return;

    switch (model.kind) {
      case EngineeringKind.gears:
        _paintGears(canvas, model, time);
        break;
      case EngineeringKind.dcCircuit:
        _paintDcCircuit(canvas, model, time);
        break;
      case EngineeringKind.trussBeam:
        _paintTrussBeam(canvas, model, time);
        break;
    }
  }

  void _paintGears(Canvas canvas, EngineeringExplanation model, double time) {
    final double r1 = model.radius;
    final double r2 = model.radius * model.gearRatio;
    final int teeth1 = model.toothCount;
    final int teeth2 = (model.toothCount * model.gearRatio).round();

    final double rotation1 = model.isPlaying ? (time * 2 * math.pi * model.angularVelocity) : 0.0;
    // Segunda engrenagem roda na direção oposta com velocidade angular inversamente proporcional ao raio
    final double rotation2 = -rotation1 / model.gearRatio;

    final fillPaint = Paint()..color = Colors.blueGrey.shade400..style = PaintingStyle.fill;
    final strokePaint = Paint()..color = Colors.black87..strokeWidth = 2.0..style = PaintingStyle.stroke;

    // Engrenagem 1 (Esquerda)
    canvas.save();
    canvas.translate(-r1, 0);
    canvas.rotate(rotation1);
    _drawSingleGear(canvas, r1, teeth1, fillPaint, strokePaint);
    canvas.restore();

    // Engrenagem 2 (Direita, tocando no ponto de contato)
    canvas.save();
    canvas.translate(r2, 0);
    canvas.rotate(rotation2);
    _drawSingleGear(canvas, r2, teeth2, Paint()..color = Colors.blueGrey.shade600..style = PaintingStyle.fill, strokePaint);
    canvas.restore();
  }

  void _drawSingleGear(Canvas canvas, double radius, int teeth, Paint fill, Paint stroke) {
    final Path path = Path();
    final double angleStep = (2 * math.pi) / teeth;
    final double toothHeight = radius * 0.18;

    for (int i = 0; i < teeth; i++) {
      final double angle = i * angleStep;
      
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
    
    // Círculo interno para centro da engrenagem
    canvas.drawCircle(Offset.zero, radius * 0.6, Paint()..color = Colors.white..style = PaintingStyle.fill);
    canvas.drawCircle(Offset.zero, radius * 0.6, stroke);
    canvas.drawCircle(Offset.zero, 6.0, Paint()..color = Colors.black87);
  }

  void _paintDcCircuit(Canvas canvas, EngineeringExplanation model, double time) {
    const double width = 180.0;
    const double height = 110.0;
    final rect = Rect.fromCenter(center: Offset.zero, width: width, height: height);

    final wirePaint = Paint()
      ..color = Colors.indigo.shade800
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    // 1. Fios Retangulares do Circuito
    canvas.drawRect(rect, wirePaint);

    // 2. Fonte de Tensão DC (Bateria no lado esquerdo)
    final double batteryX = rect.left;
    const double batteryH = 30.0;
    
    // Apagar trecho do fio na bateria
    canvas.drawRect(Rect.fromCenter(center: Offset(batteryX, 0), width: 10, height: batteryH), Paint()..color = Colors.white);
    
    // Placa Positiva (+) maior e Placa Negativa (-) menor
    canvas.drawLine(Offset(batteryX - 12, -batteryH / 2), Offset(batteryX + 12, -batteryH / 2), wirePaint);
    canvas.drawLine(Offset(batteryX - 6, batteryH / 2), Offset(batteryX + 6, batteryH / 2), wirePaint..strokeWidth = 5.0);

    // 3. Resistor (Lado Superior)
    const double resW = 40.0;
    final double resY = rect.top;
    canvas.drawRect(Rect.fromCenter(center: Offset(0, resY), width: resW + 4, height: 16), Paint()..color = Colors.white);
    
    // Zigzag do Resistor
    final resPath = Path()..moveTo(-resW / 2, resY);
    for (int i = -3; i <= 3; i++) {
      final double x = (i * resW / 6);
      final double y = resY + ((i % 2 == 0) ? -6 : 6);
      resPath.lineTo(x, y);
    }
    resPath.lineTo(resW / 2, resY);
    canvas.drawPath(resPath, Paint()..color = Colors.brown..strokeWidth = 2.0..style = PaintingStyle.stroke);

    // 4. Lâmpada/LED (Lado Direito)
    final double bulbX = rect.right;
    canvas.drawCircle(Offset(bulbX, 0), 16.0, Paint()..color = Colors.white..style = PaintingStyle.fill);
    
    // Brilho da Lâmpada proporcional à corrente I = V / R
    final double current = model.resistance > 0 ? (model.voltage / model.resistance) : 0.0;
    final double glowAlpha = (current * 0.4).clamp(0.0, 0.9);

    canvas.drawCircle(Offset(bulbX, 0), 20.0, Paint()..color = Colors.amber.withValues(alpha: glowAlpha));
    canvas.drawCircle(Offset(bulbX, 0), 16.0, Paint()..color = Colors.amber.shade200..style = PaintingStyle.stroke..strokeWidth = 2.0);
    
    // Filamento X
    canvas.drawLine(Offset(bulbX - 6, -6), Offset(bulbX + 6, 6), Paint()..color = Colors.orange.shade800..strokeWidth = 2.0);
    canvas.drawLine(Offset(bulbX - 6, 6), Offset(bulbX + 6, -6), Paint()..color = Colors.orange.shade800..strokeWidth = 2.0);

    // 5. Elétrons Animados Fluindo pelo Circuito (Pontos Azuis em movimento)
    if (model.isPlaying && current > 0) {
      final double perimeter = (width + height) * 2;
      const int electronCount = 12;
      
      final electronPaint = Paint()..color = Colors.cyan.shade600;

      for (int i = 0; i < electronCount; i++) {
        final double progress = ((time * (current * 0.5)) + (i / electronCount)) % 1.0;
        final double dist = progress * perimeter;

        Offset pos;
        if (dist < width) {
          // Topo (esquerda para direita)
          pos = Offset(rect.left + dist, rect.top);
        } else if (dist < width + height) {
          // Direita (topo para baixo)
          pos = Offset(rect.right, rect.top + (dist - width));
        } else if (dist < (2 * width) + height) {
          // Base (direita para esquerda)
          pos = Offset(rect.right - (dist - width - height), rect.bottom);
        } else {
          // Esquerda (baixo para topo)
          pos = Offset(rect.left, rect.bottom - (dist - (2 * width) - height));
        }

        canvas.drawCircle(pos, 3.5, electronPaint);
      }
    }
  }

  void _paintTrussBeam(Canvas canvas, EngineeringExplanation model, double time) {
    final double length = model.beamLength;
    const double height = 30.0;

    // 1. Estrutura em Viga / Treliça
    final beamRect = Rect.fromCenter(center: Offset.zero, width: length, height: height);
    
    final beamPaint = Paint()
      ..color = Colors.blueGrey.shade100
      ..style = PaintingStyle.fill;
    
    final borderPaint = Paint()
      ..color = Colors.blueGrey.shade900
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    canvas.drawRect(beamRect, beamPaint);
    canvas.drawRect(beamRect, borderPaint);

    // Triângulos Internos de Treliça
    final int sections = 6;
    final double sectionW = length / sections;
    
    for (int i = 0; i < sections; i++) {
      final double leftX = -length / 2 + (i * sectionW);
      final double rightX = leftX + sectionW;
      
      canvas.drawLine(Offset(leftX, -height / 2), Offset(rightX, height / 2), borderPaint..strokeWidth = 1.0);
      canvas.drawLine(Offset(leftX, height / 2), Offset(rightX, -height / 2), borderPaint..strokeWidth = 1.0);
    }

    // 2. Apoios (Apoio Fixo à Esquerda, Apoio Móvel à Direita)
    final double leftX = -length / 2;
    final double rightX = length / 2;
    final double supportY = height / 2;

    // Apoio Fixo (Triângulo)
    final fixedSupport = Path()
      ..moveTo(leftX, supportY)
      ..lineTo(leftX - 12, supportY + 20)
      ..lineTo(leftX + 12, supportY + 20)
      ..close();
    canvas.drawPath(fixedSupport, Paint()..color = Colors.grey.shade600..style = PaintingStyle.fill);

    // Apoio Móvel (Triângulo com Roletes)
    final rollerSupport = Path()
      ..moveTo(rightX, supportY)
      ..lineTo(rightX - 12, supportY + 14)
      ..lineTo(rightX + 12, supportY + 14)
      ..close();
    canvas.drawPath(rollerSupport, Paint()..color = Colors.grey.shade600..style = PaintingStyle.fill);
    canvas.drawCircle(Offset(rightX - 6, supportY + 18), 3, Paint()..color = Colors.black);
    canvas.drawCircle(Offset(rightX + 6, supportY + 18), 3, Paint()..color = Colors.black);

    // 3. Força Aplicada (Carga Concentrada no Centro)
    final double forceY = -height / 2;
    _drawArrow(canvas, Offset(0, forceY - 45), Offset(0, 40), Paint()..color = Colors.redAccent..strokeWidth = 3.0);

    // 4. Reações nos Apoios (Vetores para cima)
    _drawArrow(canvas, Offset(leftX, supportY + 35), const Offset(0, -25), Paint()..color = Colors.green.shade700..strokeWidth = 2.0);
    _drawArrow(canvas, Offset(rightX, supportY + 35), const Offset(0, -25), Paint()..color = Colors.green.shade700..strokeWidth = 2.0);
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
