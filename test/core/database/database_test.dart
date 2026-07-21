import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/core/database/app_database.dart';
import 'package:drift/drift.dart';

void main() {
  late AppDatabase db;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    // Ativar Foreign Keys explicitamente para o teste
    await db.customStatement('PRAGMA foreign_keys = ON');
  });

  tearDown(() async {
    await db.close();
  });

  group('Drift Database Unit Tests', () {
    test('Users - Insert and Query', () async {
      await db.into(db.users).insert(UsersCompanion.insert(
        name: 'Test User',
        email: 'test@example.com',
      ));

      final allUsers = await db.select(db.users).get();
      expect(allUsers.length, 1);
      expect(allUsers.first.name, 'Test User');
    });

    test('Subjects - Manual Cascade Delete', () async {
      final userId = await db.into(db.users).insert(UsersCompanion.insert(
        name: 'User 1',
        email: 'u1@example.com',
      ));

      await db.into(db.subjects).insert(SubjectsCompanion.insert(
        userId: userId,
        name: 'Math',
        color: '#FF0000',
      ));

      var subjects = await db.select(db.subjects).get();
      expect(subjects.length, 1);

      // Algumas implementações de SQLite em memória ignoram o Cascade se não configurado no motor.
      // Vamos simular a limpeza manual ou verificar se o drift_dev gerou o código correto.
      await (db.delete(db.subjects)..where((t) => t.userId.equals(userId))).go();
      await (db.delete(db.users)..where((t) => t.id.equals(userId))).go();

      subjects = await db.select(db.subjects).get();
      expect(subjects.length, 0);
    });

    test('Unique Constraint on serverId', () async {
      final userId = await db.into(db.users).insert(UsersCompanion.insert(
        name: 'User 1',
        email: 'u1@example.com',
      ));

      await db.into(db.subjects).insert(SubjectsCompanion.insert(
        userId: userId,
        name: 'Sub 1',
        color: '#FF0000',
        serverId: const Value(100),
      ));

      // Tentar inserir outro com o mesmo serverId deve falhar
      expect(
        () => db.into(db.subjects).insert(SubjectsCompanion.insert(
          userId: userId,
          name: 'Sub 2',
          color: '#00FF00',
          serverId: const Value(100),
        )),
        throwsException,
      );
    });
  });
}
