import 'dart:math';
import 'package:flutter/material.dart';

class GeometryUtils {
  static const Map<String, Size> paperSizes = {
    'A5': Size(420, 595), 'A4': Size(595, 842),
    'A3': Size(842, 1191), 'A2': Size(1191, 1684),
    'A1': Size(1684, 2384), 'A0': Size(2384, 3370),
  };

  static Size getPaperSize(String key) => paperSizes[key] ?? paperSizes['A4']!;

  /// Simplifica uma lista de pontos usando o algoritmo de Ramer-Douglas-Peucker.
  /// [epsilon] é a tolerância de distância. Valores maiores simplificam mais.
  static List<Offset> simplifyPoints(List<Offset> points, {double epsilon = 1.0}) {
    if (points.length < 3) return points;

    return _ramerDouglasPeucker(points, epsilon);
  }

  static List<Offset> _ramerDouglasPeucker(List<Offset> points, double epsilon) {
    double maxDistance = 0.0;
    int index = 0;

    for (int i = 1; i < points.length - 1; i++) {
      double distance = _perpendicularDistance(points[i], points.first, points.last);
      if (distance > maxDistance) {
        index = i;
        maxDistance = distance;
      }
    }

    if (maxDistance > epsilon) {
      List<Offset> left = _ramerDouglasPeucker(points.sublist(0, index + 1), epsilon);
      List<Offset> right = _ramerDouglasPeucker(points.sublist(index), epsilon);

      return [...left.sublist(0, left.length - 1), ...right];
    } else {
      return [points.first, points.last];
    }
  }

  static double _perpendicularDistance(Offset p, Offset start, Offset end) {
    double sx = end.dx - start.dx;
    double sy = end.dy - start.dy;

    if (sx == 0 && sy == 0) {
      return sqrt(pow(p.dx - start.dx, 2) + pow(p.dy - start.dy, 2));
    }

    double u = ((p.dx - start.dx) * sx + (p.dy - start.dy) * sy) / (sx * sx + sy * sy);
    Offset closestPoint;

    if (u < 0) {
      closestPoint = start;
    } else if (u > 1) {
      closestPoint = end;
    } else {
      closestPoint = Offset(start.dx + u * sx, start.dy + u * sy);
    }

    return sqrt(pow(p.dx - closestPoint.dx, 2) + pow(p.dy - closestPoint.dy, 2));
  }

  /// 🚀 Gera uma versão suavizada da lista de pontos usando o algoritmo de Chaikin.
  /// Dobra a densidade de pontos e arredonda as quinas.
  static List<Offset> generateSmoothPoints(List<Offset> points, {int iterations = 1}) {
    if (points.length < 3) return points;

    // 🛡️ PASSO 1: Simplificar antes de suavizar para remover ruído e redundância.
    // Isso torna a suavização muito mais elegante e evita explosão de pontos.
    List<Offset> result = simplifyPoints(points, epsilon: 0.2);

    for (int i = 0; i < iterations; i++) {
      List<Offset> next = [];
      
      // Chaikin's algorithm
      next.add(result.first);
      for (int j = 0; j < result.length - 1; j++) {
        final p0 = result[j];
        final p1 = result[j + 1];

        // Pontos de corte em 1/4 e 3/4 da linha (Corta as quinas)
        final q = Offset(p0.dx * 0.75 + p1.dx * 0.25, p0.dy * 0.75 + p1.dy * 0.25);
        final r = Offset(p0.dx * 0.25 + p1.dx * 0.75, p0.dy * 0.25 + p1.dy * 0.75);

        next.add(q);
        next.add(r);
      }
      next.add(result.last);
      result = next;
    }

    return result;
  }
}
