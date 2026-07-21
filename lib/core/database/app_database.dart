import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

// O Drift gerará este arquivo para nós com as nossas tabelas e tipos seguros
part 'app_database.g.dart';

// ====================================================================
// 1. AS TABELAS DO SEU CADERNO DEFINIDAS EM DRIFT
// ====================================================================
class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  TextColumn get avatar => text().nullable()();
  TextColumn get planType => text().withDefault(const Constant('free'))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  IntColumn get userId => integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get color => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

class Notebooks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  IntColumn get subjectId => integer().nullable().references(Subjects, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get coverType => text()();
  TextColumn get color => text().nullable()();
  TextColumn get coverImage => text().nullable()();
  TextColumn get lineType => text().nullable()();
  TextColumn get paperSize => text().nullable()();
  IntColumn get isPublished => integer().withDefault(const Constant(0))();
  RealColumn get price => real().withDefault(const Constant(0.00))();
  TextColumn get description => text().nullable()();
  TextColumn get authorName => text().nullable()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

class Pages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  IntColumn get notebookId => integer().references(Notebooks, #id, onDelete: KeyAction.cascade)();
  IntColumn get pageNumber => integer()();
  IntColumn get isLandscape => integer().withDefault(const Constant(0))();
  TextColumn get headerData => text().nullable()();
  TextColumn get footerData => text().nullable()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

class CanvasStrokes extends Table {
  TextColumn get clientStrokeId => text()();
  IntColumn get serverId => integer().nullable()();
  IntColumn get pageId => integer().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get strokeData => text()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {clientStrokeId};
}

class CanvasTextBlocks extends Table {
  TextColumn get clientTextId => text()();
  IntColumn get serverId => integer().nullable()();
  IntColumn get pageId => integer().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get textData => text()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {clientTextId};
}

class CanvasImageBlocks extends Table {
  TextColumn get clientImageId => text()();
  IntColumn get serverId => integer().nullable()();
  IntColumn get pageId => integer().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get imagePath => text()();
  RealColumn get posX => real()();
  RealColumn get posY => real()();
  RealColumn get width => real()();
  RealColumn get height => real()();
  RealColumn get rotation => real()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();

  @override
  Set<Column> get primaryKey => {clientImageId};
}

class NotebookUser extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  IntColumn get notebookId => integer().references(Notebooks, #id, onDelete: KeyAction.cascade)();
  IntColumn get userId => integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get role => text().withDefault(const Constant('viewer'))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

class Payments extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable()();
  IntColumn get userId => integer().references(Users, #id, onDelete: KeyAction.cascade)();
  RealColumn get amount => real()();
  TextColumn get paymentMethod => text().withDefault(const Constant('multicaixa'))();
  TextColumn get entity => text()();
  TextColumn get reference => text()();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  TextColumn get itemType => text().withDefault(const Constant('subscription'))();
  IntColumn get itemId => integer().nullable()();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
}

// ====================================================================
// 2. A CLASSE PRINCIPAL DO BANCO (O seu novo DatabaseHelper)
// ====================================================================
@DriftDatabase(tables: [
  Users, Subjects, Notebooks, Pages, CanvasStrokes,
  CanvasTextBlocks, CanvasImageBlocks, NotebookUser, Payments
])
class AppDatabase extends _$AppDatabase {
  // Padrão Singleton usando drift_flutter para conexão automática multiplataforma
  AppDatabase._privateConstructor() : super(driftDatabase(name: 'caderno_digital_v9'));
  static final AppDatabase instance = AppDatabase._privateConstructor();

  // Construtor para Testes
  AppDatabase.forTesting(QueryExecutor connection) : super(connection);

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
    );
  }

  @override
  int get schemaVersion => 1;

  // Função equivalente ao seu antigo clearAllData()
  Future<void> clearAllData() async {
    await delete(canvasImageBlocks).go();
    await delete(canvasTextBlocks).go();
    await delete(canvasStrokes).go();
    await delete(pages).go();
    await delete(notebookUser).go();
    await delete(notebooks).go();
    await delete(subjects).go();
    await delete(payments).go();
    await delete(users).go();
  }
}
