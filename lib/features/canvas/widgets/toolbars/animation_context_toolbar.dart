import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../models/local_page_model.dart';
import '../../services/transform_service.dart';
import '../../../explanations/widgets/simulation_studio_sheet.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/canvas_enums.dart';
import '../../models/animation_object_model.dart';
import '../../models/stroke_model.dart'; // 🚀 Rasterization
import '../../services/rasterization_service.dart'; // 🚀 Rasterization
import 'package:uuid/uuid.dart';

class AnimationContextToolbar extends ConsumerWidget {
  final LocalPage currentPage;

  const AnimationContextToolbar({super.key, required this.currentPage});

  void _handleMagicConversion(BuildContext context, WidgetRef ref) {
    final toolState = ref.read(canvasToolProvider);
    final selectedObjects = currentPage.objects
        .where((o) => toolState.selectedObjectIds.contains(o.id))
        .toList();

    if (selectedObjects.isEmpty) return;

    final targetBounds = TransformService.getCombinedBounds(selectedObjects);

    SimulationStudioSheet.show(
      context,
      canvasSize: Size(currentPage.pageWidthPx, currentPage.pageHeightPx),
      targetBounds: targetBounds,
      onConversion: (expModel) {
        final docNotifier = ref.read(canvasDocumentProvider.notifier);
        // Remove os originais
        docNotifier.deleteObjects(currentPage, selectedObjects.map((o) => o.id).toList());
        // Adiciona a nova simulação modelada
        docNotifier.addObject(currentPage, expModel.copyWith(zIndex: currentPage.objects.length));
        
        // Foca nela com a ferramenta de seleção
        ref.read(canvasToolProvider.notifier).switchTool(ToolMode.select);
        ref.read(canvasToolProvider.notifier).selectIds(objectIds: {expModel.id});
        ref.read(canvasToolProvider.notifier).setAnimationContextActive(false);
      },
    );
  }

  void _handleGhostingRotation(BuildContext context, WidgetRef ref) async {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasToolProvider);
    final docNotifier = ref.read(canvasDocumentProvider.notifier);

    toolNotifier.setAnimationContextActive(false);
    
    if (toolState.selectedObjectIds.isEmpty) return;

    final selectedObjects = currentPage.objects.where((o) => toolState.selectedObjectIds.contains(o.id)).toList();
    final strokes = selectedObjects.whereType<Stroke>().toList();
    
    String targetId = toolState.selectedObjectIds.first;

    // Se houver traços selecionados, converte-os numa imagem fixa para desempenho
    if (strokes.isNotEmpty) {
      final imgBlock = await RasterizationService.rasterizeStrokes(strokes, docNotifier.state.myUserId);
      if (imgBlock != null) {
        docNotifier.deleteObjects(currentPage, selectedObjects.map((o) => o.id).toList());
        docNotifier.addObject(currentPage, imgBlock);
        targetId = imgBlock.id;
      }
    }

    final anim = AnimationObject(
      id: const Uuid().v4(),
      animationType: AnimationObjectType.sequence,
      position: Offset.zero,
      configData: {
        'type': 'ghosting',
        'movement_type': 'rotation',
        'target_id': targetId,
        'speed': 1.0,
      },
    );
    docNotifier.addObject(currentPage, anim);
    
