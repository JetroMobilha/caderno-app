import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/controllers/auth_controller.dart';
import '../../features/auth/controllers/auth_state.dart';
import '../../features/canvas/repositories/canvas_repository.dart';
import 'api_provider.dart';
import 'realtime_service.dart';
import 'sync_service.dart';

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref ref;
  Timer? _syncTimer;
  Timer? _connectivityDebouncer; // 🚀 Debouncer de rede
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;
  final SyncService _syncService;

  SyncNotifier(this.ref, this._syncService) : super(SyncState.idle) {
    // 1. Iniciar o loop de sincronização periódica (Failsafe)
    _startAutoSync();
    
    // 2. Ouvir mudanças de rede para sincronização inteligente (Quando ficar online)
    _listenToConnectivity();

    // 3. 🚀 REINÍCIO INTELIGENTE NO LOGIN:
    // Observa o estado de autenticação. Se passar de deslogado para logado,
    // força o reinício da rede e sincroniza imediatamente.
    ref.listen<AuthState>(authProvider, (previous, next) {
      final wasAuthenticated = previous?.isAuthenticated ?? false;
      final isNowAuthenticated = next.isAuthenticated;

      if (!wasAuthenticated && isNowAuthenticated) {
        debugPrint('🔐 [Sync] Login detetado. Reiniciando rede e forçando sincronização...');
        
        // A. Forçar reinício do WebSocket (Realtime)
        ref.read(realtimeServiceProvider).initConnection();
        
        // B. Disparar Sincronização Leve (Metadata) imediatamente
        performSync(forced: true, metadataOnly: true);
      }
    });
  }

  void _startAutoSync() {
    _syncTimer?.cancel();
    // Tenta sincronizar a cada 5 minutos como redundância
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated) {
        await performSync();
      }
    });
  }

  void _listenToConnectivity() {
    _connectivitySubscription?.cancel();
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((results) async {
      // Se voltamos a ter qualquer tipo de ligação, tentamos o sync
      final bool isConnected = results.any((r) => r != ConnectivityResult.none);
      
      if (isConnected) {
        _connectivityDebouncer?.cancel();
        _connectivityDebouncer = Timer(const Duration(seconds: 2), () async {
          final auth = ref.read(authProvider);
          if (auth.isAuthenticated) {
            debugPrint('🌐 [Sync] Ligação estável detectada. Disparando sincronização...');
            await performSync();
          }
        });
      }
    });
  }

  Future<void> performSync({bool forced = false, bool metadataOnly = false, bool pushOnly = false}) async {
    if (state == SyncState.syncing) return;

    state = SyncState.syncing;
    debugPrint('🔄 [SyncProvider] A iniciar ciclo de sincronização... (Forced: $forced, Meta: $metadataOnly, Push: $pushOnly)');
    
    try {
      await _syncService.syncAll(forced: forced, metadataOnly: metadataOnly, pushOnly: pushOnly);
      state = SyncState.idle;
      debugPrint('✅ [SyncProvider] Ciclo concluído.');
    } catch (e) {
      debugPrint('❌ [SyncProvider] Erro no ciclo: $e');
      if (mounted) state = SyncState.error;
      // Volta para idle após um tempo para permitir novas tentativas
      Future.delayed(const Duration(seconds: 10), () {
        if (mounted && state == SyncState.error) {
          state = SyncState.idle;
        }
      });
    }
  }

  @override
  void dispose() {
    _syncTimer?.cancel();
    _connectivitySubscription?.cancel();
    super.dispose();
  }
}

enum SyncState { idle, syncing, error }

final appSyncServiceProvider = Provider<SyncService>((ref) {
  final apiService = ref.watch(apiServiceProvider);
  final canvasRepository = ref.watch(canvasRepositoryProvider);
  return SyncService(apiService, canvasRepository);
});

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  final syncService = ref.watch(appSyncServiceProvider);
  return SyncNotifier(ref, syncService);
});
