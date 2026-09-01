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
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'api_service.dart';
import 'sync_service_isolates.dart';

class SyncService {
  final AppDatabase _db = AppDatabase.instance;
  final ApiService _apiService;
  final CanvasRepository _canvasRepository;
  
  bool _isGlobalSyncing = false; // 🚀 Semáforo interno

  SyncService(this._apiService, this._canvasRepository);

  static bool isCollaborationActive = false;
  static int? activeNotebookId;

  int? _parseSafeInt(dynamic val) {
    if (val == null) return null;
    if (val is int) return val;
    if (val is double) return val.toInt();
    if (val is String) {
      final date = DateTime.tryParse(val);
      if (date != null) return date.millisecondsSinceEpoch;
      return int.tryParse(val);
    }
    return null;
  }

  String uniqid() => DateTime.now().microsecondsSinceEpoch.toString();

  String? _parseMetaTime(dynamic meta) {
    if (meta == null) return null;
    // Tenta server_time (ISO String) primeiro, depois server_time_ms
    if (meta['server_time'] != null) return meta['server_time'].toString();
    if (meta['server_time_ms'] != null) return meta['server_time_ms'].toString();
    return null;
  }

  // =========================================================================
  // 1. SINCRONIZAÇÃO TOTAL
  // =========================================================================
  Future<void> syncAll({bool forced = false, bool metadataOnly = false, bool pushOnly = false}) async {
    if (_isGlobalSyncing && !forced) {
      debugPrint('⏳ [Sync] Ignorado: Já existe um ciclo em curso.');
      return;
    }
    
    if (isCollaborationActive && !forced) return;
    
    _isGlobalSyncing = true;
    debugPrint('🔄 [Sync] Sincronização híbrida iniciada... ${pushOnly ? "(Apenas PUSH)" : ""}');

    try {
      // 1. Tentar Enviar Novidades (E receber deltas rápidos no retorno)
      final bool hasMoreSubjects = await pushOfflineSubjects(pushOnly: pushOnly);
      final bool hasMoreNotebooks = await pushNotebooks(pushOnly: pushOnly);

      // 2. Recuperação de Lotes (Apenas se PUSH indicou que há muito mais dados)
      if (!pushOnly) {
        if (hasMoreSubjects || forced) await pullSubjects();
        if (hasMoreNotebooks || forced) await pullNotebooks();
      }

      if (!metadataOnly) {
        final bool hasMorePages = await pushPages(pushOnly: pushOnly);
        if (!pushOnly && (hasMorePages || forced)) {
          await pullPages(); // 🚀 Só ativa o pull pesado se detectado grande volume
        }
        final bool hasMoreRecs = await pushRecordings(pushOnly: pushOnly);
        if (!pushOnly && (hasMoreRecs || forced)) {
          await pullRecordings();
        }
      }
      debugPrint('✅ [Sync] Ciclo híbrido concluído.');
    } catch (e) {
      debugPrint('🚨 [Sync General] Falha: $e');
      rethrow;
    } finally {
      _isGlobalSyncing = false; // 🚀 Libertar semáforo
    }
  }

