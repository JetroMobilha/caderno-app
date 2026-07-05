import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/sync_service.dart';
import '../../../core/database/database_helper.dart';
import '../models/subject_model.dart';
import '../../notebooks/providers/notebook_provider.dart';
import '../../auth/providers/user_provider.dart';

class SubjectNotifier extends StateNotifier<List<Subject>> {
  final Ref ref;
  Timer? _syncTimer;

  SubjectNotifier(this.ref) : super([]) {
    loadSubjects();
    _startAutomaticTracker();
  }

  // =========================================================================
  // 🚀 O CRONÓMETRO AUTOMÁTICO (O nosso Radar de Fundo)
  // =========================================================================
  void _startAutomaticTracker() {
    if (kIsWeb) return;

    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {

      // 🛡️ BLINDAGEM 1: Se a classe foi destruída, desliga
      if (!mounted) {
        timer.cancel();
        return;
      }

      // 🛡️ BLINDAGEM 2 (ANTI-ZOMBIE): Se não há identidade (Logout), destrói o radar!
      final currentUser = ref.read(userProvider);
      if (currentUser == null) {
        print('🛑 [Radar Silencioso] Soldado fora de combate (Logout). A desligar o radar.');
        timer.cancel();
        return;
      }

      print('⏱️ [Radar Silencioso] A executar varrimento automático de rede...');
      try {
        final syncService = SyncService();
        await syncService.pushOfflineData();
        await syncService.pullSubjects();

        await syncService.pushNotebooks();
        final bool novosCadernosChegaram = await syncService.pullNotebooks();
        await syncService.pushPages();
        final bool novasFolhasChegaram = await syncService.pullPages();

        if (!mounted) return;

        await loadSubjects();

        if (novosCadernosChegaram || novasFolhasChegaram) {
          print('🔄 [Radar Silencioso] Novidades na estante! A atualizar UI...');
          ref.read(notebookProvider.notifier).refreshCurrent();
        }
      } catch (e) {
        print('📴 [Radar Silencioso] Modo Offline ou erro no ciclo de sync: $e');
      }
    });
  }

  // =========================================================================
  // 📥 LER DISCIPLINAS DO SQLITE LOCAL
  // =========================================================================
  Future<void> loadSubjects() async {
    final db = await DatabaseHelper.instance.database;
    final maps = await db.query('subjects', orderBy: 'id DESC');

    final lista = maps.map((s) => Subject(
      id: s['id'] as int,
      serverId: s['server_id'] as int?,
      userId: s['user_id'] as int,
      name: s['name'] as String,
      color: s['color'] as String,
      icon: s['icon'] as String?,
      syncedWithCloud: s['synced_with_cloud'] as int? ?? 0,
    )).toList();

    // Só atualiza se houver mudanças para evitar piscadas desnecessárias na tela
    if (lista.length != state.length || _hasChanges(lista, state)) {
      state = lista;
    }
  }

  bool _hasChanges(List<Subject> a, List<Subject> b) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].name != b[i].name || a[i].serverId != b[i].serverId) return true;
    }
    return false;
  }

  // =========================================================================
  // 🚀 O MÉTOD EM FALTA: CRIAR NOVA DISCIPLINA (OFFLINE-FIRST)
  // =========================================================================
  Future<void> addSubject(Subject subject) async {
    final db = await DatabaseHelper.instance.database;

    // 1. Prepara o mapa para o SQLite (Garante que server_id entra como NULL!)
    final map = {
      'user_id': subject.userId,
      'server_id': null, // Nasce offline, logo ainda não tem ID da nuvem
      'name': subject.name,
      'color': subject.color,
      'icon': subject.icon,
      'synced_with_cloud': 0, // 0 = Pendente de envio para o Laravel
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };

    // 2. Insere na base de dados do dispositivo (SQLite) e captura o ID local gerado
    final int insertedId = await db.insert('subjects', map);

    // 3. Cria o objeto completo já com o ID local
    final newSubject = Subject(
      id: insertedId,
      userId: subject.userId,
      serverId: null,
      name: subject.name,
      color: subject.color,
      icon: subject.icon,
      syncedWithCloud: 0,
    );

    // 4. Atualiza a memória RAM na hora! A disciplina aparece na UI no mesmo milissegundo!
    state = [newSubject, ...state];
    print('✅ Disciplina "${newSubject.name}" criada offline com sucesso! (Local ID: $insertedId)');

    // 5. (Opcional) Tenta disparar uma sincronização imediata em segundo plano
    _tryInstantSync();
  }

  // =========================================================================
  // 🗑️ EXTRAS TÁTICOS: APAGAR E ATUALIZAR DISCIPLINAS
  // =========================================================================
  Future<void> deleteSubject(int subjectId) async {
    final db = await DatabaseHelper.instance.database;
    await db.delete('subjects', where: 'id = ?', whereArgs: [subjectId]);
    state = state.where((s) => s.id != subjectId).toList();
    print('🗑️ Disciplina $subjectId eliminada localmente.');
  }

  Future<void> updateSubject(Subject subject) async {
    if (subject.id == null) return;
    final db = await DatabaseHelper.instance.database;

    await db.update(
      'subjects',
      {
        'name': subject.name,
        'color': subject.color,
        'icon': subject.icon,
        'synced_with_cloud': 0, // Marcamos como 0 para o Laravel receber o novo nome/cor!
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      where: 'id = ?',
      whereArgs: [subject.id],
    );

    // Atualiza o ecrã
    state = state.map((s) => s.id == subject.id ? subject : s).toList();
    _tryInstantSync();
  }

  void _tryInstantSync() {
    if (!kIsWeb) {
      SyncService().pushOfflineData().then((_) => loadSubjects());
    }
  }

  // =========================================================================
  // 💣 ORDEM DE DESTRUIÇÃO: Executada quando fazemos Logout!
  // =========================================================================
  @override
  void dispose() {
    _syncTimer?.cancel(); // Desativa a bomba-relógio
    super.dispose();      // Destrói a classe em segurança
  }

}

// O nosso Provider Global que injeta a referência (ref) corretamente
final subjectProvider = StateNotifierProvider<SubjectNotifier, List<Subject>>((ref) {
  return SubjectNotifier(ref);
});