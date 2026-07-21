import 'package:drift/drift.dart' hide Column;
import '../../../core/database/app_database.dart' hide User, Subject, Notebook, Page;
import '../models/subject_model.dart';

class SubjectRepository {
  final AppDatabase _db = AppDatabase.instance;

  // =========================================================================
  // 📚 LER DISCIPLINAS
  // =========================================================================
  Future<List<Subject>> getAllSubjects() async {
    final rows = await (_db.select(_db.subjects)
          ..where((t) => t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .get();

    return rows.map((row) => Subject(
      id: row.id,
      serverId: row.serverId,
      userId: row.userId,
      name: row.name,
      color: row.color,
      icon: row.icon,
      syncedWithCloud: row.syncedWithCloud,
    )).toList();
  }

  // =========================================================================
  // 📡 ASSINAR DISCIPLINAS (REATIVO)
  // =========================================================================
  Stream<List<Subject>> watchAllSubjects() {
    return (_db.select(_db.subjects)
          ..where((t) => t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm(expression: t.name)]))
        .watch()
        .map((rows) => rows.map((row) => Subject(
              id: row.id,
              serverId: row.serverId,
              userId: row.userId,
              name: row.name,
              color: row.color,
              icon: row.icon,
              syncedWithCloud: row.syncedWithCloud,
            )).toList());
  }

  // =========================================================================
  // ➕ CRIAR DISCIPLINA
  // =========================================================================
  Future<Subject?> addSubject(Subject subject) async {
    final companion = SubjectsCompanion.insert(
      userId: subject.userId!,
      name: subject.name,
      color: subject.color,
      icon: Value(subject.icon),
      syncedWithCloud: const Value(0),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
    );

    final int insertedId = await _db.into(_db.subjects).insert(companion);

    return Subject(
      id: insertedId,
      userId: subject.userId,
      serverId: null,
      name: subject.name,
      color: subject.color,
      icon: subject.icon,
      syncedWithCloud: 0,
    );
  }

  // =========================================================================
  // ✏️ ATUALIZAR DISCIPLINA
  // =========================================================================
  Future<void> updateSubject(Subject subject) async {
    if (subject.id == null) return;
    await (_db.update(_db.subjects)..where((t) => t.id.equals(subject.id!))).write(
      SubjectsCompanion(
        name: Value(subject.name),
        color: Value(subject.color),
        icon: Value(subject.icon),
        syncedWithCloud: const Value(0),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  // =========================================================================
  // 🗑️ APAGAR DISCIPLINA
  // =========================================================================
  Future<void> deleteSubject(Subject subject) async {
    if (subject.id == null) return;
    await (_db.update(_db.subjects)..where((t) => t.id.equals(subject.id!))).write(
      const SubjectsCompanion(
        isDeleted: Value(1),
        syncedWithCloud: Value(0),
      ),
    );
  }
}
