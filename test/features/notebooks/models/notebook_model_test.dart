import 'package:flutter_test/flutter_test.dart';
// Nota: O import abaixo vai falhar de propósito (Red) porque o modelo ainda não existe!
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';

void main() {
  group('NotebookModel Tests |', () {
    final mockMap = {
      'id': 1,
      'server_id': 501,
      'subject_id': 10,
      'title': 'Álgebra Linear',
      'cover_type': 'leather',
      'color': '#2C3E50',
      'cover_image': null,
      'line_type': 'ruled',
      'synced_with_cloud': 0,
    };

    test('Deve converter corretamente um Map do SQLite para Objeto Notebook (fromMap)', () {
      final notebook = Notebook.fromMap(mockMap);

      expect(notebook.id, 1);
      expect(notebook.serverId, 501);
      expect(notebook.subject_id, 10);
      expect(notebook.title, 'Álgebra Linear');
      expect(notebook.coverType, 'leather');
      expect(notebook.color, '#2C3E50');
      expect(notebook.coverImage, isNull);
      expect(notebook.lineType, 'ruled');
      expect(notebook.syncedWithCloud, 0);
    });

    test('Deve converter corretamente um Objeto Notebook para Map (toMap)', () {
      final notebook = Notebook(
        id: 2,
        serverId: null,
        subject_id: 10,
        title: 'Geometria Analítica',
        coverType: 'classic',
        color: null,
        coverImage: 'assets/covers/geo.png',
        lineType: 'grid',
        syncedWithCloud: 1,
      );

      final map = notebook.toMap();

      expect(map['id'], 2);
      expect(map['server_id'], isNull);
      expect(map['subject_id'], 10);
      expect(map['title'], 'Geometria Analítica');
      expect(map['cover_type'], 'classic');
      expect(map['color'], isNull);
      expect(map['cover_image'], 'assets/covers/geo.png');
      expect(map['line_type'], 'grid');
      expect(map['synced_with_cloud'], 1);
    });
  });
}