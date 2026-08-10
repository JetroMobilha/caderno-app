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
  IntColumn get version => integer().withDefault(const Constant(1))();
}

class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  TextColumn get clientId => text().nullable().unique()(); // 🆔 Identidade única global
  IntColumn get userId => integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get color => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
}

class Notebooks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  TextColumn get clientId => text().nullable().unique()(); // 🆔 Identidade única global
  IntColumn get subjectId => integer().nullable().references(Subjects, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get coverType => text()();
  TextColumn get color => text().nullable()();
  TextColumn get coverImage => text().nullable()();
  TextColumn get lineType => text().nullable()();
  TextColumn get paperSize => text().nullable()();
  RealColumn get lineSpacing => real().nullable()(); // 📏 Espaçamento dinâmico
  IntColumn get isPublished => integer().withDefault(const Constant(0))();
  RealColumn get price => real().withDefault(const Constant(0.00))();
  TextColumn get description => text().nullable()();
  TextColumn get authorName => text().nullable()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get templateType => text().withDefault(const Constant('study'))(); // 🚀 study, technical, formal
  TextColumn get collaborationMode => text().withDefault(const Constant('study_group'))(); // 🚀 study_group, lecture, tutoring
}

class Pages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  TextColumn get clientId => text().nullable().unique()(); // 🆔 Identidade única global
  IntColumn get notebookId => integer().references(Notebooks, #id, onDelete: KeyAction.cascade)();
  IntColumn get pageNumber => integer()();
  IntColumn get isLandscape => integer().withDefault(const Constant(0))();
  TextColumn get headerData => text().nullable()();
  TextColumn get footerData => text().nullable()();
  TextColumn get extractedText => text().nullable()(); // 🧠 O cérebro local: Armazena o texto convertido da escrita manual
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get isFrozen => integer().withDefault(const Constant(0))(); // 🚀 0 = Open, 1 = Frozen
  TextColumn get paperSize => text().withDefault(const Constant('A4'))(); // 🚀 Novo: Tamanho por folha
  TextColumn get backgroundPdfPath => text().nullable()(); // 🚀 Para modo Técnico/Engenharia
}

class CanvasStrokes extends Table {
  TextColumn get clientStrokeId => text()();
  IntColumn get serverId => integer().nullable()();
  IntColumn get pageId => integer().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get strokeData => text()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get deletedInSession => integer().withDefault(const Constant(0))(); // 🚀 Novo
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get creatorId => text().nullable()(); // 🚀 Identifica quem criou
  TextColumn get layerId => text().nullable()(); // 🚀 Agrupamento de traços (Novo)

  @override
  Set<Column> get primaryKey => {clientStrokeId};
}

class CanvasTextBlocks extends Table {
  TextColumn get clientTextId => text()();
  IntColumn get serverId => integer().nullable()();
  IntColumn get pageId => integer().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get textData => text()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get deletedInSession => integer().withDefault(const Constant(0))(); 
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get creatorId => text().nullable()(); // 🚀 Identifica quem criou
  TextColumn get layerId => text().nullable()(); // 🚀 Agrupamento de textos (Novo)

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
  IntColumn get deletedInSession => integer().withDefault(const Constant(0))(); 
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get creatorId => text().nullable()(); // 🚀 Identifica quem criou
  TextColumn get layerId => text().nullable()(); // 🚀 Agrupamento de imagens (Novo)

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
  IntColumn get version => integer().withDefault(const Constant(1))();
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
  IntColumn get version => integer().withDefault(const Constant(1))();
}

class LessonRecordings extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  TextColumn get clientId => text().nullable().unique()();
  IntColumn get notebookId => integer().references(Notebooks, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get audioUrl => text()();
  IntColumn get durationSeconds => integer().withDefault(const Constant(0))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
}

// ====================================================================
// 2. A CLASSE PRINCIPAL DO BANCO (O seu novo DatabaseHelper)
// ====================================================================
@DriftDatabase(tables: [
  Users, Subjects, Notebooks, Pages, CanvasStrokes,
  CanvasTextBlocks, CanvasImageBlocks, NotebookUser, Payments, LessonRecordings
])
class AppDatabase extends _$AppDatabase {
  // Padrão Singleton usando drift_flutter para conexão automática multiplataforma
  AppDatabase._privateConstructor() : super(driftDatabase(
    name: 'caderno_digital_v9',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  ));
  static final AppDatabase instance = AppDatabase._privateConstructor();

