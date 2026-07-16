import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../core/network/realtime_service.dart';
import '../../../core/network/sync_service.dart';
import '../models/image_block_model.dart';
import '../models/local_page_model.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../repositories/canvas_repository.dart';

enum ToolMode { draw, pan, select, text, eraser, insertImage, imageEdit }
enum InlineTarget { none, block, title, footer }

class CanvasController extends ChangeNotifier {
  final CanvasRepository _repository = CanvasRepository();

  // =========================================================================
  // 1. ESTADO GERAL DA TELA
  // =========================================================================
  List<LocalPage> pages = [];
  int currentPageIndex = 0;
  bool isLoading = true;

  int? liveNotebookSid;
  int currentNotebookId = 0;
  String currentPaperSize = 'A4';
  late String liveLineType;

  // =========================================================================
  // 2. FERRAMENTAS E SELEÇÕES
  // =========================================================================
  ToolMode currentTool = ToolMode.draw;
  InlineTarget activeInlineTarget = InlineTarget.none;
  TextBlock? activeTextBlock;

  String selectedColorHex = '#2C3E50';
  double selectedThickness = 3.0;

  final Set<String> selectedStrokeIds = {};
  Offset? selectionRectStart;
  Offset? selectionRectEnd;
  bool isMovingStrokes = false;
  Offset? lastPanOffset;

  // =========================================================================
  // 3. WEBSOCKETS (PRESENÇA EM TEMPO REAL VIA STREAMS)
  // =========================================================================
  bool isRealtimeActive = false;
  bool isInVoiceCall = false;
  bool isMuted = false;
  bool isSpeakerOn = true;
  List<Map<String, dynamic>> onlineUsers = [];

  // Subscrições das Streams (Para as podermos fechar no dispose)
  StreamSubscription? _usersSubscription;
  StreamSubscription? _strokesSubscription;

  final List<Color> avatarColorsPool = [
    const Color(0xFFE67E22), const Color(0xFF9B59B6), const Color(0xFF27AE60),
    const Color(0xFF2980B9), const Color(0xFFE74C3C), const Color(0xFF1ABC9C),
    const Color(0xFFF1C40F),
  ];

  // =========================================================================
  // 4. CONTROLADORES VISUAIS E DE DESENHO
  // =========================================================================
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

    // Cancela as escutas das Streams para não deixar vazamentos de memória!
    _usersSubscription?.cancel();
    _strokesSubscription?.cancel();

    SyncService.syncedPagesRadio.removeListener(_onPageSyncedByRadar);
    SyncService.syncedNoteBooksRadio.removeListener(_onNoteBookSyncedByRadar);

