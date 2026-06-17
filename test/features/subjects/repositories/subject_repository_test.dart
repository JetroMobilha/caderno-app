import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';

// Uma simulação rápida do repositório Web em memória para o teste
class MockWebSubjectRepository {
  final List<Subject> _mockDb = [];

  Future<List<Subject>> fetchSubjects() async => _mockDb;

  Future<void> saveSubject(Subject subject) async {
    _mockDb.add(subject);
  }
}

void main() {
  test('Deve simular o comportamento de guardar dados na Web em memória', () async {
    final repository = MockWebSubjectRepository();
    final subject = Subject(userId: 1, name: 'Web Design', color: '#000');

    await repository.saveSubject(subject);
    final list = await repository.fetchSubjects();

    expect(list.length, 1);
    expect(list.first.name, 'Web Design');
  });
}