  // Construtor para Testes
  AppDatabase.forTesting(QueryExecutor connection) : super(connection);

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) {
          // Migração da v1 para v2: Adicionar coluna extractedText
          await m.addColumn(pages, pages.extractedText);
        }
        if (from < 3) {
          // 🚀 Migração v2 -> v3: Reconstrução total das tabelas para garantir UNIQUE no clientId
          await m.alterTable(TableMigration(subjects, newColumns: [subjects.clientId]));
          await m.alterTable(TableMigration(notebooks, newColumns: [notebooks.clientId]));
        }
        if (from < 4) {
          // 🚀 Migração v3 -> v4: Adicionar colunas deletedInSession
          await m.addColumn(canvasStrokes, canvasStrokes.deletedInSession);
          await m.addColumn(canvasTextBlocks, canvasTextBlocks.deletedInSession);
          await m.addColumn(canvasImageBlocks, canvasImageBlocks.deletedInSession);
        }
        if (from < 5) {
          // 🚀 Migração v4 -> v5: Adicionar clientId na tabela Pages
          await m.alterTable(TableMigration(pages, newColumns: [pages.clientId]));
        }
        if (from < 6) {
          // 🚀 Migração v5 -> v6: Adicionar lineSpacing na tabela Notebooks
          await m.addColumn(notebooks, notebooks.lineSpacing);
        }
        if (from < 7) {
          // 🚀 Migração v6 -> v7: Adicionar version em TODAS as tabelas para consistência
          await m.addColumn(users, users.version);
          await m.addColumn(subjects, subjects.version);
          await m.addColumn(notebooks, notebooks.version);
          await m.addColumn(pages, pages.version);
          await m.addColumn(canvasStrokes, canvasStrokes.version);
          await m.addColumn(canvasTextBlocks, canvasTextBlocks.version);
          await m.addColumn(canvasImageBlocks, canvasImageBlocks.version);
          await m.addColumn(notebookUser, notebookUser.version);
          await m.addColumn(payments, payments.version);
        }
        if (from < 8) {
          // 🚀 Migração v7 -> v8: Adicionar creatorId
          await customStatement('ALTER TABLE canvas_strokes ADD COLUMN creator_id TEXT');
          await customStatement('ALTER TABLE canvas_text_blocks ADD COLUMN creator_id TEXT');
          await customStatement('ALTER TABLE canvas_image_blocks ADD COLUMN creator_id TEXT');
        }
        if (from < 9) {
          // 🚀 Migração v8 -> v9: Adicionar templateType na tabela Notebooks
          await m.addColumn(notebooks, notebooks.templateType);
        }
        if (from < 10) {
          // 🚀 Migração v9 -> v10: Adicionar isFrozen na tabela Pages
          await m.addColumn(pages, pages.isFrozen);
        }
        if (from < 11) {
          // 🚀 Migração v10 -> v11: Adicionar backgroundPdfPath e layerId
          await m.addColumn(pages, pages.backgroundPdfPath);
          await m.addColumn(canvasStrokes, canvasStrokes.layerId);
          await m.addColumn(canvasTextBlocks, canvasTextBlocks.layerId);
          await m.addColumn(canvasImageBlocks, canvasImageBlocks.layerId);
        }
        if (from < 12) {
          // 🚀 Migração v11 -> v12: Adicionar tabela LessonRecordings
          await m.createTable(lessonRecordings);
        }
        if (from < 13) {
          // 🚀 Migração v12 -> v13: Adicionar paperSize à tabela Pages
          await m.addColumn(pages, pages.paperSize);
        }
        if (from < 14) {
          // 🚀 Migração v13 -> v14: Adicionar collaborationMode à tabela Notebooks
          await m.addColumn(notebooks, notebooks.collaborationMode);
        }
      },
    );
  }

  @override
  int get schemaVersion => 14;

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
