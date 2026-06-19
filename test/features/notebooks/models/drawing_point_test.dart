import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/features/notebooks/models/drawing_point_model.dart';

void main() {
  group('DrawingPoint Model Serialization Tests |', () {
    final mockJson = {
      'color': '#FF0000',
      'thickness': 4.5,
      'points': [
        {'x': 10.5, 'y': 20.1}
      ]
    };

    test('Deve converter corretamente o Objeto Stroke para o formato JSON do Servidor', () {
      final stroke = Stroke(
        color: '#FF0000',
        thickness: 4.5,
        points: [const Offset(10.5, 20.1)],
      );

      final result = stroke.toMap();

      expect(result, mockJson);
    });

    test('Deve construir corretamente o Objeto Stroke a partir do JSON do Servidor', () {
      final stroke = Stroke.fromMap(mockJson);

      expect(stroke.color, '#FF0000');
      expect(stroke.thickness, 4.5);
      expect(stroke.points.length, 1);
      expect(stroke.points.first.dx, 10.5); // Opa, isto vai falhar de propósito! Deve ser 10.5
    });
  });
}