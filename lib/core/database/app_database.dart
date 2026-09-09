import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

class Users extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  TextColumn get name => text()();
  TextColumn get email => text().unique()();
  TextColumn get avatar => text().nullable()();
  TextColumn get planType => text().withDefault(const Constant('free'))();
  TextColumn get bio => text().nullable()();
  TextColumn get institution => text().nullable()();
  TextColumn get preferredColor => text().nullable()();
  TextColumn get preferredFont => text().nullable()();
  TextColumn get specialties => text().nullable()();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get isArchived => integer().withDefault(const Constant(0))(); 
  IntColumn get isFavorite => integer().withDefault(const Constant(0))(); 
}

class Subjects extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  TextColumn get clientId => text().nullable().unique()();
  IntColumn get userId => integer().references(Users, #id, onDelete: KeyAction.cascade)();
  TextColumn get name => text()();
  TextColumn get color => text()();
  TextColumn get icon => text().nullable()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get isArchived => integer().withDefault(const Constant(0))(); 
  IntColumn get isFavorite => integer().withDefault(const Constant(0))(); 
}

class Notebooks extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  TextColumn get clientId => text().nullable().unique()();
  IntColumn get subjectId => integer().nullable().references(Subjects, #id, onDelete: KeyAction.cascade)();
  TextColumn get title => text()();
  TextColumn get coverType => text()();
  TextColumn get color => text().nullable()();
  TextColumn get coverImage => text().nullable()();
  IntColumn get isPublished => integer().withDefault(const Constant(0))();
  RealColumn get price => real().withDefault(const Constant(0.00))();
  TextColumn get description => text().nullable()();
  TextColumn get authorName => text().nullable()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get templateType => text().withDefault(const Constant('study'))();
  TextColumn get collaborationMode => text().withDefault(const Constant('study_group'))();
  TextColumn get role => text().withDefault(const Constant('owner'))();
  TextColumn get alternativeTitle => text().nullable()();
  TextColumn get sharingType => text().withDefault(const Constant('full'))();
  TextColumn get tags => text().nullable()(); 
  IntColumn get isArchived => integer().withDefault(const Constant(0))(); 
  IntColumn get isFavorite => integer().withDefault(const Constant(0))(); 
  TextColumn get origin => text().nullable()(); 
  TextColumn get participantsPreview => text().nullable()(); 
  TextColumn get lastUpdatedByName => text().nullable()(); 
  IntColumn get notificationsEnabled => integer().withDefault(const Constant(1))(); 
  TextColumn get configuration => text().nullable()(); 
}

class Pages extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get serverId => integer().nullable().unique()();
  TextColumn get clientId => text().nullable().unique()();
  IntColumn get notebookId => integer().references(Notebooks, #id, onDelete: KeyAction.cascade)();
  IntColumn get pageNumber => integer()();
  IntColumn get isLandscape => integer().withDefault(const Constant(0))();
  TextColumn get headerData => text().nullable()();
  TextColumn get footerData => text().nullable()();
  TextColumn get extractedText => text().nullable()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  IntColumn get isFrozen => integer().withDefault(const Constant(0))();
  IntColumn get isFavorite => integer().withDefault(const Constant(0))(); 
  TextColumn get paperSize => text().withDefault(const Constant('A4'))();
  TextColumn get lineType => text().nullable()();
  RealColumn get lineSpacing => real().nullable()();
  TextColumn get backgroundPdfPath => text().nullable()();
  TextColumn get backgroundConfig => text().nullable()(); 
  TextColumn get viewportMatrix => text().nullable()(); 
  TextColumn get layers => text().nullable()(); 
}

class CanvasStrokes extends Table {
  TextColumn get clientStrokeId => text()();
  IntColumn get serverId => integer().nullable()();
  IntColumn get pageId => integer().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get strokeData => text()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get deletedInSession => integer().withDefault(const Constant(0))();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get creatorId => text().nullable()();
  TextColumn get layerId => text().nullable()(); 
  TextColumn get parentId => text().nullable()(); 
  IntColumn get isVisible => integer().withDefault(const Constant(1))(); 
  IntColumn get isLocked => integer().withDefault(const Constant(0))(); 
  RealColumn get opacity => real().withDefault(const Constant(1.0))(); 
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
  TextColumn get creatorId => text().nullable()();
  TextColumn get layerId => text().nullable()(); 
  TextColumn get parentId => text().nullable()(); 
  IntColumn get isVisible => integer().withDefault(const Constant(1))(); 
  IntColumn get isLocked => integer().withDefault(const Constant(0))(); 
  RealColumn get opacity => real().withDefault(const Constant(1.0))(); 
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
  TextColumn get creatorId => text().nullable()();
  TextColumn get layerId => text().nullable()(); 
  TextColumn get parentId => text().nullable()(); 
  IntColumn get isVisible => integer().withDefault(const Constant(1))(); 
  IntColumn get isLocked => integer().withDefault(const Constant(0))(); 
  RealColumn get opacity => real().withDefault(const Constant(1.0))(); 
  @override
  Set<Column> get primaryKey => {clientImageId};
}

