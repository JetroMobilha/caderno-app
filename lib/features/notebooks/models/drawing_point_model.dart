import 'package:flutter/material.dart';

/// Representa um traço contínuo desenhado no Canvas, pronto para sincronização.
class Stroke {
  final String color;
  final double thickness;
  final List<Offset> points;

  Stroke({
    required this.color,
    required this.thickness,
    required this.points,
  });

  /// Converte o Traço num Map (JSON) compatível com a API Laravel.
  Map<String, dynamic> toMap() {
    return {
      'color': color,
      'thickness': thickness,
      'points': points.map((p) => {'x': p.dx, 'y': p.dy}).toList(),
    };
  }

  /// Cria um Traço a partir do formato JSON vindo do Servidor.
  factory Stroke.fromMap(Map<String, dynamic> map) {
    final List<dynamic> pointsList = map['points'] ?? [];
    return Stroke(
      color: map['color'] ?? '#000000',
      thickness: (map['thickness'] as num).toDouble(),
      points: pointsList.map((p) {
        return Offset(
          (p['x'] as num).toDouble(),
          (p['y'] as num).toDouble(),
        );
      }).toList(),
    );
  }
}