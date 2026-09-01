import 'dart:convert';

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

    final List<Notebook> notebooks = [];
    for (final row in rows) {
      final n = row.readTable(_db.notebooks);
      final pivot = row.readTable(_db.notebookUser);
      
      final pCount = await _getPageCount(n.id);
      
      List<ParticipantPreview> parts = [];
      int totalParts = 0;
      int oCount = 0;
      if (n.participantsPreview != null) {
        try {
          final map = jsonDecode(n.participantsPreview!);
          totalParts = map['total'] ?? 0;
          oCount = map['online_count'] ?? 0;
          if (map['list'] is List) {
            parts = (map['list'] as List).map((e) => ParticipantPreview.fromJson(e)).toList();
          }
        } catch (_) {}
      }

      notebooks.add(Notebook(
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
        role: pivot.role,
        alternativeTitle: n.alternativeTitle,
        sharingType: n.sharingType ?? 'full',
        tags: Notebook.parseTags(n.tags),
        isArchived: n.isArchived == 1,
        isFavorite: n.isFavorite == 1,
        origin: n.origin,
        pageCount: pCount,
        participants: parts,
        participantsTotal: totalParts,
        onlineCount: oCount,
        lastUpdatedByName: n.lastUpdatedByName,
        notificationsEnabled: n.notificationsEnabled == 1,
      ));
    }
    return notebooks;
  }

  Future<int> _getPageCount(int notebookId) async {
    final countExp = _db.pages.id.count();
    final query = _db.selectOnly(_db.pages)
      ..addColumns([countExp])
      ..where(_db.pages.notebookId.equals(notebookId))
      ..where(_db.pages.isDeleted.equals(0));
    final result = await query.getSingle();
    return result.read(countExp) ?? 0;
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

    return query.watch().asyncMap((rows) async {
      final List<Notebook> notebooks = [];
      for (final row in rows) {
        final n = row.readTable(_db.notebooks);
        final pivot = row.readTable(_db.notebookUser);
        
        final pCount = await _getPageCount(n.id);

        List<ParticipantPreview> parts = [];
        int totalParts = 0;
        if (n.participantsPreview != null) {
          try {
            final map = jsonDecode(n.participantsPreview!);
            totalParts = map['total'] ?? 0;
            if (map['list'] is List) {
              parts = (map['list'] as List).map((e) => ParticipantPreview.fromJson(e)).toList();
            }
          } catch (_) {}
        }

        notebooks.add(Notebook(
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
          role: pivot.role,
          alternativeTitle: n.alternativeTitle,
          sharingType: n.sharingType ?? 'full',
          tags: Notebook.parseTags(n.tags),
          isArchived: n.isArchived == 1,
          isFavorite: n.isFavorite == 1,
          origin: n.origin,
          pageCount: pCount,
          participants: parts,
          participantsTotal: totalParts,
          lastUpdatedByName: n.lastUpdatedByName,
          notificationsEnabled: n.notificationsEnabled == 1,
        ));
      }
      return notebooks;
    });
  }
}

final sharedNotebookRepositoryProvider = Provider<SharedNotebookRepository>((ref) {
  return SharedNotebookRepository(AppDatabase.instance);
});
