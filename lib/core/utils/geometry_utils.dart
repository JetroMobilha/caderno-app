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
}
