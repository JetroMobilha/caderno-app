import 'dart:async';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/local_page_model.dart';
import '../models/stroke_model.dart';
import '../models/canvas_enums.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/live_stroke_provider.dart'; // 🚀 v10.50
import 'canvas_tool.dart';

/* 🚀 v10.45: Orquestrador da ferramenta de Caneta/Pincel.

  Esta classe converte eventos brutos de "Pan" em ações de desenho estruturadas.
  Ela colabora com o [liveStrokeProvider] para feedback visual imediato e com o
 [canvasDocumentProvider] para a persistência final do traço.
*/
class BrushTool extends CanvasTool {
  static Timer? _broadcastThrottle;
  
  /// Flag de segurança para interromper traços que sofram saltos impossíveis de hardware.
  static bool _isCorrupted = false;
  
  /// Distância máxima (em pixels) permitida entre dois frames consecutivos.
  /// Se ultrapassada, o traço é considerado um "Ghost Touch" e interrompido.
  static const double _maxAllowedJump = 1200.0; 

  const BrushTool() : super(ToolMode.draw);

  @override
  void onTapDown(Offset localPos, dynamic ref, LocalPage page) {
    ref.read(canvasToolProvider.notifier).clearSelection();
  }

  /// Inicializa o processo de desenho.
  /// 1. Limpa seleções ativas.
  /// 2. Gera um UUID único para o novo traço.
  /// 3. Regista o ponto inicial no motor de latência zero.
  @override
  void onPanStart(Offset localPos, dynamic ref, LocalPage page) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasInteractionProvider);
    
    toolNotifier.clearSelection();
    _isCorrupted = false; 
    
    final String id = const Uuid().v4();
    
    ref.read(liveStrokeProvider).start(
      id: id,
      startPos: localPos,
      brushType: toolState.selectedBrushType,
      colorHex: toolState.selectedColorHex,
      thickness: toolState.selectedThickness,
      opacity: toolState.brushOpacity,
      isHighlighter: toolState.isHighlighter,
    );
  }

  /// Processa o movimento contínuo da caneta.
  /// 1. Valida a continuidade física do movimento (anti-salto).
  /// 2. Envia o ponto para o motor de renderização "live".
  /// 3. Dispara o broadcast em tempo real para colaboradores (com throttle).
  @override
  void onPanUpdate(Offset localPos, Offset delta, dynamic ref, LocalPage page) {
    final liveNotifier = ref.read(liveStrokeProvider);
    final toolState = ref.read(canvasInteractionProvider);
    
    if (liveNotifier.id == null || _isCorrupted) return;
    
    if (liveNotifier.points.isNotEmpty) {
      final double dist = (localPos - liveNotifier.points.last).distance;
      
      if (dist > _maxAllowedJump) {
        debugPrint('⚠️ [BrushTool] Salto anómalo detetado ($dist px). Traço corrompido.');
        _isCorrupted = true;
        return;
      }
    }
    
    liveNotifier.update(localPos);
    _throttledBroadcast(ref, page, liveNotifier.id!, liveNotifier.points, toolState);
  }

  /// Finaliza o traço e torna-o permanente.
  /// 1. Converte a lista mutável do LiveStroke numa lista imutável no StrokeModel.
  /// 2. Adiciona o traço ao documento oficial da página.
  /// 3. Limpa o motor live para o próximo movimento.
  @override
  void onPanEnd(dynamic ref, LocalPage page) {
    final liveNotifier = ref.read(liveStrokeProvider);
    
    if (liveNotifier.id != null && liveNotifier.points.isNotEmpty && !_isCorrupted) {
      ref.read(canvasDocumentProvider.notifier).addStroke(
        page, 
        Stroke(
          id: liveNotifier.id!,
          color: liveNotifier.colorHex,
          thickness: liveNotifier.thickness,
          points: List.from(liveNotifier.points), 
          isHighlighter: liveNotifier.isHighlighter,
          brushType: liveNotifier.brushType,
          opacity: liveNotifier.opacity,
        ),
      );
    }
    liveNotifier.clear();
  }

  void _throttledBroadcast(dynamic ref, LocalPage page, String id, List<Offset> points, CanvasToolState toolState) {
    if (_broadcastThrottle?.isActive ?? false) return;
    _broadcastThrottle = Timer(const Duration(milliseconds: 50), () {
      ref.read(canvasDocumentProvider.notifier).broadcastLiveStroke(
        pageClientId: page.clientId, pageNumber: page.pageNumber, strokeId: id,
        points: points, color: toolState.selectedColorHex, thickness: toolState.selectedThickness,
        isHighlighter: toolState.isHighlighter, brushType: toolState.selectedBrushType,
      );
    });
  }
}
