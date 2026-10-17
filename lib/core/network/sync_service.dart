import 'dart:convert';
import 'dart:io' as io;
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/config/app_config.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

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
  final Set<String> _activePullUrls =
      {}; // 🚀 Previne PULLs simultâneos idênticos
  final Set<String> _activePushNotebookKeys =
      {}; // 🚀 Previne PUSHs simultâneos do mesmo caderno

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
    if (meta['server_time_ms'] != null)
      return meta['server_time_ms'].toString();
    return null;
  }

  void _prewarmBackgroundImage(Map<String, dynamic> pageData) {
    if (!kIsWeb) {
      final bgPath =
          pageData['background_pdf_path']?.toString() ??
          pageData['background_image_path']?.toString();
      if (bgPath != null && bgPath.startsWith('http')) {
        try {
          DefaultCacheManager().downloadFile(bgPath);
        } catch (_) {
          // Ignora o erro silenciosamente se a cache falhar
        }
      }
    }
  }

  /// 🚀 Retorna o timestamp ISO do lastSynced recuado com uma janela de segurança (Safety Buffer)
  /// para tolerar pequenas diferenças de relógio entre dispositivos e atrasos de rede.
  String? _getBufferedLastSynced(String? rawLastSynced) {
    if (rawLastSynced == null || rawLastSynced.isEmpty) return null;
    try {
      final dt = DateTime.parse(rawLastSynced);
      // 🚀 OTIMIZAÇÃO: Sem subtração de tempo. O TimeService já garante a precisão do relógio.
      // O buffer estava a causar um re-download infinito porque o PULL procurava sempre páginas
      // 2 minutos antes, re-encontrando as páginas que tinham acabado de ser enviadas no PUSH!
      return dt.toUtc().toIso8601String();
    } catch (e) {
      return rawLastSynced;
    }
  }

  // =========================================================================
  // 1. SINCRONIZAÇÃO TOTAL
  // =========================================================================
  Future<void> syncAll({ bool forced = false, bool metadataOnly = false, bool pushOnly = false, }) async {
    if (_isGlobalSyncing && !forced) {
      AppLog.sync('⏳ [Sync] Ignorado: Já existe um ciclo em curso.');
      return;
    }

    if (isCollaborationActive && !forced) return;

    _isGlobalSyncing = true;
    AppLog.sync('🔄 [Sync] Sincronização híbrida iniciada... ${pushOnly ? "(Apenas PUSH)" : ""}');

    try {
      // 1. Tentar Enviar Novidades (E receber deltas rápidos no retorno)
      final bool hasMoreSubjects = await pushOfflineSubjects(
        pushOnly: pushOnly,
      );
      final bool hasMoreNotebooks = await pushNotebooks(pushOnly: pushOnly);

      // 2. Recuperação de Lotes (Apenas se PUSH indicou que há muito mais dados em lote ou forced)
      if (!pushOnly) {
        if (hasMoreSubjects) await pullSubjects();
        if (hasMoreNotebooks) await pullNotebooks();
      }

      if (!metadataOnly) {
        await pushPages(pushOnly: pushOnly);
        if (!pushOnly) {
          await pullPages(); // 🚀 FIX DEFINITIVO: Não passar forceFull: forced! Mantém sempre o last_synced_at para evitar o re-download desnecessário de 50+ páginas!
        }
        final bool hasMoreRecs = await pushRecordings(pushOnly: pushOnly);
        if (!pushOnly && hasMoreRecs) {
          await pullRecordings();
        }
      }
      AppLog.sync('✅ [Sync] Ciclo híbrido concluído.');
    } catch (e) {
      AppLog.sync('🚨 [Sync General] Falha: $e');
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
    final String? lastSynced = _getBufferedLastSynced(
      prefs.getString('last_subjects_sync'),
    );

    try {
      final unsynced = await (_db.select(
        _db.subjects,
      )..where((t) => t.syncedWithCloud.equals(0))).get();
      final List<Map<String, dynamic>> payload = [];
      for (var s in unsynced) {
        String effectiveUuid = s.clientId ?? uniqid();
        if (s.clientId == null) {
          await (_db.update(_db.subjects)..where((t) => t.id.equals(s.id)))
              .write(SubjectsCompanion(clientId: Value(effectiveUuid)));
        }
        final subjectObj = subjects_model.Subject(
          id: s.id,
          serverId: s.serverId,
          clientId: effectiveUuid,
          userId: s.userId,
          name: s.name,
          color: s.color,
          icon: s.icon,
          isDeleted: s.isDeleted,
          syncedWithCloud: s.syncedWithCloud,
          updatedAt: s.updatedAt,
        );
        payload.add(subjectObj.toJson());
      }

      if (payload.isNotEmpty) {
        AppLog.sync('🛫 [Sync-Push] Enviando ${payload.length} disciplinas: ${payload.map((s) => '${s['name']}(del:${s['is_deleted']})').join(', ')}');
      }

      final response = await _apiService.post('/sync/push', {
        'subjects': payload,
        'last_synced_at': lastSynced,
      }, compress: true);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // 1. Processar confirmações do PUSH
        for (var item in data['synced_subjects'] ?? []) {
          final String clientUuid = item['client_id'].toString();
          final int? serverId = item['id'] ?? item['server_id'];
          final int serverTime =
              _parseSafeInt(item['updated_at_ms']) ??
              _parseSafeInt(item['updated_at']) ??
              TimeService().nowMs();

          if (serverId != null) {
            await (_db.update(
              _db.subjects,
            )..where((t) => t.clientId.equals(clientUuid))).write(
              SubjectsCompanion(
                serverId: Value(serverId),
                updatedAt: Value(serverTime),
                syncedWithCloud: const Value(1),
              ),
            );
          } else {
            // Se o servidor confirmou mas não enviou ID (ex: já estava apagado), apenas marcamos como sincronizado
            await (_db.update(_db.subjects)
                  ..where((t) => t.clientId.equals(clientUuid)))
                .write(const SubjectsCompanion(syncedWithCloud: Value(1)));
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
      AppLog.sync('🚨 Erro Sync Subjects: $e');
      return false;
    }
  }

  Future<void> _applySubjectUpdates(List updates) async {
    final userQuery =
        await (_db.select(_db.users)
              ..orderBy([(t) => OrderingTerm(expression: t.id)])
              ..limit(1))
            .get();
    if (userQuery.isEmpty) return;
    final int localUserId = userQuery.first.id;

    await _db.transaction(() async {
      for (var sub in updates) {
        final int? sId = sub['id'] ?? sub['server_id'];
        if (sId == null) continue;

        final String cId = sub['client_id'] ?? uniqid();
        final int serverTime =
            _parseSafeInt(sub['updated_at_ms']) ??
            _parseSafeInt(sub['updated_at']) ??
            0;

        final companion = SubjectsCompanion.insert(
          serverId: Value(sId),
          clientId: Value(cId),
          userId: localUserId,
          name: sub['name'] ?? '',
          color: sub['color'] ?? '#0F4C5C',
          icon: Value(sub['icon']),
          isDeleted: Value(sub['deleted_at'] != null ? 1 : 0),
          syncedWithCloud: const Value(1),
          updatedAt: Value(serverTime),
          isArchived: Value(
            sub['is_archived'] == 1 || sub['is_archived'] == true ? 1 : 0,
          ),
          isFavorite: Value(
            sub['is_favorite'] == 1 || sub['is_favorite'] == true ? 1 : 0,
          ),
        );

        final existing = await (_db.select(
          _db.subjects,
        )..where((t) => t.clientId.equals(cId))).getSingleOrNull();
        if (existing != null) {
          // 🚀 PRIORIDADE PARA ELIMINAÇÃO: Se o servidor diz que foi apagado, marcamos localmente
          // mesmo que o timestamp pareça idêntico, para evitar "ressurreição" de itens.
          final bool serverSaysDeleted = sub['deleted_at'] != null;

          if (serverSaysDeleted || serverTime > existing.updatedAt) {
            await (_db.update(
              _db.subjects,
            )..where((t) => t.id.equals(existing.id))).write(companion);
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
    final String? lastSynced = localCount > 0
        ? _getBufferedLastSynced(prefs.getString('last_subjects_sync'))
        : null;
    try {
      String? nextUrl = lastSynced != null
          ? '/sync/pull?last_synced_at=$lastSynced'
          : '/sync/pull';
      bool anyChanges = false;
      while (nextUrl != null) {
        final response = await _apiService.get(nextUrl);
        if (response.statusCode == 200) {
          final dynamic decoded = await compute<String, dynamic>(
            (jsonStr) => jsonDecode(jsonStr),
            response.body,
          );
          final Map<String, dynamic> responseData = decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : {'data': decoded};
          final List serverSubjects =
              responseData['data'] ?? responseData['subjects'] ?? [];
          final String? serverTime = _parseMetaTime(responseData['meta']);
          if (serverTime != null)
            await prefs.setString('last_subjects_sync', serverTime);
          if (serverSubjects.isNotEmpty) {
            anyChanges = true;
            final userQuery =
                await (_db.select(_db.users)
                      ..orderBy([(t) => OrderingTerm(expression: t.id)])
                      ..limit(1))
                    .get();
            if (userQuery.isEmpty) return false;
            final int localUserId = userQuery.first.id;
            await _db.transaction(() async {
              for (var sub in serverSubjects) {
                final int? sId = sub['id'] is int
                    ? sub['id']
                    : int.tryParse(sub['id']?.toString() ?? '');
                if (sId == null) continue;

                final String? cId = sub['client_id']?.toString();
                final int serverTime = sub['updated_at_ms'] != null
                    ? (sub['updated_at_ms'] as num).toInt()
                    : (sub['updated_at'] != null
                          ? DateTime.parse(
                              sub['updated_at'].toString(),
                            ).millisecondsSinceEpoch
                          : 0);
                final companion = SubjectsCompanion.insert(
                  serverId: Value(sId),
                  clientId: Value(cId ?? uniqid()),
                  userId: localUserId,
                  name: sub['name'] ?? '',
                  color: sub['color'] ?? '#0F4C5C',
                  icon: Value(sub['icon']),
                  isDeleted: Value(sub['deleted_at'] != null ? 1 : 0),
                  syncedWithCloud: const Value(1),
                  updatedAt: Value(serverTime),
                  isArchived: Value(
                    sub['is_archived'] == 1 || sub['is_archived'] == true
                        ? 1
                        : 0,
                  ),
                  isFavorite: Value(
                    sub['is_favorite'] == 1 || sub['is_favorite'] == true
                        ? 1
                        : 0,
                  ),
                );
                final existing =
                    await (_db.select(_db.subjects)
                          ..where((t) => t.clientId.equals(cId ?? '')))
                        .getSingleOrNull();
                if (existing != null) {
                  if (serverTime > existing.updatedAt) {
                    await (_db.update(
                      _db.subjects,
                    )..where((t) => t.id.equals(existing.id))).write(
                      SubjectsCompanion(
                        serverId: companion.serverId,
                        name: companion.name,
                        color: companion.color,
                        icon: companion.icon,
                        isDeleted: companion.isDeleted,
                        syncedWithCloud: companion.syncedWithCloud,
                        updatedAt: companion.updatedAt,
                      ),
                    );
                  }
                } else {
                  final existingByServerId = await (_db.select(
                    _db.subjects,
                  )..where((t) => t.serverId.equals(sId))).getSingleOrNull();
                  if (existingByServerId != null) {
                    if (serverTime > existingByServerId.updatedAt)
                      await (_db.update(_db.subjects)
                            ..where((t) => t.id.equals(existingByServerId.id)))
                          .write(companion);
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
      AppLog.sync('🚨 Erro PULL Subjects: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 3. CADERNOS (NOTEBOOKS)
  // =========================================================================
  Future<bool> pushNotebooks({bool pushOnly = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastSynced = _getBufferedLastSynced(
      prefs.getString('last_notebooks_sync'),
    );

    try {
      final unsynced = await (_db.select(
        _db.notebooks,
      )..where((t) => t.syncedWithCloud.equals(0))).get();
      final List<Map<String, dynamic>> payload = [];
      for (var row in unsynced) {
        String effectiveUuid = row.clientId ?? uniqid();
        if (row.clientId == null)
          await (_db.update(_db.notebooks)..where((t) => t.id.equals(row.id)))
              .write(NotebooksCompanion(clientId: Value(effectiveUuid)));
        int? cloudSubId;
        if (row.subjectId != null) {
          final sub = await (_db.select(
            _db.subjects,
          )..where((t) => t.id.equals(row.subjectId!))).getSingleOrNull();
          if (sub != null && sub.serverId != null) cloudSubId = sub.serverId;
        }
        final notebookObj = notebooks_model.Notebook(
          id: row.id,
          serverId: row.serverId,
          clientId: effectiveUuid,
          subjectId: cloudSubId,
          title: row.title,
          coverType: row.coverType,
          color: row.color,
          coverImage: row.coverImage,
          templateType: row.templateType,
          collaborationMode: row.collaborationMode,
          isPublished: row.isPublished,
          price: row.price,
          description: row.description,
          authorName: row.authorName,
          syncedWithCloud: row.syncedWithCloud,
          isDeleted: row.isDeleted,
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
      }, compress: true);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // 1. Confirmações
        for (var item in data['synced_notebooks'] ?? []) {
          final String clientUuid = item['client_id'].toString();
          final int? sId = item['id'] ?? item['server_id'];
          final localRow = await (_db.select(
            _db.notebooks,
          )..where((t) => t.clientId.equals(clientUuid))).getSingleOrNull();
          if (localRow == null) continue;

          if (sId != null) {
            final existing =
                await (_db.select(_db.notebooks)..where(
                      (t) =>
                          t.serverId.equals(sId) &
                          t.id.equals(localRow.id).not(),
                    ))
                    .getSingleOrNull();
            if (existing != null) {
              await (_db.delete(
                _db.notebooks,
              )..where((t) => t.id.equals(localRow.id))).go();
            } else {
              final int serverTime =
                  _parseSafeInt(item['updated_at_ms']) ??
                  _parseSafeInt(item['updated_at']) ??
                  TimeService().nowMs();
              await (_db.update(
                _db.notebooks,
              )..where((t) => t.id.equals(localRow.id))).write(
                NotebooksCompanion(
                  serverId: Value(sId),
                  updatedAt: Value(serverTime),
                  syncedWithCloud: const Value(1),
                ),
              );
            }
          } else {
            // Confirmação sem ID (ex: apagado no servidor)
            await (_db.update(_db.notebooks)
                  ..where((t) => t.id.equals(localRow.id)))
                .write(const NotebooksCompanion(syncedWithCloud: Value(1)));
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
      AppLog.sync('🚨 Erro Sync Notebooks: $e');
      return false;
    }
  }

  Future<void> _applyNotebookUpdates(List updates) async {
    final userQuery =
        await (_db.select(_db.users)
              ..orderBy([(t) => OrderingTerm(expression: t.id)])
              ..limit(1))
            .get();
    final int currentUserId = userQuery.isNotEmpty ? userQuery.first.id : 0;
    final allSubjects = await _db.select(_db.subjects).get();
    final Map<int, int> subjectIdMap = {
      for (var s in allSubjects)
        if (s.serverId != null) s.serverId!: s.id,
    };

    await _db.transaction(() async {
      for (var net in updates) {
        final int? sId = net['id'] is int
            ? net['id']
            : int.tryParse(net['id']?.toString() ?? '');
        if (sId == null) continue;

        final String? cId = net['client_id'];
        final int? serverSubId = net['subject_id'] != null
            ? int.tryParse(net['subject_id'].toString())
            : null;
        final int? localSubId = (serverSubId != null)
            ? subjectIdMap[serverSubId]
            : null;
        final int serverTime =
            _parseSafeInt(net['updated_at_ms']) ??
            _parseSafeInt(net['updated_at']) ??
            0;

        final companion = NotebooksCompanion.insert(
          serverId: Value(sId),
          clientId: Value(cId ?? uniqid()),
          subjectId: Value(localSubId),
          title: net['title'] ?? '',
          coverType: net['cover_type'] ?? 'color',
          color: Value(net['color']),
          coverImage: Value(net['cover_image']),
          templateType: Value(net['template_type'] ?? 'study'),
          collaborationMode: Value(net['collaboration_mode'] ?? 'study_group'),
          isPublished: Value(
            int.tryParse(net['is_published']?.toString() ?? '0') ?? 0,
          ),
          price: Value(
            double.tryParse(net['price']?.toString() ?? '0.0') ?? 0.0,
          ),
          isDeleted: Value(net['deleted_at'] != null ? 1 : 0),
          syncedWithCloud: const Value(1),
          updatedAt: Value(serverTime),
          role: Value(net['role'] ?? 'viewer'),
          alternativeTitle: Value(net['alternative_title']),
          sharingType: Value(net['sharing_type'] ?? 'full'),
          isArchived: Value(
            net['is_archived'] == 1 || net['is_archived'] == true ? 1 : 0,
          ),
          isFavorite: Value(
            net['is_favorite'] == 1 || net['is_favorite'] == true ? 1 : 0,
          ),
          origin: Value(net['origin']),
          lastUpdatedByName: Value(net['last_updated_by_name']),
          notificationsEnabled: Value(
            (net['notifications_enabled'] == 1 ||
                    net['notifications_enabled'] == true)
                ? 1
                : 0,
          ),
          participantsPreview: Value(
            net['participants_preview'] != null
                ? jsonEncode(net['participants_preview'])
                : null,
          ),
        );

        final existing = await (_db.select(
          _db.notebooks,
        )..where((t) => t.clientId.equals(cId ?? ''))).getSingleOrNull();
        if (existing != null) {
          if (serverTime >= existing.updatedAt) {
            await (_db.update(
              _db.notebooks,
            )..where((t) => t.id.equals(existing.id))).write(companion);
          }
        } else {
          await _db.into(_db.notebooks).insertOnConflictUpdate(companion);
        }

        // 🚀 NOVIDADE: Atualizar também a tabela de pivô para cadernos partilhados (Visibilidade imediata)
        final localNb = await (_db.select(
          _db.notebooks,
        )..where((t) => t.serverId.equals(sId))).getSingleOrNull();
        final String? role = net['role']?.toString();
        if (localNb != null && currentUserId > 0 && role != null) {
          if (role != 'owner') {
            await _db
                .into(_db.notebookUser)
                .insertOnConflictUpdate(
                  NotebookUserCompanion.insert(
                    notebookId: localNb.id,
                    userId: currentUserId,
                    role: Value(role),
                    syncedWithCloud: const Value(1),
                    updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
                    isArchived: Value(
                      net['is_archived'] == 1 || net['is_archived'] == true
                          ? 1
                          : 0,
                    ),
                    isFavorite: Value(
                      net['is_favorite'] == 1 || net['is_favorite'] == true
                          ? 1
                          : 0,
                    ),
                  ),
                );
          } else {
            // Se agora sou dono (raro em update, mas possível), remover do pivô de partilhas
            await (_db.delete(_db.notebookUser)..where(
                  (t) =>
                      t.notebookId.equals(localNb.id) &
                      t.userId.equals(currentUserId),
                ))
                .go();
          }
        }
      }
    });
  }

  Future<bool> pullNotebooks() async {
    final prefs = await SharedPreferences.getInstance();
    final localCount = await _db.notebooks.count().getSingle();
    final String? lastSynced = localCount > 0
        ? _getBufferedLastSynced(prefs.getString('last_notebooks_sync'))
        : null;
    try {
      String? nextUrl = lastSynced != null
          ? '/sync/notebooks/pull?last_synced_at=$lastSynced'
          : '/sync/notebooks/pull';
      bool anyChanges = false;
      final Set<int> receivedServerIds = {};
      while (nextUrl != null) {
        final response = await _apiService.get(nextUrl);
        if (response.statusCode == 200) {
          final dynamic decoded = await compute<String, dynamic>(
            (jsonStr) => jsonDecode(jsonStr),
            response.body,
          );
          final Map<String, dynamic> responseData = decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : {'data': decoded};
          final List serverNotebooks =
              responseData['data'] ?? responseData['notebooks'] ?? [];
          final String? serverTime = _parseMetaTime(responseData['meta']);
          if (serverTime != null)
            await prefs.setString('last_notebooks_sync', serverTime);
          if (serverNotebooks.isNotEmpty) {
            anyChanges = true;
            final userQuery =
                await (_db.select(_db.users)
                      ..orderBy([(t) => OrderingTerm(expression: t.id)])
                      ..limit(1))
                    .get();
            final int currentUserId = userQuery.isNotEmpty
                ? userQuery.first.id
                : 0;
            final allSubjects = await _db.select(_db.subjects).get();
            final Map<int, int> subjectIdMap = {
              for (var s in allSubjects)
                if (s.serverId != null) s.serverId!: s.id,
            };
            await _db.transaction(() async {
              for (var net in serverNotebooks) {
                final int? sId = net['id'] is int
                    ? net['id']
                    : int.tryParse(net['id']?.toString() ?? '');
                if (sId == null) continue;

                receivedServerIds.add(sId);
                final String? cId = net['client_id']?.toString();
                final int? serverSubId = net['subject_id'] != null
                    ? (net['subject_id'] is int
                          ? net['subject_id']
                          : int.parse(net['subject_id'].toString()))
                    : null;
                final int? localSubId = (serverSubId != null)
                    ? subjectIdMap[serverSubId]
                    : null;
                final int serverTime = net['updated_at_ms'] != null
                    ? (net['updated_at_ms'] as num).toInt()
                    : (net['updated_at'] != null
                          ? DateTime.parse(
                              net['updated_at'].toString(),
                            ).millisecondsSinceEpoch
                          : 0);
                final String serverRole = net['role']?.toString() ?? 'viewer';

                final companion = NotebooksCompanion.insert(
                  serverId: Value(sId),
                  clientId: Value(cId ?? uniqid()),
                  subjectId: Value(localSubId),
                  title: net['title'] ?? '',
                  coverType: net['cover_type'] ?? 'color',
                  color: net['color'] != null
                      ? Value(net['color'])
                      : const Value.absent(),
                  coverImage: Value(net['cover_image']),
                  templateType: Value(net['template_type'] ?? 'study'),
                  collaborationMode: Value(
                    net['collaboration_mode'] ?? 'study_group',
                  ),
                  isPublished: Value(
                    int.tryParse(net['is_published']?.toString() ?? '0') ?? 0,
                  ),
                  price: Value(
                    double.tryParse(net['price']?.toString() ?? '0.0') ?? 0.0,
                  ),
                  description: Value(net['description']),
                  authorName: Value(net['author_name']),
                  isDeleted: Value(net['deleted_at'] != null ? 1 : 0),
                  syncedWithCloud: const Value(1),
                  updatedAt: Value(serverTime),
                  role: Value(serverRole),
                  alternativeTitle: Value(net['alternative_title']),
                  sharingType: Value(net['sharing_type'] ?? 'full'),
                  isArchived: Value(
                    net['is_archived'] == 1 || net['is_archived'] == true
                        ? 1
                        : 0,
                  ),
                  isFavorite: Value(
                    net['is_favorite'] == 1 || net['is_favorite'] == true
                        ? 1
                        : 0,
                  ),
                  origin: Value(net['origin']),
                  lastUpdatedByName: Value(net['last_updated_by_name']),
                  notificationsEnabled: Value(
                    (net['notifications_enabled'] == 1 ||
                            net['notifications_enabled'] == true)
                        ? 1
                        : 0,
                  ),
                  participantsPreview: Value(
                    net['participants_preview'] != null
                        ? jsonEncode(net['participants_preview'])
                        : null,
                  ),
                );

                final existing =
                    await (_db.select(_db.notebooks)
                          ..where((t) => t.clientId.equals(cId ?? '')))
                        .getSingleOrNull();
                if (existing != null) {
                  final bool isBeingDeleted = net['deleted_at'] != null;
                  if (isBeingDeleted) {
                    final unsynced =
                        await (_db.select(_db.pages)..where(
                              (t) =>
                                  t.notebookId.equals(existing.id) &
                                  t.syncedWithCloud.equals(0),
                            ))
                            .get();
                    if (unsynced.isEmpty) {
                      await (_db.delete(
                        _db.notebooks,
                      )..where((t) => t.id.equals(existing.id))).go();
                      continue;
                    } else {
                      await (_db.update(
                        _db.notebooks,
                      )..where((t) => t.id.equals(existing.id))).write(
                        NotebooksCompanion(
                          serverId: const Value(null),
                          clientId: Value(const Uuid().v4()),
                          syncedWithCloud: const Value(0),
                        ),
                      );
                      continue;
                    }
                  }

                  if (serverTime >= existing.updatedAt) {
                    await (_db.update(
                      _db.notebooks,
                    )..where((t) => t.id.equals(existing.id))).write(
                      NotebooksCompanion(
                        serverId: companion.serverId,
                        subjectId: companion.subjectId,
                        title: companion.title,
                        coverType: companion.coverType,
                        color: net['color'] != null
                            ? Value(net['color'])
                            : const Value.absent(),
                        coverImage: companion.coverImage,
                        templateType: companion.templateType,
                        collaborationMode: companion.collaborationMode,
                        isPublished: companion.isPublished,
                        price: companion.price,
                        description: companion.description,
                        authorName: companion.authorName,
                        isDeleted: companion.isDeleted,
                        syncedWithCloud: companion.syncedWithCloud,
                        updatedAt: Value(serverTime),
                        role: companion.role,
                        alternativeTitle: companion.alternativeTitle,
                        sharingType: companion.sharingType,
                        origin: companion.origin,
                        lastUpdatedByName: companion.lastUpdatedByName,
                        notificationsEnabled: companion.notificationsEnabled,
                        participantsPreview: companion.participantsPreview,
                      ),
                    );
                  }
                } else {
                  final existingByServerId = await (_db.select(
                    _db.notebooks,
                  )..where((t) => t.serverId.equals(sId))).getSingleOrNull();
                  if (existingByServerId != null) {
                    if (serverTime >= existingByServerId.updatedAt)
                      await (_db.update(_db.notebooks)
                            ..where((t) => t.id.equals(existingByServerId.id)))
                          .write(companion);
                  } else {
                    await _db.into(_db.notebooks).insert(companion);
                  }
                }
              }
            });
            final allNotebooksAfter = await _db.select(_db.notebooks).get();
            final Map<int, int> notebookIdMap = {
              for (var n in allNotebooksAfter)
                if (n.serverId != null) n.serverId!: n.id,
            };
            await _db.batch((batch) {
              for (var net in serverNotebooks) {
                final sId = net['id'];
                final localNbId = notebookIdMap[sId];
                final String? role = net['role']?.toString();
                if (localNbId != null &&
                    currentUserId > 0 &&
                    role != null &&
                    role != 'owner') {
                  batch.insert(
                    _db.notebookUser,
                    NotebookUserCompanion.insert(
                      notebookId: localNbId,
                      userId: currentUserId,
                      role: Value(role),
                      syncedWithCloud: const Value(1),
                      updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
                      isArchived: Value(
                        net['is_archived'] == 1 || net['is_archived'] == true
                            ? 1
                            : 0,
                      ),
                      isFavorite: Value(
                        net['is_favorite'] == 1 || net['is_favorite'] == true
                            ? 1
                            : 0,
                      ),
                    ),
                    mode: InsertMode.insertOrReplace,
                  );
                } else if (localNbId != null &&
                    currentUserId > 0 &&
                    role == 'owner') {
                  batch.deleteWhere(
                    _db.notebookUser,
                    (t) =>
                        t.notebookId.equals(localNbId) &
                        t.userId.equals(currentUserId),
                  );
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
        final allLocalShared =
            await (_db.select(_db.notebooks)..where(
                  (t) => t.role.isNotValue('owner') & t.serverId.isNotNull(),
                ))
                .get();
        for (var localNb in allLocalShared) {
          if (localNb.serverId != null &&
              !receivedServerIds.contains(localNb.serverId!)) {
            await (_db.delete(
              _db.notebooks,
            )..where((t) => t.id.equals(localNb.id))).go();
          }
        }
      }
      return anyChanges;
    } catch (e) {
      AppLog.sync('🚨 Erro PULL Notebooks: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 4. PÁGINAS E CANVAS
  // =========================================================================
  Future<bool> pushPages({
    int? onlyNotebookId,
    int? onlyNotebookServerId,
    bool pushOnly = false,
  }) async {
    final pushKey =
        'push_${onlyNotebookId ?? 'all'}_${onlyNotebookServerId ?? 'all'}';
    if (_activePushNotebookKeys.contains(pushKey)) return false;
    _activePushNotebookKeys.add(pushKey);

    try {
      final prefs = await SharedPreferences.getInstance();
      final String? lastSynced = _getBufferedLastSynced(
        prefs.getString('last_pages_sync'),
      );

      // 🚀 Resolver ID local e ID do servidor do caderno
      int? targetLocalNbId = onlyNotebookId;
      int? targetServerNbId = onlyNotebookServerId;

      if (targetLocalNbId != null && targetServerNbId == null) {
        final localId = targetLocalNbId;
        final nb = await (_db.select(
          _db.notebooks,
        )..where((t) => t.id.equals(localId))).getSingleOrNull();
        targetServerNbId = nb?.serverId;
        if (targetServerNbId == null) {
          final nbByServer = await (_db.select(
            _db.notebooks,
          )..where((t) => t.serverId.equals(localId))).getSingleOrNull();
          if (nbByServer != null) {
            targetLocalNbId = nbByServer.id;
            targetServerNbId = nbByServer.serverId;
          }
        }
      } else if (targetServerNbId != null && targetLocalNbId == null) {
        final serverId = targetServerNbId;
        final nb = await (_db.select(
          _db.notebooks,
        )..where((t) => t.serverId.equals(serverId))).getSingleOrNull();
        targetLocalNbId = nb?.id;
      }

      final query = _db.select(_db.pages)
        ..where((t) => t.syncedWithCloud.equals(0));
      if (targetLocalNbId != null) {
        final localId = targetLocalNbId;
        query.where((t) => t.notebookId.equals(localId));
      }
      final unsyncedPages = await query.get();

      if (unsyncedPages.isEmpty) {
        if (pushOnly) return false;

        // PUSH leve com payload de páginas vazio para receber os deltas remotos no mesmo pedido
        final response = await _apiService.post('/sync/pages/push', {
          'pages': [],
          'last_synced_at': lastSynced,
          if (targetServerNbId != null) 'notebook_id': targetServerNbId,
        });

        if (response.statusCode == 200 || response.statusCode == 201) {
          final data = jsonDecode(response.body);
          final List updates = data['server_updates'] ?? [];
          final List<int> localIdsToPull = [];
          final Map<int, Map<String, dynamic>> serverDataForPull = {};

          for (var updData in updates) {
            try {
              final Map<String, dynamic> updMap = updData is Map
                  ? Map<String, dynamic>.from(updData)
                  : {};
              if (updMap.isEmpty) continue;
              final int sNbId = updMap['notebook_id'] is int
                  ? updMap['notebook_id']
                  : int.parse(updMap['notebook_id'].toString());
              final localId = await _canvasRepository.savePageFromMap(
                updMap,
                sNbId,
              );
              _prewarmBackgroundImage(
                updMap,
              ); // 🚀 OTIMIZAÇÃO: Caching em plano de fundo
              localIdsToPull.add(localId);
              serverDataForPull[localId] = updMap;
            } catch (e) {
              AppLog.sync('🚨 [Sync-Push-Empty] Erro ao processar update do servidor: $e');
            }
          }

          if (localIdsToPull.isNotEmpty) {
            await _pullCanvasDataBatch(localIdsToPull, serverDataForPull);
          }

          final String? serverTime = _parseMetaTime(data['meta']);
          if (serverTime != null) {
            await prefs.setString('last_pages_sync', serverTime);
          }
          return data['has_more'] == true;
        }
        return false;
      }

      AppLog.sync('🛫 [Sync-Push] Detectadas ${unsyncedPages.length} páginas pendentes: ${unsyncedPages.map((p) => 'p${p.pageNumber}(id:${p.id})').join(', ')}');
      unsyncedPages.sort((a, b) => b.isDeleted.compareTo(a.isDeleted));
      bool allSuccess = true;
      bool serverHasMore = false;

      // 🚀 OTIMIZAÇÃO: Enviar em lotes (Chunks) para reduzir overhead de rede sem travar
      // 🚀 OTIMIZAÇÃO: Lote maior para reordenações e cadernos grandes
      // 🚀 OTIMIZAÇÃO: Loteamento Adaptativo por Tamanho de Payload (Adaptive Payload Chunking)
      // Limite seguro: máximo de ~2.5 MB (2.5 * 1024 * 1024 bytes) ou no máximo 10 páginas por requisição HTTP.
      const int maxBatchBytes = 2500000;
      const int maxBatchPages = 10;

      int currentBatchBytes = 0;
      List<Map<String, dynamic>> currentBatchPayload = [];
      Map<String, int> sentPageTimestamps = {};

      Future<void> sendBatch(List<Map<String, dynamic>> batchPayload) async {
        if (batchPayload.isEmpty) return;
        try {
          AppLog.sync('🛫 [Sync-Push-Batch] Enviando lote adaptativo de ${batchPayload.length} páginas (${(jsonEncode(batchPayload).length / 1024).toStringAsFixed(1)} KB)...');
          var response = await _apiService.post('/sync/pages/push', {
            'pages': batchPayload,
            'last_synced_at': lastSynced, // 🚀 Delta bidirecional
          }, compress: true);

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = jsonDecode(response.body);
            if (data['has_more'] == true) serverHasMore = true;

            // 1. Processar Confirmações (Resultados do PUSH)
            final List syncedPages = data['synced_pages'] ?? [];
            final List<int> localIdsToPull = [];
            final Map<int, Map<String, dynamic>> serverDataForPull = {};

            for (var syncedPageData in syncedPages) {
              try {
                final Map<String, dynamic> syncedPageMap = syncedPageData is Map
                    ? Map<String, dynamic>.from(syncedPageData)
                    : {};

                if (syncedPageMap.isEmpty) continue;

                final String? cId = syncedPageMap['client_id'];
                if (cId == null) continue;

                final String? status = syncedPageMap['status']?.toString();
                final int? sentTs = sentPageTimestamps[cId];

                // 🚀 1. FASE DE CONFIRMAÇÃO DO PUSH (Livre de bloqueios de caderno local)
                final localPage = await (_db.select(_db.pages)
                      ..where((t) => t.clientId.equals(cId)))
                    .getSingleOrNull();

                if (localPage != null) {
                  // Se a página local ou remota foi apagada, purge físico imediato!
                  if (localPage.isDeleted == 1 ||
                      status == 'deleted' ||
                      status == 'already_deleted' ||
                      syncedPageMap['is_deleted'] == 1 ||
                      syncedPageMap['is_deleted'] == true) {
                    await _canvasRepository.purgePageCompletely(localPage.id);
                    continue;
                  }

                  // Marcar a página e todos os seus objetos/traços como sincronizados
                  await _markPageItemsAsSynced(localPage.id, sentTs: sentTs);
                  await (_db.update(_db.pages)
                        ..where((t) => t.id.equals(localPage.id)))
                      .write(const PagesCompanion(syncedWithCloud: Value(1)));
                  await _canvasRepository.purgeSyncedDeletedObjects(localPage.id);
                }

                if (pushOnly || (status != null && status.startsWith('ignored_'))) {
                  continue;
                }

                // 🚀 2. FASE DE DELTAS / ATUALIZAÇÕES DO SERVIDOR
                final int? sNbId = syncedPageMap['notebook_id'] != null
                    ? int.tryParse(syncedPageMap['notebook_id'].toString())
                    : null;

                int? localNbId;
                if (sNbId != null) {
                  var nbRow = await (_db.select(_db.notebooks)
                        ..where((t) => t.serverId.equals(sNbId)))
                      .getSingleOrNull();
                  nbRow ??= await (_db.select(_db.notebooks)
                        ..where((t) => t.id.equals(sNbId)))
                      .getSingleOrNull();
                  localNbId = nbRow?.id;
                }

                if (localNbId == null && sNbId != null) {
                  AppLog.sync('⚠️ [Sync] Updates ignorados: Caderno servidor $sNbId não encontrado localmente.');
                  continue;
                }

                int localId = localPage?.id ?? 0;
                if (localPage != null &&
                    localPage.syncedWithCloud == 0 &&
                    sentTs != null &&
                    localPage.updatedAt > sentTs) {
                  // A página foi editada localmente durante o upload. Preservamos o estado local.
                  if (syncedPageMap['id'] != null) {
                    await (_db.update(_db.pages)
                          ..where((t) => t.id.equals(localId)))
                        .write(PagesCompanion(serverId: Value(syncedPageMap['id'])));
                  }
                } else {
                  // 🚀 PREVENÇÃO DE LOOP: Se a página já está sincronizada e não tem deltas novos,
                  // evitamos regravar para não resetar o syncedWithCloud para 0 no SQLite!
                  if (localPage == null || syncedPageMap['_sync_status'] != 'already_current') {
                    localId = await _canvasRepository.savePageFromMap(
                      syncedPageMap,
                      sNbId,
                    );
                    _prewarmBackgroundImage(syncedPageMap);
                  }
                }

                if (syncedPageMap['_sync_status'] != 'already_current') {
                  localIdsToPull.add(localId);
                  serverDataForPull[localId] = syncedPageMap;
                }
              } catch (e) {
                AppLog.sync('🚨 [Sync-Push-Batch] Erro ao processar confirmação de página: $e');
              }
            }

            // 2. Processar Novidades do Servidor (Resultados do PULL) - Pular se pushOnly
            if (!pushOnly) {
              final List updates = data['server_updates'] ?? [];
              for (var updData in updates) {
                try {
                  final Map<String, dynamic> updMap = updData is Map
                      ? Map<String, dynamic>.from(updData)
                      : {};
                  if (updMap.isEmpty) continue;

                  final int sNbId = updMap['notebook_id'] is int
                      ? updMap['notebook_id']
                      : int.parse(updMap['notebook_id'].toString());

                  // 🚀 PREVENÇÃO DE FANTASMAS (Phase 2): Se a folha vem no array de updates como apagada,
                  // ou se ELA JÁ ESTÁ MARCADA COMO APAGADA LOCALMENTE (isDeleted == 1),
                  // expurgamos localmente (se existir) e NUNCA inserimos de volta nem processamos updates!
                  final bool isUpdDeleted = updMap['is_deleted'] == 1 || updMap['is_deleted'] == true || updMap['deleted_at'] != null;
                  final String? updCId = updMap['client_id'];
                  if (updCId != null) {
                    final existingGhost = await (_db.select(_db.pages)..where((t) => t.clientId.equals(updCId))).getSingleOrNull();
                    if (isUpdDeleted || (existingGhost != null && existingGhost.isDeleted == 1)) {
                      if (existingGhost != null) {
                        await _canvasRepository.purgePageCompletely(existingGhost.id);
                      }
                      continue;
                    }
                  }

                  final localId = await _canvasRepository.savePageFromMap(
                    updMap,
                    sNbId,
                  );
                  _prewarmBackgroundImage(
                    updMap,
                  ); // 🚀 OTIMIZAÇÃO: Caching em plano de fundo
                  localIdsToPull.add(localId);
                  serverDataForPull[localId] = updMap;
                } catch (e) {
                  AppLog.sync('🚨 [Sync-Push-Batch] Erro ao processar update do servidor: $e');
                }
              }

              if (localIdsToPull.isNotEmpty) {
                await _pullCanvasDataBatch(localIdsToPull, serverDataForPull);
              }

              final String? serverTime = _parseMetaTime(data['meta']);
              if (serverTime != null) {
                await prefs.setString('last_pages_sync', serverTime);
              }
            }

            // 🚀 SALVAGUARDA ANTI-LOOP: Marcar como sincronizadas todas as páginas enviadas no lote
            for (var batchItem in batchPayload) {
              try {
                final String? sentCId = batchItem['client_id']?.toString();
                if (sentCId == null) continue;
                final localPage = await (_db.select(
                  _db.pages,
                )..where((t) => t.clientId.equals(sentCId))).getSingleOrNull();
                if (localPage != null) {
                  if (localPage.isDeleted == 1) {
                    await _canvasRepository.purgePageCompletely(localPage.id);
                  } else if (localPage.syncedWithCloud == 0) {
                    await _markPageItemsAsSynced(localPage.id);
                    await (_db.update(_db.pages)..where((t) => t.id.equals(localPage.id)))
                        .write(const PagesCompanion(syncedWithCloud: Value(1)));
                  }
                } else {
                  // Se localPage == null e o batchItem era de is_deleted == 1, significa
                  // que a Fase 1 da confirmação já fez o purgeCompletely!
                  // Não fazemos nada.
                }
              } catch (e) {
                 AppLog.sync('🚨 [Sync-Push-Batch] Erro fatal ao purgar página local: $e');
              }
            }

            AppLog.sync('✅ [Sync-Push-Batch] Lote processado. Mais dados no servidor: $serverHasMore');
          } else {
            allSuccess = false;
          }
        } catch (e) {
          AppLog.sync('🚨 [Sync-Push-Batch] Erro no lote: $e');
          allSuccess = false;
          rethrow; // 🚀 Aborta o push em caso de falha de rede para não perder o lote
        }
      }

      for (var row in unsyncedPages) {
        final notebook = await (_db.select(
          _db.notebooks,
        )..where((t) => t.id.equals(row.notebookId))).getSingleOrNull();
        if (notebook == null || notebook.serverId == null) continue;

        final String? cId = row.clientId;
        if (cId == null) continue;

        Map<String, dynamic> pageMap;

        // 🚀 OTIMIZAÇÃO E ANTI-GHOST: Se a página foi apagada localmente, 
        // não perdemos tempo a carregar os traços do repositório (que podem dar erro/ser nulos), 
        // mas IMPORTANTE: Não incluímos no batch se ela já não existir no servidor (serverId null).
        // Se ela só existe no telemóvel e já foi apagada, basta limpar localmente sem gastar rede!
        if (row.isDeleted == 1) {
          if (row.serverId == null) {
             await _canvasRepository.purgePageCompletely(row.id);
             continue;
          }
          pageMap = {
            'id': row.serverId,
            'client_id': cId,
            'notebook_id': notebook.serverId,
            'is_deleted': 1,
            'page_number': row.pageNumber,
            'synced_with_cloud': 0,
          };
        } else {
          final fullPage = await _canvasRepository.getPageByClientId(
            cId,
            onlyUnsynced: true,
          );
          if (fullPage == null) continue;

          pageMap = await fullPage.toJsonAsync();
          pageMap['notebook_id'] = notebook.serverId;
          pageMap['is_deleted'] = 0;
          if (row.serverId != null) pageMap['server_id'] = row.serverId;

          // 🚀 UPLOAD DE IMAGEM DE FUNDO DA PÁGINA (PDF Importado em disco local)
          String? bgPath = fullPage.backgroundPdfPath;
          if (bgPath != null && bgPath.isNotEmpty && !bgPath.startsWith('http')) {
            final localFile = io.File(bgPath);
            bool bgSuccess = false;
            if (localFile.existsSync()) {
              try {
                final bytes = await localFile.readAsBytes();
                final String fileName = bgPath.split('/').last.split('\\').last;
                final String? remoteUrl = await _canvasRepository.uploadImage(
                  notebook.serverId!,
                  fileName,
                  bytes,
                );
                if (remoteUrl != null && remoteUrl.isNotEmpty) {
                  pageMap['background_pdf_path'] = remoteUrl;
                  pageMap['background_image_path'] = remoteUrl;

                  await (_db.update(_db.pages)
                        ..where((t) => t.clientId.equals(cId)))
                      .write(PagesCompanion(backgroundPdfPath: Value(remoteUrl)));

                  if (!kIsWeb) {
                    try {
                      DefaultCacheManager().putFile(
                        remoteUrl,
                        bytes,
                        fileExtension: 'jpg',
                      );
                    } catch (_) {}
                  }

                  bgSuccess = true;
                  AppLog.sync('☁️ [Sync-Push] Upload do fundo da página ${row.pageNumber} concluído: $remoteUrl');
                }
              } catch (e) {
                AppLog.sync('⚠️ [Sync-Push] Falha ao fazer upload do fundo local da página ${row.pageNumber}: $e');
              }
            }
            if (!bgSuccess) {
              pageMap.remove('background_pdf_path');
              pageMap.remove('background_image_path');
            }
          } else {
            // Garantir envio explícito do valor (URL remoto ou "" para remoção)
            pageMap['background_pdf_path'] = bgPath ?? '';
            pageMap['background_image_path'] = bgPath ?? '';
          }
        }

        final int pageEstimatedBytes = jsonEncode(pageMap).length;

        // Se adicionar esta página ultrapassar o limite de bytes (~2.5MB) ou número máximo de páginas (10), envia o lote atual
        if (currentBatchPayload.isNotEmpty &&
            (currentBatchBytes + pageEstimatedBytes > maxBatchBytes ||
                currentBatchPayload.length >= maxBatchPages)) {
          await sendBatch(currentBatchPayload);
          currentBatchPayload = [];
          currentBatchBytes = 0;
          sentPageTimestamps.clear();
        }

        currentBatchPayload.add(pageMap);
        currentBatchBytes += pageEstimatedBytes;
        // Se a folha for apagada, forçamos o timestamp local, caso contrário usamos o da fullPage
        sentPageTimestamps[cId] = row.isDeleted == 1 ? row.updatedAt : (pageMap['updated_at'] ?? row.updatedAt);

        if (row.isDeleted == 1) {
          AppLog.sync('🛫 [Sync-Push-Delete] Enviando folha apagada ${row.pageNumber} com conteúdos pendentes.');
        } else {
          AppLog.sync('🛫 [Sync-Push-Delta] Preparando página ${row.pageNumber} (${(pageEstimatedBytes / 1024).toStringAsFixed(1)} KB).');
        }
      }

      // Enviar o último lote restante
      if (currentBatchPayload.isNotEmpty) {
        await sendBatch(currentBatchPayload);
      }

      return serverHasMore;
    } catch (e) {
      return false;
    } finally {
      _activePushNotebookKeys.remove(pushKey);
    }
  }

  Future<void> _markPageItemsAsSynced(int localPageId, {int? sentTs}) async {
    // 🚀 OTIMIZAÇÃO: Atualizar a coluna de sincronismo em TODAS as tabelas de objetos do Canvas
    await _db.batch((batch) {
      batch.update(
        _db.canvasStrokes,
        const CanvasStrokesCompanion(syncedWithCloud: Value(1)),
        where: (t) => sentTs != null
            ? t.pageId.equals(localPageId) &
                  t.updatedAt.isSmallerOrEqualValue(sentTs)
            : t.pageId.equals(localPageId),
      );
      batch.update(
        _db.canvasTextBlocks,
        const CanvasTextBlocksCompanion(syncedWithCloud: Value(1)),
        where: (t) => sentTs != null
            ? t.pageId.equals(localPageId) &
                  t.updatedAt.isSmallerOrEqualValue(sentTs)
            : t.pageId.equals(localPageId),
      );
      batch.update(
        _db.canvasImageBlocks,
        const CanvasImageBlocksCompanion(syncedWithCloud: Value(1)),
        where: (t) => sentTs != null
            ? t.pageId.equals(localPageId) &
                  t.updatedAt.isSmallerOrEqualValue(sentTs)
            : t.pageId.equals(localPageId),
      );
      batch.update(
        _db.canvasShapes,
        const CanvasShapesCompanion(syncedWithCloud: Value(1)),
        where: (t) => sentTs != null
            ? t.pageId.equals(localPageId) &
                  t.updatedAt.isSmallerOrEqualValue(sentTs)
            : t.pageId.equals(localPageId),
      );
      batch.update(
        _db.canvasAudioBlocks,
        const CanvasAudioBlocksCompanion(syncedWithCloud: Value(1)),
        where: (t) => sentTs != null
            ? t.pageId.equals(localPageId) &
                  t.updatedAt.isSmallerOrEqualValue(sentTs)
            : t.pageId.equals(localPageId),
      );
      batch.update(
        _db.canvasAnimations,
        const CanvasAnimationsCompanion(syncedWithCloud: Value(1)),
        where: (t) => sentTs != null
            ? t.pageId.equals(localPageId) &
                  t.updatedAt.isSmallerOrEqualValue(sentTs)
            : t.pageId.equals(localPageId),
      );
      batch.update(
        _db.canvasTables,
        const CanvasTablesCompanion(syncedWithCloud: Value(1)),
        where: (t) => sentTs != null
            ? t.pageId.equals(localPageId) &
                  t.updatedAt.isSmallerOrEqualValue(sentTs)
            : t.pageId.equals(localPageId),
      );
      batch.update(
        _db.canvasLinks,
        const CanvasLinksCompanion(syncedWithCloud: Value(1)),
        where: (t) => sentTs != null
            ? t.pageId.equals(localPageId) &
                  t.updatedAt.isSmallerOrEqualValue(sentTs)
            : t.pageId.equals(localPageId),
      );
      batch.update(
        _db.canvasAttachments,
        const CanvasAttachmentsCompanion(syncedWithCloud: Value(1)),
        where: (t) => sentTs != null
            ? t.pageId.equals(localPageId) &
                  t.updatedAt.isSmallerOrEqualValue(sentTs)
            : t.pageId.equals(localPageId),
      );
      batch.update(
        _db.canvasExplanations,
        const CanvasExplanationsCompanion(syncedWithCloud: Value(1)),
        where: (t) => sentTs != null
            ? t.pageId.equals(localPageId) &
                  t.updatedAt.isSmallerOrEqualValue(sentTs)
            : t.pageId.equals(localPageId),
      );
    });
  }

  Future<bool> pullPages({ bool forceFull = false, int? onlyNotebookId, int? onlyNotebookServerId, }) async {
    final prefs = await SharedPreferences.getInstance();

    int? targetServerNbId = onlyNotebookServerId;
    if (targetServerNbId == null && onlyNotebookId != null) {
      final inputId = onlyNotebookId;
      // 1. Verificar se inputId já é o serverId de algum caderno local
      final nbByServer = await (_db.select(_db.notebooks)
            ..where((t) => t.serverId.equals(inputId)))
          .getSingleOrNull();
      if (nbByServer != null) {
        targetServerNbId = nbByServer.serverId;
      } else {
        // 2. Tentar buscar por ID primário local (id)
        final nbByLocal = await (_db.select(_db.notebooks)
              ..where((t) => t.id.equals(inputId)))
            .getSingleOrNull();
        if (nbByLocal?.serverId != null) {
          targetServerNbId = nbByLocal!.serverId;
        } else {
          // 3. Fallback: assumir que é o próprio serverId
          targetServerNbId = inputId;
        }
      }
    }

    // 🚀 OTIMIZAÇÃO: Se for pull de um caderno específico, não usamos o timestamp global
    // para garantir que trazemos tudo o que falta para esse caderno.
    final String? lastSynced = (targetServerNbId == null && !forceFull)
        ? _getBufferedLastSynced(prefs.getString('last_pages_sync'))
        : null;

    final String resumeKey = targetServerNbId != null
        ? 'resume_pull_url_$targetServerNbId'
        : 'resume_pull_url_global';

    try {
      String? nextUrl;
      // 🚀 CURSOR DE RETOMADA: Se não for forçado do início, verifica se temos um lote pendente de uma tentativa anterior
      if (!forceFull && prefs.containsKey(resumeKey)) {
        final savedUrl = prefs.getString(resumeKey);
        if (savedUrl != null && savedUrl.isNotEmpty && savedUrl != 'null') {
          nextUrl = savedUrl;
          AppLog.sync('🗂️ [Sync-Resume] Retomando download do lote a partir de: $nextUrl');
        }
      }

      if (nextUrl == null) {
        String baseUrl = '/sync/pages/pull';
        if (lastSynced != null) baseUrl += '?last_synced_at=$lastSynced';
        if (targetServerNbId != null) {
          baseUrl += (lastSynced != null ? '&' : '?') + 'notebook_id=$targetServerNbId';
        }
        nextUrl = baseUrl;
      }

      bool anyChanges = false;
      final Set<String> serverClientIds = {};

      while (nextUrl != null) {
        final response = await _apiService.get(nextUrl);
        if (response.statusCode == 200) {
          final dynamic decoded = await compute<String, dynamic>(
            (jsonStr) => jsonDecode(jsonStr),
            response.body,
          );
          final Map<String, dynamic> responseData = decoded is Map
              ? Map<String, dynamic>.from(decoded)
              : (decoded is List ? {'data': decoded} : {});

          final List serverPages =
              responseData['data'] ?? responseData['pages'] ?? [];
          // 🚀 AGORA GUARDA O METADATA SEMPRE, MESMO SE A PÁGINA NÃO TIVER DADOS NO ARRAY!
          // Isto impede o bug de "nextUrl == null" na página 11 não salvar a última data de sincronização!
          final String? serverTime = _parseMetaTime(responseData['meta']);
          if (targetServerNbId == null && serverTime != null) {
            await prefs.setString('last_pages_sync', serverTime);
          }

          if (serverPages.isNotEmpty) {
            anyChanges = true;
            final List<int> localPageIdsForBatch = [];
            final Map<int, Map<String, dynamic>> serverPageDataMap = {};
            for (var sPageData in serverPages) {
              try {
                final Map<String, dynamic> sPage = sPageData is Map
                    ? Map<String, dynamic>.from(sPageData)
                    : {};
                if (sPage.isEmpty) continue;

                final int sNbId = sPage['notebook_id'] is int
                    ? sPage['notebook_id']
                    : int.parse(sPage['notebook_id'].toString());
                final String? cId = sPage['client_id']?.toString();
                if (cId != null) serverClientIds.add(cId);

                final notebook = await (_db.select(
                  _db.notebooks,
                )..where((t) => t.serverId.equals(sNbId))).getSingleOrNull();
                if (notebook == null) continue;
                final existingPage =
                    await (_db.select(_db.pages)
                          ..where((t) => t.clientId.equals(cId ?? '')))
                        .getSingleOrNull();
                final int serverTs =
                    _parseSafeInt(sPage['updated_at_ms']) ??
                    _parseSafeInt(sPage['updated_at']) ??
                    0;

                // 🚀 PREVENÇÃO DE FANTASMAS: Se o servidor disser que a folha está apagada,
                // apagamo-la localmente caso exista, e SALTAMOS a recriação!
                final bool isServerDeleted = sPage['is_deleted'] == 1 || sPage['is_deleted'] == true || sPage['deleted_at'] != null;
                if (isServerDeleted) {
                  if (existingPage != null) {
                    await _canvasRepository.purgePageCompletely(existingPage.id);
                  }
                  continue;
                }

                // 🚀 OTIMIZAÇÃO CRÍTICA: Se a página já existe localmente, está limpa (syncedWithCloud == 1)
                // e o timestamp local for IGUAL ou MAIOR que o do servidor, a página NÃO MUDOU.
                // Ignoramos a re-gravação no SQLite e o re-processamento de objetos!
                if (existingPage != null &&
                    existingPage.syncedWithCloud == 1 &&
                    existingPage.updatedAt >= serverTs) {
                  continue;
                }

                if (existingPage != null &&
                    existingPage.syncedWithCloud == 0 &&
                    existingPage.updatedAt > serverTs) {
                  localPageIdsForBatch.add(existingPage.id);
                  serverPageDataMap[existingPage.id] = sPage;
                  continue;
                }
                final localPageId = await _canvasRepository.savePageFromMap(
                  sPage,
                  sNbId,
                );
                _prewarmBackgroundImage(
                  sPage,
                ); // 🚀 OTIMIZAÇÃO: Caching em plano de fundo
                localPageIdsForBatch.add(localPageId);
                serverPageDataMap[localPageId] = sPage;
              } catch (e) {
                AppLog.sync('🚨 [Sync-Pull] Erro ao processar página do servidor:  $e');
              }
            }
            if (localPageIdsForBatch.isNotEmpty)
              await _pullCanvasDataBatch(
                localPageIdsForBatch,
                serverPageDataMap,
              );
          }
          nextUrl = _extractNextUrl(responseData);
          if (nextUrl != null && nextUrl.isNotEmpty && nextUrl != 'null') {
            await prefs.setString(resumeKey, nextUrl);
          } else {
            await prefs.remove(resumeKey); // 🚀 Lote 100% concluído! Limpar cursor.
          }
        } else {
          throw Exception('Erro ${response.statusCode} no PULL Pages');
        }
      }
      if (forceFull) {
        final query = _db.select(_db.pages)
          ..where((t) => t.syncedWithCloud.equals(1));
        if (targetServerNbId != null) {
          final sId = targetServerNbId;
          final nb = await (_db.select(
            _db.notebooks,
          )..where((t) => t.serverId.equals(sId))).getSingleOrNull();
          if (nb != null) query.where((t) => t.notebookId.equals(nb.id));
        }
        final localSyncedPages = await query.get();
        for (var lp in localSyncedPages) {
          if (!serverClientIds.contains(lp.clientId))
            await (_db.delete(
              _db.pages,
            )..where((t) => t.id.equals(lp.id))).go();
        }
      }

      // 🚀 AUTO-RECUPERAÇÃO E RETOMADA DE CADERNOS INCOMPLETOS:
      // Se for um PULL global (sem filtro de caderno específico),
      // verifica se há cadernos locais sem páginas OU com cursores de retomada pendentes.
      if (targetServerNbId == null) {
        final allLocalNotebooks = await (_db.select(_db.notebooks)
              ..where((t) => t.serverId.isNotNull() & t.isDeleted.equals(0)))
            .get();

        for (var nb in allLocalNotebooks) {
          if (nb.serverId == null) continue;
          final String nbResumeKey = 'resume_pull_url_${nb.serverId}';
          final bool hasPendingResume = prefs.containsKey(nbResumeKey);

          final pagesInNb = await (_db.select(_db.pages)
                ..where((t) => t.notebookId.equals(nb.id) & t.isDeleted.equals(0)))
              .get();

          if (pagesInNb.isEmpty || hasPendingResume) {
            AppLog.sync(
              '📥 [Sync-AutoPull] Caderno "${nb.title}" (ServerID: ${nb.serverId}) ${hasPendingResume ? "possui lote pendente após quebra de rede" : "tem 0 páginas"}! Sincronizando...',
            );
            await pullPages(
              forceFull: pagesInNb.isEmpty,
              onlyNotebookServerId: nb.serverId,
            );
          }
        }
      }

      return anyChanges;
    } catch (e) {
      return false;
    }
  }

  Future<void> pullSpecificPage(
    int notebookServerId,
    int pageNumber, {
    String? clientId,
    bool isRetry = false,
  }) async {
    String url = '/sync/pages/pull?notebook_id=$notebookServerId';
    if (clientId != null)
      url += '&client_id=$clientId';
    else
      url += '&page_number=$pageNumber';

    if (_activePullUrls.contains(url)) return;
    _activePullUrls.add(url);

    try {
      final response = await _apiService.get(url);
      if (response.statusCode == 200) {
        final dynamic decoded = await compute<String, dynamic>(
          (jsonStr) => jsonDecode(jsonStr),
          response.body,
        );
        final Map<String, dynamic> responseData = decoded is Map
            ? Map<String, dynamic>.from(decoded)
            : (decoded is List ? {'data': decoded} : {});

        final List serverPages =
            responseData['data'] ?? responseData['pages'] ?? [];
        if (serverPages.isNotEmpty) {
          final dynamic sPageData = serverPages.first;
          final Map<String, dynamic> sPage = sPageData is Map
              ? Map<String, dynamic>.from(sPageData)
              : {};

          if (sPage.isEmpty) return;

          final notebook =
              await (_db.select(_db.notebooks)
                    ..where((t) => t.serverId.equals(notebookServerId)))
                  .getSingleOrNull();
          if (notebook == null) return;
          final localId = await _canvasRepository.savePageFromMap(
            sPage,
            notebookServerId,
          );
          _prewarmBackgroundImage(
            sPage,
          ); // 🚀 OTIMIZAÇÃO: Caching em plano de fundo
          await _pullCanvasData(localId, sPage);
        }
      }
    } catch (e) {
      AppLog.sync('🚨 [Sync] Erro pullSpecificPage: $e');
    } finally {
      _activePullUrls.remove(url);
    }
  }

  Future<void> _pullCanvasDataBatch(
    List<int> localPageIds,
    Map<int, Map<String, dynamic>> serverPageDataMap,
  ) async {
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
      List<CanvasShapesCompanion> shapes = [];
      List<CanvasAudioBlocksCompanion> audios = [];
      List<CanvasAnimationsCompanion> animations = [];
      List<CanvasTablesCompanion> tables = [];
      List<CanvasLinksCompanion> links = [];
      List<CanvasAttachmentsCompanion> attachments = [];
      List<CanvasExplanationsCompanion> explanations = [];

      if (kIsWeb) {
        // ... (Mapeamento web simplificado omitido para brevidade, segue lógica similar ao Isolate)
      } else {
        final List<dynamic> results = await compute(
          SyncIsolates.processCanvasDataBatch,
          {'serverPages': serverPagesList, 'currentTime': currentTime},
        );
        strokes = results[0];
        texts = results[1];
        images = results[2];
        shapes = results[3];
        audios = results[4];
        animations = results[5];
        tables = results[6];
        links = results[7];
        attachments = results[8];
        explanations = results[9];
      }

      // 🚀 VERIFICAÇÃO DE EXISTÊNCIA
      final existingPageRows = await (_db.select(
        _db.pages,
      )..where((t) => t.id.isIn(validPageIds))).get();
      final Set<int> confirmedIds = existingPageRows.map((r) => r.id).toSet();

      final finalPageIds = validPageIds
          .where((id) => confirmedIds.contains(id))
          .toList();
      if (finalPageIds.isEmpty) return;

      // 🚀 OCC: Obter IDs de objetos sujos locais para não serem substituídos pelo PULL
      final dirtyStrokes =
          await (_db.select(_db.canvasStrokes)..where(
                (t) =>
                    t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(0),
              ))
              .get();
      final Set<String> ds = dirtyStrokes.map((e) => e.clientStrokeId).toSet();

      final dirtyTexts =
          await (_db.select(_db.canvasTextBlocks)..where(
                (t) =>
                    t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(0),
              ))
              .get();
      final Set<String> dt = dirtyTexts.map((e) => e.clientTextId).toSet();

      final dirtyImages =
          await (_db.select(_db.canvasImageBlocks)..where(
                (t) =>
                    t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(0),
              ))
              .get();
      final Set<String> di = dirtyImages.map((e) => e.clientImageId).toSet();

      final dirtyShapes =
          await (_db.select(_db.canvasShapes)..where(
                (t) =>
                    t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(0),
              ))
              .get();
      final Set<String> dsh = dirtyShapes.map((e) => e.clientShapeId).toSet();

      final dirtyAudios =
          await (_db.select(_db.canvasAudioBlocks)..where(
                (t) =>
                    t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(0),
              ))
              .get();
      final Set<String> da = dirtyAudios.map((e) => e.clientAudioId).toSet();

      final dirtyAnims =
          await (_db.select(_db.canvasAnimations)..where(
                (t) =>
                    t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(0),
              ))
              .get();
      final Set<String> dan = dirtyAnims
          .map((e) => e.clientAnimationId)
          .toSet();

      final dirtyTables =
          await (_db.select(_db.canvasTables)..where(
                (t) =>
                    t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(0),
              ))
              .get();
      final Set<String> dtb = dirtyTables.map((e) => e.clientTableId).toSet();

      final dirtyLinks =
          await (_db.select(_db.canvasLinks)..where(
                (t) =>
                    t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(0),
              ))
              .get();
      final Set<String> dl = dirtyLinks.map((e) => e.clientLinkId).toSet();

      final dirtyAttachs =
          await (_db.select(_db.canvasAttachments)..where(
                (t) =>
                    t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(0),
              ))
              .get();
      final Set<String> dat = dirtyAttachs
          .map((e) => e.clientAttachmentId)
          .toSet();

      final dirtyExps =
          await (_db.select(_db.canvasExplanations)..where(
                (t) =>
                    t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(0),
              ))
              .get();
      final Set<String> de = dirtyExps
          .map((e) => e.clientExplanationId)
          .toSet();

      await _db.batch((batch) {
        batch.deleteWhere(
          _db.canvasStrokes,
          (t) => t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(1),
        );
        batch.deleteWhere(
          _db.canvasTextBlocks,
          (t) => t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(1),
        );
        batch.deleteWhere(
          _db.canvasImageBlocks,
          (t) => t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(1),
        );
        batch.deleteWhere(
          _db.canvasShapes,
          (t) => t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(1),
        );
        batch.deleteWhere(
          _db.canvasAudioBlocks,
          (t) => t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(1),
        );
        batch.deleteWhere(
          _db.canvasAnimations,
          (t) => t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(1),
        );
        batch.deleteWhere(
          _db.canvasTables,
          (t) => t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(1),
        );
        batch.deleteWhere(
          _db.canvasLinks,
          (t) => t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(1),
        );
        batch.deleteWhere(
          _db.canvasAttachments,
          (t) => t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(1),
        );
        batch.deleteWhere(
          _db.canvasExplanations,
          (t) => t.pageId.isIn(finalPageIds) & t.syncedWithCloud.equals(1),
        );

        for (var s in strokes) {
          if (confirmedIds.contains(s.pageId.value) &&
              !ds.contains(s.clientStrokeId.value))
            batch.insert(
              _db.canvasStrokes,
              s,
              mode: InsertMode.insertOrReplace,
            );
        }
        for (var t in texts) {
          if (confirmedIds.contains(t.pageId.value) &&
              !dt.contains(t.clientTextId.value))
            batch.insert(
              _db.canvasTextBlocks,
              t,
              mode: InsertMode.insertOrReplace,
            );
        }
        for (var i in images) {
          if (confirmedIds.contains(i.pageId.value) &&
              !di.contains(i.clientImageId.value))
            batch.insert(
              _db.canvasImageBlocks,
              i,
              mode: InsertMode.insertOrReplace,
            );
        }
        for (var s in shapes) {
          if (confirmedIds.contains(s.pageId.value) &&
              !dsh.contains(s.clientShapeId.value))
            batch.insert(_db.canvasShapes, s, mode: InsertMode.insertOrReplace);
        }
        for (var a in audios) {
          if (confirmedIds.contains(a.pageId.value) &&
              !da.contains(a.clientAudioId.value))
            batch.insert(
              _db.canvasAudioBlocks,
              a,
              mode: InsertMode.insertOrReplace,
            );
        }
        for (var a in animations) {
          if (confirmedIds.contains(a.pageId.value) &&
              !dan.contains(a.clientAnimationId.value))
            batch.insert(
              _db.canvasAnimations,
              a,
              mode: InsertMode.insertOrReplace,
            );
        }
        for (var t in tables) {
          if (confirmedIds.contains(t.pageId.value) &&
              !dtb.contains(t.clientTableId.value))
            batch.insert(_db.canvasTables, t, mode: InsertMode.insertOrReplace);
        }
        for (var l in links) {
          if (confirmedIds.contains(l.pageId.value) &&
              !dl.contains(l.clientLinkId.value))
            batch.insert(_db.canvasLinks, l, mode: InsertMode.insertOrReplace);
        }
        for (var a in attachments) {
          if (confirmedIds.contains(a.pageId.value) &&
              !dat.contains(a.clientAttachmentId.value))
            batch.insert(
              _db.canvasAttachments,
              a,
              mode: InsertMode.insertOrReplace,
            );
        }
        for (var e in explanations) {
          if (confirmedIds.contains(e.pageId.value) &&
              !de.contains(e.clientExplanationId.value))
            batch.insert(
              _db.canvasExplanations,
              e,
              mode: InsertMode.insertOrReplace,
            );
        }

        for (var id in finalPageIds) {
          final int serverPageUpdatedAt =
              serverPageDataMap[id]?['updated_at_ms'] ?? 0;
          batch.update(
            _db.pages,
            PagesCompanion(
              updatedAt: Value(TimeService().nowMs()),
              syncedWithCloud: const Value(1),
            ),
            where: (t) =>
                t.id.equals(id) &
                t.updatedAt.isSmallerOrEqualValue(serverPageUpdatedAt),
          );
        }
      });
      // 🚀 v10.88: Purge após pull massivo
      for (var id in finalPageIds) {
        await _canvasRepository.purgeSyncedDeletedObjects(id);
      }
      AppLog.sync('');
    } catch (e) {
      AppLog.sync('');
    }
  }

  Future<void> _pullCanvasData(
    int localPageId,
    Map<String, dynamic> sPage,
  ) async {
    await _pullCanvasDataBatch([localPageId], {localPageId: sPage});
  }

  String? _extractNextUrl(Map<String, dynamic> responseData) {
    if (responseData['next_page_url'] != null) {
      final String nextUrl = responseData['next_page_url'].toString();
      if (nextUrl.isNotEmpty && nextUrl != 'null') return nextUrl;
    }
    final dynamic links = responseData['links'];
    if (links is Map && links['next'] != null) {
      final String nextUrl = links['next'].toString();
      if (nextUrl.isNotEmpty && nextUrl != 'null') return nextUrl;
    }
    if (links is List) {
      for (var link in links) {
        if (link is Map && link['label']?.toString().contains('Next') == true) {
          final String? url = link['url']?.toString();
          if (url != null && url.isNotEmpty && url != 'null') return url;
        }
      }
    }
    return null;
  }

  Future<bool> pushRecordings({bool pushOnly = false}) async {
    final prefs = await SharedPreferences.getInstance();
    final String? lastSynced = _getBufferedLastSynced(
      prefs.getString('last_recordings_sync'),
    );

    try {
      final unsynced = await (_db.select(
        _db.lessonRecordings,
      )..where((t) => t.syncedWithCloud.equals(0))).get();
      final List<Map<String, dynamic>> payload = [];

      for (var row in unsynced) {
        final notebookRow = await (_db.select(
          _db.notebooks,
        )..where((t) => t.id.equals(row.notebookId))).getSingleOrNull();
        if (notebookRow?.serverId == null) continue;

        String audioUrl = row.audioUrl;
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
              clientId: row.clientId,
            );
            if (remoteUrl != null)
              audioUrl = remoteUrl;
            else
              continue;
          }
        }
        payload.add({
          'notebook_id': notebookRow!.serverId,
          'client_id': row.clientId,
          'title': row.title,
          'audio_url': audioUrl,
          'duration_seconds': row.durationSeconds,
          'updated_at': row.updatedAt,
        });
      }

      final response = await _apiService.post('/sync/recordings/push', {
        'recordings': payload,
        'last_synced_at': lastSynced,
      }, compress: true);

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);

        // 1. Confirmações
        for (var item in data['synced_recordings'] ?? []) {
          final String clientUuid = item['client_id'].toString();
          final int sId = item['id'] ?? item['server_id'];
          final int serverTime =
              _parseSafeInt(item['updated_at_ms']) ??
              _parseSafeInt(item['updated_at']) ??
              TimeService().nowMs();

          await (_db.update(
            _db.lessonRecordings,
          )..where((t) => t.clientId.equals(clientUuid))).write(
            LessonRecordingsCompanion(
              serverId: Value(sId),
              audioUrl: Value(item['audio_url']),
              syncedWithCloud: const Value(1),
              updatedAt: Value(serverTime),
            ),
          );
        }

        // 2. Updates do Servidor (Pular se pushOnly)
        if (!pushOnly) {
          final List updates = data['server_updates'] ?? [];
          if (updates.isNotEmpty) {
            await _applyRecordingUpdates(updates);
          }

          if (data['meta'] != null && data['meta']['server_time'] != null) {
            await prefs.setString(
              'last_recordings_sync',
              data['meta']['server_time'],
            );
          }
        }
        return data['has_more'] == true;
      }
      return false;
    } catch (e) {
      AppLog.sync('🚨 [Sync-Recordings] Erro: $e');
      return false;
    }
  }

  Future<void> _applyRecordingUpdates(List updates) async {
    final allNotebooks = await _db.select(_db.notebooks).get();
    final Map<int, int> serverToLocalNotebookId = {
      for (var n in allNotebooks)
        if (n.serverId != null) n.serverId!: n.id,
    };

    await _db.batch((batch) {
      for (var rec in updates) {
        final int? localNbId = serverToLocalNotebookId[rec['notebook_id']];
        if (localNbId == null) continue;

        batch.insert(
          _db.lessonRecordings,
          LessonRecordingsCompanion.insert(
            serverId: Value(rec['id']),
            clientId: Value(rec['client_id'] ?? const Uuid().v4()),
            notebookId: localNbId,
            title: rec['title'] ?? 'Sem título',
            audioUrl: rec['audio_url'] ?? '',
            durationSeconds: Value(rec['duration_seconds'] ?? 0),
            syncedWithCloud: const Value(1),
            updatedAt: Value(_parseSafeInt(rec['updated_at_ms']) ?? 0),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  Future<void> pullRecordings() async {
    // PULL explícito mantido para gravações pois são ficheiros grandes e fluxo diferente
    final prefs = await SharedPreferences.getInstance();
    final String? lastSynced = _getBufferedLastSynced(
      prefs.getString('last_recordings_sync'),
    );
    try {
      final url = lastSynced != null
          ? '/sync/recordings/pull?last_synced_at=$lastSynced'
          : '/sync/recordings/pull';
      final response = await _apiService.get(url);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List serverRecordings = data['data'] ?? [];
        final allNotebooks = await _db.select(_db.notebooks).get();
        final Map<int, int> serverToLocalNotebookId = {
          for (var n in allNotebooks)
            if (n.serverId != null) n.serverId!: n.id,
        };
        if (data['meta'] != null && data['meta']['server_time'] != null)
          await prefs.setString(
            'last_recordings_sync',
            data['meta']['server_time'],
          );
        await _db.batch((batch) {
          for (var rec in serverRecordings) {
            final int? localNbId = serverToLocalNotebookId[rec['notebook_id']];
            if (localNbId == null) continue;
            batch.insert(
              _db.lessonRecordings,
              LessonRecordingsCompanion.insert(
                serverId: Value(rec['id']),
                clientId: Value(rec['client_id'] ?? Uuid().v4()),
                notebookId: localNbId,
                title: rec['title'] ?? 'Sem título',
                audioUrl: rec['audio_url'] ?? '',
                durationSeconds: Value(rec['duration_seconds'] ?? 0),
                syncedWithCloud: const Value(1),
                updatedAt: Value(rec['updated_at_ms'] ?? 0),
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
      }
    } catch (e) {}
  }

  Future<bool> fastPushPage(
    pages_model.LocalPage page,
    int notebookServerId,
    String myUserId,
  ) async {
    try {
      final Map<String, dynamic> payload = await page.toJsonAsync();
      payload['notebook_id'] = notebookServerId;
      payload['sender_id'] = myUserId;
      if (page.serverId == null) payload['is_new_page'] = true;
      final response = await _apiService.post('/sync/realtime/update', {
        'page': payload,
      }, compress: true);
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // =========================================================================
  // 6. HISTÓRICO DE COLABORAÇÃO (REDIS)
  // =========================================================================

  /// 🚀 Envia uma ação validada para o backend guardar no Redis
  Future<void> recordActionToCloud(
    int notebookServerId,
    Map<String, dynamic> actionData,
  ) async {
    try {
      await _apiService.post('/notebooks/$notebookServerId/session/action', {
        'action': actionData,
      });
    } catch (e) {
      AppLog.sync('⚠️ [Sync] Falha ao guardar ação no Redis: $e');
    }
  }

  /// 🚀 Recupera ações do Redis que falharam/foram perdidas durante a hibernação
  Future<List<Map<String, dynamic>>> pullSessionHistory(
    int notebookServerId,
    int sinceTimestamp,
  ) async {
    try {
      final response = await _apiService.get(
        '/notebooks/$notebookServerId/session/history?since=$sinceTimestamp',
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['status'] == 'ok' && data['actions'] != null) {
          return List<Map<String, dynamic>>.from(data['actions']);
        }
      }
    } catch (e) {
      AppLog.sync('🚨 [Sync] Erro a puxar histórico do Redis: $e');
    }
    return [];
  }
}