class CanvasShapes extends Table {
  TextColumn get clientShapeId => text()();
  IntColumn get pageId => integer().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get shapeData => text()(); 
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  IntColumn get version => integer().withDefault(const Constant(1))();
  TextColumn get layerId => text().nullable()();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  TextColumn get parentId => text().nullable()(); 
  IntColumn get isVisible => integer().withDefault(const Constant(1))(); 
  IntColumn get isLocked => integer().withDefault(const Constant(0))(); 
  RealColumn get opacity => real().withDefault(const Constant(1.0))(); 
  @override
  Set<Column> get primaryKey => {clientShapeId};
}

class CanvasAudioBlocks extends Table {
  TextColumn get clientAudioId => text()();
  IntColumn get pageId => integer().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get audioData => text()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  TextColumn get layerId => text().nullable()();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  TextColumn get parentId => text().nullable()(); 
  IntColumn get isVisible => integer().withDefault(const Constant(1))(); 
  IntColumn get isLocked => integer().withDefault(const Constant(0))(); 
  RealColumn get opacity => real().withDefault(const Constant(1.0))(); 
  @override
  Set<Column> get primaryKey => {clientAudioId};
}

class CanvasAnimations extends Table {
  TextColumn get clientAnimationId => text()();
  IntColumn get pageId => integer().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get animationData => text()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  TextColumn get layerId => text().nullable()();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  TextColumn get parentId => text().nullable()(); 
  IntColumn get isVisible => integer().withDefault(const Constant(1))(); 
  IntColumn get isLocked => integer().withDefault(const Constant(0))(); 
  RealColumn get opacity => real().withDefault(const Constant(1.0))(); 
  @override
  Set<Column> get primaryKey => {clientAnimationId};
}

class CanvasTables extends Table {
  TextColumn get clientTableId => text()();
  IntColumn get pageId => integer().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get tableData => text()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  TextColumn get layerId => text().nullable()();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  TextColumn get parentId => text().nullable()(); 
  IntColumn get isVisible => integer().withDefault(const Constant(1))(); 
  IntColumn get isLocked => integer().withDefault(const Constant(0))(); 
  RealColumn get opacity => real().withDefault(const Constant(1.0))(); 
  @override
  Set<Column> get primaryKey => {clientTableId};
}

class CanvasLinks extends Table {
  TextColumn get clientLinkId => text()();
  IntColumn get pageId => integer().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get linkData => text()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  TextColumn get layerId => text().nullable()();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  TextColumn get parentId => text().nullable()(); 
  IntColumn get isVisible => integer().withDefault(const Constant(1))(); 
  IntColumn get isLocked => integer().withDefault(const Constant(0))(); 
  RealColumn get opacity => real().withDefault(const Constant(1.0))(); 
  @override
  Set<Column> get primaryKey => {clientLinkId};
}

