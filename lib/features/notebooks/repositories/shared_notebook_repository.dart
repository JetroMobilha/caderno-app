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
    // 🚀 FILTRAR APENAS PARTILHADOS: Remover cadernos onde sou o dono
    query.where(_db.notebookUser.role.isNotValue('owner'));
    
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
        lineType: n.lineType ?? 'ruled',
        paperSize: n.paperSize ?? 'A4',
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
    // 🚀 FILTRAR APENAS PARTILHADOS: Remover cadernos onde sou o dono
    query.where(_db.notebookUser.role.isNotValue('owner'));
    
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
            lineType: n.lineType ?? 'ruled',
            paperSize: n.paperSize ?? 'A4',
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
          );
        }).toList());
  }
}

final sharedNotebookRepositoryProvider = Provider<SharedNotebookRepository>((ref) {
  return SharedNotebookRepository(AppDatabase.instance);
});
