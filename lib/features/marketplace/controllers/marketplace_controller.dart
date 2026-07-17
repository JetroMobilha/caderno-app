import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import '../../auth/controllers/auth_controller.dart';
import '../../notebooks/models/notebook_model.dart';

class MarketplaceState {
  final List<Notebook> notebooks;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int currentPage;
  final String searchQuery;

  MarketplaceState({
    required this.notebooks,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.currentPage = 1,
    this.searchQuery = '',
  });

  MarketplaceState copyWith({
    List<Notebook>? notebooks,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? currentPage,
    String? searchQuery,
  }) {
    return MarketplaceState(
      notebooks: notebooks ?? this.notebooks,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      currentPage: currentPage ?? this.currentPage,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

class MarketplaceNotifier extends StateNotifier<MarketplaceState> {
  final Ref ref;
  // Ajusta para o IP/domínio real da tua API
  final String _baseUrl = 'http://35.205.132.251:8080/api';

  MarketplaceNotifier(this.ref) : super(MarketplaceState(notebooks: [])) {
    loadInitial();
  }

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
      final url = Uri.parse('$_baseUrl/marketplace/notebooks?page=$page&q=$query');
      final response = await http.get(url, headers: {
        'Authorization': 'Bearer $token',
        'Accept': 'application/json',
      });

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        final List rawList = body['data'] ?? [];
        final int lastPage = body['last_page'] ?? 1;

        final newNotebooks = rawList.map((json) => Notebook.fromMap(json)).toList();
        final updatedList = isInitial ? newNotebooks : [...state.notebooks, ...newNotebooks];

        state = state.copyWith(
          notebooks: updatedList,
          isLoading: false,
          isLoadingMore: false,
          currentPage: page,
          hasMore: page < lastPage,
        );
      } else {
        state = state.copyWith(isLoading: false, isLoadingMore: false);
      }
    } catch (e) {
      state = state.copyWith(isLoading: false, isLoadingMore: false);
    }
  }
}

final marketplaceProvider = StateNotifierProvider<MarketplaceNotifier, MarketplaceState>((ref) {
  return MarketplaceNotifier(ref);
});