import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors, Matrix4;

import 'package:drift/drift.dart' hide Column;
import '../../../core/database/app_database.dart' as db;
import '../../../core/network/realtime_service.dart';
import '../../../core/network/sync_service.dart';
import '../../../core/network/webrtc_service.dart';
import '../../../core/services/ocr_service.dart';
import '../models/image_block_model.dart';
import '../models/local_page_model.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../repositories/canvas_repository.dart';

enum ToolMode { draw, pan, select, text, eraser, insertImage, imageEdit }
enum InlineTarget { none, block, title, footer }

class CanvasController extends ChangeNotifier {
  final CanvasRepository _repository = CanvasRepository();
  final HandwritingOCRService _ocrService = HandwritingOCRService();

  List<LocalPage> pages = [];
  int currentPageIndex = 0;
  bool isLoading = true;
  bool isUploadingImage = false; // ☁️ Indicador de upload para a UI

  int? liveNotebookSid;
  int currentNotebookId = 0;
  String currentPaperSize = 'A4';
  late String liveLineType;
  String currentUserRole = 'viewer';
  String myUserId = ""; // 🚀 Identificador único do utilizador atual

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
  String? followingUserId;
  final Set<String> whoIsWatchingMe = {}; // 👥 Utilizadores que me estão a seguir
  bool isBroadcastingViewport = false;
  Timer? _viewportBroadcastTimer;
  
  // 🔭 Dados para sincronização adaptativa e foco
  Offset? currentViewportCenter;
  double? currentVisibleWidth; 
  Size? lastScreenSize;
  
  // 🎢 Variáveis para suavização de movimento
  Matrix4? _targetMatrix;
  Timer? _smoothTimer;

  StreamSubscription? _usersSubscription;
  StreamSubscription? _strokesSubscription;
  StreamSubscription? _textSubscription;
  StreamSubscription? _imageSubscription;
  StreamSubscription? _viewportSubscription;
  StreamSubscription? _followSubscription;
  StreamSubscription? _pageEventSubscription;
  StreamSubscription? _pageUpdatedSubscription;
  StreamSubscription? _dbPagesSubscription;
  StreamSubscription? _dbNotebookSubscription;

  final List<Color> avatarColorsPool = [
    const Color(0xFFE67E22), const Color(0xFF9B59B6), const Color(0xFF27AE60),
    const Color(0xFF2980B9), const Color(0xFFE74C3C), const Color(0xFF1ABC9C),
  ];

  final ValueNotifier<Map<String, Stroke>> remoteLiveStrokes = ValueNotifier({});
  final ValueNotifier<List<Offset>> activePointsNotifier = ValueNotifier([]);
  late TransformationController transformationController;
  final PageController pageController = PageController(initialPage: 0);

  final Set<String> activeBroadcasters = {};
  final Map<String, Timer> _broadcasterTimers = {};
  Timer? _autoSyncPushTimer; // 🚀 Timer para o Dono enviar dados para a nuvem
  final Set<String> uploadingImageIds = {}; // 🖼️ IDs das imagens em upload de fundo

  CanvasController() {
    transformationController = TransformationController();
  }

  @override
  void dispose() {
    activePointsNotifier.dispose();
    transformationController.dispose();
    pageController.dispose();
    _usersSubscription?.cancel();
    _strokesSubscription?.cancel();
    _textSubscription?.cancel();
    _imageSubscription?.cancel();
    _viewportSubscription?.cancel();
    _followSubscription?.cancel();
    _pageEventSubscription?.cancel();
    _pageUpdatedSubscription?.cancel();
    _dbPagesSubscription?.cancel();
    _dbNotebookSubscription?.cancel();
    _viewportBroadcastTimer?.cancel();
    _autoSyncPushTimer?.cancel();
    for (var timer in _pageSaveDebouncers.values) { timer.cancel(); }
    for (var timer in _broadcasterTimers.values) { timer.cancel(); }
    _broadcasterTimers.clear();
    if (liveNotebookSid != null) RealtimeService().leaveNotebookChannel(liveNotebookSid!);
    SyncService.isCollaborationActive = false;
    super.dispose();
  }