class CanvasAttachments extends Table {
  TextColumn get clientAttachmentId => text()();
  IntColumn get pageId => integer().references(Pages, #id, onDelete: KeyAction.cascade)();
  TextColumn get attachmentData => text()();
  IntColumn get isDeleted => integer().withDefault(const Constant(0))();
  IntColumn get updatedAt => integer().withDefault(const Constant(0))();
  TextColumn get layerId => text().nullable()();
  IntColumn get syncedWithCloud => integer().withDefault(const Constant(0))();
  TextColumn get parentId => text().nullable()(); 
  IntColumn get isVisible => integer().withDefault(const Constant(1))(); 
  IntColumn get isLocked => integer().withDefault(const Constant(0))(); 
  RealColumn get opacity => real().withDefault(const Constant(1.0))(); 
  @override
  Set<Column> get primaryKey => {clientAttachmentId};
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
  IntColumn get isArchived => integer().withDefault(const Constant(0))(); 
  IntColumn get isFavorite => integer().withDefault(const Constant(0))(); 
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
  IntColumn get isArchived => integer().withDefault(const Constant(0))(); 
  IntColumn get isFavorite => integer().withDefault(const Constant(0))(); 
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
  IntColumn get isArchived => integer().withDefault(const Constant(0))(); 
  IntColumn get isFavorite => integer().withDefault(const Constant(0))(); 
}

class NotebookTemplates extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get description => text().nullable()();
  TextColumn get category => text().nullable()();
  TextColumn get icon => text().nullable()();
  TextColumn get cover => text().nullable()();
  IntColumn get isSystem => integer().withDefault(const Constant(0))();
  IntColumn get createdBy => integer().nullable()();
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

class NotebookTemplateVersions extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get templateId => integer().references(NotebookTemplates, #id, onDelete: KeyAction.cascade)();
  IntColumn get version => integer()();
  TextColumn get configuration => text()(); 
  IntColumn get createdAt => integer()();
  IntColumn get updatedAt => integer()();
}

@DriftDatabase(tables: [
  Users, Subjects, Notebooks, Pages, CanvasStrokes,
  CanvasTextBlocks, CanvasImageBlocks, CanvasShapes, CanvasAudioBlocks, 
  CanvasAnimations, CanvasTables, CanvasLinks, CanvasAttachments,
  NotebookUser, Payments, LessonRecordings,
  NotebookTemplates, NotebookTemplateVersions
])
class AppDatabase extends _$AppDatabase {
  AppDatabase._privateConstructor() : super(driftDatabase(
    name: 'caderno_digital_v9',
    web: DriftWebOptions(
      sqlite3Wasm: Uri.parse('sqlite3.wasm'),
      driftWorker: Uri.parse('drift_worker.js'),
    ),
  ));
  static final AppDatabase instance = AppDatabase._privateConstructor();

  AppDatabase.forTesting(QueryExecutor connection) : super(connection);

