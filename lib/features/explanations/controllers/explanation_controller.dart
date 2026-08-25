import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/explanation_model.dart';

class ExplanationState {
  final List<ExplanationModel> activeExplanations;
  final bool isMotorEnabled;

  ExplanationState({
    this.activeExplanations = const [],
    this.isMotorEnabled = true,
  });

  ExplanationState copyWith({
    List<ExplanationModel>? activeExplanations,
    bool? isMotorEnabled,
  }) {
    return ExplanationState(
      activeExplanations: activeExplanations ?? this.activeExplanations,
      isMotorEnabled: isMotorEnabled ?? this.isMotorEnabled,
    );
  }
}

class ExplanationController extends StateNotifier<ExplanationState> {
  ExplanationController() : super(ExplanationState());

  void addExplanation(ExplanationModel explanation) {
    state = state.copyWith(
      activeExplanations: [...state.activeExplanations, explanation],
    );
  }

  void removeExplanation(String id) {
    state = state.copyWith(
      activeExplanations: state.activeExplanations.where((e) => e.id != id).toList(),
    );
  }

  void updateExplanation(ExplanationModel updated) {
    state = state.copyWith(
      activeExplanations: state.activeExplanations
          .map((e) => e.id == updated.id ? updated : e)
          .toList(),
    );
  }

  void toggleMotor(bool enabled) {
    state = state.copyWith(isMotorEnabled: enabled);
  }

  void clearPage() {
    state = state.copyWith(activeExplanations: []);
  }
}

final explanationProvider = StateNotifierProvider<ExplanationController, ExplanationState>((ref) {
  return ExplanationController();
});
