import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import '../providers/collaboration_provider.dart';
import '../providers/audio_session_provider.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_viewport_provider.dart';
import '../providers/canvas_tool_provider.dart';
import '../models/canvas_enums.dart';
import '../widgets/canvas_app_bar.dart';
import '../widgets/canvas_page_drawer.dart';
import '../widgets/canvas_toolbar.dart';
import '../widgets/layers/drawing_layer.dart';
import '../widgets/layers/interaction_layer.dart';
import '../widgets/layers/text_layer.dart';
import '../widgets/layers/image_layer.dart';
import '../widgets/dialogs/color_studio_dialog.dart';
import '../widgets/dialogs/thickness_studio_dialog.dart';
import '../widgets/dialogs/paper_style_dialog.dart';
import '../widgets/collaboration_center_sheet.dart'; // 🚀 Adicionado
import 'package:caderno_digital_app/features/canvas/models/text_block_model.dart';
import '../../auth/controllers/auth_controller.dart';

class CanvasScreen extends ConsumerStatefulWidget {
  final Notebook notebook;

  const CanvasScreen({super.key, required this.notebook});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  final TextEditingController _textController = TextEditingController();
  final FocusNode _textFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).currentUser;
      
      // 🚀 Inicializar Notifier (Novo)
      ref.read(canvasDocumentProvider.notifier).initNotebook(
        widget.notebook.id ?? 0,
        widget.notebook.serverId,
        widget.notebook.role,
        user?.serverId?.toString(),
        templateType: widget.notebook.templateType,
      );

      // 🚀 Inicializar Serviços (Colaboração e Áudio)
      final collabService = ref.read(collaborationProvider);
      collabService.getPages = () => ref.read(canvasDocumentProvider).pages;
      collabService.getCurrentPageIndex = () => ref.read(canvasViewportProvider).currentPageIndex;
      collabService.getCurrentScale = () => ref.read(canvasViewportProvider.notifier).transformationController.value.getMaxScaleOnAxis();

      collabService.init(
        widget.notebook.serverId ?? 0,
        user?.serverId?.toString() ?? '',
        widget.notebook.role,
      );
      
      ref.read(audioSessionProvider).loadLessonRecordings(widget.notebook.id ?? 0);
    });
  }

  @override
  void dispose() {
    _textController.dispose();
    _textFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(canvasDocumentProvider);
    final viewportState = ref.watch(canvasViewportProvider);
    final viewportNotifier = ref.read(canvasViewportProvider.notifier);
    final toolState = ref.watch(canvasToolProvider);
    final toolNotifier = ref.read(canvasToolProvider.notifier);

    // 🚀 OTIMIZAÇÃO: Ouvir quando as páginas carregam para garantir que a primeira página tem conteúdo
    ref.listen<CanvasDocumentState>(canvasDocumentProvider, (previous, next) {
      if ((previous == null || previous.pages.isEmpty) && next.pages.isNotEmpty) {
        ref.read(canvasDocumentProvider.notifier).ensurePageLoaded(0);
      }
    });

    if (docState.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0F4C5C))));
    }

    final bool hasPages = docState.pages.isNotEmpty;
    final currentPage = hasPages ? docState.pages[viewportState.currentPageIndex] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFD6D6D6),
      appBar: viewportState.isFocusMode ? null : CanvasAppBar(
        notebook: widget.notebook,
        onCollaborationTap: () => showModalBottomSheet(
          context: context,
          isScrollControlled: true,
          backgroundColor: Colors.transparent,
          builder: (context) => CollaborationCenterSheet(notebook: widget.notebook),
        ),
      ),
      endDrawer: hasPages ? CanvasPageDrawer(
        notebook: widget.notebook,
        onAddPage: () => ref.read(canvasDocumentProvider.notifier).addNewPage(false),
      ) : null,
      body: !hasPages ? const Center(child: Text('Nenhuma página disponível')) : Stack(
        children: [
          PageView.builder(
            controller: viewportNotifier.pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: docState.pages.length,
            onPageChanged: (index) {
              viewportNotifier.setPageIndex(index);
              ref.read(canvasDocumentProvider.notifier).ensurePageLoaded(index);
            },
            itemBuilder: (context, index) {
              final page = docState.pages[index];
              
              return LayoutBuilder(
                builder: (context, constraints) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    viewportNotifier.updateViewport(
                      screenSize: Size(constraints.maxWidth, constraints.maxHeight),
                    );
                  });

                  return InteractiveViewer(
                    transformationController: viewportNotifier.transformationController,
                    boundaryMargin: const EdgeInsets.symmetric(horizontal: 500, vertical: 800),
                    minScale: 0.1,
                    maxScale: 6.0,
                    child: Center(
                      child: Container(
                        width: 595, height: 842, 
                        decoration: BoxDecoration(
                          color: const Color(0xFFFDFBF7),
                          boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10, offset: const Offset(0, 4))],
                        ),
                        child: ClipRect(
                          child: Stack(
                            children: [
                              ImageLayer(page: page),
                              InteractionLayer(
                              page: page,
                              isBlocked: page.isFrozen,
                              onFinishEditing: () => toolNotifier.clearTextEditing(),
                              onAddTextBlock: (pos) {
                                final newBlock = TextBlock(text: '', position: pos, textColorHex: toolState.selectedColorHex);
                                ref.read(canvasDocumentProvider.notifier).addTextBlock(page, newBlock);
                                toolNotifier.setTextEditing(InlineTarget.block, newBlock);
                                _textController.text = '';
                                _textFocusNode.requestFocus();
                              },
                            ),
                              TextLayer(
                                page: page,
                                textController: _textController,
                                textFocusNode: _textFocusNode,
                                onTitleTap: () {
                                  toolNotifier.setTextEditing(InlineTarget.title);
                                  _textController.text = page.title;
                                  _textFocusNode.requestFocus();
                                },
                                onTextBlockTap: (p, b) {
                                  toolNotifier.setTextEditing(InlineTarget.block, b);
                                  _textController.text = b.text;
                                  _textFocusNode.requestFocus();
                                },
                              ),
                              DrawingLayer(page: page, pageSize: const Size(595, 842)),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          if (!viewportState.isFocusMode)
            Positioned(
              bottom: 20, left: 0, right: 0,
              child: Center(
                child: CanvasToolbar(
                  currentPage: currentPage!,
                  onColorTap: () => showDialog(context: context, builder: (_) => const ColorStudioDialog()),
                  onThicknessTap: () => showDialog(context: context, builder: (_) => const ThicknessStudioDialog()),
                  onChangePaperTap: () => showDialog(context: context, builder: (_) => PaperStyleDialog(currentPage: currentPage)),
                  onDeletePageTap: () => ref.read(canvasDocumentProvider.notifier).deletePage(currentPage),
                  onAiAssistantTap: () {},
                  onAddImageTap: () => ref.read(canvasDocumentProvider.notifier).pickAndInsertImage(currentPage),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
