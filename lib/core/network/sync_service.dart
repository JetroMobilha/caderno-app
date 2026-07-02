import 'dart:convert';
import 'package:flutter/foundation.dart'; // 🚀 IMPORTANTE: O Escudo que deteta o Chrome (kIsWeb)
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import 'api_service.dart';

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

  // 📥 INICIAR OPERAÇÃO PULL (Receber do Servidor)
  Future<void> pullSubjects() async {
    // 🌐 ESCUDO WEB: No Chrome não há SQLite para preencher. O Provider já lê direto do servidor!
    if (kIsWeb) {
      print('🌐 [Web] Operação PULL local ignorada: O Chrome lê os dados em tempo real.');
      return;
    }

    final db = await _dbHelper.database;

    try {
      final response = await _apiService.get('/sync/pull');

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        final List<dynamic> serverSubjects = responseData['subjects'];

        for (var serverSub in serverSubjects) {
          // 1. Verifica se a disciplina já existe no telemóvel usando o server_id
          final existing = await db.query(
            'subjects',
            where: 'server_id = ?',
            whereArgs: [serverSub['id']],
          );

          if (existing.isEmpty) {
            // 2. Se não existir, INSERE UMA NOVA no SQLite
            await db.insert('subjects', {
              'server_id': serverSub['id'],
              'user_id': serverSub['user_id'],
              'name': serverSub['name'],
              'color': serverSub['color'],
              'icon': serverSub['icon'],
              'synced_with_cloud': 1, // Já veio da nuvem, logo está sincronizado!
            });
          } else {
            // 3. Se já existir, ATUALIZA (para caso o utilizador tenha mudado o nome noutro dispositivo)
            await db.update('subjects', {
              'name': serverSub['name'],
              'color': serverSub['color'],
              'icon': serverSub['icon'],
              'synced_with_cloud': 1,
            }, where: 'server_id = ?', whereArgs: [serverSub['id']]);
          }
        }
        print('☁️ Sincronização PULL concluída com sucesso!');
      } else {
        print('🚨 Falha no PULL: Servidor retornou ${response.statusCode}');
      }
    } catch (e) {
      print('🚨 Erro crítico na Sincronização PULL: $e');
    }
  }
}