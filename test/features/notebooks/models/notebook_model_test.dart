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

    test('Deve converter corretamente um Map do SQLite para Objeto Notebook (fromMap)', () {
      final notebook = Notebook.fromMap(mockMap);

      expect(notebook.id, 1);
      expect(notebook.subject_id, 10);
      expect(notebook.title, 'Álgebra Linear');
      expect(notebook.cover_type, 'leather');
      expect(notebook.color, '#2C3E50');
      expect(notebook.cover_image, isNull);
      expect(notebook.line_type, 'ruled');
    });

    test('Deve converter corretamente um Objeto Notebook para Map (toMap)', () {
      final notebook = Notebook(
        id: 2,
        subject_id: 10,
        title: 'Geometria Analítica',
        cover_type: 'classic',
        color: null,
        cover_image: 'assets/covers/geo.png',
        line_type: 'grid',
      );

      final map = notebook.toMap();

      expect(map['id'], 2);
      expect(map['subject_id'], 10);
      expect(map['title'], 'Geometria Analítica');
      expect(map['cover_type'], 'classic');
      expect(map['color'], isNull);
      expect(map['cover_image'], 'assets/covers/geo.png');
      expect(map['line_type'], 'grid');
    });
  });
}