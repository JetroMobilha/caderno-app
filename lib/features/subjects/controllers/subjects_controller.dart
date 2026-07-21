import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/sync_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/subject_model.dart';
import '../repositories/subject_repository.dart';

// ============================================================================
// 🧠 CONTROLADOR OFFLINE-FIRST (Puro, Rápido e Sem Polling)
// ============================================================================
class SubjectsController extends Notifier<List<Subject>> {
  StreamSubscription? _subscription;

  @override
  List<Subject> build() {
    // 📡 ESCUTAR AUTH: Se o utilizador sair, limpamos tudo instantaneamente!
    final auth = ref.watch(authProvider);
    
    if (!auth.isAuthenticated) {
      _subscription?.cancel();
      return [];
    }

    _subscribe();
    return []; // Estado inicial vazio enquanto o stream não emite
  }

  SubjectRepository get _repository => ref.read(subjectRepositoryProvider);

  void _subscribe() {
    _subscription?.cancel();
    _subscription = _repository.watchAllSubjects().listen((lista) {
      // 🚀 SEGURANÇA: Evita atualizar o estado durante o ciclo de construção
      Future.microtask(() {
        state = lista;
      });
    });
  }

  Future<Subject?> addSubject(Subject subject) async {
    final newSubject = await _repository.addSubject(subject);
    return newSubject;
  }

  Future<void> updateSubject(Subject subject) async {
    await _repository.updateSubject(subject);
  }

  Future<void> deleteSubject(Subject subject) async {
    await _repository.deleteSubject(subject);
  }

  // 📡 Chamado manualmente pelo botão da Gaveta ou pelo Reverb (WebSocket)
  Future<void> syncManuallyWithCloud() async {
    await ref.read(syncProvider.notifier).performSync(forced: true);
  }
}

final subjectsProvider = NotifierProvider<SubjectsController, List<Subject>>(() {
  return SubjectsController();
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
      // Se não há nada no SQLite, esvazia
      if (_cachedSubject?.id != -1) {
        _cachedSubject = null;
      }
      return _cachedSubject;
    }

    if (!_isLoaded) {
      _isLoaded = true;
      Future.microtask(() => _restoreLastSubject(subjects));
      if (subjects.isNotEmpty) {
        _cachedSubject = subjects.first;
      }
      return _cachedSubject;
    }

    // 🧠 REATIVIDADE AUTÓNOMA BLINDADA
    if (subjects.isNotEmpty) {
      if (_cachedSubject == null) {
        _cachedSubject = subjects.first;
      } else if (_cachedSubject!.id != -1) {
        // Se não for a Aba de Partilhados e a matéria realmente sumir da lista geral, volta à primeira
        if (!subjects.any((s) => s.id == _cachedSubject!.id)) {
          _cachedSubject = subjects.first;
        }
      }
    } else {
      if (_cachedSubject?.id != -1) {
        _cachedSubject = null;
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