  @override
  MigrationStrategy get migration {
    return MigrationStrategy(
      beforeOpen: (details) async {
        await customStatement('PRAGMA foreign_keys = ON');
      },
      onUpgrade: (m, from, to) async {
        if (from < 2) await m.addColumn(pages, pages.extractedText);
        if (from < 3) {
          await m.alterTable(TableMigration(subjects, newColumns: [subjects.clientId]));
          await m.alterTable(TableMigration(notebooks, newColumns: [notebooks.clientId]));
        }
        if (from < 4) {
          await m.addColumn(canvasStrokes, canvasStrokes.deletedInSession);
          await m.addColumn(canvasTextBlocks, canvasTextBlocks.deletedInSession);
          await m.addColumn(canvasImageBlocks, canvasImageBlocks.deletedInSession);
        }
        if (from < 5) await m.alterTable(TableMigration(pages, newColumns: [pages.clientId]));
        if (from < 6)  ;
        if (from < 7) {
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
          await customStatement('ALTER TABLE canvas_strokes ADD COLUMN creator_id TEXT');
          await customStatement('ALTER TABLE canvas_text_blocks ADD COLUMN creator_id TEXT');
          await customStatement('ALTER TABLE canvas_image_blocks ADD COLUMN creator_id TEXT');
        }
        if (from < 9) await m.addColumn(notebooks, notebooks.templateType);
        if (from < 10) await m.addColumn(pages, pages.isFrozen);
        if (from < 11) {
          await m.addColumn(pages, pages.backgroundPdfPath);
          await m.addColumn(canvasStrokes, canvasStrokes.layerId);
        }
        if (from < 12) await m.createTable(lessonRecordings);
        if (from < 13) await m.addColumn(pages, pages.paperSize);
        if (from < 14) await m.addColumn(notebooks, notebooks.collaborationMode);
        if (from < 15) await customStatement('ALTER TABLE notebooks ADD COLUMN role TEXT DEFAULT "owner"');
        if (from < 16) {
          await customStatement('ALTER TABLE notebooks ADD COLUMN alternative_title TEXT');
          await customStatement('ALTER TABLE notebooks ADD COLUMN sharing_type TEXT DEFAULT "full"');
        }
        if (from < 17) {
          await m.addColumn(pages, pages.lineType);
          await m.addColumn(pages, pages.lineSpacing);
        }
        if (from < 18) {
          await customStatement('ALTER TABLE users ADD COLUMN bio TEXT');
          await customStatement('ALTER TABLE users ADD COLUMN institution TEXT');
          await customStatement('ALTER TABLE users ADD COLUMN preferred_color TEXT');
          await customStatement('ALTER TABLE users ADD COLUMN preferred_font TEXT');
          await customStatement('ALTER TABLE users ADD COLUMN specialties TEXT');
        }
        if (from < 19) {
          await customStatement('ALTER TABLE pages ADD COLUMN is_favorite INTEGER DEFAULT 0 NOT NULL');
        }
        if (from < 20) {
          await m.addColumn(notebooks, notebooks.tags);
          await m.addColumn(notebooks, notebooks.isArchived);
          await m.addColumn(notebooks, notebooks.isFavorite);
        }
        if (from < 21) {}
        if (from < 22) {
          await m.addColumn(subjects, subjects.isArchived);
          await m.addColumn(subjects, subjects.isFavorite);
        }
        if (from < 23) {
          await m.addColumn(users, users.isArchived);
          await m.addColumn(users, users.isFavorite);
          await m.addColumn(notebookUser, notebookUser.isArchived);
          await m.addColumn(notebookUser, notebookUser.isFavorite);
          await m.addColumn(payments, payments.isArchived);
          await m.addColumn(payments, payments.isFavorite);
          await m.addColumn(lessonRecordings, lessonRecordings.isArchived);
          await m.addColumn(lessonRecordings, lessonRecordings.isFavorite);
          try { await m.addColumn(subjects, subjects.isArchived); } catch(_) {}
          try { await m.addColumn(subjects, subjects.isFavorite); } catch(_) {}
          try { await m.addColumn(notebooks, notebooks.isArchived); } catch(_) {}
          try { await m.addColumn(notebooks, notebooks.isFavorite); } catch(_) {}
        }
        if (from < 24) {
          await m.addColumn(notebooks, notebooks.origin);
          await m.addColumn(notebooks, notebooks.participantsPreview);
          await m.addColumn(notebooks, notebooks.lastUpdatedByName);
          await m.addColumn(notebooks, notebooks.notificationsEnabled);
        }
        if (from < 25) {
          try { await m.addColumn(notebooks, notebooks.configuration); } catch(_) {}
          try { await m.addColumn(pages, pages.backgroundConfig); } catch(_) {}
          try { await m.createTable(notebookTemplates); } catch(_) {}
          try { await m.createTable(notebookTemplateVersions); } catch(_) {}
        }
        if (from < 27) {
          try { await m.addColumn(pages, pages.viewportMatrix); } catch(_) {}
        }
        if (from < 28) {
          try { await m.addColumn(pages, pages.layers); } catch(_) {}
          try { await m.addColumn(canvasImageBlocks, canvasImageBlocks.layerId); } catch(_) {}
          try { await m.addColumn(canvasTextBlocks, canvasTextBlocks.layerId); } catch(_) {}
          try { await m.createTable(canvasShapes); } catch(_) {}
          try { await m.createTable(canvasAudioBlocks); } catch(_) {}
          try { await m.createTable(canvasAnimations); } catch(_) {}
        }
        if (from < 29) {
          try { await m.createTable(canvasTables); } catch(_) {}
          try { await m.createTable(canvasLinks); } catch(_) {}
          try { await m.createTable(canvasAttachments); } catch(_) {}
        }
        if (from < 30) {
          try { await m.addColumn(canvasShapes, canvasShapes.syncedWithCloud); } catch(_) {}
          try { await m.addColumn(canvasAudioBlocks, canvasAudioBlocks.syncedWithCloud); } catch(_) {}
          try { await m.addColumn(canvasAnimations, canvasAnimations.syncedWithCloud); } catch(_) {}
          try { await m.addColumn(canvasTables, canvasTables.syncedWithCloud); } catch(_) {}
          try { await m.addColumn(canvasLinks, canvasLinks.syncedWithCloud); } catch(_) {}
          try { await m.addColumn(canvasAttachments, canvasAttachments.syncedWithCloud); } catch(_) {}
        }
        if (from < 31) {
          // 🚀 v31: Metadados de Grupo, Visibilidade e Bloqueio
          // NOTA: Acesso via customStatement para evitar dependência do código gerado
          final tables = [
            'canvas_strokes', 'canvas_text_blocks', 'canvas_image_blocks',
            'canvas_shapes', 'canvas_audio_blocks', 'canvas_animations',
            'canvas_tables', 'canvas_links', 'canvas_attachments'
          ];
          for (var t in tables) {
            await customStatement('ALTER TABLE $t ADD COLUMN parent_id TEXT');
            await customStatement('ALTER TABLE $t ADD COLUMN is_visible INTEGER DEFAULT 1');
            await customStatement('ALTER TABLE $t ADD COLUMN is_locked INTEGER DEFAULT 0');
            await customStatement('ALTER TABLE $t ADD COLUMN opacity REAL DEFAULT 1.0');
          }
        }
      },
    );
  }

  @override
  int get schemaVersion => 31;

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
