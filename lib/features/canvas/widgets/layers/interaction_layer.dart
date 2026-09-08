import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/table_model.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../providers/canvas_document_provider.dart';
import '../../providers/canvas_viewport_provider.dart';
import '../../models/local_page_model.dart';
import '../../models/stroke_model.dart';
import '../../models/canvas_enums.dart';
import '../../providers/canvas_ui_provider.dart';
import '../../widgets/canvas_painter.dart';
import '../../services/shape_recognizer_service.dart'; 
import '../../models/page_object.dart';
import '../../models/text_block_model.dart';
import '../../models/image_block_model.dart';
import '../../models/shape_model.dart';
import '../../models/audio_block_model.dart';
import '../../models/animation_object_model.dart';
import '../dialogs/paper_style_dialog.dart';
import '../dialogs/add_page_dialog.dart'; 
import '../dialogs/brush_style_sheet.dart'; 
import '../dialogs/brush_context_popup.dart'; // 🚀 v1.7
import '../../../../core/network/time_service.dart';
import '../dialogs/thickness_studio_dialog.dart';

/// Camada de interação principal do canvas.
/// Captura gestos (tap, pan, long press) e os traduz em ações de ferramenta,
/// como desenhar, selecionar objetos, apagar ou iniciar edições.
class InteractionLayer extends ConsumerStatefulWidget {
  final LocalPage page;
  final bool isBlocked;
  final VoidCallback onFinishEditing;
  final Function(Offset) onAddTextBlock;
  final VoidCallback onTitleTap; // 🚀 v4.3

  const InteractionLayer({
    super.key,
    required this.page,
    required this.isBlocked,
    required this.onFinishEditing,
    required this.onAddTextBlock,
    required this.onTitleTap,
  });

  @override
  ConsumerState<InteractionLayer> createState() => _InteractionLayerState();
}

class _InteractionLayerState extends ConsumerState<InteractionLayer> {
  String? _liveStrokeId;
  final ValueNotifier<List<Offset>> _activePoints = ValueNotifier([]);
  Timer? _broadcastThrottle;
  
  Timer? _dwellTimer;
  bool _isShapeDetected = false;
  List<Offset>? _originalBeforeShape;

  // 🚀 v2.1: Acumuladores para Borracha de Precisão (Undo/Redo)
  final List<String> _deletedIdsDuringErase = [];
  final List<Stroke> _addedStrokesDuringErase = [];

  @override
  void dispose() {
    _activePoints.dispose();
    _broadcastThrottle?.cancel();
    _dwellTimer?.cancel();
    super.dispose();
  }

  void _startDwellTimer() {
    _dwellTimer?.cancel();
    _dwellTimer = Timer(const Duration(milliseconds: 500), () {
      if (_activePoints.value.length > 10) {
        final recognized = ShapeRecognizerService.recognize(_activePoints.value);
        if (recognized.type != RecognizedShapeType.none) {
          _originalBeforeShape = List.from(_activePoints.value);
          _activePoints.value = recognized.points;
          _isShapeDetected = true;
        }
      }
    });
  }

  void _throttledBroadcast(String strokeId, List<Offset> points, CanvasToolState toolState) {
    if (_broadcastThrottle?.isActive ?? false) return;
    
    _broadcastThrottle = Timer(const Duration(milliseconds: 50), () {
      ref.read(canvasDocumentProvider.notifier).broadcastLiveStroke(
        pageClientId: widget.page.clientId,
        pageNumber: widget.page.pageNumber,
        strokeId: strokeId,
        points: points,
        color: toolState.selectedColorHex,
        thickness: toolState.selectedThickness,
        isHighlighter: toolState.isHighlighter,
        brushType: toolState.selectedBrushType, // 🚀 v1.2
        isSmoothed: toolState.isSmoothingEnabled, // 🚀 v1.2
      );
    });
  }

