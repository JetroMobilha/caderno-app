import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/canvas/models/local_page_model.dart';
import '../../features/canvas/repositories/canvas_repository.dart'; // 🚀 O Repositório Supremo do Canvas
import '../database/database_helper.dart';
import 'api_service.dart';

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService();

  // 🚀 A nossa "Ponte" para aceder à lógica complexa de compor páginas inteiras do SQLite
  final CanvasRepository _canvasRepository = CanvasRepository();

  // 🎯 O INTERRUPTOR GERAL DE REDE
  static bool isCollaborationActive = false;

  // 🚀 A ANTENA GLOBAL (ValueNotifiers para a UI escutar sem acoplamento)
  static final ValueNotifier<Map<int, int>> syncedPagesRadio = ValueNotifier({});
  static final ValueNotifier<Map<int, int>> syncedNoteBooksRadio = ValueNotifier({});

  String uniqid() => DateTime.now().microsecondsSinceEpoch.toString();

  // =========================================================================
  // 1. SINCRONIZAÇÃO TOTAL
  // =========================================================================
  Future<void> syncAll() async {
    if (kIsWeb) return;

    if (isCollaborationActive) {
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

    debugPrint('🏆 [Sync General] Ciclo Concluído!');
  }

  // =========================================================================
  // 2. DISCIPLINAS (SUBJECTS)
  // =========================================================================
  Future<void> pushOfflineSubjects() async {
    if (kIsWeb) return;
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
    if (kIsWeb) return false;
    final db = await _dbHelper.database;
    final prefs = await SharedPreferences.getInstance();
    final lastSynced = prefs.getString('last_subjects_sync');

    try {
      final endpoint = lastSynced != null ? '/sync/pull?last_synced_at=$lastSynced' : '/sync/pull';
      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List serverSubjects = data['subjects'];
        if (data['server_time'] != null) await prefs.setString('last_subjects_sync', data['server_time']);

        if (serverSubjects.isEmpty) return false;

        for (var sub in serverSubjects) {
          final existing = await db.query('subjects', where: 'server_id = ?', whereArgs: [sub['id']]);
          final payload = {
            'server_id': sub['id'], 'user_id': sub['user_id'],
            'name': sub['name'], 'color': sub['color'],
            'icon': sub['icon'], 'synced_with_cloud': 1,
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
  // 3. CADERNOS (NOTEBOOKS)
  // =========================================================================
  Future<void> pushNotebooks() async {
    if (kIsWeb) return;
    final db = await _dbHelper.database;
    try {
      final unsynced = await db.query('notebooks', where: 'synced_with_cloud = ?', whereArgs: [0]);
      if (unsynced.isEmpty) return;

      final List<Map<String, dynamic>> payload = [];
      for (var row in unsynced) {
        final subjectQuery = await db.query('subjects', columns: ['server_id'], where: 'id = ?', whereArgs: [row['subject_id']]);
        if (subjectQuery.isEmpty || subjectQuery.first['server_id'] == null) continue;

        final map = Map<String, dynamic>.from(row);
        map['subject_id'] = subjectQuery.first['server_id']; // Tradução do ID Local para ID da Nuvem
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
    if (kIsWeb) return false;
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

        for (var net in serverNotebooks) {
          final subjectQuery = await db.query('subjects', columns: ['id'], where: 'server_id = ?', whereArgs: [net['subject_id']]);
          if (subjectQuery.isEmpty) continue;

          final payload = {
            'server_id': net['id'],
            'subject_id': subjectQuery.first['id'], // Tradução Inversa da Nuvem para o Local
            'title': net['title'],
            'cover_type': net['cover_type'] ?? 'color',
            'color': net['color'],
            'line_type': net['line_type'] ?? 'ruled',
            'paper_size': net['paper_size'] ?? 'A4',
            'synced_with_cloud': 1,
            'updated_at': DateTime.parse(net['updated_at'].toString()).millisecondsSinceEpoch,
          };

          final existing = await db.query('notebooks', where: 'server_id = ?', whereArgs: [net['id']]);
          if (existing.isEmpty) {
            await db.insert('notebooks', payload);
          } else {
            await db.update('notebooks', payload, where: 'server_id = ?', whereArgs: [net['id']]);
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
    if (kIsWeb) return;
    final db = await _dbHelper.database;
    try {
      final unsyncedPages = await db.query('pages', where: 'synced_with_cloud = ?', whereArgs: [0]);
      if (unsyncedPages.isEmpty) return;

      final List<Map<String, dynamic>> payloadPages = [];

      for (var row in unsyncedPages) {
        final notebookQuery = await db.query('notebooks', columns: ['server_id'], where: 'id = ?', whereArgs: [row['notebook_id']]);
        if (notebookQuery.isEmpty || notebookQuery.first['server_id'] == null) continue;

        // 🚀 O SEGREDO AQUI! Lemos as folhas montadas diretamente pelo novo CanvasRepository
        final allPages = await _canvasRepository.getPagesByNotebook(row['notebook_id'] as int, null);
        final fullPage = allPages.firstWhere((p) => p.id == row['id'], orElse: () => LocalPage.fromDatabaseMap(row));

        // 🚀 O TEU CONVERSOR ASSÍNCRONO GENIAL: Aguardamos a conversão de Base64 das fotos
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
    if (kIsWeb) return false;
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
            'header_data': sPage['header_data'],
            'footer_data': sPage['footer_data'],
            'synced_with_cloud': 1,
            'updated_at': DateTime.parse(sPage['updated_at'].toString()).millisecondsSinceEpoch,
          };

          // Insere a página e obtém o ID local. Se já existir, usamos Replace.
          final localPageId = await db.insert('pages', pageData, conflictAlgorithm: ConflictAlgorithm.replace);

          // Limpa Canvas antigo e insere os novos traços da Nuvem
          await db.delete('canvas_strokes', where: 'page_id = ?', whereArgs: [localPageId]);
          for (var st in sPage['stroke_data'] ?? []) {
            await db.insert('canvas_strokes', {
              'client_stroke_id': st['id']?.toString() ?? uniqid(),
              'page_id': localPageId,
              'stroke_data': jsonEncode(st),
              'is_deleted': 0, 'synced_with_cloud': 1,
              'updated_at': DateTime.now().millisecondsSinceEpoch,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          }

          // (Os textos e imagens seriam inseridos da mesma forma a seguir...)
        }
        return true;
      }
    } catch (e) {
      debugPrint('🚨 Erro PULL Pages: $e');
    }
    return false;
  }
}