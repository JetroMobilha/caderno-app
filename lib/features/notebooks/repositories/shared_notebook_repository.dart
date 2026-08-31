import 'package:drift/drift.dart' hide Column;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/database/app_database.dart' hide User, Subject, Notebook, Page;
import '../models/notebook_model.dart';

class SharedNotebookRepository {
  final AppDatabase _db;

  SharedNotebookRepository(this._db);

  Future<List<Notebook>> getSharedNotebooks(int currentUserId) async {
    final query = _db.select(_db.notebooks).join([
      innerJoin(_db.notebookUser, _db.notebookUser.notebookId.equalsExp(_db.notebooks.id)),
    ]);

    query.where(_db.notebookUser.userId.equals(currentUserId));
    query.where(_db.notebooks.isDeleted.equals(0));
    
    // Simular o GROUP BY n.id para evitar duplicados se o usuário tiver múltiplas roles
    query.groupBy([_db.notebooks.id]);
    query.orderBy([OrderingTerm(expression: _db.notebooks.updatedAt, mode: OrderingMode.desc)]);

    final rows = await query.get();

    return rows.map((row) {
      final n = row.readTable(_db.notebooks);
      final pivot = row.readTable(_db.notebookUser); // 🚀 Ler o papel real do pivô
      
      return Notebook(
        id: n.id,
        serverId: n.serverId,
        clientId: n.clientId,
        subjectId: n.subjectId,
        title: n.title,
        coverType: n.coverType,
        color: n.color,
        coverImage: n.coverImage,
        templateType: n.templateType,
        isPublished: n.isPublished,
        price: n.price,
        description: n.description,
        authorName: n.authorName,
        isDeleted: n.isDeleted,
        syncedWithCloud: n.syncedWithCloud,
        updatedAt: n.updatedAt,
        role: pivot.role, // 🚀 PRIORIDADE: O papel da partilha
        alternativeTitle: n.alternativeTitle,
        sharingType: n.sharingType ?? 'full',
        tags: Notebook.parseTags(n.tags),
        isArchived: n.isArchived == 1,
        isFavorite: n.isFavorite == 1,
      );
    }).toList();
  }

  // =========================================================================
  // 📡 ASSINAR CADERNOS PARTILHADOS (REATIVO)
  // =========================================================================
  Stream<List<Notebook>> watchSharedNotebooks(int currentUserId) {
    final query = _db.select(_db.notebooks).join([
      innerJoin(_db.notebookUser, _db.notebookUser.notebookId.equalsExp(_db.notebooks.id)),
    ]);

    query.where(_db.notebookUser.userId.equals(currentUserId));
    query.where(_db.notebooks.isDeleted.equals(0));
    
    query.groupBy([_db.notebooks.id]);
    query.orderBy([OrderingTerm(expression: _db.notebooks.updatedAt, mode: OrderingMode.desc)]);

    return query.watch().map((rows) => rows.map((row) {
          final n = row.readTable(_db.notebooks);
          final pivot = row.readTable(_db.notebookUser); // 🚀 Ler o papel real do pivô
          
          return Notebook(
            id: n.id,
            serverId: n.serverId,
            clientId: n.clientId,
            subjectId: n.subjectId,
            title: n.title,
            coverType: n.coverType,
            color: n.color,
            coverImage: n.coverImage,
            templateType: n.templateType,
            isPublished: n.isPublished,
            price: n.price,
            description: n.description,
            authorName: n.authorName,
            isDeleted: n.isDeleted,
            syncedWithCloud: n.syncedWithCloud,
            updatedAt: n.updatedAt,
            role: pivot.role, // 🚀 PRIORIDADE: O papel da partilha
            alternativeTitle: n.alternativeTitle,
            sharingType: n.sharingType ?? 'full',
            tags: Notebook.parseTags(n.tags),
            isArchived: n.isArchived == 1,
            isFavorite: n.isFavorite == 1,
          );
        }).toList());
  }
}

final sharedNotebookRepositoryProvider = Provider<SharedNotebookRepository>((ref) {
  return SharedNotebookRepository(AppDatabase.instance);
});
