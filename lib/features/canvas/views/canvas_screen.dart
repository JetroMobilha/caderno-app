import 'dart:io';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/realtime_service.dart';
import '../controllers/canvas_controller.dart';
import '../models/local_page_model.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../widgets/share_notebook_sheet.dart';

class CanvasScreen extends ConsumerStatefulWidget {
  final int notebookId;
  final int? notebookSid;
  final String notebookTitle;
  final String lineType;
  final String paperSize;

  const CanvasScreen({
    super.key,
    required this.notebookId,
    required this.notebookSid,
    required this.notebookTitle,
    this.lineType = 'ruled',
    required this.paperSize,
  });

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

  final Map<String, Color> _colorPalette = {
    'Preto': const Color(0xFF1A1A24), 'Azul Clássico': const Color(0xFF1976D2),
    'Verde Floresta': const Color(0xFF27AE60), 'Vermelho': const Color(0xFFE74C3C),
    'Laranja': const Color(0xFFE67E22), 'Roxo': const Color(0xFF9B59B6),
  };

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(canvasProvider).initNotebook(
        widget.notebookId, widget.notebookSid, widget.lineType, widget.paperSize,
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

    controller.activeInlineTarget = InlineTarget.none;
    controller.activeTextBlock = null;
    _textFocusNode.unfocus();
    controller.triggerAutoSave(page);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(canvasProvider);

    if (controller.isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFD6D6D6),
        appBar: AppBar(backgroundColor: Colors.white, elevation: 1),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0F4C5C)),
              const SizedBox(height: 16),
              Text('A carregar folhas...', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final bool hasPages = controller.pages.isNotEmpty;
    final LocalPage? currentPage = hasPages ? controller.pages[controller.currentPageIndex] : null;
    final Size baseSize = _paperSizes[widget.paperSize] ?? const Size(595, 842);

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
            onPageChanged: (idx) => controller.setPageIndex(idx),
            itemBuilder: (context, index) {
              final page = controller.pages[index];
              final Size currentPageSize = page.isLandscape ? Size(baseSize.height, baseSize.width) : baseSize;

              final bool isDrawingBlocked = controller.currentTool == ToolMode.pan ||
                  controller.currentTool == ToolMode.text || controller.currentTool == ToolMode.imageEdit;
              final bool canTapCanvas = controller.currentTool == ToolMode.text || controller.currentTool == ToolMode.eraser;

              return InteractiveViewer.builder(
                scaleEnabled: controller.currentTool == ToolMode.pan,
                panEnabled: controller.currentTool == ToolMode.pan,
                maxScale: 6.0, minScale: 0.1,
                transformationController: controller.transformationController,
                boundaryMargin: const EdgeInsets.all(3000),
                builder: (context, viewport) {
                  return Center(
                    child: Container(
                      width: currentPageSize.width, height: currentPageSize.height,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFBF7),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: ClipRect(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [
                            // 1. CAMADA DE FUNDO E PAUTA
                            RepaintBoundary(
                              child: CustomPaint(
                                size: currentPageSize,
                                painter: StaticNotebookPainter(
                                  strokes: page.strokes,
                                  lineType: controller.liveLineType,
                                  selectedStrokeIds: controller.selectedStrokeIds,
                                  selectionRect: controller.selectionRectStart != null && controller.selectionRectEnd != null
                                      ? Rect.fromPoints(controller.selectionRectStart!, controller.selectionRectEnd!) : null,
                                ),
                              ),
                            ),

                            // 2. CAMADA DE IMAGENS
                            ...page.imageBlocks.map((img) {
                              final bool isImageMode = controller.currentTool == ToolMode.imageEdit;
                              return Positioned(
                                key: ValueKey('img_${img.id}'), left: img.position.dx, top: img.position.dy,
                                child: SizedBox(
                                  width: img.width + 24, height: img.height + 24,
                                  child: Stack(
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
                                      if (isImageMode) ...[
                                        Positioned(
                                          left: (img.width / 2) - 22, top: (img.height / 2) - 22, width: 44, height: 44,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onPanUpdate: (d) => setState(() => img.position += d.delta),
                                            onPanEnd: (_) => controller.triggerAutoSave(page),
                                            child: const CircleAvatar(backgroundColor: Color(0xFF0F4C5C), child: Icon(Icons.open_with, size: 20, color: Colors.white)),
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

                            // 3. DETEÇÃO DE GESTOS E TRAÇOS ATIVOS
                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: controller.currentTool == ToolMode.imageEdit || controller.currentTool == ToolMode.pan,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapUp: canTapCanvas ? (details) {
                                    if (controller.activeInlineTarget != InlineTarget.none) _finishEditingInline(page);
                                    if (controller.currentTool == ToolMode.text) {
                                      final newBlock = TextBlock(text: '', position: details.localPosition, textColorHex: controller.selectedColorHex);
                                      setState(() {
                                        page.textBlocks.add(newBlock);
                                        controller.activeInlineTarget = InlineTarget.block;
                                        controller.activeTextBlock = newBlock;
                                        _textController.text = '';
                                      });
                                      _textFocusNode.requestFocus();
                                    } else if (controller.currentTool == ToolMode.eraser) {
                                      controller.eraseAtPosition(details.localPosition, page);
                                    }
                                  } : null,
                                  onPanStart: !isDrawingBlocked ? (details) {
                                    if (controller.currentTool == ToolMode.draw) {
                                      controller.activePointsNotifier.value = [details.localPosition];
                                    } else if (controller.currentTool == ToolMode.eraser) {
                                      controller.eraseAtPosition(details.localPosition, page);
                                    }
                                  } : null,
                                  onPanUpdate: !isDrawingBlocked ? (details) {
                                    if (controller.currentTool == ToolMode.draw) {
                                      final list = controller.activePointsNotifier.value;
                                      if (list.isEmpty || (details.localPosition - list.last).distance > 1.5) {
                                        controller.activePointsNotifier.value = List.from(list)..add(details.localPosition);
                                      }
                                    } else if (controller.currentTool == ToolMode.eraser) {
                                      controller.eraseAtPosition(details.localPosition, page);
                                    }
                                  } : null,
                                  onPanEnd: !isDrawingBlocked ? (details) async {
                                    if (controller.currentTool == ToolMode.draw) {
                                      final newStroke = Stroke(
                                        id: const Uuid().v4(),
                                        color: controller.selectedColorHex,
                                        thickness: controller.selectedThickness,
                                        points: List.from(controller.activePointsNotifier.value),
                                      );
                                      setState(() => page.strokes.add(newStroke));
                                      controller.activePointsNotifier.value = [];
                                      await controller.triggerAutoSave(page);

                                      if (controller.isRealtimeActive && (controller.liveNotebookSid != null && controller.liveNotebookSid != 0)) {
                                        RealtimeService().broadcastStroke(
                                          notebookId: controller.liveNotebookSid!,
                                          strokeData: {
                                            'page_number': page.pageNumber,
                                            'strokes': [{
                                              'id': newStroke.id, 'color': newStroke.color, 'thickness': newStroke.thickness,
                                              'points': newStroke.points.map((pt) => {'x': pt.dx, 'y': pt.dy}).toList()
                                            }]
                                          },
                                        );
                                      }
                                    }
                                  } : null,
                                  child: RepaintBoundary(
                                    child: ValueListenableBuilder<List<Offset>>(
                                      valueListenable: controller.activePointsNotifier,
                                      builder: (context, activePoints, _) => CustomPaint(
                                        size: currentPageSize,
                                        painter: ActiveStrokePainter(currentPoints: activePoints, currentColor: controller.selectedColorHex, currentThickness: controller.selectedThickness),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // 4. CAMADA DE TEXTO E PAUTA FÍSICA
                            ...page.textBlocks.map((tb) {
                              final bool isEditing = tb == controller.activeTextBlock && controller.activeInlineTarget == InlineTarget.block;
                              final double physicalLineStep = controller.liveLineType == 'grid' ? 25.0 : 28.0;
                              final double exactLineMulti = physicalLineStep / tb.fontSize;

                              return Positioned(
                                left: tb.position.dx, top: tb.position.dy,
                                width: (currentPageSize.width - tb.position.dx - 20.0).clamp(60.0, currentPageSize.width),
                                child: GestureDetector(
                                  onPanUpdate: controller.currentTool == ToolMode.text && !isEditing ? (d) => setState(() => tb.position += d.delta) : null,
                                  onTap: controller.currentTool == ToolMode.text && !isEditing ? () {
                                    if (controller.activeInlineTarget != InlineTarget.none) _finishEditingInline(page);
                                    setState(() {
                                      controller.activeInlineTarget = InlineTarget.block;
                                      controller.activeTextBlock = tb;
                                      _textController.text = tb.text;
                                    });
                                    _textFocusNode.requestFocus();
                                  } : null,
                                  child: isEditing
                                      ? TextField(
                                    controller: _textController, focusNode: _textFocusNode, maxLines: null, autofocus: true,
                                    style: GoogleFonts.inter(fontSize: tb.fontSize, height: exactLineMulti, color: Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF')))),
                                    decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
                                    onChanged: (val) => tb.text = val,
                                  )
                                      : Text(tb.text, style: GoogleFonts.inter(fontSize: tb.fontSize, height: exactLineMulti, color: Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF'))))),
                                ),
                              );
                            }),

                            // 5. CABEÇALHO E RODAPÉ DA FOLHA
                            Positioned(
                              top: 30, left: 40, right: 40,
                              child: Center(
                                child: controller.activeInlineTarget == InlineTarget.title
                                    ? TextField(
                                  controller: _textController, focusNode: _textFocusNode, autofocus: true, textAlign: TextAlign.center,
                                  style: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.bold),
                                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Título da Folha...', isDense: true),
                                  onSubmitted: (_) => _finishEditingInline(page),
                                )
                                    : GestureDetector(
                                  onTap: controller.currentTool == ToolMode.text ? () {
                                    if (controller.activeInlineTarget != InlineTarget.none) _finishEditingInline(page);
                                    setState(() {
                                      controller.activeInlineTarget = InlineTarget.title;
                                      _textController.text = page.title;
                                    });
                                    _textFocusNode.requestFocus();
                                  } : null,
                                  child: Text(page.title.isEmpty ? (controller.currentTool == ToolMode.text ? '[ Escrever Título ]' : '') : page.title, style: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.bold, color: page.title.isEmpty ? Colors.black26 : const Color(0xFF1A1A24))),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 30, left: 40, right: 40,
                              child: Center(
                                child: controller.activeInlineTarget == InlineTarget.footer
                                    ? TextField(
                                  controller: _textController, focusNode: _textFocusNode, autofocus: true, textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 12),
                                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Rodapé...', isDense: true),
                                  onSubmitted: (_) => _finishEditingInline(page),
                                )
                                    : GestureDetector(
                                  onTap: controller.currentTool == ToolMode.text ? () {
                                    if (controller.activeInlineTarget != InlineTarget.none) _finishEditingInline(page);
                                    setState(() {
                                      controller.activeInlineTarget = InlineTarget.footer;
                                      _textController.text = page.footer;
                                    });
                                    _textFocusNode.requestFocus();
                                  } : null,
                                  child: Text(page.footer.isEmpty ? (controller.currentTool == ToolMode.text ? '[ Escrever Rodapé ]' : '') : page.footer, style: GoogleFonts.inter(fontSize: 12, color: page.footer.isEmpty ? Colors.black26 : Colors.black54)),
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

          Positioned(bottom: 20, left: 0, right: 0, child: Center(child: _buildFloatingToolbar(controller, currentPage!))),
          if (controller.isInVoiceCall) Positioned(top: 16, left: 0, right: 0, child: Center(child: _buildLiveVoiceCockpit(controller))),
        ],
      ),
      floatingActionButton: hasPages ? null : FloatingActionButton(backgroundColor: const Color(0xFF0F4C5C), foregroundColor: Colors.white, onPressed: _showAddPageDialog, child: const Icon(Icons.note_add)),
    );
  }

  PreferredSizeWidget _buildAppBar(CanvasController controller, bool hasPages) {
    return AppBar(
      backgroundColor: Colors.white, elevation: 1, iconTheme: const IconThemeData(color: Color(0xFF1A1A24)),
      title: hasPages ? _buildAppBarDropdown(controller) : Text(widget.notebookTitle, style: GoogleFonts.lora(color: const Color(0xFF1A1A24), fontWeight: FontWeight.bold, fontSize: 16)),
      actions: [
        if (hasPages) ...[
          Center(
            child: Container(
              margin: const EdgeInsets.only(right: 8), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFF0F4F8), borderRadius: BorderRadius.circular(20)),
              child: Row(
                children: [
                  Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF27AE60), shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text('${controller.onlineUsers.length}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24))),
                ],
              ),
            ),
          ),
          IconButton(
            icon: Icon(controller.isInVoiceCall ? Icons.phone_in_talk : Icons.add_ic_call_outlined, color: controller.isInVoiceCall ? const Color(0xFF27AE60) : const Color(0xFF0F4C5C)),
            onPressed: () => setState(() => controller.isInVoiceCall = !controller.isInVoiceCall),
          ),
          IconButton(
            icon: const Icon(Icons.person_add_alt_1, color: Color(0xFF0F4C5C)),
            onPressed: () async {
              if ((controller.liveNotebookSid == null || controller.liveNotebookSid == 0) && !kIsWeb) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Este caderno ainda está a subir para a nuvem. Aguarda uns segundos! 📡'), backgroundColor: Color(0xFFE67E22)));
                return;
              }
              final int? convidados = await showModalBottomSheet<int>(
                context: context, isScrollControlled: true, backgroundColor: Colors.transparent,
                builder: (context) => ShareNotebookBottomSheet(notebook: Notebook(title: widget.notebookTitle, coverType: widget.lineType, lineType: widget.lineType, paperSize: widget.paperSize,id: widget.notebookId,serverId: widget.notebookSid),),
              );
              if (convidados != null && convidados > 0) {
                controller.initRealtimeCollaboration();
                setState(() => controller.isRealtimeActive = true);
              }
            },
          ),
        ]
      ],
    );
  }

  Widget _buildAppBarDropdown(CanvasController controller) {
    final double screenWidth = MediaQuery.of(context).size.width;
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        isExpanded: true, value: controller.currentPageIndex, icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1A1A24)),
        selectedItemBuilder: (context) => controller.pages.asMap().entries.map<Widget>((entry) {
          String label = '${widget.notebookTitle} — Folha ${entry.key + 1} de ${controller.pages.length}';
          if (screenWidth < 400) label = 'Folha ${entry.key + 1} de ${controller.pages.length}';
          else if (screenWidth < 600) label = '${widget.notebookTitle} • F. ${entry.key + 1}/${controller.pages.length}';
          return Container(alignment: Alignment.centerLeft, child: Text(label, style: GoogleFonts.lora(color: const Color(0xFF1A1A24), fontWeight: FontWeight.bold, fontSize: screenWidth < 400 ? 15.0 : 17.0), overflow: TextOverflow.ellipsis));
        }).toList()..add(const SizedBox.shrink()),
        items: [
          ...controller.pages.asMap().entries.map((entry) => DropdownMenuItem<int>(value: entry.key, child: Text('Ir para Folha ${entry.key + 1}'))),
          DropdownMenuItem<int>(value: controller.pages.length, child: const Row(children: [Icon(Icons.add, color: Color(0xFF0F4C5C)), SizedBox(width: 8), Text('Nova Folha')])),
        ],
        onChanged: (newIndex) {
          if (newIndex == controller.pages.length) _showAddPageDialog();
          else if (newIndex != null) controller.pageController.animateToPage(newIndex, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.insert_page_break_outlined, size: 80, color: Colors.black.withOpacity(0.1)), const SizedBox(height: 16), Text('Este caderno está vazio.\nClique no + para criar a primeira folha.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.black45, fontSize: 16))]));
  }

  Widget _buildFloatingToolbar(CanvasController controller, LocalPage currentPage) {
    if (controller.activeInlineTarget != InlineTarget.none) return _buildInlineEditingToolbar(controller, currentPage);

    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8))]),
      child: Wrap(
        spacing: 6, runSpacing: 4, crossAxisAlignment: WrapCrossAlignment.center, alignment: WrapAlignment.center,
        children: [
          _buildToolButton(Icons.brush, ToolMode.draw, 'Caneta', controller),
          if (!isSmallScreen || controller.currentTool == ToolMode.eraser) _buildToolButton(Icons.backspace_outlined, ToolMode.eraser, 'Borracha', controller),
          _buildToolButton(Icons.pan_tool, ToolMode.pan, 'Mover Folha', controller),
          _buildToolButton(Icons.text_fields, ToolMode.text, 'Texto', controller),
          if (!isSmallScreen) IconButton(icon: const Icon(Icons.add_photo_alternate_outlined), onPressed: () => controller.pickAndInsertImage(currentPage), tooltip: 'Adicionar Imagem'),
          if (currentPage.imageBlocks.isNotEmpty) _buildToolButton(Icons.transform, ToolMode.imageEdit, 'Editar Imagem', controller),
          if (!isSmallScreen) ...[
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            IconButton(icon: const Icon(Icons.grid_on, color: Color(0xFF0F4C5C)), onPressed: _showPaperStyleStudioDialog, tooltip: 'Mudar Pauta'),
            IconButton(icon: const Icon(Icons.zoom_out), onPressed: () => controller.zoom(0.8, MediaQuery.of(context).size), tooltip: 'Afastar'),
            IconButton(icon: const Icon(Icons.zoom_in), onPressed: () => controller.zoom(1.2, MediaQuery.of(context).size), tooltip: 'Aproximar'),
            IconButton(icon: const Icon(Icons.undo), onPressed: () => controller.undo(currentPage), tooltip: 'Desfazer'),
            IconButton(icon: const Icon(Icons.delete_forever, color: Colors.redAccent), onPressed: () => controller.deleteCurrentPage(context), tooltip: 'Rasgar Folha'),
          ],
          if (controller.currentTool == ToolMode.draw) ...[
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildColorButton(controller), _buildThicknessButton(controller),
          ],
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, ToolMode mode, String tooltip, CanvasController controller) {
    final bool isActive = controller.currentTool == mode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(color: isActive ? const Color(0xFF0F4C5C).withOpacity(0.15) : Colors.transparent, shape: BoxShape.circle),
      child: IconButton(icon: Icon(icon, color: isActive ? const Color(0xFF0F4C5C) : const Color(0xFF1A1A24)), onPressed: () => controller.switchTool(mode), tooltip: tooltip),
    );
  }

  Widget _buildInlineEditingToolbar(CanvasController controller, LocalPage currentPage) {
    if (controller.activeInlineTarget == InlineTarget.title || controller.activeInlineTarget == InlineTarget.footer) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8), decoration: BoxDecoration(color: const Color(0xFFFDFBF7), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFF0F4C5C).withOpacity(0.3))),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Text('A editar...', style: GoogleFonts.inter(fontStyle: FontStyle.italic)), const SizedBox(width: 12), ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C)), onPressed: () => _finishEditingInline(currentPage), child: const Text('Concluir', style: TextStyle(color: Colors.white)))]),
      );
    }
    final tb = controller.activeTextBlock!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: const Color(0xFFFDFBF7), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFF0F4C5C).withOpacity(0.3))),
      child: Wrap(crossAxisAlignment: WrapCrossAlignment.center, children: [
        IconButton(icon: Icon(Icons.format_bold, color: tb.isBold ? const Color(0xFF0F4C5C) : Colors.black45), onPressed: () => setState(() => tb.isBold = !tb.isBold)),
        IconButton(icon: Icon(Icons.format_italic, color: tb.isItalic ? const Color(0xFF0F4C5C) : Colors.black45), onPressed: () => setState(() => tb.isItalic = !tb.isItalic)),
        IconButton(icon: Icon(Icons.format_underlined, color: tb.isUnderline ? const Color(0xFF0F4C5C) : Colors.black45), onPressed: () => setState(() => tb.isUnderline = !tb.isUnderline)),
        ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C)), onPressed: () => _finishEditingInline(currentPage), child: const Text('OK', style: TextStyle(color: Colors.white))),
      ]),
    );
  }

  Widget _buildLiveVoiceCockpit(CanvasController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8), decoration: BoxDecoration(color: const Color(0xFF1A1A24), borderRadius: BorderRadius.circular(32)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.graphic_eq, color: Color(0xFF27AE60), size: 18), const SizedBox(width: 8),
        Text('Sala de Voz P2P', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
        Container(width: 1, height: 16, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 10)),
        ...controller.onlineUsers.map((s) => CircleAvatar(radius: 9, backgroundColor: s['color'], child: Text(s['name'][0].toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.white)))),
        const SizedBox(width: 6),
        IconButton(icon: Icon(controller.isMuted ? Icons.mic_off : Icons.mic, size: 14, color: Colors.white), onPressed: () => setState(() => controller.isMuted = !controller.isMuted)),
        IconButton(icon: Icon(controller.isSpeakerOn ? Icons.volume_up : Icons.headphones, size: 14, color: Colors.white), onPressed: () => setState(() => controller.isSpeakerOn = !controller.isSpeakerOn)),
        IconButton(icon: const Icon(Icons.call_end, size: 14, color: Colors.redAccent), onPressed: () => setState(() => controller.isInVoiceCall = false)),
      ]),
    );
  }

  Widget _buildColorButton(CanvasController controller) => InkWell(onTap: _showColorStudioDialog, child: CircleAvatar(radius: 11, backgroundColor: Color(int.parse(controller.selectedColorHex.replaceFirst('#', '0xFF')))));
  Widget _buildThicknessButton(CanvasController controller) => InkWell(onTap: _showThicknessStudioDialog, child: CircleAvatar(radius: 11, backgroundColor: Colors.black12, child: CircleAvatar(radius: (controller.selectedThickness / 1.5).clamp(2.0, 9.0), backgroundColor: const Color(0xFF1A1A24))));

  void _showAddPageDialog() {
    bool isLand = false;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Nova Folha', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            RadioListTile<bool>(title: const Text('Retrato (Vertical)'), value: false, groupValue: isLand, onChanged: (v) => setModalState(() => isLand = v!)),
            RadioListTile<bool>(title: const Text('Paisagem (Horizontal)'), value: true, groupValue: isLand, onChanged: (v) => setModalState(() => isLand = v!)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () { ref.read(canvasProvider).addNewPage(isLand); Navigator.pop(context); }, child: const Text('Adicionar')),
          ],
        ),
      ),
    );
  }

  void _showColorStudioDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cor da Caneta', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
        content: Wrap(spacing: 16, children: _colorPalette.entries.map((entry) {
          final hex = '#${entry.value.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
          return GestureDetector(onTap: () { setState(() => ref.read(canvasProvider).selectedColorHex = hex); Navigator.pop(context); }, child: CircleAvatar(radius: 16, backgroundColor: entry.value));
        }).toList()),
      ),
    );
  }

  void _showThicknessStudioDialog() {
    double temp = ref.read(canvasProvider).selectedThickness;
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          title: Text('Espessura: ${temp.toInt()}px', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
          content: Slider(value: temp, min: 1.0, max: 30.0, onChanged: (val) => setModalState(() => temp = val)),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(onPressed: () { setState(() => ref.read(canvasProvider).selectedThickness = temp); Navigator.pop(context); }, child: const Text('Aplicar')),
          ],
        ),
      ),
    );
  }

  void _showPaperStyleStudioDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Pauta do Papel', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          ListTile(title: const Text('Pautado'), onTap: () { ref.read(canvasProvider).setLineType('ruled'); Navigator.pop(context); }),
          ListTile(title: const Text('Quadriculado'), onTap: () { ref.read(canvasProvider).setLineType('grid'); Navigator.pop(context); }),
          ListTile(title: const Text('Liso'), onTap: () { ref.read(canvasProvider).setLineType('blank'); Navigator.pop(context); }),
        ]),
      ),
    );
  }
}

