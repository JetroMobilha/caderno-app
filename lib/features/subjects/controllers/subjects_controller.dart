import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/sync_provider.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/subject_model.dart';
import '../repositories/subject_repository.dart';
import '../../notebooks/repositories/notebook_repository.dart';
import '../../canvas/repositories/canvas_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

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
    final notebookRepo = ref.read(notebookRepositoryProvider);
    
    // 1. Verificar se houve alteração no estado de arquivo
    // Precisamos de buscar o estado atual no banco antes de atualizar
    final currentSubjects = state;
    final oldSubject = currentSubjects.firstWhere((s) => s.id == subject.id, orElse: () => subject);
    
    final bool wasArchived = oldSubject.isArchived;
    final bool isNowArchived = subject.isArchived;

    // 2. Aplicar a atualização no repositório
    await _repository.updateSubject(subject);

    // 3. CASCATA DE ARQUIVO: Se mudou, aplicar aos cadernos
    if (wasArchived != isNowArchived) {
      debugPrint('📦 [SubjectArchive] Aplicando cascata para estado: $isNowArchived');
      
      // Obter cadernos (usando serverId se disponível para blindagem)
      final notebooks = await notebookRepo.getNotebooksBySubject(subject.id!, subject.serverId);
      
      for (var nb in notebooks) {
        if (nb.isArchived != isNowArchived) {
          await notebookRepo.updateNotebook(nb.copyWith(isArchived: isNowArchived));
        }
      }
    }
    
    // 🚀 Sincronizar para informar a nuvem
    syncManuallyWithCloud();
  }

  Future<void> deleteSubject(Subject subject) async {
    if (subject.id == null) return;
    
    // 1. Marcar a pasta como apagada
    await _repository.deleteSubject(subject);
    
    // 2. Marcar todos os cadernos associados como apagados (Cascata Local)
    final notebookRepo = ref.read(notebookRepositoryProvider);
    final notebooks = await notebookRepo.getNotebooksBySubject(subject.id!, subject.serverId);
    for (var nb in notebooks) {
      await notebookRepo.deleteNotebook(nb);
    }
    
    // 🚀 Sincronizar para informar a nuvem
    syncManuallyWithCloud();
  }

  Future<void> restoreSubject(Subject subject) async {
    if (subject.id == null) return;
    
    // 1. Restaurar a pasta
    await _repository.restoreSubject(subject.id!);
    
    // 2. Restaurar todos os cadernos que foram apagados junto com esta pasta
    final notebookRepo = ref.read(notebookRepositoryProvider);
    final allDeleted = await notebookRepo.getDeletedNotebooks();
    final toRestore = allDeleted.where((n) => n.subjectId == subject.id);
    
    for (var nb in toRestore) {
      await notebookRepo.restoreNotebook(nb.id!);
    }
    
    // 🚀 Sincronizar para informar a nuvem do restauro
    syncManuallyWithCloud();
  }

  Future<List<Subject>> getTrashItems() async {
    return await _repository.getDeletedSubjects();
  }

  Future<void> emptyTrash() async {
    final notebookRepo = ref.read(notebookRepositoryProvider);
    
    // 1. Limpar pastas e os seus cadernos
    final deletedSubs = await _repository.getDeletedSubjects();
    for (var sub in deletedSubs) {
      if (sub.id != null) {
        // Hard delete notebooks of this subject (even if they were not marked as deleted, but subject is)
        final nbs = await notebookRepo.getNotebooksBySubject(sub.id!, sub.serverId);
        for (var nb in nbs) await notebookRepo.hardDeleteNotebook(nb.id!);
        
        // Also hard delete notebooks already in trash for this subject
        final deletedNbs = await notebookRepo.getDeletedNotebooks();
        final subNbsInTrash = deletedNbs.where((n) => n.subjectId == sub.id);
        for (var nb in subNbsInTrash) await notebookRepo.hardDeleteNotebook(nb.id!);
        
        await _repository.hardDeleteSubject(sub.id!);
      }
    }
    
    // 2. Limpar cadernos avulsos que já estavam na lixeira
    final remainingDeletedNbs = await notebookRepo.getDeletedNotebooks();
    for (var nb in remainingDeletedNbs) {
      if (nb.id != null) await notebookRepo.hardDeleteNotebook(nb.id!);
    }
  }

  // 🚀 DUPLICAÇÃO PROFUNDA: Pasta -> Cadernos -> Páginas -> Conteúdo
  Future<void> duplicateSubject(Subject source) async {
    try {
      final notebookRepo = ref.read(notebookRepositoryProvider);
      final canvasRepo = ref.read(canvasRepositoryProvider);

      // 1. Clonar a Pasta
      final clonedSubject = source.clone();
      final newSubject = await _repository.addSubject(clonedSubject);
      
      if (newSubject == null || newSubject.id == null) return;
      final int newSubId = newSubject.id!;

      // 2. Obter Cadernos da Pasta Original
      final originalNotebooks = await notebookRepo.getNotebooksBySubject(source.id!, source.serverId);
      debugPrint('📑 [SubjectClone] Iniciando cópia de ${originalNotebooks.length} cadernos para a pasta $newSubId');

      for (var nb in originalNotebooks) {
        // 3. Clonar cada Caderno
        final clonedNb = nb.clone(newSubjectId: newSubId);
        final int newNbId = await notebookRepo.insertNotebook(clonedNb);

        // 4. Obter Páginas do Caderno Original com Conteúdo
        final originalPages = await canvasRepo.getPagesByNotebook(nb.id!, nb.serverId);
        debugPrint('  📄 [SubjectClone] Copiando ${originalPages.length} páginas para o caderno $newNbId');

        for (var page in originalPages) {
          // 5. Clonar cada Página
          final clonedPage = page.clone(newNotebookId: newNbId);
          await canvasRepo.savePage(clonedPage, null);

          // 6. Salvar Elementos (Strokes, Text, Images)
          for (var s in clonedPage.strokes) {
            await canvasRepo.saveSingleStroke(clonedPage.clientId, s);
          }
          for (var t in clonedPage.textBlocks) {
            await canvasRepo.saveSingleTextBlock(clonedPage.clientId, t);
          }
          for (var i in clonedPage.imageBlocks) {
            await canvasRepo.saveSingleImageBlock(clonedPage.clientId, i);
          }
        }
      }
      
      debugPrint('✅ [SubjectClone] Pasta "${source.name}" duplicada com sucesso!');
    } catch (e) {
      debugPrint('🚨 [SubjectClone] Erro fatal: $e');
    }
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

// ============================================================================
// ⚙️ DEFINIÇÕES DE UI (Persistência de filtros e vistas)
// ============================================================================
class SubjectsUiSettings {
  final bool showArchivedInDrawer;
  final bool showArchivedInList;
  final bool showArchivedInNotebooks;

  SubjectsUiSettings({
    this.showArchivedInDrawer = false,
    this.showArchivedInList = false,
    this.showArchivedInNotebooks = false,
  });

  SubjectsUiSettings copyWith({
    bool? showArchivedInDrawer,
    bool? showArchivedInList,
    bool? showArchivedInNotebooks,
  }) {
    return SubjectsUiSettings(
      showArchivedInDrawer: showArchivedInDrawer ?? this.showArchivedInDrawer,
      showArchivedInList: showArchivedInList ?? this.showArchivedInList,
      showArchivedInNotebooks: showArchivedInNotebooks ?? this.showArchivedInNotebooks,
    );
  }
}

class SubjectsUiNotifier extends Notifier<SubjectsUiSettings> {
  static const _kDrawerKey = 'ui_subjects_drawer_archived';
  static const _kListKey = 'ui_subjects_list_archived';
  static const _kNotebooksKey = 'ui_notebooks_list_archived';

  @override
  SubjectsUiSettings build() {
    _load();
    return SubjectsUiSettings();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    state = SubjectsUiSettings(
      showArchivedInDrawer: prefs.getBool(_kDrawerKey) ?? false,
      showArchivedInList: prefs.getBool(_kListKey) ?? false,
      showArchivedInNotebooks: prefs.getBool(_kNotebooksKey) ?? false,
    );
  }

  Future<void> toggleDrawerArchive() async {
    final newValue = !state.showArchivedInDrawer;
    state = state.copyWith(showArchivedInDrawer: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kDrawerKey, newValue);
  }

  Future<void> toggleListArchive({bool? forceValue}) async {
    final newValue = forceValue ?? !state.showArchivedInList;
    state = state.copyWith(showArchivedInList: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kListKey, newValue);
  }

  Future<void> toggleNotebooksArchive() async {
    final newValue = !state.showArchivedInNotebooks;
    state = state.copyWith(showArchivedInNotebooks: newValue);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotebooksKey, newValue);
  }
}

final subjectsUiProvider = NotifierProvider<SubjectsUiNotifier, SubjectsUiSettings>(() {
  return SubjectsUiNotifier();
});
