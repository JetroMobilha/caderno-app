import 'dart:math';
import 'package:flutter/material.dart';

class RdpSimplifier {
  /// Ramer-Douglas-Peucker algorithm to simplify a path of points.
  static List<Offset> simplify(List<Offset> points, double epsilon) {
    if (points.length < 3) return points;

    int index = -1;
    double maxDist = 0;

    for (int i = 1; i < points.length - 1; i++) {
      double dist = _perpendicularDistance(points[i], points.first, points.last);
      if (dist > maxDist) {
        index = i;
        maxDist = dist;
      }
    }

    if (maxDist > epsilon) {
      List<Offset> res1 = simplify(points.sublist(0, index + 1), epsilon);
      List<Offset> res2 = simplify(points.sublist(index, points.length), epsilon);

      return [...res1.sublist(0, res1.length - 1), ...res2];
    } else {
      return [points.first, points.last];
    }
  }

  static double _perpendicularDistance(Offset p, Offset p1, Offset p2) {
    double x = p.dx;
    double y = p.dy;
    double x1 = p1.dx;
    double y1 = p1.dy;
    double x2 = p2.dx;
    double y2 = p2.dy;

    double num = ((y2 - y1) * x - (x2 - x1) * y + x2 * y1 - y2 * x1).abs();
    double den = sqrt(pow(y2 - y1, 2) + pow(x2 - x1, 2));

    return den == 0 ? (p - p1).distance : num / den;
  }
}
