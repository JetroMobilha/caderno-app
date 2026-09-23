import 'dart:math' as math; // 🚀 v10.97
import 'package:caderno_digital_app/features/canvas/models/canvas_enums.dart';
import 'package:caderno_digital_app/features/canvas/models/image_block_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../providers/canvas_viewport_provider.dart';
import '../../models/local_page_model.dart';
import '../../models/page_object.dart';
import '../../models/table_model.dart';
import '../../services/transform_service.dart';

/// 🚀 v10.30: Camada Visual de Seleção Imersiva com Foco Exclusivo.
class CanvasSelectionOverlay extends ConsumerWidget {
  final LocalPage page;

  const CanvasSelectionOverlay({super.key, required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolState = ref.watch(canvasToolProvider);
    final viewportState = ref.watch(canvasViewportProvider);
    
    final double currentScale = viewportState.currentPageClientId != null 
        ? ref.read(canvasViewportProvider.notifier).getControllerFor(viewportState.currentPageClientId!).value.getMaxScaleOnAxis()
        : 1.0;

    // 🚀 Ocultar delimitador de seleção externa de tabela quando estiver editando no modo de tabela simples
    final bool isTableInSimpleEditMode = (toolState.activeTool == ToolMode.table && !toolState.isTableStructuralMode && !toolState.isTransformMode) 
        || toolState.interactionMode == CanvasInteractionStateMode.tableEditing;

    final List<PageObject> selectedObjects = page.objects
        .where((o) => toolState.selectedObjectIds.contains(o.id))
        .where((o) => !(isTableInSimpleEditMode && o is TableObject))
        .toList();

    if (selectedObjects.isEmpty && toolState.isTableStructuralMode) {
      final String? activeId = toolState.activeTableId;
      final firstTable = page.objects.whereType<TableObject>().where((t) => activeId == null || t.id == activeId).firstOrNull 
          ?? page.objects.whereType<TableObject>().firstOrNull;
      if (firstTable != null) {
        selectedObjects.add(firstTable);
      }
    }

    if (selectedObjects.isEmpty) return const SizedBox.shrink();

    final Rect baseBounds = TransformService.getCombinedBounds(selectedObjects);
    final bool isSingle = selectedObjects.length == 1;
    final PageObject? firstObj = isSingle ? selectedObjects.first : null;
    
    // 🚀 Qualquer tipo exceto desenho livre (stroke) pode ser redimensionado se no modo de transformação
    final bool canResize = isSingle && firstObj!.type != 'stroke' && toolState.isTransformMode;

    // 🚀 v10.33: Identificar se estamos na ferramenta específica de Tabela
    final bool isTableTool = toolState.activeTool == ToolMode.table;

    // 🚀 v10.97: Outset Visual - Pequena margem entre o objeto e a moldura azul
    final double visualOutset = 6.0 / currentScale;
    
    // 🚀 v10.97: Tamanho Mínimo Garantido (24x24 px no documento)
    final double minDim = 24.0;
    final double finalW = math.max(minDim, baseBounds.width * toolState.liveScale.width) + (visualOutset * 2);
    final double finalH = math.max(minDim, baseBounds.height * toolState.liveScale.height) + (visualOutset * 2);

    final Offset position = baseBounds.topLeft + toolState.totalSelectionDelta + toolState.livePositionDelta - Offset(visualOutset, visualOutset);
    final double rotation = (isSingle ? firstObj!.rotation : 0.0) + toolState.liveRotation;

    final bool isLocked = selectedObjects.any((o) => o.isLocked);
    
    // 🚀 v10.99: Detecção de Seleção de Grupo
    final bool isPureGroup = !isSingle && selectedObjects.every((o) => o.parentId != null && o.parentId == selectedObjects.first.parentId);
    
    final Color primaryColor = isLocked 
        ? Colors.orange 
        : (isPureGroup ? Colors.indigo : const Color(0xFF1976D2)); 
    
    final double handleSize = 14.0 / currentScale;
    final double borderThickness = 1.5 / currentScale;

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          clipBehavior: Clip.none, // 🚀 v10.86: Crucial para ver hastes externas
          children: [
            // 🚀 v10.99: Sub-contornos para seleção múltipla solta
            if (!isSingle && !isPureGroup)
              ...selectedObjects.map((obj) => _buildIndividualFrame(obj, toolState, currentScale)),

            Positioned(
              left: position.dx,
              top: position.dy,
              child: Transform.rotate(
                angle: rotation,
                alignment: Alignment.center,
                child: Container(
                  width: finalW,
                  height: finalH,
                  decoration: BoxDecoration(
                    border: Border.all(color: primaryColor, width: borderThickness),
                    color: primaryColor.withValues(alpha: 0.02),
                  ),
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      if (isLocked) 
                        Center(child: Icon(Icons.lock_outline_rounded, color: Colors.orange, size: 24 / currentScale)),
                        
                      // 1. Alças de Redimensionamento Padrão (Scale/Rotate)
                      // 🚀 v10.33: Ocultar se a ferramenta ativa for Tabela (e não estrutural) ou se o Modo Estrutural estiver ativo
                      // 🚀 v10.34: Ocultar se o Modo de Corte estiver ativo
                      if (!isLocked && canResize && !toolState.isTableStructuralMode && !(isTableTool && !toolState.isTableStructuralMode) && !toolState.isImageCropping) ...[
                        _buildHandle(HandleType.topLeft, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.topCenter, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.topRight, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.middleLeft, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.middleRight, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.bottomLeft, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.bottomCenter, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.bottomRight, primaryColor, handleSize, borderThickness),
                        _buildRotationKnob(primaryColor, handleSize, borderThickness, currentScale, visualOutset),
                      ],

                      // 2. Hastes Estruturais de Tabela (Apenas em Modo Estrutural)
                      if (!isLocked && isSingle && firstObj is TableObject && toolState.isTableStructuralMode)
                        ..._buildTableStructuralHandles(firstObj, primaryColor, currentScale, handleSize, visualOutset),

                      // 3. Alças de Corte de Imagem (Apenas em Modo de Corte)
                      if (!isLocked && isSingle && firstObj is ImageBlock && toolState.isImageCropping)
                        ..._buildCropHandles(primaryColor, handleSize, borderThickness, currentScale),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHandle(HandleType type, Color color, double size, double thickness) {
    Alignment alignment;
    switch (type) {
      case HandleType.topLeft: alignment = Alignment.topLeft; break;
      case HandleType.topCenter: alignment = Alignment.topCenter; break;
      case HandleType.topRight: alignment = Alignment.topRight; break;
      case HandleType.middleLeft: alignment = Alignment.centerLeft; break;
      case HandleType.middleRight: alignment = Alignment.centerRight; break;
      case HandleType.bottomLeft: alignment = Alignment.bottomLeft; break;
      case HandleType.bottomCenter: alignment = Alignment.bottomCenter; break;
      case HandleType.bottomRight: alignment = Alignment.bottomRight; break;
      default: alignment = Alignment.center;
    }

    final double finalSize = size * 1.1;

    return Align(
      alignment: alignment,
      child: Transform.translate(
        offset: Offset(alignment.x * (finalSize / 2), alignment.y * (finalSize / 2)),
        child: Container(
          width: finalSize, height: finalSize,
          decoration: BoxDecoration(
            color: color, 
            shape: BoxShape.circle,
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4)],
          ),
          child: Center(
            child: Container(
              width: finalSize * 0.35, height: finalSize * 0.35,
              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRotationKnob(Color color, double size, double thickness, double scale, double outset) {
    return Positioned(
      top: (-45 / scale) - outset,
      left: 0, right: 0,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: size * 1.5, height: size * 1.5,
            decoration: BoxDecoration(
              color: color, 
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 4 / scale)],
            ),
            child: Center(
              child: Container(
                width: size * 0.5, height: size * 0.5,
                decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                child: Center(child: Icon(Icons.sync_rounded, size: size * 0.4, color: color)),
              ),
            ),
          ),
          Container(width: thickness * 1.5, height: 20 / scale, color: color.withValues(alpha: 0.6)),
        ],
      ),
    );
  }

  List<Widget> _buildTableStructuralHandles(TableObject table, Color color, double scale, double size, double outset) {
    final List<Widget> handles = [];
    final double finalHandleSize = size * 0.9;
    
    // 1. Hastes de Coluna (Superiores - Verticais)
    double currentX = outset; // Começa após a margem lateral
    for (int i = 0; i <= table.columnWidths.length; i++) {
      handles.add(Positioned(
        left: currentX - (finalHandleSize * 0.5), 
        top: (-35 / scale) - outset, 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMiniHasteCircle(color, size, scale),
            Container(width: 2.0 / scale, height: (35 / scale) + outset, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ));
      if (i < table.columnWidths.length) {
        currentX += table.columnWidths[i];
      }
    }

    // 2. Hastes de Linha (Esquerdas - Horizontais)
    double currentY = outset;
    for (int i = 0; i <= table.rowHeights.length; i++) {
      handles.add(Positioned(
        top: currentY - (finalHandleSize * 0.5), 
        left: (-35 / scale) - outset, 
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildMiniHasteCircle(color, size, scale),
            Container(height: 2.0 / scale, width: (35 / scale) + outset, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ));
      if (i < table.rowHeights.length) {
        currentY += table.rowHeights[i];
      }
    }
    return handles;
  }

  List<Widget> _buildCropHandles(Color color, double size, double thickness, double scale) {
    return [
      _buildCropHandle(HandleType.cropTopLeft, Alignment.topLeft, size, thickness, scale),
      _buildCropHandle(HandleType.cropTopCenter, Alignment.topCenter, size, thickness, scale),
      _buildCropHandle(HandleType.cropTopRight, Alignment.topRight, size, thickness, scale),
      _buildCropHandle(HandleType.cropMiddleLeft, Alignment.centerLeft, size, thickness, scale),
      _buildCropHandle(HandleType.cropMiddleRight, Alignment.centerRight, size, thickness, scale),
      _buildCropHandle(HandleType.cropBottomLeft, Alignment.bottomLeft, size, thickness, scale),
      _buildCropHandle(HandleType.cropBottomCenter, Alignment.bottomCenter, size, thickness, scale),
      _buildCropHandle(HandleType.cropBottomRight, Alignment.bottomRight, size, thickness, scale),
    ];
  }

  Widget _buildCropHandle(HandleType type, Alignment alignment, double size, double thickness, double scale) {
    final bool isCorner = [HandleType.cropTopLeft, HandleType.cropTopRight, HandleType.cropBottomLeft, HandleType.cropBottomRight].contains(type);
    
    return Align(
      alignment: alignment,
      child: Container(
        width: isCorner ? 16 / scale : (alignment.x == 0 ? 30 / scale : 4 / scale),
        height: isCorner ? 16 / scale : (alignment.y == 0 ? 30 / scale : 4 / scale),
        decoration: BoxDecoration(
          color: Colors.white, 
          border: Border.all(color: Colors.black, width: 1.5 / scale),
          borderRadius: BorderRadius.circular(2),
          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 2 / scale)],
        ),
      ),
    );
  }

  Widget _buildMiniHasteCircle(Color color, double size, double scale) {
    final double finalSize = size * 0.8;
    return Container(
      width: finalSize, height: finalSize,
      decoration: BoxDecoration(
        color: color, shape: BoxShape.circle,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 3 / scale)],
      ),
      child: Center(
        child: Container(width: finalSize * 0.4, height: finalSize * 0.4, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
      ),
    );
  }

  Widget _buildIndividualFrame(PageObject obj, CanvasToolState toolState, double scale) {
    final Rect bounds = (obj.position & obj.size).shift(toolState.totalSelectionDelta);
    return Positioned(
      left: bounds.left,
      top: bounds.top,
      child: Transform.rotate(
        angle: obj.rotation,
        alignment: Alignment.center,
        child: Container(
          width: bounds.width,
          height: bounds.height,
          decoration: BoxDecoration(
            border: Border.all(color: const Color(0xFF1976D2).withValues(alpha: 0.3), width: 1.0 / scale),
          ),
        ),
      ),
    );
  }
}
