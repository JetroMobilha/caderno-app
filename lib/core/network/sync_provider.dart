import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/controllers/auth_controller.dart';
import 'sync_service.dart';

class SyncNotifier extends StateNotifier<SyncState> {
  final Ref ref;
  Timer? _syncTimer;
  final SyncService _syncService = SyncService();

  SyncNotifier(this.ref) : super(SyncState.idle) {
    // Iniciar o loop de sincronização automática
    _startAutoSync();
  }

  void _startAutoSync() {
    _syncTimer?.cancel();
    // Tenta sincronizar a cada 5 minutos
    _syncTimer = Timer.periodic(const Duration(minutes: 5), (timer) async {
      final auth = ref.read(authProvider);
      if (auth.isAuthenticated) {
        await performSync();
      }
    });
  }

  Future<void> performSync({bool forced = false}) async {
    if (state == SyncState.syncing) return;

    state = SyncState.syncing;
    debugPrint('🔄 [SyncProvider] A iniciar ciclo de sincronização...');
    
    try {
      await _syncService.syncAll(forced: forced);
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
    super.dispose();
  }
}

enum SyncState { idle, syncing, error }

final syncProvider = StateNotifierProvider<SyncNotifier, SyncState>((ref) {
  return SyncNotifier(ref);
});