Path _buildSmoothPath(List<Offset> points) {
  final path = Path();
  if (points.isEmpty) return path;
  path.moveTo(points.first.dx, points.first.dy);
  if (points.length == 1) { path.addOval(Rect.fromCircle(center: points.first, radius: 0.5)); return path; }
  for (int i = 1; i < points.length; i++) { path.lineTo(points[i].dx, points[i].dy); }
  return path;
}

class StaticNotebookPainter extends CustomPainter {
  final List<Stroke> strokes; final String lineType; final Set<String> selectedStrokeIds; final Rect? selectionRect;
  StaticNotebookPainter({required this.strokes, required this.lineType, required this.selectedStrokeIds, required this.selectionRect});

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()..color = const Color(0xFF1B365D).withOpacity(0.18)..strokeWidth = 1.0;
    if (lineType == 'ruled') {
      canvas.drawLine(const Offset(60, 0), Offset(60, size.height), Paint()..color = Colors.redAccent.withOpacity(0.4)..strokeWidth = 1.5);
      for (double y = 90; y < size.height - 60; y += 28) { canvas.drawLine(Offset(60, y), Offset(size.width - 20, y), bgPaint); }
    } else if (lineType == 'grid') {
      for (double y = 90; y < size.height - 60; y += 25) { canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), bgPaint); }
      for (double x = 20; x < size.width - 20; x += 25) { canvas.drawLine(Offset(x, 90), Offset(x, size.height - 60), bgPaint); }
    }
    for (final stroke in strokes) {
      final paint = Paint()..color = Color(int.parse(stroke.color.replaceFirst('#', '0xFF')))..strokeWidth = stroke.thickness..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
      canvas.drawPath(_buildSmoothPath(stroke.points), paint);
    }
  }
  @override bool shouldRepaint(covariant StaticNotebookPainter old) => true;
}

class ActiveStrokePainter extends CustomPainter {
  final List<Offset> currentPoints; final String currentColor; final double currentThickness;
  ActiveStrokePainter({required this.currentPoints, required this.currentColor, required this.currentThickness});

  @override
  void paint(Canvas canvas, Size size) {
    if (currentPoints.isEmpty) return;
    final paint = Paint()..color = Color(int.parse(currentColor.replaceFirst('#', '0xFF')))..strokeWidth = currentThickness..style = PaintingStyle.stroke..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    canvas.drawPath(_buildSmoothPath(currentPoints), paint);
  }
  @override bool shouldRepaint(covariant ActiveStrokePainter old) => true;
}