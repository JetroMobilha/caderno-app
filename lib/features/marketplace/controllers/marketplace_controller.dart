import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/sync_provider.dart'; // 🚀 Novo
import '../../../core/database/app_database.dart' hide Notebook;
import '../../auth/controllers/auth_controller.dart';
import '../../notebooks/controllers/notebooks_controller.dart';
import '../../notebooks/models/notebook_model.dart';
import '../../subjects/controllers/subjects_controller.dart';
import '../repositories/marketplace_repository.dart';

class MarketplaceState {
  final List<Notebook> notebooks;
  final bool isLoading;
  final bool isLoadingMore;
  final bool isAcquiring; // 🚀 Rastreio de compra em curso
  final bool hasMore;
  final int currentPage;
  final String searchQuery;

  MarketplaceState({
    required this.notebooks,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.isAcquiring = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.searchQuery = '',
  });

  MarketplaceState copyWith({
    List<Notebook>? notebooks,
    bool? isLoading,
    bool? isLoadingMore,
    bool? isAcquiring,
    bool? hasMore,
    int? currentPage,
    String? searchQuery,
  }) {
    return MarketplaceState(
      notebooks: notebooks ?? this.notebooks,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isAcquiring: isAcquiring ?? this.isAcquiring,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  final Ref ref;

  MarketplaceNotifier(this.ref) : super(MarketplaceState(notebooks: [])) {
    loadInitial();
  }

  MarketplaceRepository get _repository => ref.read(marketplaceRepositoryProvider);

  Future<void> loadInitial({String query = ''}) async {
    state = state.copyWith(isLoading: true, currentPage: 1, searchQuery: query, notebooks: []);
    await _fetchPage(page: 1, query: query, isInitial: true);
  }

  Future<void> loadMore() async {
    if (state.isLoading || state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    await _fetchPage(page: state.currentPage + 1, query: state.searchQuery, isInitial: false);
  }

  Future<void> _fetchPage({required int page, required String query, required bool isInitial}) async {
    final token = ref.read(authProvider).token;
    if (token == null) {
      state = state.copyWith(isLoading: false, isLoadingMore: false);
      return;
    }

    try {
      final result = await _repository.getPublishedNotebooks(page: page, searchQuery: query);
      
      final List<Notebook> newNotebooks = result['notebooks'];
      final int lastPage = result['last_page'];
      final updatedList = isInitial ? newNotebooks : [...state.notebooks, ...newNotebooks];

      state = state.copyWith(
        notebooks: updatedList,
        isLoading: false,
        isLoadingMore: false,
        currentPage: page,
        hasMore: page < lastPage,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, isLoadingMore: false);
    }
  }

  /// 🚀 ADQUIRIR CADERNO: Ação principal de compra/obtenção
  Future<bool> acquireNotebook(int serverId) async {
    if (state.isAcquiring) return false;
    
    state = state.copyWith(isAcquiring: true);
    
    try {
      // 1. Chamar a API de aquisição. O servidor trata de clonar tudo 
      // e organizar na pasta "Matérias Adquiridas 🛒".
      final clonedNotebook = await _repository.acquireNotebook(serverId);
      
      if (clonedNotebook != null) {
        // 2. Disparar sincronização total. 
        // O motor de Sync detetará a nova pasta e o novo caderno no servidor
        // e descarregará tudo de forma atómica para o SQLite local.
        ref.read(subjectsProvider.notifier).syncManuallyWithCloud();
        
        state = state.copyWith(isAcquiring: false);
        return true;
      }
    } catch (e) {
      debugPrint('🚨 Erro ao adquirir caderno: $e');
    }

    state = state.copyWith(isAcquiring: false);
    return false;
  }
}

final marketplaceProvider = StateNotifierProvider<MarketplaceNotifier, MarketplaceState>((ref) {
  return MarketplaceNotifier(ref);
});
