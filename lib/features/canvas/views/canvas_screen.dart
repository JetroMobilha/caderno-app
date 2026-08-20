import 'dart:async';
import 'dart:io' as io;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math_64.dart' as vm hide Colors, Matrix4;

import 'package:caderno_digital_app/features/auth/controllers/auth_controller.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:caderno_digital_app/features/canvas/controllers/canvas_controller.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';
import 'package:caderno_digital_app/features/canvas/widgets/start_collaboration_sheet.dart'; 
import 'package:caderno_digital_app/features/canvas/models/image_block_model.dart'; 
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/models/stroke_model.dart';
import 'package:caderno_digital_app/features/canvas/models/text_block_model.dart';
import 'package:caderno_digital_app/features/canvas/widgets/canvas_painter.dart';
import 'package:caderno_digital_app/features/canvas/widgets/canvas_toolbar.dart';
import 'package:caderno_digital_app/features/canvas/widgets/ai_assistant_sheet.dart';
import 'package:caderno_digital_app/features/canvas/widgets/collaboration_center_sheet.dart';
import 'package:caderno_digital_app/features/canvas/widgets/live_voice_cockpit.dart';
import 'package:caderno_digital_app/features/canvas/widgets/collaboration_chat_widget.dart';

class CanvasScreen extends ConsumerStatefulWidget {
  final Notebook notebook;

  const CanvasScreen({super.key, required this.notebook});

  @override
  ConsumerState<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends ConsumerState<CanvasScreen> {
  final FocusNode _textFocusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();

  final Set<int> _activePointers = {};

  final Map<String, Size> _paperSizes = {
    'A5': const Size(420, 595), 'A4': const Size(595, 842),
    'A3': const Size(842, 1191), 'A2': const Size(1191, 1684),
    'A1': const Size(1684, 2384), 'A0': const Size(2384, 3370),
  };

  final Map<String, Color> _colorPalette = {
    'Black': const Color(0xFF1A1A24),
    'Dark Blue': const Color(0xFF0F4C5C),
    'Forest Green': const Color(0xFF1B4332),
    'Royal Blue': const Color(0xFF1976D2),
    'Purple': const Color(0xFF6A1B9A),
    'Deep Red': const Color(0xFF9B2226),
    'Orange': const Color(0xFFE67E22),
    'Vibrant Green': const Color(0xFF27AE60),
    'Teal': const Color(0xFF00897B),
    'Pink': const Color(0xFFD81B60),
  };

  String? _liveStrokeId;
  DateTime _lastBroadcastTime = DateTime.now();
  int _lastBroadcastedPointIndex = 0;
  String myUserId = "";

  ImageBlock? _originalImageState;
  TextBlock? _originalTextState;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final controller = ref.read(canvasProvider);
      final user = ref.read(authProvider).currentUser;
      controller.initNotebook(
        widget.notebook.id ?? 0,
        widget.notebook.serverId,
        widget.notebook.lineType,
        widget.notebook.paperSize,
        widget.notebook.role,
        user?.serverId?.toString() ?? "",
        templateType: widget.notebook.templateType,
        collaborationMode: widget.notebook.collaborationMode,
      ).then((_) {
        if (!mounted) {
          return;
        }
        if (controller.isNotebookDeleted) {
          _showNotebookDeletedDialog(controller);
        } else if (controller.currentUserRole == 'viewer') {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              backgroundColor: const Color(0xFF0F4C5C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              content: Row(
                children: [
                  const Icon(Icons.lock_person, color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(child: Text('Modo Visualização: Não tens permissão para editar.', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                ],
              ),
            ),
          );
        }
      });
    });
  }

  void _showNotebookDeletedDialog(CanvasController controller) {
    int? selectedSubjectId;
    String newSubjectName = "";
    bool isCreatingSubject = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => PopScope(
          canPop: false,
          child: AlertDialog(
            backgroundColor: const Color(0xFFFDFBF7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
            title: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
                const SizedBox(width: 12),
                Text('Caderno Apagado!', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'O proprietário removeu este caderno. Podes continuar a visualizar o conteúdo atual, mas as alterações não serão sincronizadas.',
                    style: TextStyle(color: Colors.black87, fontSize: 14),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Podes salvar uma cópia local deste caderno nas tuas disciplinas para não perderes o teu trabalho.',
                    style: TextStyle(color: Colors.black54, fontSize: 13),
                  ),
                  const SizedBox(height: 20),
                  const Text('Onde queres guardar a cópia?', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 12),
                  if (!isCreatingSubject) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<int>(
                          isExpanded: true,
                          hint: const Text('Selecionar Disciplina'),
                          value: selectedSubjectId,
                          items: ref.watch(subjectsProvider).map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                          onChanged: (val) => setModalState(() => selectedSubjectId = val),
                        ),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () => setModalState(() => isCreatingSubject = true),
                      icon: const Icon(Icons.add, size: 18),
                      label: const Text('Criar Nova Disciplina'),
                    ),
                  ] else ...[
                    TextField(
                      decoration: InputDecoration(
                        hintText: 'Nome da disciplina...',
                        filled: true,
                        fillColor: Colors.white,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Colors.black12)),
                      ),
                      onChanged: (val) => newSubjectName = val,
                    ),
                    TextButton.icon(
                      onPressed: () => setModalState(() => isCreatingSubject = false),
                      icon: const Icon(Icons.list, size: 18),
                      label: const Text('Voltar à lista'),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  controller.exitNotebook();
                  Navigator.pop(context);
                  Navigator.pop(context);
                },
                child: const Text('Descartar e Sair', style: TextStyle(color: Colors.black45)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F4C5C),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () async {
                  int? finalSubId = selectedSubjectId;
                  if (isCreatingSubject && newSubjectName.isNotEmpty) {
                    final newSub = Subject(name: newSubjectName, color: "#0F4C5C");
                    final added = await ref.read(subjectsProvider.notifier).addSubject(newSub);
                    finalSubId = added?.id;
                  }
                  if (finalSubId != null) {
                    await controller.saveCopyOfNotebook(finalSubId);
                    if (!context.mounted) return;
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cópia guardada com sucesso! ✨')));
                    Navigator.pop(context);
                    Navigator.pop(context);
                  }
                },
                child: const Text('Salvar Cópia'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _textFocusNode.dispose();
    _textController.dispose();
    super.dispose();
  }

  void _finishEditingInline(LocalPage page) {
    final controller = ref.read(canvasProvider);
    if (controller.activeInlineTarget == InlineTarget.title) {
      controller.savePageMetadata(page);
      controller.broadcastPageMetadataUpdate(page, isEditing: false);
    } else if (controller.activeInlineTarget == InlineTarget.block && controller.activeTextBlock != null) {
      if (_textController.text.trim().isEmpty) {
        controller.deleteTextBlock(page, controller.activeTextBlock!);
      } else {
        final oldBlock = _originalTextState;
        final newBlock = controller.activeTextBlock!.clone()..text = _textController.text;
        if (oldBlock != null) {
          controller.recordTextBlockUpdate(page, oldBlock, newBlock);
        }
        controller.saveTextBlock(page, newBlock);
        controller.broadcastTextBlockUpdate(page, newBlock, senderId: myUserId, isEditing: false);
      }
    }
    controller.clearTextEditing();
    _textController.clear();
    _textFocusNode.unfocus();
    controller.safeNotify();
  }

  void _showAiAssistantSheet(CanvasController controller, LocalPage? page) {
    if (page == null) {
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: AIAssistantSheet(
          notebookId: widget.notebook.id,
          pageId: page.id,
        ),
      ),
    );
  }

