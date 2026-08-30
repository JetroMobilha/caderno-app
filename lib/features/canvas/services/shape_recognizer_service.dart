import 'dart:math';
import 'package:flutter/material.dart';

enum RecognizedShapeType { none, line, circle, rectangle, triangle }

class RecognizedShape {
  final RecognizedShapeType type;
  final List<Offset> points;

  RecognizedShape(this.type, this.points);
}

class ShapeRecognizerService {
  static RecognizedShape recognize(List<Offset> points) {
    if (points.length < 10) return RecognizedShape(RecognizedShapeType.none, points);

    // 1. Verificar se é uma Linha (Regressão simples / Distância ponta a ponta)
    final double distStartEnd = (points.first - points.last).distance;
    double totalPathLength = 0;
    for (int i = 0; i < points.length - 1; i++) {
      totalPathLength += (points[i] - points[i + 1]).distance;
    }

    if (distStartEnd / totalPathLength > 0.92) {
      return RecognizedShape(RecognizedShapeType.line, [points.first, points.last]);
    }

    // 2. Verificar se é Círculo (Variação de raio em relação ao centroide)
    final Offset center = _calculateCentroid(points);
    final List<double> radii = points.map((p) => (p - center).distance).toList();
    final double avgRadius = radii.reduce((a, b) => a + b) / radii.length;
    double variance = 0;
    for (var r in radii) variance += pow(r - avgRadius, 2);
    variance /= radii.length;
    final double stdDev = sqrt(variance);

    if (stdDev / avgRadius < 0.15) {
      // É um círculo - gerar 40 pontos para suavidade
      final List<Offset> circlePoints = [];
      for (double i = 0; i < 2 * pi; i += 0.15) {
        circlePoints.add(Offset(center.dx + avgRadius * cos(i), center.dy + avgRadius * sin(i)));
      }
      circlePoints.add(circlePoints.first); // fechar
      return RecognizedShape(RecognizedShapeType.circle, circlePoints);
    }

    // 3. Verificar Retângulo (Bounding Box vs Área do traço)
    final Rect bounds = _calculateBounds(points);
    final double boundsArea = bounds.width * bounds.height;
    // Heurística simplificada: se as pontas estão perto e a variação angular é baixa em 4 picos
    if (distStartEnd < 50 && (totalPathLength / (2 * (bounds.width + bounds.height))) > 0.8) {
       return RecognizedShape(RecognizedShapeType.rectangle, [
         bounds.topLeft, bounds.topRight, bounds.bottomRight, bounds.bottomLeft, bounds.topLeft
       ]);
    }

    return RecognizedShape(RecognizedShapeType.none, points);
  }

  static Offset _calculateCentroid(List<Offset> points) {
    double x = 0, y = 0;
    for (var p in points) { x += p.dx; y += p.dy; }
    return Offset(x / points.length, y / points.length);
  }

  static Rect _calculateBounds(List<Offset> points) {
    double minX = points[0].dx, maxX = points[0].dx, minY = points[0].dy, maxY = points[0].dy;
    for (var p in points) {
      if (p.dx < minX) minX = p.dx; if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy; if (p.dy > maxY) maxY = p.dy;
    }
    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }
}
