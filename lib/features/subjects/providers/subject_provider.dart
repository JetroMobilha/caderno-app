import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/sync_service.dart';
import '../../auth/providers/user_provider.dart';
import '../models/subject_model.dart';
import '../repositories/subject_repository.dart'; // 🚀 IMPORTA O REPOSITÓRIO
import '../../notebooks/providers/notebook_provider.dart';

class SubjectNotifier extends StateNotifier<List<Subject>> {
  final Ref ref;
  Timer? _syncTimer;
  final SubjectRepository _repository = SubjectRepository(); // 🚀 INJETA O REPOSITÓRIO

  SubjectNotifier(this.ref) : super([]) {
    loadSubjects();
    _startAutomaticTracker();
  }

  void _startAutomaticTracker() {
    if (kIsWeb) return;

    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

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
  // 📥 CARREGAR DISCIPLINAS
  // =========================================================================
  Future<void> loadSubjects() async {
    // 🚀 DELEGA TUDO PARA O REPOSITÓRIO
    final lista = await _repository.getSubjects();

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
  // 🚀 CRIAR NOVA DISCIPLINA
  // =========================================================================
  Future<void> addSubject(Subject subject) async {
    final newSubject = await _repository.addSubject(subject);

    if (newSubject != null) {
      state = [newSubject, ...state];
      print('✅ Disciplina "${newSubject.name}" gerada com sucesso!');
      _tryInstantSync();
    }
  }

  // =========================================================================
  // 🗑️ APAGAR E ATUALIZAR DISCIPLINAS
  // =========================================================================
  Future<void> deleteSubject(Subject subject) async {
    await _repository.deleteSubject(subject);
    state = state.where((s) => s.id != subject.id).toList();
    print('🗑️ Disciplina ${subject.name} eliminada.');
  }

  Future<void> updateSubject(Subject subject) async {
    await _repository.updateSubject(subject);

    // Atualiza a memória RAM
    final updatedSubject = Subject(
      id: subject.id,
      serverId: subject.serverId,
      userId: subject.userId,
      name: subject.name,
      color: subject.color,
      icon: subject.icon,
      syncedWithCloud: kIsWeb ? 1 : 0,
    );

    state = state.map((s) => s.id == subject.id ? updatedSubject : s).toList();
    _tryInstantSync();
  }

  void _tryInstantSync() {
    if (!kIsWeb) {
      SyncService().pushOfflineData().then((_) => loadSubjects());
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

final subjectProvider = StateNotifierProvider<SubjectNotifier, List<Subject>>((ref) {
  return SubjectNotifier(ref);
});