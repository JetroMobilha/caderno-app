import 'package:drift/drift.dart' hide Column;
import '../../../core/database/app_database.dart' hide User, Subject, Notebook, Page;
import '../models/notebook_model.dart';

class SharedNotebookRepository {
  final AppDatabase _db = AppDatabase.instance;

  Future<List<Notebook>> getSharedNotebooks(int currentUserId, {int? serverUserId}) async {
    final query = _db.select(_db.notebooks).join([
      innerJoin(_db.notebookUser, _db.notebookUser.notebookId.equalsExp(_db.notebooks.id)),
    ]);

    query.where(_db.notebookUser.userId.equals(currentUserId) |
        (_db.notebookUser.userId.equals(serverUserId ?? 0) & Constant(serverUserId != null && serverUserId != 0)));
    query.where(_db.notebooks.isDeleted.equals(0));
    
    // Simular o GROUP BY n.id para evitar duplicados se o usuário tiver múltiplas roles
    query.groupBy([_db.notebooks.id]);
    query.orderBy([OrderingTerm(expression: _db.notebooks.updatedAt, mode: OrderingMode.desc)]);

    final rows = await query.get();

    return rows.map((row) {
      final n = row.readTable(_db.notebooks);
      return Notebook(
        id: n.id,
        serverId: n.serverId,
        subjectId: n.subjectId,
        title: n.title,
        coverType: n.coverType,
        color: n.color,
        coverImage: n.coverImage,
        lineType: n.lineType ?? 'ruled',
        paperSize: n.paperSize ?? 'A4',
        isPublished: n.isPublished,
        price: n.price,
        description: n.description,
        authorName: n.authorName,
        isDeleted: n.isDeleted,
        syncedWithCloud: n.syncedWithCloud,
        updatedAt: n.updatedAt,
      );
    }).toList();
  }

  // =========================================================================
  // 📡 ASSINAR CADERNOS PARTILHADOS (REATIVO)
  // =========================================================================
  Stream<List<Notebook>> watchSharedNotebooks(int currentUserId, {int? serverUserId}) {
    final query = _db.select(_db.notebooks).join([
      innerJoin(_db.notebookUser, _db.notebookUser.notebookId.equalsExp(_db.notebooks.id)),
    ]);

    query.where(_db.notebookUser.userId.equals(currentUserId) |
        (_db.notebookUser.userId.equals(serverUserId ?? 0) & Constant(serverUserId != null && serverUserId != 0)));
    query.where(_db.notebooks.isDeleted.equals(0));
    
    query.groupBy([_db.notebooks.id]);
    query.orderBy([OrderingTerm(expression: _db.notebooks.updatedAt, mode: OrderingMode.desc)]);

    return query.watch().map((rows) => rows.map((row) {
          final n = row.readTable(_db.notebooks);
          return Notebook(
            id: n.id,
            serverId: n.serverId,
            subjectId: n.subjectId,
            title: n.title,
            coverType: n.coverType,
            color: n.color,
            coverImage: n.coverImage,
            lineType: n.lineType ?? 'ruled',
            paperSize: n.paperSize ?? 'A4',
            isPublished: n.isPublished,
            price: n.price,
            description: n.description,
            authorName: n.authorName,
            isDeleted: n.isDeleted,
            syncedWithCloud: n.syncedWithCloud,
            updatedAt: n.updatedAt,
          );
        }).toList());
  }
}
