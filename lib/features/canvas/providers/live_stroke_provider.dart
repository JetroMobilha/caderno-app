import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/canvas_enums.dart';

/* 🚀 v10.50: Notifier de Alta Performance para Desenho em Tempo Real.
/// 
/// Esta classe é o "Hot Path" do sistema de desenho. Para atingir **Latência Zero**,
/// ela rompe com o padrão de imutabilidade do Riverpod durante a fase de captura,
/// utilizando listas mutáveis internas. Isso evita o custo de CPU de copiar milhares 
/// de pontos por segundo (O(N) -> O(1)).
/// 
/// As responsabilidades incluem:
/// 1. Gerir o feedback visual imediato do traço atual (`points`).
/// 2. Gerir o feedback visual do laço de seleção (`lassoPath`).
/// 3. Notificar apenas os componentes de renderização isolados.

 */
class LiveStrokeNotifier extends ChangeNotifier {
  // 🚀 v10.80: Isolamento Total por Ponteiro (Fix: Linhas Fantasmas)
  final Map<int, List<Offset>> _strokes = {};
  final Map<int, String> _pointerIds = {}; // Map de ID de Toque -> UUID do Banco
  
  BrushType _brushType = BrushType.gel;
  String _colorHex = '#000000';
  double _thickness = 1.0;
  double _opacity = 1.0;
  bool _isHighlighter = false;

  List<Offset>? _lassoPath;

  Map<int, List<Offset>> get activeStrokes => _strokes;
  
  // Getter de conveniência para ferramentas legadas (retorna o primeiro ativo)
  String? get id => _pointerIds.values.isNotEmpty ? _pointerIds.values.first : null;
  
  // Retorna o UUID específico de um ponteiro
  String? getStrokeId(int pointerId) => _pointerIds[pointerId];
  
  BrushType get brushType => _brushType;
  String get colorHex => _colorHex;
  double get thickness => _thickness;
  double get opacity => _opacity;
  bool get isHighlighter => _isHighlighter;
  List<Offset>? get lassoPath => _lassoPath;

  bool get isEmpty => _strokes.isEmpty && _lassoPath == null;

  void start({
    required int pointerId,
    required String globalId,
    required Offset startPos,
    required BrushType brushType,
    required String colorHex,
    required double thickness,
    double opacity = 1.0,
    bool isHighlighter = false,
  }) {
    _brushType = brushType;
    _colorHex = colorHex;
    _thickness = thickness;
    _opacity = opacity;
    _isHighlighter = isHighlighter;
    _lassoPath = null;
    
    _pointerIds[pointerId] = globalId;
    _strokes[pointerId] = [startPos];
    notifyListeners();
  }

  void update(int pointerId, Offset pos) {
    if (_strokes.containsKey(pointerId)) {
      _strokes[pointerId]!.add(pos);
      notifyListeners();
    }
  }

  void removeStroke(int pointerId) {
    _strokes.remove(pointerId);
    _pointerIds.remove(pointerId);
    notifyListeners();
  }

  void keepOnly(int winnerPointerId) {
    final winnerPoints = _strokes[winnerPointerId];
    final winnerId = _pointerIds[winnerPointerId];
    
    _strokes.clear();
    _pointerIds.clear();
    
    if (winnerPoints != null && winnerId != null) {
      _strokes[winnerPointerId] = winnerPoints;
      _pointerIds[winnerPointerId] = winnerId;
    }
    notifyListeners();
  }

  void startLasso(Offset startPos) {
    _lassoPath = [startPos];
    _strokes.clear();
    _pointerIds.clear();
    notifyListeners();
  }

  void updateLasso(Offset pos) {
    _lassoPath?.add(pos);
    notifyListeners();
  }

  void clear() {
    _strokes.clear();
    _pointerIds.clear();
    _lassoPath = null;
    notifyListeners();
  }

  List<Offset> getPoints(int pointerId) => _strokes[pointerId] ?? [];
}

final liveStrokeProvider = ChangeNotifierProvider<LiveStrokeNotifier>((ref) {
  return LiveStrokeNotifier();
});