  Future<void> initNotebook(int notebookId, int? notebookSid, String lineType, String paperSize, String role, [String? userId]) async {
    isLoading = true;
    currentNotebookId = notebookId;
    liveNotebookSid = notebookSid;
    liveLineType = lineType;
    currentPaperSize = paperSize;
    currentUserRole = role;
    if (userId != null) myUserId = userId;
    SyncService.isCollaborationActive = true;

    // 📡 ASSINAR METADADOS DO CADERNO (Reatividade para o Server ID)
    _dbNotebookSubscription?.cancel();
    final database = db.AppDatabase.instance;
    _dbNotebookSubscription = (database.select(database.notebooks)..where((t) => t.id.equals(notebookId))).watchSingle().listen((row) {
      if (row.serverId != null && liveNotebookSid == null) {
        debugPrint('☁️ [Canvas] Server ID detetado via reatividade do banco! Ativando Realtime...');
        liveNotebookSid = row.serverId;
        initRealtimeCollaboration();
        isRealtimeActive = true;
        notifyListeners();
      }
    });

    // 📡 INÍCIO DA REATIVIDADE DO BANCO: Assina as páginas imediatamente
    _dbPagesSubscription?.cancel();
    _dbPagesSubscription = _repository.watchPagesByNotebook(notebookId).listen((fullPages) async {
      if (fullPages.isEmpty && isLoading) {
        // Se o banco está vazio e estamos a carregar, cria a primeira página
        final firstPage = await _repository.createNewPage(notebookId, 1, false, liveNotebookSid);
        if (firstPage != null) {
          _resetZoomForPage(firstPage, paperSize);
          pages = [firstPage];
        }
      } else {
        pages = fullPages;
        if (isLoading && pages.isNotEmpty) {
          _resetZoomForPage(pages.first, paperSize);
        }
      }
      
      isLoading = false;
      notifyListeners();
    });

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

  void setThickness(double thickness) { selectedThickness = thickness; notifyListeners(); }
  void setColor(String hex) { selectedColorHex = hex; notifyListeners(); }
  void setTextColor(String hex) {
    if (activeTextBlock != null) {
      activeTextBlock!.textColorHex = hex;
      notifyListeners();
      broadcastTextBlockUpdate(pages[currentPageIndex], activeTextBlock!);
    }
  }

  void setTextEditing(InlineTarget target, [TextBlock? block]) {
    activeInlineTarget = target;
    activeTextBlock = block;
    notifyListeners();
    if (block != null) broadcastTextBlockUpdate(pages[currentPageIndex], block);
  }

  void _markUserBroadcasting(String userId) {
    if (!activeBroadcasters.contains(userId)) {
      activeBroadcasters.add(userId);
      notifyListeners();
    }
    _broadcasterTimers[userId]?.cancel();
    _broadcasterTimers[userId] = Timer(const Duration(seconds: 4), () {
      if (activeBroadcasters.contains(userId)) {
        activeBroadcasters.remove(userId);
        _broadcasterTimers.remove(userId);
        notifyListeners();
      }
    });
  }

  void initRealtimeCollaboration() async {
    final realtime = RealtimeService();
    await realtime.initConnection();
    final int channelId = (liveNotebookSid != null && liveNotebookSid != 0) ? liveNotebookSid! : currentNotebookId;

    // 🚀 CORREÇÃO DE PRESENÇA: Configurar listeners ANTES de entrar na sala
    _usersSubscription?.cancel();
    _usersSubscription = realtime.onUsersUpdated.listen((usersList) {
      final List<String> currentOnlineIds = usersList.map((u) => u['id'].toString()).toList();
      
      // Limpar quem saiu da lista de seguidores
      whoIsWatchingMe.removeWhere((uid) => !currentOnlineIds.contains(uid));

      onlineUsers = usersList.map((u) {
        final map = Map<String, dynamic>.from(u);
        final String uid = map['id'].toString();
        
        int idAsInt = int.tryParse(uid) ?? 0;
        
        return {
          'id': uid,
          'name': map['name'] ?? 'Colega',
          'color': avatarColorsPool[idAsInt % avatarColorsPool.length],
          'isTalking': map['isTalking'] ?? false,
        };
      }).toList();

      // 🚀 ROOM SYNC: Se entrei numa sala com mais gente, alinhamos os dados
      if (onlineUsers.length > 1 && isRealtimeActive) {
        _debounceRoomSync();
      }

      notifyListeners();
    });

    _strokesSubscription?.cancel();
    _strokesSubscription = realtime.onStrokeReceived.listen((data) {
      try {
        final int incomingPageNum = data['page_number'];
        final String? senderId = data['sender_id']?.toString();
        
        debugPrint('🎨 [Live-Stroke] Recebido de $senderId para folha $incomingPageNum');
        
        if (senderId == myUserId) return;

        if (pages.isEmpty) return;
        
        // 🔭 SINCRONIZAÇÃO DE PÁGINA
        if (followingUserId != null && senderId == followingUserId) {
          if (currentPageIndex + 1 != incomingPageNum) {
            final targetIdx = incomingPageNum - 1;
            if (targetIdx >= 0 && targetIdx < pages.length) {
              setPageIndex(targetIdx);
              pageController.jumpToPage(targetIdx);
            }
          }
        }

        // 🎯 LOCALIZAR A PÁGINA ALVO DE FORMA RÍGIDA
        final int targetIdx = pages.indexWhere((p) => p.pageNumber == incomingPageNum);
        if (targetIdx == -1) return; // 🛡️ Se não existe, não "vaza" para a atual!

        final targetPage = pages[targetIdx];

        for (var strokeMap in data['strokes']) {
          final String strokeId = strokeMap['id'];
          final bool isFinal = strokeMap['is_final'] == true;
          final bool isDeleted = strokeMap['is_deleted'] == true;

          if (isDeleted) {
            targetPage.strokes.removeWhere((s) => s.id == strokeId);
            notifyListeners();
            if (currentUserRole == 'owner') triggerAutoSave(targetPage);
            continue;
          }

          final List<Offset> incomingPoints = (strokeMap['points'] as List)
              .map((pt) => Offset((pt['x'] as num).toDouble(), (pt['y'] as num).toDouble()))
              .toList();

          if (!isFinal) {
            final currentMap = Map<String, Stroke>.from(remoteLiveStrokes.value);
            if (currentMap.containsKey(strokeId)) {
              currentMap[strokeId]!.points.addAll(incomingPoints);
            } else {
              // 🚀 ISOLAMENTO: Atribuímos o número da página ao traço live
              currentMap[strokeId] = Stroke(
                id: strokeId, 
                color: strokeMap['color'], 
                thickness: (strokeMap['thickness'] as num).toDouble(), 
                points: incomingPoints,
                pageNumber: incomingPageNum,
              );
            }
            remoteLiveStrokes.value = currentMap;
          } else {
            // 🚀 SALVAMENTO IMEDIATO: Adicionamos o traço final à página local
            final newStroke = Stroke(
              id: strokeId, 
              color: strokeMap['color'], 
              thickness: (strokeMap['thickness'] as num).toDouble(), 
              points: incomingPoints,
              pageNumber: incomingPageNum,
            );

            targetPage.strokes.removeWhere((s) => s.id == strokeId);
            targetPage.strokes.add(newStroke);
            
            // Removemos o traço 'live' de preview
            final currentMap = Map<String, Stroke>.from(remoteLiveStrokes.value);
            currentMap.remove(strokeId);
            remoteLiveStrokes.value = currentMap;
            
            notifyListeners();

            // Todos salvam localmente para evitar perda de dados se saírem da app
            _repository.savePage(targetPage, liveNotebookSid);
          }
        }
      } catch (e) { debugPrint('⚠️ Erro tinta remota: $e'); }
    });

    _textSubscription?.cancel();
    _textSubscription = realtime.onTextReceived.listen((data) {
      try {
        final String? senderId = data['sender_id']?.toString();
        debugPrint('📝 [Live-Text] Recebido de $senderId');
        if (senderId == myUserId) return;

        final int incomingPageNum = data['page_number'];
        if (pages.isEmpty) return;
        
        final int targetIdx = pages.indexWhere((p) => p.pageNumber == incomingPageNum);
        if (targetIdx == -1) return;

        final targetPage = pages[targetIdx];
        final blockData = data['block'];
        final String blockId = blockData['id'];
        if (data['is_deleted'] == true) {
          targetPage.textBlocks.removeWhere((t) => t.id == blockId);
        } else {
          final existingIndex = targetPage.textBlocks.indexWhere((t) => t.id == blockId);
          final newBlock = TextBlock.fromJson(blockData);
          if (existingIndex != -1) targetPage.textBlocks[existingIndex] = newBlock;
          else targetPage.textBlocks.add(newBlock);
        }
        notifyListeners();
        // 🚀 Nota: Agora o salvamento SQLite acontece localmente para todos.
        _repository.savePage(targetPage, liveNotebookSid);
      } catch (e) { debugPrint('⚠️ Erro texto remoto: $e'); }
    });

    _imageSubscription?.cancel();
    _imageSubscription = realtime.onImageReceived.listen((data) {
      try {
        final String? senderId = data['sender_id']?.toString();
        debugPrint('🖼️ [Live-Image] Recebido de $senderId');
        if (senderId == myUserId) return;

        final int incomingPageNum = data['page_number'];
        if (pages.isEmpty) return;

        final int targetIdx = pages.indexWhere((p) => p.pageNumber == incomingPageNum);
        if (targetIdx == -1) return;

        final targetPage = pages[targetIdx];
        final blockData = data['block'];
        final String blockId = blockData['id'];
        if (data['is_deleted'] == true) {
          targetPage.imageBlocks.removeWhere((img) => img.id == blockId);
        } else {
          final existingIndex = targetPage.imageBlocks.indexWhere((img) => img.id == blockId);
          final newBlock = ImageBlock.fromJson(blockData);
          if (existingIndex != -1) targetPage.imageBlocks[existingIndex] = newBlock;
          else targetPage.imageBlocks.add(newBlock);
        }
        notifyListeners();
        _repository.savePage(targetPage, liveNotebookSid);
      } catch (e) { debugPrint('⚠️ Erro imagem remota: $e'); }
    });

    // 🏆 SERVER-AUTHORITATIVE: Ouvir a confirmação final do servidor Laravel
    _pageUpdatedSubscription?.cancel();
    _pageUpdatedSubscription = realtime.onPageUpdated.listen((data) {
      try {
        final String? senderId = data['sender_id']?.toString();
        final int incomingPageNum = data['page_number'];
        debugPrint('🏆 [Server-Update] Confirmação final recebida para folha $incomingPageNum');

        if (senderId == myUserId) {
          debugPrint('ℹ️ [Server-Update] Ignorando eco do meu próprio push.');
          return;
        }

        final int pageId = data['id'];
        
        // Localizar a página local correspondente
        final targetPage = pages.firstWhere(
          (p) => p.serverId == pageId || (p.pageNumber == data['page_number']),
          orElse: () => pages[currentPageIndex],
        );

        // Atualizar dados da página com a versão "da verdade" do servidor
        targetPage.serverId = pageId;
        
        if (data['stroke_data'] != null) {
          final List strokeList = (data['stroke_data'] is String) 
              ? jsonDecode(data['stroke_data']) 
              : data['stroke_data'];
          targetPage.strokes = strokeList.map((s) => Stroke.fromJson(Map<String, dynamic>.from(s))).toList();
        }

        if (data['text_data'] != null) {
          final List textList = (data['text_data'] is String) 
              ? jsonDecode(data['text_data']) 
              : data['text_data'];
          targetPage.textBlocks = textList.map((t) => TextBlock.fromJson(Map<String, dynamic>.from(t))).toList();
        }

        if (data['image_data'] != null) {
          final List imageList = (data['image_data'] is String) 
              ? jsonDecode(data['image_data']) 
              : data['image_data'];
          targetPage.imageBlocks = imageList.map((img) => ImageBlock.fromJson(Map<String, dynamic>.from(img))).toList();
        }

        notifyListeners();
        _repository.savePage(targetPage, liveNotebookSid);
      } catch (e) {
        debugPrint('⚠️ Erro ao processar PageUpdated: $e');
      }
    });

    _viewportSubscription?.cancel();
    _viewportSubscription = realtime.onViewportReceived.listen((data) {
      final String senderId = data['sender_id'].toString();
      _markUserBroadcasting(senderId);

      if (followingUserId == null || senderId != followingUserId) return;

      // 🔭 SINCRONIZAÇÃO DE PÁGINA
      final int? incomingPageNum = data['page_number'];
      if (incomingPageNum != null && currentPageIndex + 1 != incomingPageNum) {
        final targetIdx = incomingPageNum - 1;
        if (targetIdx >= 0 && targetIdx < pages.length) {
          setPageIndex(targetIdx);
          pageController.jumpToPage(targetIdx);
        }
      }

      final double focusX = (data['focusX'] as num).toDouble();
      final double focusY = (data['focusY'] as num).toDouble();
      final double remoteVisibleWidth = (data['visibleWidth'] as num).toDouble();

      if (lastScreenSize != null && remoteVisibleWidth > 0) {
        final screenCenter = Offset(lastScreenSize!.width / 2, lastScreenSize!.height / 2);
        
        // 🚀 CÁLCULO DE ESCALA COM PISO DE LEGIBILIDADE
        double adaptiveScale = lastScreenSize!.width / remoteVisibleWidth;
        final bool isPhone = lastScreenSize!.width < 600;
        final double minComfortScale = isPhone ? 1.2 : 0.8;
        adaptiveScale = adaptiveScale.clamp(minComfortScale, 3.5);

        // 🎯 LÓGICA DE ZONA DE SEGURANÇA (Safe Zone)
        final currentMatrix = transformationController.value;
        final focusVector = Vector3(focusX, focusY, 0);
        final screenVector = currentMatrix.transform3(focusVector);
        final screenPoint = Offset(screenVector.x, screenVector.y);

        // Definimos o tamanho do quadrado de segurança (95% de largura para movimento apenas nos extremos)
        final double safeWidth = lastScreenSize!.width * 0.95;
        final double safeHeight = lastScreenSize!.height * 0.6;
        final Rect safeZone = Rect.fromCenter(
          center: screenCenter,
          width: safeWidth,
          height: safeHeight,
        );

        // Só movemos a folha se o desenho sair do quadrado central
        if (!safeZone.contains(screenPoint) || (currentMatrix.getMaxScaleOnAxis() - adaptiveScale).abs() > 0.1) {
          final Matrix4 newTarget = Matrix4.identity()
            ..translate(screenCenter.dx, screenCenter.dy)
            ..scale(adaptiveScale)
            ..translate(-focusX, -focusY);
          
          _startSmoothTransition(newTarget);
        }
      }
    });

    _followSubscription?.cancel();
    _followSubscription = realtime.onFollowUpdateReceived.listen((data) {
      final String followerId = data['follower_id'].toString();
      final String? followingId = data['following_id']?.toString();
      final String myId = myUserId; // Precisamos do myUserId atualizado

      if (followingId == myId) {
        if (!whoIsWatchingMe.contains(followerId)) {
          whoIsWatchingMe.add(followerId);
          notifyListeners();
        }
      } else {
        if (whoIsWatchingMe.contains(followerId)) {
          whoIsWatchingMe.remove(followerId);
          notifyListeners();
        }
      }
    });

    _pageEventSubscription?.cancel();
    _pageEventSubscription = realtime.onPageEventReceived.listen((data) async {
      try {
        final String? senderId = data['sender_id']?.toString();
        // 🛡️ ANTI-DUPLICIDADE E SERVER-AUTHORITATIVE
        if (senderId == myUserId) return;

        final String action = data['action'];
        final int notebookSid = data['notebook_sid'];
        if (notebookSid != liveNotebookSid) return;

        if (action == 'add') {
          final int pageNumber = data['page_number'];
          final bool isLandscape = data['is_landscape'] ?? false;
          
          final existingIndex = pages.indexWhere((p) => p.pageNumber == pageNumber);
          if (existingIndex == -1) {
            final newPage = LocalPage(
              notebookId: currentNotebookId, 
              pageNumber: pageNumber, 
              isLandscape: isLandscape
            );
            _resetZoomForPage(newPage, currentPaperSize);
            pages.add(newPage);
            pages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
            notifyListeners();

            // 🛡️ PERSISTÊNCIA UNIVERSAL: Todos salvam a nova folha no SQLite local
            await _repository.savePage(newPage, liveNotebookSid);
          }
        } else if (action == 'delete') {
          final int pageNumber = data['page_number'];
          final int index = pages.indexWhere((p) => p.pageNumber == pageNumber);
          if (index != -1) {
            final pageToDelete = pages[index];
            pages.removeAt(index);
            if (currentPageIndex >= pages.length) currentPageIndex = pages.length - 1;
            if (currentPageIndex < 0) currentPageIndex = 0;
            notifyListeners();
            if (pageController.hasClients) pageController.jumpToPage(currentPageIndex);

            // 🛡️ PERSISTÊNCIA UNIVERSAL: Todos removem a folha do SQLite local
            if (pageToDelete.id != null) {
              await _repository.deletePage(pageToDelete.id!);
            }
          }
        }
      } catch (e) {
        debugPrint('⚠️ Erro ao processar evento de página remoto: $e');
      }
    });

    // Agora sim, entrar no canal
    await realtime.joinNotebookChannel(notebookId: channelId);
  }

  final Map<int, Timer> _pageSaveDebouncers = {};

  void _debounceSave(LocalPage page) {
    if (page.id == null) return;
    _pageSaveDebouncers[page.id!]?.cancel();
    _pageSaveDebouncers[page.id!] = Timer(const Duration(milliseconds: 500), () {
      triggerAutoSave(page);
    });
  }

  Timer? _roomSyncDebouncer;
  bool _hasSyncedInThisSession = false;

  void _debounceRoomSync() {
    if (_hasSyncedInThisSession) return;
    
    _roomSyncDebouncer?.cancel();
    _roomSyncDebouncer = Timer(const Duration(seconds: 2), () async {
      debugPrint('📡 [RoomSync] Detetada colaboração ativa. Sincronizando conteúdo local com a nuvem...');
      
      // 1. Push: Envia o que tenho localmente para o Laravel (Laravel funde os dados)
      await SyncService().pushPages();
      
      // 2. Pull: Recebe o conteúdo fundido de todos os utilizadores
      await SyncService().pullPages();
      
      // 3. Recarregar e Notificar
      pages = await _repository.getPagesByNotebook(currentNotebookId, liveNotebookSid);
      _hasSyncedInThisSession = true;
      notifyListeners();
      debugPrint('🏆 [RoomSync] Caderno alinhado com sucesso!');
    });
  }

  Future<void> triggerAutoSave(LocalPage page) async {
    debugPrint('💾 [SQLite] A guardar folha ${page.pageNumber} localmente...');
    await _repository.savePage(page, liveNotebookSid);

    // 🧠 DISPARAR OCR (Background)
    _debounceOCR(page);

    // 🚀 SERVER-AUTHORITATIVE PUSH
    if (isRealtimeActive && liveNotebookSid != null && liveNotebookSid != 0) {
      _autoSyncPushTimer?.cancel();
      _autoSyncPushTimer = Timer(const Duration(milliseconds: 1500), () async {
        debugPrint('☁️ [Authoritative Push] A enviar folha ${page.pageNumber} para a Cloud...');
        final success = await _repository.savePageToCloud(page, liveNotebookSid!, myUserId);
        if (success) {
          debugPrint('✅ [Authoritative Push] Folha ${page.pageNumber} sincronizada!');
        } else {
          debugPrint('❌ [Authoritative Push] Falha ao sincronizar folha ${page.pageNumber}.');
        }
      });
    }
  }

  void switchTool(ToolMode newMode) {
    currentTool = newMode;
    if (newMode != ToolMode.select) {
      selectedStrokeIds.clear(); selectedTextIds.clear();
      selectionRectStart = null; selectionRectEnd = null;
      isMovingStrokes = false;
    }
    notifyListeners();
  }

  void zoom(double factor, Size screenSize) {
    final Matrix4 matrix = transformationController.value;
    final double centerX = screenSize.width / 2;
    final double centerY = screenSize.height / 2;
    matrix.translate(centerX, centerY); matrix.scale(factor); matrix.translate(-centerX, -centerY);
    transformationController.value = matrix;
    notifyListeners();
  }

  void setLineType(String type) { liveLineType = type; notifyListeners(); }
  void setPageIndex(int index) { currentPageIndex = index; notifyListeners(); }

  Future<void> addNewPage(bool isLandscape) async {
    // 🛡️ ALGORITMO ROBUSTO: Pega o maior número existente e soma 1
    int maxPage = 0;
    for (var p in pages) { if (p.pageNumber > maxPage) maxPage = p.pageNumber; }
    final int newPageNumber = maxPage + 1;

    final newPage = LocalPage(notebookId: currentNotebookId, pageNumber: newPageNumber, isLandscape: isLandscape);
    _resetZoomForPage(newPage, currentPaperSize);
    pages.add(newPage);
    notifyListeners();
    await triggerAutoSave(newPage);

    // 📢 Notificar colegas online
    if (isRealtimeActive && liveNotebookSid != null) {
      RealtimeService().broadcastPageEvent(
        notebookId: liveNotebookSid!,
        myUserId: myUserId,
        pageData: {
          'action': 'add',
          'notebook_sid': liveNotebookSid,
          'page_number': newPageNumber,
          'is_landscape': isLandscape,
        }
      );
    }

    pageController.animateToPage(pages.length - 1, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
  }

  void deletePage(LocalPage pageToDelete) async {
    final int deletedPageNumber = pageToDelete.pageNumber;

    pages.remove(pageToDelete);
    if (currentPageIndex >= pages.length) currentPageIndex = pages.length - 1;
    if (currentPageIndex < 0) currentPageIndex = 0;
    
    notifyListeners();
    
    Future.microtask(() { if (pageController.hasClients) pageController.jumpToPage(currentPageIndex); });
    
    if (pageToDelete.id != null) await _repository.deletePage(pageToDelete.id!);
    
    // 📢 Notificar colegas online
    if (isRealtimeActive && liveNotebookSid != null) {
      RealtimeService().broadcastPageEvent(
        notebookId: liveNotebookSid!,
        myUserId: myUserId,
        pageData: {
          'action': 'delete',
          'notebook_sid': liveNotebookSid,
          'page_number': deletedPageNumber,
        }
      );
    }

    if (pages.isNotEmpty) triggerAutoSave(pages[currentPageIndex]);
  }

  final Map<int, Timer> _ocrDebouncers = {};

  void _debounceOCR(LocalPage page) {
    if (page.id == null) return;
    _ocrDebouncers[page.id!]?.cancel();
    _ocrDebouncers[page.id!] = Timer(const Duration(seconds: 3), () async {
      debugPrint('🧠 [OCR] Iniciando reconhecimento de escrita para folha ${page.pageNumber}...');
      final text = await _ocrService.recognizeHandwriting(page.strokes);
      if (text.isNotEmpty && text != page.extractedText) {
        page.extractedText = text;
        await _repository.updatePageMetadata(page.id!, page.title, page.footer, extractedText: text);
        debugPrint('✅ [OCR] Texto extraído e indexado!');
      }
    });
  }

  void eraseAtPosition(Offset pos, LocalPage page) {
    final List<String> deletedStrokeIds = [];
    final List<String> deletedTextIds = [];

    if (selectedStrokeIds.isNotEmpty || selectedTextIds.isNotEmpty) {
      deletedStrokeIds.addAll(selectedStrokeIds); deletedTextIds.addAll(selectedTextIds);
      page.strokes.removeWhere((s) => selectedStrokeIds.contains(s.id));
      page.textBlocks.removeWhere((t) => selectedTextIds.contains(t.id));
      selectedStrokeIds.clear(); selectedTextIds.clear();
    } else {
      const double eraserRadius = 24.0;
      final List<Stroke> strokesToRemove = [];
      for (var stroke in page.strokes) {
        if (stroke.points.any((pt) => (pt - pos).distance < eraserRadius)) strokesToRemove.add(stroke);
      }
      if (strokesToRemove.isNotEmpty) {
        deletedStrokeIds.addAll(strokesToRemove.map((s) => s.id));
        page.strokes.removeWhere((s) => strokesToRemove.contains(s));
      }

      final List<TextBlock> textsToRemove = [];
      for (var tb in page.textBlocks) {
        final Rect textHitBox = Rect.fromLTWH(tb.position.dx, tb.position.dy, 150, tb.fontSize * 1.5);
        if (textHitBox.contains(pos) || (tb.position - pos).distance < eraserRadius) textsToRemove.add(tb);
      }
      if (textsToRemove.isNotEmpty) {
        deletedTextIds.addAll(textsToRemove.map((t) => t.id));
        page.textBlocks.removeWhere((t) => textsToRemove.contains(t));
      }
    }

    if (deletedStrokeIds.isNotEmpty || deletedTextIds.isNotEmpty) {
      notifyListeners(); triggerAutoSave(page);
      if (isRealtimeActive && liveNotebookSid != null) {
        for (var id in deletedStrokeIds) {
          RealtimeService().broadcastStroke(notebookId: liveNotebookSid!, strokeData: {
            'page_number': page.pageNumber, 'strokes': [{'id': id, 'is_deleted': true}]
          });
        }
        for (var id in deletedTextIds) {
          RealtimeService().broadcastTextBlock(notebookId: liveNotebookSid!, textData: {
            'page_number': page.pageNumber, 'block': {'id': id}, 'is_deleted': true
          });
        }
      }
    }
  }

  void undo(LocalPage page) {
    if (page.strokes.isNotEmpty) {
      final removed = page.strokes.removeLast();
      page.redoHistory.add(removed);
      notifyListeners(); triggerAutoSave(page);
    }
  }

  void redo(LocalPage page) {
    if (page.redoHistory.isNotEmpty) {
      final restored = page.redoHistory.removeLast();
      page.strokes.add(restored);
      notifyListeners(); triggerAutoSave(page);
    }
  }

  Future<void> pickAndInsertImage(LocalPage page) async {
    final picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    
    if (pickedFile != null) {
      // 🚀 EXIBIÇÃO INSTANTÂNEA: Usamos o path local imediatamente
      final String localId = const Uuid().v4();
      final newImageBlock = ImageBlock(
        id: localId, 
        imagePath: pickedFile.path, 
        position: const Offset(100, 150), 
        width: 300.0, 
        height: 200.0
      );

      page.imageBlocks.add(newImageBlock);
      currentTool = ToolMode.imageEdit;
      notifyListeners();

      // Gravação local imediata
      await _repository.saveSingleImageBlock(page.id!, newImageBlock);
      await triggerAutoSave(page);

      // 🌐 UPLOAD EM BACKGROUND: Se estiver online, sobe para a nuvem sem travar a UI
      if (isRealtimeActive) {
        uploadingImageIds.add(localId);
        notifyListeners();

        final Uint8List bytes = await pickedFile.readAsBytes();
        
        _repository.uploadImage(currentNotebookId, pickedFile.name, bytes).then((remoteUrl) {
          uploadingImageIds.remove(localId);
          if (remoteUrl != null) {
            // Atualiza o path para o URL oficial e avisa os outros
            newImageBlock.imagePath = remoteUrl;
            _repository.saveSingleImageBlock(page.id!, newImageBlock);
            broadcastImageBlockUpdate(page, newImageBlock, myUserId);
            debugPrint('✅ [ImageUpload] Background upload concluído: $remoteUrl');
          }
          notifyListeners();
        });
      }
    }
  }

  Future<void> deleteImageBlock(LocalPage page, ImageBlock img) async {
    page.imageBlocks.remove(img);
    notifyListeners(); await triggerAutoSave(page);
    if (isRealtimeActive && liveNotebookSid != null) {
      RealtimeService().broadcastImageBlock(notebookId: liveNotebookSid!, imageData: {
        'page_number': page.pageNumber, 'block': {'id': img.id}, 'is_deleted': true
      });
    }
  }

  void updateSelectionRect(LocalPage page, Offset currentPos) {
    selectionRectEnd = currentPos;
    if (selectionRectStart != null && selectionRectEnd != null) {
      final rect = Rect.fromPoints(selectionRectStart!, selectionRectEnd!);
      selectedStrokeIds.clear(); selectedTextIds.clear();
      for (var stroke in page.strokes) { if (stroke.points.any((pt) => rect.contains(pt))) selectedStrokeIds.add(stroke.id); }
      for (var tb in page.textBlocks) { if (rect.contains(tb.position)) selectedTextIds.add(tb.id); }
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

  void broadcastSelectionUpdate(LocalPage page) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    for (var id in selectedStrokeIds) {
      final matches = page.strokes.where((s) => s.id == id);
      if (matches.isNotEmpty) {
        final stroke = matches.first;
        RealtimeService().broadcastStroke(notebookId: liveNotebookSid!, strokeData: {
          'page_number': page.pageNumber,
          'strokes': [{
            'id': stroke.id, 'color': stroke.color, 'thickness': stroke.thickness, 'is_final': true,
            'points': stroke.points.map((pt) => {'x': pt.dx, 'y': pt.dy}).toList(),
          }]
        });
      }
    }
    for (var id in selectedTextIds) {
      final matches = page.textBlocks.where((t) => t.id == id);
      if (matches.isNotEmpty) broadcastTextBlockUpdate(page, matches.first);
    }
  }

  void broadcastTextBlockUpdate(LocalPage page, TextBlock block, [String? senderId]) {
    if (isRealtimeActive && liveNotebookSid != null) {
      final String id = senderId ?? myUserId;
      RealtimeService().broadcastTextBlock(notebookId: liveNotebookSid!, textData: {
        'sender_id': id,
        'page_number': page.pageNumber,
        'block': block.toJson(),
      });
    }
  }

  void broadcastImageBlockUpdate(LocalPage page, ImageBlock block, [String? senderId]) {
    if (isRealtimeActive && liveNotebookSid != null) {
      final String id = senderId ?? myUserId;
      // 🚀 AGORA É SINCRONO E LEVE: Enviamos apenas o URL que já está no block.imagePath
      RealtimeService().broadcastImageBlock(notebookId: liveNotebookSid!, imageData: {
        'sender_id': id,
        'page_number': page.pageNumber,
        'block': block.toJson(),
      });
    }
  }

  void forceNotify() => notifyListeners();

  Future<void> toggleVoiceCall(String myUserId) async {
    if (isInVoiceCall) { WebRTCService().leaveVoiceRoom(); isInVoiceCall = false; }
    else {
      final existingUserIds = onlineUsers.map((u) => u['id'].toString()).toList();
      final success = await WebRTCService().joinVoiceRoom(liveNotebookSid ?? currentNotebookId, myUserId, existingUserIds);
      if (success) isInVoiceCall = true;
    }
    notifyListeners();
  }

  void toggleMute() { isMuted = !isMuted; WebRTCService().toggleMute(); notifyListeners(); }
  void toggleSpeaker() { isSpeakerOn = !isSpeakerOn; WebRTCService().toggleSpeaker(); notifyListeners(); }

  void toggleFollowUser(String? userId, String myId) {
    debugPrint('🔭 [CanvasController] Tentar seguir/parar utilizador: $userId');
    if (followingUserId == userId) {
      followingUserId = null;
    } else {
      followingUserId = userId;
    }
    
    // 📢 Avisar os outros sobre a mudança de estado
    if (liveNotebookSid != null) {
      RealtimeService().broadcastFollowUpdate(
        notebookId: liveNotebookSid!,
        myUserId: myId,
        followingUserId: followingUserId,
      );
    }
    
    notifyListeners();
  }

  void startViewportBroadcasting(String effectiveUserId) {
    if (isBroadcastingViewport) return;
    debugPrint('🔭 [Viewport] A iniciar transmissão (User ID Oficial: $effectiveUserId)...');
    isBroadcastingViewport = true;
    notifyListeners(); 

    _viewportBroadcastTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!isRealtimeActive || liveNotebookSid == null || !isBroadcastingViewport) {
        timer.cancel(); return;
      }
      
      if (currentViewportCenter == null || currentVisibleWidth == null || effectiveUserId.isEmpty) return;

      RealtimeService().broadcastViewport(notebookId: liveNotebookSid!, viewportData: {
        'page_number': currentPageIndex + 1,
        'focusX': currentViewportCenter!.dx,
        'focusY': currentViewportCenter!.dy,
        'visibleWidth': currentVisibleWidth,
      }, myUserId: effectiveUserId);
    });
  }

