import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math_64.dart' as vector_math;

import '../../../core/network/realtime_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notebooks/models/notebook_model.dart';
import '../controllers/canvas_controller.dart';
import '../models/local_page_model.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../widgets/canvas_painter.dart';
import '../widgets/canvas_toolbar.dart';
import '../widgets/live_voice_cockpit.dart';
import '../widgets/share_notebook_sheet.dart'; // 🚀 Importado para a AppBar

class CanvasScreen extends ConsumerStatefulWidget {
  final Notebook notebook;

  const CanvasScreen({super.key, required this.notebook});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  final FocusNode _textFocusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();

  final Map<String, Size> _paperSizes = {
    'A5': const Size(420, 595), 'A4': const Size(595, 842),
    'A3': const Size(842, 1191), 'A2': const Size(1191, 1684),
    'A1': const Size(1684, 2384), 'A0': const Size(2384, 3370),
  };

  // 🎨 PALETA DE 24 CORES
  final Map<String, Color> _colorPalette = {
    'Preto': const Color(0xFF1A1A24), 'Cinzento Escuro': const Color(0xFF455A64),
    'Cinzento Claro': const Color(0xFF90A4AE), 'Branco': const Color(0xFFFFFFFF),
    'Azul Marinho': const Color(0xFF2C3E50), 'Azul Clássico': const Color(0xFF1976D2),
    'Azul Celeste': const Color(0xFF03A9F4), 'Ciano': const Color(0xFF00BCD4),
    'Verde Floresta': const Color(0xFF27AE60), 'Verde Esmeralda': const Color(0xFF2ECC71),
    'Verde Alface': const Color(0xFF8BC34A), 'Amarelo Lima': const Color(0xFFCDDC39),
    'Amarelo Sol': const Color(0xFFFFEB3B), 'Amarelo Torrado': const Color(0xFFFBC02D),
    'Laranja Claro': const Color(0xFFFF9800), 'Laranja Forte': const Color(0xFFE67E22),
    'Vermelho Vivo': const Color(0xFFE74C3C), 'Vermelho Sangue': const Color(0xFFB71C1C),
    'Rosa Choque': const Color(0xFFE91E63), 'Rosa Claro': const Color(0xFFF06292),
    'Roxo Escuro': const Color(0xFF8E44AD), 'Roxo Claro': const Color(0xFF9B59B6),
    'Castanho Claro': const Color(0xFF8D6E63), 'Castanho Escuro': const Color(0xFF5D4037),
  };

  String? _liveStrokeId;
  DateTime _lastBroadcastTime = DateTime.now();
  int _lastBroadcastedPointIndex = 0;
  String myUserId ="";

// Helper para arredondar pontos (Poupa extrema largura de banda no Reverb)
  Map<String, num> _pointToMap(Offset pt) => {
    'x': num.parse(pt.dx.toStringAsFixed(1)),
    'y': num.parse(pt.dy.toStringAsFixed(1)),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).currentUser;
      final String uid = user?.serverId?.toString() ?? user?.id?.toString() ?? "";
      
