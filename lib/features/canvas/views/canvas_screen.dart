import 'dart:math' as math;
import 'package:flutter/material.dart' hide SelectionOverlay;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import '../providers/collaboration_provider.dart';
import '../providers/audio_session_provider.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_viewport_provider.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_ui_provider.dart'; 
import '../models/canvas_enums.dart';
import '../widgets/canvas_app_bar.dart';
import '../widgets/canvas_page_drawer.dart';
import '../widgets/canvas_toolbar.dart';
import '../widgets/layers/interaction_layer.dart';
import '../widgets/layers/live_text_edit_layer.dart'; 
import '../widgets/page_canvas.dart'; 
import '../widgets/selection_overlay.dart'; 
import '../../explanations/widgets/explanation_layer.dart'; 
import '../widgets/dialogs/thickness_studio_dialog.dart';
import '../widgets/dialogs/paper_style_dialog.dart';
import '../widgets/dialogs/add_page_dialog.dart'; 
import '../widgets/collaboration_center_sheet.dart'; 
import '../../shared/widgets/color_engine_widget.dart'; // 🚀
import 'package:caderno_digital_app/features/canvas/models/text_block_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../models/local_page_model.dart';

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
      
      ref.read(canvasDocumentProvider.notifier).initNotebook(
        widget.notebook.id ?? 0,
        widget.notebook.serverId,
        widget.notebook.role,
        user?.serverId?.toString(),
        templateType: widget.notebook.templateType,
      );

      final collabService = ref.read(collaborationProvider);
      collabService.getPages = () => ref.read(canvasDocumentProvider).pages;
      collabService.getCurrentPageIndex = () => ref.read(canvasViewportProvider).currentPageIndex;
      collabService.getCurrentScale = () {
        final state = ref.read(canvasViewportProvider);
        if (state.currentPageClientId == null) return 1.0;
        return ref.read(canvasViewportProvider.notifier)
            .getControllerFor(state.currentPageClientId!)
            .value.getMaxScaleOnAxis();
      };

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
    // 🚀 PERSISTÊNCIA DO VIEWPORT: watch(select) garante que o provider não seja auto-disposed
    // e mantém o zoom na RAM por página sem causar rebuilds globais por movimento.
    ref.watch(canvasViewportProvider.select((s) => s.currentPageClientId)); 
    
    final bool isFocusMode = ref.watch(canvasViewportProvider.select((s) => s.isFocusMode));
    final toolState = ref.watch(canvasToolProvider);
    final toolNotifier = ref.read(canvasToolProvider.notifier); // 🚀 FIX: Definir o notifier
    
    // 🚀 v4.5: Sincronizar o TextEditingController quando um bloco entra em edição
    ref.listen<CanvasToolState>(canvasToolProvider, (previous, next) {
      if (next.activeTextBlock != null && next.activeTextBlock != previous?.activeTextBlock) {
        _textController.text = next.activeTextBlock!.text;
        _textController.selection = TextSelection.fromPosition(
          TextPosition(offset: _textController.text.length),
        );
      }
    });

    ref.watch(canvasUiProvider); 

    ref.listen<CanvasDocumentState>(canvasDocumentProvider, (previous, next) {
      if (next.pages.isNotEmpty) {
        if (previous == null || previous.pages.isEmpty) {
          ref.read(canvasDocumentProvider.notifier).ensurePageLoaded(0);
        }
        ref.read(canvasViewportProvider.notifier).syncIndexWithId(
          next.pages.map((p) => p.clientId).toList()
        );
      }
    });

    final bool hasPages = docState.pages.isNotEmpty;
    // 🚀 Selecionar apenas o index para evitar rebuild global por zoom (%)
    final int currentPageIndex = ref.watch(canvasViewportProvider.select((s) => s.currentPageIndex));
    final int safeIndex = hasPages ? currentPageIndex.clamp(0, docState.pages.length - 1) : 0;
    final currentPage = hasPages ? docState.pages[safeIndex] : null;

    return Scaffold(
      backgroundColor: const Color(0xFFD6D6D6),
      resizeToAvoidBottomInset: true, // 🚀 v5.8: Garantir que a folha sobe no Android/iOS
      appBar: isFocusMode ? null : CanvasAppBar(
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
                Icon(Icons.note_add_rounded, size: 64, color: Colors.black.withValues(alpha: 0.1)),
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
              ExcludeSemantics(
                child: _CanvasPageView(
                  textController: _textController,
                  textFocusNode: _textFocusNode,
                ),
              ),
                if (!ref.watch(canvasViewportProvider.select((s) => s.isFocusMode)))
                  Positioned(
                    bottom: 20, left: 0, right: 0,
                    child: Center(
                      child: CanvasToolbar(
                        currentPage: currentPage!,
                        onColorTap: () async {
                          if (toolState.selectedStrokeIds.isNotEmpty) {
                            final hex = await ColorEngine.show(context, initialColor: toolState.selectedColorHex, title: 'Cor da Seleção');
                            if (hex != null) {
                              ref.read(canvasDocumentProvider.notifier).updateStrokesColor(
                                currentPage, 
                                toolState.selectedStrokeIds, 
                                hex
                              );
                            }
                          } else {
                            final hex = await ColorEngine.show(context, initialColor: toolState.selectedColorHex, title: 'Cor da Caneta');
                            if (hex != null) toolNotifier.setColor(hex);
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
    final viewportNotifier = ref.read(canvasViewportProvider.notifier);
    final int pageCount = ref.watch(canvasDocumentProvider.select((s) => s.pages.length));
    
    return PageView.builder(
      controller: viewportNotifier.pageController,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: pageCount,
      onPageChanged: (index) {
        final page = ref.read(canvasDocumentProvider).pages[index];
        viewportNotifier.setPageIndex(index, clientId: page.clientId, initialMatrix: page.viewportMatrix);
        ref.read(canvasDocumentProvider.notifier).ensurePageLoaded(index);
      },
      itemBuilder: (context, index) {
        return Consumer(
          builder: (context, ref, _) {
            final page = ref.watch(canvasDocumentProvider.select((s) => s.pages[index]));
            final toolState = ref.watch(canvasToolProvider);
            final toolNotifier = ref.read(canvasToolProvider.notifier);
            
            return LayoutBuilder(
              builder: (context, constraints) {
                final Size screenSize = Size(constraints.maxWidth, constraints.maxHeight);

                return _IsolateViewportItem(
                  page: page,
                  screenSize: screenSize,
                  toolState: toolState,
                  toolNotifier: toolNotifier,
                  textController: textController,
                  textFocusNode: textFocusNode,
                  viewportNotifier: viewportNotifier,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _IsolateViewportItem extends ConsumerStatefulWidget {
  final LocalPage page;
  final Size screenSize;
  final CanvasToolState toolState;
  final CanvasToolNotifier toolNotifier;
  final TextEditingController textController;
  final FocusNode textFocusNode;
  final CanvasViewportNotifier viewportNotifier;

  const _IsolateViewportItem({
    required this.page,
    required this.screenSize,
    required this.toolState,
    required this.toolNotifier,
    required this.textController,
    required this.textFocusNode,
    required this.viewportNotifier,
  });

  @override
  ConsumerState<_IsolateViewportItem> createState() => _IsolateViewportItemState();
}

class _IsolateViewportItemState extends ConsumerState<_IsolateViewportItem> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.viewportNotifier.updateViewport(screenSize: widget.screenSize);
        if (!widget.viewportNotifier.isPageInitialized(widget.page.clientId)) {
          widget.viewportNotifier.restorePageMatrix(widget.page, widget.screenSize);
        }
      }
    });
  }

  int _activePointers = 0; // 🚀 v7.4: Controle local para evitar race conditions

  @override
  Widget build(BuildContext context) {
    final controller = widget.viewportNotifier.getControllerFor(widget.page.clientId);
    final viewportState = ref.watch(canvasViewportProvider); // 🚀 v7.5

    return Listener(
      onPointerDown: (e) {
        _activePointers++;
        widget.viewportNotifier.updatePointerCount(_activePointers);
        
        // 🚀 v9.8: Atalho Multi-toque para Pan
        if (_activePointers > 1) {
          widget.toolNotifier.enterTemporaryPan();
        }
      },
      onPointerUp: (e) {
        _activePointers = math.max(0, _activePointers - 1);
        widget.viewportNotifier.updatePointerCount(_activePointers);
        
        // 🚀 v9.8: Voltar para a ferramenta anterior ao soltar todos os dedos
        if (_activePointers == 0) {
          widget.toolNotifier.exitTemporaryPan();
          ref.read(canvasUiProvider.notifier).setHudMode(false); // 🚀 FIX v9.9: Garantir toolbar visível
        }
      },
      onPointerCancel: (e) {
        _activePointers = 0;
        widget.viewportNotifier.updatePointerCount(0);
        widget.toolNotifier.exitTemporaryPan();
        ref.read(canvasUiProvider.notifier).setHudMode(false); // 🚀 FIX v9.9
      },
      child: InteractiveViewer(
        key: ValueKey('viewport_${widget.page.clientId}'),
        transformationController: controller,
        boundaryMargin: const EdgeInsets.all(5000.0),
        minScale: 0.05,
        maxScale: 6.0,
        constrained: false,
        interactionEndFrictionCoefficient: 0.01,
        child: IgnorePointer(
          ignoring: viewportState.activePointerCount > 1, // 🚀 v7.5: Bloqueio global da folha no multi-toque
          child: SizedBox(
            width: widget.page.pageWidthPx,
            height: widget.page.pageHeightPx,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Container(
                  width: widget.page.pageWidthPx,
                  height: widget.page.pageHeightPx,
                  key: ValueKey('page_container_${widget.page.clientId}'),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFDFBF7),
                    boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.26), blurRadius: 10, offset: const Offset(0, 4))],
                  ),
                  child: ClipRect(
                    child: Stack(
                      clipBehavior: Clip.none,
                      children: [
                        PageCanvas(
                          page: widget.page,
                          pageSize: Size(widget.page.pageWidthPx, widget.page.pageHeightPx),
                        ),
                        SelectionOverlay(
                          page: widget.page,
                          pageSize: Size(widget.page.pageWidthPx, widget.page.pageHeightPx),
                        ),
                        ExplanationLayer(pageSize: Size(widget.page.pageWidthPx, widget.page.pageHeightPx)),
                        InteractionLayer(
                          page: widget.page,
                          isBlocked: widget.page.isFrozen,
                          onFinishEditing: () async {
                            debugPrint('🏁 [CanvasScreen] Parando edição ativa...');
                            final toolState = ref.read(canvasToolProvider);
                            if (toolState.activeTextBlock != null) {
                              await ref.read(canvasDocumentProvider.notifier).cleanupIfEmpty(widget.page, toolState.activeTextBlock!.id);
                            }
                            ref.read(canvasToolProvider.notifier).stopEditing();
                            FocusManager.instance.primaryFocus?.unfocus();
                          },
                          onAddTextBlock: (pos) {
                            final newBlock = TextBlock(
                              text: '',
                              position: pos,
                              textColorHex: widget.toolState.selectedColorHex,
                              zIndex: widget.page.objects.length,
                            );
                            ref.read(canvasDocumentProvider.notifier).addTextBlock(widget.page, newBlock);
                            widget.toolNotifier.setTextEditing(InlineTarget.block, newBlock);
                            widget.textController.text = '';
                            widget.textFocusNode.requestFocus();
                          },
                          onTitleTap: () {
                            widget.toolNotifier.setTextEditing(InlineTarget.title);
                            widget.textController.text = widget.page.title;
                            widget.textFocusNode.requestFocus();
                          },
                        ),
                        LiveTextEditLayer(
                          page: widget.page,
                          textController: widget.textController,
                          textFocusNode: widget.textFocusNode,
                          onTitleTap: () {
                            widget.toolNotifier.setTextEditing(InlineTarget.title);
                            widget.textController.text = widget.page.title;
                            widget.textFocusNode.requestFocus();
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
