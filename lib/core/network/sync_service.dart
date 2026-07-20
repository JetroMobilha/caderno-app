import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/canvas/models/local_page_model.dart';
import '../../features/canvas/repositories/canvas_repository.dart';
import '../database/database_helper.dart';
import 'api_service.dart';

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService();
  final CanvasRepository _canvasRepository = CanvasRepository();

  static bool isCollaborationActive = false;

  // 🚀 A ANTENA GLOBAL
  static final ValueNotifier<Map<int, int>> syncedPagesRadio = ValueNotifier({});
  static final ValueNotifier<Map<int, int>> syncedNoteBooksRadio = ValueNotifier({});

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

    await pushOfflineSubjects();
    await pullSubjects();

    await pushNotebooks();
    await pullNotebooks();

    await pushPages();
    await pullPages();

    debugPrint('🏆 [Sync General] Ciclo Concluído com Sucesso!');
  }

  // =========================================================================
  // 2. DISCIPLINAS (SUBJECTS)
  // =========================================================================
  Future<void> pushOfflineSubjects() async {
    final db = await _dbHelper.database;
    try {
      final unsynced = await db.query('subjects', where: 'synced_with_cloud = ?', whereArgs: [0]);
      if (unsynced.isEmpty) return;

      final response = await _apiService.post('/sync/push', {'subjects': unsynced});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        for (var item in data['synced_subjects']) {
          await db.update('subjects', {'server_id': item['server_id'], 'synced_with_cloud': 1}, where: 'id = ?', whereArgs: [item['client_id']]);
        }
      }
    } catch (e) {
      debugPrint('🚨 Erro PUSH Subjects: $e');
    }
  }

  Future<bool> pullSubjects() async {
    final db = await _dbHelper.database;
    final prefs = await SharedPreferences.getInstance();
    final lastSynced = prefs.getString('last_subjects_sync');

    try {
      final endpoint = lastSynced != null ? '/sync/pull?last_synced_at=$lastSynced' : '/sync/pull';
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List serverSubjects = data['subjects'] ?? [];
        if (data['server_time'] != null) await prefs.setString('last_subjects_sync', data['server_time']);

        if (serverSubjects.isEmpty) return false;

        for (var sub in serverSubjects) {
          final existing = await db.query('subjects', where: 'server_id = ?', whereArgs: [sub['id']]);

          final payload = {
            'server_id': sub['id'],
            'user_id': sub['user_id'],
            'name': sub['name'],
            'color': sub['color'],
            'icon': sub['icon'],
            // 🚀 A CORREÇÃO ANTI-FANTASMA AQUI! Lê o deleted_at da nuvem!
            'is_deleted': sub['deleted_at'] != null ? 1 : 0,
            'synced_with_cloud': 1,
            'updated_at': DateTime.now().millisecondsSinceEpoch,
          };

          if (existing.isEmpty) {
            await db.insert('subjects', payload);
          } else {
            await db.update('subjects', payload, where: 'server_id = ?', whereArgs: [sub['id']]);
          }
        }
        return true;
      }
    } catch (e) {
      debugPrint('🚨 Erro PULL Subjects: $e');
    }
    return false;
  }

  // =========================================================================
  // 3. CADERNOS (NOTEBOOKS) - COM SUPORTE EDTECH E PERMISSÕES (ROLES)
  // =========================================================================
  Future<void> pushNotebooks() async {
    final db = await _dbHelper.database;
    try {
      final unsynced = await db.query('notebooks', where: 'synced_with_cloud = ?', whereArgs: [0]);
      if (unsynced.isEmpty) return;

      final List<Map<String, dynamic>> payload = [];
      for (var row in unsynced) {
        int? cloudSubjectId;

        // 🚀 Se subject_id for nulo, é um caderno partilhado/comprado solto. Não precisa de FK.
        if (row['subject_id'] != null) {
          final subjectQuery = await db.query('subjects', columns: ['server_id'], where: 'id = ?', whereArgs: [row['subject_id']]);
          if (subjectQuery.isEmpty || subjectQuery.first['server_id'] == null) continue; // Só avança se a matéria já estiver na nuvem
          cloudSubjectId = subjectQuery.first['server_id'] as int;
        }

        final map = Map<String, dynamic>.from(row);
        map['subject_id'] = cloudSubjectId; // Traduzido ou Null
        payload.add(map);
      }

      if (payload.isEmpty) return;

      final response = await _apiService.post('/sync/notebooks/push', {'notebooks': payload});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        Map<int, int> newIdsMap = {};
        for (var item in data['synced_notebooks']) {
          await db.update('notebooks', {'server_id': item['server_id'], 'synced_with_cloud': 1}, where: 'id = ?', whereArgs: [item['client_id']]);
          newIdsMap[item['client_id']] = item['server_id'];
        }
        if (newIdsMap.isNotEmpty) syncedNoteBooksRadio.value = Map.from(newIdsMap);
      }
    } catch (e) {
      debugPrint('🚨 Erro PUSH Notebooks: $e');
    }
  }

  Future<bool> pullNotebooks() async {
    final db = await _dbHelper.database;
    final prefs = await SharedPreferences.getInstance();
    final lastSynced = prefs.getString('last_notebooks_sync');

    try {
      final endpoint = lastSynced != null ? '/sync/notebooks/pull?last_synced_at=$lastSynced' : '/sync/notebooks/pull';
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['server_time'] != null) await prefs.setString('last_notebooks_sync', data['server_time']);

        final List serverNotebooks = data['notebooks'] ?? [];
        if (serverNotebooks.isEmpty) return false;

        // 🧠 Captura o ID do utilizador local para cruzar as permissões da tabela pivô
        final userQuery = await db.query('users', orderBy: 'id ASC', limit: 1);
        final int currentUserId = userQuery.isNotEmpty ? userQuery.first['id'] as int : 0;

        for (var net in serverNotebooks) {
          int? localSubjectId;
          final role = net['role'] ?? 'owner';

          // 1. Lógica de Cruzamento: Se for caderno próprio, traduz o subject_id
          if (net['subject_id'] != null) {
            final subjectQuery = await db.query('subjects', columns: ['id'], where: 'server_id = ?', whereArgs: [net['subject_id']]);
            if (subjectQuery.isEmpty) continue; // A matéria ainda não baixou
            localSubjectId = subjectQuery.first['id'] as int;
          }

          // 2. Prepara os dados estruturais preservando campos de monetização/formato
          final payload = {
            'server_id': net['id'],
            'subject_id': localSubjectId, // Nulo se for partilha/marketplace
            'title': net['title'],
            'cover_type': net['cover_type'] ?? 'color',
            'color': net['color'],
            'cover_image': net['cover_image'],
            'line_type': net['line_type'] ?? 'ruled',
            'paper_size': net['paper_size'] ?? 'A4',

            // 🛡️ HIGIENE DE DADOS: Força a gravação de números reais no SQLite
            'is_published': int.tryParse(net['is_published']?.toString() ?? '0') ?? 0,
            'price': double.tryParse(net['price']?.toString() ?? '0.0') ?? 0.0,

            'description': net['description'],
            'author_name': net['author_name'],
            'is_deleted': net['deleted_at'] != null ? 1 : 0,
            'synced_with_cloud': 1,
            'updated_at': DateTime.parse(net['updated_at'].toString()).millisecondsSinceEpoch,
          };

          // 3. Grava o Caderno na Estante Virtual Local
          int localNotebookId;
          final existing = await db.query('notebooks', where: 'server_id = ?', whereArgs: [net['id']]);
          if (existing.isEmpty) {
            localNotebookId = await db.insert('notebooks', payload);
          } else {
            localNotebookId = existing.first['id'] as int;
            await db.update('notebooks', payload, where: 'id = ?', whereArgs: [localNotebookId]);
          }

          // 4. 🚀 MAGIA RELACIONAL: Se for convidado ou aluno, grava a Tabela Pivô (notebook_user)
          if (role != 'owner' && currentUserId > 0) {
            await db.insert('notebook_user', {
              'server_id': null,
              'notebook_id': localNotebookId,
              'user_id': currentUserId,
              'role': role,
              'synced_with_cloud': 1,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            }, conflictAlgorithm: ConflictAlgorithm.replace); // Se já existir, substitui a role atualizada
          }
        }
        return true;
      }
    } catch (e) {
      debugPrint('🚨 Erro PULL Notebooks: $e');
    }
    return false;
  }

  // =========================================================================
  // 4. PÁGINAS E TRAÇOS DE TINTA (PAGES & CANVAS)
  // =========================================================================
  Future<void> pushPages() async {
    final db = await _dbHelper.database;
    try {
      final unsyncedPages = await db.query('pages', where: 'synced_with_cloud = ?', whereArgs: [0]);
      if (unsyncedPages.isEmpty) return;

      final List<Map<String, dynamic>> payloadPages = [];

      for (var row in unsyncedPages) {
        final notebookQuery = await db.query('notebooks', columns: ['server_id'], where: 'id = ?', whereArgs: [row['notebook_id']]);
        if (notebookQuery.isEmpty || notebookQuery.first['server_id'] == null) continue;

        // Lemos as folhas montadas diretamente pelo novo CanvasRepository
        final allPages = await _canvasRepository.getPagesByNotebook(row['notebook_id'] as int, null);
        final fullPage = allPages.firstWhere((p) => p.id == row['id'], orElse: () => LocalPage.fromDatabaseMap(row));

        // Conversor Assíncrono (Trata do Base64)
        final map = await fullPage.toMapAsync();

        map['notebook_id'] = notebookQuery.first['server_id'];
        map['client_id'] = row['id'];
        map['server_id'] = row['server_id'];
        payloadPages.add(map);
      }

      if (payloadPages.isEmpty) return;

      final response = await _apiService.post('/sync/pages/push', {'pages': payloadPages});
      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = jsonDecode(response.body);
        Map<int, int> newIdsMap = {};
        for (var item in data['synced_pages'] ?? []) {
          if (item['client_id'] != null && item['server_id'] != null) {
            await db.update('pages', {
              'server_id': item['server_id'],
              'page_number': item['page_number'],
              'synced_with_cloud': 1,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            }, where: 'id = ?', whereArgs: [item['client_id']]);
            newIdsMap[item['client_id']] = item['server_id'];
          }
        }
        if (newIdsMap.isNotEmpty) syncedPagesRadio.value = Map.from(newIdsMap);
      }
    } catch (e) {
      debugPrint('🚨 Erro PUSH Pages: $e');
    }
  }

  Future<bool> pullPages() async {
    final db = await _dbHelper.database;
    final prefs = await SharedPreferences.getInstance();
    final lastSynced = prefs.getString('last_pages_sync');

    try {
      final endpoint = lastSynced != null ? '/sync/pages/pull?last_synced_at=$lastSynced' : '/sync/pages/pull';
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['server_time'] != null) await prefs.setString('last_pages_sync', data['server_time']);

        final List serverPages = data['pages'] ?? [];
        if (serverPages.isEmpty) return false;

        for (var sPage in serverPages) {
          final notebookQuery = await db.query('notebooks', columns: ['id'], where: 'server_id = ?', whereArgs: [sPage['notebook_id']]);
          if (notebookQuery.isEmpty) continue;

          final localNotebookId = notebookQuery.first['id'] as int;

          final pageData = {
            'server_id': sPage['id'],
            'notebook_id': localNotebookId,
            'page_number': sPage['page_number'],
            'is_landscape': (sPage['is_landscape'] == true || sPage['is_landscape'] == 1) ? 1 : 0,

            // 🛡️ Previne Strings Null ou Inválidas nos headers
            'header_data': sPage['header_data'] is String ? sPage['header_data'] : jsonEncode(sPage['header_data'] ?? ''),
            'footer_data': sPage['footer_data'] is String ? sPage['footer_data'] : jsonEncode(sPage['footer_data'] ?? ''),

            'synced_with_cloud': 1,
            'updated_at': DateTime.parse(sPage['updated_at'].toString()).millisecondsSinceEpoch,
          };

          final localPageId = await db.insert('pages', pageData, conflictAlgorithm: ConflictAlgorithm.replace);

          // =========================================================
          // 🖌️ 1. PUXAR TINTA VETORIAL
          // =========================================================
          List strokeList = [];
          if (sPage['stroke_data'] != null) {
            if (sPage['stroke_data'] is String) {
              try { strokeList = jsonDecode(sPage['stroke_data']); } catch (_) {}
            } else if (sPage['stroke_data'] is Iterable) {
              strokeList = List.from(sPage['stroke_data']);
            }
          }

          await db.delete('canvas_strokes', where: 'page_id = ?', whereArgs: [localPageId]);
          for (var st in strokeList) {
            await db.insert('canvas_strokes', {
              'client_stroke_id': st['id']?.toString() ?? uniqid(),
              'page_id': localPageId,
              'stroke_data': jsonEncode(st),
              'is_deleted': 0,
              'synced_with_cloud': 1,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }

          // =========================================================
          // 📝 2. PUXAR TEXTO LIVRE
          // =========================================================
          List textList = [];
          if (sPage['text_data'] != null) {
            if (sPage['text_data'] is String) {
              try { textList = jsonDecode(sPage['text_data']); } catch (_) {}
            } else if (sPage['text_data'] is Iterable) {
              textList = List.from(sPage['text_data']);
            }
          }

          await db.delete('canvas_text_blocks', where: 'page_id = ?', whereArgs: [localPageId]);
          for (var txt in textList) {
            await db.insert('canvas_text_blocks', {
              'client_text_id': txt['id']?.toString() ?? uniqid(),
              'page_id': localPageId,
              'text_data': jsonEncode(txt),
              'is_deleted': 0,
              'synced_with_cloud': 1,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }

          // =========================================================
          // 🖼️ 3. PUXAR IMAGENS E FORMATOS (Largura e Altura!)
          // =========================================================
          List imageList = [];
          if (sPage['image_data'] != null) {
            if (sPage['image_data'] is String) {
              try { imageList = jsonDecode(sPage['image_data']); } catch (_) {}
            } else if (sPage['image_data'] is Iterable) {
              imageList = List.from(sPage['image_data']);
            }
          }

          await db.delete('canvas_image_blocks', where: 'page_id = ?', whereArgs: [localPageId]);
          for (var img in imageList) {
            await db.insert('canvas_image_blocks', {
              'client_image_id': img['id']?.toString() ?? uniqid(),
              'page_id': localPageId,
              'image_path': img['image_path']?.toString() ?? '',
              'pos_x': (img['dx'] as num?)?.toDouble() ?? 0.0,
              'pos_y': (img['dy'] as num?)?.toDouble() ?? 0.0,

              // 🚀 OS NOVOS PARÂMETROS SÃO RECOLHIDOS AQUI:
              'width': (img['width'] as num?)?.toDouble() ?? 300.0,
              'height': (img['height'] as num?)?.toDouble() ?? 200.0,

              'rotation': (img['rotation'] as num?)?.toDouble() ?? 0.0,
              'is_deleted': 0,
              'synced_with_cloud': 1,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        return true;
      }
    } catch (e) {
      debugPrint('🚨 Erro PULL Pages: $e');
    }
    return false;
  }
}