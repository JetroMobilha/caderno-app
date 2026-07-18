import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/realtime_service.dart';
import '../../../core/network/sync_service.dart';
import '../../../core/network/webrtc_service.dart';
import '../models/image_block_model.dart';
import '../models/local_page_model.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../repositories/canvas_repository.dart';

enum ToolMode { draw, pan, select, text, eraser, insertImage, imageEdit }
enum InlineTarget { none, block, title, footer }

class CanvasController extends ChangeNotifier {
  final CanvasRepository _repository = CanvasRepository();

  List<LocalPage> pages = [];
  int currentPageIndex = 0;
  bool isLoading = true;

  int? liveNotebookSid;
  int currentNotebookId = 0;
  String currentPaperSize = 'A4';
  late String liveLineType;
  String currentUserRole = 'viewer';

  ToolMode currentTool = ToolMode.draw;
  InlineTarget activeInlineTarget = InlineTarget.none;
  TextBlock? activeTextBlock;

  String selectedColorHex = '#2C3E50';
  double selectedThickness = 3.0;

  final Set<String> selectedStrokeIds = {};
  final Set<String> selectedTextIds = {};

  Offset? selectionRectStart;
  Offset? selectionRectEnd;
  bool isMovingStrokes = false;
  Offset? lastPanOffset;

  bool isRealtimeActive = false;
  bool isInVoiceCall = false;
  bool isMuted = false;
  bool isSpeakerOn = true;
  List<Map<String, dynamic>> onlineUsers = [];

  StreamSubscription? _usersSubscription;
  StreamSubscription? _strokesSubscription;

  final List<Color> avatarColorsPool = [
    const Color(0xFFE67E22), const Color(0xFF9B59B6), const Color(0xFF27AE60),
    const Color(0xFF2980B9), const Color(0xFFE74C3C), const Color(0xFF1ABC9C),
  ];

  // 🚀
  final ValueNotifier<Map<String, Stroke>> remoteLiveStrokes = ValueNotifier({});
  final ValueNotifier<List<Offset>> activePointsNotifier = ValueNotifier([]);
  late TransformationController transformationController;
  final PageController pageController = PageController(initialPage: 0);

  CanvasController() {
    transformationController = TransformationController();
    SyncService.syncedPagesRadio.addListener(_onPageSyncedByRadar);
    SyncService.syncedNoteBooksRadio.addListener(_onNoteBookSyncedByRadar);
  }

  @override
  void dispose() {
    activePointsNotifier.dispose();
    transformationController.dispose();
    pageController.dispose();
    _usersSubscription?.cancel();
    _strokesSubscription?.cancel();
    SyncService.syncedPagesRadio.removeListener(_onPageSyncedByRadar);
    SyncService.syncedNoteBooksRadio.removeListener(_onNoteBookSyncedByRadar);
    if (liveNotebookSid != null) RealtimeService().leaveNotebookChannel(liveNotebookSid!);
    SyncService.isCollaborationActive = false;
    super.dispose();
  }

  Future<void> initNotebook(int notebookId, int? notebookSid, String lineType, String paperSize, String role) async {
    isLoading = true;
    currentNotebookId = notebookId;
    liveNotebookSid = kIsWeb ? notebookId : notebookSid;
    liveLineType = lineType;
    currentPaperSize = paperSize;
    currentUserRole = role;

    SyncService.isCollaborationActive = true;

    pages = await _repository.getPagesByNotebook(notebookId, liveNotebookSid);
    if (pages.isEmpty) {
      final firstPage = await _repository.createNewPage(notebookId, 1, false, liveNotebookSid);
      if (firstPage != null) {
        _resetZoomForPage(firstPage, paperSize);
        pages.add(firstPage);
      }
    } else {
      _resetZoomForPage(pages.first, paperSize);
    }
    isLoading = false;
    notifyListeners();

    if (liveNotebookSid != null && liveNotebookSid != 0) {
      initRealtimeCollaboration();
      isRealtimeActive = true;
      notifyListeners();
    }
  }

