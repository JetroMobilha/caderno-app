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
      icon: 'book',
    );

    test('fromMap deve construir o objeto com as propriedades corretas', () {
      final map = {
        'id': 1,
        'user_id': 1,
        'name': 'Matemática',
        'color': '#FF0000',
        'icon': 'book',
      };

      final result = Subject.fromMap(map);

      expect(result.id, mockSubject.id);
      expect(result.userId, mockSubject.userId);
      expect(result.name, mockSubject.name);
      expect(result.color, mockSubject.color);
      expect(result.icon, mockSubject.icon);
    });

    test('toMap deve gerar o mapa com a estrutura correta', () {
      final result = mockSubject.toMap();

      expect(result['id'], mockSubject.id);
      expect(result['user_id'], mockSubject.userId);
      expect(result['name'], mockSubject.name);
      expect(result['color'], mockSubject.color);
      expect(result['icon'], mockSubject.icon);
    });
  });
}