    if (liveNotebookSid != null) {
      RealtimeService().leaveNotebookChannel(liveNotebookSid!);
    }
    super.dispose();
  }

  // =========================================================================
  // 📥 INICIALIZAÇÃO DO CADERNO
  // =========================================================================
  Future<void> initNotebook(int notebookId, int? notebookSid, String lineType, String paperSize) async {
    isLoading = true;
    currentNotebookId = notebookId;
    liveNotebookSid = kIsWeb ? notebookId : notebookSid;
    liveLineType = lineType;
    currentPaperSize = paperSize;
    notifyListeners();

    SyncService.isCollaborationActive = false;
    debugPrint('🔒 [Canvas] Motor de Sincronização Automática DESLIGADO.');

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

  // =========================================================================
  // 📡 WEBSOCKETS REVERB (FUSÃO PERFEITA COM AS TEUS STREAMS!)
  // =========================================================================
  void initRealtimeCollaboration() async {
    final realtime = RealtimeService();
    await realtime.initConnection();

    final int channelId = (liveNotebookSid != null && liveNotebookSid != 0) ? liveNotebookSid! : currentNotebookId;

    // 1. Entra na sala no servidor Laravel via Pusher/Reverb
    await realtime.joinNotebookChannel(notebookId: channelId);

    // 2. 👂 CANAL 1: Ouve as atualizações da lista de avatares online via Stream
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

    // 3. 👂 CANAL 2: Ouve a chegada de traços de tinta dos colegas via Stream
    _strokesSubscription?.cancel();
    _strokesSubscription = realtime.onStrokeReceived.listen((data) {
      try {
        final int incomingPageNum = data['page_number'];
        final List<dynamic> rawStrokes = data['strokes'];
        if (pages.isEmpty) return;

        final LocalPage activePage = pages[currentPageIndex];

        // Só desenhamos na tela se o colega estiver a riscar na mesma página em que estamos a olhar!
        if (activePage.pageNumber == incomingPageNum) {
          for (var strokeMap in rawStrokes) {
            final List<Offset> points = (strokeMap['points'] as List).map((pt) {
              final double dx = (pt['x'] is int) ? (pt['x'] as int).toDouble() : pt['x'];
              final double dy = (pt['y'] is int) ? (pt['y'] as int).toDouble() : pt['y'];
              return Offset(dx, dy);
            }).toList();

            final receivedStroke = Stroke(
              id: strokeMap['id'] ?? const Uuid().v4(),
              color: strokeMap['color'] ?? '#2C3E50',
              thickness: (strokeMap['thickness'] is int) ? (strokeMap['thickness'] as int).toDouble() : strokeMap['thickness'].toDouble(),
              points: points,
            );
            activePage.strokes.add(receivedStroke);
          }
          notifyListeners(); // Redesenha a tela na hora com a tinta nova!
        }
      } catch (e) {
        debugPrint('🚨 [WebSocket PULL] Falha ao processar traço da Stream: $e');
      }
    });
  }

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

      // Salto de frequência: sai da sala local provisória e entra na sala oficial da nuvem!
      RealtimeService().leaveNotebookChannel(currentNotebookId);
      initRealtimeCollaboration();
      notifyListeners();
    }
  }

  Future<void> triggerAutoSave(LocalPage page) async {
    await _repository.savePage(page, liveNotebookSid);
  }

  // =========================================================================
  // 🛠️ FERRAMENTAS, CORES E ZOOM
  // =========================================================================
  void switchTool(ToolMode newMode) {
    currentTool = newMode;
    if (newMode != ToolMode.select) {
      selectedStrokeIds.clear();
      selectionRectStart = null;
      selectionRectEnd = null;
      isMovingStrokes = false;
    }
    notifyListeners();
  }

  void zoom(double factor, Size screenSize) {
    final Matrix4 matrix = transformationController.value;
    final double currentScale = matrix.getMaxScaleOnAxis();
    if (currentScale * factor < 0.1 || currentScale * factor > 6.0) return;

    final double centerX = screenSize.width / 2;
    final double centerY = screenSize.height / 2;

    matrix.translate(centerX, centerY);
    matrix.scale(factor);
    matrix.translate(-centerX, -centerY);
    transformationController.value = matrix;
    notifyListeners();
  }

  void setLineType(String type) {
    liveLineType = type;
    notifyListeners();
  }

  // =========================================================================
  // 📄 GESTÃO DE PÁGINAS E NAVEGAÇÃO
  // =========================================================================
  void setPageIndex(int index) {
    currentPageIndex = index;
    notifyListeners();
  }

  Future<void> addNewPage(bool isLandscape) async {
    final newPage = LocalPage(
      notebookId: currentNotebookId,
      pageNumber: pages.length + 1,
      isLandscape: isLandscape,
    );
    _resetZoomForPage(newPage, currentPaperSize);
    pages.add(newPage);
    notifyListeners();
    await _repository.savePage(newPage, liveNotebookSid);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (pageController.hasClients) {
        pageController.animateToPage(pages.length - 1, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
      }
    });
  }

  Future<void> deleteCurrentPage(BuildContext context) async {
    if (pages.length <= 1) return;
    pages.removeAt(currentPageIndex);
    if (currentPageIndex >= pages.length) {
      currentPageIndex = pages.length - 1;
    }
    notifyListeners();
  }

  // =========================================================================
  // 🖌️ AÇÕES DE DESENHO, BORRACHA E LAÇO
  // =========================================================================
  void eraseAtPosition(Offset pos, LocalPage page) {
    const double eraserRadius = 20.0;
    final List<Stroke> strokesToRemove = [];
    for (var stroke in page.strokes) {
      for (var point in stroke.points) {
        if ((point - pos).distance < eraserRadius) {
          strokesToRemove.add(stroke);
          break;
        }
      }
    }
    if (strokesToRemove.isNotEmpty) {
      for (var stroke in strokesToRemove) {
        page.strokes.remove(stroke);
      }
      notifyListeners();
      triggerAutoSave(page);
    }
  }

  Future<void> pickAndInsertImage(LocalPage page) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      final newImageBlock = ImageBlock(
        imagePath: pickedFile.path,
        position: const Offset(100, 150),
        width: 300.0,
        height: 200.0,
      );
      page.imageBlocks.add(newImageBlock);
      currentTool = ToolMode.imageEdit;
      selectedStrokeIds.clear();
      notifyListeners();
      await triggerAutoSave(page);
    }
  }

  void deleteImageBlock(LocalPage page, ImageBlock img) {
    page.imageBlocks.remove(img);
    notifyListeners();
    triggerAutoSave(page);
  }

  void undo(LocalPage page) {
    if (page.strokes.isNotEmpty) {
      page.strokes.removeLast();
      notifyListeners();
      triggerAutoSave(page);
    }
  }

  // Calcula quais traços estão dentro da caixa de seleção
  void selectStrokesInRect(LocalPage page, Rect rect) {
    selectedStrokeIds.clear();
    for (var stroke in page.strokes) {
      for (var pt in stroke.points) {
        if (rect.contains(pt)) {
          selectedStrokeIds.add(stroke.id);
          break;
        }
      }
    }
    notifyListeners();
  }

  // Move a tinta arrastada pelo dedo
  void moveSelectedStrokes(LocalPage page, Offset delta) {
    for (var id in selectedStrokeIds) {
      final matches = page.strokes.where((s) => s.id == id);
      if (matches.isNotEmpty) {
        final stroke = matches.first;
        for (int i = 0; i < stroke.points.length; i++) {
          stroke.points[i] = stroke.points[i] + delta;
        }
      }
    }
    notifyListeners();
  }
}

// 🚀 A ANTENA DO RIVERPOD PARA TODA A APP!
final canvasProvider = ChangeNotifierProvider<CanvasController>((ref) {
  return CanvasController();
});