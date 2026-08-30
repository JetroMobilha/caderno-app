import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:caderno_digital_app/core/database/app_database.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:drift/drift.dart';

void main() {
  late AppDatabase db;
  late CanvasRepository repository;

  setUp(() async {
    db = AppDatabase.forTesting(NativeDatabase.memory());
    repository = CanvasRepository(db);
    
    // Setup initial data: User, Subject, Notebook
    await db.into(db.users).insert(UsersCompanion.insert(id: const Value(1), name: 'Test', email: 'test@test.com'));
    await db.into(db.subjects).insert(SubjectsCompanion.insert(id: const Value(1), userId: 1, name: 'Math', color: '#FF0000'));
    await db.into(db.notebooks).insert(NotebooksCompanion.insert(id: const Value(1), subjectId: const Value(1), title: 'Notebook 1', coverType: 'color'));
    await db.into(db.notebooks).insert(NotebooksCompanion.insert(id: const Value(2), subjectId: const Value(1), title: 'Notebook 2', coverType: 'color'));
  });

  tearDown(() async {
    await db.close();
  });

  group('CanvasRepository Structural Tests', () {
    test('Reordering pages updates pageNumber correctly', () async {
      // 1. Create 3 pages
      final p1 = LocalPage(notebookId: 1, pageNumber: 1, isLandscape: false, clientId: 'c1');
      final p2 = LocalPage(notebookId: 1, pageNumber: 2, isLandscape: false, clientId: 'c2');
      final p3 = LocalPage(notebookId: 1, pageNumber: 3, isLandscape: false, clientId: 'c3');

      await repository.savePage(p1, null);
      await repository.savePage(p2, null);
      await repository.savePage(p3, null);

      // 2. Perform reindex (reorder logic usually happens in provider + repository reindex)
      // Simulating a move: move c3 to position 1
      await db.batch((batch) {
        batch.update(db.pages, const PagesCompanion(pageNumber: Value(1)), where: (t) => t.clientId.equals('c3'));
        batch.update(db.pages, const PagesCompanion(pageNumber: Value(2)), where: (t) => t.clientId.equals('c1'));
        batch.update(db.pages, const PagesCompanion(pageNumber: Value(3)), where: (t) => t.clientId.equals('c2'));
      });

      final pages = await repository.getPagesByNotebook(1, null);
      expect(pages[0].clientId, 'c3');
      expect(pages[1].clientId, 'c1');
      expect(pages[2].clientId, 'c2');
      expect(pages[0].pageNumber, 1);
      expect(pages[2].pageNumber, 3);
    });

    test('Soft Delete keeps page in database but hides from active list', () async {
      final p1 = LocalPage(notebookId: 1, pageNumber: 1, isLandscape: false, clientId: 'c1');
      await repository.savePage(p1, null);

      // Soft delete
      await (db.update(db.pages)..where((t) => t.clientId.equals('c1'))).write(const PagesCompanion(isDeleted: Value(1)));

      final activePages = await repository.getPagesByNotebook(1, null);
      final deletedPages = await repository.getDeletedPages(1);

      expect(activePages, isEmpty);
      expect(deletedPages.length, 1);
      expect(deletedPages.first.clientId, 'c1');
    });

    test('Restore page brings it back to active list', () async {
      final p1 = LocalPage(notebookId: 1, pageNumber: 1, isLandscape: false, clientId: 'c1', isDeleted: true);
      await repository.savePage(p1, null); // Saved as deleted

      await repository.restorePage('c1');

      final activePages = await repository.getPagesByNotebook(1, null);
      expect(activePages.length, 1);
      expect(activePages.first.isDeleted, false);
    });

    test('Moving page between notebooks updates notebookId', () async {
      final p1 = LocalPage(notebookId: 1, pageNumber: 1, isLandscape: false, clientId: 'c1');
      await repository.savePage(p1, null);

      // Move to Notebook 2 at position 1
      await repository.movePageToNotebook('c1', 2, 1);

      final pagesInNb1 = await repository.getPagesByNotebook(1, null);
      final pagesInNb2 = await repository.getPagesByNotebook(2, null);

      expect(pagesInNb1, isEmpty);
      expect(pagesInNb2.length, 1);
      expect(pagesInNb2.first.notebookId, 2);
    });
  });
}
