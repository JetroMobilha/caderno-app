import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../core/database/app_database.dart' hide User, Subject, Notebook, Page;
import '../../auth/controllers/auth_controller.dart';
import '../../subjects/models/subject_model.dart';
import '../../subjects/repositories/subject_repository.dart';
import '../../notebooks/models/notebook_model.dart';
import '../../notebooks/repositories/notebook_repository.dart';
import '../../canvas/models/local_page_model.dart';
import '../../canvas/repositories/canvas_repository.dart';

class QuickNotesState {
  final List<LocalPage> notes;
  final bool isLoading;
  final int? notebookId;

  QuickNotesState({
    this.notes = const [],
    this.isLoading = false,
    this.notebookId,
  });

  QuickNotesState copyWith({
    List<LocalPage>? notes,
    bool? isLoading,
    int? notebookId,
  }) {
    return QuickNotesState(
      notes: notes ?? this.notes,
      isLoading: isLoading ?? this.isLoading,
      notebookId: notebookId ?? this.notebookId,
    );
  }
}

class QuickNotesController extends StateNotifier<QuickNotesState> {
  final Ref ref;
  StreamSubscription? _pagesSubscription;

  QuickNotesController(this.ref) : super(QuickNotesState()) {
    _init();
  }

  SubjectRepository get _subjectRepo => ref.read(subjectRepositoryProvider);
  NotebookRepository get _notebookRepo => ref.read(notebookRepositoryProvider);
  CanvasRepository get _canvasRepo => ref.read(canvasRepositoryProvider);

  Future<void> _init() async {
    state = state.copyWith(isLoading: true);

    final user = ref.read(authProvider).currentUser;
    if (user == null || user.id == null) {
      state = state.copyWith(isLoading: false);
      return;
    }

    // 1. Garantir que a disciplina de sistema existe
    final subjects = await _subjectRepo.getAllSubjects();
    Subject? systemSubject = subjects.cast<Subject?>().firstWhere(
      (s) => s?.name == 'Agenda & Sistema', 
      orElse: () => null
    );

    if (systemSubject == null) {
      systemSubject = await _subjectRepo.addSubject(Subject(
        userId: user.id,
        name: 'Agenda & Sistema',
        color: '#0F4C5C',
        icon: 'calendar',
      ));
    }

    if (systemSubject == null) return;

    // 2. Garantir que o caderno de notas existe
    final notebooks = await _notebookRepo.getNotebooksBySubject(systemSubject.id!, null);
    Notebook? notesNotebook = notebooks.cast<Notebook?>().firstWhere(
      (n) => n?.templateType == 'quick_notes', 
      orElse: () => null
    );

    if (notesNotebook == null) {
      final newId = await _notebookRepo.insertNotebook(Notebook(
        subjectId: systemSubject.id,
        title: 'Minhas Notas Rápidas',
        coverType: 'color',
        color: '#0F4C5C',
        lineType: 'blank',
        paperSize: 'A4',
        templateType: 'quick_notes',
      ));
      notesNotebook = Notebook(
        id: newId,
        subjectId: systemSubject.id,
        title: 'Minhas Notas Rápidas',
        coverType: 'color',
        lineType: 'blank',
        paperSize: 'A4',
      );
    }

    if (notesNotebook?.id == null) return;

    state = state.copyWith(notebookId: notesNotebook!.id);

    // 3. Assistir às páginas (notas)
    _pagesSubscription?.cancel();
    _pagesSubscription = _canvasRepo.watchPagesByNotebook(notesNotebook.id!).listen((pages) async {
      final List<LocalPage> fullNotes = [];
      for (var p in pages) {
        if (p.isDeleted) continue;
        // Precisamos do conteúdo (extractedText) que não vem no watch padrão (lazy)
        final content = await _canvasRepo.loadPageContent(p.id!);
        fullNotes.add(p.copyWith(
          strokes: content['strokes'],
          textBlocks: content['textBlocks'],
          imageBlocks: content['imageBlocks'],
        )..isContentLoaded = true);
      }
      
      // Ordenar por data (updatedAt) decrescente
      fullNotes.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
      
      state = state.copyWith(notes: fullNotes, isLoading: false);
    });
  }

  Future<void> addNote({required String title, required String content, required String colorHex}) async {
    if (state.notebookId == null) return;

    final newPage = LocalPage(
      notebookId: state.notebookId!,
      pageNumber: state.notes.length + 1,
      isLandscape: false,
      title: title,
      extractedText: content,
      footer: colorHex, // Usamos footer para a cor
    );

    await _canvasRepo.savePage(newPage, null);
  }

  Future<void> updateNote(LocalPage note, {String? title, String? content, String? colorHex}) async {
    final updated = note.copyWith(
      title: title ?? note.title,
      extractedText: content ?? note.extractedText,
      footer: colorHex ?? note.footer,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
      syncedWithCloud: 0,
    );

    await _canvasRepo.savePage(updated, null);
  }

  Future<void> deleteNote(LocalPage note) async {
    if (note.id == null) return;
    
    // Soft delete
    final updated = note.copyWith(isDeleted: true, syncedWithCloud: 0);
    await _canvasRepo.savePage(updated, null);
  }

  @override
  void dispose() {
    _pagesSubscription?.cancel();
    super.dispose();
  }
}

final quickNotesProvider = StateNotifierProvider<QuickNotesController, QuickNotesState>((ref) {
  return QuickNotesController(ref);
});
