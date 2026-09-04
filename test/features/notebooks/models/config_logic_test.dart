import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_configuration.dart';

void main() {
  group('NotebookConfiguration Logic Tests', () {
    test('PageConfig should infer paperSize correctly if not provided', () {
      final config = PageConfig(width: 210, height: 297); // A4 Portrait
      expect(config.paperSize, 'A4');

      final configA3 = PageConfig(width: 420, height: 297); // A3 Landscape
      expect(configA3.paperSize, 'A3');
    });

    test('PageConfig JSON mapping should preserve isInfinite', () {
      final config = PageConfig(width: 1000, height: 1000, isInfinite: true);
      final json = config.toJson();
      expect(json['is_infinite'], 1);

      final fromJson = PageConfig.fromJson(json);
      expect(fromJson.isInfinite, true);
    });

    test('BackgroundConfig should preserve lineWidth and opacity', () {
      final bg = BackgroundConfig(
        type: 'grid', 
        lineWidth: 0.5, 
        opacity: 0.8,
        lineColor: '#FF0000',
      );
      
      final json = bg.toJson();
      expect(json['line_width'], 0.5);
      expect(json['opacity'], 0.8);
      expect(json['line_color'], '#FF0000');

      final fromJson = BackgroundConfig.fromJson(json);
      expect(fromJson.lineWidth, 0.5);
      expect(fromJson.opacity, 0.8);
    });
  });
}
