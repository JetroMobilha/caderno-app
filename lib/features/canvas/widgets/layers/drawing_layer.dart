import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/local_page_model.dart';
import '../../models/stroke_model.dart';
import '../../widgets/canvas_painter.dart';
import '../../../../core/network/realtime_service.dart';
import '../../services/collaboration_room_service.dart';

class DrawingLayer extends ConsumerWidget {
  final LocalPage page;
  final Size pageSize;

  const DrawingLayer({
    super.key,
    required this.page,
    required this.pageSize,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolState = ref.watch(canvasToolProvider);
    final docState = ref.watch(canvasDocumentProvider);
    final realtime = ref.read(realtimeServiceProvider);
    
    // Provisório: Obter o serviço de colaboração para os traços remotos
    // Numa fase posterior, isto pode ser um provider específico
    final collabService = ref.read(collaborationRoomServiceProvider);

    return IgnorePointer(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 1. Camada de Traços Estáticos (Persistidos)
          RepaintBoundary(
            child: CustomPaint(
              size: pageSize,
              painter: StaticNotebookPainter(
                strokes: page.strokes,
                lineType: page.lineType ?? 'ruled',
                lineSpacing: page.lineSpacing ?? 28.0,
                selectedStrokeIds: toolState.selectedStrokeIds,
                selectionRect: toolState.selectionRectStart != null && toolState.selectionRectEnd != null
                    ? Rect.fromPoints(toolState.selectionRectStart!, toolState.selectionRectEnd!)
                    : null,
                pageVersion: page.version,
                remoteMovingStrokeIds: collabService.remoteMovingStrokeIds,
                userColors: collabService.userColorsMap,
                isAuthorColorEnabled: collabService.isAuthorColorEnabled,
              ),
            ),
          ),
          
          // 2. Camada de Traços Remotos (Live - Alta Frequência)
          ValueListenableBuilder<Map<String, Stroke>>(
            valueListenable: collabService.remoteLiveStrokes,
            builder: (context, remoteMap, _) => CustomPaint(
              size: pageSize, 
              painter: RemoteLiveStrokesPainter(
                liveStrokes: remoteMap, 
                targetPageNumber: page.pageNumber,
                userColors: collabService.userColorsMap,
                isAuthorColorEnabled: collabService.isAuthorColorEnabled,
              )
            ),
          ),

          // 3. Camada do Meu Traço Ativo (Local - Alta Frequência)
          // Nota: O activePointsNotifier e activeDrawingPageNumber devem ser geridos
          // por um provider de Drawing ou preservados na Viewport para evitar rebuilds do Doc.
          // Por agora, usamos um ValueNotifier se disponível.
        ],
      ),
    );
  }
}
