import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/local_page_model.dart';
import '../models/canvas_enums.dart';
import '../models/animation_object_model.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_document_provider.dart';
import 'canvas_tool.dart';

/// 🚀 v10.10: Ferramenta de Animação.
/// Gere a inserção de objetos animados (Física, Lottie).
class AnimationTool extends CanvasTool {
  const AnimationTool() : super(ToolMode.video); // Reutilizando ToolMode.video por agora ou ToolMode.animation se existisse

  @override
  void onTapDown(Offset localPos, dynamic ref, LocalPage page) {
    _insertDefaultAnimation(localPos, ref, page);
  }

  @override
  void onPanStart(Offset localPos, dynamic ref, LocalPage page, [double pressure = 0.5]) {}

  @override
  void onPanUpdate(Offset localPos, Offset delta, dynamic ref, LocalPage page, [double pressure = 0.5]) {}

  @override
  void onPanEnd(dynamic ref, LocalPage page) {}

  void _insertDefaultAnimation(Offset pos, dynamic ref, LocalPage page) {
    final anim = AnimationObject(
      id: const Uuid().v4(),
      animationType: AnimationObjectType.physics,
      position: pos,
      size: const Size(200, 200),
      configData: {
        'type': 'engineeringMechanism',
        'radius': 60.0,
        'angular_velocity': 1.5,
        'tooth_count': 12,
        'is_gear': true,
      },
    );
    ref.read(canvasDocumentProvider.notifier).addAnimation(page, anim);
    // Switch to select tool to allow immediate manipulation
    ref.read(canvasInteractionProvider.notifier).switchTool(ToolMode.select);
    ref.read(canvasInteractionProvider.notifier).selectIds(objectIds: {anim.id});
  }
}
