import 'package:caderno_digital_app/core/config/app_config.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../models/canvas_action_model.dart';
import '../../../core/network/time_service.dart';

/// 🚀 Gestor de Histórico Local para Recuperação P2P após Hibernação
class CollaborationHistoryManager {
  // Guardamos as ações num buffer limitado para não explodir a RAM.
  // ~2000 ações é suficiente para cobrir alguns minutos de desconexão.
  static const int _maxHistorySize = 2000;

  final List<CanvasAction> _actionLog = [];
  int _lastDisconnectTimestamp = 0;

  /// Regista uma ação no histórico
  void recordAction(CanvasAction action) {
    _actionLog.add(action);
    if (_actionLog.length > _maxHistorySize) {
      _actionLog.removeAt(0); // Remove a mais antiga
    }
  }

  /// Limpa o histórico (ex: ao fechar o caderno)
  void clear() {
    _actionLog.clear();
    _lastDisconnectTimestamp = 0;
  }

  /// Define o momento em que a app foi para segundo plano
  void markDisconnected() {
    _lastDisconnectTimestamp = TimeService().nowMs();
    AppLog.histo(
      '🛑 [HistoryManager] Desconexão registada às $_lastDisconnectTimestamp',
    );
  }

  /// Atualiza o marcador do último sincronismo com o servidor/p2p
  void updateLastSyncTimestamp(int ts) {
    if (ts > _lastDisconnectTimestamp) {
      _lastDisconnectTimestamp = ts;
      AppLog.histo('⏱️ [HistoryManager] Relógio de histórico atualizado para $ts');
    }
  }

  /// Obtém o timestamp da última desconexão
  int get lastDisconnectTimestamp => _lastDisconnectTimestamp;

  /// Recupera as ações que ocorreram após um determinado timestamp.
  /// 🚀 Otimizado: Não envia histórico P2P gigantesco. Se a desconexão for 
  /// maior que 60 segundos ou tiver mais de 50 ações, retorna vazio, 
  /// delegando a recuperação massiva para o `SyncService` via HTTP (REST).
  List<Map<String, dynamic>> getActionsSince(int timestamp) {
    // Tolerância de 5 segundos para garantir que não perdemos pacotes em trânsito
    final safeTimestamp = timestamp - 5000;
    
    // Se esteve offline há mais de 1 minuto, forçamos uso exclusivo do REST HTTP
    if (TimeService().nowMs() - safeTimestamp > 60000) {
      AppLog.histo('📦 [HistoryManager] Desconexão longa (>60s). P2P ignorado. A usar Sync HTTP.');
      return [];
    }

    final recentActions = _actionLog
        .where((a) => a.timestamp >= safeTimestamp)
        .toList();

    // Se houver demasiadas ações, o payload arrebenta o Reverb (WebSocket).
    // Delegamos para HTTP
    if (recentActions.length > 50) {
      AppLog.histo('📦 [HistoryManager] Demasiadas ações (${recentActions.length}). P2P ignorado. A usar Sync HTTP.');
      return [];
    }

    AppLog.histo(
      '📦 [HistoryManager] Pedido de ações desde $timestamp. Encontradas ${recentActions.length} ações limitadas para envio P2P.',
    );

    // Retornamos os dados mapeados para enviar via Reverb
    return recentActions.map((a) {
      final map = a.toMap();
      // O Reverb envia "action_type" na root, pelo que colocamos para compatibilidade
      return {'action_type': map['type'], 'data': map};
    }).toList();
  }
}

final collaborationHistoryManagerProvider =
    Provider<CollaborationHistoryManager>((ref) {
      return CollaborationHistoryManager();
    });
