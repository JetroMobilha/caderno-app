import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/local_page_model.dart';
import '../models/stroke_model.dart';
import '../models/page_object.dart';
import '../models/image_block_model.dart';
import '../models/table_model.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_render_provider.dart'; // 🚀 NOVO
import '../providers/canvas_document_provider.dart';
import '../services/collaboration_room_service.dart';
import 'canvas_painter.dart';
import 'object_renderer.dart';

/// 🚀 v9.0: Widget de renderização pura da folha.
/// Agora é um "Pure Consumer" que recebe a lista de renderização pré-calculada.
class PageCanvas extends ConsumerWidget {
  final LocalPage page;
  final Size pageSize;
  final bool isReadOnly;

  const PageCanvas({
    super.key,
    required this.page,
    required this.pageSize,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!page.isContentLoaded && page.id != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        final docNotifier = ref.read(canvasDocumentProvider.notifier);
        final docState = ref.read(canvasDocumentProvider);
        final idx = docState.pages.indexWhere((p) => p.clientId == page.clientId);
        if (idx != -1) {
          docNotifier.ensurePageLoaded(idx);
        }
      });
    }

    final toolState = ref.watch(canvasToolProvider);
    final collabService = ref.read(collaborationRoomServiceProvider); // 🚀 Ler em vez de watch para evitar reconstruções no canvas
    final renderList = ref.watch(canvasRenderProvider(page.clientId)); // 🚀 v9.0

    final List<Widget> widgets = [];

    for (var item in renderList) {
      if (item is StrokesRenderItem) {
        widgets.add(
          ValueListenableBuilder(
            valueListenable: collabService.remoteObjectTransforms,
            builder: (context, transforms, _) {
              return RepaintBoundary(
                child: CustomPaint(
                  size: pageSize,
                  painter: StrokesPainter(
                    strokes: item.strokes,
                    selectedStrokeIds: toolState.selectedStrokeIds, 
                    selectionRect: null,
                    pageVersion: page.version,
                    remoteMovingStrokeIds: collabService.remoteMovingStrokeIds,
                    remoteObjectTransforms: transforms,
                    userColors: collabService.userColorsMap,
                    isAuthorColorEnabled: collabService.isAuthorColorEnabled,
                    selectionDelta: toolState.totalSelectionDelta,
                  ),
                ),
              );
            }
          ),
        );
      } else if (item is ObjectRenderItem) {
        final localOverride = toolState.liveObjectOverrides[item.object.id];
        final effectiveObject = localOverride ?? item.object;

        widgets.add(ValueListenableBuilder<Map<String, Map<String, dynamic>>>(
          valueListenable: collabService.remoteObjectTransforms,
          builder: (context, transforms, child) {
            final remoteTx = transforms[item.object.id];
            
            Offset? finalDelta = item.isSelected ? toolState.totalSelectionDelta : null;
            Offset? finalPosDelta = item.isSelected ? toolState.livePositionDelta : null;
            Size? finalScale = item.isSelected ? toolState.liveScale : null;
            double? finalRotation = item.isSelected ? toolState.liveRotation : null;
            PageObject renderObj = effectiveObject;

            if (!item.isSelected && remoteTx != null) {
              finalDelta = Offset(remoteTx['dx'] ?? 0.0, remoteTx['dy'] ?? 0.0);
              if (remoteTx['pdx'] != null || remoteTx['pdy'] != null) {
                finalPosDelta = Offset(remoteTx['pdx'] ?? 0.0, remoteTx['pdy'] ?? 0.0);
              }
              if (remoteTx['scale'] != null) finalScale = Size(remoteTx['scale'], remoteTx['scale']);
              if (remoteTx['rotation'] != null) finalRotation = remoteTx['rotation'];
              
              if (remoteTx['state'] != null) {
                final stateMap = Map<String, dynamic>.from(remoteTx['state']);
                if (renderObj is ImageBlock) renderObj = ImageBlock.fromJson(stateMap);
                else if (renderObj is TableObject) renderObj = TableObject.fromJson(stateMap);
                else if (renderObj is Stroke) renderObj = Stroke.fromJson(stateMap);
              }
            }

            return ObjectRenderer(
              object: renderObj,
              isReadOnly: isReadOnly,
              movementDelta: finalDelta,
              liveScale: finalScale,
              liveRotation: finalRotation,
              livePositionDelta: finalPosDelta,
            );
          },
        ));
      }
    }

    return Container(
      width: pageSize.width,
      height: pageSize.height,
      color: Colors.white,
      child: Stack(
        fit: StackFit.expand, 
        children: [
          // 📄 Fundo Imagem de PDF Importado se existir (Local ou Remoto)
          if (page.backgroundPdfPath != null && page.backgroundPdfPath!.isNotEmpty)
            Positioned.fill(
              child: page.backgroundPdfPath!.startsWith('http')
                  ? CachedNetworkImage(
                      imageUrl: page.backgroundPdfPath!,
                      fit: BoxFit.fill,
                      placeholder: (context, url) => const Center(
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        ),
                      ),
                      errorWidget: (context, url, error) => const SizedBox.shrink(),
                    )
                  : (File(page.backgroundPdfPath!).existsSync()
                      ? Image.file(
                          File(page.backgroundPdfPath!),
                          fit: BoxFit.fill,
                        )
                      : const SizedBox.shrink()),
            ),
          CustomPaint(
            size: pageSize,
            painter: BackgroundPainter(
              notebookConfig: page.toConfig, 
              bgConfig: page.backgroundConfig,
              lineType: page.lineType,
              lineSpacing: page.lineSpacing,
            ),
          ),
          ...widgets,
          // 🚀 Camada de Traços Remotos (Live - Alta Frequência)
          RepaintBoundary(
            child: ValueListenableBuilder<Map<String, Stroke>>(
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
          ),
          // 🚀 Camada de Ponteiros Remotos (Live - Cursos Flutuantes)
          RepaintBoundary(
            child: ValueListenableBuilder<Map<String, dynamic>>(
              valueListenable: collabService.remotePointers,
              builder: (context, pointersMap, _) => CustomPaint(
                size: pageSize,
                painter: RemotePointersPainter(
                  pointers: pointersMap,
                  onlineUsers: collabService.onlineUsers,
                  targetPageNumber: page.pageNumber,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
