import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/features/canvas/models/stroke_model.dart';
import 'package:caderno_digital_app/features/canvas/models/text_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/image_block_model.dart';
import 'package:flutter/material.dart';

void main() {
  group('Canvas Models Unit Tests', () {
    test('Stroke - Serialization/Deserialization', () {
      final stroke = Stroke(
        id: 's1',
        color: '#FF0000',
        thickness: 2.0,
        points: [const Offset(0, 0), const Offset(10, 10)],
      );

      final json = stroke.toJson();
      final fromJson = Stroke.fromJson(json);

      expect(fromJson.id, stroke.id);
      expect(fromJson.color, stroke.color);
      expect(fromJson.thickness, stroke.thickness);
      expect(fromJson.points.length, 2);
    });

    test('TextBlock - Serialization/Deserialization', () {
      final block = TextBlock(
        id: 't1',
        text: 'Hello Test',
        position: const Offset(50, 50),
        textColorHex: '#0000FF',
        fontSize: 18.0,
      );

      final json = block.toJson();
      final fromJson = TextBlock.fromJson(json);

      expect(fromJson.id, block.id);
      expect(fromJson.text, block.text);
      expect(fromJson.position, block.position);
      expect(fromJson.fontSize, block.fontSize);
    });

    test('ImageBlock - Serialization/Deserialization', () {
      final img = ImageBlock(
        id: 'i1',
        imagePath: 'path/to/img.png',
        position: const Offset(100, 100),
        width: 200,
        height: 150,
      );

      final json = img.toJson();
      final fromJson = ImageBlock.fromJson(json);

      expect(fromJson.id, img.id);
      expect(fromJson.imagePath, img.imagePath);
      expect(fromJson.position, img.position);
      expect(fromJson.width, img.width);
    });
  });
}
