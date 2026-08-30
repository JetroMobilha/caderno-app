import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import '../providers/collaboration_provider.dart';
import '../providers/audio_session_provider.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_viewport_provider.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_ui_provider.dart'; // 🚀 NOVO
import '../models/canvas_enums.dart';
import '../widgets/canvas_app_bar.dart';
import '../widgets/canvas_page_drawer.dart';
import '../widgets/canvas_toolbar.dart';
import '../widgets/layers/drawing_layer.dart';
import '../widgets/layers/interaction_layer.dart';
import '../widgets/layers/text_layer.dart';
import '../widgets/layers/image_layer.dart';
import '../../explanations/widgets/explanation_layer.dart'; // 🚀 Novo
import '../widgets/dialogs/color_studio_dialog.dart';
import '../widgets/dialogs/thickness_studio_dialog.dart';
import '../widgets/dialogs/paper_style_dialog.dart';
import '../widgets/dialogs/add_page_dialog.dart'; // 🚀 Novo
import '../widgets/collaboration_center_sheet.dart'; 
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
    final toolState = ref.watch(canvasToolProvider);
    
    // 🚀 PERSISTÊNCIA DA UI: Assistir ao provider aqui garante que o estado da gaveta
    // (grelha, secções fechadas) se mantenha vivo enquanto o caderno estiver aberto.
    ref.watch(canvasUiProvider); 

    // 🚀 OTIMIZAÇÃO: Ouvir quando as páginas carregam ou mudam de ordem
    ref.listen<CanvasDocumentState>(canvasDocumentProvider, (previous, next) {
      if (next.pages.isNotEmpty) {
        // 1. Garantir lazy load se necessário
        if (previous == null || previous.pages.isEmpty) {
          ref.read(canvasDocumentProvider.notifier).ensurePageLoaded(0);
        }
        // 2. ⚓ Sincronizar índice do Viewport com os IDs (Âncora)
        ref.read(canvasViewportProvider.notifier).syncIndexWithId(
          next.pages.map((p) => p.clientId).toList()
        );
      }
    });

    final bool hasPages = docState.pages.isNotEmpty;
    // 🚀 SEGURANÇA: Garantir que o index está sempre dentro dos limites para evitar RangeError
    final int safeIndex = hasPages ? viewportState.currentPageIndex.clamp(0, docState.pages.length - 1) : 0;
    final currentPage = hasPages ? docState.pages[safeIndex] : null;

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
        onAddPage: () => showDialog(
          context: context, 
          builder: (_) => AddPageDialog(
            defaultLineType:'ruled',
            defaultLineSpacing: 28.0,
          )
        ),
      ) : null,
      body: !hasPages 
        ? Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.note_add_rounded, size: 64, color: Colors.black.withOpacity(0.1)),
                const SizedBox(height: 16),
                Text(
                  'Este caderno ainda não tem folhas.',
                  style: GoogleFonts.inter(fontSize: 16, color: Colors.black54),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      showDialog(
                        context: context, 
                        builder: (_) => AddPageDialog(
                          defaultLineType:'ruled',
                          defaultLineSpacing: 28.0,
                        ),
                      );
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C5C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.add),
                  label: const Text('CRIAR PRIMEIRA FOLHA', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ) 
        : Stack(
        children: [
          // 🚀 ESTABILIDADE SUPREMA: Excluímos as páginas da árvore de semântica global 
          ExcludeSemantics(
            child: _CanvasPageView(
              textController: _textController,
              textFocusNode: _textFocusNode,
            ),
          ),
          if (!viewportState.isFocusMode)
            Positioned(
              bottom: 20, left: 0, right: 0,
              child: Center(
                child: CanvasToolbar(
                  currentPage: currentPage!,
                  onColorTap: () {
                    if (toolState.selectedStrokeIds.isNotEmpty) {
                      showDialog(context: context, builder: (_) => ColorStudioDialog(
                        onColorSelected: (hex) {
                          ref.read(canvasDocumentProvider.notifier).updateStrokesColor(
                            currentPage, 
                            toolState.selectedStrokeIds, 
                            hex
                          );
                        },
                      ));
                    } else {
                      showDialog(context: context, builder: (_) => const ColorStudioDialog());
                    }
                  },
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

class _CanvasPageView extends ConsumerWidget {
  final TextEditingController textController;
  final FocusNode textFocusNode;

  const _CanvasPageView({
    required this.textController,
    required this.textFocusNode,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docState = ref.watch(canvasDocumentProvider);
    final viewportNotifier = ref.read(canvasViewportProvider.notifier);

    return PageView.builder(
      controller: viewportNotifier.pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: docState.pages.length,
      onPageChanged: (index) {
        final String cid = docState.pages[index].clientId;
        viewportNotifier.setPageIndex(index, clientId: cid);
        ref.read(canvasDocumentProvider.notifier).ensurePageLoaded(index);
      },
      itemBuilder: (context, index) {
        final page = docState.pages[index];
        final toolState = ref.watch(canvasToolProvider);
        final toolNotifier = ref.read(canvasToolProvider.notifier);
        
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
              interactionEndFrictionCoefficient: 0.01,
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
                        ExplanationLayer(pageSize: const Size(595, 842)),
                        InteractionLayer(
                          page: page,
                          isBlocked: page.isFrozen,
                          onFinishEditing: () => toolNotifier.clearTextEditing(),
                          onAddTextBlock: (pos) {
                            final newBlock = TextBlock(text: '', position: pos, textColorHex: toolState.selectedColorHex);
                            ref.read(canvasDocumentProvider.notifier).addTextBlock(page, newBlock);
                            toolNotifier.setTextEditing(InlineTarget.block, newBlock);
                            textController.text = '';
                            textFocusNode.requestFocus();
                          },
                        ),
                        TextLayer(
                          page: page,
                          textController: textController,
                          textFocusNode: textFocusNode,
                          onTitleTap: () {
                            toolNotifier.setTextEditing(InlineTarget.title);
                            textController.text = page.title;
                            textFocusNode.requestFocus();
                          },
                          onTextBlockTap: (p, b) {
                            toolNotifier.setTextEditing(InlineTarget.block, b);
                            textController.text = b.text;
                            textFocusNode.requestFocus();
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
    );
  }
}
