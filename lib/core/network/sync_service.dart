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

      // 🛡️ SEGURANÇA: Só puxar páginas se o push local tiver tido sucesso
      // Isto evita apagar trabalho local não sincronizado.
      final bool pushSuccess = await pushPages();
      if (pushSuccess) {
        await pullPages();
      } else {
        debugPrint('⚠️ [Sync General] Push de páginas falhou. Pull adiado para proteger dados locais.');
      }
      
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

      final List<Map<String, dynamic>> payload = [];
      
      for (var s in unsynced) {
        // 🛡️ Garante que temos um UUID antes de enviar
        String effectiveUuid = s.clientId ?? uniqid();
        if (s.clientId == null) {
          await (_db.update(_db.subjects)..where((t) => t.id.equals(s.id))).write(
            SubjectsCompanion(clientId: Value(effectiveUuid))
          );
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

      final response = await _apiService.post('/sync/push', {'subjects': payload});

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        for (var item in data['synced_subjects'] ?? []) {
          final String clientUuid = item['client_id'].toString();
          final int serverId = item['server_id'];

          await (_db.update(_db.subjects)
                ..where((t) => t.clientId.equals(clientUuid)))
              .write(SubjectsCompanion(
                serverId: Value(serverId),
                syncedWithCloud: const Value(1),
              ));
        }
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

        await _db.transaction(() async {
          for (var sub in serverSubjects) {
            final int sId = sub['id'] is int ? sub['id'] : int.parse(sub['id'].toString());
            final String? cId = sub['client_id']?.toString();
            
            final companion = SubjectsCompanion.insert(
              serverId: Value(sId),
              clientId: Value(cId ?? uniqid()),
              userId: localUserId,
              name: sub['name'] ?? '',
              color: sub['color'] ?? '#0F4C5C',
              icon: Value(sub['icon']),
              isDeleted: Value(sub['deleted_at'] != null ? 1 : 0),
              syncedWithCloud: const Value(1),
              updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
            );

            // 🛡️ SEGURANÇA MÁXIMA: Busca manual para evitar erros de constraint ON CONFLICT
            final existing = await (_db.select(_db.subjects)..where((t) => t.clientId.equals(cId ?? ''))).getSingleOrNull();
            
            if (existing != null) {
              await (_db.update(_db.subjects)..where((t) => t.id.equals(existing.id))).write(
                SubjectsCompanion(
                  serverId: companion.serverId,
                  name: companion.name,
                  color: companion.color,
                  icon: companion.icon,
                  isDeleted: companion.isDeleted,
                  syncedWithCloud: companion.syncedWithCloud,
                  updatedAt: companion.updatedAt,
                )
              );
            } else {
              // Verificar se serverId já existe para evitar erro UNIQUE
              final existingByServerId = await (_db.select(_db.subjects)..where((t) => t.serverId.equals(sId))).getSingleOrNull();
              if (existingByServerId != null) {
                await (_db.update(_db.subjects)..where((t) => t.id.equals(existingByServerId.id))).write(companion);
              } else {
                await _db.into(_db.subjects).insert(companion);
              }
            }
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
        // 🛡️ Garante UUID para cadernos antigos
        String effectiveUuid = row.clientId ?? uniqid();
        if (row.clientId == null) {
           await (_db.update(_db.notebooks)..where((t) => t.id.equals(row.id))).write(
             NotebooksCompanion(clientId: Value(effectiveUuid))
           );
        }

        int? cloudSubjectId;
        if (row.subjectId != null) {
          final subject = await (_db.select(_db.subjects)..where((t) => t.id.equals(row.subjectId!))).getSingleOrNull();
          if (subject == null || subject.serverId == null) continue;
          cloudSubjectId = subject.serverId;
        }

        final map = row.toJson();
        map['subject_id'] = cloudSubjectId;
        map['client_id'] = effectiveUuid; // 🆔 UUID Real
        payload.add(map);
      }

      if (payload.isEmpty) return;

      final response = await _apiService.post('/sync/notebooks/push', {'notebooks': payload});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        
        for (var item in data['synced_notebooks'] ?? []) {
          final String clientUuid = item['client_id'].toString();
          final int serverId = item['server_id'];

          try {
            // 1. Localizar o caderno local pelo UUID
            final localRow = await (_db.select(_db.notebooks)..where((t) => t.clientId.equals(clientUuid))).getSingleOrNull();
            if (localRow == null) continue;

            final int localAutoId = localRow.id;

            // 🛡️ SEGURANÇA: Verificar se este server_id já está em uso por OUTRO registo local
            final existing = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(serverId) & t.id.equals(localAutoId).not())).getSingleOrNull();
            
            if (existing != null) {
              debugPrint('⚠️ [Sync] Detetada duplicação local para server_id $serverId. Mesclando...');
              // Se já temos um registo local com este server_id, apagamos o registo que acabámos de sincronizar (o que não tem serverId ainda)
              await (_db.delete(_db.notebooks)..where((t) => t.id.equals(localAutoId))).go();
            } else {
              // Atualização normal: associa o ID do servidor ao registo local
              await (_db.update(_db.notebooks)..where((t) => t.id.equals(localAutoId))).write(
                NotebooksCompanion(serverId: Value(serverId), syncedWithCloud: const Value(1))
              );
            }
          } catch (e) {
            debugPrint('🚨 Erro ao atualizar notebook $clientUuid: $e');
          }
        }
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

        await _db.transaction(() async {
          for (var net in serverNotebooks) {
            final int sId = net['id'] is int ? net['id'] : int.parse(net['id'].toString());
            final String? cId = net['client_id']?.toString();
            final int? serverSubId = net['subject_id'] != null 
                ? (net['subject_id'] is int ? net['subject_id'] : int.parse(net['subject_id'].toString()))
                : null;

            final int? localSubjectId = (serverSubId != null) ? subjectIdMap[serverSubId] : null;
            
            final companion = NotebooksCompanion.insert(
              serverId: Value(sId),
              clientId: Value(cId ?? uniqid()),
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

            // 🛡️ SEGURANÇA MÁXIMA: Busca manual para evitar erros de constraint ON CONFLICT
            final existing = await (_db.select(_db.notebooks)..where((t) => t.clientId.equals(cId ?? ''))).getSingleOrNull();
            
            if (existing != null) {
              await (_db.update(_db.notebooks)..where((t) => t.id.equals(existing.id))).write(
                NotebooksCompanion(
                  serverId: companion.serverId,
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
                )
              );
            } else {
              // Verificar se serverId já existe para evitar erro UNIQUE
              final existingByServerId = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(sId))).getSingleOrNull();
              if (existingByServerId != null) {
                await (_db.update(_db.notebooks)..where((t) => t.id.equals(existingByServerId.id))).write(companion);
              } else {
                await _db.into(_db.notebooks).insert(companion);
              }
            }
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
  Future<bool> pushPages() async {
    try {
      final unsyncedPages = await (_db.select(_db.pages)..where((t) => t.syncedWithCloud.equals(0))).get();
      if (unsyncedPages.isEmpty) return true; // Nada para sincronizar é considerado sucesso

      final List<Map<String, dynamic>> payloadPages = [];

      for (var row in unsyncedPages) {
        final notebook = await (_db.select(_db.notebooks)..where((t) => t.id.equals(row.notebookId))).getSingleOrNull();
        if (notebook == null || notebook.serverId == null) continue;

        // Se a página foi deletada offline, enviamos o sinal de deleção
        if (row.isDeleted == 1) {
          payloadPages.add({
            'notebook_id': notebook.serverId,
            'page_number': row.pageNumber,
            'client_id': row.clientId, // 🆔 Usar clientId global
            'server_id': row.serverId,
            'is_deleted': 1,
          });
          continue;
        }

        final allPages = await _canvasRepository.getPagesByNotebook(row.notebookId, null);
        final fullPage = allPages.firstWhere((p) => p.clientId == row.clientId, orElse: () => pages_model.LocalPage(notebookId: row.notebookId, pageNumber: row.pageNumber, isLandscape: row.isLandscape == 1, clientId: row.clientId));

        final map = await fullPage.toJsonAsync();
        map['notebook_id'] = notebook.serverId;
        map['is_deleted'] = 0;
        payloadPages.add(map);
      }

      if (payloadPages.isEmpty) return true;

      final response = await _apiService.post('/sync/pages/push', {'pages': payloadPages});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        await _db.batch((batch) {
          for (var item in data['synced_pages'] ?? []) {
            final String? clientId = item['client_id']?.toString();
            final dynamic rawServerId = item['server_id'] ?? item['serverId'];

            if (clientId != null && rawServerId != null) {
              final int serverId = rawServerId is int ? rawServerId : int.parse(rawServerId.toString());

              batch.update(_db.pages,
                PagesCompanion(
                  serverId: Value(serverId),
                  pageNumber: Value(item['page_number']),
                  syncedWithCloud: const Value(1),
                  updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
                ),
                where: (t) => t.clientId.equals(clientId),
              );
            }
          }
        });
        return true;
      }
else {
        debugPrint('❌ Servidor retornou erro ${response.statusCode} no PUSH Pages');
        return false;
      }
    } catch (e) {
      debugPrint('🚨 Erro PUSH Pages: $e');
      return false;
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
          final String? cId = sPage['client_id']?.toString();
          
          // 🚀 TRATAMENTO DE DELEÇÃO REMOTA
          if (sPage['deleted_at'] != null || sPage['is_deleted'] == 1) {
            if (cId != null) {
              await (_db.delete(_db.pages)..where((t) => t.clientId.equals(cId))).go();
            } else {
              await (_db.delete(_db.pages)..where((t) => t.serverId.equals(sId))).go();
            }
            continue;
          }

          final int sNotebookId = sPage['notebook_id'] is int ? sPage['notebook_id'] : int.parse(sPage['notebook_id'].toString());
          final notebook = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(sNotebookId))).getSingleOrNull();
          if (notebook == null) continue;

          final pageCompanion = PagesCompanion.insert(
            serverId: Value(sId),
            clientId: Value(cId ?? uniqid()),
            notebookId: notebook.id,
            pageNumber: sPage['page_number'],
            isLandscape: Value((sPage['is_landscape'] == true || sPage['is_landscape'] == 1) ? 1 : 0),
            headerData: Value(pages_model.LocalPage.encodeMeta(pages_model.LocalPage.parseMeta(sPage['header_data']))),
            footerData: Value(pages_model.LocalPage.encodeMeta(pages_model.LocalPage.parseMeta(sPage['footer_data']))),
            extractedText: Value(sPage['extracted_text']?.toString()),
            syncedWithCloud: const Value(1),
            updatedAt: Value(DateTime.parse(sPage['updated_at'].toString()).millisecondsSinceEpoch),
          );

          final existingPage = await (_db.select(_db.pages)..where((t) => t.clientId.equals(cId ?? ''))).getSingleOrNull();
          int localPageId;
          
          if (existingPage != null) {
            localPageId = existingPage.id;
            await (_db.update(_db.pages)..where((t) => t.id.equals(localPageId))).write(
              PagesCompanion(
                serverId: pageCompanion.serverId,
                pageNumber: pageCompanion.pageNumber,
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
    // 🛡️ ALINHAMENTO INTELIGENTE: Em vez de apagar tudo, comparamos item a item
    // utilizando a regra Last-Write-Wins (LWW) baseada no updatedAt.

    // 1. Obter dados locais para comparação
    final localStrokes = await (_db.select(_db.canvasStrokes)..where((t) => t.pageId.equals(localPageId))).get();
    final localTexts = await (_db.select(_db.canvasTextBlocks)..where((t) => t.pageId.equals(localPageId))).get();
    final localImages = await (_db.select(_db.canvasImageBlocks)..where((t) => t.pageId.equals(localPageId))).get();

    final Map<String, CanvasStroke> localStrokeMap = {for (var s in localStrokes) s.clientStrokeId: s};
    final Map<String, CanvasTextBlock> localTextMap = {for (var t in localTexts) t.clientTextId: t};
    final Map<String, CanvasImageBlock> localImageMap = {for (var i in localImages) i.clientImageId: i};

    await _db.batch((batch) {
      // --- SINCRONIZAR TRAÇOS ---
      List strokeList = _parseJsonList(sPage['stroke_data']);
      for (var st in strokeList) {
        final String id = st['id']?.toString() ?? uniqid();
        final int serverTime = (st['updated_at'] as num?)?.toInt() ?? 0;
        final bool serverDeleted = st['is_deleted'] == true || st['is_deleted'] == 1;

        final local = localStrokeMap[id];
        if (local == null || serverTime > local.updatedAt) {
          batch.insert(_db.canvasStrokes, 
            CanvasStrokesCompanion.insert(
              clientStrokeId: id,
              pageId: localPageId,
              strokeData: jsonEncode(st),
              isDeleted: Value(serverDeleted ? 1 : 0),
              deletedInSession: Value(st['deleted_in_session'] == true ? 1 : 0),
              syncedWithCloud: const Value(1),
              updatedAt: Value(serverTime > 0 ? serverTime : DateTime.now().millisecondsSinceEpoch),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      }

      // --- SINCRONIZAR TEXTOS ---
      List textList = _parseJsonList(sPage['text_data']);
      for (var txt in textList) {
        final String id = txt['id']?.toString() ?? uniqid();
        final int serverTime = (txt['updated_at'] as num?)?.toInt() ?? 0;
        final bool serverDeleted = txt['is_deleted'] == true || txt['is_deleted'] == 1;

        final local = localTextMap[id];
        if (local == null || serverTime > local.updatedAt) {
          batch.insert(_db.canvasTextBlocks, 
            CanvasTextBlocksCompanion.insert(
              clientTextId: id,
              pageId: localPageId,
              textData: jsonEncode(txt),
              isDeleted: Value(serverDeleted ? 1 : 0),
              deletedInSession: Value(txt['deleted_in_session'] == true ? 1 : 0),
              syncedWithCloud: const Value(1),
              updatedAt: Value(serverTime > 0 ? serverTime : DateTime.now().millisecondsSinceEpoch),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
      }

      // --- SINCRONIZAR IMAGENS ---
      List imageList = _parseJsonList(sPage['image_data']);
      for (var img in imageList) {
        final String id = img['id']?.toString() ?? uniqid();
        final int serverTime = (img['updated_at'] as num?)?.toInt() ?? 0;
        final bool serverDeleted = img['is_deleted'] == true || img['is_deleted'] == 1;

        final local = localImageMap[id];
        if (local == null || serverTime > local.updatedAt) {
          batch.insert(_db.canvasImageBlocks,
            CanvasImageBlocksCompanion.insert(
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
              updatedAt: Value(serverTime > 0 ? serverTime : DateTime.now().millisecondsSinceEpoch),
            ),
            mode: InsertMode.insertOrReplace,
          );
        }
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
