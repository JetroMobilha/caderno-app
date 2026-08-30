import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import '../../../core/database/app_database.dart' hide User, Subject, Notebook, Page;
import '../models/subject_model.dart';

class SubjectRepository {
  final AppDatabase _db;

  SubjectRepository(this._db);

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
      clientId: row.clientId, // 🆔 Restaurado do banco
      userId: row.userId,
      name: row.name,
      color: row.color,
      icon: row.icon,
      syncedWithCloud: row.syncedWithCloud,
      isArchived: row.isArchived == 1,
      isFavorite: row.isFavorite == 1,
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
              clientId: row.clientId, // 🆔 Restaurado do banco
              userId: row.userId,
              name: row.name,
              color: row.color,
              icon: row.icon,
              syncedWithCloud: row.syncedWithCloud,
              isArchived: row.isArchived == 1,
              isFavorite: row.isFavorite == 1,
            )).toList());
  }

  // =========================================================================
  // ➕ CRIAR DISCIPLINA
  // =========================================================================
  Future<Subject?> addSubject(Subject subject) async {
    // 🚀 Usando companion dinâmico para evitar erros antes da regeneração
    final companion = SubjectsCompanion.insert(
      userId: subject.userId!,
      clientId: Value(subject.clientId),
      name: subject.name,
      color: subject.color,
      icon: Value(subject.icon),
      syncedWithCloud: const Value(0),
      updatedAt: Value(TimeService().nowMs()),
      isArchived: Value(subject.isArchived ? 1 : 0),
      isFavorite: Value(subject.isFavorite ? 1 : 0),
    );

    final int insertedId = await _db.into(_db.subjects).insert(companion);

    return Subject(
      id: insertedId,
      userId: subject.userId,
      clientId: subject.clientId,
      serverId: null,
      name: subject.name,
      color: subject.color,
      icon: subject.icon,
      syncedWithCloud: 0,
      isArchived: subject.isArchived,
      isFavorite: subject.isFavorite,
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
        updatedAt: Value(TimeService().nowMs()),
        isArchived: Value(subject.isArchived ? 1 : 0),
        isFavorite: Value(subject.isFavorite ? 1 : 0),
      ),
    );
  }

  // =========================================================================
  // 🗑️ APAGAR DISCIPLINA
  // =========================================================================
  Future<void> deleteSubject(Subject subject) async {
    if (subject.id == null) return;
    await (_db.update(_db.subjects)..where((t) => t.id.equals(subject.id!))).write(
      SubjectsCompanion(
        isDeleted: const Value(1),
        syncedWithCloud: const Value(0),
        updatedAt: Value(TimeService().nowMs()), // 🚀 Atualizar para o Sync detetar
      ),
    );
  }

  // =========================================================================
  // ♻️ LIXEIRA & RESTAURO
  // =========================================================================
  Future<List<Subject>> getDeletedSubjects() async {
    final rows = await (_db.select(_db.subjects)
          ..where((t) => t.isDeleted.equals(1))
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .get();

    return rows.map((row) => Subject(
      id: row.id,
      serverId: row.serverId,
      clientId: row.clientId,
      userId: row.userId,
      name: row.name,
      color: row.color,
      icon: row.icon,
      syncedWithCloud: row.syncedWithCloud,
      isDeleted: row.isDeleted,
      updatedAt: row.updatedAt,
      isArchived: (row as dynamic).isArchived == 1,
      isFavorite: (row as dynamic).isFavorite == 1,
    )).toList();
  }

  Future<void> restoreSubject(int id) async {
    await (_db.update(_db.subjects)..where((t) => t.id.equals(id))).write(
      SubjectsCompanion(
        isDeleted: const Value(0),
        syncedWithCloud: const Value(0),
        updatedAt: Value(TimeService().nowMs()),
      ),
    );
  }

  Future<void> hardDeleteSubject(int id) async {
    await (_db.delete(_db.subjects)..where((t) => t.id.equals(id))).go();
  }
}

final subjectRepositoryProvider = Provider<SubjectRepository>((ref) {
  return SubjectRepository(AppDatabase.instance);
});
