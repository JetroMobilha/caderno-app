import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/subject_model.dart';
import '../repositories/subject_repository.dart';

class SubjectNotifier extends Notifier<List<Subject>> {
  // Instanciamos o nosso repositório inteligente
  final _repository = SubjectRepository();

  @override
  List<Subject> build() {
    loadSubjects();
    return [];
  }

  Future<void> loadSubjects() async {
    // O ecrã já não quer saber se vem do SQL ou do Chrome, o repositório resolve!
    state = await _repository.getSubjects();
  }

  Future<void> addSubject(Subject subject) async {
    await _repository.insertSubject(subject);
    // Atualiza a UI localmente de forma fluida
    state = [...state, subject];
  }
}

final subjectProvider = NotifierProvider<SubjectNotifier, List<Subject>>(() {
  return SubjectNotifier();
});