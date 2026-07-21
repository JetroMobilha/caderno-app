import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';

void main() {
  group('NotebookModel Tests |', () {
    final mockMap = {
      'id': 1,
      'subject_id': 10,
      'title': 'Álgebra Linear',
      'cover_type': 'leather',
      'color': '#2C3E50',
      'cover_image': null,
      'line_type': 'ruled',
    };

    test('Deve converter corretamente um JSON do Laravel para Objeto Notebook (fromJson)', () {
      final notebook = Notebook.fromJson(mockMap);

      expect(notebook.serverId, 1);
      expect(notebook.subjectId, 10);
      expect(notebook.title, 'Álgebra Linear');
      expect(notebook.coverType, 'leather');
      expect(notebook.color, '#2C3E50');
      expect(notebook.coverImage, isNull);
      expect(notebook.lineType, 'ruled');
    });

    test('Deve converter corretamente um Objeto Notebook para JSON (toJson)', () {
      final notebook = Notebook(
        id: 2,
        subjectId: 10,
        title: 'Geometria Analítica',
        coverType: 'classic',
        color: null,
        coverImage: 'assets/covers/geo.png',
        lineType: 'grid', paperSize: 'A4',
      );

      final json = notebook.toJson();

      expect(json['id'], 2);
      expect(json['subject_id'], 10);
      expect(json['title'], 'Geometria Analítica');
      expect(json['cover_type'], 'classic');
      expect(json['color'], isNull);
      expect(json['cover_image'], 'assets/covers/geo.png');
      expect(json['line_type'], 'grid');
    });
  });
}