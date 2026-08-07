import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/handwriting_repository.dart';

class HandwritingState {
  final String currentCharacter;
  final List<List<Offset>> currentStrokes;
  final Set<String> trainedCharacters;
  final bool isSaving;
  final bool isLoading;

  HandwritingState({
    required this.currentCharacter,
    this.currentStrokes = const [],
    this.trainedCharacters = const {},
    this.isSaving = false,
    this.isLoading = false,
  });

  HandwritingState copyWith({
    String? currentCharacter,
    List<List<Offset>>? currentStrokes,
    Set<String>? trainedCharacters,
    bool? isSaving,
    bool? isLoading,
  }) {
    return HandwritingState(
      currentCharacter: currentCharacter ?? this.currentCharacter,
      currentStrokes: currentStrokes ?? this.currentStrokes,
      trainedCharacters: trainedCharacters ?? this.trainedCharacters,
      isSaving: isSaving ?? this.isSaving,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class HandwritingController extends StateNotifier<HandwritingState> {
  final Ref ref;

  HandwritingController(this.ref) : super(HandwritingState(currentCharacter: 'A')) {
    loadProgress();
  }

  HandwritingRepository get _repository => ref.read(handwritingRepositoryProvider);

  /// 📋 Carregar quais caracteres já foram treinados
  Future<void> loadProgress() async {
    state = state.copyWith(isLoading: true);
    final trained = await _repository.getTrainedCharacters();
    state = state.copyWith(
      trainedCharacters: trained.toSet(),
      isLoading: false,
    );
  }

  /// 🔠 Mudar o caractere que está a ser treinado
  void setCharacter(String char) {
    if (state.currentCharacter == char) return;
    state = state.copyWith(
      currentCharacter: char,
      currentStrokes: [], // Limpa o canvas para o novo caractere
    );
  }

  /// ✍️ Adicionar um traço completo (vindo do canvas fluido)
  void addFullStroke(List<Offset> points) {
    if (points.isEmpty) return;
    final List<List<Offset>> newStrokes = List.from(state.currentStrokes);
    newStrokes.add(points);
    state = state.copyWith(currentStrokes: newStrokes);
  }

  /// ✍️ Adicionar um novo traço (ponto inicial) - Legado/Realtime manual
  void startStroke(Offset point) {
    final List<List<Offset>> newStrokes = List.from(state.currentStrokes);
    newStrokes.add([point]);
    state = state.copyWith(currentStrokes: newStrokes);
  }

  /// 🖊️ Continuar um traço (adicionar pontos)
  void updateStroke(Offset point) {
    if (state.currentStrokes.isEmpty) return;
    
    final lastStroke = state.currentStrokes.last;
    if (lastStroke.isNotEmpty && (point - lastStroke.last).distance < 1.2) return;

    final List<List<Offset>> newStrokes = List.from(state.currentStrokes);
    newStrokes.last = List.from(lastStroke)..add(point);
    state = state.copyWith(currentStrokes: newStrokes);
  }

  /// 🧹 Limpar o desenho atual
  void clearCanvas() {
    state = state.copyWith(currentStrokes: []);
  }

  /// ↩️ Desfazer o último traço
  void undoLastStroke() {
    if (state.currentStrokes.isEmpty) return;
    final List<List<Offset>> newStrokes = List.from(state.currentStrokes);
    newStrokes.removeLast();
    state = state.copyWith(currentStrokes: newStrokes);
  }

  /// 💾 Enviar caractere para o servidor
  Future<bool> saveCurrentCharacter() async {
    if (state.currentStrokes.isEmpty) return false;
    
    state = state.copyWith(isSaving: true);
    
    final bool success = await _repository.saveCharacter(
      character: state.currentCharacter,
      strokes: state.currentStrokes,
    );
    
    if (success) {
      final Set<String> updatedTrained = Set.from(state.trainedCharacters);
      updatedTrained.add(state.currentCharacter);
      
      state = state.copyWith(
        trainedCharacters: updatedTrained,
        isSaving: false,
        // Mantemos os traços no ecrã para o utilizador ver o que guardou
      );
    } else {
      state = state.copyWith(isSaving: false);
    }
    
    return success;
  }
}

final handwritingProvider = StateNotifierProvider<HandwritingController, HandwritingState>((ref) {
  return HandwritingController(ref);
});
