import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/sync_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notebooks/controllers/notebooks_controller.dart';
import '../models/subject_model.dart';
import '../repositories/subject_repository.dart';

// ============================================================================
// 🧠 CONTROLADOR COM RADAR SILENCIOSO: GERE A RAM, SQLITE E SINCRONIZAÇÃO
// ============================================================================
class SubjectsController extends StateNotifier<List<Subject>> {
  final Ref ref;
  Timer? _syncTimer;
  final SubjectRepository _repository = SubjectRepository();

  SubjectsController(this.ref) : super([]) {
    loadSubjects();
    _startAutomaticTracker();
  }

  void _startAutomaticTracker() {
    if (kIsWeb) return;

    _syncTimer = Timer.periodic(const Duration(minutes: 1), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      final authState = ref.read(authProvider);
      if (authState.currentUser == null) {
        timer.cancel();
        return;
      }

      if (SyncService.isCollaborationActive) return;

      try {
        final syncService = SyncService();
        await syncService.pushOfflineSubjects();
        await syncService.pullSubjects();
        await syncService.pushNotebooks();
        final bool novosCadernosChegaram = await syncService.pullNotebooks();
        await syncService.pushPages();
        final bool novasFolhasChegaram = await syncService.pullPages();

        if (!mounted) return;
        await loadSubjects();

        if (novosCadernosChegaram || novasFolhasChegaram) {
          ref.invalidate(notebooksProvider);
        }
      } catch (e) {
        debugPrint('📴 [Radar Silencioso] Modo Offline: $e');
      }
    });
  }

  Future<void> loadSubjects() async {
    final lista = await _repository.getAllSubjects();
    if (lista.length != state.length || _hasChanges(lista, state)) {
      state = lista;
    }
  }

  bool _hasChanges(List<Subject> a, List<Subject> b) {
    if (a.length != b.length) return true;
    for (int i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].name != b[i].name || a[i].serverId != b[i].serverId) {
        return true;
      }
    }
    return false;
  }

  Future<void> addSubject(Subject subject) async {
    final newSubject = await _repository.addSubject(subject);
    if (newSubject != null) {
      state = [newSubject, ...state];
      // 🚀 Removido o _tryInstantSync daqui! Foco 100% offline local.
    }
  }

  Future<void> updateSubject(Subject subject) async {
    await _repository.updateSubject(subject);
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
    // 🚀 Removido o _tryInstantSync daqui!
  }

  // =========================================================================
  // 🗑️ APAGAR DISCIPLINA (Purificado e sem dependências circulares!)
  // =========================================================================
  Future<void> deleteSubject(Subject subject) async {
    // 1. Executa o Soft Delete no Repositório (Muda is_deleted para 1 no SQLite)
    await _repository.deleteSubject(subject);

    // 2. 🚀 ATUALIZAÇÃO OTIMISTA INSTANTÂNEA: Remove o item da memória RAM
    // Removida por completo a leitura do 'activeSubjectProvider' e do 'invalidateSelf()'.
    // O loop circular foi completamente destruído!
    state = state.where((s) => s.id != subject.id).toList();
  }

  Future<void> syncManuallyWithCloud() async {
    if (!kIsWeb) {
      final syncService = SyncService();
      await syncService.syncAll();
    }
    await loadSubjects();
    ref.invalidate(notebooksProvider);
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    super.dispose();
  }
}

final subjectsProvider = StateNotifierProvider<SubjectsController, List<Subject>>((ref) {
  return SubjectsController(ref);
});

// ============================================================================
// 🎯 PROVIDER DA DISCIPLINA ATIVA (Gere a sua reatividade de forma limpa)
// ============================================================================
class ActiveSubjectNotifier extends Notifier<Subject?> {
  bool _isLoaded = false;
  Subject? _cachedSubject;

  @override
  Subject? build() {
    // Escuta a lista geral de disciplinas de forma passiva
    final subjects = ref.watch(subjectsProvider);

    if (subjects.isEmpty) {
      _cachedSubject = null;
      return null;
    }

    if (!_isLoaded) {
      _isLoaded = true;
      Future.microtask(() => _restoreLastSubject(subjects));
      _cachedSubject = subjects.first;
      return _cachedSubject;
    }

    // 🧠 REATIVIDADE AUTÓNOMA: Se a disciplina focada sumir da lista geral
    // (porque o utilizador a apagou), esta antena percebe sozinha e foca-se na primeira!
    if (_cachedSubject != null && !subjects.any((s) => s.id == _cachedSubject!.id)) {
      _cachedSubject = subjects.first;
      return _cachedSubject;
    }

    return _cachedSubject;
  }

  Future<void> _restoreLastSubject(List<Subject> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt('last_subject_id');

    if (lastId != null) {
      try {
        final savedSubject = subjects.firstWhere((s) => s.id == lastId);
        _cachedSubject = savedSubject;
        state = savedSubject;
      } catch (_) {
        _cachedSubject = subjects.first;
        state = subjects.first;
      }
    }
  }

  Future<void> setSubject(Subject? subject) async {
    _cachedSubject = subject;
    state = subject;
    final prefs = await SharedPreferences.getInstance();
    if (subject?.id != null) {
      await prefs.setInt('last_subject_id', subject!.id!);
    } else {
      await prefs.remove('last_subject_id');
    }
  }
}

final activeSubjectProvider = NotifierProvider<ActiveSubjectNotifier, Subject?>(() {
  return ActiveSubjectNotifier();
});