  void _resetZoomForPage(LocalPage page, String paperSize) {
    final double initialScale = (paperSize == 'A0' || paperSize == 'A1') ? 0.25 : 1.4;
    transformationController.value = Matrix4.identity()..scale(initialScale);
  }

  void setThickness(double thickness) {
    selectedThickness = thickness;
    notifyListeners();
  }

  void setColor(String hex) {
    selectedColorHex = hex;
    notifyListeners();
  }

  void setTextColor(String hex) {
    if (activeTextBlock != null) {
      activeTextBlock!.textColorHex = hex;
      notifyListeners();
    }
  }

  void setTextEditing(InlineTarget target, [TextBlock? block]) {
    activeInlineTarget = target;
    activeTextBlock = block;
    notifyListeners();
  }

  void initRealtimeCollaboration() async {
    final realtime = RealtimeService();
    await realtime.initConnection();
    final int channelId = (liveNotebookSid != null && liveNotebookSid != 0) ? liveNotebookSid! : currentNotebookId;
    await realtime.joinNotebookChannel(notebookId: channelId);

    _usersSubscription?.cancel();
    _usersSubscription = realtime.onUsersUpdated.listen((usersList) {
      onlineUsers = usersList.map((u) {
        final map = Map<String, dynamic>.from(u);
        return {
          'name': map['name'] ?? 'Colega',
          'color': avatarColorsPool[(map['id'] ?? 0) % avatarColorsPool.length],
          'isTalking': false,
        };
      }).toList();
      notifyListeners();
    });

    _strokesSubscription?.cancel();
    _strokesSubscription = realtime.onStrokeReceived.listen((data) {
      try {
        final int incomingPageNum = data['page_number'];
        final List<dynamic> rawStrokes = data['strokes'];
        if (pages.isEmpty) return;
        final LocalPage activePage = pages[currentPageIndex];

        if (activePage.pageNumber == incomingPageNum) {
          for (var strokeMap in rawStrokes) {
            final String strokeId = strokeMap['id'];
            final bool isFinal = strokeMap['is_final'] == true;

            final List<Offset> incomingPoints = (strokeMap['points'] as List)
                .map((pt) => Offset((pt['x'] as num).toDouble(), (pt['y'] as num).toDouble()))
                .toList();

            if (incomingPoints.isEmpty) continue;

            // 🟢 SE O TRAÇO AINDA ESTÁ NO AR (O colega está a arrastar o dedo)
            if (!isFinal) {
              final currentMap = Map<String, Stroke>.from(remoteLiveStrokes.value);

              if (currentMap.containsKey(strokeId)) {
                // Adiciona os novos pontos instantaneamente à camada rápida
                currentMap[strokeId]!.points.addAll(incomingPoints);
              } else {
                // Começa a desenhar o traço remoto na camada rápida
                currentMap[strokeId] = Stroke(
                  id: strokeId,
                  color: strokeMap['color'],
                  thickness: (strokeMap['thickness'] as num).toDouble(),
                  points: incomingPoints,
                );
              }

              // 🚀 Avisa APENAS a camada de tinta remota (0% de lag, sem redesenhar a folha inteira!)
              remoteLiveStrokes.value = currentMap;

            }
            // 🔴 SE O TRAÇO TERMINOU (O colega levantou o dedo)
            else {
              final currentMap = Map<String, Stroke>.from(remoteLiveStrokes.value);
              Stroke? completedStroke = currentMap.remove(strokeId);

              if (completedStroke != null) {
                completedStroke.points.addAll(incomingPoints);
              } else {
                completedStroke = Stroke(
                  id: strokeId,
                  color: strokeMap['color'],
                  thickness: (strokeMap['thickness'] as num).toDouble(),
                  points: incomingPoints,
                );
              }

              // Limpa da camada rápida
              remoteLiveStrokes.value = currentMap;

              // Carimba na folha estática em definitivo!
              activePage.strokes.add(completedStroke);
              notifyListeners(); // Aqui sim, fazemos 1 único rebuild final!

              if (currentUserRole == 'owner') triggerAutoSave(activePage);
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Erro ao processar tinta remota: $e');
      }
    });
  }

  Future<void> triggerAutoSave(LocalPage page) async {
    if (isRealtimeActive && currentUserRole != 'owner') return;
    await _repository.savePage(page, liveNotebookSid);
  }

  void switchTool(ToolMode newMode) {
    currentTool = newMode;
    if (newMode != ToolMode.select) {
      selectedStrokeIds.clear();
      selectedTextIds.clear();
      selectionRectStart = null;
      selectionRectEnd = null;
      isMovingStrokes = false;
    }
    notifyListeners();
  }

  void zoom(double factor, Size screenSize) {
    final Matrix4 matrix = transformationController.value;
    final double centerX = screenSize.width / 2;
    final double centerY = screenSize.height / 2;
    matrix.translate(centerX, centerY);
    matrix.scale(factor);
    matrix.translate(-centerX, -centerY);
    transformationController.value = matrix;
    notifyListeners();
  }

  void setLineType(String type) { liveLineType = type; notifyListeners(); }
  void setPageIndex(int index) { currentPageIndex = index; notifyListeners(); }

  Future<void> addNewPage(bool isLandscape) async {
    final newPage = LocalPage(notebookId: currentNotebookId, pageNumber: pages.length + 1, isLandscape: isLandscape);
    _resetZoomForPage(newPage, currentPaperSize);
    pages.add(newPage);
    notifyListeners();
    await triggerAutoSave(newPage);
    pageController.animateToPage(pages.length - 1, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
  }

  // =========================================================================
  // 🚀 APAGAR PÁGINA (Com destruição verdadeira e navegação corrigida)
  // =========================================================================
  void deleteCurrentPage() async {
    if (pages.length <= 1) return;

    final pageToDelete = pages[currentPageIndex];

    pages.removeAt(currentPageIndex);
    if (currentPageIndex >= pages.length) {
      currentPageIndex = pages.length - 1;
    }

    notifyListeners(); // Atualiza a UI primeiro

    // Força o salto do carrossel visual logo a seguir
    Future.microtask(() {
      if (pageController.hasClients) {
        pageController.jumpToPage(currentPageIndex);
      }
    });

    // 🔥 Queima a página definitivamente no disco!
    if (pageToDelete.id != null) {
      await _repository.deletePage(pageToDelete.id!);
    }

    if (pages.isNotEmpty) triggerAutoSave(pages[currentPageIndex]);
  }

  void eraseAtPosition(Offset pos, LocalPage page) {
    if (selectedStrokeIds.isNotEmpty || selectedTextIds.isNotEmpty) {
      page.strokes.removeWhere((s) => selectedStrokeIds.contains(s.id));
      page.textBlocks.removeWhere((t) => selectedTextIds.contains(t.id));
      selectedStrokeIds.clear();
      selectedTextIds.clear();
      notifyListeners();
      triggerAutoSave(page);
      return;
    }

    const double eraserRadius = 24.0;
    bool mudou = false;

    final List<Stroke> strokesToRemove = [];
    for (var stroke in page.strokes) {
      if (stroke.points.any((pt) => (pt - pos).distance < eraserRadius)) {
        strokesToRemove.add(stroke);
      }
    }
    if (strokesToRemove.isNotEmpty) {
      page.strokes.removeWhere((s) => strokesToRemove.contains(s));
      mudou = true;
    }

    final List<TextBlock> textsToRemove = [];
    for (var tb in page.textBlocks) {
      final Rect textHitBox = Rect.fromLTWH(tb.position.dx, tb.position.dy, 150, tb.fontSize * 1.5);
      if (textHitBox.contains(pos) || (tb.position - pos).distance < eraserRadius) {
        textsToRemove.add(tb);
      }
    }
    if (textsToRemove.isNotEmpty) {
      page.textBlocks.removeWhere((t) => textsToRemove.contains(t));
      mudou = true;
    }

    if (mudou) {
      notifyListeners();
      triggerAutoSave(page);
    }
  }

  void undo(LocalPage page) {
    if (page.strokes.isNotEmpty) {
      final removed = page.strokes.removeLast();
      page.redoHistory.add(removed);
      notifyListeners();
      triggerAutoSave(page);
    }
  }

  void redo(LocalPage page) {
    if (page.redoHistory.isNotEmpty) {
      final restored = page.redoHistory.removeLast();
      page.strokes.add(restored);
      notifyListeners();
      triggerAutoSave(page);
    }
  }

  Future<void> pickAndInsertImage(LocalPage page) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      final newImageBlock = ImageBlock(
          id: const Uuid().v4(),
          imagePath: pickedFile.path,
          position: const Offset(100, 150),
          width: 300.0,
          height: 200.0
      );
      page.imageBlocks.add(newImageBlock);
      currentTool = ToolMode.imageEdit;
      selectedStrokeIds.clear();
      selectedTextIds.clear();
      notifyListeners();
      if (!kIsWeb && page.id != null) {
        await _repository.saveSingleImageBlock(page.id!, newImageBlock);
      }
      await triggerAutoSave(page);
    }
  }

  void deleteImageBlock(LocalPage page, ImageBlock img) {
    page.imageBlocks.remove(img);
    notifyListeners();
    triggerAutoSave(page);
  }

  void updateSelectionRect(LocalPage page, Offset currentPos) {
    selectionRectEnd = currentPos;
    if (selectionRectStart != null && selectionRectEnd != null) {
      final rect = Rect.fromPoints(selectionRectStart!, selectionRectEnd!);
      selectedStrokeIds.clear();
      selectedTextIds.clear();

      for (var stroke in page.strokes) {
        if (stroke.points.any((pt) => rect.contains(pt))) selectedStrokeIds.add(stroke.id);
      }
      for (var tb in page.textBlocks) {
        if (rect.contains(tb.position)) selectedTextIds.add(tb.id);
      }
    }
    notifyListeners();
  }

  void moveSelectedStrokes(LocalPage page, Offset delta) {
    for (var id in selectedStrokeIds) {
      final matches = page.strokes.where((s) => s.id == id);
      if (matches.isNotEmpty) {
        final stroke = matches.first;
        for (int i = 0; i < stroke.points.length; i++) stroke.points[i] = stroke.points[i] + delta;
      }
    }
    for (var id in selectedTextIds) {
      final matches = page.textBlocks.where((t) => t.id == id);
      if (matches.isNotEmpty) matches.first.position = matches.first.position + delta;
    }
    notifyListeners();
  }

  void forceNotify() => notifyListeners();

  void _onPageSyncedByRadar() {
    if (pages.isEmpty) return;
    final Map<int, int> updates = SyncService.syncedPagesRadio.value;
    final LocalPage activePage = pages[currentPageIndex];
    if (activePage.id != null && updates.containsKey(activePage.id)) {
      activePage.serverId = updates[activePage.id]!;
      notifyListeners();
    }
  }

  void _onNoteBookSyncedByRadar() {
    if (liveNotebookSid != null && liveNotebookSid != 0 && !kIsWeb) return;
    final Map<int, int> updates = SyncService.syncedNoteBooksRadio.value;
    if (updates.containsKey(currentNotebookId)) {
      liveNotebookSid = updates[currentNotebookId]!;
      RealtimeService().leaveNotebookChannel(currentNotebookId);
      initRealtimeCollaboration();
      notifyListeners();
    }
  }

  // Método para entrar ou sair da chamada de voz
  Future<void> toggleVoiceCall(String myUserId) async {
    if (isInVoiceCall) {
      WebRTCService().leaveVoiceRoom();
      isInVoiceCall = false;
    } else {
      final existingUserIds = onlineUsers.map((u) => u['id'].toString()).toList();
      final success = await WebRTCService().joinVoiceRoom(
          liveNotebookSid ?? currentNotebookId,
          myUserId,
          existingUserIds
      );
      if (success) {
        isInVoiceCall = true;
      }
    }
    notifyListeners();
  }

  void toggleMute() {
    isMuted = !isMuted;
    WebRTCService().toggleMute();
    notifyListeners();
  }

  void toggleSpeaker() {
    isSpeakerOn = !isSpeakerOn;
    WebRTCService().toggleSpeaker();
    notifyListeners();
  }
}

final canvasProvider = ChangeNotifierProvider.autoDispose<CanvasController>((ref) {
  return CanvasController();
});