  HandleType _detectHandleHit(Offset localPos, CanvasToolState toolState) {
    final selectedIds = {
      ...toolState.selectedTextIds,
      ...toolState.selectedImageIds,
      ...toolState.selectedShapeIds,
      ...toolState.selectedAudioIds,
      ...toolState.selectedAnimationIds,
      ...toolState.selectedTableIds,
      ...toolState.selectedLinkIds,
      ...toolState.selectedAttachmentIds,
    };
    if (selectedIds.length != 1) return HandleType.none;

    // 🚀 v3.1: Procura segura para evitar "Bad state: No element"
    final objIdx = widget.page.objects.indexWhere((o) => selectedIds.contains(o.id));
    if (objIdx == -1) return HandleType.none;
    
    final obj = widget.page.objects[objIdx];

    // 🚀 v6.5: Se for uma tabela ou texto e o MODO de TRANSFORMAÇÃO estiver desligado, ignoramos alças
    final bool isLayoutObject = obj is TableObject || obj is TextBlock;
    if (isLayoutObject && !toolState.isTransformMode) return HandleType.none;

    final bounds = obj.position & obj.size;
    
    final center = bounds.center;
    final rotatedHitPoint = _rotatePoint(localPos, center, -obj.rotation);

    const double threshold = 35.0; // 🚀 Área de toque ultra-generosa

    // Alças de canto
    if ((rotatedHitPoint - bounds.topLeft).distance < threshold) return HandleType.topLeft;
    if ((rotatedHitPoint - bounds.topRight).distance < threshold) return HandleType.topRight;
    if ((rotatedHitPoint - bounds.bottomRight).distance < threshold) return HandleType.bottomRight;
    if ((rotatedHitPoint - bounds.bottomLeft).distance < threshold) return HandleType.bottomLeft;

    // Alças de centro
    if ((rotatedHitPoint - Offset(bounds.center.dx, bounds.top)).distance < threshold) return HandleType.topCenter;
    if ((rotatedHitPoint - Offset(bounds.right, bounds.center.dy)).distance < threshold) return HandleType.middleRight;
    if ((rotatedHitPoint - Offset(bounds.center.dx, bounds.bottom)).distance < threshold) return HandleType.bottomCenter;
    if ((rotatedHitPoint - Offset(bounds.left, bounds.center.dy)).distance < threshold) return HandleType.middleLeft;
    
    // 🚀 Alça de Rotação (Sincronizada com SelectionOverlay - 50px acima)
    final rotateHandlePos = Offset(bounds.center.dx, bounds.top - 50);
    if ((rotatedHitPoint - rotateHandlePos).distance < threshold) return HandleType.rotate;

    return HandleType.none;
  }

  void _performHandleTransform(Offset localPos, Offset delta, CanvasToolState toolState, CanvasToolNotifier toolNotifier) {
    final selectedIds = {
      ...toolState.selectedTextIds, 
      ...toolState.selectedImageIds, 
      ...toolState.selectedShapeIds,
      ...toolState.selectedAudioIds,
      ...toolState.selectedAnimationIds,
      ...toolState.selectedTableIds,
      ...toolState.selectedLinkIds,
      ...toolState.selectedAttachmentIds,
    };
    if (selectedIds.length != 1) return;

    final objIdx = widget.page.objects.indexWhere((o) => selectedIds.contains(o.id));
    if (objIdx == -1) return;
    
    final obj = widget.page.objects[objIdx];

    if (toolState.activeHandle == HandleType.rotate) {
      final center = (obj.position & obj.size).center;
      final double angle = math.atan2(localPos.dy - center.dy, localPos.dx - center.dx);
      
      // 🚀 v3: Calcular rotação relativa e atualizar estado global para fluidez
      final double newRotation = angle + (math.pi / 2) - obj.rotation;
      toolNotifier.updateLiveTransform(rotation: newRotation);
      return;
    }

    // 🚀 v3: Redimensionamento optimista (Escala)
    // Usamos a distância total desde o início para evitar acumulação de erros
    final totalDelta = localPos - toolState.initialPosition;
    
    if (toolState.activeHandle == HandleType.bottomRight) {
       final double scaleX = (toolState.initialSize.width + totalDelta.dx) / toolState.initialSize.width;
       final double scaleY = (toolState.initialSize.height + totalDelta.dy) / toolState.initialSize.height;
       
       toolNotifier.updateLiveTransform(scale: Size(
         scaleX.clamp(0.1, 10.0), 
         scaleY.clamp(0.1, 10.0)
       ));
    } else {
       // Outras alças mantêm a lógica per-frame por enquanto
       _applyResize(obj, toolState.activeHandle, delta);
       toolNotifier.selectIds(); 
    }
  }

