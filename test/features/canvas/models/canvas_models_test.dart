import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/features/canvas/models/stroke_model.dart';
import 'package:caderno_digital_app/features/canvas/models/image_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/text_block_model.dart';

void main() {
  group('Canvas Models Data Integrity', () {
    test('Stroke JSON mapping should preserve isDeleted', () {
      final stroke = Stroke(
        color: '#FF00FF',
        thickness: 5.0,
        points: [const Offset(10, 10), const Offset(20, 20)],
        isDeleted: true,
        version: 10,
      );

      final json = stroke.toJson();
      expect(json['is_deleted'], true);
      expect(json['version'], 10);

      final fromJson = Stroke.fromJson(json);
      expect(fromJson.isDeleted, true);
      expect(fromJson.version, 10);
      expect(fromJson.points.length, 2);
    });

    test('ImageBlock JSON mapping should preserve isDeleted and dimensions', () {
      final img = ImageBlock(
        imagePath: 'path/to/img.png',
        position: const Offset(100, 100),
        width: 500,
        height: 400,
        isDeleted: true,
        version: 3,
      );

      final json = img.toJson();
      expect(json['is_deleted'], true);
      expect(json['width'], 500.0);
      expect(json['height'], 400.0);

      final fromJson = ImageBlock.fromJson(json);
      expect(fromJson.isDeleted, true);
      expect(fromJson.width, 500.0);
      expect(fromJson.height, 400.0);
      expect(fromJson.version, 3);
    });

    test('TextBlock JSON mapping should preserve checklist state', () {
      final text = TextBlock(
        text: 'Item 1\nItem 2',
        position: const Offset(50, 50),
        isChecklist: true,
      );
      text.checkedLineIndices.add(1);

      final json = text.toJson();
      expect(json['is_checklist'], true);
      expect(json['checked_line_indices'], [1]);

      final fromJson = TextBlock.fromJson(json);
      expect(fromJson.isChecklist, true);
      expect(fromJson.checkedLineIndices.contains(1), true);
    });
  });
}
