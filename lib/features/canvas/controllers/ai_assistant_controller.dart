import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/ai_assistant_service.dart';

class AIAssistantState {
  final bool isSearching;
  final List<AIQueryResult> searchResults;
  final String? lastSummary;
  final String? error;

  AIAssistantState({
    this.isSearching = false,
    this.searchResults = const [],
    this.lastSummary,
    this.error,
  });

  AIAssistantState copyWith({
    bool? isSearching,
    List<AIQueryResult>? searchResults,
    String? lastSummary,
    String? error,
  }) {
    return AIAssistantState(
      isSearching: isSearching ?? this.isSearching,
      searchResults: searchResults ?? this.searchResults,
      lastSummary: lastSummary ?? this.lastSummary,
      error: error ?? this.error,
    );
  }
}

class AIAssistantController extends StateNotifier<AIAssistantState> {
  final AIAssistantService _service = AIAssistantService();

  AIAssistantController() : super(AIAssistantState());

  Future<void> search(String query, {int? notebookId}) async {
    state = state.copyWith(isSearching: true, error: null);
    try {
      final results = await _service.searchInNotebooks(query, notebookId: notebookId);
      state = state.copyWith(isSearching: false, searchResults: results);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: "Falha na pesquisa inteligente.");
    }
  }

  Future<void> summarizePage(int pageId) async {
    state = state.copyWith(isSearching: true, error: null);
    try {
      final summary = await _service.generateSummary(pageId: pageId);
      state = state.copyWith(isSearching: false, lastSummary: summary);
    } catch (e) {
      state = state.copyWith(isSearching: false, error: "Falha ao gerar resumo.");
    }
  }

  void clearResults() {
    state = AIAssistantState();
  }
}

final aiAssistantProvider = StateNotifierProvider<AIAssistantController, AIAssistantState>((ref) {
  return AIAssistantController();
});
