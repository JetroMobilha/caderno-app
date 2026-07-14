import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/sync_service.dart';
import '../../auth/controllers/auth_controller.dart'; // 🚀 Aponta para a nova pasta controllers
import '../../notebooks/controllers/notebooks_controller.dart'; // 🚀 Aponta para a nova pasta controllers
import '../models/subject_model.dart';
import '../repositories/subject_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  @override
  List<Subject> build() {
    loadSubjects();
    return [];
  }

  // =========================================================================
  // 📡 O RADAR SILENCIOSO (VARRIMENTO AUTOMÁTICO DE DEZ EM DEZ SEGUNDOS / 30S)
  // =========================================================================
  void _startAutomaticTracker() {
    // Na Web não precisamos de polling no disco local
    if (kIsWeb) return;

    _syncTimer = Timer.periodic(const Duration(seconds: 30), (timer) async {
      if (!mounted) {
        timer.cancel();
        return;
      }

      // 1. Verifica se o aluno ainda tem sessão ativa
      final authState = ref.read(authProvider);
      if (authState.currentUser == null) {
        debugPrint('🛑 [Radar Silencioso] Soldado fora de combate (Logout). A desligar o radar.');
        timer.cancel();
        return;
      }

      // 2. 🛡️ TRAVA DE SEGURANÇA: Se estiver no Canvas a colaborar via Reverb, aborta o sync HTTP
      if (SyncService.isCollaborationActive) {
        return;
      }

      debugPrint('⏱️ [Radar Silencioso] A executar varrimento automático de rede...');
      try {
        final syncService = SyncService();

        // Push & Pull Disciplinas
        await syncService.pushOfflineSubjects();
        await syncService.pullSubjects();

        // Push & Pull Cadernos e Folhas
        await syncService.pushNotebooks();
        final bool novosCadernosChegaram = await syncService.pullNotebooks();
        await syncService.pushPages();
        final bool novasFolhasChegaram = await syncService.pullPages();

        if (!mounted) return;

        // Atualiza a lista de disciplinas silenciosamente se algo mudou
        await loadSubjects();

        // Se chegaram novos cadernos ou páginas da nuvem, avisa o estande de cadernos para atualizar a UI!
        if (novosCadernosChegaram || novasFolhasChegaram) {
          debugPrint('🔄 [Radar Silencioso] Novidades na estante! A notificar o controlador de cadernos...');
          // O método loadNotebooks será acionado na tela correspondente pelo utilizador,
          // mas podemos invalidar para forçar recarga na próxima visita:
          ref.invalidate(notebooksProvider);
        }
      } catch (e) {
        debugPrint('📴 [Radar Silencioso] Modo Offline ou erro no ciclo de sync: $e');
      }
    });
  }

  // =========================================================================
  // 📥 CARREGAR DISCIPLINAS (OTIMIZADO CONTRA PISCADAS DE TELA)
  // =========================================================================
  Future<void> loadSubjects() async {
    final lista = await _repository.getAllSubjects();

    // 🛡️ Só substitui o estado na RAM se houver uma alteração real!
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

  // =========================================================================
  // 🚀 CRIAR NOVA DISCIPLINA
  // =========================================================================
  Future<void> addSubject(Subject subject) async {
    final newSubject = await _repository.addSubject(subject);

    if (newSubject != null) {
      // Injeta no topo da lista na memória RAM
      state = [newSubject, ...state];
      debugPrint('✅ Disciplina "${newSubject.name}" gerada com sucesso no disco/nuvem!');
      _tryInstantSync();
    }
  }

  // =========================================================================
  // ✏️ ATUALIZAR E 🗑️ APAGAR DISCIPLINAS
  // =========================================================================
  Future<void> updateSubject(Subject subject) async {
    await _repository.updateSubject(subject);

    // Atualiza a memória RAM na hora para refletir o novo nome ou cor
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

  Future<void> deleteSubject(Subject subject) async {
    await _repository.deleteSubject(subject);
    state = state.where((s) => s.id != subject.id && (s.serverId == null || s.serverId != subject.serverId)).toList();
    debugPrint('🗑️ Disciplina "${subject.name}" eliminada.');

    // Se a matéria apagada era a que estava ativa, limpamos o Íman de Foco
    final currentActive = ref.read(activeSubjectProvider);
    if (currentActive?.id == subject.id) {
      ref.read(activeSubjectProvider.notifier).setSubject(null as dynamic);
      // NOTA: Usa um bypass temporário, na reconstrução ele seleciona a primeira!
    }

    ref.invalidateSelf();
  }

  // =========================================================================
  // ⚡ DISPARO INSTANTÂNEO DE BACKUP
  // =========================================================================
  void _tryInstantSync() {
    if (!kIsWeb) {
      SyncService().pushOfflineSubjects().then((_) => loadSubjects());
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel(); // 🛑 Desliga o temporizador se o controlador for destruído
    super.dispose();
  }
}

// ============================================================================
// 🚀 ANTENA GLOBAL DO RIVERPOD PARA A APLICAÇÃO (NOVO NOME ALINHADO)
// ============================================================================
final subjectsProvider = StateNotifierProvider<SubjectsController, List<Subject>>((ref) {
  return SubjectsController(ref);
});

// ============================================================================
// 🎯 PROVIDER DA DISCIPLINA ATIVA (Com Memória Permanente)
// ============================================================================
class ActiveSubjectNotifier extends Notifier<Subject?> {
  bool _isLoaded = false;

  @override
  Subject? build() {
    final subjects = ref.watch(subjectsProvider);

    if (subjects.isEmpty) return null;

    if (!_isLoaded) {
      _isLoaded = true;
      // 🚀 SOLUÇÃO DO CRASH: Agenda a leitura do disco para DEPOIS de o ecrã terminar de desenhar!
      Future.microtask(() => _restoreLastSubject(subjects));
      return subjects.first;
    }

    if (state != null && !subjects.any((s) => s.id == state!.id)) {
      return subjects.first;
    }

    return state;
  }

  Future<void> _restoreLastSubject(List<Subject> subjects) async {
    final prefs = await SharedPreferences.getInstance();
    final lastId = prefs.getInt('last_subject_id');

    if (lastId != null) {
      try {
        final savedSubject = subjects.firstWhere((s) => s.id == lastId);
        state = savedSubject;
      } catch (_) {
        state = subjects.first;
      }
    }
  }

  Future<void> setSubject(Subject subject) async {
    state = subject;
    final prefs = await SharedPreferences.getInstance();
    if (subject.id != null) {
      await prefs.setInt('last_subject_id', subject.id!);
    }
  }
}
final activeSubjectProvider = NotifierProvider<ActiveSubjectNotifier, Subject?>(() {
  return ActiveSubjectNotifier();
});