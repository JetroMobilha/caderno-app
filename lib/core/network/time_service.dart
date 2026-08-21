import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 🕒 Serviço para sincronizar o relógio do telemóvel com o do servidor.
/// Resolve o problema de "Clock Skew" em sistemas distribuídos.
/// 🚀 OFFLINE-FIRST: Persistente e resistente a alterações manuais do relógio (Relógio Monotónico).
class TimeService {
  static final TimeService _instance = TimeService._internal();
  factory TimeService() => _instance;
  TimeService._internal();

  int _driftMs = 0; // Desvio persistido: (ServerTime - LocalTime)
  bool _hasSyncedAtLeastOnce = false;
  int _lastSyncTimestamp = 0; // Quando foi a última calibração online

  // 🛡️ PROTEÇÃO ADICIONAL: Relógio Monotónico
  // Rastreia o passar do tempo real enquanto a app está aberta, 
  // ignorando se o utilizador muda a hora do sistema.
  final Stopwatch _monotonicClock = Stopwatch();
  int _serverTimeAtMonotonicStart = 0;

  // Chaves para persistência
  static const String _kDriftKey = 'time_sync_drift_ms';
  static const String _kLastSyncKey = 'time_sync_last_ts';

  /// 🚀 Inicializa o serviço carregando o desvio do disco.
  Future<void> init() async {
    _monotonicClock.start();
    try {
      final prefs = await SharedPreferences.getInstance();
      _driftMs = prefs.getInt(_kDriftKey) ?? 0;
      _lastSyncTimestamp = prefs.getInt(_kLastSyncKey) ?? 0;
      _hasSyncedAtLeastOnce = _lastSyncTimestamp != 0;
      
      // Âncora inicial: assumimos que o servidor está em (LocalNow + Drift)
      _serverTimeAtMonotonicStart = DateTime.now().millisecondsSinceEpoch + _driftMs;

      if (_hasSyncedAtLeastOnce) {
        debugPrint('🕒 [TimeSync] Desvio carregado: ${_driftMs}ms. Calibração persistente ativa.');
      }
    } catch (e) {
      debugPrint('🚨 [TimeSync] Erro inicialização: $e');
    }
  }

  /// 🚀 Atualiza o desvio a partir de dados do servidor e persiste no disco.
  void updateOffset({int? serverTimeMs, String? serverTimeIso}) async {
    final int localNow = DateTime.now().millisecondsSinceEpoch;
    int? sMs = serverTimeMs;

    if (sMs == null && serverTimeIso != null) {
      try {
        sMs = DateTime.parse(serverTimeIso).millisecondsSinceEpoch;
      } catch (e) {
        debugPrint('🚨 [TimeSync] Erro parse data ISO: $e');
      }
    }

    if (sMs != null) {
      final int newDrift = sMs - localNow;
      
      // Calibrar âncora monotónica
      _serverTimeAtMonotonicStart = sMs;
      _monotonicClock.reset();
      _monotonicClock.start();

      // Só persistir se houver uma mudança significativa (> 100ms) ou se nunca sincronizou
      if (!_hasSyncedAtLeastOnce || (newDrift - _driftMs).abs() > 100) {
        _driftMs = newDrift;
        _lastSyncTimestamp = localNow;
        _hasSyncedAtLeastOnce = true;
        
        debugPrint('💾 [TimeSync] Calibração Refinada: ${_driftMs}ms (Persistida)');
        
        try {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt(_kDriftKey, _driftMs);
          await prefs.setInt(_kLastSyncKey, _lastSyncTimestamp);
        } catch (e) {
          debugPrint('🚨 [TimeSync] Erro persistência: $e');
        }
      }
    }
  }

  /// 🎯 Devolve o tempo atual "corrigido" (Relativo ao Servidor).
  /// 🛡️ Usa o relógio monotónico se disponível para evitar saltos manuais.
  int nowMs() {
    if (_serverTimeAtMonotonicStart > 0) {
      // Cálculo resiliente: (Hora do servidor no sync) + (Tempo real decorrido)
      return _serverTimeAtMonotonicStart + _monotonicClock.elapsedMilliseconds;
    }
    // Fallback se ainda não sincronizou: Relógio local + último drift conhecido
    return DateTime.now().millisecondsSinceEpoch + _driftMs;
  }

  /// 🎯 Devolve um objeto DateTime na hora do servidor.
  DateTime now() {
    return DateTime.fromMillisecondsSinceEpoch(nowMs());
  }

  /// 🛡️ Indica se já houve pelo menos uma sincronização com o servidor.
  bool get isCalibrated => _hasSyncedAtLeastOnce;

  /// 🛡️ Indica se a calibração atual é "fresca" (menos de 24 horas).
  bool get isCalibrationFresh {
    if (!_hasSyncedAtLeastOnce) return false;
    final int age = DateTime.now().millisecondsSinceEpoch - _lastSyncTimestamp;
    return age < (24 * 60 * 60 * 1000); // 24h
  }
}
