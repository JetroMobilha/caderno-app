import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import '../../../core/database/app_database.dart' hide User, Subject, Notebook, Page;
import '../../../core/network/api_service.dart';
import '../models/notebook_model.dart';

class NotebookRepository {
  final AppDatabase _db;
  final ApiService _apiService = ApiService();

  NotebookRepository(this._db);

  // =========================================================================
  // 📚 LISTAR CADERNOS ATIVOS DA DISCIPLINA (Com Blindagem de ID)
  // =========================================================================
  Future<List<Notebook>> getNotebooksBySubject(int subjectId, int? subjectServerId) async {
    int realLocalSubjectId = subjectId;
    if (subjectServerId != null) {
      final subQuery = await (_db.select(_db.subjects)..where((t) => t.serverId.equals(subjectServerId))).getSingleOrNull();
      if (subQuery != null) realLocalSubjectId = subQuery.id;
    }

    final rows = await (_db.select(_db.notebooks)
          ..where((t) => t.isDeleted.equals(0) & t.subjectId.equals(realLocalSubjectId))
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .get();

    return rows.map((row) => Notebook(
      id: row.id,
      serverId: row.serverId,
      clientId: row.clientId,
      subjectId: row.subjectId,
      title: row.title,
      coverType: row.coverType,
      color: row.color,
      coverImage: row.coverImage,
      templateType: row.templateType,
      isPublished: row.isPublished,
      price: row.price,
      description: row.description,
      authorName: row.authorName,
      isDeleted: row.isDeleted,
      syncedWithCloud: row.syncedWithCloud,
      updatedAt: row.updatedAt,
      role: row.role ?? 'owner',
      alternativeTitle: row.alternativeTitle,
      sharingType: row.sharingType ?? 'full',
      tags: _parseTags(row.tags),
      isArchived: row.isArchived == 1,
      isFavorite: row.isFavorite == 1,
    )).toList();
  }

  static List<String> _parseTags(String? tagsStr) {
    if (tagsStr == null || tagsStr.isEmpty) return [];
    return tagsStr.split(',').where((t) => t.isNotEmpty).toList();
  }

  // =========================================================================
  // 📡 ASSINAR CADERNOS DA DISCIPLINA (REATIVO)
  // =========================================================================
  Stream<List<Notebook>> watchNotebooksBySubject(int subjectId) {
    return (_db.select(_db.notebooks)
          ..where((t) => t.isDeleted.equals(0) & t.subjectId.equals(subjectId))
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .watch()
        .map((rows) => rows.map((row) => Notebook(
              id: row.id,
              serverId: row.serverId,
              clientId: row.clientId,
              subjectId: row.subjectId,
              title: row.title,
              coverType: row.coverType,
              color: row.color,
              coverImage: row.coverImage,
              templateType: row.templateType,
              isPublished: row.isPublished,
              price: row.price,
              description: row.description,
              authorName: row.authorName,
              isDeleted: row.isDeleted,
              syncedWithCloud: row.syncedWithCloud,
              updatedAt: row.updatedAt,
              role: row.role ?? 'owner',
              alternativeTitle: row.alternativeTitle,
              sharingType: row.sharingType ?? 'full',
              tags: _parseTags(row.tags),
              isArchived: row.isArchived == 1,
              isFavorite: row.isFavorite == 1,
            )).toList());
  }

  // =========================================================================
  // 📓 CRIAR CADERNO (OFFLINE-FIRST)
  // =========================================================================
  Future<int> insertNotebook(Notebook notebook) async {
    final companion = NotebooksCompanion.insert(
      serverId: Value(notebook.serverId),
      clientId: Value(notebook.clientId),
      subjectId: Value(notebook.subjectId),
      title: notebook.title,
      coverType: notebook.coverType,
      color: Value(notebook.color),
      coverImage: Value(notebook.coverImage),
      templateType: Value(notebook.templateType),
      isPublished: Value(notebook.isPublished),
      price: Value(notebook.price),
      description: Value(notebook.description),
      authorName: Value(notebook.authorName),
      syncedWithCloud: const Value(0),
      isDeleted: const Value(0),
      updatedAt: Value(TimeService().nowMs()),
    );
    return await _db.into(_db.notebooks).insert(companion);
  }

  // =========================================================================
  // ✏️ ATUALIZAR CADERNO (OFFLINE-FIRST)
  // =========================================================================
  Future<void> updateNotebook(Notebook notebook) async {
    if (notebook.id == null) return;
    await (_db.update(_db.notebooks)..where((t) => t.id.equals(notebook.id!))).write(
      NotebooksCompanion(
        subjectId: Value(notebook.subjectId),
        title: Value(notebook.title),
        coverType: Value(notebook.coverType),
        color: Value(notebook.color),
        coverImage: Value(notebook.coverImage),
        templateType: Value(notebook.templateType),
        isPublished: Value(notebook.isPublished),
        price: Value(notebook.price),
        description: Value(notebook.description),
        authorName: Value(notebook.authorName),
        syncedWithCloud: const Value(0),
        updatedAt: Value(TimeService().nowMs()),
      ),
    );
  }

  // =========================================================================
  // 🗑️ APAGAR CADERNO (SOFT DELETE OFFLINE-FIRST)
  // =========================================================================
  Future<void> deleteNotebook(Notebook notebook) async {
    if (notebook.id == null) return;
    await (_db.update(_db.notebooks)..where((t) => t.id.equals(notebook.id!))).write(
      NotebooksCompanion(
        isDeleted: const Value(1),
        syncedWithCloud: const Value(0),
        updatedAt: Value(TimeService().nowMs()),
      ),
    );
  }

  // =========================================================================
  // ♻️ LIXEIRA & RESTAURO
  // =========================================================================
  Future<List<Notebook>> getDeletedNotebooks() async {
    final rows = await (_db.select(_db.notebooks)
          ..where((t) => t.isDeleted.equals(1))
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .get();

    return rows.map((row) => Notebook(
      id: row.id,
      serverId: row.serverId,
      clientId: row.clientId,
      subjectId: row.subjectId,
      title: row.title,
      coverType: row.coverType,
      color: row.color,
      coverImage: row.coverImage,
      templateType: row.templateType,
      isPublished: row.isPublished,
      price: row.price,
      description: row.description,
      authorName: row.authorName,
      isDeleted: row.isDeleted,
      syncedWithCloud: row.syncedWithCloud,
      updatedAt: row.updatedAt,
      role: row.role ?? 'owner',
      alternativeTitle: row.alternativeTitle,
      sharingType: row.sharingType ?? 'full',
      tags: _parseTags(row.tags),
      isArchived: row.isArchived == 1,
      isFavorite: row.isFavorite == 1,
    )).toList();
  }

  Future<void> restoreNotebook(int id) async {
    await (_db.update(_db.notebooks)..where((t) => t.id.equals(id))).write(
      NotebooksCompanion(
        isDeleted: const Value(0),
        syncedWithCloud: const Value(0),
        updatedAt: Value(TimeService().nowMs()),
      ),
    );
  }

  Future<void> hardDeleteNotebook(int id) async {
    await (_db.delete(_db.notebooks)..where((t) => t.id.equals(id))).go();
  }

  // =========================================================================
  // 🤝 PARTILHAR CADERNO COM COLEGA (API)
  // =========================================================================
  Future<bool> shareNotebookWithFriend({
    required int notebookId, 
    required String email, 
    required String role,
    String? alternativeTitle,
    String? sharingType,
    List<int>? pageIds,
  }) async {
    try {
      final response = await _apiService.post('/notebooks/$notebookId/share', {
        'email': email, 
        'role': role,
        if (alternativeTitle != null) 'alternative_title': alternativeTitle,
        if (sharingType != null) 'sharing_type': sharingType,
        if (pageIds != null) 'page_ids': pageIds,
      });
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('🚨 Erro ao partilhar nas rotas da API: $e');
      return false;
    }
  }

  Future<List<String>> searchEmails(String query) async {
    try {
      final response = await _apiService.get('/users/search?q=$query');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((user) => user['email'] as String).toList();
      }
    } catch (e) {
      debugPrint('🚨 Erro Autocomplete: $e');
    }
    return [];
  }

  Future<List<Map<String, String>>> fetchCollaborators(int notebookId) async {
    try {
      final response = await _apiService.get('/notebooks/$notebookId/collaborators');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((c) => {
          'id': c['id'].toString(),
          'name': c['name'] as String,
          'email': c['email'] as String,
          'role': c['role'] as String,
        }).toList();
      }
    } catch (e) {
      debugPrint('🚨 Erro ao buscar colaboradores: $e');
    }
    return [];
  }

  Future<bool> removeShareWithFriend({required int notebookId, required String email}) async {
    try {
      final response = await _apiService.deleteWithBody('/notebooks/$notebookId/share', {
        'email': email,
      });
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🚨 Erro ao remover partilha: $e');
      return false;
    }
  }

  Future<bool> leaveSharedNotebook(int notebookId, String myEmail) async {
    return await removeShareWithFriend(notebookId: notebookId, email: myEmail);
  }

  Future<Map<String, dynamic>?> fetchSessionStatus(int notebookId) async {
    try {
      final response = await _apiService.get('/notebooks/$notebookId/session/status');
      if (response.statusCode == 200) return jsonDecode(response.body);
    } catch (e) {
      debugPrint('🚨 Erro ao buscar status da sessão: $e');
    }
    return null;
  }

  Future<bool> updateSessionSettings({
    required int notebookId,
    required String sharingType,
    String? alternativeTitle,
    List<int>? pageIds,
  }) async {
    try {
      final payload = {
        'sharing_type': sharingType,
        if (alternativeTitle != null) 'alternative_title': alternativeTitle,
        if (pageIds != null) 'page_ids': pageIds,
      };
      final response = await _apiService.post('/notebooks/$notebookId/session/update-settings', payload);
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🚨 Erro ao guardar configurações: $e');
      return false;
    }
  }

  Future<List<Notebook>> getAllNotebooks() async {
    final rows = await (_db.select(_db.notebooks)
          ..where((t) => t.isDeleted.equals(0))
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .get();

    return rows.map((row) => Notebook(
      id: row.id,
      serverId: row.serverId,
      clientId: row.clientId,
      subjectId: row.subjectId,
      title: row.title,
      coverType: row.coverType,
      color: row.color,
      coverImage: row.coverImage,
      templateType: row.templateType,
      isPublished: row.isPublished,
      price: row.price,
      description: row.description,
      authorName: row.authorName,
      isDeleted: row.isDeleted,
      syncedWithCloud: row.syncedWithCloud,
      updatedAt: row.updatedAt,
      role: row.role ?? 'owner',
      alternativeTitle: row.alternativeTitle,
      sharingType: row.sharingType ?? 'full',
      tags: _parseTags(row.tags),
      isArchived: row.isArchived == 1,
      isFavorite: row.isFavorite == 1,
    )).toList();
  }
}

final notebookRepositoryProvider = Provider<NotebookRepository>((ref) {
  return NotebookRepository(AppDatabase.instance);
});
