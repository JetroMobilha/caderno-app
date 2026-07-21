import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/subjects/models/subject_model.dart' as subjects_model;
import '../../features/canvas/models/local_page_model.dart' as pages_model;
import '../../features/canvas/repositories/canvas_repository.dart';
import '../database/app_database.dart';
import 'api_service.dart';

class SyncService {
  final AppDatabase _db = AppDatabase.instance;
  final ApiService _apiService = ApiService();
  late final CanvasRepository _canvasRepository;

  SyncService() {
    _canvasRepository = CanvasRepository(_db);
  }

  static bool isCollaborationActive = false;

  String uniqid() => DateTime.now().microsecondsSinceEpoch.toString();

  // =========================================================================
  // 1. SINCRONIZAÇÃO TOTAL
  // =========================================================================
  Future<void> syncAll({bool forced = false}) async {
    if (isCollaborationActive && !forced) {
      debugPrint('🛑 [SyncService] Sincronização automática pausada para colaboração.');
      return;
    }

    debugPrint('🏁 [Sync General] A iniciar ofensiva de sincronização total...');

    try {
      await pushOfflineSubjects();
      await pullSubjects();

      await pushNotebooks();
      await pullNotebooks();

      await pushPages();
      await pullPages();
      
      debugPrint('🏆 [Sync General] Ciclo Concluído com Sucesso!');
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

      final List<Map<String, dynamic>> payload = unsynced.map((s) => 
        subjects_model.Subject(
          id: s.id,
          serverId: s.serverId,
          userId: s.userId,
          name: s.name,
          color: s.color,
          icon: s.icon,
          isDeleted: s.isDeleted,
          syncedWithCloud: s.syncedWithCloud,
          updatedAt: s.updatedAt,
        ).toJson()
      ).toList();

      final response = await _apiService.post('/sync/push', {'subjects': payload});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _db.batch((batch) {
          for (var item in data['synced_subjects']) {
            batch.update(_db.subjects, 
              SubjectsCompanion(
                serverId: Value(item['server_id']),
                syncedWithCloud: const Value(1),
              ),
              where: (t) => t.id.equals(item['client_id']),
            );
          }
        });
      } else {
        throw Exception('Servidor retornou erro ${response.statusCode} no PUSH Subjects');
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
      final endpoint = lastSynced != null ? '/sync/pull?last_synced_at=$lastSynced' : '/sync/pull';
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = await compute<String, Map<String, dynamic>>(
          (jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>,
          response.body,
        );
        final List serverSubjects = data['subjects'] ?? [];
        if (data['server_time'] != null) await prefs.setString('last_subjects_sync', data['server_time']);

        if (serverSubjects.isEmpty) return false;

        final userQuery = await (_db.select(_db.users)..orderBy([(t) => OrderingTerm(expression: t.id)])..limit(1)).get();
        if (userQuery.isEmpty) return false;
        final int localUserId = userQuery.first.id;

        await _db.batch((batch) {
          for (var sub in serverSubjects) {
            final int sId = sub['id'] is int ? sub['id'] : int.parse(sub['id'].toString());
            
            final companion = SubjectsCompanion.insert(
              serverId: Value(sId),
              userId: localUserId,
              name: sub['name'] ?? '',
              color: sub['color'] ?? '#0F4C5C',
              icon: Value(sub['icon']),
              isDeleted: Value(sub['deleted_at'] != null ? 1 : 0),
              syncedWithCloud: const Value(1),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            );

            batch.insert(_db.subjects, companion, 
              onConflict: DoUpdate((old) => SubjectsCompanion(
                name: companion.name,
                color: companion.color,
                icon: companion.icon,
                isDeleted: companion.isDeleted,
                syncedWithCloud: companion.syncedWithCloud,
                updatedAt: companion.updatedAt,
              ), target: [_db.subjects.serverId])
            );
          }
        });
        return true;
      } else {
        throw Exception('Erro ${response.statusCode} no PULL Subjects');
      }
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
        int? cloudSubjectId;
        if (row.subjectId != null) {
          final subject = await (_db.select(_db.subjects)..where((t) => t.id.equals(row.subjectId!))).getSingleOrNull();
          if (subject == null || subject.serverId == null) continue;
          cloudSubjectId = subject.serverId;
        }

        final map = row.toJson();
        map['subject_id'] = cloudSubjectId;
        payload.add(map);
      }

      if (payload.isEmpty) return;

      final response = await _apiService.post('/sync/notebooks/push', {'notebooks': payload});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _db.batch((batch) {
          for (var item in data['synced_notebooks']) {
            batch.update(_db.notebooks,
              NotebooksCompanion(serverId: Value(item['server_id']), syncedWithCloud: const Value(1)),
              where: (t) => t.id.equals(item['client_id']),
            );
          }
        });
      } else {
        throw Exception('Servidor retornou erro ${response.statusCode} no PUSH Notebooks');
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
      final endpoint = lastSynced != null ? '/sync/notebooks/pull?last_synced_at=$lastSynced' : '/sync/notebooks/pull';
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = await compute<String, Map<String, dynamic>>(
          (jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>,
          response.body,
        );
        if (data['server_time'] != null) await prefs.setString('last_notebooks_sync', data['server_time']);

        final List serverNotebooks = data['notebooks'] ?? [];
        if (serverNotebooks.isEmpty) return false;

        if (lastSynced == null) {
          final List<int> serverIds = serverNotebooks.map((n) => n['id'] as int).toList();
          await (_db.delete(_db.notebooks)..where((t) => t.serverId.isNotNull() & t.serverId.isNotIn(serverIds))).go();
        }

        final userQuery = await (_db.select(_db.users)..orderBy([(t) => OrderingTerm(expression: t.id)])..limit(1)).get();
        final int currentUserId = userQuery.isNotEmpty ? userQuery.first.id : 0;

        final allSubjects = await _db.select(_db.subjects).get();
        final Map<int, int> subjectIdMap = {for (var s in allSubjects) if (s.serverId != null) s.serverId!: s.id};

        await _db.batch((batch) {
          for (var net in serverNotebooks) {
            final int sId = net['id'] is int ? net['id'] : int.parse(net['id'].toString());
            final int? serverSubId = net['subject_id'] != null 
                ? (net['subject_id'] is int ? net['subject_id'] : int.parse(net['subject_id'].toString()))
                : null;

            final int? localSubjectId = (serverSubId != null) ? subjectIdMap[serverSubId] : null;
            
            final companion = NotebooksCompanion.insert(
              serverId: Value(sId),
              subjectId: Value(localSubjectId),
              title: net['title'] ?? '',
              coverType: net['cover_type'] ?? 'color',
              color: Value(net['color']),
              coverImage: Value(net['cover_image']),
              lineType: Value(net['line_type'] ?? 'ruled'),
              paperSize: Value(net['paper_size'] ?? 'A4'),
              isPublished: Value(int.tryParse(net['is_published']?.toString() ?? '0') ?? 0),
              price: Value(double.tryParse(net['price']?.toString() ?? '0.0') ?? 0.0),
              description: Value(net['description']),
              authorName: Value(net['author_name']),
              isDeleted: Value(net['deleted_at'] != null ? 1 : 0),
              syncedWithCloud: const Value(1),
              updatedAt: Value(DateTime.parse(net['updated_at'].toString()).millisecondsSinceEpoch),
            );

            batch.insert(_db.notebooks, companion, 
              onConflict: DoUpdate((old) => NotebooksCompanion(
                subjectId: companion.subjectId,
                title: companion.title,
                coverType: companion.coverType,
                color: companion.color,
                coverImage: companion.coverImage,
                lineType: companion.lineType,
                paperSize: companion.paperSize,
                isPublished: companion.isPublished,
                price: companion.price,
                description: companion.description,
                authorName: companion.authorName,
                isDeleted: companion.isDeleted,
                syncedWithCloud: companion.syncedWithCloud,
                updatedAt: companion.updatedAt,
              ), target: [_db.notebooks.serverId])
            );
          }
        });

        final allNotebooks = await _db.select(_db.notebooks).get();
        final Map<int, int> notebookIdMap = {for (var n in allNotebooks) if (n.serverId != null) n.serverId!: n.id};

        await _db.batch((batch) {
          for (var net in serverNotebooks) {
            final role = net['role'];
            final sId = net['id'];
            final localNotebookId = notebookIdMap[sId];

            if (role != null && role != 'owner' && currentUserId > 0 && localNotebookId != null) {
              batch.insert(_db.notebookUser, 
                NotebookUserCompanion.insert(
                  notebookId: localNotebookId,
                  userId: currentUserId,
                  role: Value(role),
                  syncedWithCloud: const Value(1),
                  updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
                ),
                mode: InsertMode.insertOrReplace,
              );
            }
          }
        });

        return true;
      } else {
        throw Exception('Erro ${response.statusCode} no PULL Notebooks');
      }
    } catch (e) {
      debugPrint('🚨 Erro PULL Notebooks: $e');
      rethrow;
    }
  }

  // =========================================================================
  // 4. PÁGINAS E CANVAS
  // =========================================================================
  Future<void> pushPages() async {
    try {
      final unsyncedPages = await (_db.select(_db.pages)..where((t) => t.syncedWithCloud.equals(0))).get();
      if (unsyncedPages.isEmpty) return;

      final List<Map<String, dynamic>> payloadPages = [];

      for (var row in unsyncedPages) {
        final notebook = await (_db.select(_db.notebooks)..where((t) => t.id.equals(row.notebookId))).getSingleOrNull();
        if (notebook == null || notebook.serverId == null) continue;

        final allPages = await _canvasRepository.getPagesByNotebook(row.notebookId, null);
        final fullPage = allPages.firstWhere((p) => p.id == row.id);

        final map = await fullPage.toJsonAsync();
        map['notebook_id'] = notebook.serverId;
        map['client_id'] = row.id;
        map['server_id'] = row.serverId;
        payloadPages.add(map);
      }

      if (payloadPages.isEmpty) return;

      final response = await _apiService.post('/sync/pages/push', {'pages': payloadPages});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _db.batch((batch) {
          for (var item in data['synced_pages'] ?? []) {
            if (item['client_id'] != null && item['server_id'] != null) {
              batch.update(_db.pages,
                PagesCompanion(
                  serverId: Value(item['server_id']),
                  pageNumber: Value(item['page_number']),
                  syncedWithCloud: const Value(1),
                  updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
                ),
                where: (t) => t.id.equals(item['client_id']),
              );
            }
          }
        });
      } else {
        throw Exception('Servidor retornou erro ${response.statusCode} no PUSH Pages');
      }
    } catch (e) {
      debugPrint('🚨 Erro PUSH Pages: $e');
      rethrow;
    }
  }

  Future<bool> pullPages() async {
    final prefs = await SharedPreferences.getInstance();
    
    final localCount = await _db.pages.count().getSingle();
    final String? lastSynced = localCount > 0 ? prefs.getString('last_pages_sync') : null;

    try {
      final endpoint = lastSynced != null ? '/sync/pages/pull?last_synced_at=$lastSynced' : '/sync/pages/pull';
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = await compute<String, Map<String, dynamic>>(
          (jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>,
          response.body,
        );
        
        if (data['server_time'] != null) await prefs.setString('last_pages_sync', data['server_time']);

        final List serverPages = data['pages'] ?? [];
        if (serverPages.isEmpty) return false;

        for (var sPage in serverPages) {
          final int sId = sPage['id'] is int ? sPage['id'] : int.parse(sPage['id'].toString());
          final int sNotebookId = sPage['notebook_id'] is int ? sPage['notebook_id'] : int.parse(sPage['notebook_id'].toString());

          final notebook = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(sNotebookId))).getSingleOrNull();
          if (notebook == null) continue;

          final localNotebookId = notebook.id;

          final pageCompanion = PagesCompanion.insert(
            serverId: Value(sId),
            notebookId: localNotebookId,
            pageNumber: sPage['page_number'],
            isLandscape: Value((sPage['is_landscape'] == true || sPage['is_landscape'] == 1) ? 1 : 0),
            headerData: Value(sPage['header_data'] is String ? sPage['header_data'] : jsonEncode(sPage['header_data'] ?? '')),
            footerData: Value(sPage['footer_data'] is String ? sPage['footer_data'] : jsonEncode(sPage['footer_data'] ?? '')),
            extractedText: Value(sPage['extracted_text']?.toString()),
            syncedWithCloud: const Value(1),
            updatedAt: Value(DateTime.parse(sPage['updated_at'].toString()).millisecondsSinceEpoch),
          );

          final existingPage = await (_db.select(_db.pages)..where((t) => t.serverId.equals(sId))).getSingleOrNull();
          int localPageId;
          
          if (existingPage != null) {
            localPageId = existingPage.id;
            await (_db.update(_db.pages)..where((t) => t.id.equals(localPageId))).write(
              PagesCompanion(
                headerData: pageCompanion.headerData,
                footerData: pageCompanion.footerData,
                isLandscape: pageCompanion.isLandscape,
                extractedText: pageCompanion.extractedText,
                syncedWithCloud: pageCompanion.syncedWithCloud,
                updatedAt: pageCompanion.updatedAt,
              )
            );
          } else {
            localPageId = await _db.into(_db.pages).insert(pageCompanion);
          }

          await _pullCanvasData(localPageId, sPage);
        }
        return true;
      } else {
        throw Exception('Erro ${response.statusCode} no PULL Pages');
      }
    } catch (e) {
      debugPrint('🚨 Erro PULL Pages: $e');
      rethrow;
    }
  }

  Future<void> _pullCanvasData(int localPageId, Map sPage) async {
    await _db.batch((batch) {
      List strokeList = _parseJsonList(sPage['stroke_data']);
      for (var st in strokeList) {
        batch.insert(_db.canvasStrokes, 
          CanvasStrokesCompanion.insert(
            clientStrokeId: st['id']?.toString() ?? uniqid(),
            pageId: localPageId,
            strokeData: jsonEncode(st),
            isDeleted: const Value(0),
            syncedWithCloud: const Value(1),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }

      List textList = _parseJsonList(sPage['text_data']);
      for (var txt in textList) {
        batch.insert(_db.canvasTextBlocks, 
          CanvasTextBlocksCompanion.insert(
            clientTextId: txt['id']?.toString() ?? uniqid(),
            pageId: localPageId,
            textData: jsonEncode(txt),
            isDeleted: const Value(0),
            syncedWithCloud: const Value(1),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }

      List imageList = _parseJsonList(sPage['image_data']);
      for (var img in imageList) {
        batch.insert(_db.canvasImageBlocks,
          CanvasImageBlocksCompanion.insert(
            clientImageId: img['id']?.toString() ?? uniqid(),
            pageId: localPageId,
            imagePath: img['image_path']?.toString() ?? '',
            posX: (img['dx'] as num?)?.toDouble() ?? 0.0,
            posY: (img['dy'] as num?)?.toDouble() ?? 0.0,
            width: (img['width'] as num?)?.toDouble() ?? 300.0,
            height: (img['height'] as num?)?.toDouble() ?? 200.0,
            rotation: (img['rotation'] as num?)?.toDouble() ?? 0.0,
            isDeleted: const Value(0),
            syncedWithCloud: const Value(1),
            updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          ),
          mode: InsertMode.insertOrReplace,
        );
      }
    });
  }

  List _parseJsonList(dynamic data) {
    if (data == null) return [];
    if (data is String) {
      try { return jsonDecode(data); } catch (_) { return []; }
    }
    if (data is Iterable) return List.from(data);
    return [];
  }
}