  void _applyResize(PageObject obj, HandleType handle, Offset delta) {
    double newX = obj.position.dx;
    double newY = obj.position.dy;
    double newW = obj.size.width;
    double newH = obj.size.height;

    switch (handle) {
      case HandleType.bottomRight:
        newW += delta.dx;
        newH += delta.dy;
        break;
      case HandleType.bottomLeft:
        newX += delta.dx;
        newW -= delta.dx;
        newH += delta.dy;
        break;
      case HandleType.topLeft:
        newX += delta.dx;
        newY += delta.dy;
        newW -= delta.dx;
        newH -= delta.dy;
        break;
      case HandleType.topRight:
        newY += delta.dy;
        newW += delta.dx;
        newH -= delta.dy;
        break;
      case HandleType.middleRight:
        newW += delta.dx;
        break;
      case HandleType.middleLeft:
        newX += delta.dx;
        newW -= delta.dx;
        break;
      case HandleType.topCenter:
        newY += delta.dy;
        newH -= delta.dy;
        break;
      case HandleType.bottomCenter:
        newH += delta.dy;
        break;
      default: break;
    }

    if (newW < 20) newW = 20;
    if (newH < 20) newH = 20;

    obj.position = Offset(newX, newY);
    obj.size = Size(newW, newH);
  }

  Offset _rotatePoint(Offset point, Offset center, double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    return Offset(
      center.dx + dx * cosA - dy * sinA,
      center.dy + dx * sinA + dy * cosA,
    );
  }