  // =========================================================================
  // 2. DISCIPLINAS (SUBJECTS)
  // =========================================================================
  Future<bool> pushOfflineSubjects({bool pushOnly = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastSynced = prefs.getString('last_subjects_sync');

    try {
      final unsynced = await (_db.select(_db.subjects)..where((t) => t.syncedWithCloud.equals(0))).get();
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

      if (payload.isNotEmpty) {
        debugPrint('🛫 [Sync-Push] Enviando ${payload.length} disciplinas: ${payload.map((s) => '${s['name']}(del:${s['is_deleted']})').join(', ')}');
      }

      final response = await _apiService.post('/sync/push', {
        'subjects': payload,
        'last_synced_at': lastSynced,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // 1. Processar confirmações do PUSH
        for (var item in data['synced_subjects'] ?? []) {
          final String clientUuid = item['client_id'].toString();
          final int? serverId = item['id'] ?? item['server_id'];
          final int serverTime = _parseSafeInt(item['updated_at_ms']) ?? _parseSafeInt(item['updated_at']) ?? TimeService().nowMs();
          
          if (serverId != null) {
            await (_db.update(_db.subjects)..where((t) => t.clientId.equals(clientUuid))).write(
              SubjectsCompanion(serverId: Value(serverId), updatedAt: Value(serverTime), syncedWithCloud: const Value(1))
            );
          } else {
            // Se o servidor confirmou mas não enviou ID (ex: já estava apagado), apenas marcamos como sincronizado
            await (_db.update(_db.subjects)..where((t) => t.clientId.equals(clientUuid))).write(
              const SubjectsCompanion(syncedWithCloud: Value(1))
            );
          }
        }

        // 2. Processar novidades do PULL rápido (Pular se pushOnly)
        if (!pushOnly) {
          final List updates = data['server_updates'] ?? [];
          if (updates.isNotEmpty) {
             await _applySubjectUpdates(updates);
          }

          final String? serverTime = _parseMetaTime(data['meta']);
          if (serverTime != null) {
             await prefs.setString('last_subjects_sync', serverTime);
          }
        }
        
        return data['has_more'] == true; // 🚀 Avisar se deve rodar o pull total
      }
      return false;
    } catch (e) {
      debugPrint('🚨 Erro Sync Subjects: $e');
      return false;
    }
  }

  Future<void> _applySubjectUpdates(List updates) async {
    final userQuery = await (_db.select(_db.users)..orderBy([(t) => OrderingTerm(expression: t.id)])..limit(1)).get();
    if (userQuery.isEmpty) return;
    final int localUserId = userQuery.first.id;

    await _db.transaction(() async {
      for (var sub in updates) {
        final int? sId = sub['id'] ?? sub['server_id'];
        if (sId == null) continue;
        
        final String cId = sub['client_id'] ?? uniqid();
        final int serverTime = _parseSafeInt(sub['updated_at_ms']) ?? _parseSafeInt(sub['updated_at']) ?? 0;
        
        final companion = SubjectsCompanion.insert(
          serverId: Value(sId), clientId: Value(cId), userId: localUserId, 
          name: sub['name'] ?? '', color: sub['color'] ?? '#0F4C5C', icon: Value(sub['icon']), 
          isDeleted: Value(sub['deleted_at'] != null ? 1 : 0), syncedWithCloud: const Value(1), 
          updatedAt: Value(serverTime),
          isArchived: Value(sub['is_archived'] == 1 || sub['is_archived'] == true ? 1 : 0),
          isFavorite: Value(sub['is_favorite'] == 1 || sub['is_favorite'] == true ? 1 : 0),
        );

        final existing = await (_db.select(_db.subjects)..where((t) => t.clientId.equals(cId))).getSingleOrNull();
        if (existing != null) {
          // 🚀 PRIORIDADE PARA ELIMINAÇÃO: Se o servidor diz que foi apagado, marcamos localmente 
          // mesmo que o timestamp pareça idêntico, para evitar "ressurreição" de itens.
          final bool serverSaysDeleted = sub['deleted_at'] != null;
          
          if (serverSaysDeleted || serverTime > existing.updatedAt) {
            await (_db.update(_db.subjects)..where((t) => t.id.equals(existing.id))).write(companion);
          }
        } else {
          await _db.into(_db.subjects).insertOnConflictUpdate(companion);
        }
      }
    });
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
        final String? serverTime = _parseMetaTime(responseData['meta']);
        if (serverTime != null) await prefs.setString('last_subjects_sync', serverTime);
          if (serverSubjects.isNotEmpty) {
            anyChanges = true;
            final userQuery = await (_db.select(_db.users)..orderBy([(t) => OrderingTerm(expression: t.id)])..limit(1)).get();
            if (userQuery.isEmpty) return false;
            final int localUserId = userQuery.first.id;
            await _db.transaction(() async {
              for (var sub in serverSubjects) {
                final int? sId = sub['id'] is int ? sub['id'] : int.tryParse(sub['id']?.toString() ?? '');
                if (sId == null) continue;
                
                final String? cId = sub['client_id']?.toString();
                final int serverTime = sub['updated_at_ms'] != null ? (sub['updated_at_ms'] as num).toInt() : (sub['updated_at'] != null ? DateTime.parse(sub['updated_at'].toString()).millisecondsSinceEpoch : 0);
                final companion = SubjectsCompanion.insert(
                  serverId: Value(sId), clientId: Value(cId ?? uniqid()), userId: localUserId, 
                  name: sub['name'] ?? '', color: sub['color'] ?? '#0F4C5C', icon: Value(sub['icon']), 
                  isDeleted: Value(sub['deleted_at'] != null ? 1 : 0), syncedWithCloud: const Value(1), 
                  updatedAt: Value(serverTime),
                  isArchived: Value(sub['is_archived'] == 1 || sub['is_archived'] == true ? 1 : 0),
                  isFavorite: Value(sub['is_favorite'] == 1 || sub['is_favorite'] == true ? 1 : 0),
                );
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
  Future<bool> pushNotebooks({bool pushOnly = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastSynced = prefs.getString('last_notebooks_sync');

    try {
      final unsynced = await (_db.select(_db.notebooks)..where((t) => t.syncedWithCloud.equals(0))).get();
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
          id: row.id, serverId: row.serverId, clientId: effectiveUuid, subjectId: cloudSubId, 
          title: row.title, coverType: row.coverType, color: row.color, coverImage: row.coverImage, 
          templateType: row.templateType, collaborationMode: row.collaborationMode, 
          isPublished: row.isPublished, price: row.price, description: row.description, 
          authorName: row.authorName, syncedWithCloud: row.syncedWithCloud, isDeleted: row.isDeleted, 
          updatedAt: row.updatedAt,
          tags: notebooks_model.Notebook.parseTags(row.tags),
          isArchived: row.isArchived == 1,
          isFavorite: row.isFavorite == 1,
        );
        payload.add(notebookObj.toJson());
      }

      final response = await _apiService.post('/sync/notebooks/push', {
        'notebooks': payload,
        'last_synced_at': lastSynced,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // 1. Confirmações
        for (var item in data['synced_notebooks'] ?? []) {
          final String clientUuid = item['client_id'].toString();
          final int? sId = item['id'] ?? item['server_id'];
          final localRow = await (_db.select(_db.notebooks)..where((t) => t.clientId.equals(clientUuid))).getSingleOrNull();
          if (localRow == null) continue;

          if (sId != null) {
            final existing = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(sId) & t.id.equals(localRow.id).not())).getSingleOrNull();
            if (existing != null) {
              await (_db.delete(_db.notebooks)..where((t) => t.id.equals(localRow.id))).go();
            } else {
              final int serverTime = _parseSafeInt(item['updated_at_ms']) ?? _parseSafeInt(item['updated_at']) ?? TimeService().nowMs();
              await (_db.update(_db.notebooks)..where((t) => t.id.equals(localRow.id))).write(
                NotebooksCompanion(serverId: Value(sId), updatedAt: Value(serverTime), syncedWithCloud: const Value(1))
              );
            }
          } else {
            // Confirmação sem ID (ex: apagado no servidor)
            await (_db.update(_db.notebooks)..where((t) => t.id.equals(localRow.id))).write(
              const NotebooksCompanion(syncedWithCloud: Value(1))
            );
          }
        }

        // 2. Updates do Servidor (Pular se pushOnly)
        if (!pushOnly) {
          final List updates = data['server_updates'] ?? [];
          if (updates.isNotEmpty) {
             await _applyNotebookUpdates(updates);
          }

          final String? serverTime = _parseMetaTime(data['meta']);
          if (serverTime != null) {
             await prefs.setString('last_notebooks_sync', serverTime);
          }
        }

        return data['has_more'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('🚨 Erro Sync Notebooks: $e');
      return false;
    }
  }

  Future<void> _applyNotebookUpdates(List updates) async {
    final userQuery = await (_db.select(_db.users)..orderBy([(t) => OrderingTerm(expression: t.id)])..limit(1)).get();
    final int currentUserId = userQuery.isNotEmpty ? userQuery.first.id : 0;
    final allSubjects = await _db.select(_db.subjects).get();
    final Map<int, int> subjectIdMap = {for (var s in allSubjects) if (s.serverId != null) s.serverId!: s.id};

    await _db.transaction(() async {
      for (var net in updates) {
        final int? sId = net['id'] is int ? net['id'] : int.tryParse(net['id']?.toString() ?? '');
        if (sId == null) continue;
        
        final String? cId = net['client_id'];
        final int? serverSubId = net['subject_id'] != null ? int.tryParse(net['subject_id'].toString()) : null;
        final int? localSubId = (serverSubId != null) ? subjectIdMap[serverSubId] : null;
        final int serverTime = _parseSafeInt(net['updated_at_ms']) ?? _parseSafeInt(net['updated_at']) ?? 0;
        
        final companion = NotebooksCompanion.insert(
          serverId: Value(sId), clientId: Value(cId ?? uniqid()), subjectId: Value(localSubId), title: net['title'] ?? '',
          coverType: net['cover_type'] ?? 'color', color: Value(net['color']), coverImage: Value(net['cover_image']),
          templateType: Value(net['template_type'] ?? 'study'), collaborationMode: Value(net['collaboration_mode'] ?? 'study_group'),
          isPublished: Value(int.tryParse(net['is_published']?.toString() ?? '0') ?? 0), price: Value(double.tryParse(net['price']?.toString() ?? '0.0') ?? 0.0),
          isDeleted: Value(net['deleted_at'] != null ? 1 : 0), syncedWithCloud: const Value(1), updatedAt: Value(serverTime), role: Value(net['role'] ?? 'viewer'),
          alternativeTitle: Value(net['alternative_title']), sharingType: Value(net['sharing_type'] ?? 'full'),
          isArchived: Value(net['is_archived'] == 1 || net['is_archived'] == true ? 1 : 0),
          isFavorite: Value(net['is_favorite'] == 1 || net['is_favorite'] == true ? 1 : 0),
          origin: Value(net['origin']),
          lastUpdatedByName: Value(net['last_updated_by_name']),
          notificationsEnabled: Value((net['notifications_enabled'] == 1 || net['notifications_enabled'] == true) ? 1 : 0),
          participantsPreview: Value(net['participants_preview'] != null ? jsonEncode(net['participants_preview']) : null),
        );

        final existing = await (_db.select(_db.notebooks)..where((t) => t.clientId.equals(cId ?? ''))).getSingleOrNull();
        if (existing != null) {
          if (serverTime >= existing.updatedAt) {
            await (_db.update(_db.notebooks)..where((t) => t.id.equals(existing.id))).write(companion);
          }
        } else {
           await _db.into(_db.notebooks).insertOnConflictUpdate(companion);
        }

        // 🚀 NOVIDADE: Atualizar também a tabela de pivô para cadernos partilhados (Visibilidade imediata)
        final localNb = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(sId))).getSingleOrNull();
        final String? role = net['role']?.toString();
        if (localNb != null && currentUserId > 0 && role != null) {
          if (role != 'owner') {
             await _db.into(_db.notebookUser).insertOnConflictUpdate(NotebookUserCompanion.insert(
                notebookId: localNb.id, 
                userId: currentUserId, 
                role: Value(role), 
                syncedWithCloud: const Value(1), 
                updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
                isArchived: Value(net['is_archived'] == 1 || net['is_archived'] == true ? 1 : 0),
                isFavorite: Value(net['is_favorite'] == 1 || net['is_favorite'] == true ? 1 : 0),
             ));
          } else {
             // Se agora sou dono (raro em update, mas possível), remover do pivô de partilhas
             await (_db.delete(_db.notebookUser)..where((t) => t.notebookId.equals(localNb.id) & t.userId.equals(currentUserId))).go();
          }
        }
      }
    });
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
        final String? serverTime = _parseMetaTime(responseData['meta']);
        if (serverTime != null) await prefs.setString('last_notebooks_sync', serverTime);
          if (serverNotebooks.isNotEmpty) {
            anyChanges = true;
            final userQuery = await (_db.select(_db.users)..orderBy([(t) => OrderingTerm(expression: t.id)])..limit(1)).get();
            final int currentUserId = userQuery.isNotEmpty ? userQuery.first.id : 0;
            final allSubjects = await _db.select(_db.subjects).get();
            final Map<int, int> subjectIdMap = {for (var s in allSubjects) if (s.serverId != null) s.serverId!: s.id};
            await _db.transaction(() async {
              for (var net in serverNotebooks) {
                final int? sId = net['id'] is int ? net['id'] : int.tryParse(net['id']?.toString() ?? '');
                if (sId == null) continue;
                
                receivedServerIds.add(sId);
                final String? cId = net['client_id']?.toString();
                final int? serverSubId = net['subject_id'] != null ? (net['subject_id'] is int ? net['subject_id'] : int.parse(net['subject_id'].toString())) : null;
                final int? localSubId = (serverSubId != null) ? subjectIdMap[serverSubId] : null;
                final int serverTime = net['updated_at_ms'] != null ? (net['updated_at_ms'] as num).toInt() : (net['updated_at'] != null ? DateTime.parse(net['updated_at'].toString()).millisecondsSinceEpoch : 0);
                final String serverRole = net['role']?.toString() ?? 'viewer';
                
                final companion = NotebooksCompanion.insert(
                  serverId: Value(sId), clientId: Value(cId ?? uniqid()), subjectId: Value(localSubId), title: net['title'] ?? '',
                  coverType: net['cover_type'] ?? 'color', 
                  color: net['color'] != null ? Value(net['color']) : const Value.absent(),
                  coverImage: Value(net['cover_image']),
                  templateType: Value(net['template_type'] ?? 'study'), collaborationMode: Value(net['collaboration_mode'] ?? 'study_group'),
                  isPublished: Value(int.tryParse(net['is_published']?.toString() ?? '0') ?? 0), price: Value(double.tryParse(net['price']?.toString() ?? '0.0') ?? 0.0),
                  description: Value(net['description']), authorName: Value(net['author_name']), isDeleted: Value(net['deleted_at'] != null ? 1 : 0),
                  syncedWithCloud: const Value(1), updatedAt: Value(serverTime), role: Value(serverRole),
                  alternativeTitle: Value(net['alternative_title']), sharingType: Value(net['sharing_type'] ?? 'full'),
                  isArchived: Value(net['is_archived'] == 1 || net['is_archived'] == true ? 1 : 0),
                  isFavorite: Value(net['is_favorite'] == 1 || net['is_favorite'] == true ? 1 : 0),
                  origin: Value(net['origin']),
                  lastUpdatedByName: Value(net['last_updated_by_name']),
                  notificationsEnabled: Value((net['notifications_enabled'] == 1 || net['notifications_enabled'] == true) ? 1 : 0),
                  participantsPreview: Value(net['participants_preview'] != null ? jsonEncode(net['participants_preview']) : null),
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
                        color: net['color'] != null ? Value(net['color']) : const Value.absent(),
                        coverImage: companion.coverImage,templateType: companion.templateType, collaborationMode: companion.collaborationMode, isPublished: companion.isPublished, price: companion.price, description: companion.description, authorName: companion.authorName, isDeleted: companion.isDeleted, syncedWithCloud: companion.syncedWithCloud, updatedAt: Value(serverTime), role: companion.role, alternativeTitle: companion.alternativeTitle, sharingType: companion.sharingType,
                        origin: companion.origin,
                        lastUpdatedByName: companion.lastUpdatedByName,
                        notificationsEnabled: companion.notificationsEnabled,
                        participantsPreview: companion.participantsPreview,
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
            final allNotebooksAfter = await _db.select(_db.notebooks).get();
            final Map<int, int> notebookIdMap = {for (var n in allNotebooksAfter) if (n.serverId != null) n.serverId!: n.id};
            await _db.batch((batch) {
              for (var net in serverNotebooks) {
                final sId = net['id'];
                final localNbId = notebookIdMap[sId];
                final String? role = net['role']?.toString();
                if (localNbId != null && currentUserId > 0 && role != null && role != 'owner') {
                  batch.insert(_db.notebookUser, NotebookUserCompanion.insert(
                    notebookId: localNbId, 
                    userId: currentUserId, 
                    role: Value(role), 
                    syncedWithCloud: const Value(1), 
                    updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
                    isArchived: Value(net['is_archived'] == 1 || net['is_archived'] == true ? 1 : 0),
                    isFavorite: Value(net['is_favorite'] == 1 || net['is_favorite'] == true ? 1 : 0),
                  ), mode: InsertMode.insertOrReplace);
                } else if (localNbId != null && currentUserId > 0 && role == 'owner') {
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
      
      if (lastSynced == null) {
         final allLocalShared = await (_db.select(_db.notebooks)..where((t) => t.role.isNotValue('owner') & t.serverId.isNotNull())).get();
         for (var localNb in allLocalShared) {
           if (localNb.serverId != null && !receivedServerIds.contains(localNb.serverId!)) {
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
  Future<bool> pushPages({int? onlyNotebookId, bool pushOnly = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastSynced = prefs.getString('last_pages_sync');

    try {
      final query = _db.select(_db.pages)..where((t) => t.syncedWithCloud.equals(0));
      if (onlyNotebookId != null) query.where((t) => t.notebookId.equals(onlyNotebookId));
      final unsyncedPages = await query.get();
      
      if (unsyncedPages.isEmpty) {
        // debugPrint('ℹ️ [Sync-Push] Nenhuma página pendente de sincronização.');
        return true;
      }

      debugPrint('🛫 [Sync-Push] Detectadas ${unsyncedPages.length} páginas pendentes: ${unsyncedPages.map((p) => 'p${p.pageNumber}(id:${p.id})').join(', ')}');
      unsyncedPages.sort((a, b) => b.isDeleted.compareTo(a.isDeleted));
      bool allSuccess = true;
      bool serverHasMore = false;

      // 🚀 OTIMIZAÇÃO: Enviar em lotes (Chunks) para reduzir overhead de rede sem travar
      // 🚀 OTIMIZAÇÃO: Lote maior para reordenações e cadernos grandes
      const int batchSize = 10;
      for (int i = 0; i < unsyncedPages.length; i += batchSize) {
        final currentBatch = unsyncedPages.sublist(i, (i + batchSize > unsyncedPages.length) ? unsyncedPages.length : i + batchSize);
        final List<Map<String, dynamic>> pagesPayload = [];

        for (var row in currentBatch) {
          final notebook = await (_db.select(_db.notebooks)..where((t) => t.id.equals(row.notebookId))).getSingleOrNull();
          if (notebook == null || notebook.serverId == null) continue;
          
          final String? cId = row.clientId;
          if (cId == null) continue;
          
          // 🚀 CARREGAMENTO COMPLETO: Precisamos de enviar o conteúdo (strokes, etc)
          // mesmo que a folha esteja apagada, para o servidor guardar o snapshot final.
          final fullPage = await _canvasRepository.getPageByClientId(cId, onlyUnsynced: true);
          if (fullPage == null) continue;

          final pageMap = await fullPage.toJsonAsync();
          pageMap['notebook_id'] = notebook.serverId;
          // Garantir que o estado de deleção está correto no mapa
          pageMap['is_deleted'] = row.isDeleted == 1 ? 1 : 0;
          if (row.serverId != null) pageMap['server_id'] = row.serverId;

          pagesPayload.add(pageMap);
          
          if (row.isDeleted == 1) {
            debugPrint('🛫 [Sync-Push-Delete] Enviando folha apagada ${row.pageNumber} com conteúdos pendentes.');
          } else {
            debugPrint('🛫 [Sync-Push-Delta] Enviando novidades da página ${row.pageNumber}: ${fullPage.strokes.length} traços.');
          }
        }

        if (pagesPayload.isEmpty) continue;

        try {
          debugPrint('🛫 [Sync-Push-Batch] Enviando lote de ${pagesPayload.length} páginas...');
          var response = await _apiService.post('/sync/pages/push', {
            'pages': pagesPayload,
            'last_synced_at': lastSynced, // 🚀 Delta bidirecional
          });
          
          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = jsonDecode(response.body);
            if (data['has_more'] == true) serverHasMore = true;
            
            // 1. Processar Confirmações (Resultados do PUSH)
            final List syncedPages = data['synced_pages'] ?? [];
            final List<int> localIdsToPull = [];
            final Map<int, Map<String, dynamic>> serverDataForPull = {};

            for (var syncedPageMap in syncedPages) {
              final String? cId = syncedPageMap['client_id'];
              final String? status = syncedPageMap['status']?.toString();
              final int? sNbId = syncedPageMap['notebook_id'];

              if (cId == null) continue;
              
              // No logout (pushOnly), não precisamos de puxar dados ignorados ou deltas do servidor
              if (pushOnly) {
                 // Apenas marcamos como sincronizado localmente se o servidor confirmou
                 final localPage = await (_db.select(_db.pages)..where((t) => t.clientId.equals(cId))).getSingleOrNull();
                 if (localPage != null) {
                    await _markPageItemsAsSynced(localPage.id);
                    await (_db.update(_db.pages)..where((t) => t.id.equals(localPage.id))).write(const PagesCompanion(syncedWithCloud: Value(1)));
                 }
                 continue;
              }

              if (status == 'ignored_old' && sNbId != null) {
                await pullSpecificPage(sNbId, syncedPageMap['page_number'] ?? 0, clientId: cId);
                continue;
              }
              
              if (status == 'deleted') {
                final localPage = await (_db.select(_db.pages)..where((t) => t.clientId.equals(cId))).getSingleOrNull();
                if (localPage != null) {
                  // 🚀 PRESERVAÇÃO: Não apagar fisicamente. 
                  // Apenas marcar como sincronizado para que o utilizador possa restaurar se quiser.
                  await (_db.update(_db.pages)..where((t) => t.id.equals(localPage.id))).write(const PagesCompanion(syncedWithCloud: Value(1)));
                }
                continue;
              }

              final int localId = await _canvasRepository.savePageFromMap(syncedPageMap, sNbId);
              if (syncedPageMap['_sync_status'] == 'already_current') {
                await _markPageItemsAsSynced(localId);
              } else {
                localIdsToPull.add(localId);
                serverDataForPull[localId] = syncedPageMap;
              }
              await (_db.update(_db.pages)..where((t) => t.id.equals(localId))).write(const PagesCompanion(syncedWithCloud: Value(1)));
            }

            // 2. Processar Novidades do Servidor (Resultados do PULL) - Pular se pushOnly
            if (!pushOnly) {
              final List updates = data['server_updates'] ?? [];
              for (var updMap in updates) {
                 final int sNbId = updMap['notebook_id'] is int ? updMap['notebook_id'] : int.parse(updMap['notebook_id'].toString());
                 final localId = await _canvasRepository.savePageFromMap(updMap, sNbId);
                 localIdsToPull.add(localId);
                 serverDataForPull[localId] = updMap;
              }

              if (localIdsToPull.isNotEmpty) {
                await _pullCanvasDataBatch(localIdsToPull, serverDataForPull);
              }
              
              final String? serverTime = _parseMetaTime(data['meta']);
              if (serverTime != null) {
                 await prefs.setString('last_pages_sync', serverTime);
              }
            }
            
            debugPrint('✅ [Sync-Push-Batch] Lote processado. Mais dados no servidor: $serverHasMore');
          } else {
            allSuccess = false;
          }
        } catch (e) {
          debugPrint('🚨 [Sync-Push-Batch] Erro no lote: $e');
          allSuccess = false;
        }
      }

      return serverHasMore;
    } catch (e) { return false; }
  }

  Future<void> _markPageItemsAsSynced(int localPageId) async {
    // 🚀 OTIMIZAÇÃO: Apenas atualizamos a coluna de sincronismo. 
    // O repository já ignora o valor interno do JSON ao carregar, priorizando a coluna.
    await _db.batch((batch) {
      batch.update(_db.canvasStrokes, const CanvasStrokesCompanion(syncedWithCloud: Value(1)), 
        where: (t) => t.pageId.equals(localPageId));
      batch.update(_db.canvasTextBlocks, const CanvasTextBlocksCompanion(syncedWithCloud: Value(1)), 
        where: (t) => t.pageId.equals(localPageId));
      batch.update(_db.canvasImageBlocks, const CanvasImageBlocksCompanion(syncedWithCloud: Value(1)), 
        where: (t) => t.pageId.equals(localPageId));
    });
  }

  Future<bool> pullPages({bool forceFull = false, int? onlyNotebookId}) async {
    final prefs = await SharedPreferences.getInstance();
    
    // 🚀 OTIMIZAÇÃO: Se for pull de um caderno específico, não usamos o timestamp global
    // para garantir que trazemos tudo o que falta para esse caderno.
    final String? lastSynced = (onlyNotebookId == null && !forceFull) ? prefs.getString('last_pages_sync') : null;
    
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
          final String? serverTime = _parseMetaTime(responseData['meta']);
          
          // 🚀 SÓ ATUALIZAMOS O MARCADOR GLOBAL se for um pull completo (sem filtro de caderno)
          if (onlyNotebookId == null && serverTime != null) {
            await prefs.setString('last_pages_sync', serverTime);
          }
          if (serverPages.isNotEmpty) {
            anyChanges = true;
            final List<int> localPageIdsForBatch = [];
            final Map<int, Map<String, dynamic>> serverPageDataMap = {};
            for (var sPage in serverPages) {
              final int sNbId = sPage['notebook_id'] is int ? sPage['notebook_id'] : int.parse(sPage['notebook_id'].toString());
              final int sId = sPage['id'] is int ? sPage['id'] : int.parse(sPage['id'].toString());
              final String? cId = sPage['client_id']?.toString();
              if (cId != null) serverClientIds.add(cId);
              
              // 🚀 JÁ NÃO APAGAMOS FISICAMENTE NO PULL
              // O savePageFromMap tratará de marcar isDeleted=1 ou 0
              // permitindo que o restauro funcione entre dispositivos.
              
              final notebook = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(sNbId))).getSingleOrNull();
              if (notebook == null) continue;
              final existingPage = await (_db.select(_db.pages)..where((t) => t.clientId.equals(cId ?? ''))).getSingleOrNull();
              final int serverTs = sPage['updated_at_ms'] ?? 0;
              if (existingPage != null && existingPage.syncedWithCloud == 0 && existingPage.updatedAt > serverTs) {
                localPageIdsForBatch.add(existingPage.id);
                serverPageDataMap[existingPage.id] = sPage;
                continue;
              }
              final localPageId = await _canvasRepository.savePageFromMap(sPage, sNbId);
              localPageIdsForBatch.add(localPageId);
              serverPageDataMap[localPageId] = sPage;
            }
            if (localPageIdsForBatch.isNotEmpty) await _pullCanvasDataBatch(localPageIdsForBatch, serverPageDataMap);
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
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = await compute<String, Map<String, dynamic>>((jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>, response.body);
        final List serverPages = responseData['data'] ?? responseData['pages'] ?? [];
        if (serverPages.isNotEmpty) {
          final sPage = serverPages.first;
          final notebook = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(notebookServerId))).getSingleOrNull();
          if (notebook == null) return;
          final localId = await _canvasRepository.savePageFromMap(sPage, notebookServerId);
          await _pullCanvasData(localId, sPage);
        }
      } else if (!isRetry && response.statusCode != 429) {
        await Future.delayed(const Duration(seconds: 2));
        return pullSpecificPage(notebookServerId, pageNumber, isRetry: true);
      }
    } catch (e) { debugPrint('🚨 [Sync] Erro pullSpecificPage: $e'); }
  }

  Future<void> _pullCanvasDataBatch(List<int> localPageIds, Map<int, Map<String, dynamic>> serverPageDataMap) async {
    try {
      // 🚀 LIMPEZA: Filtrar IDs inválidos (0) que podem ter vindo de falhas no repositório
      final validPageIds = localPageIds.where((id) => id > 0).toList();
      if (validPageIds.isEmpty) return;

      final List<Map<String, dynamic>> serverPagesList = [];
      for (var id in validPageIds) {
        final data = serverPageDataMap[id];
        if (data != null) serverPagesList.add({...data, '_localPageId': id});
      }
      
      final int currentTime = TimeService().nowMs();
      List<CanvasStrokesCompanion> strokes = [];
      List<CanvasTextBlocksCompanion> texts = [];
      List<CanvasImageBlocksCompanion> images = [];

      if (kIsWeb) {
        for (var sPage in serverPagesList) {
          final int localPageId = sPage['_localPageId'];
          final List strokeList = sPage['stroke_data'] ?? [];
          for (var st in strokeList) { 
            strokes.add(SyncIsolates.mapStrokeToCompanion(st, localPageId, currentTime)); 
            if (strokes.length % 100 == 0) await Future.delayed(Duration.zero); 
          }
          final List textList = sPage['text_data'] ?? [];
          for (var txt in textList) { texts.add(SyncIsolates.mapTextToCompanion(txt, localPageId, currentTime)); }
          final List imageList = sPage['image_data'] ?? [];
          for (var img in imageList) { images.add(SyncIsolates.mapImageToCompanion(img, localPageId, currentTime)); }
          await Future.delayed(Duration.zero);
        }
      } else {
        final List<dynamic> results = await compute(SyncIsolates.processCanvasDataBatch, {'serverPages': serverPagesList, 'currentTime': currentTime});
        strokes = results[0];
        texts = results[1];
        images = results[2];
      }

      // 🚀 VERIFICAÇÃO DE EXISTÊNCIA: Garantir que as páginas ainda existem no banco local
      // para evitar erros de Foreign Key.
      final existingPageRows = await (_db.select(_db.pages)..where((t) => t.id.isIn(validPageIds))).get();
      final Set<int> confirmedIds = existingPageRows.map((r) => r.id).toSet();
      
      final finalPageIds = validPageIds.where((id) => confirmedIds.contains(id)).toList();
      if (finalPageIds.isEmpty) return;

      await _db.batch((batch) {
        batch.deleteWhere(_db.canvasStrokes, (t) => t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(1));
        batch.deleteWhere(_db.canvasTextBlocks, (t) => t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(1));
        batch.deleteWhere(_db.canvasImageBlocks, (t) => t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(1));
        
        for (var s in strokes) {
          if (confirmedIds.contains(s.pageId.value)) {
            batch.insert(_db.canvasStrokes, s, mode: InsertMode.insertOrReplace);
          }
        }
        for (var t in texts) {
          if (confirmedIds.contains(t.pageId.value)) {
            batch.insert(_db.canvasTextBlocks, t, mode: InsertMode.insertOrReplace);
          }
        }
        for (var i in images) {
          if (confirmedIds.contains(i.pageId.value)) {
            batch.insert(_db.canvasImageBlocks, i, mode: InsertMode.insertOrReplace);
          }
        }

        for (var id in finalPageIds) {
           batch.update(_db.pages, PagesCompanion(updatedAt: Value(TimeService().nowMs()), syncedWithCloud: const Value(1)), where: (t) => t.id.equals(id));
        }
      });
      debugPrint('✅ [Sync-Batch] Sincronizados ${strokes.length} elementos em ${finalPageIds.length} páginas.');
    } catch (e) { 
      debugPrint('🚨 [Sync-Batch] Falha crítica: $e'); 
    }
  }

  Future<void> _pullCanvasData(int localPageId, Map<String, dynamic> sPage) async {
    await _pullCanvasDataBatch([localPageId], {localPageId: sPage});
  }

  String? _extractNextUrl(Map<String, dynamic> responseData) {
    final dynamic links = responseData['links'];
    if (links is Map) return links['next']?.toString();
    if (links is List) for (var link in links) if (link is Map && link['label']?.toString().contains('Next') == true) return link['url']?.toString();
    return responseData['next_page_url']?.toString();
  }

  Future<bool> pushRecordings({bool pushOnly = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastSynced = prefs.getString('last_recordings_sync');

    try {
      final unsynced = await (_db.select(_db.lessonRecordings)..where((t) => t.syncedWithCloud.equals(0))).get();
      final List<Map<String, dynamic>> payload = [];

      for (var row in unsynced) {
        final notebookRow = await (_db.select(_db.notebooks)..where((t) => t.id.equals(row.notebookId))).getSingleOrNull();
        if (notebookRow?.serverId == null) continue;

        String audioUrl = row.audioUrl;
        if (!kIsWeb && !audioUrl.startsWith('http')) {
          final file = io.File(audioUrl);
          if (await file.exists()) {
            final bytes = await file.readAsBytes();
            final remoteUrl = await _canvasRepository.uploadLessonAudio(notebookRow!.serverId!, 'lesson_${row.clientId}.m4a', bytes, title: row.title, duration: row.durationSeconds, clientId: row.clientId);
            if (remoteUrl != null) audioUrl = remoteUrl; else continue;
          }
        }
        payload.add({'notebook_id': notebookRow!.serverId, 'client_id': row.clientId, 'title': row.title, 'audio_url': audioUrl, 'duration_seconds': row.durationSeconds, 'updated_at': row.updatedAt});
      }

      final response = await _apiService.post('/sync/recordings/push', {
        'recordings': payload,
        'last_synced_at': lastSynced,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        // 1. Confirmações
        for (var item in data['synced_recordings'] ?? []) {
          final String clientUuid = item['client_id'].toString();
          final int sId = item['id'] ?? item['server_id'];
          final int serverTime = _parseSafeInt(item['updated_at_ms']) ?? _parseSafeInt(item['updated_at']) ?? TimeService().nowMs();
          
          await (_db.update(_db.lessonRecordings)..where((t) => t.clientId.equals(clientUuid))).write(
            LessonRecordingsCompanion(serverId: Value(sId), audioUrl: Value(item['audio_url']), syncedWithCloud: const Value(1), updatedAt: Value(serverTime))
          );
        }

        // 2. Updates do Servidor (Pular se pushOnly)
        if (!pushOnly) {
          final List updates = data['server_updates'] ?? [];
          if (updates.isNotEmpty) {
             await _applyRecordingUpdates(updates);
          }

          if (data['meta'] != null && data['meta']['server_time'] != null) {
             await prefs.setString('last_recordings_sync', data['meta']['server_time']);
          }
        }
        return data['has_more'] == true;
      }
      return false;
    } catch (e) {
      debugPrint('🚨 [Sync-Recordings] Erro: $e');
      return false;
    }
  }

  Future<void> _applyRecordingUpdates(List updates) async {
    final allNotebooks = await _db.select(_db.notebooks).get();
    final Map<int, int> serverToLocalNotebookId = {for (var n in allNotebooks) if (n.serverId != null) n.serverId!: n.id};

    await _db.batch((batch) {
      for (var rec in updates) {
        final int? localNbId = serverToLocalNotebookId[rec['notebook_id']];
        if (localNbId == null) continue;
        
        batch.insert(_db.lessonRecordings, 
          LessonRecordingsCompanion.insert(
            serverId: Value(rec['id']), 
            clientId: Value(rec['client_id'] ?? const Uuid().v4()), 
            notebookId: localNbId, 
            title: rec['title'] ?? 'Sem título', 
            audioUrl: rec['audio_url'] ?? '', 
            durationSeconds: Value(rec['duration_seconds'] ?? 0), 
            syncedWithCloud: const Value(1), 
            updatedAt: Value(_parseSafeInt(rec['updated_at_ms']) ?? 0)
          ), 
          mode: InsertMode.insertOrReplace
        );
      }
    });
  }

  Future<void> pullRecordings() async {
    // PULL explícito mantido para gravações pois são ficheiros grandes e fluxo diferente
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
      // 🚀 OTIMIZAÇÃO: Servidor simplifica os traços, App envia dados puros para poupar CPU
      payload['notebook_id'] = notebookServerId;
      payload['sender_id'] = myUserId;
      if (page.serverId == null) payload['is_new_page'] = true;
      final response = await _apiService.post('/sync/realtime/update', {'page': payload});
      return response.statusCode == 200;
    } catch (e) { return false; }
  }
}
