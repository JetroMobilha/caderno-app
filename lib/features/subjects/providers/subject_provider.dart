import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/database_helper.dart';
import '../models/subject_model.dart';

// 1. A Classe que gere o estado (agora usando a versão moderna: Notifier)
class SubjectNotifier extends Notifier<List<Subject>> {
  final dbHelper = DatabaseHelper.instance;

  // No novo Riverpod, usamos o método 'build' para definir o estado inicial
  @override
  List<Subject> build() {
    loadSubjects(); // Manda carregar os dados assim que a app arranca
    return [];      // O estado inicial é uma lista vazia
  }

  // Função para LER as disciplinas do SQLite
  Future<void> loadSubjects() async {
    final db = await dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query('subjects');

    // Atualiza o ecrã com as disciplinas encontradas
    state = maps.map((map) => Subject.fromMap(map)).toList();
  }

  // Função para CRIAR uma nova disciplina
  Future<void> addSubject(Subject subject) async {
    final db = await dbHelper.database;

    final id = await db.insert('subjects', subject.toMap());

    // Adiciona a nova disciplina à lista atual no ecrã
    final newSubject = Subject(
      id: id,
      userId: subject.userId,
      name: subject.name,
      color: subject.color,
      icon: subject.icon,
      syncedWithCloud: subject.syncedWithCloud,
    );

    state = [...state, newSubject];
  }
}

// 2. O Provider global usando a nova sintaxe NotifierProvider
final subjectProvider = NotifierProvider<SubjectNotifier, List<Subject>>(() {
  return SubjectNotifier();
});