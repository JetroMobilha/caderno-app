import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import '../models/local_page_model.dart';
import '../models/canvas_enums.dart';
import '../models/animation_object_model.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_document_provider.dart';
import 'canvas_tool.dart';

/// 🚀 v10.15: Ferramenta de Animação (Modificadora Contextual).
class AnimationTool extends CanvasTool {
  const AnimationTool() : super(ToolMode.video); 

  @override
  void onTapDown(Offset localPos, dynamic ref, LocalPage page) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasInteractionProvider);

    // Se estiver a gravar, ignora o toque solto
    if (toolState.isRecordingGhostPath) return;

    // Encontrar objeto
    final objects = page.objects.where((o) => !o.isDeleted).toList()..sort((a, b) => b.zIndex.compareTo(a.zIndex));
    dynamic hitObj;
    for (var obj in objects) {
      if (!obj.isVisible) continue;
      if (toolNotifier.checkHit(localPos, obj)) {
        hitObj = obj;
        break;
      }
    }

    if (hitObj != null) {
      toolNotifier.selectIds(objectIds: <String>{hitObj.id});
      toolNotifier.setAnimationContextActive(true);
    } else {
      toolNotifier.clearSelection();
      toolNotifier.setAnimationContextActive(false);
    }
  }

  @override
  void onPanStart(Offset localPos, dynamic ref, LocalPage page, {int? pointerId}) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasInteractionProvider);
    if (toolState.isRecordingGhostPath) {
      toolNotifier.addGhostPathPoint(localPos);
    }
  }

  @override
  void onPanUpdate(Offset localPos, Offset delta, dynamic ref, LocalPage page, {int? pointerId}) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasInteractionProvider);
    if (toolState.isRecordingGhostPath) {
      toolNotifier.addGhostPathPoint(localPos);
    }
  }

  @override
  void onPanEnd(dynamic ref, LocalPage page, {int? pointerId}) {
    final toolState = ref.read(canvasInteractionProvider);
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    if (toolState.isRecordingGhostPath) {
      if (toolState.ghostPathPoints.length > 2 && toolState.selectedObjectIds.isNotEmpty) {
        final targetId = toolState.selectedObjectIds.first;
        final anim = AnimationObject(
          id: const Uuid().v4(),
          animationType: AnimationObjectType.sequence,
          position: toolState.ghostPathPoints.first,
          configData: {
            'type': 'ghosting',
            'target_id': targetId,
            'path': toolState.ghostPathPoints.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
          },
        );
        ref.read(canvasDocumentProvider.notifier).addObject(page, anim);
      }
      
      toolNotifier.setRecordingGhostPath(false);
      toolNotifier.setAnimationContextActive(true); // volta para a toolbar contextual
    }
  }
}
