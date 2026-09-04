import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/models/stroke_model.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_configuration.dart';
import 'package:flutter/material.dart';

void main() {
  group('LocalPage Model Tests', () {
    test('JSON serialization should preserve unified objects list', () {
      final stroke = Stroke(
        id: 's1',
        color: '#FF0000',
        thickness: 2.0,
        points: [const Offset(0, 0), const Offset(10, 10)],
      );

      final page = LocalPage(
        notebookId: 1,
        pageNumber: 1,
        isLandscape: false,
        paperSize: 'A4',
        objects: [stroke],
        backgroundConfig: BackgroundConfig(type: 'grid', spacing: 10.0),
      );

      final json = page.toJson();
      expect(json['objects_data'], isNotNull);
      expect((json['objects_data'] as List).length, 1);
      expect(json['objects_data'][0]['type'], 'stroke');
      expect(json['background_config']['type'], 'grid');

      final fromJson = LocalPage.fromJson(json);
      expect(fromJson.objects.length, 1);
      expect(fromJson.objects.first, isA<Stroke>());
      expect(fromJson.backgroundConfig?.type, 'grid');
    });

    test('Dimension getters (pageWidthPx/HeightPx) should respect orientation', () {
      // A4 is 210 x 297 mm
      // In Pixels (x 3.78): ~793.8 x ~1122.66
      
      final portraitPage = LocalPage(
        notebookId: 1,
        pageNumber: 1,
        isLandscape: false,
        paperSize: 'A4',
      );

      expect(portraitPage.pageWidthPx, closeTo(210 * 3.78, 0.1));
      expect(portraitPage.pageHeightPx, closeTo(297 * 3.78, 0.1));

      final landscapePage = LocalPage(
        notebookId: 1,
        pageNumber: 1,
        isLandscape: true,
        paperSize: 'A4',
      );

      expect(landscapePage.pageWidthPx, closeTo(297 * 3.78, 0.1));
      expect(landscapePage.pageHeightPx, closeTo(210 * 3.78, 0.1));
    });

    test('toConfig should Specifiy orientation and infinite mode correctly', () {
      final page = LocalPage(
        notebookId: 1,
        pageNumber: 1,
        isLandscape: true,
        isInfinite: true,
        paperSize: 'A4',
      );

      final config = page.toConfig;
      expect(config.page.orientation, 'landscape');
      expect(config.page.isInfinite, true);
      // For infinite, we currently set width/height to 1000 in toConfig
      expect(config.page.width, 1000);
    });

    test('copyWith should update fields correctly', () {
      final page = LocalPage(notebookId: 1, pageNumber: 1, isLandscape: false);
      final updated = page.copyWith(isLandscape: true, isInfinite: true);
      
      expect(updated.isLandscape, true);
      expect(updated.isInfinite, true);
    });
  });
}
