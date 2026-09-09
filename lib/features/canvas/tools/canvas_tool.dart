import 'package:flutter/material.dart';
import '../models/local_page_model.dart';
import '../models/canvas_enums.dart';

/// 🚀 v10.5: Classe base para o Sistema de Ferramentas (Pilar 4).
abstract class CanvasTool {
  final ToolMode mode;
  const CanvasTool(this.mode);

  void onTapDown(Offset localPos, dynamic ref, LocalPage page);
  void onPanStart(Offset localPos, dynamic ref, LocalPage page);
  void onPanUpdate(Offset localPos, Offset delta, dynamic ref, LocalPage page);
  void onPanEnd(dynamic ref, LocalPage page);
  
  /// Chamado quando a ferramenta é desativada.
  void onToolDeactivated() {}
}
