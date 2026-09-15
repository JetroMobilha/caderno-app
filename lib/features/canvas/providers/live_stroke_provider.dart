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
  final List<Offset> _points = [];
  String? _id;
  BrushType _brushType = BrushType.gel;
  String _colorHex = '#000000';
  double _thickness = 1.0;
  double _opacity = 1.0;
  bool _isHighlighter = false;

  // Feedback visual do Laço (Lasso)
  List<Offset>? _lassoPath;

  /// Lista mutável de pontos do traço em curso.
  List<Offset> get points => _points;
  
  /// ID temporário do traço atual.
  String? get id => _id;
  
  BrushType get brushType => _brushType;
  String get colorHex => _colorHex;
  double get thickness => _thickness;
  double get opacity => _opacity;
  bool get isHighlighter => _isHighlighter;
  
  /// Caminho do laço de seleção ativa.
  List<Offset>? get lassoPath => _lassoPath;

  /// Verifica se não há atividade de desenho no momento.
  bool get isEmpty => _points.isEmpty && _lassoPath == null;

  /// Inicializa um novo traço live com as propriedades da caneta selecionada.
  void start({
    required String id,
    required Offset startPos,
    required BrushType brushType,
    required String colorHex,
    required double thickness,
    double opacity = 1.0,
    bool isHighlighter = false,
  }) {
    _id = id;
    _points.clear();
    _points.add(startPos);
    _brushType = brushType;
    _colorHex = colorHex;
    _thickness = thickness;
    _opacity = opacity;
    _isHighlighter = isHighlighter;
    _lassoPath = null;
    notifyListeners();
  }

  /// Adiciona um novo ponto à lista mutável sem recriar a lista.
  /// Operação O(1) que garante a fluidez em traços longos.
  void update(Offset pos) {
    _points.add(pos);
    notifyListeners(); // 🚀 Notifica apenas quem observa o LiveStroke
  }

  /// Inicia o feedback visual para a ferramenta de Laço.
  void startLasso(Offset startPos) {
    _lassoPath = [startPos];
    _points.clear();
    _id = null;
    notifyListeners();
  }

  /// Atualiza o caminho do laço em tempo real.
  void updateLasso(Offset pos) {
    _lassoPath?.add(pos);
    notifyListeners();
  }

  /// Limpa todos os dados live, preparando para o próximo toque.
  void clear() {
    _id = null;
    _points.clear();
    _lassoPath = null;
    notifyListeners();
  }
}

final liveStrokeProvider = ChangeNotifierProvider<LiveStrokeNotifier>((ref) {
  return LiveStrokeNotifier();
});
