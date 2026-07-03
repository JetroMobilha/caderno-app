import 'dart:convert';
import 'package:flutter/foundation.dart'; // 🚀 IMPORTANTE: O Escudo que deteta o Chrome (kIsWeb)
import 'package:sqflite/sqflite.dart';
import '../../features/notebooks/models/local_page_model.dart';
import '../database/database_helper.dart';
import '../services/local_database_service.dart';
import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService();

  // 🚀 INICIAR OPERAÇÃO PUSH
  Future<void> pushOfflineData() async {
    // 🌐 ESCUDO WEB: No Chrome não existe SQLite local. Os dados já nascem na nuvem!
    if (kIsWeb) {
      print('🌐 [Web] Operação PUSH ignorada: O Chrome opera 100% online.');
      return;
    }

    final db = await _dbHelper.database;

    try {
      // 1. RECOLHA DE TROPAS: Procurar disciplinas que ainda não foram para a nuvem
      final List<Map<String, dynamic>> unsyncedSubjects = await db.query(
        'subjects',
        where: 'synced_with_cloud = ?',
        whereArgs: [0],
      );

      if (unsyncedSubjects.isEmpty) {
        print('✅ Tudo sincronizado. Nada a enviar.');
        return;
      }

      // 2. DISPARO PARA A NUVEM: Formatar em JSON e enviar para o Laravel
      final payload = {
        'subjects': unsyncedSubjects,
      };

      final response = await _apiService.post('/sync/push', payload);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> syncedSubjectsData = responseData['synced_subjects'];

        // 3. ATUALIZAÇÃO LOCAL: Dizer ao SQLite os IDs oficiais e marcar como sincronizado
        for (var item in syncedSubjectsData) {
          final int clientId = item['client_id'];
          final int serverId = item['server_id'];

          await db.update(
            'subjects',
            {
              'server_id': serverId,
              'synced_with_cloud': 1, // 🚀 Missão Cumprida!
            },
            where: 'id = ?',
            whereArgs: [clientId],
          );
        }

        print('☁️ Sincronização PUSH concluída com sucesso!');
      } else {
        print('🚨 Servidor recusou a sincronização: ${response.statusCode}');
      }
    } catch (e) {
      print('🚨 Erro crítico na Sincronização PUSH: $e');
    }
  }

  // 📥 INICIAR OPERAÇÃO PULL (Rastreio Inteligente por Timestamp)
  Future<bool> pullSubjects() async {
    if (kIsWeb) return false;

    final db = await _dbHelper.database;
    final prefs = await SharedPreferences.getInstance();

    // 🚀 LER O ÚLTIMO CARIMBO: Vai buscar a data do último rastreio guardada no disco
    final String? lastSynced = prefs.getString('last_subjects_sync');

    try {
      // Constrói o link. Se houver carimbo, anexa-o à rota: ex: /sync/pull?last_synced_at=2026-07-01...
      final String endpoint = lastSynced != null
          ? '/sync/pull?last_synced_at=$lastSynced'
          : '/sync/pull';

      final response = await _apiService.get(endpoint);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> serverSubjects = responseData['subjects'];
        final String? serverTime = responseData['server_time'];

        if (serverSubjects.isEmpty) {
          print('📡 [Rastreio] Nenhuma novidade detetada na nuvem.');
          // Mesmo sem dados novos, atualiza o tempo com o do servidor para precisão
          if (serverTime != null) await prefs.setString('last_subjects_sync', serverTime);
          return false; // Não houve alterações
        }

        print('📡 [Rastreio] Detetadas ${serverSubjects.length} novidades na nuvem! A processar...');

        for (var serverSub in serverSubjects) {
          final existing = await db.query(
            'subjects',
            where: 'server_id = ?',
            whereArgs: [serverSub['id']],
          );

          if (existing.isEmpty) {
            await db.insert('subjects', {
              'server_id': serverSub['id'],
              'user_id': serverSub['user_id'],
              'name': serverSub['name'],
              'color': serverSub['color'],
              'icon': serverSub['icon'],
              'synced_with_cloud': 1,
            });
          } else {
            await db.update('subjects', {
              'name': serverSub['name'],
              'color': serverSub['color'],
              'icon': serverSub['icon'],
              'synced_with_cloud': 1,
            }, where: 'server_id = ?', whereArgs: [serverSub['id']]);
          }
        }

        // 🚀 GRAVAR NOVO CARIMBO: Guarda a hora do servidor para o próximo ciclo automático
        if (serverTime != null) {
          await prefs.setString('last_subjects_sync', serverTime);
        }

        return true; // Dados novos injetados com sucesso!
      }
    } catch (e) {
      print('🚨 Erro no rastreio automático PULL: $e');
    }
    return false;
  }

  Future<void> pushNotebooks() async {
    if (kIsWeb) return; // Web já opera na nuvem
    final db = await _dbHelper.database;

    try {
      // 1. Procura cadernos não sincronizados no SQLite
      final List<Map<String, dynamic>> unsynced = await db.query(
        'notebooks',
        where: 'synced_with_cloud = ?',
        whereArgs: [0],
      );

      if (unsynced.isEmpty) {
        debugPrint('✅ [Sync] Todos os cadernos já estão na nuvem.');
        return;
      }

      debugPrint('📡 [Sync] A disparar ${unsynced.length} cadernos para o Laravel...');

      // 2. Dispara para a rota da nuvem
      final response = await _apiService.post('/sync/notebooks/push', {
        'notebooks': unsynced,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> syncedList = data['synced_notebooks'] ?? [];

        // 3. Atualiza o SQLite com os IDs oficiais do servidor
        for (var item in syncedList) {
          await db.update(
            'notebooks',
            {
              'server_id': item['server_id'],
              'synced_with_cloud': 1, // 🚀 Missão Cumprida!
            },
            where: 'id = ?',
            whereArgs: [item['client_id']],
          );
        }
        debugPrint('☁️ [Sync] Cadernos sincronizados com sucesso!');
      }
    } catch (e) {
      debugPrint('🚨 [Sync] Erro no PUSH dos cadernos: $e');
    }
  }

  // =========================================================================
  // 📤 FASE 3: ENVIAR FOLHAS COM DESENHOS E FOTOS BASE64 (PUSH)
  // =========================================================================
  Future<void> pushPages() async {
    if (kIsWeb) return;
    final db = await _dbHelper.database;

    try {
      // 1. Procura as folhas não sincronizadas
      final List<Map<String, dynamic>> unsyncedPages = await db.query(
        'pages',
        where: 'synced_with_cloud = ?',
        whereArgs: [0],
      );

      if (unsyncedPages.isEmpty) {
        debugPrint('✅ [Sync] Todas as folhas já estão na nuvem.');
        return;
      }

      debugPrint('📡 [Sync] A empacotar e disparar ${unsyncedPages.length} folhas...');

      // 🚀 SEGREDO TÁTICO: Recrutamos o LocalDatabaseService para montar
      // a folha completa (com traços, textos e as imagens convertidas para Base64!)
      final localDb = LocalDatabaseService();
      final List<Map<String, dynamic>> payloadPages = [];

      for (var pageRow in unsyncedPages) {
        final int pageId = pageRow['id'];
        final int notebookId = pageRow['notebook_id'];

        // Puxa as folhas completas do caderno da memória e filtra a que queremos
        final allPages = await localDb.getFullPagesForNotebook(notebookId);
        final fullPage = allPages.firstWhere((p) => p.id == pageId, orElse: () => LocalPage.fromDatabaseMap(pageRow));

        // O nosso novo toMap() vai converter as fotografias para Base64 automaticamente!
        payloadPages.add(fullPage.toMap());
      }

      // 2. Dispara o pacote pesado para o Laravel
      final response = await _apiService.post('/sync/pages/push', {
        'pages': payloadPages,
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<dynamic> syncedList = data['synced_pages'] ?? [];

        // 3. Marca as folhas como sincronizadas no SQLite
        for (var item in syncedList) {
          await db.update(
            'pages',
            {
              'server_id': item['server_id'],
              'synced_with_cloud': 1, // 🚀 Carimbada na Nuvem!
            },
            where: 'id = ?',
            whereArgs: [item['client_id']],
          );
        }
        debugPrint('☁️ [Sync] Folhas e desenhos sincronizados com sucesso!');
      }
    } catch (e) {
      debugPrint('🚨 [Sync] Erro no PUSH das folhas: $e');
    }
  }

  // =========================================================================
  // 🚀 COMANDO SUPREMO: SINCRONIZAÇÃO TOTAL (Offline-First para Nuvem)
  // =========================================================================
  Future<void> syncAll() async {
    if (kIsWeb) return;

    debugPrint('🏁 [Sync General] A iniciar ofensiva de sincronização total...');

    // 1º ESCALÃO: Sobem as Disciplinas
    await pushOfflineData();
    await pullSubjects();

    // 2º ESCALÃO: Sobem os Cadernos
    await pushNotebooks();
    // await pullNotebooks(); // (Podes criar este no futuro se precisares)

    // 3º ESCALÃO: Sobem as Folhas e Fotografias Base64
    await pushPages();

    debugPrint('🏆 [Sync General] Sincronização total concluída com sucesso!');
  }

}