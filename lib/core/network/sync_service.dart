import 'dart:convert';
import 'package:flutter/foundation.dart'; // 🚀 IMPORTANTE: O Escudo que deteta o Chrome (kIsWeb)
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
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
}