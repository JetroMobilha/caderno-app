import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';

void main() {
  group('Subject Model Unit Tests |', () {
    final mockSubject = Subject(
      id: 1,
      userId: 1,
      serverId: 1,
      name: 'Matemática',
      color: '#FF0000',
      icon: 'book', syncedWithCloud: 0,
    );

    test('fromJson deve construir o objeto com as propriedades corretas', () {
      final json = {
        'id': 1,
        'user_id': 1,
        'name': 'Matemática',
        'color': '#FF0000',
        'icon': 'book',
      };

      final result = Subject.fromJson(json);

      expect(result.serverId, mockSubject.serverId);
      expect(result.userId, mockSubject.userId);
      expect(result.name, mockSubject.name);
      expect(result.color, mockSubject.color);
      expect(result.icon, mockSubject.icon);
    });

    test('copyWith deve gerar um novo objeto alterado', () {
      final result = mockSubject.copyWith(name: 'História');
      expect(result.name, 'História');
      expect(result.id, mockSubject.id);
    });
  });
}