    toolNotifier.clearSelection();
    toolNotifier.switchTool(ToolMode.select);
  }

  void _handleGhostingPath(BuildContext context, WidgetRef ref) async {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final toolState = ref.read(canvasToolProvider);
    final docNotifier = ref.read(canvasDocumentProvider.notifier);

    toolNotifier.setAnimationContextActive(false);

    if (toolState.selectedObjectIds.isEmpty) return;

    final selectedObjects = currentPage.objects.where((o) => toolState.selectedObjectIds.contains(o.id)).toList();
    final strokes = selectedObjects.whereType<Stroke>().toList();
    
    // Se houver traços, planifica
    if (strokes.isNotEmpty) {
      final imgBlock = await RasterizationService.rasterizeStrokes(strokes, docNotifier.state.myUserId);
      if (imgBlock != null) {
        docNotifier.deleteObjects(currentPage, selectedObjects.map((o) => o.id).toList());
        docNotifier.addObject(currentPage, imgBlock);
        toolNotifier.selectIds(objectIds: {imgBlock.id});
      }
    }

    toolNotifier.setRecordingGhostPath(true);
  }

  void _handleClose(WidgetRef ref) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    toolNotifier.setAnimationContextActive(false);
    toolNotifier.clearSelection();
    toolNotifier.switchTool(ToolMode.draw);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolState = ref.watch(canvasToolProvider);
    if (!toolState.isAnimationContextActive || toolState.selectedObjectIds.isEmpty) {
      return const SizedBox.shrink();
    }

    final bool isRecording = toolState.isRecordingGhostPath;

    if (isRecording) {
      return _buildRecordingIndicator();
    }

    final existingGhost = currentPage.objects.whereType<AnimationObject>().where((a) => a.animationType == AnimationObjectType.sequence && a.configData?['target_id'] == toolState.selectedObjectIds.first).firstOrNull;

    if (existingGhost != null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: const Color(0xFF0F4C5C),
          borderRadius: BorderRadius.circular(32),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.animation_rounded, color: Colors.amberAccent, size: 20),
            const SizedBox(width: 8),
            const Text('Animação Ativa', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(width: 12),
            Container(width: 1, height: 24, color: Colors.white24),
            const SizedBox(width: 12),
            _buildContextButton(
              icon: existingGhost.autoPlay ? Icons.pause_rounded : Icons.play_arrow_rounded,
              label: existingGhost.autoPlay ? 'Pausar' : 'Reproduzir',
              onTap: () {
                final updatedGhost = existingGhost.copyWith(autoPlay: !existingGhost.autoPlay);
                ref.read(canvasDocumentProvider.notifier).updateObject(currentPage, updatedGhost);
              },
              color: Colors.greenAccent,
            ),
            const SizedBox(width: 8),
            Container(width: 1, height: 24, color: Colors.white24),
            const SizedBox(width: 8),
            _buildContextButton(
              icon: Icons.delete_sweep_rounded,
              label: 'Remover',
              onTap: () {
                ref.read(canvasDocumentProvider.notifier).deleteObjects(currentPage, [existingGhost.id]);
                _handleClose(ref);
              },
              color: Colors.redAccent,
            ),
            const SizedBox(width: 4),
            IconButton(
              icon: const Icon(Icons.close_rounded, color: Colors.white),
              onPressed: () => _handleClose(ref),
              iconSize: 20,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C5C),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildContextButton(
            icon: Icons.auto_awesome_rounded,
            label: 'Magia',
            onTap: () => _handleMagicConversion(context, ref),
            color: Colors.amberAccent,
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: Colors.white24),
          const SizedBox(width: 8),
          _buildContextButton(
            icon: Icons.route_rounded,
            label: 'Translação',
            onTap: () => _handleGhostingPath(context, ref),
            color: Colors.lightBlueAccent,
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: Colors.white24),
          const SizedBox(width: 8),
          _buildContextButton(
            icon: Icons.rotate_right_rounded,
            label: 'Rotação',
            onTap: () => _handleGhostingRotation(context, ref),
            color: Colors.greenAccent,
          ),
          const SizedBox(width: 8),
          Container(width: 1, height: 24, color: Colors.white24),
          const SizedBox(width: 4),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => _handleClose(ref),
            iconSize: 20,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  Widget _buildContextButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
    required Color color,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 6),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecordingIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.redAccent,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.red.withOpacity(0.3), blurRadius: 10, offset: const Offset(0, 4))
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: const [
          Icon(Icons.fiber_manual_record, color: Colors.white, size: 16),
          SizedBox(width: 8),
          Text(
            'A gravar caminho... Arraste o objeto.',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
