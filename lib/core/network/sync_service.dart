import 'dart:convert';
import 'dart:io' as io;
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../features/subjects/models/subject_model.dart' as subjects_model;
import '../../features/notebooks/models/notebook_model.dart' as notebooks_model;
import '../../features/canvas/models/local_page_model.dart' as pages_model;
import '../../features/canvas/repositories/canvas_repository.dart';
import '../database/app_database.dart';
import 'package:caderno_digital_app/core/network/time_service.dart'; // 🚀
import 'api_service.dart';

class SyncService {
  final AppDatabase _db = AppDatabase.instance;
  final ApiService _apiService;
  final CanvasRepository _canvasRepository;

  SyncService(this._apiService, this._canvasRepository);

  static bool isCollaborationActive = false;
  static int? activeNotebookId;

  String uniqid() => DateTime.now().microsecondsSinceEpoch.toString();

  // =========================================================================
  // 1. SINCRONIZAÇÃO TOTAL
  // =========================================================================
  Future<void> syncAll({bool forced = false, bool metadataOnly = false}) async {
    if (isCollaborationActive && !forced) return;
    debugPrint('🔄 [Sync] Sincronização total iniciada... (MetadataOnly: $metadataOnly)');

    try {
      await pushOfflineSubjects();
      await pullSubjects();
      await pushNotebooks();
      await pullNotebooks();

      if (!metadataOnly) {
        await pushPages();
        await pullPages();
        await pushRecordings();
        await pullRecordings();
      }
      debugPrint('✅ [Sync] Ciclo concluído.');
    } catch (e) {
      debugPrint('🚨 [Sync General] Falha no ciclo de sincronização: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 2. DISCIPLINAS (SUBJECTS)
  // =========================================================================
  Future<void> pushOfflineSubjects() async {
    try {
      final unsynced = await (_db.select(_db.subjects)..where((t) => t.syncedWithCloud.equals(0))).get();
      if (unsynced.isEmpty) return;
      final List<Map<String, dynamic>> payload = [];
      for (var s in unsynced) {
        String effectiveUuid = s.clientId ?? uniqid();
        if (s.clientId == null) {
          await (_db.update(_db.subjects)..where((t) => t.id.equals(s.id))).write(SubjectsCompanion(clientId: Value(effectiveUuid)));
        }
        final subjectObj = subjects_model.Subject(
          id: s.id, serverId: s.serverId, clientId: effectiveUuid, userId: s.userId,
          name: s.name, color: s.color, icon: s.icon, isDeleted: s.isDeleted,
          syncedWithCloud: s.syncedWithCloud, updatedAt: s.updatedAt,
        );
        payload.add(subjectObj.toJson());
      }
      final response = await _apiService.post('/sync/push', {'subjects': payload});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        for (var item in data['synced_subjects'] ?? []) {
          final String clientUuid = item['client_id'].toString();
          final int serverId = item['server_id'];
          await (_db.update(_db.subjects)..where((t) => t.clientId.equals(clientUuid))).write(SubjectsCompanion(serverId: Value(serverId), syncedWithCloud: const Value(1)));
        }
      } else {
        throw Exception('Erro ${response.statusCode} no PUSH Subjects');
      }
    } catch (e) {
      debugPrint('🚨 Erro PUSH Subjects: $e');
      rethrow;
    }
  }

  Future<bool> pullSubjects() async {
    final prefs = await SharedPreferences.getInstance();
    final localCount = await _db.subjects.count().getSingle();
    final String? lastSynced = localCount > 0 ? prefs.getString('last_subjects_sync') : null;
    try {
      String? nextUrl = lastSynced != null ? '/sync/pull?last_synced_at=$lastSynced' : '/sync/pull';
      bool anyChanges = false;
      while (nextUrl != null) {
        final response = await _apiService.get(nextUrl);
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = await compute<String, Map<String, dynamic>>((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>, response.body);
          final List serverSubjects = responseData['data'] ?? responseData['subjects'] ?? [];
          final Map<String, dynamic> meta = responseData['meta'] ?? {};
          if (meta['server_time'] != null) {
            await prefs.setString('last_subjects_sync', meta['server_time']);
          }
          if (serverSubjects.isNotEmpty) {
            anyChanges = true;
            final userQuery = await (_db.select(_db.users)..orderBy([(t) => OrderingTerm(expression: t.id)])..limit(1)).get();
            if (userQuery.isEmpty) return false;
            final int localUserId = userQuery.first.id;
            await _db.transaction(() async {
              for (var sub in serverSubjects) {
                final int sId = sub['id'] is int ? sub['id'] : int.parse(sub['id'].toString());
                final String? cId = sub['client_id']?.toString();
                final int serverTime = sub['updated_at_ms'] != null ? (sub['updated_at_ms'] as num).toInt() : (sub['updated_at'] != null ? DateTime.parse(sub['updated_at'].toString()).millisecondsSinceEpoch : 0);
                final companion = SubjectsCompanion.insert(serverId: Value(sId), clientId: Value(cId ?? uniqid()), userId: localUserId, name: sub['name'] ?? '', color: sub['color'] ?? '#0F4C5C', icon: Value(sub['icon']), isDeleted: Value(sub['deleted_at'] != null ? 1 : 0), syncedWithCloud: const Value(1), updatedAt: Value(serverTime));
                final existing = await (_db.select(_db.subjects)..where((t) => t.clientId.equals(cId ?? ''))).getSingleOrNull();
                if (existing != null) {
                  if (serverTime > existing.updatedAt) {
                    await (_db.update(_db.subjects)..where((t) => t.id.equals(existing.id))).write(SubjectsCompanion(serverId: companion.serverId, name: companion.name, color: companion.color, icon: companion.icon, isDeleted: companion.isDeleted, syncedWithCloud: companion.syncedWithCloud, updatedAt: companion.updatedAt));
                  }
                } else {
                  final existingByServerId = await (_db.select(_db.subjects)..where((t) => t.serverId.equals(sId))).getSingleOrNull();
                  if (existingByServerId != null) {
                    if (serverTime > existingByServerId.updatedAt) await (_db.update(_db.subjects)..where((t) => t.id.equals(existingByServerId.id))).write(companion);
                  } else {
                    await _db.into(_db.subjects).insert(companion);
                  }
                }
              }
            });
          }
          nextUrl = _extractNextUrl(responseData);
        } else {
          throw Exception('Erro ${response.statusCode} no PULL Subjects');
        }
      }
      return anyChanges;
    } catch (e) {
      debugPrint('🚨 Erro PULL Subjects: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 3. CADERNOS (NOTEBOOKS)
  // =========================================================================
  Future<void> pushNotebooks() async {
    try {
      final unsynced = await (_db.select(_db.notebooks)..where((t) => t.syncedWithCloud.equals(0))).get();
      if (unsynced.isEmpty) return;
      final List<Map<String, dynamic>> payload = [];
      for (var row in unsynced) {
        String effectiveUuid = row.clientId ?? uniqid();
        if (row.clientId == null) await (_db.update(_db.notebooks)..where((t) => t.id.equals(row.id))).write(NotebooksCompanion(clientId: Value(effectiveUuid)));
        int? cloudSubId;
        if (row.subjectId != null) {
          final sub = await (_db.select(_db.subjects)..where((t) => t.id.equals(row.subjectId!))).getSingleOrNull();
          if (sub != null && sub.serverId != null) cloudSubId = sub.serverId;
        }
        final notebookObj = notebooks_model.Notebook(
          id: row.id, serverId: row.serverId, clientId: effectiveUuid, subjectId: cloudSubId, title: row.title, coverType: row.coverType, color: row.color, coverImage: row.coverImage, lineType: row.lineType ?? 'ruled', paperSize: row.paperSize ?? 'A4', lineSpacing: row.lineSpacing, templateType: row.templateType, collaborationMode: row.collaborationMode, isPublished: row.isPublished, price: row.price, description: row.description, authorName: row.authorName, syncedWithCloud: row.syncedWithCloud, isDeleted: row.isDeleted, updatedAt: row.updatedAt,
        );
        payload.add(notebookObj.toJson());
      }
      if (payload.isEmpty) return;
      final response = await _apiService.post('/sync/notebooks/push', {'notebooks': payload});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        for (var item in data['synced_notebooks'] ?? []) {
          final String clientUuid = item['client_id'].toString();
          final int sId = item['server_id'];
          final localRow = await (_db.select(_db.notebooks)..where((t) => t.clientId.equals(clientUuid))).getSingleOrNull();
          if (localRow == null) continue;
          final existing = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(sId) & t.id.equals(localRow.id).not())).getSingleOrNull();
          if (existing != null) {
            await (_db.delete(_db.notebooks)..where((t) => t.id.equals(localRow.id))).go();
          } else {
            await (_db.update(_db.notebooks)..where((t) => t.id.equals(localRow.id))).write(NotebooksCompanion(serverId: Value(sId), syncedWithCloud: const Value(1)));
          }
        }
      }
    } catch (e) {
      debugPrint('🚨 Erro PUSH Notebooks: $e');
      rethrow;
    }
  }

  Future<bool> pullNotebooks() async {
    final prefs = await SharedPreferences.getInstance();
    final localCount = await _db.notebooks.count().getSingle();
    final String? lastSynced = localCount > 0 ? prefs.getString('last_notebooks_sync') : null;
    try {
      String? nextUrl = lastSynced != null ? '/sync/notebooks/pull?last_synced_at=$lastSynced' : '/sync/notebooks/pull';
      bool anyChanges = false;
      final Set<int> receivedServerIds = {};
      while (nextUrl != null) {
        final response = await _apiService.get(nextUrl);
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = await compute<String, Map<String, dynamic>>((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>, response.body);
          final List serverNotebooks = responseData['data'] ?? responseData['notebooks'] ?? [];
          final Map<String, dynamic> meta = responseData['meta'] ?? {};
          if (meta['server_time'] != null) await prefs.setString('last_notebooks_sync', meta['server_time']);
          if (serverNotebooks.isNotEmpty) {
            anyChanges = true;
            final userQuery = await (_db.select(_db.users)..orderBy([(t) => OrderingTerm(expression: t.id)])..limit(1)).get();
            final int currentUserId = userQuery.isNotEmpty ? userQuery.first.id : 0;
            final allSubjects = await _db.select(_db.subjects).get();
            final Map<int, int> subjectIdMap = {for (var s in allSubjects) if (s.serverId != null) s.serverId!: s.id};
            await _db.transaction(() async {
              for (var net in serverNotebooks) {
                final int sId = net['id'] is int ? net['id'] : int.parse(net['id'].toString());
                receivedServerIds.add(sId);
                final String? cId = net['client_id']?.toString();
                final int? serverSubId = net['subject_id'] != null ? (net['subject_id'] is int ? net['subject_id'] : int.parse(net['subject_id'].toString())) : null;
                final int? localSubId = (serverSubId != null) ? subjectIdMap[serverSubId] : null;
                final int serverTime = net['updated_at_ms'] != null ? (net['updated_at_ms'] as num).toInt() : (net['updated_at'] != null ? DateTime.parse(net['updated_at'].toString()).millisecondsSinceEpoch : 0);
                final String serverRole = net['role']?.toString() ?? 'viewer';
                
                final companion = NotebooksCompanion.insert(
                  serverId: Value(sId), clientId: Value(cId ?? uniqid()), subjectId: Value(localSubId), title: net['title'] ?? '',
                  coverType: net['cover_type'] ?? 'color', 
                  color: net['color'] != null ? Value(net['color']) : const Value.absent(), // 🚀 Proteger cor
                  coverImage: Value(net['cover_image']),
                  lineType: Value(net['line_type'] ?? 'ruled'), lineSpacing: Value(net['line_spacing'] != null ? double.tryParse(net['line_spacing'].toString()) : null),
                  paperSize: Value(net['paper_size'] ?? 'A4'), templateType: Value(net['template_type'] ?? 'study'), collaborationMode: Value(net['collaboration_mode'] ?? 'study_group'),
                  isPublished: Value(int.tryParse(net['is_published']?.toString() ?? '0') ?? 0), price: Value(double.tryParse(net['price']?.toString() ?? '0.0') ?? 0.0),
                  description: Value(net['description']), authorName: Value(net['author_name']), isDeleted: Value(net['deleted_at'] != null ? 1 : 0),
                  syncedWithCloud: const Value(1), updatedAt: Value(serverTime), role: Value(serverRole),
                  alternativeTitle: Value(net['alternative_title']), sharingType: Value(net['sharing_type'] ?? 'full'),
                );

                final existing = await (_db.select(_db.notebooks)..where((t) => t.clientId.equals(cId ?? ''))).getSingleOrNull();
                if (existing != null) {
                  final bool isBeingDeleted = net['deleted_at'] != null;
                  if (isBeingDeleted) {
                    final unsynced = await (_db.select(_db.pages)..where((t) => t.notebookId.equals(existing.id) & t.syncedWithCloud.equals(0))).get();
                    if (unsynced.isEmpty) {
                      await (_db.delete(_db.notebooks)..where((t) => t.id.equals(existing.id))).go();
                      continue;
                    } else {
                      await (_db.update(_db.notebooks)..where((t) => t.id.equals(existing.id))).write(NotebooksCompanion(serverId: const Value(null), clientId: Value(const Uuid().v4()), syncedWithCloud: const Value(0)));
                      continue;
                    }
                  }

                  if (serverTime >= existing.updatedAt) {
                    await (_db.update(_db.notebooks)..where((t) => t.id.equals(existing.id))).write(
                      NotebooksCompanion(
                        serverId: companion.serverId, subjectId: companion.subjectId, title: companion.title, coverType: companion.coverType, 
                        color: net['color'] != null ? Value(net['color']) : const Value.absent(), // 🚀 Proteger cor
                        coverImage: companion.coverImage, lineType: companion.lineType, lineSpacing: companion.lineSpacing, paperSize: companion.paperSize, templateType: companion.templateType, collaborationMode: companion.collaborationMode, isPublished: companion.isPublished, price: companion.price, description: companion.description, authorName: companion.authorName, isDeleted: companion.isDeleted, syncedWithCloud: companion.syncedWithCloud, updatedAt: companion.updatedAt, role: companion.role, alternativeTitle: companion.alternativeTitle, sharingType: companion.sharingType,
                      )
                    );
                  }
                } else {
                  final existingByServerId = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(sId))).getSingleOrNull();
                  if (existingByServerId != null) {
                    if (serverTime >= existingByServerId.updatedAt) await (_db.update(_db.notebooks)..where((t) => t.id.equals(existingByServerId.id))).write(companion);
                  } else {
                    await _db.into(_db.notebooks).insert(companion);
                  }
                }
              }
            });
            // 🚀 SINCRONIZAÇÃO DE PERMISSÕES (notebook_user)
            final allNotebooksAfter = await _db.select(_db.notebooks).get();
            final Map<int, int> notebookIdMap = {for (var n in allNotebooksAfter) if (n.serverId != null) n.serverId!: n.id};
            await _db.batch((batch) {
              for (var net in serverNotebooks) {
                final sId = net['id'];
                final localNbId = notebookIdMap[sId];
                final String? role = net['role']?.toString();
                if (localNbId != null && currentUserId > 0 && role != null && role != 'owner') {
                  // Registramos no pivô APENAS se for partilhado (não sou o dono)
                  batch.insert(_db.notebookUser, 
                    NotebookUserCompanion.insert(
                      notebookId: localNbId, 
                      userId: currentUserId, 
                      role: Value(role), 
                      syncedWithCloud: const Value(1), 
                      updatedAt: Value(DateTime.now().millisecondsSinceEpoch)
                    ), 
                    mode: InsertMode.insertOrReplace
                  );
                } else if (localNbId != null && currentUserId > 0 && role == 'owner') {
                  // 🚀 LIMPEZA: Se antes era partilhado e agora sou dono (ou erro de sync), remover do pivô
                  batch.deleteWhere(_db.notebookUser, (t) => t.notebookId.equals(localNbId) & t.userId.equals(currentUserId));
                }
              }
            });
          }
          nextUrl = _extractNextUrl(responseData);
        } else {
          throw Exception('Erro ${response.statusCode} no PULL Notebooks');
        }
      }
      
      // 🛡️ LIMPEZA SEGURA DE ACESSOS REVOGADOS
      if (lastSynced == null) {
         final allLocalShared = await (_db.select(_db.notebooks)..where((t) => t.role.isNotValue('owner') & t.serverId.isNotNull())).get();
         for (var localNb in allLocalShared) {
           if (localNb.serverId != null && !receivedServerIds.contains(localNb.serverId!)) {
              debugPrint('🧨 [Sync] Acesso revogado ao caderno ${localNb.serverId}. Removendo localmente.');
              await (_db.delete(_db.notebooks)..where((t) => t.id.equals(localNb.id))).go();
           }
         }
      }
      return anyChanges;
    } catch (e) {
      debugPrint('🚨 Erro PULL Notebooks: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 4. PÁGINAS E CANVAS
  // =========================================================================
  Future<bool> pushPages({int? onlyNotebookId}) async {
    try {
      final query = _db.select(_db.pages)..where((t) => t.syncedWithCloud.equals(0));
      if (onlyNotebookId != null) query.where((t) => t.notebookId.equals(onlyNotebookId));
      final unsyncedPages = await query.get();
      if (unsyncedPages.isEmpty) return true;
      unsyncedPages.sort((a, b) => b.isDeleted.compareTo(a.isDeleted));
      bool allSuccess = true;
      for (var row in unsyncedPages) {
        try {
          final notebook = await (_db.select(_db.notebooks)..where((t) => t.id.equals(row.notebookId))).getSingleOrNull();
          if (notebook == null || notebook.serverId == null) continue;
          Map<String, dynamic> pageMap;
          pages_model.LocalPage? fullPage;
          if (row.isDeleted == 1) {
            pageMap = {'notebook_id': notebook.serverId, 'page_number': row.pageNumber, 'client_id': row.clientId, 'server_id': row.serverId, 'is_deleted': 1};
          } else {
            final allPages = await _canvasRepository.getPagesByNotebook(row.notebookId, null);
            fullPage = allPages.firstWhere((p) => p.clientId == row.clientId, orElse: () => pages_model.LocalPage(notebookId: row.notebookId, pageNumber: row.pageNumber, isLandscape: row.isLandscape == 1, clientId: row.clientId, lineType: row.lineType, lineSpacing: row.lineSpacing));
            int totalPts = fullPage.strokes.fold(0, (sum, s) => sum + s.points.length);
            if (totalPts > 1000) fullPage.strokes = fullPage.strokes.map((s) => s.simplify(epsilon: 0.5)).toList();
            else fullPage.strokes = fullPage.strokes.map((s) => s.simplify(epsilon: 0.2)).toList();
            pageMap = await fullPage.toJsonAsync();
            pageMap['notebook_id'] = notebook.serverId;
            pageMap['is_deleted'] = 0;

            debugPrint('🛫 [Sync-Push] Enviando página ${row.pageNumber}: ${fullPage.strokes.length} traços, ${fullPage.textBlocks.length} textos, ${fullPage.imageBlocks.length} imagens.');
          }
          var response = await _apiService.post('/sync/pages/push', {'pages': [pageMap]});
          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = jsonDecode(response.body);
            final syncedItem = (data['synced_pages'] as List?)?.first;
            if (syncedItem != null) {
              final String? status = syncedItem['status']?.toString();
              if (status == 'ignored_old') {
                await pullSpecificPage(notebook.serverId!, row.pageNumber, clientId: row.clientId);
                continue;
              }
              final int? sId = syncedItem['server_id'] ?? syncedItem['serverId'];
              if (sId != null) await (_db.update(_db.pages)..where((t) => t.clientId.equals(row.clientId ?? ''))).write(PagesCompanion(serverId: Value(sId), pageNumber: Value(syncedItem['page_number']), syncedWithCloud: const Value(1), updatedAt: Value(fullPage?.updatedAt ?? row.updatedAt)));
            }
          } else { allSuccess = false; }
        } catch (e) { allSuccess = false; }
      }
      return allSuccess;
    } catch (e) { return false; }
  }

  Future<bool> pullPages({bool forceFull = false, int? onlyNotebookId}) async {
    final prefs = await SharedPreferences.getInstance();
    final localCount = await _db.pages.count().getSingle();
    final String? lastSynced = (localCount > 0 && !forceFull) ? prefs.getString('last_pages_sync') : null;
    try {
      String? baseUrl = '/sync/pages/pull';
      if (lastSynced != null) baseUrl += '?last_synced_at=$lastSynced';
      if (onlyNotebookId != null) baseUrl += (lastSynced != null ? '&' : '?') + 'notebook_id=$onlyNotebookId';
      String? nextUrl = baseUrl;
      bool anyChanges = false;
      final Set<String> serverClientIds = {};
      while (nextUrl != null) {
        final response = await _apiService.get(nextUrl);
        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = await compute<String, Map<String, dynamic>>((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>, response.body);
          final List serverPages = responseData['data'] ?? responseData['pages'] ?? [];
          final Map<String, dynamic> meta = responseData['meta'] ?? {};
          if (meta['server_time'] != null) await prefs.setString('last_pages_sync', meta['server_time']);
          if (serverPages.isNotEmpty) {
            anyChanges = true;
            for (var sPage in serverPages) {
              final int sNbId = sPage['notebook_id'] is int ? sPage['notebook_id'] : int.parse(sPage['notebook_id'].toString());
              final int sId = sPage['id'] is int ? sPage['id'] : int.parse(sPage['id'].toString());
              final String? cId = sPage['client_id']?.toString();
              if (cId != null) serverClientIds.add(cId);
              if (sPage['deleted_at'] != null || sPage['is_deleted'] == 1) {
                if (cId != null) await (_db.delete(_db.pages)..where((t) => t.clientId.equals(cId))).go();
                else await (_db.delete(_db.pages)..where((t) => t.serverId.equals(sId))).go();
                continue;
              }
              final notebook = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(sNbId))).getSingleOrNull();
              if (notebook == null) continue;
              
              // 🚀 LÓGICA LWW (Last-Write-Wins) PARA A PÁGINA
              final existingPage = await (_db.select(_db.pages)..where((t) => t.clientId.equals(cId ?? ''))).getSingleOrNull();
              final int serverTs = sPage['updated_at_ms'] ?? 0;

              if (existingPage != null) {
                // Se a página local é 'dirty' e mais recente que o servidor, não sobrescrever metadados
                if (existingPage.syncedWithCloud == 0 && existingPage.updatedAt > serverTs) {
                  debugPrint('⚠️ [Sync] PULL ignorado para folha ${existingPage.pageNumber} (Local Dirty & Newer).');
                  // Mesmo ignorando o pull da linha da página, tentamos fundir o conteúdo (strokes etc)
                  await _pullCanvasData(existingPage.id, sPage, serverTs: serverTs);
                  continue;
                }
              }

              // 🚀 REMAPEAMENTO DE ID: Garantir que a página aponta para o ID local do SQLite
              final newPageData = pages_model.LocalPage.fromJson(sPage).copyWith(notebookId: notebook.id);
              
              // 🚀 SALVAR PÁGINA PRIMEIRO (FK PARENT)
              final localPageId = await _canvasRepository.savePage(newPageData, sNbId);
              
              // 🚀 SÓ DEPOIS PUXAR OS DADOS DO CANVAS (CHILDREN)
              await _pullCanvasData(localPageId, sPage, serverTs: newPageData.updatedAt);
            }
          }
          nextUrl = _extractNextUrl(responseData);
        } else { throw Exception('Erro ${response.statusCode} no PULL Pages'); }
      }
      if (forceFull) {
        final query = _db.select(_db.pages)..where((t) => t.syncedWithCloud.equals(1));
        if (onlyNotebookId != null) {
          final nb = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(onlyNotebookId))).getSingleOrNull();
          if (nb != null) query.where((t) => t.notebookId.equals(nb.id));
        }
        final localSyncedPages = await query.get();
        for (var lp in localSyncedPages) { if (!serverClientIds.contains(lp.clientId)) await (_db.delete(_db.pages)..where((t) => t.id.equals(lp.id))).go(); }
      }
      return anyChanges;
    } catch (e) { return false; }
  }

  Future<void> pullSpecificPage(int notebookServerId, int pageNumber, {String? clientId, bool isRetry = false}) async {
    try {
      String url = '/sync/pages/pull?notebook_id=$notebookServerId';
      if (clientId != null) url += '&client_id=$clientId'; else url += '&page_number=$pageNumber';
      final response = await _apiService.get(url);
      
      // 🚀 TRATAMENTO DE THROTTLING (429)
      if (response.statusCode == 429) {
        debugPrint('⚠️ [Sync] Bloqueio por excesso de pedidos (429). Aguardando...');
        if (!isRetry) {
          await Future.delayed(const Duration(seconds: 5));
          return pullSpecificPage(notebookServerId, pageNumber, clientId: clientId, isRetry: true);
        }
        return;
      }

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List serverPages = responseData['data'] ?? responseData['pages'] ?? [];
        if (serverPages.isNotEmpty) {
          final sPage = serverPages.first;
          final int inNbId = int.tryParse(sPage['notebook_id']?.toString() ?? '') ?? 0;
          if (inNbId != notebookServerId) return;
          final notebook = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(notebookServerId))).getSingleOrNull();
          if (notebook == null) return;
          
          // 🚀 REMAPEAMENTO DE ID: Garantir que a página aponta para o ID local do SQLite
          final newPageData = pages_model.LocalPage.fromJson(sPage).copyWith(notebookId: notebook.id);
          
          final localId = await _canvasRepository.savePage(newPageData, notebookServerId);
          await _pullCanvasData(localId, sPage, serverTs: (newPageData.updatedAt));
        }
      } else if (!isRetry) {
        await Future.delayed(const Duration(seconds: 2));
        return pullSpecificPage(notebookServerId, pageNumber, isRetry: true);
      }
    } catch (e) {
      debugPrint('🚨 [Sync] Erro no pullSpecificPage: $e');
    }
  }

  Future<void> _pullCanvasData(int localPageId, Map sPage, {int? serverTs}) async {
    final localStrokes = await (_db.select(_db.canvasStrokes)..where((t) => t.pageId.equals(localPageId))).get();
    final localTexts = await (_db.select(_db.canvasTextBlocks)..where((t) => t.pageId.equals(localPageId))).get();
    final localImages = await (_db.select(_db.canvasImageBlocks)..where((t) => t.pageId.equals(localPageId))).get();
    final Map<String, CanvasStroke> localStrokeMap = {for (var s in localStrokes) s.clientStrokeId: s};
    final Map<String, CanvasTextBlock> localTextMap = {for (var t in localTexts) t.clientTextId: t};
    final Map<String, CanvasImageBlock> localImageMap = {for (var i in localImages) i.clientImageId: i};
    await _db.batch((batch) {
      List strokeList = _parseJsonList(sPage['stroke_data']);
      for (var st in strokeList) {
        final String id = st['id']?.toString() ?? uniqid();
        final int serverTime = (st['updated_at'] as num?)?.toInt() ?? 0;
        final bool serverDeleted = st['is_deleted'] == true || st['is_deleted'] == 1;
        final local = localStrokeMap[id];
        
        if (local == null) {
          debugPrint('📥 [Sync-Merge] Novo traço detectado: $id');
          batch.insert(_db.canvasStrokes, CanvasStrokesCompanion.insert(
            clientStrokeId: id, 
            pageId: localPageId, 
            strokeData: jsonEncode(st), 
            isDeleted: Value(serverDeleted ? 1 : 0), 
            deletedInSession: Value(st['deleted_in_session'] == true ? 1 : 0), 
            syncedWithCloud: const Value(1), 
            updatedAt: Value(serverTime > 0 ? serverTime : TimeService().nowMs())
          ), mode: InsertMode.insertOrReplace);
        } else if (serverTime > local.updatedAt) {
          debugPrint('🔄 [Sync-Merge] Atualizando traço $id (LWW): Server $serverTime > Local ${local.updatedAt}');
          batch.insert(_db.canvasStrokes, CanvasStrokesCompanion.insert(
            clientStrokeId: id, 
            pageId: localPageId, 
            strokeData: jsonEncode(st), 
            isDeleted: Value(serverDeleted ? 1 : 0), 
            deletedInSession: Value(st['deleted_in_session'] == true ? 1 : 0), 
            syncedWithCloud: const Value(1), 
            updatedAt: Value(serverTime)
          ), mode: InsertMode.insertOrReplace);
        } else {
          debugPrint('🛡️ [Sync-Merge] Traço local $id é mais recente ou igual. Ignorando atualização do servidor.');
        }
      }
      List textList = _parseJsonList(sPage['text_data']);
      for (var txt in textList) {
        final String id = txt['id']?.toString() ?? uniqid();
        final int serverTime = (txt['updated_at'] as num?)?.toInt() ?? 0;
        final bool serverDeleted = txt['is_deleted'] == true || txt['is_deleted'] == 1;
        final local = localTextMap[id];
        if (local == null) {
           debugPrint('📥 [Sync-Merge] Novo texto detectado: $id');
           batch.insert(_db.canvasTextBlocks, CanvasTextBlocksCompanion.insert(
            clientTextId: id, 
            pageId: localPageId, 
            textData: jsonEncode(txt), 
            isDeleted: Value(serverDeleted ? 1 : 0), 
            deletedInSession: Value(txt['deleted_in_session'] == true ? 1 : 0), 
            syncedWithCloud: const Value(1), 
            updatedAt: Value(serverTime > 0 ? serverTime : TimeService().nowMs())
          ), mode: InsertMode.insertOrReplace);
        } else if (serverTime > local.updatedAt) {
          debugPrint('🔄 [Sync-Merge] Atualizando texto $id (LWW): Server $serverTime > Local ${local.updatedAt}');
          batch.insert(_db.canvasTextBlocks, CanvasTextBlocksCompanion.insert(
            clientTextId: id, 
            pageId: localPageId, 
            textData: jsonEncode(txt), 
            isDeleted: Value(serverDeleted ? 1 : 0), 
            deletedInSession: Value(txt['deleted_in_session'] == true ? 1 : 0), 
            syncedWithCloud: const Value(1), 
            updatedAt: Value(serverTime)
          ), mode: InsertMode.insertOrReplace);
        }
      }
      List imageList = _parseJsonList(sPage['image_data']);
      for (var img in imageList) {
        final String id = img['id']?.toString() ?? uniqid();
        final int serverTime = (img['updated_at'] as num?)?.toInt() ?? 0;
        final bool serverDeleted = img['is_deleted'] == true || img['is_deleted'] == 1;
        final local = localImageMap[id];
        if (local == null) {
           debugPrint('📥 [Sync-Merge] Nova imagem detectada: $id');
           batch.insert(_db.canvasImageBlocks, CanvasImageBlocksCompanion.insert(
            clientImageId: id, 
            pageId: localPageId, 
            imagePath: img['image_path']?.toString() ?? '', 
            posX: (img['dx'] as num?)?.toDouble() ?? 0.0, 
            posY: (img['dy'] as num?)?.toDouble() ?? 0.0, 
            width: (img['width'] as num?)?.toDouble() ?? 300.0, 
            height: (img['height'] as num?)?.toDouble() ?? 200.0, 
            rotation: (img['rotation'] as num?)?.toDouble() ?? 0.0, 
            isDeleted: Value(serverDeleted ? 1 : 0), 
            deletedInSession: Value(img['deleted_in_session'] == true ? 1 : 0), 
            syncedWithCloud: const Value(1), 
            updatedAt: Value(serverTime > 0 ? serverTime : TimeService().nowMs())
          ), mode: InsertMode.insertOrReplace);
        } else if (serverTime > local.updatedAt) {
          debugPrint('🔄 [Sync-Merge] Atualizando imagem $id (LWW): Server $serverTime > Local ${local.updatedAt}');
          batch.insert(_db.canvasImageBlocks, CanvasImageBlocksCompanion.insert(
            clientImageId: id, 
            pageId: localPageId, 
            imagePath: img['image_path']?.toString() ?? '', 
            posX: (img['dx'] as num?)?.toDouble() ?? 0.0, 
            posY: (img['dy'] as num?)?.toDouble() ?? 0.0, 
            width: (img['width'] as num?)?.toDouble() ?? 300.0, 
            height: (img['height'] as num?)?.toDouble() ?? 200.0, 
            rotation: (img['rotation'] as num?)?.toDouble() ?? 0.0, 
            isDeleted: Value(serverDeleted ? 1 : 0), 
            deletedInSession: Value(img['deleted_in_session'] == true ? 1 : 0), 
            syncedWithCloud: const Value(1), 
            updatedAt: Value(serverTime)
          ), mode: InsertMode.insertOrReplace);
        }
      }

      // 🛡️ PROTEÇÃO OFFLINE-FIRST REFORÇADA: Removida deleção por ausência.
      // Agora confiamos apenas no flag 'is_deleted' explícito que o servidor envia.
      // Se um item local não estiver na resposta do servidor, ele é mantido como "novo/pendente".
    });
    await (_db.update(_db.pages)..where((t) => t.id.equals(localPageId))).write(PagesCompanion(updatedAt: Value(serverTs ?? TimeService().nowMs())));
  }

  String? _extractNextUrl(Map<String, dynamic> responseData) {
    final dynamic links = responseData['links'];
    if (links is Map) return links['next']?.toString();
    if (links is List) for (var link in links) if (link is Map && link['label']?.toString().contains('Next') == true) return link['url']?.toString();
    return responseData['next_page_url']?.toString();
  }

  List _parseJsonList(dynamic data) {
    if (data == null) return [];
    if (data is String) { try { return jsonDecode(data); } catch (_) { return []; } }
    if (data is Iterable) return List.from(data);
    return [];
  }

  Future<void> pushRecordings() async {
    try {
      final unsynced = await (_db.select(_db.lessonRecordings)..where((t) => t.syncedWithCloud.equals(0))).get();
      if (unsynced.isEmpty) return;

      for (var row in unsynced) {
        final notebookRow = await (_db.select(_db.notebooks)..where((t) => t.id.equals(row.notebookId))).getSingleOrNull();
        if (notebookRow?.serverId == null) continue;

        String audioUrl = row.audioUrl;
        
        // 🚀 Se for um path local, tentar upload primeiro
        if (!kIsWeb && !audioUrl.startsWith('http')) {
          final file = io.File(audioUrl);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final remoteUrl = await _canvasRepository.uploadLessonAudio(
              notebookRow!.serverId!, 
              'lesson_${row.clientId}.m4a', 
              bytes,
              title: row.title,
              duration: row.durationSeconds,
              clientId: row.clientId
            );
            if (remoteUrl != null) {
              audioUrl = remoteUrl;
              // Atualizar localmente com a nova URL (opcional aqui, o push final confirmará)
            } else {
              continue; // Tenta no próximo ciclo
            }
          }
        }

        final response = await _apiService.post('/sync/recordings/push', {
          'recordings': [{
            'notebook_id': notebookRow!.serverId, 
            'client_id': row.clientId, 
            'title': row.title, 
            'audio_url': audioUrl, 
            'duration_seconds': row.durationSeconds, 
            'updated_at': row.updatedAt
          }]
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final syncedItem = (data['synced_recordings'] as List?)?.first;
          if (syncedItem != null) {
            final int serverId = syncedItem['server_id'];
            await (_db.update(_db.lessonRecordings)..where((t) => t.clientId.equals(row.clientId!))).write(
              LessonRecordingsCompanion(
                serverId: Value(serverId), 
                audioUrl: Value(audioUrl),
                syncedWithCloud: const Value(1)
              )
            );
          }
        }
      }
    } catch (e) {
      debugPrint('🚨 [Sync-Recordings] Erro no push: $e');
    }
  }

  Future<void> pullRecordings() async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastSynced = prefs.getString('last_recordings_sync');
    try {
      final url = lastSynced != null ? '/sync/recordings/pull?last_synced_at=$lastSynced' : '/sync/recordings/pull';
      final response = await _apiService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List serverRecordings = data['data'] ?? [];
        final allNotebooks = await _db.select(_db.notebooks).get();
        final Map<int, int> serverToLocalNotebookId = {for (var n in allNotebooks) if (n.serverId != null) n.serverId!: n.id};
        if (data['meta'] != null && data['meta']['server_time'] != null) await prefs.setString('last_recordings_sync', data['meta']['server_time']);
        await _db.batch((batch) {
          for (var rec in serverRecordings) {
            final int? localNbId = serverToLocalNotebookId[rec['notebook_id']];
            if (localNbId == null) continue;
            batch.insert(_db.lessonRecordings, LessonRecordingsCompanion.insert(serverId: Value(rec['id']), clientId: Value(rec['client_id'] ?? Uuid().v4()), notebookId: localNbId, title: rec['title'] ?? 'Sem título', audioUrl: rec['audio_url'] ?? '', durationSeconds: Value(rec['duration_seconds'] ?? 0), syncedWithCloud: const Value(1), updatedAt: Value(rec['updated_at_ms'] ?? 0)), mode: InsertMode.insertOrReplace);
          }
        });
      }
    } catch (e) {}
  }

  Future<bool> fastPushPage(pages_model.LocalPage page, int notebookServerId, String myUserId) async {
    try {
      final Map<String, dynamic> payload = await page.toJsonAsync();
      payload['stroke_data'] = page.strokes.map((s) => s.simplify(epsilon: 0.25).toJson()).toList();
      payload['notebook_id'] = notebookServerId;
      payload['sender_id'] = myUserId;
      if (page.serverId == null) payload['is_new_page'] = true;
      final response = await _apiService.post('/sync/realtime/update', {'page': payload});
      return response.statusCode == 200;
    } catch (e) { return false; }
  }
}