      ref.read(canvasProvider).initNotebook(
        widget.notebook.id ?? 0, widget.notebook.serverId,
        widget.notebook.lineType ?? 'ruled', widget.notebook.paperSize ?? 'A4', 
        widget.notebook.role, uid,
      );
    });
  }

  @override
  void dispose() {
    _textFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _finishEditingInline(LocalPage page) {
    final controller = ref.read(canvasProvider);
    if (controller.activeInlineTarget == InlineTarget.none) return;

    final String cleanText = _textController.text.trim();
    if (controller.activeInlineTarget == InlineTarget.block && controller.activeTextBlock != null) {
      controller.activeTextBlock!.text = cleanText;
      if (cleanText.isEmpty) page.textBlocks.remove(controller.activeTextBlock);
    } else if (controller.activeInlineTarget == InlineTarget.title) {
      page.title = cleanText;
    } else if (controller.activeInlineTarget == InlineTarget.footer) {
      page.footer = cleanText;
    }

    controller.setTextEditing(InlineTarget.none);
    _textFocusNode.unfocus();
    controller.triggerAutoSave(page);
  }

  void _confirmDeletePage(CanvasController controller, int index) {
    if (controller.pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por segurança, não podes rasgar a única folha do caderno!'), backgroundColor: Colors.redAccent));
      return;
    }
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF7),
        title: Text('Rasgar Folha ${index + 1}?', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text('Esta ação destruirá em definitivo todos os desenhos e textos contidos nesta página.', style: GoogleFonts.inter(fontSize: 14)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: Colors.black54))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              controller.deleteCurrentPage();
              Navigator.pop(ctx);
            },
            child: const Text('Rasgar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(canvasProvider);
    final user = ref.watch(authProvider).currentUser;
    
    // 🚀 UNIFICAÇÃO DE ID: Para colaboração, usamos EXCLUSIVAMENTE o serverId.
    // O ID local do SQLite não serve para identificar utilizadores em diferentes dispositivos.
    myUserId = user?.serverId?.toString() ?? "";

    // 💡 AUTO-CORREÇÃO: Se estivermos online mas o myUserId não estiver na lista, tentamos sincronizar pelo nome
    if (myUserId.isNotEmpty && controller.onlineUsers.isNotEmpty) {
      final String myName = user?.name ?? "";
      final meInList = controller.onlineUsers.where((u) => u['name'] == myName);
      if (meInList.isNotEmpty && meInList.first['id'] != myUserId) {
        final String officialId = meInList.first['id'];
        debugPrint('🆔 [Auto-Sinc] O meu ID real no servidor é $officialId (em vez de $myUserId)');
        myUserId = officialId;
      }
    }

    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0F4C5C))));
    }

    final bool hasPages = controller.pages.isNotEmpty;
    final LocalPage? currentPage = hasPages ? controller.pages[controller.currentPageIndex] : null;
    final Size baseSize = _paperSizes[widget.notebook.paperSize ?? 'A4'] ?? const Size(595, 842);

    return Scaffold(
      backgroundColor: const Color(0xFFD6D6D6),
      appBar: _buildAppBar(controller, hasPages),
      body: !hasPages
          ? _buildEmptyState()
          : Stack(
        children: [
          PageView.builder(
            controller: controller.pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: controller.pages.length,
            onPageChanged: (index) => controller.setPageIndex(index),
            itemBuilder: (context, index) {
              final page = controller.pages[index];
              final Size pSize = page.isLandscape ? Size(baseSize.height, baseSize.width) : baseSize;

              final bool isFollowing = controller.followingUserId != null;
              final bool isBlocked = (controller.currentTool == ToolMode.pan || widget.notebook.role == 'viewer') && !isFollowing;
              final bool canTapCanvas = controller.currentTool == ToolMode.text || controller.currentTool == ToolMode.eraser;

              return InteractiveViewer.builder(
                scaleEnabled: controller.currentTool == ToolMode.pan && !isFollowing,
                panEnabled: controller.currentTool == ToolMode.pan && !isFollowing,
                maxScale: 6.0, minScale: 0.1,
                transformationController: controller.transformationController,
                boundaryMargin: const EdgeInsets.all(3000),
                builder: (context, viewport) {
                  // 🔭 ATUALIZAÇÃO DO CENTRO DE VISÃO E LARGURA (Para quem está a transmitir)
                  // 🚀 CORREÇÃO DE SALTO: Só atualizamos pelo viewport se não estivermos a desenhar agora.
                  if (_liveStrokeId == null) {
                    final center = Offset(
                      (viewport.point0.x + viewport.point1.x + viewport.point2.x + viewport.point3.x) / 4,
                      (viewport.point0.y + viewport.point1.y + viewport.point2.y + viewport.point3.y) / 4,
                    );
                    controller.currentViewportCenter = center;
                  }
                  
                  controller.currentVisibleWidth = (viewport.point1.x - viewport.point0.x).abs();
                  controller.lastScreenSize = MediaQuery.of(context).size;

                  return Center(
                    child: Container(
                      width: pSize.width, height: pSize.height,
                      decoration: const BoxDecoration(color: Color(0xFFFDFBF7)),
                      child: ClipRect(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [

                            // 📜 Z-INDEX 1: LINHAS DE PAUTA DO PAPEL
                            RepaintBoundary(
                              child: CustomPaint(
                                size: pSize,
                                painter: StaticNotebookPainter(
                                    strokes: const [], lineType: controller.liveLineType,
                                    selectedStrokeIds: const {}, selectionRect: null
                                ),
                              ),
                            ),

                            // 🖼️ Z-INDEX 2: IMAGENS
                            ...page.imageBlocks.map((img) {
                              final bool isImageMode = controller.currentTool == ToolMode.imageEdit;
                              return Positioned(
                                key: ValueKey('img_${img.id}'), left: img.position.dx, top: img.position.dy,
                                child: SizedBox(
                                  width: img.width + 44, height: img.height + 44,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        left: 0, top: 0, width: img.width, height: img.height,
                                        child: Container(
                                          decoration: BoxDecoration(border: isImageMode ? Border.all(color: const Color(0xFF0F4C5C), width: 2.0) : null),
                                          child: kIsWeb
                                              ? Image.network(img.imagePath, fit: BoxFit.fill)
                                              : (img.imagePath.startsWith('http')
                                              ? CachedNetworkImage(imageUrl: img.imagePath, fit: BoxFit.fill)
                                              : Image.file(File(img.imagePath), fit: BoxFit.fill)),
                                        ),
                                      ),
                                      if (isImageMode && widget.notebook.role != 'viewer') ...[
                                        Positioned(
                                          left: (img.width / 2) - 22, top: (img.height / 2) - 22, width: 44, height: 44,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onPanUpdate: (d) {
                                              setState(() => img.position += d.delta);
                                              
                                              // 🚀 FOCO DINÂMICO PARA IMAGEM
                                              if (controller.isBroadcastingViewport) {
                                                controller.currentViewportCenter = img.position + Offset(img.width / 2, img.height / 2);
                                              }
                                              
                                              controller.broadcastImageBlockUpdate(page, img, myUserId);
                                            },
                                            onPanEnd: (_) => controller.triggerAutoSave(page),
                                            child: const CircleAvatar(backgroundColor: Color(0xFF0F4C5C), child: Icon(Icons.open_with, size: 20, color: Colors.white)),
                                          ),
                                        ),
                                        Positioned(
                                          left: img.width - 22, top: img.height - 22, width: 44, height: 44,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onPanUpdate: (d) {
                                              setState(() {
                                                img.width = (img.width + d.delta.dx).clamp(80.0, 900.0);
                                                img.height = (img.height + d.delta.dy).clamp(80.0, 900.0);
                                              });
                                              controller.broadcastImageBlockUpdate(page, img, myUserId);
                                            },
                                            onPanEnd: (_) => controller.triggerAutoSave(page),
                                            child: Container(width: 30, height: 30, decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle), child: const Icon(Icons.open_in_full, size: 14, color: Colors.white)),
                                          ),
                                        ),
                                        Positioned(
                                          left: img.width - 22, top: -22, width: 44, height: 44,
                                          child: GestureDetector(
                                            onTap: () => controller.deleteImageBlock(page, img),
                                            child: Container(width: 30, height: 30, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle), child: const Icon(Icons.close, size: 16, color: Colors.white)),
                                          ),
                                        ),
                                      ]
                                    ],
                                  ),
                                ),
                              );
                            }),

                            // 🖌️ Z-INDEX 3: TINTA E GESTOS
                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: controller.currentTool == ToolMode.imageEdit || controller.currentTool == ToolMode.pan,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapUp: canTapCanvas && widget.notebook.role != 'viewer' ? (details) {
                                    if (controller.activeInlineTarget != InlineTarget.none) _finishEditingInline(page);
                                    if (controller.currentTool == ToolMode.text) {
                                      final newBlock = TextBlock(text: '', position: details.localPosition, textColorHex: controller.selectedColorHex);
                                      page.textBlocks.add(newBlock);
                                      controller.setTextEditing(InlineTarget.block, newBlock);
                                      _textController.text = '';
                                      _textFocusNode.requestFocus();
                                    } else if (controller.currentTool == ToolMode.eraser) {
                                      controller.eraseAtPosition(details.localPosition, page);
                                    }
                                  } : null,
                                  onPanStart: !isBlocked ? (details) {
                                    final localPos = details.localPosition;
                                    if (controller.currentTool == ToolMode.draw) {
                                      _liveStrokeId = const Uuid().v4(); // ID único para o traço em curso
                                      _lastBroadcastedPointIndex = 0;
                                      _lastBroadcastTime = DateTime.now();
                                      controller.activePointsNotifier.value = [localPos];
                                    }else if (controller.currentTool == ToolMode.select) {
                                      bool hitSelected = false;
                                      for (var id in controller.selectedStrokeIds) {
                                        final matches = page.strokes.where((s) => s.id == id);
                                        if (matches.isNotEmpty && matches.first.points.any((pt) => (pt - localPos).distance < 25.0)) {
                                          hitSelected = true; break;
                                        }
                                      }
                                      for (var id in controller.selectedTextIds) {
                                        final matches = page.textBlocks.where((t) => t.id == id);
                                        if (matches.isNotEmpty && (matches.first.position - localPos).distance < 50.0) {
                                          hitSelected = true; break;
                                        }
                                      }

                                      if (hitSelected) {
                                        controller.isMovingStrokes = true;
                                        controller.lastPanOffset = localPos;
                                      } else {
                                        controller.isMovingStrokes = false;
                                        controller.selectionRectStart = localPos;
                                        controller.selectionRectEnd = localPos;
                                        controller.selectedStrokeIds.clear();
                                        controller.selectedTextIds.clear();
                                        controller.forceNotify();
                                      }
                                    } else if (controller.currentTool == ToolMode.eraser) {
                                      controller.eraseAtPosition(localPos, page);
                                    }
                                  } : null,
                                  onPanUpdate: !isBlocked ? (details) {
                                    final localPos = details.localPosition;
                                    
                                    // 🚀 FOCO DINÂMICO: Enquanto desenhamos, enviamos a ponta da caneta como foco.
                                    // O assistente usará isto para saber se deve mover a câmera.
                                    if (controller.isBroadcastingViewport) {
                                      controller.currentViewportCenter = localPos;
                                    }

                                    if (controller.currentTool == ToolMode.draw) {
                                      final list = controller.activePointsNotifier.value;
                                      if (list.isEmpty || (localPos - list.last).distance > 1.5) {
                                        final newList = List<Offset>.from(list)..add(localPos);
                                        controller.activePointsNotifier.value = newList;

                                        // 🚀 THROTTLING OTIMIZADO
                                        final now = DateTime.now();
                                        if (now.difference(_lastBroadcastTime).inMilliseconds > 20 && controller.isRealtimeActive && controller.liveNotebookSid != null && myUserId.isNotEmpty) {
                                          final newPoints = newList.sublist(_lastBroadcastedPointIndex);
                                          if (newPoints.isNotEmpty) {
                                            RealtimeService().broadcastStroke(
                                                notebookId: controller.liveNotebookSid!,
                                                strokeData: {
                                                  'sender_id': myUserId,
                                                  'page_number': page.pageNumber,
                                                  'strokes': [{
                                                    'id': _liveStrokeId,
                                                    'color': controller.selectedColorHex,
                                                    'thickness': num.parse(controller.selectedThickness.toStringAsFixed(1)),
                                                    'is_final': false,
                                                    'points': newPoints.map(_pointToMap).toList(),
                                                  }]
                                                }
                                            );
                                            _lastBroadcastedPointIndex = newList.length;
                                            _lastBroadcastTime = now;
                                          }
                                        }
                                      }
                                    } else if (controller.currentTool == ToolMode.select) {
                                      if (controller.isMovingStrokes && controller.lastPanOffset != null) {
                                        final delta = localPos - controller.lastPanOffset!;
                                        controller.moveSelectedStrokes(page, delta);
                                        controller.lastPanOffset = localPos;
                                      } else if (controller.selectionRectStart != null) {
                                        controller.updateSelectionRect(page, localPos);
                                      }
                                    } else if (controller.currentTool == ToolMode.eraser) {
                                      controller.eraseAtPosition(localPos, page);
                                    }
                                  } : null,
                                  onPanEnd: !isBlocked ? (details) async {
                                    if (controller.currentTool == ToolMode.draw) {
                                      final allPoints = controller.activePointsNotifier.value;
                                      if (allPoints.isNotEmpty && _liveStrokeId != null) {
                                        final newStroke = Stroke(
                                          id: _liveStrokeId,
                                          color: controller.selectedColorHex,
                                          thickness: controller.selectedThickness,
                                          points: List.from(allPoints),
                                        );

                                        page.strokes.add(newStroke);
                                        controller.activePointsNotifier.value = [];
                                        controller.forceNotify();
                                        await controller.triggerAutoSave(page);

                                        // 🚀 ENVIO FINAL ROBUSTO
                                        if (controller.isRealtimeActive && controller.liveNotebookSid != null && myUserId.isNotEmpty) {
                                          RealtimeService().broadcastStroke(
                                              notebookId: controller.liveNotebookSid!,
                                              strokeData: {
                                                'sender_id': myUserId,
                                                'page_number': page.pageNumber,
                                                'strokes': [{
                                                  'id': _liveStrokeId,
                                                  'color': controller.selectedColorHex,
                                                  'thickness': num.parse(controller.selectedThickness.toStringAsFixed(1)),
                                                  'is_final': true,
                                                  'points': allPoints.map(_pointToMap).toList(),
                                                }]
                                              }
                                          );
                                        }
                                        _liveStrokeId = null;
                                      }
                                    } else if (controller.currentTool == ToolMode.select) {
                                      controller.broadcastSelectionUpdate(page);
                                      controller.selectionRectStart = null;
                                      controller.selectionRectEnd = null;
                                      controller.isMovingStrokes = false;
                                      controller.forceNotify();
                                      controller.triggerAutoSave(page);
                                    }
                                  } : null,
                                  child: RepaintBoundary(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        // 1. A Folha Estática (Só se move quando um traço é concluído)
                                        CustomPaint(
                                          size: pSize,
                                          painter: StaticNotebookPainter(
                                            strokes: page.strokes, lineType: 'blank',
                                            selectedStrokeIds: controller.selectedStrokeIds,
                                            selectionRect: controller.selectionRectStart != null && controller.selectionRectEnd != null
                                                ? Rect.fromPoints(controller.selectionRectStart!, controller.selectionRectEnd!) : null,
                                          ),
                                        ),

                                        // 🚀 2. A VIA RÁPIDA DO OBSERVADOR
                                        ValueListenableBuilder<Map<String, Stroke>>(
                                          valueListenable: controller.remoteLiveStrokes,
                                          builder: (context, remoteMap, _) {
                                            // 🎯 FILTRAGEM CRÍTICA: Mostrar apenas traços desta página
                                            final filteredMap = Map<String, Stroke>.from(remoteMap)
                                              ..removeWhere((id, s) => s.pageNumber != null && s.pageNumber != page.pageNumber);
                                            
                                            return CustomPaint(
                                              size: pSize,
                                              painter: RemoteLiveStrokesPainter(liveStrokes: filteredMap)
                                            );
                                          },
                                        ),

                                        // 3. A Via Rápida do Próprio Autor (O teu dedo no ecrã)
                                        ValueListenableBuilder<List<Offset>>(
                                          valueListenable: controller.activePointsNotifier,
                                          builder: (context, points, _) => CustomPaint(
                                              size: pSize,
                                              painter: ActiveStrokePainter(currentPoints: points, currentColor: controller.selectedColorHex, currentThickness: controller.selectedThickness)
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 📝 Z-INDEX 4: CAMADA DE TEXTO
                            ...page.textBlocks.map((tb) {
                              final bool isEditing = tb == controller.activeTextBlock && controller.activeInlineTarget == InlineTarget.block;
                              final double exactLineMulti = (controller.liveLineType == 'grid' ? 25.0 : 28.0) / tb.fontSize;
                              final bool isTextSelected = controller.selectedTextIds.contains(tb.id);

                              return Positioned(
                                left: tb.position.dx, top: tb.position.dy,
                                width: (pSize.width - tb.position.dx - 20.0).clamp(60.0, pSize.width),
                                child: GestureDetector(
                                  onPanUpdate: controller.currentTool == ToolMode.text && !isEditing && widget.notebook.role != 'viewer' ? (d) {
                                    tb.position += d.delta;
                                    
                                    // 🚀 FOCO DINÂMICO PARA TEXTO
                                    if (controller.isBroadcastingViewport) {
                                      controller.currentViewportCenter = tb.position;
                                    }
                                    
                                    controller.forceNotify();
                                    controller.broadcastTextBlockUpdate(page, tb, myUserId);
                                  } : null,
                                  onTap: controller.currentTool == ToolMode.text && !isEditing && widget.notebook.role != 'viewer' ? () {
                                    if (controller.activeInlineTarget != InlineTarget.none) _finishEditingInline(page);
                                    controller.setTextEditing(InlineTarget.block, tb);
                                    _textController.text = tb.text;
                                    _textFocusNode.requestFocus();
                                  } : null,
                                  child: isEditing
                                      ? TextField(
                                    controller: _textController, focusNode: _textFocusNode, maxLines: null, autofocus: true,
                                    style: GoogleFonts.inter(
                                      fontSize: tb.fontSize, height: exactLineMulti,
                                      color: Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF'))),
                                      fontWeight: tb.isBold ? FontWeight.bold : FontWeight.normal,
                                      fontStyle: tb.isItalic ? FontStyle.italic : FontStyle.normal,
                                      decoration: tb.isUnderline ? TextDecoration.underline : TextDecoration.none,
                                    ),
                                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                    onChanged: (val) {
                                      tb.text = val;
                                      
                                      // 🚀 FOCO DINÂMICO PARA TEXTO EM EDIÇÃO
                                      if (controller.isBroadcastingViewport) {
                                        controller.currentViewportCenter = tb.position;
                                      }
                                      
                                      controller.forceNotify();
                                      controller.broadcastTextBlockUpdate(page, tb, myUserId);
                                    },
                                  )
                                      : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 1),
                                    decoration: BoxDecoration(
                                      border: isTextSelected
                                          ? Border.all(color: const Color(0xFF1976D2), width: 1.5)
                                          : (controller.currentTool == ToolMode.text ? Border.all(color: Colors.blueAccent.withOpacity(0.15)) : null),
                                      color: isTextSelected ? const Color(0x1F1976D2) : null,
                                    ),
                                    child: Text(tb.text, style: GoogleFonts.inter(
                                      fontSize: tb.fontSize, height: exactLineMulti,
                                      color: Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF'))),
                                      fontWeight: tb.isBold ? FontWeight.bold : FontWeight.normal,
                                      fontStyle: tb.isItalic ? FontStyle.italic : FontStyle.normal,
                                      decoration: tb.isUnderline ? TextDecoration.underline : TextDecoration.none,
                                    )),
                                  ),
                                ),
                              );
                            }),

                            // 🏷️ Z-INDEX 5: CABEÇALHOS META
                            Positioned(
                              top: 30, left: 40, right: 40,
                              child: Center(
                                child: controller.activeInlineTarget == InlineTarget.title
                                    ? TextField(
                                  controller: _textController, focusNode: _textFocusNode, autofocus: true, textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Título da Folha...', isDense: true),
                                  onSubmitted: (_) => _finishEditingInline(page),
                                )
                                    : GestureDetector(
                                  onTap: controller.currentTool == ToolMode.text && widget.notebook.role != 'viewer' ? () {
                                    if (controller.activeInlineTarget != InlineTarget.none) _finishEditingInline(page);
                                    controller.setTextEditing(InlineTarget.title);
                                    _textController.text = page.title;
                                    _textFocusNode.requestFocus();
                                  } : null,
                                  child: Text(page.title.isEmpty ? (controller.currentTool == ToolMode.text && widget.notebook.role != 'viewer' ? '[ Escrever Título ]' : '') : page.title, style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.bold, color: page.title.isEmpty ? Colors.black26 : const Color(0xFF1A1A24))),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          // ==========================================
          // 2. OVERLAYS DE INTERFACE BLINDADOS
          // ==========================================
          if (widget.notebook.role != 'viewer')
            Positioned(
              bottom: 20, left: 0, right: 0,
              child: Center(
                  child: controller.activeInlineTarget != InlineTarget.none
                      ? _buildInlineEditingToolbar(controller, currentPage!)
                      : CanvasToolbar(
                    controller: controller,
                    currentPage: currentPage!,
                    onColorTap: () => _showColorStudioDialog(controller, isForText: false),
                    onThicknessTap: () => _showThicknessStudioDialog(controller),
                    onChangePaperTap: () => _showPaperStyleStudioDialog(controller),
                    onDeletePageTap: () => _confirmDeletePage(controller, controller.currentPageIndex),
                  )
              ),
            ),

          if (controller.isInVoiceCall)
            Positioned(
                top: 16, left: 0, right: 0,
                child: Center(
                    child: LiveVoiceCockpit(
                      onlineUsers: controller.onlineUsers,
                      isMuted: controller.isMuted,
                      isSpeakerOn: controller.isSpeakerOn,
                      onMuteToggle: controller.toggleMute,
                      onSpeakerToggle: controller.toggleSpeaker,
                      onHangUp: () => controller.toggleVoiceCall(myUserId),
                    )
                )
            ),

          // 🔭 INDICADORES DE ESTADO (FOLLOW/BROADCAST)
          if (controller.followingUserId != null)
            Positioned(
              top: 80, left: 20,
              child: _buildStatusBadge(
                icon: Icons.visibility,
                label: 'A assistir colega...',
                color: Colors.green,
                onClose: () => controller.toggleFollowUser(null, myUserId),
              ),
            ),

          if (controller.isBroadcastingViewport)
            Positioned(
              top: 80, right: 20,
              child: _buildStatusBadge(
                icon: Icons.sensors,
                label: 'A transmitir a minha visão',
                color: Colors.redAccent,
                onClose: () => controller.stopViewportBroadcasting(),
              ),
            ),

          // ☁️ INDICADOR DE UPLOAD DE IMAGEM
          if (controller.isUploadingImage)
            Positioned.fill(
              child: Container(
                color: Colors.black.withOpacity(0.3),
                child: Center(
                  child: Card(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: Color(0xFF0F4C5C)),
                          const SizedBox(height: 16),
                          Text('A enviar imagem...', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                          Text('Isto poupa largura de banda para todos.', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: hasPages || widget.notebook.role == 'viewer'
          ? null
          : FloatingActionButton(
        backgroundColor: const Color(0xFF0F4C5C),
        foregroundColor: Colors.white,
        onPressed: () => _showAddPageDialog(controller),
        child: const Icon(Icons.note_add),
      ),
    );
  }

  Widget _buildStatusBadge({required IconData icon, required String label, required Color color, required VoidCallback onClose}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: onClose,
            child: const Icon(Icons.close, color: Colors.white, size: 14),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 🧰 CONSTRUTORES DE APPBAR E BOTÕES GLOBAIS
  // =========================================================================
  PreferredSizeWidget _buildAppBar(CanvasController controller, bool hasPages) {
    // Se o Role for nulo (caderno acabado de criar offline), assumimos que o criador é o Dono!
    final String safeRole = widget.notebook.role ?? 'owner';

    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: const IconThemeData(color: Color(0xFF1A1A24)),
      title: hasPages
          ? _buildAppBarDropdown(controller)
          : Text(widget.notebook.title, style: GoogleFonts.inter(color: const Color(0xFF1A1A24), fontWeight: FontWeight.bold, fontSize: 16)),

      // 🚀 AÇÕES MOVIDAS PARA FORA DAS RESTRIÇÕES, FICAM SEMPRE VISÍVEIS
      actions: [

        // 🔭 0. BOTÃO DE TRANSMITIR CÂMARA
        if (controller.followingUserId == null)
          IconButton(
            icon: Icon(controller.isBroadcastingViewport ? Icons.sensors : Icons.sensors_off),
            color: controller.isBroadcastingViewport ? Colors.redAccent : const Color(0xFF0F4C5C),
            tooltip: controller.isBroadcastingViewport ? 'Parar Transmissão' : 'Transmitir Visão',
            onPressed: () {
              if (controller.isBroadcastingViewport) {
                controller.stopViewportBroadcasting();
              } else {
                controller.startViewportBroadcasting(myUserId);
              }
            },
          ),

        // 👥 1. CONTADOR DE QUEM ESTÁ ONLINE
        if (controller.onlineUsers.isNotEmpty)
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFF27AE60).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF27AE60), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('${controller.onlineUsers.length} Online', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF27AE60))),
                ],
              ),
            ),
          ),

        // 🎙️ 2. BOTÃO DE CHAMADA DE VOZ (WebRTC)
        IconButton(
          icon: Icon(
              controller.isInVoiceCall ? Icons.phone_in_talk : Icons.add_ic_call_outlined,
              color: controller.isInVoiceCall ? const Color(0xFF27AE60) : const Color(0xFF0F4C5C)
          ),
          tooltip: controller.isInVoiceCall ? 'Chamada em curso' : 'Sala de Voz P2P',
          onPressed: () => controller.toggleVoiceCall(myUserId),
        ),

        // 🤝 3. BOTÃO DE PARTILHAR CADERNO
        if (safeRole == 'owner')
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF0F4C5C)),
            tooltip: 'Partilhar Caderno',
            onPressed: () async {
              if ((controller.liveNotebookSid == null || controller.liveNotebookSid == 0) && !kIsWeb) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este caderno ainda está a subir para a nuvem. Aguarda um momento! 📡'), backgroundColor: Color(0xFFE67E22)));
                return;
              }
              final int? convidadosCount = await showModalBottomSheet<int>(
                context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (context) => ShareNotebookBottomSheet(notebook: widget.notebook),
              );
              if (convidadosCount != null && convidadosCount > 0) {
                controller.initRealtimeCollaboration();
                setState(() => controller.isRealtimeActive = true);
              }
            },
          ),

        // 📡 4. BOTÃO DE RECONECTAR
        if (controller.liveNotebookSid != null && !controller.isRealtimeActive)
          IconButton(
            icon: const Icon(Icons.cloud_off, color: Colors.orange),
            tooltip: 'Entrar na Sala em Tempo Real',
            onPressed: () {
              if (myUserId.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro: Precisas de estar ligado à nuvem para colaborar. ☁️')));
                return;
              }
              controller.initRealtimeCollaboration();
              setState(() => controller.isRealtimeActive = true);
            },
          ),
      ],
    );
  }
  Widget _buildAppBarDropdown(CanvasController controller) {
    final double screenWidth = MediaQuery.of(context).size.width;
    
    // 🔍 Log para depurar o conflito de IDs
    debugPrint('🔍 [Dropdown] Renderizando menu. myUserId (Server): $myUserId');

    // 🛠️ Construção unificada para evitar erros de Assertion
    final List<DropdownMenuItem<int>> dropdownItems = [];
    final List<Widget> selectedWidgets = [];

    // 1. Páginas existentes
    for (int i = 0; i < controller.pages.length; i++) {
      String label = '${widget.notebook.title} — Folha ${i + 1} de ${controller.pages.length}';
      if (screenWidth < 400) {
        label = 'Folha ${i + 1} de ${controller.pages.length}';
      } else if (screenWidth < 600) {
        label = '${widget.notebook.title} • F. ${i + 1}/${controller.pages.length}';
      }

      dropdownItems.add(DropdownMenuItem<int>(
        value: i,
        child: Text('Ir para Folha ${i + 1}', style: GoogleFonts.inter()),
      ));

      selectedWidgets.add(Container(
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF1A1A24),
            fontWeight: FontWeight.bold,
            fontSize: screenWidth < 400 ? 15.0 : 17.0,
          ),
          overflow: TextOverflow.ellipsis,
        ),
      ));
    }

    // 2. Botão "Nova Folha"
    if (widget.notebook.role != 'viewer') {
      dropdownItems.add(DropdownMenuItem<int>(
        value: controller.pages.length,
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.add, color: Color(0xFF0F4C5C), size: 20),
            SizedBox(width: 8),
            Flexible(child: Text('Nova Folha', overflow: TextOverflow.ellipsis)),
          ],
        ),
      ));
      selectedWidgets.add(const SizedBox.shrink());
    }

    // 3. Secção de Colaboradores Online
    if (controller.onlineUsers.isNotEmpty) {
      // Divider
      dropdownItems.add(const DropdownMenuItem<int>(
        enabled: false,
        child: Divider(),
      ));
      selectedWidgets.add(const SizedBox.shrink());

      // Header
      dropdownItems.add(const DropdownMenuItem<int>(
        enabled: false,
        child: Text(
          'ASSISTIR EM DIRETO:',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey),
        ),
      ));
      selectedWidgets.add(const SizedBox.shrink());

      // Lista de Utilizadores
      for (var u in controller.onlineUsers) {
        final String uId = u['id'].toString();
        final bool isLive = controller.activeBroadcasters.contains(uId);
        
        if (uId == myUserId) continue;

        final bool isFollowing = controller.followingUserId == uId;
        
        // 🚀 Usamos um valor negativo único baseado no hash do ID para evitar conflitos no Dropdown
        final int uniqueValue = -100 - uId.hashCode.abs() % 10000;

        dropdownItems.add(DropdownMenuItem<int>(
          value: uniqueValue, 
          onTap: () => controller.toggleFollowUser(uId, myUserId),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 12,
                    backgroundColor: u['color'],
                    child: Text(u['name'][0], style: const TextStyle(fontSize: 10, color: Colors.white)),
                  ),
                  if (isLive)
                    Positioned(
                      right: -2, bottom: -2,
                      child: Container(
                        width: 8, height: 8,
                        decoration: BoxDecoration(color: Colors.red, shape: BoxShape.circle, border: Border.all(color: Colors.white, width: 1)),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  isLive ? '${u['name']} (AO VIVO 🔴)' : 'Assistir ${u['name']}',
                  style: TextStyle(
                    color: isLive ? Colors.redAccent : Colors.black87, 
                    fontWeight: isLive ? FontWeight.bold : FontWeight.normal,
                    fontSize: 13,
                  ),
                  overflow: TextOverflow.ellipsis
                )
              ),
              // 👁️ INDICADOR PARA O TRANSMISSOR: Alguém que te está a assistir
              if (controller.whoIsWatchingMe.contains(uId))
                const Padding(
                  padding: EdgeInsets.only(right: 6),
                  child: Tooltip(
                    message: 'Está a assistir-te',
                    child: Icon(Icons.remove_red_eye, color: Colors.blueAccent, size: 16),
                  ),
                ),
              if (isFollowing) const Icon(Icons.visibility, color: Colors.green, size: 16),
            ],
          ),
        ));
        selectedWidgets.add(const SizedBox.shrink());
      }
    }

    // 👥 4. Secção: A ASSISTIR-ME (Quem me está a seguir)
    if (controller.whoIsWatchingMe.isNotEmpty) {
      dropdownItems.add(const DropdownMenuItem<int>(enabled: false, child: Divider()));
      selectedWidgets.add(const SizedBox.shrink());

      dropdownItems.add(const DropdownMenuItem<int>(
        enabled: false,
        child: Text('A ASSISTIR-ME:', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.grey)),
      ));
      selectedWidgets.add(const SizedBox.shrink());

      for (var viewerId in controller.whoIsWatchingMe) {
        final viewer = controller.onlineUsers.firstWhere((u) => u['id'].toString() == viewerId, orElse: () => {});
        if (viewer.isEmpty) continue;

        dropdownItems.add(DropdownMenuItem<int>(
          enabled: false,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircleAvatar(
                radius: 10, backgroundColor: viewer['color'],
                child: Text(viewer['name'][0], style: const TextStyle(fontSize: 9, color: Colors.white)),
              ),
              const SizedBox(width: 8),
              Flexible(child: Text(viewer['name'], style: const TextStyle(fontSize: 12, color: Colors.black54), overflow: TextOverflow.ellipsis)),
              const SizedBox(width: 4),
              const Icon(Icons.person_outline, size: 14, color: Colors.grey),
            ],
          ),
        ));
        selectedWidgets.add(const SizedBox.shrink());
      }
    }

    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        isExpanded: true,
        value: controller.currentPageIndex,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1A1A24)),
        selectedItemBuilder: (_) => selectedWidgets,
        items: dropdownItems,
        onChanged: (newIndex) {
          if (newIndex == null || newIndex < 0) return; // 🚀 Aceita apenas índices positivos (páginas)
          if (newIndex == controller.pages.length) {
            _showAddPageDialog(controller);
          } else {
            controller.pageController.animateToPage(
              newIndex,
              duration: const Duration(milliseconds: 350),
              curve: Curves.easeInOut,
            );
          }
        },
      ),
    );
  }

  Widget _buildInlineEditingToolbar(CanvasController controller, LocalPage currentPage) {
    if (controller.activeInlineTarget == InlineTarget.title || controller.activeInlineTarget == InlineTarget.footer) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFFDFBF7), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFF0F4C5C).withOpacity(0.3))),
        child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('A editar texto...', style: GoogleFonts.inter(fontStyle: FontStyle.italic, color: Colors.black54)),
              const SizedBox(width: 12),
              ElevatedButton(
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C), shape: const StadiumBorder()),
                  onPressed: () => _finishEditingInline(currentPage),
                  child: const Text('Concluir', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold))
              )
            ]
        ),
      );
    }

    final tb = controller.activeTextBlock!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFFDFBF7), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFF0F4C5C).withOpacity(0.3))),
      child: Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 4,
          children: [
            IconButton(icon: Icon(Icons.format_bold, color: tb.isBold ? const Color(0xFF0F4C5C) : Colors.black45), onPressed: () { tb.isBold = !tb.isBold; controller.forceNotify(); }),
            IconButton(icon: Icon(Icons.format_italic, color: tb.isItalic ? const Color(0xFF0F4C5C) : Colors.black45), onPressed: () { tb.isItalic = !tb.isItalic; controller.forceNotify(); }),
            IconButton(icon: Icon(Icons.format_underlined, color: tb.isUnderline ? const Color(0xFF0F4C5C) : Colors.black45), onPressed: () { tb.isUnderline = !tb.isUnderline; controller.forceNotify(); }),
            Container(width: 1, height: 20, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),

            IconButton(icon: const Icon(Icons.text_decrease, color: Colors.black87), onPressed: () { tb.fontSize = (tb.fontSize - 2).clamp(10.0, 64.0); controller.forceNotify(); }),
            Text('${tb.fontSize.toInt()}', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold)),
            IconButton(icon: const Icon(Icons.text_increase, color: Colors.black87), onPressed: () { tb.fontSize = (tb.fontSize + 2).clamp(10.0, 64.0); controller.forceNotify(); }),
            Container(width: 1, height: 20, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),

            ...['#1A1A24', '#E74C3C', '#27AE60', '#1976D2'].map((hex) {
              final bool isSelected = tb.textColorHex == hex;
              return GestureDetector(
                onTap: () => controller.setTextColor(hex),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? const Color(0xFF0F4C5C) : Colors.transparent, width: 2)),
                  child: CircleAvatar(radius: 8, backgroundColor: Color(int.parse(hex.replaceFirst('#', '0xFF')))),
                ),
              );
            }),
            IconButton(
              icon: const Icon(Icons.palette_outlined, color: Color(0xFF0F4C5C)),
              onPressed: () => _showColorStudioDialog(controller, isForText: true),
            ),
            const SizedBox(width: 4),
            ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C), shape: const StadiumBorder()),
                onPressed: () => _finishEditingInline(currentPage),
                child: const Text('OK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))
            ),
          ]
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.insert_page_break_outlined, size: 80, color: Colors.black.withOpacity(0.1)), const SizedBox(height: 16), Text('Este caderno está vazio.\nClique no botão flutuante para criar a primeira folha.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.black45, fontSize: 16))]));
  }

  // =========================================================================
  // 🧰 MODAIS PREMIUM
  // =========================================================================
  void _showAddPageDialog(CanvasController controller) {
    bool isLand = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFFFDFBF7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Nova Folha', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Orientação do Papel:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black54)),
            const SizedBox(height: 8),
            RadioListTile<bool>(title: const Text('Retrato (Vertical)'), value: false, groupValue: isLand, activeColor: const Color(0xFF0F4C5C), onChanged: (v) => setModalState(() => isLand = v!)),
            RadioListTile<bool>(title: const Text('Paisagem (Horizontal)'), value: true, groupValue: isLand, activeColor: const Color(0xFF0F4C5C), onChanged: (v) => setModalState(() => isLand = v!)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.black54))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))), onPressed: () { controller.addNewPage(isLand); Navigator.pop(context); }, child: const Text('Adicionar Folha', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  void _showColorStudioDialog(CanvasController controller, {bool isForText = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isForText ? 'Cor do Texto' : 'Paleta da Caneta', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
        content: SizedBox(
          width: 320,
          child: Wrap(
            spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
            children: _colorPalette.entries.map((entry) {
              final hex = '#${entry.value.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              final bool isSelected = isForText ? controller.activeTextBlock?.textColorHex == hex : controller.selectedColorHex == hex;
              return GestureDetector(
                  onTap: () {
                    if (isForText) { controller.setTextColor(hex); } else { controller.setColor(hex); }
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? const Color(0xFF0F4C5C) : Colors.transparent, width: 2),
                      boxShadow: isSelected ? [BoxShadow(color: entry.value.withOpacity(0.4), blurRadius: 8, offset: const Offset(0, 2))] : null,
                    ),
                    child: CircleAvatar(radius: 16, backgroundColor: entry.value, child: isSelected ? Icon(Icons.check, size: 16, color: entry.value.computeLuminance() > 0.5 ? Colors.black : Colors.white) : null),
                  )
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showThicknessStudioDialog(CanvasController controller) {
    double tempThickness = controller.selectedThickness;
    final List<double> quickPresets = [1.0, 3.0, 5.0, 8.0, 14.0];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final Color currentColor = Color(int.parse(controller.selectedColorHex.replaceFirst('#', '0xFF')));
          return AlertDialog(
            insetPadding: const EdgeInsets.symmetric(horizontal: 40), backgroundColor: const Color(0xFFFDFBF7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Espessura do Traço', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18, color: const Color(0xFF0F4C5C))),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(width: 32, height: 32, alignment: Alignment.center, child: CircleAvatar(radius: (tempThickness / 1.5).clamp(1.5, 14.0), backgroundColor: currentColor)),
                    const SizedBox(width: 12),
                    SizedBox(width: 55, child: Text('${tempThickness.toInt()} px', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24)))),
                  ],
                ),
                const SizedBox(height: 12),
                SliderTheme(
                  data: SliderTheme.of(context).copyWith(trackHeight: 4.0, thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 8.0), overlayShape: const RoundSliderOverlayShape(overlayRadius: 16.0)),
                  child: Slider(value: tempThickness, min: 1.0, max: 30.0, activeColor: const Color(0xFF0F4C5C), inactiveColor: Colors.black12, onChanged: (val) => setModalState(() => tempThickness = val)),
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: quickPresets.map((preset) {
                    final bool isSelected = tempThickness == preset;
                    return InkWell(
                      onTap: () => setModalState(() => tempThickness = preset), borderRadius: BorderRadius.circular(8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150), width: 38, height: 34, alignment: Alignment.center,
                        decoration: BoxDecoration(color: isSelected ? const Color(0xFF0F4C5C) : Colors.black.withOpacity(0.04), borderRadius: BorderRadius.circular(8), border: Border.all(color: isSelected ? const Color(0xFF0F4C5C) : Colors.transparent)),
                        child: Text('${preset.toInt()}', style: GoogleFonts.inter(fontSize: 13, fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? Colors.white : const Color(0xFF1A1A24))),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.black45))),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
                onPressed: () { controller.setThickness(tempThickness); Navigator.pop(context); },
                child: const Text('Aplicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPaperStyleStudioDialog(CanvasController controller) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Pauta do Papel', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaperOption(controller, 'ruled', 'Pautado (28px)', Icons.view_headline), const SizedBox(height: 8),
            _buildPaperOption(controller, 'grid', 'Quadriculado (25px)', Icons.grid_4x4), const SizedBox(height: 8),
            _buildPaperOption(controller, 'blank', 'Liso / Em Branco', Icons.check_box_outline_blank),
          ],
        ),
      ),
    );
  }

  Widget _buildPaperOption(CanvasController controller, String type, String label, IconData icon) {
    final bool isSelected = controller.liveLineType == type;
    return InkWell(
      onTap: () { controller.setLineType(type); Navigator.pop(context); },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF0F4C5C).withOpacity(0.12) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? const Color(0xFF0F4C5C) : Colors.black12, width: 1.5)),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF0F4C5C) : Colors.black54), const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF1A1A24))), const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF0F4C5C), size: 18),
          ],
        ),
      ),
    );
  }
}