  void _showRecordingsSheet(CanvasController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Container(
          height: MediaQuery.of(context).size.height * 0.7,
          decoration: const BoxDecoration(color: Color(0xFFFDFBF7), borderRadius: BorderRadius.vertical(top: Radius.circular(32))),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const SizedBox(width: 48),
                  Text('Gravações da Aula', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
                  const CloseButton(),
                ],
              ),
              const SizedBox(height: 8),
              
              ListenableBuilder(
                listenable: controller,
                builder: (context, _) {
                  if (controller.currentlyPlayingRecording == null) {
                    return const SizedBox.shrink();
                  }
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F4C5C).withValues(alpha: 0.05),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFF0F4C5C).withValues(alpha: 0.1)),
                    ),
                    child: Column(
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.audiotrack_rounded, color: Color(0xFF0F4C5C)),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'A reproduzir: ${controller.currentlyPlayingRecording!.title}',
                                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                maxLines: 1, overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            PopupMenuButton<double>(
                              initialValue: controller.playbackSpeed,
                              onSelected: (speed) => controller.setPlaybackSpeed(speed),
                              child: Chip(
                                label: Text('${controller.playbackSpeed}x', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                                visualDensity: VisualDensity.compact, backgroundColor: Colors.white,
                              ),
                              itemBuilder: (context) => [0.5, 1.0, 1.25, 1.5, 2.0].map((s) => PopupMenuItem(value: s, child: Text('${s}x'))).toList(),
                            ),
                          ],
                        ),
                        Slider(
                          value: controller.audioPosition.inSeconds.toDouble(),
                          max: controller.audioDuration.inSeconds.toDouble().clamp(1.0, double.infinity),
                          activeColor: const Color(0xFF0F4C5C),
                          onChanged: (v) => controller.seekAudio(v / controller.audioDuration.inSeconds.toDouble()),
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            IconButton(icon: const Icon(Icons.replay_10_rounded), onPressed: () => controller.skipAudio(-10)),
                            const SizedBox(width: 16),
                            CircleAvatar(
                              radius: 28, backgroundColor: const Color(0xFF0F4C5C),
                              child: IconButton(
                                icon: Icon(controller.isAudioPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded, color: Colors.white, size: 32),
                                onPressed: () => controller.isAudioPlaying ? controller.pauseAudio() : controller.resumeAudio(),
                              ),
                            ),
                            const SizedBox(width: 16),
                            IconButton(icon: const Icon(Icons.forward_10_rounded), onPressed: () => controller.skipAudio(10)),
                          ],
                        ),
                      ],
                    ),
                  );
                }
              ),

              const SizedBox(height: 8),
              Text('Lista de Ficheiros:', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),

              Expanded(
                child: controller.lessonRecordings.isEmpty
                    ? Center(child: Text('Nenhuma gravação disponível.', style: TextStyle(color: Colors.grey.shade400)))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        itemCount: controller.lessonRecordings.length,
                        itemBuilder: (context, index) {
                          final rec = controller.lessonRecordings[index];
                          final bool isPlaying = controller.currentlyPlayingRecording?.id == rec.id;
                          return Card(
                            elevation: 0, margin: const EdgeInsets.only(bottom: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            child: ListTile(
                              leading: CircleAvatar(backgroundColor: isPlaying ? const Color(0xFF0F4C5C) : Colors.grey.shade100, child: Icon(Icons.mic_none_rounded, color: isPlaying ? Colors.white : Colors.black54, size: 20)),
                              title: Text(rec.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              subtitle: const Text('Gravação da aula', style: TextStyle(fontSize: 12)),
                              trailing: IconButton(
                                icon: Icon(isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_outline_rounded, color: isPlaying ? Colors.redAccent : const Color(0xFF0F4C5C)),
                                onPressed: () => isPlaying ? controller.stopAudio() : controller.playRecording(rec),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showCollaborationCenter(CanvasController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => CollaborationCenterSheet(
        notebook: widget.notebook,
        onInviteTap: () => _showCollaborationSettings(controller),
      ),
    );
  }

  void _showCollaborationSettings(CanvasController controller) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => StartCollaborationSheet(
        notebookServerId: widget.notebook.serverId ?? 0,
        pages: controller.pages,
        currentTitle: widget.notebook.title,
        role: controller.currentUserRole,
        onStart: (pageIds, altTitle, sharingType) {
          controller.toggleCollaboration(true, alternativeTitle: altTitle, sharingType: sharingType, pageIds: pageIds);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = ref.watch(canvasProvider);
    final user = ref.watch(authProvider).currentUser;
    myUserId = user?.serverId?.toString() ?? "";

    if (controller.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: Color(0xFF0F4C5C))));
    }

    final bool hasPages = controller.pages.isNotEmpty;
    final LocalPage? currentPage = hasPages ? controller.pages[controller.currentPageIndex] : null;

    return Listener(
      onPointerDown: (e) {
        setState(() => _activePointers.add(e.pointer));
        controller.updatePointerCount(_activePointers.length);
      },
      onPointerUp: (e) {
        setState(() => _activePointers.remove(e.pointer));
        controller.updatePointerCount(_activePointers.length);
      },
      onPointerCancel: (e) {
        setState(() => _activePointers.remove(e.pointer));
        controller.updatePointerCount(_activePointers.length);
      },
      child: Scaffold(
        backgroundColor: const Color(0xFFD6D6D6),
        appBar: controller.isFocusMode ? null : _buildAppBar(controller, hasPages),
        endDrawer: hasPages ? _buildPageDrawer(controller) : null, 
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
                      final Size? rawSize = _paperSizes[page.paperSize];
                      final Size effectiveBaseSize = rawSize ?? const Size(595, 842);
                      final Size pSize = page.isLandscape ? Size(effectiveBaseSize.height, effectiveBaseSize.width) : effectiveBaseSize;
                      final bool isFollowing = controller.followingUserId != null;
                      final bool isBlocked = (controller.currentTool == ToolMode.pan || controller.currentUserRole == 'viewer' || page.isFrozen) && !isFollowing;
                      final bool canTapCanvas = (controller.currentTool == ToolMode.text || controller.currentTool == ToolMode.eraser || controller.currentTool == ToolMode.draw) && !page.isFrozen;
                      final bool isTearing = controller.tearingPageClientIds.contains(page.clientId);

                      return AnimatedSlide(
                        duration: const Duration(milliseconds: 450),
                        offset: isTearing ? const Offset(0.3, -1.5) : Offset.zero, 
                        curve: Curves.easeInBack,
                        child: AnimatedOpacity(
                          duration: const Duration(milliseconds: 350),
                          opacity: isTearing ? 0.0 : 1.0,
                          child: InteractiveViewer.builder(
                            scaleEnabled: (controller.currentTool == ToolMode.pan || _activePointers.length >= 2) && !isFollowing,
                            panEnabled: (controller.currentTool == ToolMode.pan || _activePointers.length >= 2) && !isFollowing,
                            maxScale: 6.0, minScale: 0.1,
                            transformationController: controller.transformationController,
                            boundaryMargin: const EdgeInsets.symmetric(horizontal: 500, vertical: 800), 
                            onInteractionUpdate: (details) {
                              if (controller.isBroadcastingViewport) {
                                final Matrix4 matrix = controller.transformationController.value;
                                final double screenWidth = MediaQuery.of(context).size.width;
                                final double screenHeight = MediaQuery.of(context).size.height;
                                try {
                                  final Matrix4 inverse = Matrix4.inverted(matrix);
                                  final vm.Vector3 centerVector = inverse.transform3(vm.Vector3(screenWidth / 2, screenHeight / 2, 0));
                                  controller.currentViewportCenter = Offset(centerVector.x, centerVector.y);
                                } catch (e) {
                                  controller.currentViewportCenter = details.focalPoint;
                                }
                              }
                            },
                            builder: (context, viewport) {
                              controller.currentVisibleWidth = (viewport.point1.x - viewport.point0.x).abs();
                              controller.lastScreenSize = MediaQuery.of(context).size;
                              return Center(
                                child: Container(
                                  width: pSize.width, height: pSize.height,
                                  decoration: BoxDecoration(color: const Color(0xFFFDFBF7), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 10, offset: const Offset(0, 4))], border: Border.all(color: Colors.black12, width: 1)),
                                  child: ClipRect(
                                    child: Stack(
                                      clipBehavior: Clip.none,
                                      children: [
                                        RepaintBoundary(
                                          child: CustomPaint(
                                            size: pSize,
                                            painter: StaticNotebookPainter(
                                              strokes: page.strokes, lineType: controller.liveLineType, lineSpacing: controller.liveLineSpacing,
                                              selectedStrokeIds: controller.selectedStrokeIds, selectionRect: controller.selectionRectStart != null && controller.selectionRectEnd != null ? Rect.fromPoints(controller.selectionRectStart!, controller.selectionRectEnd!) : null,
                                              pageVersion: page.version, remoteMovingStrokeIds: controller.remoteMovingStrokeIds, visibleAuthorIds: controller.visibleAuthorIds, isAuthorColorEnabled: controller.isAuthorColorEnabled, userColors: controller.userColorsMap,
                                            ),
                                          ),
                                        ),
                                        ...page.imageBlocks.where((img) => !img.isDeleted).map((img) {
                                          final bool isSelected = img.id == controller.selectedEditingImageId;
                                          final bool isImageToolActive = controller.currentTool == ToolMode.imageEdit;
                                          final bool isUploading = controller.uploadingImageIds.contains(img.id);
                                          final bool hasFailed = controller.failedImageUploads.contains(img.id);
                                          const double padding = 60.0;
                                          return AnimatedPositioned( 
                                            duration: const Duration(milliseconds: 60), curve: Curves.easeOutCubic, key: ValueKey('img_${img.id}'), 
                                            left: img.position.dx - padding, top: img.position.dy - padding,
                                            child: Transform.rotate(
                                              angle: img.rotation,
                                              child: SizedBox(
                                                width: img.width + (padding * 2), height: img.height + (padding * 2),
                                                child: Stack(
                                                  clipBehavior: Clip.none,
                                                  children: [
                                                    Positioned(
                                                      left: padding, top: padding, width: img.width, height: img.height,
                                                      child: GestureDetector(
                                                        onTapDown: isImageToolActive ? (_) { if (controller.selectedEditingImageId != img.id) { setState(() { controller.selectedEditingImageId = img.id; _originalImageState = img.clone(); }); controller.bringImageToFront(page, img.id); controller.safeNotify(); } } : null,
                                                        onPanUpdate: isImageToolActive && isSelected && controller.currentUserRole != 'viewer' ? (d) {
                                                          final double cosA = math.cos(img.rotation); final double sinA = math.sin(img.rotation);
                                                          final Offset rotatedDelta = Offset(d.delta.dx * cosA - d.delta.dy * sinA, d.delta.dx * sinA + d.delta.dy * cosA);
                                                          setState(() => img.position += rotatedDelta); controller.broadcastThrottledImageUpdate(page, img);
                                                        } : null,
                                                        child: Container(
                                                          decoration: BoxDecoration(border: isSelected ? Border.all(color: const Color(0xFF0F4C5C), width: 3.0) : (isUploading || hasFailed ? Border.all(color: Colors.grey.withValues(alpha: 0.5), width: 1.5) : null), color: isSelected ? const Color(0x1F0F4C5C) : null),
                                                          child: Stack(
                                                            fit: StackFit.expand,
                                                            children: [
                                                              if (!isUploading || img.imagePath.startsWith('http')) kIsWeb || img.imagePath.startsWith('http') ? Image.network(img.imagePath, fit: BoxFit.fill, loadingBuilder: (context, child, loadingProgress) { if (loadingProgress == null) { return child; } return const Center(child: CircularProgressIndicator(strokeWidth: 2)); }, errorBuilder: (context, error, stackTrace) => const Icon(Icons.broken_image_outlined, color: Colors.grey)) : Image.file(io.File(img.imagePath), fit: BoxFit.fill),
                                                              if (isUploading) Container(color: Colors.black.withValues(alpha: 0.3), child: const Center(child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3))),
                                                              if (hasFailed) const Center(child: Icon(Icons.cloud_off, color: Colors.redAccent, size: 32)),
                                                            ],
                                                          ),
                                                        ),
                                                      ),
                                                    ),
                                                    if (isSelected && controller.currentUserRole != 'viewer') ...[
                                                      Positioned(
                                                        left: padding + img.width - 18, top: padding + img.height - 18, width: 36, height: 36,
                                                        child: GestureDetector(
                                                          behavior: HitTestBehavior.opaque,
                                                          onPanUpdate: (d) { setState(() { img.width = (img.width + d.delta.dx).clamp(60.0, 1000.0); img.height = (img.height + d.delta.dy).clamp(60.0, 1000.0); }); controller.broadcastThrottledImageUpdate(page, img); },
                                                          child: Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0F4C5C), width: 2), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))]), child: const Icon(Icons.unfold_more_rounded, size: 18, color: Color(0xFF0F4C5C))),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        left: padding + (img.width / 2) - 16, top: padding - 55, width: 32,
                                                        child: Column(
                                                          mainAxisSize: MainAxisSize.min,
                                                          children: [
                                                            GestureDetector(
                                                              behavior: HitTestBehavior.opaque,
                                                              onPanUpdate: (d) { final double radius = (img.height / 2) + 55; setState(() { img.rotation += d.delta.dx / radius; }); controller.broadcastThrottledImageUpdate(page, img); },
                                                              child: Container(decoration: BoxDecoration(color: Colors.white, shape: BoxShape.circle, border: Border.all(color: const Color(0xFF0F4C5C), width: 2), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4, offset: const Offset(0, 2))]), child: const Icon(Icons.rotate_right_rounded, size: 18, color: Color(0xFF0F4C5C))),
                                                            ),
                                                            Container(width: 2, height: 23, color: const Color(0xFF0F4C5C).withValues(alpha: 0.5)),
                                                          ],
                                                        ),
                                                      ),
                                                      Positioned(
                                                        left: padding + img.width - 22, top: padding - 10, width: 32, height: 32,
                                                        child: GestureDetector(
                                                          onTap: () { controller.clearImageSelection(); controller.deleteImageBlock(page, img); },
                                                          child: Container(decoration: BoxDecoration(color: Colors.redAccent.withValues(alpha: 0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))]), child: const Icon(Icons.delete_forever_rounded, size: 16, color: Colors.white)),
                                                        ),
                                                      ),
                                                      Positioned(
                                                        left: padding - 10, top: padding - 10, width: 32, height: 32,
                                                        child: GestureDetector(
                                                          onTap: () {
                                                            if (_originalImageState != null) {
                                                              controller.recordImageUpdate(page, _originalImageState!, img.clone());
                                                            }
                                                            controller.clearImageSelection(); controller.triggerAutoSave(page);
                                                          },
                                                          child: Container(decoration: BoxDecoration(color: Colors.green.withValues(alpha: 0.9), shape: BoxShape.circle, boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 4, offset: const Offset(0, 2))]), child: const Icon(Icons.check_rounded, size: 18, color: Colors.white)),
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ),
                                              ),
                                            ),
                                          );
                                        }),
                                        Positioned.fill(
                                          child: IgnorePointer(
                                            ignoring: controller.currentTool == ToolMode.pan || controller.currentTool == ToolMode.imageEdit || (controller.currentTool == ToolMode.text && controller.activeInlineTarget == InlineTarget.block),
                                            child: GestureDetector(
                                              behavior: HitTestBehavior.opaque,
                                              onTapDown: canTapCanvas && controller.currentUserRole != 'viewer' ? (details) {
                                                if (controller.activeInlineTarget != InlineTarget.none) {
                                                  _finishEditingInline(page);
                                                }
                                                if (controller.tryToggleChecklistAt(details.localPosition, page)) {
                                                  return;
                                                }
                                                if (controller.currentTool == ToolMode.text) {
                                                  controller.selectTextBlockAt(details.localPosition, page);
                                                  if (controller.selectedTextIds.isEmpty) {
                                                    final newBlock = TextBlock(text: '', position: details.localPosition, textColorHex: controller.selectedColorHex);
                                                    _originalTextState = null; controller.addTextBlock(page, newBlock); controller.selectedTextIds.add(newBlock.id); controller.setTextEditing(InlineTarget.block, newBlock);
                                                    _textController.text = ''; Future.delayed(const Duration(milliseconds: 50), () {
                                                      if (mounted) {
                                                        _textFocusNode.requestFocus();
                                                      }
                                                    });
                                                  }
                                                }
                                              } : null,
                                              onTapUp: controller.currentTool == ToolMode.eraser && controller.currentUserRole != 'viewer' ? (details) { controller.eraseAtPosition(details.localPosition, page); } : null,
                                              onPanStart: !isBlocked ? (details) {
                                                final localPos = details.localPosition; controller.broadcastPointer(localPos);
                                                if (controller.currentTool == ToolMode.draw) {
                                                  controller.selectedTextIds.clear(); controller.selectedStrokeIds.clear(); controller.selectedImageIds.clear(); controller.activeDrawingPageNumber = page.pageNumber; controller.setUserActivity('drawing'); _liveStrokeId = const Uuid().v4(); _lastBroadcastedPointIndex = 0; _lastBroadcastTime = DateTime.now(); controller.activePointsNotifier.value = [localPos];
                                                } else if (controller.currentTool == ToolMode.select) {
                                                  bool hitSelected = false; for (var id in controller.selectedStrokeIds) { final matches = page.strokes.where((s) => s.id == id); if (matches.isNotEmpty && matches.first.points.any((pt) => (pt - localPos).distance < 25.0)) { hitSelected = true; break; } }
                                                  for (var id in controller.selectedTextIds) { final matches = page.textBlocks.where((t) => t.id == id); if (matches.isNotEmpty && (matches.first.position - localPos).distance < 50.0) { hitSelected = true; break; } }
                                                  if (hitSelected) { controller.isMovingStrokes = true; controller.lastPanOffset = localPos; } else { controller.isMovingStrokes = false; controller.selectionRectStart = localPos; controller.selectionRectEnd = localPos; controller.selectedStrokeIds.clear(); controller.selectedTextIds.clear(); controller.safeNotify(); }
                                                } else if (controller.currentTool == ToolMode.eraser) { controller.startEraserDrag(page); controller.eraseAtPosition(localPos, page); }
                                              } : null,
                                              onPanUpdate: !isBlocked ? (details) {
                                                final localPos = details.localPosition; controller.broadcastPointer(localPos);
                                                if (controller.isBroadcastingViewport) {
                                                  controller.currentViewportCenter = localPos;
                                                }
                                                if (controller.currentTool == ToolMode.draw) {
                                                  final list = controller.activePointsNotifier.value;
                                                  if (list.isEmpty || (localPos - list.last).distance > 1.5) {
                                                    final newList = List<Offset>.from(list)..add(localPos); controller.activePointsNotifier.value = newList; final now = DateTime.now();
                                                    if (now.difference(_lastBroadcastTime).inMilliseconds > 25 && controller.isRealtimeActive && controller.liveNotebookSid != null && myUserId.isNotEmpty) {
                                                      final newPoints = newList.sublist(_lastBroadcastedPointIndex);
                                                      if (newPoints.isNotEmpty) {
                                                        controller.sendStrokeUpdate(pageClientId: page.clientId, pageNumber: page.pageNumber, strokeId: _liveStrokeId!, points: newPoints, isFinal: false); _lastBroadcastedPointIndex = newList.length; _lastBroadcastTime = now;
                                                      }
                                                    }
                                                  }
                                                } else if (controller.currentTool == ToolMode.select) {
                                                  if (controller.isMovingStrokes && controller.lastPanOffset != null) { final delta = localPos - controller.lastPanOffset!; controller.moveSelectedStrokes(page, delta); controller.lastPanOffset = localPos; } else if (controller.selectionRectStart != null) { controller.updateSelectionRect(page, localPos); }
                                                } else if (controller.currentTool == ToolMode.eraser) {
                                                  controller.eraseAtPosition(localPos, page);
                                                }
                                              } : null,
                                              onPanEnd: !isBlocked ? (details) async {
                                                if (controller.currentTool == ToolMode.draw) {
                                                  final allPoints = controller.activePointsNotifier.value;
                                                  if (allPoints.isNotEmpty && _liveStrokeId != null) {
                                                    final newStroke = Stroke(id: _liveStrokeId!, color: controller.selectedColorHex, thickness: controller.selectedThickness, points: List.from(allPoints)); controller.addStroke(page, newStroke); controller.activePointsNotifier.value = []; controller.activeDrawingPageNumber = null; controller.setUserActivity('idle'); _liveStrokeId = null;
                                                  }
                                                } else if (controller.currentTool == ToolMode.select) {
                                                  controller.finalizeSelectionMovement(page);
                                                } else if (controller.currentTool == ToolMode.eraser) {
                                                  controller.endEraserDrag(page);
                                                }
                                              } : null,
                                              child: Stack(
                                                fit: StackFit.expand,
                                                children: [
                                                  ValueListenableBuilder<Map<String, Stroke>>(valueListenable: controller.remoteLiveStrokes, builder: (context, remoteMap, _) => RepaintBoundary(child: CustomPaint(size: pSize, painter: RemoteLiveStrokesPainter(liveStrokes: remoteMap, targetPageNumber: page.pageNumber, isAuthorColorEnabled: controller.isAuthorColorEnabled, userColors: controller.userColorsMap)))),
                                                  ValueListenableBuilder<List<Offset>>(valueListenable: controller.activePointsNotifier, builder: (context, points, _) {
                                                    if (controller.activeDrawingPageNumber != page.pageNumber) {
                                                      return const SizedBox.shrink();
                                                    }
                                                    Color visualColor = Color(int.parse(controller.selectedColorHex.replaceFirst('#', '0xFF')));
                                                    if (controller.isAuthorColorEnabled) {
                                                      visualColor = controller.userColorsMap[controller.myUserId] ?? visualColor;
                                                    }
                                                    return CustomPaint(size: pSize, painter: ActiveStrokePainter(currentPoints: points, visualColor: visualColor, currentThickness: controller.selectedThickness));
                                                  }),
                                                  ValueListenableBuilder<Map<String, dynamic>>(valueListenable: controller.remotePointers, builder: (context, pointers, _) => RepaintBoundary(child: CustomPaint(size: pSize, painter: RemotePointersPainter(pointers: pointers, onlineUsers: controller.onlineUsers, targetPageNumber: page.pageNumber)))),
                                                  if (page.isFrozen) IgnorePointer(child: Container(decoration: BoxDecoration(color: Colors.blueGrey.withValues(alpha: 0.03)), child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.lock_outline_rounded, size: 80, color: Colors.blueGrey.withValues(alpha: 0.1)), const SizedBox(height: 10), Text('PÁGINA CONGELADA', style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.blueGrey.withValues(alpha: 0.1), letterSpacing: 4))])))),
                                                  ...page.textBlocks.where((t) => !t.isDeleted).map((tb) {
                                                    final bool isEditing = controller.activeTextBlock?.id == tb.id && controller.activeInlineTarget == InlineTarget.block; final double exactLineMulti = controller.liveLineSpacing / tb.fontSize; final bool isTextSelected = controller.selectedTextIds.contains(tb.id); final String? editedBy = controller.remoteEditingBlocks[tb.id]; final String? editorName = editedBy != null ? controller.onlineUsers.firstWhere((u) => u['id'].toString() == editedBy, orElse: () => {})['name'] : null; const double hitboxPadding = 15.0;
                                                    return Positioned(
                                                      left: tb.position.dx - hitboxPadding, top: tb.position.dy - hitboxPadding, width: (pSize.width - tb.position.dx - 20.0).clamp(60.0, pSize.width) + (hitboxPadding * 2),
                                                      child: IgnorePointer(
                                                        ignoring: controller.currentTool != ToolMode.text,
                                                        child: Stack(
                                                          clipBehavior: Clip.none,
                                                          children: [
                                                            GestureDetector(
                                                              behavior: HitTestBehavior.opaque,
                                                              onPanUpdate: controller.currentTool == ToolMode.text && !isEditing && controller.currentUserRole != 'viewer' && editedBy == null ? (d) {
                                                                tb.position += d.delta;
                                                                if (controller.isBroadcastingViewport) {
                                                                  controller.currentViewportCenter = tb.position;
                                                                }
                                                                controller.safeNotify(); controller.broadcastThrottledTextBlockUpdate(page, tb);
                                                              } : null,
                                                              onTapDown: controller.currentTool == ToolMode.text && !isEditing && controller.currentUserRole != 'viewer' && editedBy == null ? (_) {
                                                                if (controller.activeInlineTarget != InlineTarget.none) {
                                                                  _finishEditingInline(page);
                                                                }
                                                                if (!controller.selectedTextIds.contains(tb.id)) {
                                                                  setState(() {
                                                                    controller.selectedTextIds.clear();
                                                                    controller.selectedStrokeIds.clear();
                                                                    controller.selectedImageIds.clear();
                                                                    controller.selectedTextIds.add(tb.id);
                                                                  });
                                                                  return;
                                                                }
                                                                _originalTextState = tb.clone(); controller.setTextEditing(InlineTarget.block, tb); _textController.text = tb.text; Future.delayed(const Duration(milliseconds: 50), () {
                                                                  if (mounted) {
                                                                    _textFocusNode.requestFocus();
                                                                  }
                                                                });
                                                              } : null,
                                                              onLongPress: () {
                                                                if (!isEditing) {
                                                                  controller.copyToClipboard(tb.text, context);
                                                                }
                                                              },
                                                              child: isEditing ? Container(margin: const EdgeInsets.all(hitboxPadding), width: double.infinity, decoration: BoxDecoration(border: Border.all(color: const Color(0xFF0F4C5C).withValues(alpha: 0.2), width: 1), color: Colors.white.withValues(alpha: 0.1)), child: TextField(key: ValueKey('edit_${tb.id}'), controller: _textController, focusNode: _textFocusNode, maxLines: null, autofocus: true, cursorColor: const Color(0xFF0F4C5C), keyboardType: TextInputType.multiline, textInputAction: TextInputAction.newline, style: GoogleFonts.inter(fontSize: tb.fontSize, height: exactLineMulti, color: Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF'))), fontWeight: tb.isBold ? FontWeight.bold : FontWeight.normal, fontStyle: tb.isItalic ? FontStyle.italic : FontStyle.normal, decoration: tb.isUnderline ? TextDecoration.underline : TextDecoration.none), decoration: InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.only(left: tb.isChecklist ? 22 : 0), hintText: 'Digitar...', hintStyle: const TextStyle(color: Colors.black12, fontSize: 14)), onChanged: (val) { tb.text = val; controller.safeNotify(); controller.broadcastTextBlockUpdate(page, tb, senderId: myUserId, debounced: true, isEditing: true); })) : Container(width: double.infinity, padding: const EdgeInsets.all(hitboxPadding), decoration: BoxDecoration(border: isTextSelected ? Border.all(color: const Color(0xFF1976D2), width: 1.5) : (editedBy != null ? Border.all(color: Colors.orange.withValues(alpha: 0.5), width: 1) : (controller.currentTool == ToolMode.text ? Border.all(color: Colors.blueAccent.withValues(alpha: 0.15)) : null)), color: isTextSelected ? const Color(0x1F1976D2) : (editedBy != null ? Colors.orange.withValues(alpha: 0.05) : Colors.transparent)), child: tb.isChecklist ? Column(crossAxisAlignment: CrossAxisAlignment.start, children: tb.text.split('\n').asMap().entries.map((entry) { final int idx = entry.key; final String line = entry.value; final bool isChecked = tb.checkedLineIndices.contains(idx); return Row(crossAxisAlignment: CrossAxisAlignment.center, children: [GestureDetector(onTap: controller.currentUserRole != 'viewer' ? () => controller.toggleLineChecked(tb, idx) : null, child: Padding(padding: const EdgeInsets.only(right: 6, bottom: 2), child: Icon(isChecked ? Icons.check_box : Icons.check_box_outline_blank, size: tb.fontSize * 1.1, color: isChecked ? const Color(0xFF0F4C5C) : Colors.black26))), Expanded(child: Text(line, style: GoogleFonts.inter(fontSize: tb.fontSize, height: exactLineMulti, color: Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF'))).withValues(alpha: isChecked ? 0.4 : 1.0), fontWeight: tb.isBold ? FontWeight.bold : FontWeight.normal, fontStyle: tb.isItalic ? FontStyle.italic : FontStyle.normal, decoration: isChecked ? TextDecoration.lineThrough : (tb.isUnderline ? TextDecoration.underline : TextDecoration.none))))]); }).toList()) : Text(tb.text, style: GoogleFonts.inter(fontSize: tb.fontSize, height: exactLineMulti, color: Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF'))), fontWeight: tb.isBold ? FontWeight.bold : FontWeight.normal, fontStyle: tb.isItalic ? FontStyle.italic : FontStyle.normal, decoration: tb.isUnderline ? TextDecoration.underline : TextDecoration.none))),
                                                            ),
                                                            if (editorName != null) Positioned(top: -14, left: 0, child: Container(padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1), decoration: BoxDecoration(color: Colors.orange, borderRadius: BorderRadius.circular(4)), child: Text('A editar: $editorName', style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)))),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  }),
                                                  Positioned(
                                                    top: 25, left: 0, right: 0,
                                                    child: IgnorePointer(
                                                      ignoring: controller.currentTool != ToolMode.text,
                                                      child: Column(
                                                        children: [
                                                          Builder(builder: (context) {
                                                            final String? editorId = controller.remoteEditingTitles[page.pageNumber];
                                                            if (editorId == null) {
                                                              return const SizedBox(height: 18);
                                                            }
                                                            final String editorName = controller.onlineUsers.firstWhere((u) => u['id'].toString() == editorId, orElse: () => {'name': 'Alguém'})['name']; return Padding(padding: const EdgeInsets.only(bottom: 2), child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 1), decoration: BoxDecoration(color: Colors.orange.shade800, borderRadius: BorderRadius.circular(4)), child: Text('A editar título: $editorName', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold))));
                                                          }),
                                                          Container(
                                                            margin: const EdgeInsets.symmetric(horizontal: 40), 
                                                            padding: EdgeInsets.zero,
                                                            child: Center(
                                                              child: controller.activeInlineTarget == InlineTarget.title 
? TextField(controller: _textController, focusNode: _textFocusNode, autofocus: true, textAlign: TextAlign.center, style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24)), decoration: const InputDecoration(border: InputBorder.none, hintText: 'Título da Folha...', isDense: true), onChanged: (val) { page.title = val; controller.broadcastThrottledPageMetadataUpdate(page, isEditing: true); }, onSubmitted: (_) { _finishEditingInline(page); controller.broadcastPageMetadataUpdate(page, isEditing: false); }) 
: GestureDetector(onTap: controller.currentTool == ToolMode.text && controller.currentUserRole != 'viewer' ? () {
                                                            if (controller.activeInlineTarget != InlineTarget.none) {
                                                              _finishEditingInline(page);
                                                            }
                                                            controller.setTextEditing(InlineTarget.title); _textController.text = page.title; _textFocusNode.requestFocus(); controller.broadcastPageMetadataUpdate(page, isEditing: true);
                                                          } : null, child: Text(page.title.isEmpty ? (controller.currentTool == ToolMode.text && controller.currentUserRole != 'viewer' ? '[ Escrever Título ]' : '') : page.title, textAlign: TextAlign.center, style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.bold, color: page.title.isEmpty ? Colors.black12 : const Color(0xFF1A1A24)))))),
                                                        ],
                                                      ),
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      );
                    },
                  ),

                  if (controller.currentUserRole != 'viewer' && !controller.isFocusMode)
                    Positioned(
                      bottom: 20, left: 0, right: 0,
                      child: Center(
                        child: controller.activeInlineTarget != InlineTarget.none
                            ? _buildInlineEditingToolbar(controller, currentPage!)
                            : CanvasToolbar(
                                controller: controller, currentPage: currentPage!,
                                onColorTap: () => _showColorStudioDialog(controller, isForText: false),
                                onThicknessTap: () => _showThicknessStudioDialog(controller),
                                onChangePaperTap: () => _showPaperStyleStudioDialog(controller),
                                onDeletePageTap: () => _confirmDeletePage(controller, controller.pages[controller.currentPageIndex], controller.currentPageIndex),
                                onAiAssistantTap: () => _showAiAssistantSheet(controller, currentPage),
                              ),
                      ),
                    ),

                  if (controller.isFocusMode)
                    Positioned(bottom: 30, right: 20, child: FloatingActionButton.small(backgroundColor: const Color(0xFF0F4C5C), onPressed: () => controller.toggleFocusMode(), child: const Icon(Icons.fullscreen_exit, color: Colors.white))),

                  if (controller.isLiveSessionActive && !controller.isFocusMode && controller.onlineUsers.length > 1)
                    Positioned(
                      top: 16, left: 0, right: 0, 
                      child: Center(
                      child: LiveVoiceCockpit(
                        onlineUsers: controller.onlineUsers, 
                        userAudioLevels: controller.userAudioLevels, 
                        userReactions: controller.userReactions, 
                        followingUserId: controller.followingUserId, 
                        myUserId: myUserId, 
                        canSpeak: controller.canSpeak,
                        isSpeakerOn: controller.isSpeakerOn, 
                        isRecording: controller.isRecording, 
                        isLoading: controller.isConnectingVoice, 
                        isBroadcasting: controller.isBroadcastingViewport, 
                        isHandRaised: controller.isMyHandRaised, 
                        onSpeakerToggle: controller.toggleSpeaker, 
                        onMicTap: controller.handleLiveAudioAction, 
                        onHandToggle: () => controller.toggleHandRaise(), 
                        onBroadcastToggle: () { 
                          if (controller.isBroadcastingViewport) {
                            controller.stopViewportBroadcasting(); 
                          } else {
                            controller.startViewportBroadcasting(myUserId); 
                          }
                        }, 
                        onReactionSend: (emoji) => controller.sendReaction(emoji), 
                        onUserTap: (uid) => controller.toggleFollowUser(uid, myUserId), 
                        onHangUp: () => controller.toggleVoiceCall(myUserId)
                      )
                    )
                  ),

                  if (!controller.isFocusMode) ...[
                    Positioned(bottom: MediaQuery.of(context).viewInsets.bottom > 0 ? 4 : 120, right: 16, child: const CollaborationChatWidget()),
                    if (controller.followingUserId != null) Positioned(top: 80, left: 20, child: _buildStatusBadge(icon: Icons.visibility, label: 'A assistir colega...', color: Colors.green, onClose: () => controller.toggleFollowUser(null, myUserId))),
                    if (controller.isBroadcastingViewport) Positioned(top: 80, right: 20, child: _buildStatusBadge(icon: Icons.sensors, label: 'A transmitir a minha visão', color: Colors.redAccent, onClose: () => controller.stopViewportBroadcasting())),
                    if (controller.remoteUploadingUsers.isNotEmpty) Positioned(top: 130, right: 20, child: _buildStatusBadge(icon: Icons.cloud_upload, label: '${controller.remoteUploadingUsers.length} colega(s) a carregar imagens...', color: Colors.blueGrey, onClose: () {})),
                  ],

                  if (controller.isUploadingImage) Positioned.fill(child: Container(color: Colors.black.withValues(alpha: 0.3), child: Center(child: Card(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20), child: Column(mainAxisSize: MainAxisSize.min, children: [const CircularProgressIndicator(color: Color(0xFF0F4C5C)), const SizedBox(height: 16), Text('A enviar imagem...', style: GoogleFonts.inter(fontWeight: FontWeight.bold)), Text('Isto poupa largura de banda para todos.', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54))])))))),

                  if (!controller.isFocusMode)
                    Positioned(
                      top: 100, left: 20, right: 20,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (controller.pendingInvite != null) Padding(padding: const EdgeInsets.only(bottom: 8), child: _buildInviteBanner(controller)),
                          if (controller.incomingVoiceCall != null) _buildVoiceInviteBanner(controller, controller.incomingVoiceCall!)
                          else if (controller.isAnyUserInVoice && !controller.isLiveSessionActive) _buildVoiceInviteBanner(controller, controller.firstActiveVoiceUser!),
                        ],
                      ),
                    ),

                  if (controller.isGlobalSyncing && !controller.isFocusMode) Positioned(top: 60, left: 0, right: 0, child: Center(child: _buildGlobalSyncBadge())),

                  if (!controller.isFocusMode && controller.currentTemplateType == 'study' && controller.pages.isNotEmpty)
                    Positioned(
                      top: 60, right: 16,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (controller.pages[controller.currentPageIndex].extractedText != null) _buildMiniBadge(icon: Icons.auto_awesome, label: 'OCR PRONTO', color: Colors.amber.shade700, onTap: () => controller.generateAiSummary(controller.pages[controller.currentPageIndex])),
                          const SizedBox(height: 8),
                          _buildMiniBadge(icon: Icons.library_music_rounded, label: '${controller.lessonRecordings.length} GRAVAÇÕES', color: const Color(0xFF0F4C5C), onTap: () => _showRecordingsSheet(controller)),
                        ],
                      ),
                    ),
                ],
              ),
        floatingActionButton: (hasPages || controller.currentUserRole == 'viewer' || controller.isFocusMode)
            ? null
            : FloatingActionButton(backgroundColor: const Color(0xFF0F4C5C), foregroundColor: Colors.white, onPressed: () => _showAddPageDialog(controller), child: const Icon(Icons.note_add)),
      ),
    );
  }

  AppBar _buildAppBar(CanvasController controller, bool hasPages) {
    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Builder(
        builder: (scaffoldContext) => InkWell(
          onTap: hasPages ? () => Scaffold.of(scaffoldContext).openEndDrawer() : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  widget.notebook.title, 
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasPages) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A24).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${controller.currentPageIndex + 1} / ${controller.pages.length}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24)),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                controller.hasUnsyncedChanges ? Icons.cloud_off : Icons.cloud_done,
                size: 16,
                color: controller.hasUnsyncedChanges ? Colors.orange : Colors.green,
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFDFBF7),
      foregroundColor: const Color(0xFF1A1A24),
      actions: [
        if (hasPages) ...[
          IconButton(
            icon: const Icon(Icons.people_alt_outlined), 
            onPressed: () => _showCollaborationCenter(controller)
          ),
          Builder(
            builder: (scaffoldContext) => IconButton(
              icon: const Icon(Icons.menu_open_rounded),
              onPressed: () => Scaffold.of(scaffoldContext).openEndDrawer(),
              tooltip: 'Lista de Folhas',
            ),
          ),
        ]
      ],
    );
  }

  Widget _buildPageDrawer(CanvasController controller) {
    final themeColor = const Color(0xFF0F4C5C);
    
    return Drawer(
      backgroundColor: const Color(0xFFFDFBF7),
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          // 🚀 CABEÇALHO PREMIUM COM GRADIENTE
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [themeColor, themeColor.withValues(alpha: 0.85)],
              ),
              boxShadow: [
                BoxShadow(
                  color: themeColor.withValues(alpha: 0.3),
                  blurRadius: 15,
                  offset: const Offset(0, 5),
                )
              ],
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 32),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white24),
                          ),
                          child: Text(
                            '${controller.pages.length} Folhas',
                            style: const TextStyle(
                              color: Colors.white, 
                              fontSize: 12, 
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'FOLHAS DO CADERNO',
                      style: GoogleFonts.inter(
                        color: Colors.white60, 
                        fontSize: 11, 
                        fontWeight: FontWeight.w900, 
                        letterSpacing: 2.0
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      widget.notebook.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lora(
                        color: Colors.white, 
                        fontSize: 22, 
                        fontWeight: FontWeight.bold,
                        height: 1.2
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: controller.pages.length,
              itemBuilder: (context, index) {
                final page = controller.pages[index];
                final bool isCurrent = controller.currentPageIndex == index;
                
                // Tradução de tipos de papel
                String lineLabel = 'Lisa';
                if (widget.notebook.lineType == 'ruled') lineLabel = 'Pautada';
                else if (widget.notebook.lineType == 'grid') lineLabel = 'Quadriculada';
                else if (widget.notebook.lineType == 'dots') lineLabel = 'Pontilhada';
                else if (widget.notebook.lineType == 'oblique') lineLabel = 'Caligrafia';

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
                  child: ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                    tileColor: isCurrent ? themeColor.withValues(alpha: 0.06) : Colors.transparent,
                    leading: AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      width: 44, height: 44,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCurrent ? themeColor : Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isCurrent ? themeColor : Colors.black.withValues(alpha: 0.05),
                          width: 1.5
                        ),
                        boxShadow: isCurrent ? [
                          BoxShadow(color: themeColor.withValues(alpha: 0.2), blurRadius: 8, offset: const Offset(0, 3))
                        ] : null,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: TextStyle(
                          color: isCurrent ? Colors.white : Colors.black87,
                          fontWeight: FontWeight.w900,
                          fontSize: 16
                        ),
                      ),
                    ),
                    title: Text(
                      page.title.isEmpty ? 'Página ${index + 1}' : page.title,
                      style: GoogleFonts.inter(
                        fontWeight: isCurrent ? FontWeight.w800 : FontWeight.w600,
                        fontSize: 15,
                        color: isCurrent ? themeColor : const Color(0xFF1A1A24),
                      ),
                    ),
                    subtitle: Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Row(
                        children: [
                          _buildMiniSpecBadge(page.paperSize),
                          const SizedBox(width: 6),
                          _buildMiniSpecBadge(lineLabel),
                          if (page.isFrozen) ...[
                            const SizedBox(width: 8),
                            const Icon(Icons.lock_rounded, size: 14, color: Colors.orange),
                          ],
                        ],
                      ),
                    ),
                    trailing: isCurrent 
                      ? Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(color: themeColor, shape: BoxShape.circle),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        )
                      : null,
                    onTap: () {
                      controller.jumpToPage(index);
                      Navigator.pop(context);
                    },
                  ),
                );
              },
            ),
          ),
          
          // 🚀 BOTÃO DE NOVA FOLHA ELEGANTE
          if (controller.currentUserRole != 'viewer')
            Padding(
              padding: const EdgeInsets.all(24),
              child: Container(
                width: double.infinity,
                height: 56,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: themeColor.withValues(alpha: 0.2),
                      blurRadius: 12,
                      offset: const Offset(0, 6)
                    )
                  ],
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    _showAddPageDialog(controller);
                  },
                  icon: const Icon(Icons.add_circle_outline_rounded, size: 22),
                  label: const Text('ADICIONAR FOLHA', style: TextStyle(fontWeight: FontWeight.w900, letterSpacing: 1.1)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: themeColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMiniSpecBadge(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.04),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 0.5),
      ),
    );
  }

  Widget _buildInlineEditingToolbar(CanvasController controller, LocalPage page) {
    final bool isTitle = controller.activeInlineTarget == InlineTarget.title;
    final tb = controller.activeTextBlock;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: const Icon(Icons.check_circle_outline, color: Colors.green), 
            onPressed: () => _finishEditingInline(page),
            tooltip: 'Confirmar',
          ),
          if (!isTitle && tb != null) ...[
            Container(width: 1, height: 20, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildToolbarToggle(
              icon: Icons.format_bold, 
              isActive: tb.isBold, 
              onTap: () => controller.toggleBold(),
            ),
            _buildToolbarToggle(
              icon: Icons.format_italic, 
              isActive: tb.isItalic, 
              onTap: () => controller.toggleItalic(),
            ),
            _buildToolbarToggle(
              icon: Icons.format_underlined, 
              isActive: tb.isUnderline, 
              onTap: () => controller.toggleUnderline(),
            ),
            _buildToolbarToggle(
              icon: Icons.checklist_rtl_rounded, 
              isActive: tb.isChecklist, 
              onTap: () => controller.toggleChecklist(),
            ),
            Container(width: 1, height: 20, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
          ],
          IconButton(
            icon: const Icon(Icons.text_format, color: Color(0xFF1A1A24)), 
            onPressed: () => _showColorStudioDialog(controller, isForText: true),
            tooltip: 'Cor do Texto',
          ),
        ],
      ),
    );
  }

  Widget _buildToolbarToggle({required IconData icon, required bool isActive, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F4C5C).withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon, 
          size: 20, 
          color: isActive ? const Color(0xFF0F4C5C) : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildStatusBadge({required IconData icon, required String label, required Color color, required VoidCallback onClose}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: Colors.white),
          const SizedBox(width: 8),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          GestureDetector(onTap: onClose, child: const Icon(Icons.close, size: 14, color: Colors.white70)),
        ],
      ),
    );
  }

  Widget _buildMiniBadge({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)]),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: Colors.white),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildGlobalSyncBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFF0F4C5C), borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 6)]),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
          const SizedBox(width: 8),
          Text('Sincronizando...', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.insert_page_break_outlined, size: 80, color: Colors.black.withValues(alpha: 0.1)), const SizedBox(height: 16), Text('Este caderno está vazio.\nClique no botão flutuante para criar a primeira folha.', textAlign: TextAlign.center, style: GoogleFonts.inter(color: Colors.black45, fontSize: 16))]));
  }

  void _showAddPageDialog(CanvasController controller) {
    bool isLand = false;
    String pSize = 'A4';
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFFFDFBF7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Nova Folha', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
          content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Tamanho do Papel:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              initialValue: pSize,
              decoration: InputDecoration(contentPadding: const EdgeInsets.symmetric(horizontal: 12), border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
              items: ['A0', 'A1', 'A2', 'A3', 'A4', 'A5'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
              onChanged: (v) => setModalState(() => pSize = v!),
            ),
            const SizedBox(height: 20),
            Text('Orientação:', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: Colors.black54, fontSize: 13)),
            const SizedBox(height: 8),
            Row(children: [
                Expanded(child: ChoiceChip(label: const Text('Retrato'), selected: !isLand, onSelected: (s) => setModalState(() => isLand = !s))),
                const SizedBox(width: 8),
                Expanded(child: ChoiceChip(label: const Text('Paisagem'), selected: isLand, onSelected: (s) => setModalState(() => isLand = s))),
            ]),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.black45))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), onPressed: () { controller.addNewPage(isLand, paperSize: pSize); Navigator.pop(context); }, child: const Text('Criar Folha', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  void _showColorStudioDialog(CanvasController controller, {bool isForText = false}) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF7), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(isForText ? 'Cor do Texto' : 'Paleta da Caneta', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
        content: SizedBox(
          width: 320,
          child: Wrap(
            spacing: 12, runSpacing: 12, alignment: WrapAlignment.center,
            children: _colorPalette.entries.map((entry) {
              final hex = '#${entry.value.toARGB32().toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              final bool isSelected = isForText ? controller.activeTextBlock?.textColorHex == hex : controller.selectedColorHex == hex;
              return GestureDetector(
                  onTap: () {
                    if (isForText) {
                      controller.setTextColor(hex);
                    } else {
                      controller.setColor(hex);
                    }
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? const Color(0xFF0F4C5C) : Colors.transparent, width: 2), boxShadow: isSelected ? [BoxShadow(color: entry.value.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2))] : null),
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
                Row(mainAxisAlignment: MainAxisAlignment.center, children: [CircleAvatar(radius: (tempThickness / 1.5).clamp(1.5, 14.0), backgroundColor: currentColor), const SizedBox(width: 12), Text('${tempThickness.toInt()} px', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold))]),
                const SizedBox(height: 12),
                Slider(value: tempThickness, min: 1.0, max: 30.0, activeColor: const Color(0xFF0F4C5C), onChanged: (val) => setModalState(() => tempThickness = val)),
                const SizedBox(height: 8),
                Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: quickPresets.map((preset) {
                    final bool isSelected = tempThickness == preset;
                    return InkWell(
                      onTap: () => setModalState(() => tempThickness = preset),
                      child: Container(width: 38, height: 34, alignment: Alignment.center, decoration: BoxDecoration(color: isSelected ? const Color(0xFF0F4C5C) : Colors.black.withValues(alpha: 0.04), borderRadius: BorderRadius.circular(8)), child: Text('${preset.toInt()}', style: TextStyle(color: isSelected ? Colors.white : Colors.black87))),
                    );
                }).toList()),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C)), onPressed: () { controller.setThickness(tempThickness); Navigator.pop(context); }, child: const Text('Aplicar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
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
        content: StatefulBuilder(
          builder: (context, setModalState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildPaperOption(controller, 'ruled', 'Pautado (28px)', Icons.view_headline), const SizedBox(height: 8),
                _buildPaperOption(controller, 'grid', 'Quadriculado (25px)', Icons.grid_4x4), const SizedBox(height: 8),
                _buildPaperOption(controller, 'dots', 'Pontilhado (Dots)', Icons.more_horiz), const SizedBox(height: 8),
                _buildPaperOption(controller, 'oblique', 'Oblíquo (Caligrafia)', Icons.text_rotation_angleup), const SizedBox(height: 16),
                Text('Espaçamento: ${controller.liveLineSpacing.toInt()}px', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
                Slider(
                  value: controller.liveLineSpacing.clamp(10.0, 100.0), min: 10, max: 100, divisions: 90, activeColor: const Color(0xFF0F4C5C),
                  onChanged: controller.liveLineType == 'blank' ? null : (val) { setModalState(() { controller.liveLineSpacing = val; }); controller.setLineSpacing(val, controller.pages[controller.currentPageIndex]); },
                ),
                const SizedBox(height: 8),
                _buildPaperOption(controller, 'blank', 'Liso / Em Branco', Icons.check_box_outline_blank),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildPaperOption(CanvasController controller, String type, String label, IconData icon) {
    final bool isSelected = controller.liveLineType == type;
    final currentPage = controller.pages[controller.currentPageIndex];
    return InkWell(
      onTap: () { controller.setLineType(type, currentPage); Navigator.pop(context); },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(color: isSelected ? const Color(0xFF0F4C5C).withValues(alpha: 0.12) : Colors.transparent, borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? const Color(0xFF0F4C5C) : Colors.black12, width: 1.5)),
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

  Widget _buildInviteBanner(CanvasController controller) {
    final invite = controller.pendingInvite!;
    return Card(
      elevation: 8, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), color: const Color(0xFF0F4C5C),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.bolt, color: Colors.orangeAccent),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text('Sessão ao Vivo Iniciada!', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)), Text('${invite['sender_name'] ?? 'Um colega'} começou a desenhar agora.', style: GoogleFonts.inter(color: Colors.white70, fontSize: 12))])),
            TextButton(onPressed: () => controller.dismissInvite(), child: const Text('Negar', style: TextStyle(color: Colors.white60))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent, foregroundColor: Colors.black), onPressed: () {
              if (controller.isCollaborationEnabled) {
                controller.acceptInvite();
              } else {
                controller.toggleCollaboration(true, suppressBroadcast: true).then((_) => controller.acceptInvite());
              }
            }, child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  Widget _buildVoiceInviteBanner(CanvasController controller, Map<String, dynamic> data) {
    return Card(
      elevation: 10, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), color: const Color(0xFF27AE60), 
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            const Icon(Icons.record_voice_over, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, mainAxisSize: MainAxisSize.min, children: [Text('Conversa de Voz!', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)), Text('${data['sender_name'] ?? data['name'] ?? 'Um colega'} está em Live.', style: GoogleFonts.inter(color: Colors.white.withValues(alpha: 0.8), fontSize: 12))])),
            TextButton(onPressed: () => controller.dismissVoiceCall(userId: data['id']?.toString()), child: const Text('Negar', style: TextStyle(color: Colors.white70))),
            ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF27AE60), padding: const EdgeInsets.symmetric(horizontal: 16)), onPressed: () {
              if (controller.isCollaborationEnabled) {
                controller.acceptVoiceCall();
              } else {
                controller.toggleCollaboration(true, suppressBroadcast: true).then((_) => controller.acceptVoiceCall());
              }
            }, child: const Text('Aceitar', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePage(CanvasController controller, LocalPage page, int index) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Folha'),
        content: const Text('Tens a certeza que queres eliminar esta folha? Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          TextButton(
            onPressed: () {
              controller.deletePage(page);
              Navigator.pop(context);
            },
            child: const Text('Eliminar', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