  // 🎢 LÓGICA DE INTERPOLAÇÃO SUAVE (Damping)
  void _startSmoothTransition(Matrix4 target) {
    _targetMatrix = target;
    if (_smoothTimer != null && _smoothTimer!.isActive) return;

    _smoothTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_targetMatrix == null) { timer.cancel(); return; }

      final current = transformationController.value;
      final double lerpFactor = 0.04; // 🚀 Movimento ultra-suave e lento (Damping)

      // Interpolamos a matriz manualmente para um efeito suave
      final Matrix4 next = Matrix4.identity();
      for (int i = 0; i < 16; i++) {
        next.storage[i] = current.storage[i] + (_targetMatrix!.storage[i] - current.storage[i]) * lerpFactor;
      }

      transformationController.value = next;
      notifyListeners();

      // Se estivermos muito perto do destino, paramos
      double diff = 0;
      for (int i = 0; i < 16; i++) { diff += (next.storage[i] - _targetMatrix!.storage[i]).abs(); }
      if (diff < 0.001) {
        transformationController.value = _targetMatrix!;
        _targetMatrix = null;
        timer.cancel();
        notifyListeners();
      }
    });
  }

  void stopViewportBroadcasting() {
    debugPrint('🔭 [Viewport] Transmissão parada pelo utilizador.');
    isBroadcastingViewport = false;
    _viewportBroadcastTimer?.cancel();
    _viewportBroadcastTimer = null;
    notifyListeners();
  }
}

final canvasProvider = ChangeNotifierProvider.autoDispose<CanvasController>((ref) {
  return CanvasController();
});
