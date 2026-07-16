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
// 🧠 CONTROLADOR OFFLINE-FIRST (Puro, Rápido e Sem Polling)
// ============================================================================
class SubjectsController extends StateNotifier<List<Subject>> {
  final Ref ref;
  final SubjectRepository _repository = SubjectRepository();

  SubjectsController(this.ref) : super([]) {
    loadSubjects();
    // 🚀 O Timer de 1 minuto foi ANIQUILADO! Poupamos bateria e CPU.
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
  }

  Future<void> deleteSubject(Subject subject) async {
    await _repository.deleteSubject(subject);
    state = state.where((s) => s.id != subject.id).toList();
  }

  // 📡 Chamado manualmente pelo botão da Gaveta ou pelo Reverb (WebSocket)
  Future<void> syncManuallyWithCloud() async {
    if (!kIsWeb) {
      final syncService = SyncService();
      await syncService.syncAll();
    }
    await loadSubjects();
    ref.invalidate(notebooksProvider);
  }
}

final subjectsProvider = StateNotifierProvider<SubjectsController, List<Subject>>((ref) {
  return SubjectsController(ref);
});

// ============================================================================
// 🎯 PROVIDER DA DISCIPLINA ATIVA (Gere a sua reatividade de forma limpa)
// ============================================================================
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
      // Se não há nada no SQLite, esvazia
      if (_cachedSubject?.id != -1) {
        _cachedSubject = null;
      }
      return _cachedSubject;
    }

    if (!_isLoaded) {
      _isLoaded = true;
      Future.microtask(() => _restoreLastSubject(subjects));
      _cachedSubject = subjects.first;
      return _cachedSubject;
    }

    // 🧠 REATIVIDADE AUTÓNOMA BLINDADA
    if (_cachedSubject != null) {
      // 🚀 EXCEÇÃO EDTECH: Se for a Aba Virtual "Partilhados Comigo" (-1), o scanner IGNERA.
      if (_cachedSubject!.id == -1) {
        return _cachedSubject;
      }

      // Se não for a Aba de Partilhados e a matéria realmente sumir da lista geral, volta à primeira
      if (!subjects.any((s) => s.id == _cachedSubject!.id)) {
        _cachedSubject = subjects.first;
        return _cachedSubject;
      }
    }

    return _cachedSubject;
  }

  Future<void> _restoreLastSubject(List<Subject> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt('last_subject_id');

    if (lastId != null) {
      // Impede que ele restaure a aba "Partilhados Comigo" do cache, volta sempre para as normais.
      if (lastId == -1) {
        _cachedSubject = subjects.first;
        state = subjects.first;
        return;
      }

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

    // Só guardamos a memória de longo prazo se for uma disciplina real
    if (subject?.id != null && subject!.id != -1) {
      await prefs.setInt('last_subject_id', subject.id!);
    } else {
      await prefs.remove('last_subject_id');
    }
  }
}

final activeSubjectProvider = NotifierProvider<ActiveSubjectNotifier, Subject?>(() {
  return ActiveSubjectNotifier();
});