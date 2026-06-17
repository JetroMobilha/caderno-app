import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart'; // Ajusta o nome do projeto se necessário

void main() {
  group('SubjectModel Tests |', () {
    // 1. Preparamos os nossos dados de teste (Mock Data)
    final mockSubject = Subject(
      id: 1,
      serverId: 105,
      userId: 2,
      name: 'Física Quântica',
      color: '#000000',
      icon: 'atom_icon',
      syncedWithCloud: 1,
    );

    final mockMap = {
      'id': 1,
      'server_id': 105,
      'user_id': 2,
      'name': 'Física Quântica',
      'color': '#000000',
      'icon': 'atom_icon',
      'synced_with_cloud': 1,
    };

    test('Deve converter corretamente um Objeto Subject para Map (toMap)', () {
      // Act: Executamos a função que queremos testar
      final result = mockSubject.toMap();

      // Assert: Verificamos se o resultado é exatamente o esperado
      expect(result, mockMap);
    });

    test('Deve converter corretamente um Map do SQLite para Objeto Subject (fromMap)', () {
      // Act
      final result = Subject.fromMap(mockMap);

      // Assert
      expect(result.id, mockSubject.id);
      expect(result.serverId, mockSubject.serverId);
      expect(result.userId, mockSubject.userId);
      expect(result.name, mockSubject.name);
      expect(result.color, mockSubject.color);
      expect(result.syncedWithCloud, mockSubject.syncedWithCloud);
    });
  });
}