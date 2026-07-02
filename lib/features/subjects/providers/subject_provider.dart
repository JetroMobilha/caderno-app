import 'dart:convert';
import 'dart:async';
import 'package:flutter/foundation.dart'; // 🚀 IMPORTANTE: Traz a variável kIsWeb
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_service.dart';
import '../../../core/database/database_helper.dart'; // O teu ficheiro local
import '../../../core/network/sync_service.dart';
import '../models/subject_model.dart';

class SubjectNotifier extends StateNotifier<List<Subject>> {
  Timer? _syncTimer;

  SubjectNotifier() : super([]) {
    loadSubjects();
    _startAutomaticTracker(); // 🚀 ATIVA O RADAR AUTOMÁTICO LOGO NO ARRANQUE
  }

  @override
  void dispose() {
    _syncTimer?.cancel(); // Desliga o radar se o provider for destruído
    super.dispose();
  }

  // 🚀 O CRONÓMETRO AUTOMÁTICO (Roda silenciosamente em segundo plano)
  void _startAutomaticTracker() {
    if (kIsWeb) return; // O Chrome não precisa de sincronizar disco local

    // Dispara a cada 30 segundos (Podes mudar para 1 minuto ou mais tarde para poupar dados)
    _syncTimer = Timer.periodic(const Duration(seconds: 280), (timer) async {
      print('⏱️ [Radar Silencioso] A executar varrimento automático de rede...');

      final syncService = SyncService();

      // 1. Envia o que o aluno criou localmente em modo offline (Push)
      await syncService.pushOfflineData();

      // 2. Procura novidades na nuvem (Pull Delta)
      final bool houveNovidades = await syncService.pullSubjects();

      // 3. Se o radar detetou dados novos vindos do Laravel, recarrega a UI na hora!
      if (houveNovidades) {
        print('🔄 [Radar Silencioso] Novidades injetadas! A atualizar a estante...');
        // Lê o SQLite atualizado e força o Flutter a desenhar as novas disciplinas
        final db = await DatabaseHelper.instance.database;
        final maps = await db.query('subjects', orderBy: 'id DESC');

        state = maps.map((s) => Subject(
          id: s['id'] as int,
          serverId: s['server_id'] as int,
          userId: s['user_id'] as int,
          name: s['name'] as String,
          color: s['color'] as String,
          icon: s['icon'] as String?,
        )).toList();
      }
    });
  }

  // 📥 CARREGAR DISCIPLINAS
  Future<void> loadSubjects() async {
    if (kIsWeb) {
      // ========================================================
      // 🌐 MODO CHROME: Vai direto à Nuvem (Laravel)
      // ========================================================
      try {
        final api = ApiService();
        final response = await api.get('/sync/pull');

        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final List<dynamic> serverSubjects = data['subjects'];

          // Converte o JSON que veio do Laravel em objetos Subject
          state = serverSubjects.map((s) => Subject(
            id: s['id'],
            userId: s['user_id'],
            serverId: s['id'],
            name: s['name'],
            color: s['color'],
            icon: s['icon'],
          )).toList();
        }
      } catch (e) {
        print('🚨 Erro a carregar disciplinas na Web: $e');
      }
    } else {
      // ========================================================
      // 💻 MODO WINDOWS/ANDROID: Vai ao SQLite Local
      // ========================================================
      final db = await DatabaseHelper.instance.database;
      final maps = await db.query('subjects', orderBy: 'id DESC');

      state = maps.map((s) => Subject(
        id: s['id'] as int,
        userId: s['user_id'] as int,
        serverId: s['server_id'] as int,
        name: s['name'] as String,
        color: s['color'] as String,
        icon: s['icon'] as String?,
      )).toList();

      try {
        final syncService = SyncService();
        await syncService.pushOfflineData(); // Envia o que foi criado offline
        await syncService.pullSubjects();    // Puxa o que foi criado noutros PCs

        // 3. Verifica se chegaram dados novos ao SQLite
        final updatedMaps = await db.query('subjects', orderBy: 'id DESC');
        if (updatedMaps.length != maps.length) {
          // Se o número de disciplinas mudou, atualiza a tela suavemente!
          state = updatedMaps.map((s) => Subject(
            id: s['id'] as int,
            serverId: s['server_id'] as int,
            userId: s['user_id'] as int,
            name: s['name'] as String,
            color: s['color'] as String,
            icon: s['icon'] as String?,
          )).toList();
          print('🔄 Tela atualizada automaticamente com reforços da nuvem!');
        }
      } catch (e) {
        print('📴 Modo 100% Offline ativo. Sem ligação à nuvem no momento.');
      }
    }
  }

  // 📤 CRIAR NOVA DISCIPLINA
  Future<void> addSubject(Subject subject) async {
    if (kIsWeb) {
      // ========================================================
      // 🌐 MODO CHROME: Dispara logo o Push para o Laravel
      // ========================================================
      final api = ApiService();
      // Simula o formato que o Laravel espera
      await api.post('/sync/push', {
        'subjects': [{
          'id': 0, // Temporário
          'server_id': null,
          'name': subject.name,
          'color': subject.color,
          'icon': subject.icon,
        }]
      });
      // Recarrega tudo do servidor para atualizar a UI
      await loadSubjects();

    } else {
      // ========================================================
      // 💻 MODO WINDOWS/ANDROID: Grava no SQLite local
      // ========================================================
      final db = await DatabaseHelper.instance.database;
      final id = await db.insert('subjects', {
        'user_id': subject.userId,
        'name': subject.name,
        'color': subject.color,
        'icon': subject.icon,
        'synced_with_cloud': 0, // Fica à espera do botão de Sincronizar!
      });

      // Atualiza o estado local para a UI reagir
      final newSubject = Subject(
        id: id,
        userId: subject.userId,
        serverId: subject.serverId,
        name: subject.name,
        color: subject.color,
        icon: subject.icon,
      );
      state = [newSubject, ...state];
    }
  }
}

final subjectProvider = StateNotifierProvider<SubjectNotifier, List<Subject>>((ref) {
  return SubjectNotifier()..loadSubjects(); // Carrega automaticamente ao iniciar!
});