  @override
  Widget build(BuildContext context) {
    final toolState = ref.watch(canvasToolProvider);
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final docNotifier = ref.read(canvasDocumentProvider.notifier);
    final viewportState = ref.watch(canvasViewportProvider); // 🚀 v7.4

    return Positioned.fill(
      child: IgnorePointer(
        ignoring: toolState.currentTool == ToolMode.pan || 
                  toolState.currentTool == ToolMode.imageEdit ||
                  viewportState.activePointerCount > 1, // 🚀 v7.4: Prioridade total ao Zoom/Pan
        child: Stack(
          children: [
            GestureDetector(
              behavior: HitTestBehavior.translucent, // 🚀 v4.2: Permitir toque em checklists por baixo
              onTapDown: !widget.isBlocked
                  ? (details) {
                      final bool wasEditing = toolState.activeInlineTarget != InlineTarget.none || 
                          toolState.activeTableCell != null;

                      // 🚀 v6.6: Bloqueio Total de Encerramento Automático
                      // A edição (Texto/Tabela) SÓ fecha quando o utilizador clica no botão "Voltar" ou "Check" da toolbar.
                      // Clicar no fundo da folha ou trocar de ferramenta (via toolbar) não deve encerrar a sessão de escrita.
                      // if (wasEditing) {
                      //    widget.onFinishEditing();
                      // }
                      
                      // 🚀 v6.6: Bloquear troca de seleção acidental em TransformMode
                      // Mas permitir trocar o objeto alvo se clicarmos noutro diretamente.
                      if (toolState.isTransformMode) {
                        final hit = _findHitObject(details.localPosition, toolNotifier);
                        if (hit != null) {
                           final isCurrent = toolState.selectedTableIds.contains(hit.id) || 
                                           toolState.selectedTextIds.contains(hit.id);
                           if (!isCurrent) {
                             toolNotifier.selectAt(details.localPosition, widget.page);
                           }
                           return; // Consumir o toque (não deixar ir para criação de blocos ou outros)
                        } else {
                           // Se clicou no vazio, não fazemos nada (protege o foco atual)
                           if (_detectHandleHit(details.localPosition, toolState) == HandleType.none) return;
                        }
                      }

                      // 🚀 v4.3: Detecção de Toque no Título
                      if (_isTitleHit(details.localPosition)) {
                        widget.onTitleTap();
                        return;
                      }
                      
                      // 🚀 v4.4: Lógica de Toque (Com suporte a objetos bloqueados nos modos Texto/Organizador)
                      final hitObj = _findHitObject(details.localPosition, toolNotifier, 
                          includeLocked: toolState.currentTool == ToolMode.organizer || toolState.currentTool == ToolMode.text);

                      // A. Interatividade de Checklist (Prioritária em qualquer modo)
                      if (hitObj is TextBlock && hitObj.listType == ListType.checklist) {
                        final bool toggled = _tryToggleChecklist(hitObj, details.localPosition);
                        if (toggled) {
                          ref.read(canvasDocumentProvider.notifier).updateObject(widget.page, hitObj);
                          return; // Consumir o toque se for checklist
                        }
                      }

                      // B. Seleção no modo Organizador/Select/Lasso
                      if (toolState.currentTool == ToolMode.select || 
                          toolState.currentTool == ToolMode.lasso ||
                          toolState.currentTool == ToolMode.organizer) {
                         
                         // 🚀 v4.4: Ignorar detecção de alças no modo Organizador
                         if (toolState.currentTool != ToolMode.organizer) {
                            if (_detectHandleHit(details.localPosition, toolState) != HandleType.none) return;
                         }

                         toolNotifier.selectAt(details.localPosition, widget.page, 
                            includeLocked: toolState.currentTool == ToolMode.organizer);
                      }
                      
                      // C. Borracha de Objeto
                      if (toolState.currentTool == ToolMode.eraser) {
                         _handleObjectEraser(details.localPosition, toolState, toolNotifier, docNotifier);
                      }

                      // D. Ferramenta de Texto (Editar ou Criar)
                      if (toolState.currentTool == ToolMode.text) {
                        // 🚀 v6.7: Bloquear se estivermos no Modo de Transformação
                        if (toolState.isTransformMode) return;

                        // 🚀 v5.4: Se clicar dentro da célula ativa, não faz nada (deixa o TextField lidar)
                        if (toolState.activeTableCell != null && hitObj is TableObject) {
                           final cell = _findCellAt(details.localPosition, hitObj);
                           if ('${hitObj.id}:$cell' == toolState.activeTableCell) return;
                        }

                        if (hitObj is TextBlock) {
                          debugPrint('📝 [TextTool] Editando bloco existente: ${hitObj.id}');
                          toolNotifier.setTextEditing(InlineTarget.block, hitObj);
                        } else if (hitObj is TableObject) {
                           // 🚀 v4.9: Se o usuário está no modo Texto e clica numa célula de tabela, ativa a edição de texto dela
                           final cell = _findCellAt(details.localPosition, hitObj);
                           if (cell != null) {
                             toolNotifier.setTableCellEditing(hitObj, cell);
                           }
                        } else if (!wasEditing) {
                          debugPrint('📝 [TextTool] Criando novo bloco...');
                          widget.onAddTextBlock(details.localPosition);
                        }
                      }

                      // 🚀 v4.7: Inserir Tabela via Toque ou Ativar Tabela Existente
                      if (toolState.currentTool == ToolMode.table) {
                        // 🚀 v5.4: Se clicar dentro da célula ativa, não faz nada
                        if (toolState.activeTableCell != null && hitObj is TableObject) {
                           final cell = _findCellAt(details.localPosition, hitObj);
                           if ('${hitObj.id}:$cell' == toolState.activeTableCell) return;
                        }

                        if (hitObj is TableObject) {
                          // Se já existe uma tabela, focamos nela e ativamos a edição de texto da célula imediatamente (v4.9)
                          toolNotifier.selectIds(tableIds: {hitObj.id});
                          final cell = _findCellAt(details.localPosition, hitObj);
                          if (cell != null) {
                            toolNotifier.setTableCellEditing(hitObj, cell);
                          }
                        } else if (!wasEditing) {
                          // Criar apenas se clicou no vazio e manifestou intenção (v4.9 - Desativado para evitar poluição, usar botão +)
                          // final table = TableObject(...);
                        }
                      }
                    }
                  : null,
              onLongPressStart: !widget.isBlocked 
                  ? (d) {
                      // 🚀 v1.6: Atalho de Espessura na Folha
                      if (toolState.currentTool == ToolMode.draw || toolState.currentTool == ToolMode.highlighter) {
                         _showThicknessMenu(context, d.localPosition);
                      }
                    }
                  : null,
              onPanStart: !widget.isBlocked
                  ? (d) {
                      ref.read(canvasUiProvider.notifier).setHudMode(true);
                      
                      // 1. Prioridade Máxima: Alças de Transformação
                      final bool isOrganizer = toolState.currentTool == ToolMode.organizer;
                      final hitHandle = isOrganizer ? HandleType.none : _detectHandleHit(d.localPosition, toolState);
                      
                      // 🚀 v7.1: Se estivermos no Modo de Transformação, qualquer toque num objeto deve permitir movimento imediato
                      if (toolState.isTransformMode && hitHandle == HandleType.none) {
                         final hit = _findHitObject(d.localPosition, toolNotifier, includeLocked: true);
                         if (hit != null) {
                            // Garantir que o objeto tocado está selecionado para o movimento
                            final isSelected = toolState.selectedTableIds.contains(hit.id) || 
                                             toolState.selectedTextIds.contains(hit.id);
                            if (!isSelected) {
                              toolNotifier.selectAt(d.localPosition, widget.page, includeLocked: true);
                            }
                            toolNotifier.setMovingSelection(true);
                            return;
                         }
                      }

                      if (hitHandle != HandleType.none) {
                        final selectedIds = {
                          ...toolState.selectedTextIds, 
                          ...toolState.selectedImageIds, 
                          ...toolState.selectedShapeIds,
                          ...toolState.selectedAudioIds,
                          ...toolState.selectedAnimationIds,
                          ...toolState.selectedTableIds,
                          ...toolState.selectedLinkIds,
                          ...toolState.selectedAttachmentIds,
                        };
                        // 🚀 v7.1: Procura robusta para evitar erro de firstWhere
                        final obj = widget.page.objects.cast<PageObject?>().firstWhere((o) => o != null && selectedIds.contains(o.id), orElse: () => null);
                        if (obj == null || obj.isLocked) return; 
                        toolNotifier.startHandleTransform(hitHandle, obj.position, obj.size, obj.rotation);
                        return;
                      }

                      // 2. Segunda Prioridade: Se clicou dentro de algo JÁ SELECIONADO, apenas move
                      // 🚀 v6.5: No modo de TRANSFORMAÇÃO, permitimos mover qualquer objeto selecionado (Tabela ou Texto)
                      final bool isSelectedTable = toolState.selectedTableIds.isNotEmpty;
                      final bool isSelectedText = toolState.selectedTextIds.isNotEmpty;
                      final bool shouldAllowMove = toolState.isTransformMode || (!isSelectedTable && !isSelectedText);

                      if (shouldAllowMove && toolNotifier.isPointInSelection(d.localPosition, widget.page)) {
                        // 🚀 v2.0: Se a ferramenta for Borracha e clicou na seleção -> APAGA TUDO
                        // 🚀 v2.0: Se a ferramenta for Borracha e clicou na seleção -> APAGA TUDO
                        if (toolState.currentTool == ToolMode.eraser) {
                          _handleObjectEraser(d.localPosition, toolState, toolNotifier, docNotifier);
                          return;
                        }

                        // 🚀 v4.4: No modo Organizador, permitimos mover objetos bloqueados
                        final bool hasLocked = _isAnySelectedLocked(toolState, widget.page);
                        if (hasLocked && !isOrganizer) return; 

                        toolNotifier.setMovingSelection(true); 
                        return;
                      }

                      // 🚀 v2.0: Borracha de Objeto Rápida (Pan Start)
                      if (toolState.currentTool == ToolMode.eraser) {
                        _handleObjectEraser(d.localPosition, toolState, toolNotifier, docNotifier);
                        return;
                      }

                      // 3. Ferramenta de Desenho
                      if (toolState.currentTool == ToolMode.draw) {
                        toolNotifier.clearSelection();
                        _liveStrokeId = const Uuid().v4();
                        _activePoints.value = [d.localPosition];
                      } 
                      // 4. Seleção (Retângulo)
                      else if (toolState.currentTool == ToolMode.select) {
                        toolNotifier.setSelectionRect(d.localPosition, d.localPosition, widget.page);
                      } 
                      // 5. Laço
                      else if (toolState.currentTool == ToolMode.lasso) { 
                        toolNotifier.clearSelection();
                        toolNotifier.setLassoPath([d.localPosition], widget.page);
                      } else if (toolState.currentTool == ToolMode.pixelEraser) {
                        // 🚀 v2.1: Iniciar sessão de apagamento
                        _deletedIdsDuringErase.clear();
                        _addedStrokesDuringErase.clear();
                      }
                      // 🚀 v4.4: Iniciar arraste direto no modo Organizador
                      else if (isOrganizer) {
                        final hit = _findHitObject(d.localPosition, toolNotifier, includeLocked: true);
                        if (hit != null) {
                          toolNotifier.selectAt(d.localPosition, widget.page, includeLocked: true);
                          toolNotifier.setMovingSelection(true);
                        }
                      }
                      // 🚀 v4.7: Iniciar seleção de intervalo no modo Tabela
                      else if ((toolState.currentTool == ToolMode.table || (toolState.currentTool == ToolMode.select && !toolState.isTransformMode)) && !toolState.isTransformMode) {
                        // 🚀 v6.9: Bloqueio total se estivermos a redimensionar/mover
                        final hit = _findHitObject(d.localPosition, toolNotifier);
                        if (hit is TableObject) {
                          final cell = _findCellAt(d.localPosition, hit);
                          if (cell != null) {
                            toolNotifier.updateTableSelectionRange(cell, hit);
                          }
                        }
                      }
                    }
                  : null,
              onPanUpdate: !widget.isBlocked
                  ? (d) {
                      if (toolState.activeHandle != HandleType.none) {
                        _performHandleTransform(d.localPosition, d.delta, toolState, toolNotifier);
                        return;
                      }

                      // 🚀 Prioridade: Movimentação de Seleção
                      if (toolState.isMovingSelection) {
                        toolNotifier.updateSelectionDelta(d.delta);
                        return;
                      }

                      if (toolState.currentTool == ToolMode.draw) {
                        _activePoints.value = [..._activePoints.value, d.localPosition];
                        _dwellTimer?.cancel();
                        _startDwellTimer(); 
                        if (_liveStrokeId != null) {
                          _throttledBroadcast(_liveStrokeId!, _activePoints.value, toolState);
                        }
                      } else if (toolState.currentTool == ToolMode.select) {
                        final bool hasSelection = toolState.selectedStrokeIds.isNotEmpty || 
                            toolState.selectedTextIds.isNotEmpty || 
                            toolState.selectedImageIds.isNotEmpty ||
                            toolState.selectedShapeIds.isNotEmpty ||
                            toolState.selectedTableIds.isNotEmpty ||
                            toolState.selectedLinkIds.isNotEmpty ||
                            toolState.selectedAttachmentIds.isNotEmpty;

                        if (hasSelection) {
                          toolNotifier.updateSelectionDelta(d.delta);
                        } else {
                          toolNotifier.setSelectionRect(toolState.selectionRectStart, d.localPosition, widget.page);
                        }
                      } else if (toolState.currentTool == ToolMode.lasso) { 
                        final newPath = <Offset>[...(toolState.lassoPath ?? []), d.localPosition];
                        toolNotifier.setLassoPath(newPath, widget.page);
                      } else if (toolState.currentTool == ToolMode.pixelEraser) {
                        docNotifier.pixelErase(
                          widget.page, 
                          d.localPosition, 
                          toolState.selectedThickness * 2,
                          deletedAccumulator: _deletedIdsDuringErase,
                          addedAccumulator: _addedStrokesDuringErase,
                        );
                      }
                      // 🚀 v4.7: Atualizar seleção de intervalo no modo Tabela
                      else if ((toolState.currentTool == ToolMode.table || (toolState.currentTool == ToolMode.select && !toolState.isTransformMode)) && 
                                toolState.selectedTableIds.isNotEmpty && !toolState.isTransformMode) {
                        final table = widget.page.objects.whereType<TableObject>().firstWhere((t) => toolState.selectedTableIds.contains(t.id));
                        final cell = _findCellAt(d.localPosition, table);
                        if (cell != null) {
                          toolNotifier.updateTableSelectionRange(cell, table);
                        }
                      }
                    }
                  : null,
              onPanEnd: !widget.isBlocked
                  ? (_) {
                      ref.read(canvasUiProvider.notifier).setHudMode(false);
                      if (toolState.activeHandle != HandleType.none) {
                         final selectedIds = {
                           ...toolState.selectedTextIds, 
                           ...toolState.selectedImageIds, 
                           ...toolState.selectedShapeIds,
                           ...toolState.selectedAudioIds,
                           ...toolState.selectedAnimationIds,
                           ...toolState.selectedTableIds,
                           ...toolState.selectedLinkIds,
                           ...toolState.selectedAttachmentIds,
                         };
                         if (selectedIds.length == 1) {
                           final obj = widget.page.objects.firstWhere((o) => selectedIds.contains(o.id));
                           
                           // 🚀 v3: Aplicar as transformações temporárias ao objeto real antes de gravar
                           if (toolState.liveRotation != 0) obj.rotation += toolState.liveRotation;
                           if (toolState.liveScale != const Size(1, 1)) {
                             obj.size = Size(obj.size.width * toolState.liveScale.width, obj.size.height * toolState.liveScale.height);
                           }

                           ref.read(canvasDocumentProvider.notifier).updateObject(widget.page, obj);
                         }
                         toolNotifier.endHandleTransform();
                         return;
                      }

                      _dwellTimer?.cancel();
                      if (toolState.currentTool == ToolMode.draw && _liveStrokeId != null) {
                        if (_activePoints.value.isNotEmpty) {
                          docNotifier.addStroke(
                            widget.page,
                            Stroke(
                              id: _liveStrokeId!,
                              color: toolState.selectedColorHex,
                              thickness: toolState.selectedThickness,
                              points: List.from(_activePoints.value),
                              isHighlighter: toolState.isHighlighter,
                              brushType: toolState.selectedBrushType,
                              isSmoothed: toolState.isSmoothingEnabled,
                            ),
                          );
                          docNotifier.broadcastLiveStroke(
                            pageClientId: widget.page.clientId,
                            pageNumber: widget.page.pageNumber,
                            strokeId: _liveStrokeId!,
                            points: _activePoints.value,
                            color: toolState.selectedColorHex,
                            thickness: toolState.selectedThickness,
                            isHighlighter: toolState.isHighlighter,
                            brushType: toolState.selectedBrushType,
                            isSmoothed: toolState.isSmoothingEnabled,
                            isFinal: true,
                          );
                        }
                        _activePoints.value = [];
                        _liveStrokeId = null;
                        _isShapeDetected = false;
                        _broadcastThrottle?.cancel();
                      } else if (toolState.currentTool == ToolMode.select || 
                                 toolState.currentTool == ToolMode.organizer ||
                                 toolState.isTransformMode) { // 🚀 v7.1: Salvar se estiver em modo de transformação
                        if (toolState.totalSelectionDelta != Offset.zero) {
                          docNotifier.moveSelection(
                            widget.page,
                            strokeIds: toolState.selectedStrokeIds.toList(),
                            textIds: toolState.selectedTextIds.toList(),
                            imageIds: toolState.selectedImageIds.toList(),
                            shapeIds: toolState.selectedShapeIds.toList(),
                            audioIds: toolState.selectedAudioIds.toList(),
                            animationIds: toolState.selectedAnimationIds.toList(),
                            tableIds: toolState.selectedTableIds.toList(),
                            linkIds: toolState.selectedLinkIds.toList(),
                            attachmentIds: toolState.selectedAttachmentIds.toList(),
                            delta: toolState.totalSelectionDelta,
                          );
                          toolNotifier.resetSelectionDelta();
                        }
                      } else if (toolState.currentTool == ToolMode.pixelEraser) {
                        // 🚀 v2.1: Finalizar e gravar sessão de apagamento para Undo/Redo
                        docNotifier.commitPixelErase(widget.page, _deletedIdsDuringErase, _addedStrokesDuringErase);
                        _deletedIdsDuringErase.clear();
                        _addedStrokesDuringErase.clear();
                      }
                    }
                  : null,
            ),
            RepaintBoundary(
              child: ValueListenableBuilder<List<Offset>>(
                valueListenable: _activePoints,
                builder: (context, points, _) {
                  if (points.isEmpty) return const SizedBox.shrink();
                  return CustomPaint(
                    size: Size.infinite,
                    painter: ActiveStrokePainter(
                      currentPoints: points,
                      visualColor: Color(int.parse(toolState.selectedColorHex.replaceFirst('#', '0xFF'))),
                      currentThickness: toolState.selectedThickness,
                      isHighlighter: toolState.isHighlighter,
                      brushType: toolState.selectedBrushType,
                      isSmoothed: toolState.isSmoothingEnabled,
                    ),
                  );
                }
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _isAnySelectedLocked(CanvasToolState toolState, LocalPage page) {
    final selectedIds = {
      ...toolState.selectedStrokeIds, ...toolState.selectedTextIds, ...toolState.selectedImageIds,
      ...toolState.selectedShapeIds, ...toolState.selectedAudioIds, ...toolState.selectedAnimationIds,
      ...toolState.selectedTableIds, ...toolState.selectedLinkIds, ...toolState.selectedAttachmentIds,
    };
    return page.objects.any((o) => selectedIds.contains(o.id) && o.isLocked);
  }

  // 🚀 v4.3: Alternar estado de checklist via cálculo de posição (Respeitando rotação)
  bool _tryToggleChecklist(TextBlock block, Offset localPos) {
    // 1. Converter ponto global para espaço local do objeto (lidando com rotação)
    final center = (block.position & block.size).center;
    final rotatedLocalPos = _rotatePoint(localPos, center, -block.rotation);
    
    final relPos = rotatedLocalPos - block.position;
    
    // 2. Apenas considerar toques na margem esquerda (onde estão os boxes)
    // Usamos uma margem de 45px para facilitar o toque no telemóvel
    if (relPos.dx < -10 || relPos.dx > 45) return false;
    
    final double lineHeight = block.fontSize * block.lineHeight;
    final int lineIdx = (relPos.dy / lineHeight).floor();
    
    final lines = block.text.split('\n');
    if (lineIdx >= 0 && lineIdx < lines.length) {
      final List<int> newIndices = List.from(block.checkedLineIndices);
      if (newIndices.contains(lineIdx)) {
        newIndices.remove(lineIdx);
      } else {
        newIndices.add(lineIdx);
      }
      block.checkedLineIndices = newIndices;
      debugPrint('✅ [Checklist] Linha $lineIdx alternada para ${newIndices.contains(lineIdx)}');
      return true;
    }
    return false;
  }

  // 🚀 v4.3: Área de hit do título (topo central)
  bool _isTitleHit(Offset localPos) {
    return localPos.dy > 20 && localPos.dy < 90 && 
           localPos.dx > (widget.page.pageWidthPx * 0.2) && 
           localPos.dx < (widget.page.pageWidthPx * 0.8);
  }

  void _showThicknessMenu(BuildContext context, Offset localPos) {
    // 🚀 v1.9: Converter posição local para global (ecrã) para posicionamento perfeito
    final RenderBox box = context.findRenderObject() as RenderBox;
    final Offset globalPos = box.localToGlobal(localPos);

    showDialog(
      context: context,
      barrierColor: Colors.transparent,
      builder: (ctx) => BrushContextPopup(position: globalPos),
    );
  }

  PageObject? _findHitObject(Offset localPos, CanvasToolNotifier toolNotifier, {bool includeLocked = false}) {
    final objects = widget.page.objects.where((o) => !o.isDeleted).toList()
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));

    for (var obj in objects) {
      if (!includeLocked && obj.isLocked) continue;
      if (!obj.isVisible) continue;
      
      // 🚀 v4.5: Aumentar área de hit para blocos de texto (melhor ergonomia)
      bool hit = toolNotifier.checkHit(localPos, obj);
      if (!hit && obj is TextBlock) {
         final bounds = obj.position & obj.size;
         final hitBounds = Rect.fromCenter(center: bounds.center, width: bounds.width + 20, height: bounds.height + 20);
         hit = hitBounds.contains(localPos);
      }

      if (hit) return obj;
    }
    return null;
  }

  // 🚀 v4.7: Encontrar célula em uma posição local
  String? _findCellAt(Offset localPos, TableObject table) {
    final center = (table.position & table.size).center;
    final rotatedPos = _rotatePoint(localPos, center, -table.rotation);
    
    final relPos = rotatedPos - table.position;
    
    // 🚀 v5.9: Tolerância para toque Mobile (Aumentada para 25px para máxima sensibilidade)
    const double tol = 25.0;
    if (relPos.dx < -tol || relPos.dx > table.size.width + tol || 
        relPos.dy < -tol || relPos.dy > table.size.height + tol) return null;

    final double clampedX = relPos.dx.clamp(0.0, table.size.width - 0.1);
    final double clampedY = relPos.dy.clamp(0.0, table.size.height - 0.1);

    double currentW = 0;
    int col = -1;
    for (int i = 0; i < table.columnWidths.length; i++) {
      currentW += table.columnWidths[i];
      if (clampedX <= currentW) {
        col = i;
        break;
      }
    }

    double currentH = 0;
    int row = -1;
    for (int i = 0; i < table.rowHeights.length; i++) {
      currentH += table.rowHeights[i];
      if (clampedY <= currentH) {
        row = i;
        break;
      }
    }

    if (row != -1 && col != -1) {
      // 🚀 v7.2: Resolver a célula mestre caso esteja em um Span (União)
      return table.resolveMasterCell(row, col);
    }
    return null;
  }

  void _handleObjectEraser(Offset localPos, CanvasToolState toolState, CanvasToolNotifier toolNotifier, CanvasDocumentNotifier docNotifier) {
    // 1. Apagar Seleção em Massa
    if (toolNotifier.isPointInSelection(localPos, widget.page)) {
      final selectedIds = {
        ...toolState.selectedStrokeIds, ...toolState.selectedTextIds, ...toolState.selectedImageIds,
        ...toolState.selectedShapeIds, ...toolState.selectedAudioIds, ...toolState.selectedAnimationIds,
        ...toolState.selectedTableIds, ...toolState.selectedLinkIds, ...toolState.selectedAttachmentIds,
      };
      if (selectedIds.isNotEmpty) {
        docNotifier.deleteObjects(widget.page, selectedIds.toList());
        toolNotifier.clearSelection();
        return;
      }
    }

    // 2. Apagar objeto individual sob o toque
    final objects = widget.page.objects.where((o) => !o.isDeleted).toList()
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));

    for (var obj in objects) {
      if (obj.isLocked || !obj.isVisible) continue;
      if (toolNotifier.checkHit(localPos, obj)) {
        docNotifier.deleteObjects(widget.page, [obj.id]);
        return;
      }
    }
  }
}
