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

    if (toolState.selectedObjectIds.isEmpty) return const SizedBox.shrink();

    final List<PageObject> selectedObjects = page.objects
        .where((o) => toolState.selectedObjectIds.contains(o.id))
        .toList();

    if (selectedObjects.isEmpty) return const SizedBox.shrink();

    final Rect baseBounds = TransformService.getCombinedBounds(selectedObjects);
    final bool isSingle = selectedObjects.length == 1;
    final PageObject? firstObj = isSingle ? selectedObjects.first : null;
    
    // 🚀 v10.29: Apenas Imagens, Formas e Tabelas podem ser redimensionadas
    final bool canResize = isSingle && (firstObj!.type == 'image' || firstObj!.type == 'shape' || firstObj!.type == 'table');

    // 🚀 v10.33: Identificar se estamos na ferramenta específica de Tabela
    final bool isTableTool = toolState.activeTool == ToolMode.table;

    final Offset position = baseBounds.topLeft + toolState.totalSelectionDelta;
    final double rotation = (isSingle ? firstObj!.rotation : 0.0) + toolState.liveRotation;
    final Size size = Size(
      baseBounds.width * toolState.liveScale.width,
      baseBounds.height * toolState.liveScale.height,
    );

    final bool isLocked = selectedObjects.any((o) => o.isLocked);
    final Color primaryColor = isLocked ? Colors.orange : const Color(0xFF1976D2); 

    final viewportState = ref.watch(canvasViewportProvider);
    final double currentScale = viewportState.currentPageClientId != null 
        ? ref.read(canvasViewportProvider.notifier).getControllerFor(viewportState.currentPageClientId!).value.getMaxScaleOnAxis()
        : 1.0;
    
    final double handleSize = 14.0 / currentScale;
    final double borderThickness = 1.5 / currentScale;

    return Positioned.fill(
      child: IgnorePointer(
        child: Stack(
          children: [
            Positioned(
              left: position.dx,
              top: position.dy,
              child: Transform.rotate(
                angle: rotation,
                alignment: Alignment.center,
                child: Container(
                  width: size.width,
                  height: size.height,
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
                      // 🚀 v10.33: Ocultar se a ferramenta ativa for Tabela ou se o Modo Estrutural estiver ativo
                      // 🚀 v10.34: Ocultar se o Modo de Corte estiver ativo
                      if (!isLocked && canResize && !toolState.isTableStructuralMode && !isTableTool && !toolState.isImageCropping) ...[
                        _buildHandle(HandleType.topLeft, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.topCenter, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.topRight, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.middleLeft, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.middleRight, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.bottomLeft, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.bottomCenter, primaryColor, handleSize, borderThickness),
                        _buildHandle(HandleType.bottomRight, primaryColor, handleSize, borderThickness),
                        _buildRotationKnob(primaryColor, handleSize, borderThickness, currentScale),
                      ],

                      // 2. Hastes Estruturais de Tabela (Apenas em Modo Estrutural)
                      if (!isLocked && isSingle && firstObj is TableObject && toolState.isTableStructuralMode)
                        ..._buildTableStructuralHandles(firstObj, primaryColor, currentScale, handleSize),

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

  Widget _buildRotationKnob(Color color, double size, double thickness, double scale) {
    return Positioned(
      top: -45 / scale,
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

  List<Widget> _buildTableStructuralHandles(TableObject table, Color color, double scale, double size) {
    final List<Widget> handles = [];
    final double finalHandleSize = size * 0.9;
    
    // 1. Hastes de Coluna (Superiores - Verticais)
    double currentX = 0;
    for (int i = 0; i < table.columnWidths.length - 1; i++) {
      currentX += table.columnWidths[i];
      handles.add(Positioned(
        left: currentX - (finalHandleSize * 0.5), 
        top: -35 / scale, 
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMiniHasteCircle(color, size, scale),
            Container(width: 2.0 / scale, height: 35 / scale, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ));
    }

    // 2. Hastes de Linha (Esquerdas - Horizontais)
    double currentY = 0;
    for (int i = 0; i < table.rowHeights.length - 1; i++) {
      currentY += table.rowHeights[i];
      handles.add(Positioned(
        top: currentY - (finalHandleSize * 0.5), 
        left: -35 / scale, 
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            _buildMiniHasteCircle(color, size, scale),
            Container(height: 2.0 / scale, width: 35 / scale, color: color.withValues(alpha: 0.5)),
          ],
        ),
      ));
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
}
