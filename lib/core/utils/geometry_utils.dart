import 'dart:math';
import 'package:flutter/material.dart';

class GeometryUtils {
  static const Map<String, Size> paperSizes = {
    'A5': Size(420, 595), 'A4': Size(595, 842),
    'A3': Size(842, 1191), 'A2': Size(1191, 1684),
    'A1': Size(1684, 2384), 'A0': Size(2384, 3370),
  };

  static Size getPaperSize(String key) => paperSizes[key] ?? paperSizes['A4']!;

  /// 🚀 Retorna o nível de hierarquia do papel (0 é superior/infinito, 6 é o menor)
  static int getPaperLevel(String size, {bool isInfinite = false}) {
    if (isInfinite) return 0;
    switch (size) {
      case 'A0': return 1;
      case 'A1': return 2;
      case 'A2': return 3;
      case 'A3': return 4;
      case 'A4': return 5;
      case 'A5': return 6;
      default: return 5; // A4 default
    }
  }
}
