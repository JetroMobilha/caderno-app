import 'dart:collection';

/// 🎵 Gestor de Buffer para Fluxos de Áudio Live
/// Resolve o problema de pacotes fora de ordem e perca de fluidez.
class AudioStreamBuffer {
  final String msgId;
  final String senderId;
  
  // Mapa ordenado por índice do segmento
  final SplayTreeMap<int, String> _segments = SplayTreeMap<int, String>();
  
  int nextIndexToPlay = 0;
  bool isFinalized = false;
  int? totalSegments;
  DateTime lastActivity = DateTime.now();

  AudioStreamBuffer({required this.msgId, required this.senderId});

  void addSegment(int index, String url, {bool isFinal = false}) {
    _segments[index] = url;
    if (isFinal) {
      isFinalized = true;
      totalSegments = index + 1;
    }
    lastActivity = DateTime.now();
  }

  /// Tenta obter o próximo segmento na sequência correta.
  /// Retorna null se o próximo segmento ainda não chegou.
  String? popNext() {
    if (_segments.containsKey(nextIndexToPlay)) {
      return _segments[nextIndexToPlay++];
    }
    return null;
  }

  bool get hasMoreToPlay {
    if (isFinalized && totalSegments != null) {
      return nextIndexToPlay < totalSegments!;
    }
    // Se não está finalizado, assumimos que pode vir mais
    return true; 
  }

  int get bufferedCount => _segments.length;
  
  /// Verifica se temos um buffer mínimo para começar (1 segmento = 3 segundos).
  /// Isso garante que a reprodução comece com fluidez mesmo em redes instáveis.
  bool get isReadyToStart => _segments.length >= 1 || isFinalized;

  void clear() {
    _segments.clear();
    nextIndexToPlay = 0;
  }
}
