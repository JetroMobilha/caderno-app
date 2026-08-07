import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';

void main() {
  group('Notebook Model Tests', () {
    test('should convert from JSON correctly (snake_case)', () {
      final json = {
        'id': 101,
        'client_id': 'uuid-123',
        'subject_id': 50,
        'title': 'Test Notebook',
        'cover_type': 'color',
        'color': '#FF0000',
        'line_type': 'ruled',
        'paper_size': 'A4',
        'price': '1500.00',
        'is_published': 1,
        'version': 5,
      };

      final notebook = Notebook.fromJson(json);

      expect(notebook.serverId, 101);
      expect(notebook.clientId, 'uuid-123');
      expect(notebook.subjectId, 50);
      expect(notebook.title, 'Test Notebook');
      expect(notebook.color, '#FF0000');
      expect(notebook.price, 1500.0);
      expect(notebook.isPublished, 1);
      expect(notebook.version, 5);
    });

    test('toJson should output snake_case fields for Laravel', () {
      final notebook = Notebook(
        serverId: 202,
        title: 'Draft',
        coverType: 'basic',
        color: '#00FF00',
        lineType: 'grid',
        paperSize: 'A5',
        isPublished: 0,
        version: 2,
      );

      final json = notebook.toJson();

      expect(json['server_id'], 202);
      expect(json['title'], 'Draft');
      expect(json['color'], '#00FF00');
      expect(json['line_type'], 'grid');
      expect(json['paper_size'], 'A5');
      expect(json['is_published'], 0);
      expect(json['version'], 2);
    });

    test('copyWith should preserve all values', () {
      final original = Notebook(
        title: 'Original',
        coverType: 'color',
        color: '#111111',
        lineType: 'ruled',
        paperSize: 'A4',
        version: 1,
      );

      final updated = original.copyWith(title: 'Updated', version: 2);

      expect(updated.title, 'Updated');
      expect(updated.color, '#111111');
      expect(updated.version, 2);
      expect(updated.clientId, original.clientId);
    });
  });
}
