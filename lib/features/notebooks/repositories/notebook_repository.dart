import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
    // 🚀 BLINDAGEM ANTI-FANTASMA: Descobre o ID local real da matéria!
    int realLocalSubjectId = subjectId;
    if (subjectServerId != null) {
      final subQuery = await (_db.select(_db.subjects)..where((t) => t.serverId.equals(subjectServerId))).getSingleOrNull();
      if (subQuery != null) {
        realLocalSubjectId = subQuery.id;
      }
    }

    // Agora procura com absoluta certeza na tabela de cadernos
    final rows = await (_db.select(_db.notebooks)
          ..where((t) => t.isDeleted.equals(0) & t.subjectId.equals(realLocalSubjectId))
          ..orderBy([(t) => OrderingTerm(expression: t.updatedAt, mode: OrderingMode.desc)]))
        .get();

    return rows.map((row) => Notebook(
      id: row.id,
      serverId: row.serverId,
      subjectId: row.subjectId,
      title: row.title,
      coverType: row.coverType,
      color: row.color,
      coverImage: row.coverImage,
      lineType: row.lineType ?? 'ruled',
      paperSize: row.paperSize ?? 'A4',
      isPublished: row.isPublished,
      price: row.price,
      description: row.description,
      authorName: row.authorName,
      isDeleted: row.isDeleted,
      syncedWithCloud: row.syncedWithCloud,
      updatedAt: row.updatedAt,
    )).toList();
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
              subjectId: row.subjectId,
              title: row.title,
              coverType: row.coverType,
              color: row.color,
              coverImage: row.coverImage,
              lineType: row.lineType ?? 'ruled',
              paperSize: row.paperSize ?? 'A4',
              isPublished: row.isPublished,
              price: row.price,
              description: row.description,
              authorName: row.authorName,
              isDeleted: row.isDeleted,
              syncedWithCloud: row.syncedWithCloud,
              updatedAt: row.updatedAt,
            )).toList());
  }

  // =========================================================================
  // 📓 CRIAR CADERNO (OFFLINE-FIRST)
  // =========================================================================
  Future<int> insertNotebook(Notebook notebook) async {
    final companion = NotebooksCompanion.insert(
      serverId: Value(notebook.serverId),
      subjectId: Value(notebook.subjectId),
      title: notebook.title,
      coverType: notebook.coverType,
      color: Value(notebook.color),
      coverImage: Value(notebook.coverImage),
      lineType: Value(notebook.lineType),
      paperSize: Value(notebook.paperSize),
      isPublished: Value(notebook.isPublished),
      price: Value(notebook.price),
      description: Value(notebook.description),
      authorName: Value(notebook.authorName),
      syncedWithCloud: const Value(0),
      isDeleted: const Value(0),
      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
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
        title: Value(notebook.title),
        coverType: Value(notebook.coverType),
        color: Value(notebook.color),
        coverImage: Value(notebook.coverImage),
        lineType: Value(notebook.lineType),
        paperSize: Value(notebook.paperSize),
        isPublished: Value(notebook.isPublished),
        price: Value(notebook.price),
        description: Value(notebook.description),
        authorName: Value(notebook.authorName),
        syncedWithCloud: const Value(0),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
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
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  // =========================================================================
  // 🤝 PARTILHAR CADERNO COM COLEGA (API)
  // =========================================================================
  Future<bool> shareNotebookWithFriend({required int notebookId, required String email, required String role}) async {
    try {
      final response = await _apiService.post('/notebooks/$notebookId/share', {'email': email, 'role': role});
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('🚨 Erro ao partilhar nas rotas da API: $e');
      return false;
    }
  }

  // A. Procurar e-mails para sugestões
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

  // B. Puxar colaboradores guardados na nuvem
  Future<List<Map<String, String>>> fetchCollaborators(int notebookId) async {
    try {
      final response = await _apiService.get('/notebooks/$notebookId/collaborators');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((c) => {
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

  // C. Deletar permissão na nuvem
  Future<bool> removeShareWithFriend({required int notebookId, required String email}) async {
    try {
      final response = await _apiService.deleteWithBody('/notebooks/$notebookId/share', {'email': email});
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('🚨 Erro ao revogar acesso: $e');
      return false;
    }
  }
}

final notebookRepositoryProvider = Provider<NotebookRepository>((ref) {
  return NotebookRepository(AppDatabase.instance);
});
