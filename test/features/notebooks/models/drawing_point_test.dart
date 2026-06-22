import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:caderno_digital_app/features/notebooks/models/drawing_point_model.dart';

void main() {
  test('DrawingPoint Model Serialization Tests | Deve converter corretamente o Objeto Stroke para o formato JSON do Servidor', () {
    // 1. Prepara
    final stroke = Stroke(
      id: 'bbbe634c-a8cc-4aee-8dec-63834b730e96', // Fixamos um ID para o teste não falhar com a aleatoriedade
      color: '#FF0000',
      thickness: 4.5,
      points: [const Offset(10.5, 20.1)],
    );

    // 2. Executa
    final result = stroke.toMap();

    // 3. Valida (Agora à procura de 'dx' e 'dy')
    expect(result['id'], 'bbbe634c-a8cc-4aee-8dec-63834b730e96');
    expect(result['color'], '#FF0000');
    expect(result['thickness'], 4.5);
    expect(result['points'], [{'dx': 10.5, 'dy': 20.1}]);
  });

  test('DrawingPoint Model Serialization Tests | Deve construir corretamente o Objeto Stroke a partir do JSON do Servidor', () {
    // 1. Prepara o JSON simulado do SQLite (agora com dx e dy corretos)
    final mockJson = {
      'id': '123e4567-e89b-12d3-a456-426614174000',
      'color': '#00FF00',
      'thickness': 2.5,
      'points': [{'dx': 15.0, 'dy': 30.5}]
    };

    // 2. Executa
    final stroke = Stroke.fromMap(mockJson);

    // 3. Valida
    expect(stroke.id, '123e4567-e89b-12d3-a456-426614174000');
    expect(stroke.color, '#00FF00');
    expect(stroke.thickness, 2.5);
    expect(stroke.points.first, const Offset(15.0, 30.5));
  });
}