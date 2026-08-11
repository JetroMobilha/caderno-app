import 'dart:convert';
import 'package:drift/drift.dart' hide Column;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';

import '../../features/subjects/models/subject_model.dart' as subjects_model;
import '../../features/notebooks/models/notebook_model.dart' as notebooks_model;
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
  static int? activeNotebookId; // 🚀 ID do caderno aberto no momento

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
        await pushPages(); // 🚀 Primeiro enviamos o que é nosso
        await pullPages(); // 🚀 Depois baixamos as novidades
        
        await pushRecordings(); // 🚀 Sincronizar gravações de aula
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
      String? nextUrl = lastSynced != null ? '/sync/pull?last_synced_at=$lastSynced' : '/sync/pull';
      bool anyChanges = false;

      while (nextUrl != null) {
        final response = await _apiService.get(nextUrl);

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = await compute<String, Map<String, dynamic>>(
            (jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>,
            response.body,
          );

          // A nova API usa "data" para os itens na paginação, 
          // mas mantemos compatibilidade se o backend retornar "subjects" diretamente.
          final List serverSubjects = responseData['data'] ?? responseData['subjects'] ?? [];
          
          // Metadados de paginação
          final Map<String, dynamic> meta = responseData['meta'] ?? {};
          
          if (meta['server_time'] != null) {
            await prefs.setString('last_subjects_sync', meta['server_time']);
          } else if (responseData['server_time'] != null) {
            // Fallback para estrutura antiga
            await prefs.setString('last_subjects_sync', responseData['server_time']);
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
                
                // 🚀 LWW: Usar timestamp do servidor
                final int serverTime = sub['updated_at_ms'] != null 
                    ? (sub['updated_at_ms'] as num).toInt() 
                    : (sub['updated_at'] != null ? DateTime.parse(sub['updated_at'].toString()).millisecondsSinceEpoch : 0);

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
                );

                // 🚀 IDENTIDADE ÚNICA: Procurar estritamente pelo Client ID (UUID)
                final existing = await (_db.select(_db.subjects)..where((t) => t.clientId.equals(cId ?? ''))).getSingleOrNull();
                
                if (existing != null) {
                  // 🚀 REGRA LWW: Só atualizar se o servidor for mais recente
                  if (serverTime > existing.updatedAt) {
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
                  }
                } else {
                  // Se não existe pelo UUID, tentamos o Server ID (migração de legados)
                  final existingByServerId = await (_db.select(_db.subjects)..where((t) => t.serverId.equals(sId))).getSingleOrNull();
                  if (existingByServerId != null) {
                    if (serverTime > existingByServerId.updatedAt) {
                      await (_db.update(_db.subjects)..where((t) => t.id.equals(existingByServerId.id))).write(companion);
                    }
                  } else {
                    await _db.into(_db.subjects).insert(companion);
                  }
                }
              }
            });
          }
          
          // Seguir para a próxima página - Extração robusta
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

        final notebookObj = notebooks_model.Notebook(
          id: row.id,
          serverId: row.serverId,
          clientId: effectiveUuid,
          subjectId: cloudSubjectId, // Usamos o ID do servidor para a matéria
          title: row.title,
          coverType: row.coverType,
          color: row.color,
          coverImage: row.coverImage,
          lineType: row.lineType ?? 'ruled',
          paperSize: row.paperSize ?? 'A4',
          lineSpacing: row.lineSpacing,
          templateType: row.templateType,
          collaborationMode: row.collaborationMode, // 🚀
          isPublished: row.isPublished,
          price: row.price,
          description: row.description,
          authorName: row.authorName,
          syncedWithCloud: row.syncedWithCloud,
          isDeleted: row.isDeleted,
          updatedAt: row.updatedAt,
        );

        payload.add(notebookObj.toJson());
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
                NotebooksCompanion(
                  serverId: Value(serverId), 
                  syncedWithCloud: const Value(1),
                )
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
      String? nextUrl = lastSynced != null ? '/sync/notebooks/pull?last_synced_at=$lastSynced' : '/sync/notebooks/pull';
      bool anyChanges = false;

      while (nextUrl != null) {
        final response = await _apiService.get(nextUrl);

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = await compute<String, Map<String, dynamic>>(
            (jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>,
            response.body,
          );

          final List serverNotebooks = responseData['data'] ?? responseData['notebooks'] ?? [];
          final Map<String, dynamic> meta = responseData['meta'] ?? {};

          if (meta['server_time'] != null) {
            await prefs.setString('last_notebooks_sync', meta['server_time']);
          } else if (responseData['server_time'] != null) {
            await prefs.setString('last_notebooks_sync', responseData['server_time']);
          }

          if (serverNotebooks.isNotEmpty) {
            anyChanges = true;

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
                
                // 🚀 LWW: Usar timestamp do servidor
                final int serverTime = net['updated_at_ms'] != null 
                    ? (net['updated_at_ms'] as num).toInt() 
                    : (net['updated_at'] != null ? DateTime.parse(net['updated_at'].toString()).millisecondsSinceEpoch : 0);

                final companion = NotebooksCompanion.insert(
                  serverId: Value(sId),
                  clientId: Value(cId ?? uniqid()),
                  subjectId: Value(localSubjectId),
                  title: net['title'] ?? '',
                  coverType: net['cover_type'] ?? 'color',
                  color: Value(net['color']),
                  coverImage: Value(net['cover_image']),
                  lineType: Value(net['line_type'] ?? 'ruled'),
                  lineSpacing: Value(net['line_spacing'] != null ? double.tryParse(net['line_spacing'].toString()) : null),
                  paperSize: Value(net['paper_size'] ?? 'A4'),
                  templateType: Value(net['template_type'] ?? 'study'),
                  collaborationMode: Value(net['collaboration_mode'] ?? 'study_group'),
                  isPublished: Value(int.tryParse(net['is_published']?.toString() ?? '0') ?? 0),
                  price: Value(double.tryParse(net['price']?.toString() ?? '0.0') ?? 0.0),
                  description: Value(net['description']),
                  authorName: Value(net['author_name']),
                  isDeleted: Value(net['deleted_at'] != null ? 1 : 0),
                  syncedWithCloud: const Value(1),
                  updatedAt: Value(serverTime),
                );

                // 🚀 IDENTIDADE ÚNICA: Procurar estritamente pelo Client ID (UUID)
                final existing = await (_db.select(_db.notebooks)..where((t) => t.clientId.equals(cId ?? ''))).getSingleOrNull();
                
                if (existing != null) {
                  // 🚀 REGRA LWW
                  if (serverTime > existing.updatedAt) {
                    await (_db.update(_db.notebooks)..where((t) => t.id.equals(existing.id))).write(
                      NotebooksCompanion(
                        serverId: companion.serverId,
                        subjectId: companion.subjectId,
                        title: companion.title,
                        coverType: companion.coverType,
                        color: companion.color,
                        coverImage: companion.coverImage,
                        lineType: companion.lineType,
                        lineSpacing: companion.lineSpacing,
                        paperSize: companion.paperSize,
                        templateType: companion.templateType,
                        collaborationMode: companion.collaborationMode,
                        isPublished: companion.isPublished,
                        price: companion.price,
                        description: companion.description,
                        authorName: companion.authorName,
                        isDeleted: companion.isDeleted,
                        syncedWithCloud: companion.syncedWithCloud,
                        updatedAt: companion.updatedAt,
                      )
                    );
                  }
                } else {
                  // Se não existe pelo UUID, tentamos o Server ID (migração de legados)
                  final existingByServerId = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(sId))).getSingleOrNull();
                  if (existingByServerId != null) {
                    if (serverTime > existingByServerId.updatedAt) {
                      await (_db.update(_db.notebooks)..where((t) => t.id.equals(existingByServerId.id))).write(companion);
                    }
                  } else {
                    await _db.into(_db.notebooks).insert(companion);
                  }
                }
              }
            });

            // Sincronizar roles de NotebookUser
            final allNotebooksAfter = await _db.select(_db.notebooks).get();
            final Map<int, int> notebookIdMap = {for (var n in allNotebooksAfter) if (n.serverId != null) n.serverId!: n.id};

            await _db.batch((batch) {
              for (var net in serverNotebooks) {
                final sId = net['id'];
                final localNotebookId = notebookIdMap[sId];
                final dynamic rawSubId = net['subject_id'];
                final int? serverSubId = rawSubId != null ? int.tryParse(rawSubId.toString()) : null;
                
                final String? role = net['role']?.toString();
                
                // 🚀 LÓGICA DE PARTILHA MELHORADA (Usando Injeção de Role do Servidor)
                if (localNotebookId != null && currentUserId > 0) {
                  // É partilhado se a role não for 'owner' OU se a disciplina não for nossa
                  bool isShared = (role != null && role != 'owner');
                  
                  if (!isShared && serverSubId != null && !subjectIdMap.containsKey(serverSubId)) {
                      isShared = true;
                  }

                  if (isShared) {
                    debugPrint('🤝 [Sync] Caderno $sId ("${net['title']}") detetado como PARTILHADO. Role: $role');
                    
                    batch.insert(_db.notebookUser, 
                      NotebookUserCompanion.insert(
                        notebookId: localNotebookId,
                        userId: currentUserId,
                        role: Value(role ?? 'viewer'),
                        syncedWithCloud: const Value(1),
                        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
                      ),
                      mode: InsertMode.insertOrReplace,
                    );
                  }
                }
              }
            });
          }

          nextUrl = _extractNextUrl(responseData);
        } else {
          throw Exception('Erro ${response.statusCode} no PULL Notebooks');
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
      if (onlyNotebookId != null) {
        query.where((t) => t.notebookId.equals(onlyNotebookId));
      }
      
      final unsyncedPages = await query.get();
      if (unsyncedPages.isEmpty) return true;

      // 🚀 PRIORIZAÇÃO: Enviar páginas deletadas primeiro para evitar conflitos de numeração
      unsyncedPages.sort((a, b) => b.isDeleted.compareTo(a.isDeleted));

      bool allSuccess = true;

      for (var row in unsyncedPages) {
        try {
          final notebook = await (_db.select(_db.notebooks)..where((t) => t.id.equals(row.notebookId))).getSingleOrNull();
          if (notebook == null || notebook.serverId == null) continue;

          Map<String, dynamic> pageMap;
          pages_model.LocalPage? fullPage;

          if (row.isDeleted == 1) {
            pageMap = {
              'notebook_id': notebook.serverId,
              'page_number': row.pageNumber,
              'client_id': row.clientId,
              'server_id': row.serverId,
              'is_deleted': 1,
            };
          } else {
            final allPages = await _canvasRepository.getPagesByNotebook(row.notebookId, null);
            fullPage = allPages.firstWhere(
              (p) => p.clientId == row.clientId, 
              orElse: () => pages_model.LocalPage(notebookId: row.notebookId, pageNumber: row.pageNumber, isLandscape: row.isLandscape == 1, clientId: row.clientId)
            );

            // 🚀 ESTRATÉGIA DE PAYLOAD ADAPTATIVA (ANTI-500)
            int totalPoints = fullPage.strokes.fold(0, (sum, s) => sum + s.points.length);
            
            if (totalPoints > 1000) {
              // 🚀 EMERGÊNCIA: Se a página for muito densa, simplificar agressivamente para o Sync
              fullPage.strokes = fullPage.strokes.map((s) => s.simplify(epsilon: 0.5)).toList();
              debugPrint('⚠️ [Sync] Página muito pesada ($totalPoints pts). Simplificação de emergência aplicada.');
            } else {
              // Simplificação leve padrão
              fullPage.strokes = fullPage.strokes.map((s) => s.simplify(epsilon: 0.2)).toList();
            }

            pageMap = await fullPage.toJsonAsync();
            pageMap['notebook_id'] = notebook.serverId;
            pageMap['is_deleted'] = 0;
          }

          debugPrint('[SYNC-LOG] 📤 Enviando página ${row.pageNumber} (${row.clientId}). IsDeleted: ${row.isDeleted == 1}');
          var response = await _apiService.post('/sync/pages/push', {'pages': [pageMap]});

          // 🚀 FALLBACK PARA PAYLOAD TOO LARGE (Estratégia de Simplificação Progressiva)
          if ((response.statusCode == 500 || response.statusCode == 502 || response.statusCode == 413) && 
              (response.body.contains('Payload too large') || response.body.contains('Request Entity Too Large')) && 
              row.isDeleted == 0) {
            debugPrint('⚠️ [Sync] Payload rejeitado. Tentando simplificação agressiva (epsilon 1.0)...');
            final allPages = await _canvasRepository.getPagesByNotebook(row.notebookId, null);
            final retryPage = allPages.firstWhere((p) => p.clientId == row.clientId);
            
            // Simplificação agressiva (epsilon 1.0) para garantir que cabe no pacote
            retryPage.strokes = retryPage.strokes.map((s) => s.simplify(epsilon: 1.0)).toList();
            
            final retryMap = await retryPage.toJsonAsync();
            retryMap['notebook_id'] = notebook.serverId;
            retryMap['is_deleted'] = 0;
            
            response = await _apiService.post('/sync/pages/push', {'pages': [retryMap]});
          }

          if (response.statusCode == 200 || response.statusCode == 201) {
            final data = jsonDecode(response.body);
            final syncedItem = (data['synced_pages'] as List?)?.first;

            if (syncedItem != null) {
              final String? clientId = syncedItem['client_id']?.toString();
              final dynamic rawServerId = syncedItem['server_id'] ?? syncedItem['serverId'];
              final String? status = syncedItem['status']?.toString();

              if (status == 'ignored_old') {
                debugPrint('⚠️ [Sync] Página ${row.pageNumber} rejeitada pelo servidor (ignored_old). Forçando PULL por ClientID...');
                // 🚀 ESTRATÉGIA ROBUSTA: Puxar pelo ClientId unívoco, ignorando o número da página local que pode estar errado
                await pullSpecificPage(notebook.serverId!, row.pageNumber, clientId: row.clientId);
                continue;
              }

              if (clientId != null && rawServerId != null) {
                final int serverId = rawServerId is int ? rawServerId : int.parse(rawServerId.toString());

                await (_db.update(_db.pages)..where((t) => t.clientId.equals(clientId))).write(
                  PagesCompanion(
                    serverId: Value(serverId),
                    pageNumber: Value(syncedItem['page_number']),
                    syncedWithCloud: const Value(1),
                    // 🚀 ALINHAMENTO: Usar o tempo original da página que foi enviada 
                    // para manter consistência com o servidor.
                    updatedAt: Value(fullPage?.updatedAt ?? row.updatedAt),
                  ),
                );
                debugPrint('✅ [Sync] Página ${row.pageNumber} sincronizada.');
              }
            }
          } else {
            debugPrint('❌ [Sync] Erro ${response.statusCode} ao enviar página ${row.pageNumber}');
            allSuccess = false;
          }
        } catch (e) {
          debugPrint('🚨 [Sync] Exceção ao processar página ${row.pageNumber}: $e');
          allSuccess = false;
        }
      }

      return allSuccess;
    } catch (e) {
      debugPrint('🚨 Erro PUSH Pages: $e');
      return false;
    }
  }

  Future<bool> pullPages({bool forceFull = false, int? onlyNotebookId}) async {
    final prefs = await SharedPreferences.getInstance();
    
    final localCount = await _db.pages.count().getSingle();
    final String? lastSynced = (localCount > 0 && !forceFull) ? prefs.getString('last_pages_sync') : null;

    try {
      String? baseUrl = '/sync/pages/pull';
      if (lastSynced != null) {
        baseUrl += '?last_synced_at=$lastSynced';
      }
      if (onlyNotebookId != null) {
        baseUrl += (lastSynced != null ? '&' : '?') + 'notebook_id=$onlyNotebookId';
      }
      
      String? nextUrl = baseUrl;
      bool anyChanges = false;
      final Set<String> serverClientIds = {};

      while (nextUrl != null) {
        debugPrint('[SYNC-LOG] 🛫 GET $nextUrl');
        final response = await _apiService.get(nextUrl);

        if (response.statusCode == 200) {
          final Map<String, dynamic> responseData = await compute<String, Map<String, dynamic>>(
            (jsonStr) => jsonDecode(jsonStr) as Map<String, dynamic>,
            response.body,
          );
          
          final List serverPages = responseData['data'] ?? responseData['pages'] ?? [];
          final Map<String, dynamic> meta = responseData['meta'] ?? {};

          if (meta['server_time'] != null) {
            await prefs.setString('last_pages_sync', meta['server_time']);
          } else if (responseData['server_time'] != null) {
            await prefs.setString('last_pages_sync', responseData['server_time']);
          }

          if (serverPages.isNotEmpty) {
            anyChanges = true;

            for (var sPage in serverPages) {
              final int sNotebookId = sPage['notebook_id'] is int ? sPage['notebook_id'] : int.parse(sPage['notebook_id'].toString());
              final int sId = sPage['id'] is int ? sPage['id'] : int.parse(sPage['id'].toString());
              final String? cId = sPage['client_id']?.toString();
              if (cId != null) serverClientIds.add(cId);
              
              // 🚀 TRATAMENTO DE DELEÇÃO REMOTA
              if (sPage['deleted_at'] != null || sPage['is_deleted'] == 1) {
                if (cId != null) {
                  await (_db.delete(_db.pages)..where((t) => t.clientId.equals(cId))).go();
                } else {
                  await (_db.delete(_db.pages)..where((t) => t.serverId.equals(sId))).go();
                }
                continue;
              }

              final notebook = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(sNotebookId))).getSingleOrNull();
              if (notebook == null) continue;

              // 🚀 PRECISÃO DE MILISSEGUNDOS: Usar updated_at_ms vindo do Laravel
              final int serverTs = sPage['updated_at_ms'] != null 
                  ? (sPage['updated_at_ms'] as num).toInt() 
                  : (sPage['updated_at'] != null ? DateTime.parse(sPage['updated_at'].toString()).millisecondsSinceEpoch : 0);

              final pageCompanion = PagesCompanion.insert(
                serverId: Value(sId),
                clientId: Value(cId ?? uniqid()),
                notebookId: notebook.id,
                pageNumber: sPage['page_number'],
                isLandscape: Value((sPage['is_landscape'] == true || sPage['is_landscape'] == 1) ? 1 : 0),
                isFrozen: Value((sPage['is_frozen'] == true || sPage['is_frozen'] == 1) ? 1 : 0),
                paperSize: Value(sPage['paper_size']?.toString() ?? 'A4'),
                headerData: Value(pages_model.LocalPage.encodeMeta(pages_model.LocalPage.parseMeta(sPage['header_data']))),
                footerData: Value(pages_model.LocalPage.encodeMeta(pages_model.LocalPage.parseMeta(sPage['footer_data']))),
                extractedText: Value(sPage['extracted_text']?.toString()),
                syncedWithCloud: const Value(1),
                updatedAt: Value(serverTs),
              );

              // 🚀 IDENTIDADE ÚNICA: Procurar estritamente pelo Client ID (UUID) para evitar "páginas fantasmas"
              final existingPage = await (_db.select(_db.pages)..where((t) => t.clientId.equals(cId ?? ''))).getSingleOrNull();
              int localPageId;
              
              if (existingPage != null) {
                localPageId = existingPage.id;

                // 🛡️ INTEGRIDADE: Se o Client ID já existe mas noutro caderno, ignorar (evita sequestro de folhas)
                if (existingPage.notebookId != pageCompanion.notebookId.value) {
                   debugPrint('⚠️ [Sync] Conflito de integridade: Folha $cId pertence ao caderno ${existingPage.notebookId}, mas o servidor diz que é do caderno ${pageCompanion.notebookId.value}. Ignorando.');
                   continue; 
                }

                // 🚀 LWW
                if (serverTs > existingPage.updatedAt) {
                  await (_db.update(_db.pages)..where((t) => t.id.equals(localPageId))).write(
                    PagesCompanion(
                      serverId: pageCompanion.serverId,
                      notebookId: pageCompanion.notebookId,
                      pageNumber: pageCompanion.pageNumber,
                      headerData: pageCompanion.headerData,
                      footerData: pageCompanion.footerData,
                      isLandscape: pageCompanion.isLandscape,
                      paperSize: pageCompanion.paperSize,
                      extractedText: pageCompanion.extractedText,
                      syncedWithCloud: pageCompanion.syncedWithCloud,
                      updatedAt: pageCompanion.updatedAt,
                    )
                  );
                }
              } else {
                 // 🚀 LÓGICA DE ADOÇÃO: Se não encontramos pelo UUID, verificamos se existe uma folha local VAZIA no mesmo lugar
                 final int pNum = sPage['page_number'];
                 final emptyMatch = await (_db.select(_db.pages)..where((t) => t.notebookId.equals(notebook.id) & t.pageNumber.equals(pNum))).getSingleOrNull();
                 
                 if (emptyMatch != null) {
                    // Verificar se está realmente vazia (sem strokes, textos ou imagens)
                    final sCount = await (_db.select(_db.canvasStrokes)..where((t) => t.pageId.equals(emptyMatch.id))).get();
                    final tCount = await (_db.select(_db.canvasTextBlocks)..where((t) => t.pageId.equals(emptyMatch.id))).get();
                    final iCount = await (_db.select(_db.canvasImageBlocks)..where((t) => t.pageId.equals(emptyMatch.id))).get();
                    
                    if (sCount.isEmpty && tCount.isEmpty && iCount.isEmpty) {
                       debugPrint('🤝 [Sync] Adotando folha local vazia $pNum para o UUID remoto $cId');
                       localPageId = emptyMatch.id;
                       // 🚀 ATUALIZAÇÃO TOTAL: Não mudar apenas o ID, mas todos os metadados da página
                       await (_db.update(_db.pages)..where((t) => t.id.equals(localPageId))).write(
                         PagesCompanion(
                           clientId: Value(cId ?? uniqid()),
                           serverId: pageCompanion.serverId,
                           headerData: pageCompanion.headerData,
                           footerData: pageCompanion.footerData,
                           isLandscape: pageCompanion.isLandscape,
                           updatedAt: pageCompanion.updatedAt,
                           syncedWithCloud: const Value(1),
                         )
                       );
                    } else {
                       localPageId = await _db.into(_db.pages).insert(pageCompanion);
                    }
                 } else {
                    // Fallback para Server ID (Legados)
                    final existingByServerId = sId > 0 
                        ? await (_db.select(_db.pages)..where((t) => t.serverId.equals(sId))).getSingleOrNull()
                        : null;
                        
                    if (existingByServerId != null) {
                        localPageId = existingByServerId.id;
                        if (serverTs > existingByServerId.updatedAt) {
                          await (_db.update(_db.pages)..where((t) => t.id.equals(localPageId))).write(pageCompanion);
                        }
                    } else {
                        localPageId = await _db.into(_db.pages).insert(pageCompanion);
                    }
                 }
              }

              await _pullCanvasData(localPageId, sPage, serverTs: serverTs);
            }
          }
          
          nextUrl = _extractNextUrl(responseData);
        } else {
          throw Exception('Erro ${response.statusCode} no PULL Pages');
        }
      }

      // 🚀 LIMPEZA DE "PÁGINAS FANTASMAS" (Apenas em Pull TOTAL para garantir lista completa)
      if (forceFull) {
        debugPrint('[SYNC-LOG] 🔍 Iniciando limpeza de fantasmas. Servidor tem: ${serverClientIds.length} páginas.');
        // Buscar todas as páginas locais sincronizadas
        final query = _db.select(_db.pages)..where((t) => t.syncedWithCloud.equals(1));
        if (onlyNotebookId != null) {
          // Precisamos do localId do notebook se passámos o serverId
          final nb = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(onlyNotebookId))).getSingleOrNull();
          if (nb != null) {
            query.where((t) => t.notebookId.equals(nb.id));
          }
        }
        
        final localSyncedPages = await query.get();
        
        for (var lp in localSyncedPages) {
          if (!serverClientIds.contains(lp.clientId)) {
            debugPrint('🗑️ [Sync] Removendo folha fantasma local: ${lp.pageNumber} (${lp.clientId})');
            await (_db.delete(_db.pages)..where((t) => t.id.equals(lp.id))).go();
          }
        }
      }

      return anyChanges;
    } catch (e) {
      debugPrint('🚨 Erro PULL Pages: $e');
      rethrow;
    }
  }

  Future<void> pullSpecificPage(int notebookServerId, int pageNumber, {String? clientId, bool isRetry = false}) async {
    try {
      debugPrint('🔍 [Sync] Iniciando PULL específico: Notebook $notebookServerId, Página $pageNumber ${clientId != null ? "(CID: $clientId)" : ""} ${isRetry ? "(Retry)" : ""}');
      
      String url = '/sync/pages/pull?notebook_id=$notebookServerId';
      if (clientId != null) {
        url += '&client_id=$clientId';
      } else {
        url += '&page_number=$pageNumber';
      }

      final response = await _apiService.get(url);
      if (response.statusCode == 200) {
        final Map<String, dynamic> responseData = jsonDecode(response.body);
        final List serverPages = responseData['data'] ?? responseData['pages'] ?? [];
        if (serverPages.isNotEmpty) {
          final sPage = serverPages.first;
          final int sId = sPage['id'] is int ? sPage['id'] : int.parse(sPage['id'].toString());
          final String? cId = sPage['client_id']?.toString();
          final int incomingNotebookId = int.tryParse(sPage['notebook_id']?.toString() ?? '') ?? 0;

          // 🚀 TRAVA DE SEGURANÇA: Validar se a página pertence ao caderno solicitado
          if (incomingNotebookId != notebookServerId) {
            debugPrint('⚠️ [Sync] Abortando PULL específico: Servidor retornou página do caderno $incomingNotebookId para o pedido do caderno $notebookServerId');
            return;
          }

          final notebook = await (_db.select(_db.notebooks)..where((t) => t.serverId.equals(notebookServerId))).getSingleOrNull();
          if (notebook == null) {
            debugPrint('⚠️ [Sync] Notebook $notebookServerId não encontrado no DB local.');
            return;
          }

          final int serverTs = sPage['updated_at_ms'] != null 
              ? (sPage['updated_at_ms'] as num).toInt() 
              : (sPage['updated_at'] != null ? DateTime.parse(sPage['updated_at'].toString()).millisecondsSinceEpoch : 0);

          final pageCompanion = PagesCompanion.insert(
            serverId: Value(sId),
            clientId: Value(cId ?? uniqid()),
            notebookId: notebook.id,
            pageNumber: sPage['page_number'],
            isLandscape: Value((sPage['is_landscape'] == true || sPage['is_landscape'] == 1) ? 1 : 0),
            isFrozen: Value((sPage['is_frozen'] == true || sPage['is_frozen'] == 1) ? 1 : 0),
            paperSize: Value(sPage['paper_size']?.toString() ?? 'A4'),
            headerData: Value(pages_model.LocalPage.encodeMeta(pages_model.LocalPage.parseMeta(sPage['header_data']))),
            footerData: Value(pages_model.LocalPage.encodeMeta(pages_model.LocalPage.parseMeta(sPage['footer_data']))),
            extractedText: Value(sPage['extracted_text']?.toString()),
            syncedWithCloud: const Value(1),
            updatedAt: Value(serverTs),
          );

          // 🚀 IDENTIDADE ÚNICA: Procurar estritamente pelo Client ID (UUID)
          final existingPage = await (_db.select(_db.pages)..where((t) => t.clientId.equals(cId ?? ''))).getSingleOrNull();
          int localPageId;

          if (existingPage != null) {
            localPageId = existingPage.id;

            // 🛡️ INTEGRIDADE: Validar se a página pertence ao caderno local correto
            if (existingPage.notebookId != pageCompanion.notebookId.value) {
                debugPrint('⚠️ [Sync] Conflito crítico: UUID $cId já existe no caderno ${existingPage.notebookId}. Servidor tentou mover para $notebookServerId. Abortando.');
                return;
            }

            if (serverTs > existingPage.updatedAt) {
              await (_db.update(_db.pages)..where((t) => t.id.equals(localPageId))).write(
                PagesCompanion(
                  serverId: pageCompanion.serverId,
                  notebookId: pageCompanion.notebookId,
                  pageNumber: pageCompanion.pageNumber,
                  headerData: pageCompanion.headerData,
                  footerData: pageCompanion.footerData,
                  isLandscape: pageCompanion.isLandscape,
                  paperSize: pageCompanion.paperSize,
                  extractedText: pageCompanion.extractedText,
                  syncedWithCloud: pageCompanion.syncedWithCloud,
                  updatedAt: pageCompanion.updatedAt,
                )
              );
              debugPrint('📝 [Sync] Atualizando Folha $pageNumber (ID Local: $localPageId)');
            }
          } else {
            // Fallback para Server ID (Legados)
            final existingByServerId = sId > 0 
                ? await (_db.select(_db.pages)..where((t) => t.serverId.equals(sId))).getSingleOrNull()
                : null;
                
            if (existingByServerId != null) {
               localPageId = existingByServerId.id;
               if (serverTs > existingByServerId.updatedAt) {
                 await (_db.update(_db.pages)..where((t) => t.id.equals(localPageId))).write(pageCompanion);
               }
            } else {
               localPageId = await _db.into(_db.pages).insert(pageCompanion);
               debugPrint('🆕 [Sync] Criando Folha $pageNumber (ID Local: $localPageId)');
            }
          }
          
          await _pullCanvasData(localPageId, sPage, serverTs: serverTs);
          debugPrint('✅ [Sync] PULL específico concluído para Folha $pageNumber');
        } else {
          debugPrint('ℹ️ [Sync] Nenhum dado encontrado no servidor para Folha $pageNumber');
          if (!isRetry) {
             debugPrint('🔄 [Sync] Retentativa de PULL em 2s para Folha $pageNumber...');
             await Future.delayed(const Duration(seconds: 2));
             return pullSpecificPage(notebookServerId, pageNumber, isRetry: true);
          }
        }
      } else {
        debugPrint('🚨 [Sync] Erro ${response.statusCode} no PULL específico');
      }
    } catch (e) {
      debugPrint('🚨 Erro PULL Specific Page: $e');
    }
  }

  Future<void> _pullCanvasData(int localPageId, Map sPage, {int? serverTs}) async {
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
        // 🚀 REGRA DE OURO (Merge por IDs únicos e Timestamp):
        // Só atualizamos se:
        // 1. O traço não existe localmente (Novo)
        // 2. O timestamp do servidor é maior (LWW)
        if (local == null || serverTime > local.updatedAt) {
           // 🛡️ PROTEÇÃO CONTRA FANTASMAS: Se o traço existe mas em outra página, ele será MOVIDO para esta
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

    // 🚀 FORÇAR REATIVIDADE:    // Usamos o serverTs se disponível para manter o Fingerprint sincronizado com o proprietário
    await (_db.update(_db.pages)..where((t) => t.id.equals(localPageId))).write(
      PagesCompanion(
        updatedAt: Value(serverTs ?? DateTime.now().millisecondsSinceEpoch),
      )
    );
  }

  /// Extrai a URL da próxima página de forma robusta, lidando com o campo 'links'
  /// sendo um Mapa (guia) ou uma Lista (padrão Laravel).
  String? _extractNextUrl(Map<String, dynamic> responseData) {
    final dynamic links = responseData['links'];
    
    if (links is Map) {
      return links['next']?.toString();
    }
    
    if (links is List) {
      // Procura pelo link com label "Next »" ou similar
      for (var link in links) {
        if (link is Map && link['label']?.toString().contains('Next') == true) {
          return link['url']?.toString();
        }
      }
    }

    // Fallback para campos comuns do Laravel fora do objeto 'links'
    return responseData['next_page_url']?.toString();
  }

  List _parseJsonList(dynamic data) {
    if (data == null) return [];
    if (data is String) {
      try { return jsonDecode(data); } catch (_) { return []; }
    }
    if (data is Iterable) return List.from(data);
    return [];
  }

  // =========================================================================
  // 🎙️ 5. GRAVAÇÕES DE AULA (RECORDINGS)
  // =========================================================================
  Future<void> pushRecordings() async {
    try {
      final unsynced = await (_db.select(_db.lessonRecordings)..where((t) => t.syncedWithCloud.equals(0))).get();
      if (unsynced.isEmpty) return;

      final List<Map<String, dynamic>> payload = [];
      for (var row in unsynced) {
        // 🚀 CRÍTICO: Buscar o server_id do caderno, pois o backend usa chaves estrangeiras reais
        final notebookRow = await (_db.select(_db.notebooks)..where((t) => t.id.equals(row.notebookId))).getSingleOrNull();
        final int? serverNotebookId = notebookRow?.serverId;
        
        if (serverNotebookId != null) {
          payload.add({
            'notebook_id': serverNotebookId,
            'client_id': row.clientId,
            'title': row.title,
            'audio_url': row.audioUrl,
            'duration_seconds': row.durationSeconds,
            'updated_at': row.updatedAt,
          });
        } else {
          debugPrint('⚠️ [Sync] Pulando gravação ${row.clientId} - Caderno local ${row.notebookId} ainda não tem server_id.');
        }
      }

      final response = await _apiService.post('/sync/recordings/push', {'recordings': payload});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        for (var item in data['synced_recordings'] ?? []) {
          final String clientUuid = item['client_id'].toString();
          final int serverId = item['server_id'];

          await (_db.update(_db.lessonRecordings)..where((t) => t.clientId.equals(clientUuid))).write(
            LessonRecordingsCompanion(
              serverId: Value(serverId),
              syncedWithCloud: const Value(1),
            )
          );
        }
      }
    } catch (e) {
      debugPrint('🚨 Erro PUSH Recordings: $e');
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

        // 🚀 MAPEAR SERVER_ID PARA LOCAL_ID (Para evitar erro de chave estrangeira)
        final allNotebooks = await _db.select(_db.notebooks).get();
        final Map<int, int> serverToLocalNotebookId = {
          for (var n in allNotebooks) if (n.serverId != null) n.serverId!: n.id
        };

        if (data['meta'] != null && data['meta']['server_time'] != null) {
          await prefs.setString('last_recordings_sync', data['meta']['server_time']);
        }

        await _db.batch((batch) {
          for (var rec in serverRecordings) {
            final int sId = rec['id'];
            final String? cId = rec['client_id'];
            final int serverTs = rec['updated_at_ms'] ?? 0;
            final int? sNotebookId = rec['notebook_id'];
            
            final int? localNotebookId = serverToLocalNotebookId[sNotebookId];
            
            if (localNotebookId == null) {
              debugPrint('⚠️ [Sync] Pulando gravação $sId - Caderno server_id $sNotebookId não encontrado localmente.');
              continue;
            }

            batch.insert(_db.lessonRecordings,
              LessonRecordingsCompanion.insert(
                serverId: Value(sId),
                clientId: Value(cId ?? Uuid().v4()),
                notebookId: localNotebookId,
                title: rec['title'] ?? 'Sem título',
                audioUrl: rec['audio_url'] ?? '',
                durationSeconds: Value(rec['duration_seconds'] ?? 0),
                syncedWithCloud: const Value(1),
                updatedAt: Value(serverTs),
              ),
              mode: InsertMode.insertOrReplace,
            );
          }
        });
      }
    } catch (e) {
      debugPrint('🚨 Erro PULL Recordings: $e');
    }
  }
}
