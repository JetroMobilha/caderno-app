import 'package:flutter/services.dart'; // 🚀 Para Clipboard
import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors, Matrix4;

import 'package:drift/drift.dart' hide Column;
import 'package:caderno_digital_app/core/database/app_database.dart' as db;
import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/core/network/sync_service.dart';
import 'package:caderno_digital_app/features/canvas/models/image_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/models/stroke_model.dart';
import 'package:caderno_digital_app/features/canvas/models/text_block_model.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';

enum ToolMode { draw, pan, select, text, eraser, insertImage, imageEdit }
enum InlineTarget { none, block, title, footer }

class CanvasController extends ChangeNotifier {
  final CanvasRepository _repository;
  final RealtimeService _realtimeService;

  bool _isDisposed = false; 

  void safeNotify() {
    if (!_isDisposed) {
      notifyListeners(); 
    }
  }

  List<LocalPage> pages = [];
  int currentPageIndex = 0;
  bool isLoading = true;
  bool isUploadingImage = false; 
  bool isGlobalSyncing = false; 

  int? liveNotebookSid;
  int currentNotebookId = 0;
  String currentPaperSize = 'A4';
  late String liveLineType;
  String currentUserRole = 'viewer';
  String myUserId = ""; 

  String? selectedEditingImageId; // 🚀 Novo: Rastreio de imagem selecionada para edição
  
  void clearImageSelection() {
    selectedEditingImageId = null;
    safeNotify();
  }
  
  ToolMode currentTool = ToolMode.draw;
  InlineTarget activeInlineTarget = InlineTarget.none;
  TextBlock? activeTextBlock;

  String selectedColorHex = '#2C3E50';
  double selectedThickness = 3.0;

  final Set<String> selectedStrokeIds = {};
  final Set<String> selectedTextIds = {};
  final Set<String> selectedImageIds = {};

  final List<CanvasAction> _undoStack = [];
  final List<CanvasAction> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  Offset? selectionRectStart;
  Offset? selectionRectEnd;
  bool isMovingStrokes = false;
  Offset? lastPanOffset;

  bool isRealtimeActive = false;
  bool isCollaborationEnabled = false; 
  bool isLiveSessionActive = false; 
  bool isConnectingVoice = false; 
  bool isMuted = false;
  bool isSpeakerOn = true;
  bool isMyHandRaised = false; 
  bool isAudioConsentGiven = true; 
  Map<String, dynamic>? pendingInvite; 
  Map<String, dynamic>? incomingVoiceCall; 
  bool isRemoteVoiceCallActive = false; 
  final Set<String> usersInLiveSession = {}; 
  
  Map<String, double> userAudioLevels = {}; 

  List<Map<String, dynamic>> onlineUsers = [];
  String? followingUserId;
  final Set<String> whoIsWatchingMe = {}; 
  bool isBroadcastingViewport = false;
  Timer? _viewportBroadcastTimer;
  Timer? _remoteImageSaveTimer; 
  
  Offset? currentViewportCenter;
  double? currentVisibleWidth; 
  Size? lastScreenSize;
  
  Matrix4? _targetMatrix;
  Timer? _smoothTimer;

  StreamSubscription? _usersSubscription;
  StreamSubscription? _strokesSubscription;
  StreamSubscription? _textSubscription;
  StreamSubscription? _imageSubscription;
  StreamSubscription? _viewportSubscription;
  StreamSubscription? _activitySubscription;
  StreamSubscription? _pointerSubscription;
  StreamSubscription? _chatSubscription; 
  StreamSubscription? _audioMessageSubscription; 
  StreamSubscription? _reactionSubscription; 
  StreamSubscription? _collectiveSyncSubscription; 
  StreamSubscription? _globalActionSubscription; // 🚀 Novo
  VoidCallback? _statusListener; 

  final ValueNotifier<Map<String, Offset>> remotePointers = ValueNotifier({});
  final List<Map<String, dynamic>> chatMessages = []; 
  int unreadChatCount = 0;
  bool _isChatOpen = false;
  bool get isChatOpen => _isChatOpen;
  set isChatOpen(bool value) {
    _isChatOpen = value;
    if (value) {
      unreadChatCount = 0;
    }
    safeNotify();
  }

  final StreamController<Map<String, dynamic>> _newMessageAlertController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onNewMessageAlert => _newMessageAlertController.stream;

  final List<Map<String, dynamic>> _pendingChatQueue = [];
  AudioRecorder? _audioRecorderInstance;
  AudioRecorder get _audioRecorder => _audioRecorderInstance ??= AudioRecorder();
  final AudioPlayer _audioPlayer = AudioPlayer();
  String? currentlyPlayingAudioUrl; 
  double audioPlaybackProgress = 0.0; 
  bool isRecording = false;
  DateTime? _recordingStartTime;
  Duration get recordingDuration => _recordingStartTime != null 
      ? DateTime.now().difference(_recordingStartTime!) 
      : Duration.zero;

  final Map<String, String?> userReactions = {}; 
  final Map<String, Timer> _reactionTimers = {};
  DateTime _lastPointerBroadcast = DateTime.now();
  DateTime _lastMoveBroadcastTime = DateTime.now(); 

  Timer? _typingDebounce; 
  Timer? _textBroadcastDebounce; 
  StreamSubscription? _followSubscription;
  StreamSubscription? _pageEventSubscription;
  StreamSubscription? _pageUpdatedSubscription;
  StreamSubscription? _handSubscription;
  StreamSubscription? _uploadingSubscription;
  StreamSubscription? _inviteSubscription; 
  StreamSubscription? _voiceCallSubscription; 
  StreamSubscription? _voiceStateSubscription; 
  StreamSubscription? _audioLevelSubscription; 
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
  final Map<String, String> remoteEditingBlocks = {}; 
  final Map<String, Timer> _editingTimers = {}; 
  final Map<String, Timer> _broadcasterTimers = {};
  final Set<String> remoteUploadingUsers = {}; 
  final Set<String> uploadingImageIds = {}; 
  final Set<String> failedImageUploads = {}; 
  Timer? _autoSyncPushTimer; 
  final List<Map<String, dynamic>> _pendingStrokesQueue = []; 

  Future<void> sendStrokeUpdate({
    required int pageNumber,
    required String strokeId,
    required List<Offset> points,
    bool isFinal = false,
  }) async {
    if (!isRealtimeActive || liveNotebookSid == null) return;

    final data = {
      'page_number': pageNumber,
      'strokes': [{
        'id': strokeId,
        'color': selectedColorHex,
        'thickness': num.parse(selectedThickness.toStringAsFixed(1)),
        'is_final': isFinal,
        'points': points.map((pt) => {
          'x': num.parse(pt.dx.toStringAsFixed(1)),
          'y': num.parse(pt.dy.toStringAsFixed(1)),
        }).toList(),
      }]
    };

    try {
      final success = await _realtimeService.broadcastStroke(
        notebookId: liveNotebookSid!,
        myUserId: myUserId,
        strokeData: data,
      );

      if (!success) {
        _pendingStrokesQueue.add(data);
      } else if (_pendingStrokesQueue.isNotEmpty) {
        _flushPendingStrokes();
      }
    } catch (e) {
      _pendingStrokesQueue.add(data);
    }
  }

  void _flushPendingStrokes() async {
    if (_pendingStrokesQueue.isEmpty || !isRealtimeActive || liveNotebookSid == null) return;
    
    final toSend = List<Map<String, dynamic>>.from(_pendingStrokesQueue);
    _pendingStrokesQueue.clear();

    for (var strokeData in toSend) {
      await _realtimeService.broadcastStroke(
        notebookId: liveNotebookSid!,
        myUserId: myUserId,
        strokeData: strokeData,
      );
    }
  }

  CanvasController(this._realtimeService, {CanvasRepository? repository}) 
      : _repository = repository ?? CanvasRepository(db.AppDatabase.instance) {
    transformationController = TransformationController();
    
    _audioPlayer.onPlayerComplete.listen((_) {
      userAudioLevels.clear();
      audioPlaybackProgress = 0.0;
      _playNextAudioInQueue();
      safeNotify();
    });

    _audioPlayer.onPositionChanged.listen((pos) {
      if (currentlyPlayingAudioUrl == null) return;
      
      _audioPlayer.getDuration().then((duration) {
        if (duration != null && duration.inMilliseconds > 0) {
          audioPlaybackProgress = (pos.inMilliseconds / duration.inMilliseconds).clamp(0.0, 1.0);
        } else {
          final msg = chatMessages.firstWhere((m) => m['audio_url'] == currentlyPlayingAudioUrl, orElse: () => {});
          final int msgDuration = (msg['duration'] as int? ?? 1) * 1000;
          if (msgDuration > 0) {
             audioPlaybackProgress = (pos.inMilliseconds / msgDuration).clamp(0.0, 1.0);
          }
        }
        safeNotify();
      });
    });
    
    _audioPlayer.setVolume(1.0);
  }

  @override
  void dispose() {
    _isDisposed = true;
    activePointsNotifier.dispose();
    remoteLiveStrokes.dispose(); 
    remotePointers.dispose(); 
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
    _handSubscription?.cancel();
    _uploadingSubscription?.cancel();
    _inviteSubscription?.cancel();
    _voiceCallSubscription?.cancel();
    _voiceStateSubscription?.cancel();
    _audioLevelSubscription?.cancel();
    _activitySubscription?.cancel();
    _pointerSubscription?.cancel();
    _chatSubscription?.cancel(); 
    _audioMessageSubscription?.cancel(); 
    _reactionSubscription?.cancel(); 
    _collectiveSyncSubscription?.cancel(); 
    _globalActionSubscription?.cancel(); // 🚀
    if (_statusListener != null) {
      _realtimeService.statusNotifier.removeListener(_statusListener!);
    }
    
    _viewportBroadcastTimer?.cancel();
    _autoSyncPushTimer?.cancel();
    _typingDebounce?.cancel(); 
    _textBroadcastDebounce?.cancel(); 
    _roomSyncDebouncer?.cancel(); 
    _remoteImageSaveTimer?.cancel();
    
    for (var timer in _broadcasterTimers.values) { timer.cancel(); }
    for (var timer in _editingTimers.values) { timer.cancel(); } 
    
    _broadcasterTimers.clear();
    _editingTimers.clear();
    chatMessages.clear(); 
    unreadChatCount = 0;

    if (pages.isNotEmpty && isRealtimeActive && liveNotebookSid != null) {
      _flushPendingStrokes(); 
      final currentPage = pages[currentPageIndex];
      _repository.savePageToCloud(currentPage, liveNotebookSid!, myUserId);
    }

    _audioPlayer.dispose();
    _audioRecorderInstance?.dispose();
    _audioRecorderInstance = null;
    _newMessageAlertController.close();
    if (liveNotebookSid != null && liveNotebookSid != 0) {
      _realtimeService.leaveNotebookChannel(liveNotebookSid!);
    }
    SyncService.isCollaborationActive = false;
    super.dispose();
  }

  bool _isCreatingFirstPage = false; // 🚀 Impedir criação dupla

  Future<void> initNotebook(int notebookId, int? notebookSid, String lineType, String paperSize, String role, [String? userId]) async {
    isLoading = true;
    currentNotebookId = notebookId;
    liveNotebookSid = notebookSid;
    liveLineType = lineType;
    currentPaperSize = paperSize;
    currentUserRole = role;
    if (userId != null) {
      myUserId = userId;
      _realtimeService.listenToUserAccount(int.parse(userId), () {});
    }
    
    SyncService.isCollaborationActive = false;

    _dbNotebookSubscription?.cancel();
    final database = db.AppDatabase.instance;
    _dbNotebookSubscription = (database.select(database.notebooks)..where((t) => t.id.equals(notebookId))).watchSingle().listen((row) {
      if (!_isDisposed && row.serverId != null && liveNotebookSid == null) {
        liveNotebookSid = row.serverId;
        safeNotify();
      }
    });

    _dbPagesSubscription?.cancel();
    _dbPagesSubscription = _repository.watchPagesByNotebook(notebookId).listen((fullPages) async {
      if (fullPages.isEmpty && isLoading && !_isCreatingFirstPage) {
        _isCreatingFirstPage = true;
        
        // 🛡️ Verificar se o servidor já tem páginas antes de criar a local
        await Future.delayed(const Duration(milliseconds: 800)); // Pequena pausa para o sync chegar
        
        final freshCheck = await _repository.getPagesByNotebook(notebookId, liveNotebookSid);
        if (freshCheck.isEmpty) {
          final firstPage = await _repository.createNewPage(notebookId, 1, false, liveNotebookSid);
          if (firstPage != null) {
            _resetZoomForPage(firstPage, paperSize);
            pages = [firstPage];
          }
        }
        _isCreatingFirstPage = false;
      } else {
        pages = fullPages;
        
        // 🚀 RE-VINCULAR REFERÊNCIAS ATIVAS APÓS ATUALIZAÇÃO DO BANCO (Resiliente)
        if (activeTextBlock != null && activeInlineTarget == InlineTarget.block) {
          try {
            // Tentar encontrar na página atual primeiro
            final currentPage = pages.length > currentPageIndex ? pages[currentPageIndex] : null;
            if (currentPage != null) {
              activeTextBlock = currentPage.textBlocks.firstWhere((t) => t.id == activeTextBlock!.id);
            } else {
              // Fallback: procurar em todas as páginas se o index mudou
              for (var p in pages) {
                final found = p.textBlocks.where((t) => t.id == activeTextBlock!.id);
                if (found.isNotEmpty) {
                  activeTextBlock = found.first;
                  break;
                }
              }
            }
          } catch (_) {
            // Bloco realmente sumiu (deletado por outro colega, por exemplo)
            activeInlineTarget = InlineTarget.none;
            activeTextBlock = null;
          }
        }
        
        if (isLoading && pages.isNotEmpty) {
          _resetZoomForPage(pages.first, paperSize);
        }
      }
      
      isLoading = false;
      safeNotify();
    });
  }

  Future<void> toggleCollaboration(bool enable) async {
    if (isCollaborationEnabled == enable) return;
    
    isCollaborationEnabled = enable;
    SyncService.isCollaborationActive = enable;
    
    if (enable) {
      if (liveNotebookSid == null || liveNotebookSid == 0) {
        try {
          await SyncService().pushOfflineSubjects();
          await SyncService().pushNotebooks();
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {}
      }

      if (liveNotebookSid != null && liveNotebookSid != 0) {
        await initRealtimeCollaboration();
        isRealtimeActive = true;
        
        if (currentUserRole == 'owner' || currentUserRole == 'editor') {
          _realtimeService.broadcastLiveInvite(
            notebookId: liveNotebookSid!, 
            myUserId: myUserId, 
            senderName: "Um colega",
            targetUserIds: [],
          );
        }
      } else {
        isCollaborationEnabled = false;
        SyncService.isCollaborationActive = false;
        isRealtimeActive = false;
      }
    } else {
      if (liveNotebookSid != null) _realtimeService.leaveNotebookChannel(liveNotebookSid!);
      chatMessages.clear(); 
      unreadChatCount = 0;
      isLiveSessionActive = false;
      isRealtimeActive = false;
      onlineUsers = [];
    }
    safeNotify();
  }

  void _resetZoomForPage(LocalPage page, String paperSize) {
    final double initialScale = (paperSize == 'A0' || paperSize == 'A1') ? 0.25 : 1.4;
    transformationController.value = Matrix4.identity()..scale(initialScale);
  }

  void setThickness(double thickness) { selectedThickness = thickness; safeNotify(); }
  void setColor(String hex) { selectedColorHex = hex; safeNotify(); }
  
  void setTextColor(String hex) {
    if (activeTextBlock != null) {
      final oldBlock = activeTextBlock!.clone();
      activeTextBlock!.textColorHex = hex;
      recordTextUpdate(pages[currentPageIndex], oldBlock, activeTextBlock!.clone());
      safeNotify();
    }
  }

  void toggleBold() {
    if (activeTextBlock != null) {
      final oldBlock = activeTextBlock!.clone();
      activeTextBlock!.isBold = !activeTextBlock!.isBold;
      recordTextUpdate(pages[currentPageIndex], oldBlock, activeTextBlock!.clone());
      safeNotify();
    }
  }

  void toggleItalic() {
    if (activeTextBlock != null) {
      final oldBlock = activeTextBlock!.clone();
      activeTextBlock!.isItalic = !activeTextBlock!.isItalic;
      recordTextUpdate(pages[currentPageIndex], oldBlock, activeTextBlock!.clone());
      safeNotify();
    }
  }

  void toggleUnderline() {
    if (activeTextBlock != null) {
      final oldBlock = activeTextBlock!.clone();
      activeTextBlock!.isUnderline = !activeTextBlock!.isUnderline;
      recordTextUpdate(pages[currentPageIndex], oldBlock, activeTextBlock!.clone());
      safeNotify();
    }
  }

  void updateFontSize(double delta) {
    if (activeTextBlock != null) {
      final oldBlock = activeTextBlock!.clone();
      activeTextBlock!.fontSize = (activeTextBlock!.fontSize + delta).clamp(10.0, 72.0);
      recordTextUpdate(pages[currentPageIndex], oldBlock, activeTextBlock!.clone());
      safeNotify();
    }
  }

  void recordTextUpdate(LocalPage page, TextBlock oldState, TextBlock newState) {
    newState.updatedAt = DateTime.now().millisecondsSinceEpoch; // 🚀 Atualizar tempo
    final action = UpdateTextAction(
      pageNumber: page.pageNumber,
      textId: newState.id,
      oldState: oldState,
      newState: newState,
    );
    _executeAction(action);
    
    // 🚀 REFRESH REFERENCE: Garante que o controller trabalha na nova instância do bloco
    final updatedBlock = page.textBlocks.firstWhere((t) => t.id == newState.id, orElse: () => newState);
    if (activeTextBlock?.id == newState.id) {
      activeTextBlock = updatedBlock;
    }
  }

  void setTextEditing(InlineTarget target, [TextBlock? block]) {
    final oldBlock = activeTextBlock;
    activeInlineTarget = target;
    activeTextBlock = block;
    safeNotify();

    if (block != null) {
      broadcastTextBlockUpdate(pages[currentPageIndex], block, isEditing: true);
    } else if (oldBlock != null) {
      broadcastTextBlockUpdate(pages[currentPageIndex], oldBlock, isEditing: false);
    }
  }

  void _markUserBroadcasting(String userId) {
    if (!activeBroadcasters.contains(userId)) {
      activeBroadcasters.add(userId);
      safeNotify();
    }
    _broadcasterTimers[userId]?.cancel();
    _broadcasterTimers[userId] = Timer(const Duration(seconds: 4), () {
      if (activeBroadcasters.contains(userId)) {
        activeBroadcasters.remove(userId);
        _broadcasterTimers.remove(userId);
        safeNotify();
      }
    });
  }

  Future<void> initRealtimeCollaboration() async {
    final realtime = _realtimeService;
    
    if (liveNotebookSid == null || liveNotebookSid == 0) {
      isCollaborationEnabled = false;
      SyncService.isCollaborationActive = false;
      safeNotify();
      return;
    }

    await realtime.initConnection();
    final int channelId = liveNotebookSid!;

    _usersSubscription?.cancel();
    _usersSubscription = realtime.onUsersUpdated.listen((usersList) {
      if (_isDisposed) return;
      
      final int previousCount = onlineUsers.length;
      onlineUsers = usersList.map((u) {
        final map = Map<String, dynamic>.from(u);
        final String uid = map['id'].toString();
        
        if (map['isInCall'] == true) usersInLiveSession.add(uid);

        int idAsInt = int.tryParse(uid) ?? 0;
        
        return {
          'id': uid,
          'name': map['name'] ?? 'Colega',
          'color': avatarColorsPool[idAsInt % avatarColorsPool.length],
          'isTalking': map['isTalking'] ?? false,
          'activity': map['activity'] ?? 'idle', 
          'isHandRaised': map['isHandRaised'] ?? false,
          'isInCall': usersInLiveSession.contains(uid), 
        };
      }).toList();

      if (followingUserId != null && !onlineUsers.any((u) => u['id'] == followingUserId)) {
        followingUserId = null;
      }

      isRemoteVoiceCallActive = onlineUsers.any((u) => u['id'].toString() != myUserId && u['isInCall'] == true);

      if (usersInLiveSession.any((uid) => uid != myUserId) && !isLiveSessionActive && incomingVoiceCall == null) {
        incomingVoiceCall = {'sender_name': 'A sala'};
        isRemoteVoiceCallActive = true;
      }

      if (onlineUsers.length > previousCount && previousCount > 0) {
        // 🚀 UM NOVO COLEGA ENTROU: Disparar alinhamento de segurança
        _debounceRoomSync();
        _realtimeService.requestCollectiveSync(myUserId: myUserId);
      } else if (onlineUsers.length < previousCount) {
        // 🚪 ALGUÉM SAIU: Garantir que o nosso estado está na nuvem
        _repository.savePageToCloud(pages[currentPageIndex], liveNotebookSid!, myUserId);
      }

      if (isRealtimeActive && previousCount == 0 && onlineUsers.isNotEmpty) {
        // 🏁 ENTRADA INICIAL: Sync total
        _debounceRoomSync();
      }

      safeNotify();
    });

    _collectiveSyncSubscription?.cancel();
    _collectiveSyncSubscription = realtime.onCollectiveSyncRequested.listen((data) {
      if (_isDisposed) return;
      if (data['sender_id'].toString() != myUserId) _performCollectiveSync();
    });

    _globalActionSubscription?.cancel();
    _globalActionSubscription = realtime.onGlobalActionReceived.listen((data) {
      if (_isDisposed) return;
      final String senderId = data['sender_id'].toString();
      if (senderId == myUserId) return; // Ignorar eco

      final String actionType = data['type'];
      final dynamic payload = data['data'];

      if (actionType == 'undo') {
        _performUndoRemote();
      } else if (actionType == 'redo') {
        _performRedoRemote();
      } else {
        // Receber uma nova ação para a pilha de histórico
        final action = CanvasAction.fromMap(actionType, payload, (num) => _getTargetPage(num));
        if (action != null) {
          _undoStack.add(action);
          _redoStack.clear();
          if (_undoStack.length > 50) _undoStack.removeAt(0);
          safeNotify();
        }
      }
    });

    _activitySubscription?.cancel();
    _activitySubscription = realtime.onUserActivityReceived.listen((data) {
      if (_isDisposed) return;
      _realtimeService.updateUserActivityState(data['sender_id'].toString(), data['activity'].toString());
    });

    _pointerSubscription?.cancel();
    _pointerSubscription = realtime.onPointerMoveReceived.listen((data) {
      if (_isDisposed) return;
      final String uid = data['sender_id'].toString();
      if (uid == myUserId) return;
      
      final pos = Offset((data['x'] as num).toDouble(), (data['y'] as num).toDouble());
      final currentMap = Map<String, Offset>.from(remotePointers.value);
      currentMap[uid] = pos;
      remotePointers.value = currentMap;
    });

    _chatSubscription?.cancel();
    _chatSubscription = realtime.onChatMessageReceived.listen((data) {
      if (_isDisposed) return;
      _addChatMessage(data);
    });

    _audioMessageSubscription?.cancel();
    _audioMessageSubscription = realtime.onAudioMessageReceived.listen((data) {
      if (_isDisposed) return;
      _addChatMessage(data);
      if (isLiveSessionActive && data['is_live'] == true && data['sender_id'] != myUserId) {
        playAudioMessage(data['audio_url']);
      }
    });

    realtime.onChatSyncRequestReceived.listen((data) {
      if (_isDisposed) return;
      if (data['sender_id'].toString() != myUserId && chatMessages.isNotEmpty) {
        _realtimeService.sendChatSyncResponse(targetUserId: data['sender_id'].toString(), history: chatMessages);
      }
    });

    realtime.onChatSyncResponseReceived.listen((data) {
      if (_isDisposed) return;
      if (data['target_id'].toString() == myUserId) {
        final List<dynamic> history = data['history'] ?? [];
        for (var msg in history) _addChatMessage(Map<String, dynamic>.from(msg));
      }
    });

    if (_statusListener != null) _realtimeService.statusNotifier.removeListener(_statusListener!);
    _statusListener = () {
      if (realtime.statusNotifier.value == RealtimeStatus.connected) _flushPendingChat();
    };
    realtime.statusNotifier.addListener(_statusListener!);

    _reactionSubscription?.cancel();
    _reactionSubscription = realtime.onReactionReceived.listen((data) {
      if (_isDisposed) return;
      final String uid = data['sender_id'].toString();
      userReactions[uid] = data['reaction'].toString();
      _reactionTimers[uid]?.cancel();
      _reactionTimers[uid] = Timer(const Duration(seconds: 5), () {
        userReactions[uid] = null;
        safeNotify();
      });
      safeNotify();
    });

    _strokesSubscription?.cancel();
    _strokesSubscription = realtime.onStrokeReceived.listen((data) {
      if (_isDisposed) return;
      try {
        final int incomingPageNum = data['page_number'];
        final String? senderId = data['sender_id']?.toString();
        if (senderId == myUserId || pages.isEmpty) return;

        if (followingUserId != null && senderId == followingUserId) {
          if (currentPageIndex + 1 != incomingPageNum) {
            final targetIdx = incomingPageNum - 1;
            if (targetIdx >= 0 && targetIdx < pages.length) jumpToPage(targetIdx);
          }
        }

        final int targetIdx = pages.indexWhere((p) => p.pageNumber == incomingPageNum);
        if (targetIdx == -1) return;

        final targetPage = pages[targetIdx];

        for (var strokeMap in data['strokes']) {
          final String strokeId = strokeMap['id'];
          final bool isDeleted = strokeMap['is_deleted'] == true;
          final bool isFinal = strokeMap['is_final'] == true;

          if (isDeleted) {
            targetPage.strokes.removeWhere((s) => s.id == strokeId);
            final currentMap = Map<String, Stroke>.from(remoteLiveStrokes.value);
            if (currentMap.containsKey(strokeId)) {
              currentMap.remove(strokeId);
              remoteLiveStrokes.value = currentMap;
            }
            safeNotify();
            if (targetPage.id != null) {
              _repository.deleteSingleStroke(targetPage.id!, strokeId);
              _repository.triggerSyncRadar(targetPage.id!);
            }
            continue;
          }

          final List<Offset> incomingPoints = (strokeMap['points'] as List)
              .map((pt) => Offset((pt['x'] as num).toDouble(), (pt['y'] as num).toDouble()))
              .toList();

          final currentMap = Map<String, Stroke>.from(remoteLiveStrokes.value);
          final existingStroke = currentMap[strokeId];

          if (!isFinal) {
            if (existingStroke != null) {
              existingStroke.points.addAll(incomingPoints);
            } else {
              currentMap[strokeId] = Stroke(
                id: strokeId, 
                color: strokeMap['color'], 
                thickness: (strokeMap['thickness'] as num).toDouble(), 
                points: List<Offset>.from(incomingPoints), 
                pageNumber: incomingPageNum,
              );
            }
            remoteLiveStrokes.value = currentMap;
          } else {
            final newStroke = Stroke(
              id: strokeId, 
              color: strokeMap['color'], 
              thickness: (strokeMap['thickness'] as num).toDouble(), 
              points: incomingPoints, 
              pageNumber: incomingPageNum,
            );

            targetPage.strokes.removeWhere((s) => s.id == strokeId);
            targetPage.strokes.add(newStroke);
            currentMap.remove(strokeId);
            remoteLiveStrokes.value = currentMap;
            safeNotify();
            if (targetPage.id != null) {
              _repository.saveSingleStroke(targetPage.id!, newStroke);
              _repository.triggerSyncRadar(targetPage.id!);
            }
          }
        }
      } catch (e) {}
    });

    _textSubscription?.cancel();
    _textSubscription = realtime.onTextReceived.listen((data) {
      if (_isDisposed) return;
      try {
        final String? senderId = data['sender_id']?.toString();
        if (senderId == myUserId || pages.isEmpty) return;

        final int targetIdx = pages.indexWhere((p) => p.pageNumber == data['page_number']);
        if (targetIdx == -1) return;

        final targetPage = pages[targetIdx];
        final blockData = data['block'];
        final String blockId = blockData['id'];

        if (data['is_editing'] == true) {
          remoteEditingBlocks[blockId] = senderId!;
          _editingTimers[blockId]?.cancel();
          _editingTimers[blockId] = Timer(const Duration(seconds: 5), () {
            remoteEditingBlocks.remove(blockId);
            safeNotify();
          });
        } else {
          remoteEditingBlocks.remove(blockId);
          _editingTimers[blockId]?.cancel();
        }

        if (data['is_deleted'] == true) {
          targetPage.textBlocks.removeWhere((t) => t.id == blockId);
          remoteEditingBlocks.remove(blockId);
        } else {
          final existingIndex = targetPage.textBlocks.indexWhere((t) => t.id == blockId);
          final newBlock = TextBlock.fromJson(blockData);
          if (existingIndex != -1) {
            targetPage.textBlocks.removeAt(existingIndex);
            targetPage.textBlocks.add(newBlock);
          } else {
            targetPage.textBlocks.add(newBlock);
          }
        }
        safeNotify();
        _repository.savePage(targetPage, liveNotebookSid);
      } catch (e) {}
    });

    _imageSubscription?.cancel();
    _imageSubscription = realtime.onImageReceived.listen((data) {
      if (_isDisposed) return;
      try {
        final String? senderId = data['sender_id']?.toString();
        if (senderId == myUserId || pages.isEmpty) return;

        final int targetIdx = pages.indexWhere((p) => p.pageNumber == data['page_number']);
        if (targetIdx == -1) return;

        final targetPage = pages[targetIdx];
        final blockData = data['block'];
        final String blockId = blockData['id'];

        if (data['is_deleted'] == true) {
          targetPage.imageBlocks.removeWhere((img) => img.id == blockId);
        } else {
          final existingIndex = targetPage.imageBlocks.indexWhere((img) => img.id == blockId);
          final newBlock = ImageBlock.fromJson(blockData);
          if (existingIndex != -1) {
            targetPage.imageBlocks.removeAt(existingIndex);
            targetPage.imageBlocks.add(newBlock);
          } else {
            targetPage.imageBlocks.add(newBlock);
          }
        }
        safeNotify();

        _remoteImageSaveTimer?.cancel();
        _remoteImageSaveTimer = Timer(const Duration(seconds: 1), () {
          _repository.savePage(targetPage, liveNotebookSid);
        });
      } catch (e) {}
    });

    _pageUpdatedSubscription?.cancel();
    _pageUpdatedSubscription = realtime.onPageUpdated.listen((data) {
      if (_isDisposed) return;
      try {
        if (data['sender_id']?.toString() == myUserId) return;

        final int pageId = data['id'];
        final targetPage = pages.firstWhere(
          (p) => p.serverId == pageId || (p.pageNumber == data['page_number']),
          orElse: () => pages[currentPageIndex],
        );

        targetPage.serverId = pageId;
        if (data['header_data'] != null) targetPage.title = LocalPage.parseMeta(data['header_data']);
        if (data['footer_data'] != null) targetPage.footer = LocalPage.parseMeta(data['footer_data']);
        
        if (data['stroke_data'] != null) {
          final List strokeList = (data['stroke_data'] is String) ? jsonDecode(data['stroke_data']) : data['stroke_data'];
          targetPage.strokes = strokeList.map((s) => Stroke.fromJson(Map<String, dynamic>.from(s))).toList();
        }
        if (data['text_data'] != null) {
          final List textList = (data['text_data'] is String) ? jsonDecode(data['text_data']) : data['text_data'];
          targetPage.textBlocks = textList.map((t) => TextBlock.fromJson(Map<String, dynamic>.from(t))).toList();
        }
        if (data['image_data'] != null) {
          final List imageList = (data['image_data'] is String) ? jsonDecode(data['image_data']) : data['image_data'];
          targetPage.imageBlocks = imageList.map((img) => ImageBlock.fromJson(Map<String, dynamic>.from(img))).toList();
        }

        safeNotify();
        _repository.savePage(targetPage, liveNotebookSid);
      } catch (e) {}
    });

    _viewportSubscription?.cancel();
    _viewportSubscription = realtime.onViewportReceived.listen((data) {
      if (_isDisposed) return;
      final String senderId = data['sender_id'].toString();
      _markUserBroadcasting(senderId);

      if (followingUserId == null || senderId != followingUserId) return;

      final int? incomingPageNum = data['page_number'];
      if (incomingPageNum != null && currentPageIndex + 1 != incomingPageNum) {
        final targetIdx = incomingPageNum - 1;
        if (targetIdx >= 0 && targetIdx < pages.length) jumpToPage(targetIdx);
      }

      if (lastScreenSize != null && (data['visibleWidth'] as num).toDouble() > 0) {
        final screenCenter = Offset(lastScreenSize!.width / 2, lastScreenSize!.height / 2);
        double adaptiveScale = lastScreenSize!.width / (data['visibleWidth'] as num).toDouble();
        adaptiveScale = adaptiveScale.clamp(lastScreenSize!.width < 600 ? 1.2 : 0.8, 3.5);

        final currentMatrix = transformationController.value;
        final screenPoint = currentMatrix.transform3(Vector3((data['focusX'] as num).toDouble(), (data['focusY'] as num).toDouble(), 0));

        final Rect safeZone = Rect.fromCenter(center: screenCenter, width: lastScreenSize!.width * 0.95, height: lastScreenSize!.height * 0.6);

        if (!safeZone.contains(Offset(screenPoint.x, screenPoint.y)) || (currentMatrix.getMaxScaleOnAxis() - adaptiveScale).abs() > 0.1) {
          _startSmoothTransition(Matrix4.identity()..translate(screenCenter.dx, screenCenter.dy)..scale(adaptiveScale)..translate(-(data['focusX'] as num).toDouble(), -(data['focusY'] as num).toDouble()));
        }
      }
    });

    _followSubscription?.cancel();
    _followSubscription = realtime.onFollowUpdateReceived.listen((data) {
      if (_isDisposed) return;
      final String fid = data['follower_id'].toString();
      if (data['following_id']?.toString() == myUserId) {
        whoIsWatchingMe.add(fid);
      } else {
        whoIsWatchingMe.remove(fid);
      }
      safeNotify();
    });

    _pageEventSubscription?.cancel();
    _pageEventSubscription = realtime.onPageEventReceived.listen((data) async {
      if (_isDisposed || data['sender_id']?.toString() == myUserId) return;
      try {
        if (data['notebook_sid'] != liveNotebookSid) return;
        final String action = data['action'];
        final int pageNumber = data['page_number'];

        if (action == 'add') {
          if (!pages.any((p) => p.pageNumber == pageNumber)) {
            final newPage = LocalPage(notebookId: currentNotebookId, pageNumber: pageNumber, isLandscape: data['is_landscape'] ?? false);
            _resetZoomForPage(newPage, currentPaperSize);
            pages.add(newPage);
            pages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
            safeNotify();
            await _repository.savePage(newPage, liveNotebookSid);
          }
        } else if (action == 'delete') {
          final index = pages.indexWhere((p) => p.pageNumber == pageNumber);
          if (index != -1) {
            final pageToDelete = pages[index];
            pages.removeAt(index);
            if (currentPageIndex >= pages.length) currentPageIndex = pages.length - 1;
            if (currentPageIndex < 0) currentPageIndex = 0;
            safeNotify();
            if (pageController.hasClients) pageController.jumpToPage(currentPageIndex);
            if (pageToDelete.id != null) await _repository.deletePage(pageToDelete.id!);
          }
        } else if (action == 'metadata_update') {
          final index = pages.indexWhere((p) => p.pageNumber == pageNumber);
          if (index != -1) {
            final targetPage = pages[index];
            if (data.containsKey('line_type')) liveLineType = data['line_type'];
            if (data.containsKey('header_data')) targetPage.title = LocalPage.parseMeta(data['header_data']);
            if (data.containsKey('footer_data')) targetPage.footer = LocalPage.parseMeta(data['footer_data']);
            safeNotify();
            await _repository.savePage(targetPage, liveNotebookSid);
          }
        }
      } catch (e) {}
    });

    _handSubscription?.cancel();
    _handSubscription = realtime.onHandEventReceived.listen((data) {
      if (_isDisposed) return;
      _realtimeService.updateUserHandState(data['sender_id'].toString(), data['is_raised'] == true);
      safeNotify();
    });

    _uploadingSubscription?.cancel();
    _uploadingSubscription = realtime.onRemoteUploading.listen((data) {
      if (data['is_uploading'] == true) {
        remoteUploadingUsers.add(data['sender_id'].toString());
      } else {
        remoteUploadingUsers.remove(data['sender_id'].toString());
      }
      safeNotify();
    });

    _inviteSubscription?.cancel();
    _inviteSubscription = realtime.onLiveInviteReceived.listen((data) {
      if (_isDisposed || isRealtimeActive) return;
      if (data['notebook_id'] == liveNotebookSid || data['notebook_id'] == currentNotebookId) {
        pendingInvite = data;
        safeNotify();
      }
    });

    _voiceCallSubscription?.cancel();
    _voiceCallSubscription = realtime.onVoiceCallStarted.listen((data) {
      if (_isDisposed || data['sender_id'] == myUserId || isLiveSessionActive) return;
      incomingVoiceCall = data;
      isRemoteVoiceCallActive = true;
      safeNotify();
    });

    _voiceStateSubscription?.cancel();
    _voiceStateSubscription = realtime.onVoiceStateReceived.listen((data) {
      if (_isDisposed) return;
      final String uid = data['sender_id'].toString();
      if (data['is_in_call'] == true) {
        usersInLiveSession.add(uid);
        isRemoteVoiceCallActive = true;
      } else {
        usersInLiveSession.remove(uid);
        userAudioLevels.remove(uid);
        if (usersInLiveSession.isEmpty || (usersInLiveSession.length == 1 && usersInLiveSession.contains(myUserId))) {
          isRemoteVoiceCallActive = false;
        }
      }
      safeNotify();
    });

    await realtime.joinNotebookChannel(notebookId: channelId);
    onlineUsers = realtime.getConnectedUsers();
    Future.delayed(const Duration(seconds: 1), () {
      if (!_isDisposed && isRealtimeActive) _realtimeService.requestChatSync(myUserId: myUserId);
    });
    safeNotify();
  }

  Timer? _roomSyncDebouncer;
  bool _hasSyncedInThisSession = false;

  void _addChatMessage(Map<String, dynamic> data) {
    final String? msgId = data['msg_id']?.toString();
    if (msgId != null && chatMessages.any((m) => m['msg_id'] == msgId)) return;
    chatMessages.add(data);
    if (chatMessages.length > 50) chatMessages.removeAt(0);
    if (!_isChatOpen && data['sender_id'] != myUserId) {
      unreadChatCount++;
      _newMessageAlertController.add(data); 
    }
    safeNotify();
  }

  Future<void> _performCollectiveSync() async {
    if (isGlobalSyncing) return;
    isGlobalSyncing = true;
    safeNotify();
    try {
      // 🚀 VIEWERS NÃO ENVIAM DADOS OFFLINE, APENAS RECEBEM
      if (currentUserRole != 'viewer') {
        await SyncService().pushPages();
      }
      
      await SyncService().pullPages();
      final freshPages = await _repository.getPagesByNotebook(currentNotebookId, liveNotebookSid);
      if (freshPages.isNotEmpty) pages = freshPages;
    } catch (e) {
    } finally {
      isGlobalSyncing = false;
      safeNotify();
    }
  }

  void _debounceRoomSync() {
    if (_hasSyncedInThisSession) return;
    _roomSyncDebouncer?.cancel();
    _roomSyncDebouncer = Timer(const Duration(milliseconds: 500), () async {
      isGlobalSyncing = true; // 🚀 Mostrar badge durante debounce sync
      safeNotify();
      try {
        // 🚀 SE FOR VIEWER, PULA O PUSH E SÓ FAZ PULL
        bool syncSuccess = true;
        if (currentUserRole != 'viewer') {
          syncSuccess = await SyncService().pushPages();
        }
        
        if (syncSuccess) {
          await SyncService().pullPages();
          final remotePages = await _repository.getPagesByNotebook(currentNotebookId, liveNotebookSid);
          if (remotePages.isNotEmpty) {
            pages = remotePages;
            _hasSyncedInThisSession = true;
          }
        }
      } catch (e) {
      } finally {
        isGlobalSyncing = false;
        safeNotify();
      }
    });
  }

  void sendChatMessage(String message) {
    if (liveNotebookSid == null) return;
    final msg = {'type': 'text', 'sender_id': myUserId, 'message': message, 'timestamp': DateTime.now().toIso8601String()};
    _addChatMessage(msg);
    if (isRealtimeActive && _realtimeService.isConnected) {
      _realtimeService.broadcastChatMessage(notebookId: liveNotebookSid!, myUserId: myUserId, message: message);
    } else {
      _pendingChatQueue.add(msg);
    }
  }

  void _flushPendingChat() async {
    if (_pendingChatQueue.isEmpty || !isRealtimeActive || liveNotebookSid == null || !_realtimeService.isConnected) return;
    final toSend = List<Map<String, dynamic>>.from(_pendingChatQueue);
    _pendingChatQueue.clear();
    for (var msg in toSend) {
      if (msg['type'] == 'text') {
        await _realtimeService.broadcastChatMessage(notebookId: liveNotebookSid!, myUserId: myUserId, message: msg['message']);
      } else if (msg['type'] == 'audio') {
        await _realtimeService.broadcastAudioMessage(notebookId: liveNotebookSid!, myUserId: myUserId, audioUrl: msg['audio_url'], duration: msg['duration']);
      }
    }
  }

  Future<void> startRecording() async {
    try {
      if (_isDisposed || isRecording) return;
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        await _audioRecorder.start(const RecordConfig(), path: path);
        isRecording = true;
        _recordingStartTime = DateTime.now();
        safeNotify();
      }
    } catch (e) {}
  }

  Future<void> stopAndSendAudio() async {
    try {
      if (_isDisposed || !isRecording) return;
      final path = await _audioRecorder.stop();
      isRecording = false;
      final duration = recordingDuration.inSeconds;
      _recordingStartTime = null;
      safeNotify();
      if (path != null && liveNotebookSid != null && liveNotebookSid != 0) {
        final audioUrl = await _repository.uploadAudio(liveNotebookSid!, path.split('/').last, await File(path).readAsBytes());
        if (audioUrl != null) {
          final msg = {'type': 'audio', 'sender_id': myUserId, 'audio_url': audioUrl, 'duration': duration, 'timestamp': DateTime.now().toIso8601String()};
          _addChatMessage(msg);
          if (isRealtimeActive && _realtimeService.isConnected) {
            _realtimeService.broadcastAudioMessage(notebookId: liveNotebookSid!, myUserId: myUserId, audioUrl: audioUrl, duration: duration, isLive: isLiveSessionActive);
          } else {
            _pendingChatQueue.add(msg);
          }
        }
      }
    } catch (e) {
      isRecording = false;
      safeNotify();
    }
  }

  Future<void> playAudioMessage(String url, {String? senderId}) async {
    if (currentlyPlayingAudioUrl == url) {
      currentlyPlayingAudioUrl = null;
      if (senderId != null) userAudioLevels[senderId] = 0.0;
      await _audioPlayer.pause();
      safeNotify();
      return;
    }
    userAudioLevels.clear();
    audioPlaybackProgress = 0.0;
    currentlyPlayingAudioUrl = url;
    final effectiveSenderId = senderId ?? chatMessages.firstWhere((m) => m['audio_url'] == url, orElse: () => {})['sender_id']?.toString();
    if (effectiveSenderId != null) userAudioLevels[effectiveSenderId] = 0.5;
    safeNotify();
    try {
      await _audioPlayer.stop();
      await _audioPlayer.release();
      await Future.delayed(const Duration(milliseconds: 200)); 
      await _audioPlayer.setVolume(isSpeakerOn ? 1.0 : 0.0);
      await _audioPlayer.play(UrlSource(url));
    } catch (e) {
      userAudioLevels.clear();
      safeNotify();
    }
  }

  void _playNextAudioInQueue() async {
    if (currentlyPlayingAudioUrl == null) return;
    int currentIndex = chatMessages.indexWhere((m) => m['audio_url'] == currentlyPlayingAudioUrl);
    currentlyPlayingAudioUrl = null;
    safeNotify();
    if (currentIndex != -1 && currentIndex < chatMessages.length - 1) {
      for (int i = currentIndex + 1; i < chatMessages.length; i++) {
        if (chatMessages[i]['type'] == 'audio') {
          await Future.delayed(const Duration(milliseconds: 800));
          if (!_isDisposed) await playAudioMessage(chatMessages[i]['audio_url']);
          break;
        }
      }
    }
  }

  void sendReaction(String emoji) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    userReactions[myUserId] = emoji;
    _reactionTimers[myUserId]?.cancel();
    _reactionTimers[myUserId] = Timer(const Duration(seconds: 5), () {
      userReactions[myUserId] = null;
      safeNotify();
    });
    _realtimeService.broadcastReaction(notebookId: liveNotebookSid!, myUserId: myUserId, reaction: emoji);
    safeNotify();
  }

  Future<void> triggerAutoSave(LocalPage page) async {
    await _repository.savePage(page, liveNotebookSid);
    if (isRealtimeActive && liveNotebookSid != null && liveNotebookSid != 0) {
      _autoSyncPushTimer?.cancel();
      _autoSyncPushTimer = Timer(const Duration(milliseconds: 1500), () async {
        await _repository.savePageToCloud(page, liveNotebookSid!, myUserId);
      });
    }
  }

  void switchTool(ToolMode newMode) {
    if (newMode == ToolMode.eraser && (selectedStrokeIds.isNotEmpty || selectedTextIds.isNotEmpty || selectedImageIds.isNotEmpty)) {
      deleteSelection(pages[currentPageIndex]);
      return; 
    }
    currentTool = newMode;
    
    // 🚀 LIMPAR SELEÇÃO AO TROCAR DE FERRAMENTA
    selectedEditingImageId = null;
    
    if (newMode != ToolMode.select && newMode != ToolMode.eraser) {
      selectedStrokeIds.clear(); selectedTextIds.clear(); selectedImageIds.clear();
      selectionRectStart = null; selectionRectEnd = null;
      isMovingStrokes = false;
    }
    safeNotify();
  }

  void zoom(double factor, Size screenSize) {
    final matrix = transformationController.value;
    matrix.translate(screenSize.width / 2, screenSize.height / 2);
    matrix.scale(factor);
    matrix.translate(-(screenSize.width / 2), -(screenSize.height / 2));
    transformationController.value = matrix;
    safeNotify();
  }

  void broadcastPageMetadataUpdate(LocalPage page) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    _realtimeService.broadcastPageEvent(notebookId: liveNotebookSid!, myUserId: myUserId, pageData: {'action': 'metadata_update', 'notebook_sid': liveNotebookSid, 'page_number': page.pageNumber, 'line_type': liveLineType, 'header_data': {'title': page.title}, 'footer_data': {'title': page.footer}});
  }

  void setLineType(String type, LocalPage page) { 
    liveLineType = type; 
    safeNotify(); 
    broadcastPageMetadataUpdate(page);
    triggerAutoSave(page);
  }
  void setPageIndex(int index) { 
    if (currentPageIndex == index) return;
    currentPageIndex = index; 
    safeNotify(); 
  }

  void jumpToPage(int index) {
    if (index < 0 || index >= pages.length) return;
    setPageIndex(index);
    pageController.jumpToPage(index);
  }

  Future<void> addNewPage(bool isLandscape) async {
    int maxPage = 0;
    for (var p in pages) if (p.pageNumber > maxPage) maxPage = p.pageNumber;
    final newPage = LocalPage(notebookId: currentNotebookId, pageNumber: maxPage + 1, isLandscape: isLandscape);
    _resetZoomForPage(newPage, currentPaperSize);
    pages.add(newPage);
    safeNotify();
    await triggerAutoSave(newPage);
    if (isRealtimeActive && liveNotebookSid != null) {
      _realtimeService.broadcastPageEvent(notebookId: liveNotebookSid!, myUserId: myUserId, pageData: {'action': 'add', 'notebook_sid': liveNotebookSid, 'page_number': maxPage + 1, 'is_landscape': isLandscape});
    }
    pageController.animateToPage(pages.length - 1, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
  }

  void deletePage(LocalPage pageToDelete) async {
    final int pNum = pageToDelete.pageNumber;
    pages.remove(pageToDelete);
    if (currentPageIndex >= pages.length) currentPageIndex = pages.length - 1;
    if (currentPageIndex < 0) currentPageIndex = 0;
    safeNotify();
    Future.microtask(() { if (pageController.hasClients) pageController.jumpToPage(currentPageIndex); });
    if (pageToDelete.id != null) {
      await _repository.deletePage(pageToDelete.id!);
      SyncService().pushPages();
    }
    if (isRealtimeActive && liveNotebookSid != null) {
      _realtimeService.broadcastPageEvent(notebookId: liveNotebookSid!, myUserId: myUserId, pageData: {'action': 'delete', 'notebook_sid': liveNotebookSid, 'page_number': pNum});
    }
    if (pages.isNotEmpty) triggerAutoSave(pages[currentPageIndex]);
  }

  void eraseAtPosition(Offset pos, LocalPage page) {
    if (selectedStrokeIds.isNotEmpty || selectedTextIds.isNotEmpty || selectedImageIds.isNotEmpty) {
      deleteSelection(page);
    } else {
      final List<Stroke> sToRemove = page.strokes.where((s) => s.points.any((pt) => (pt - pos).distance < 24.0)).toList();
      final List<TextBlock> tToRemove = page.textBlocks.where((tb) => Rect.fromLTWH(tb.position.dx, tb.position.dy, 150, tb.fontSize * 1.5).contains(pos) || (tb.position - pos).distance < 24.0).toList();
      final List<ImageBlock> iToRemove = page.imageBlocks.where((img) => Rect.fromLTWH(img.position.dx, img.position.dy, img.width, img.height).contains(pos)).toList();

      if (sToRemove.isNotEmpty || tToRemove.isNotEmpty || iToRemove.isNotEmpty) {
        // 🚀 MARCAR COMO DELETADO NO CONTEXTO ATUAL
        final bool inSession = isRealtimeActive && liveNotebookSid != null;
        for (var s in sToRemove) { s.isDeleted = true; s.deletedInSession = inSession; s.updatedAt = DateTime.now().millisecondsSinceEpoch; }
        for (var t in tToRemove) { t.isDeleted = true; t.deletedInSession = inSession; t.updatedAt = DateTime.now().millisecondsSinceEpoch; }
        for (var img in iToRemove) { img.isDeleted = true; img.deletedInSession = inSession; img.updatedAt = DateTime.now().millisecondsSinceEpoch; }

        _executeAction(DeleteAction(
          pageNumber: page.pageNumber,
          strokes: sToRemove,
          texts: tToRemove,
          images: iToRemove,
        ));
      }
    }
  }

  void deleteSelection(LocalPage page) {
    if (selectedStrokeIds.isEmpty && selectedTextIds.isEmpty && selectedImageIds.isEmpty) return;
    final strokesToRemove = page.strokes.where((s) => selectedStrokeIds.contains(s.id)).toList();
    final textsToRemove = page.textBlocks.where((t) => selectedTextIds.contains(t.id)).toList();
    final imagesToRemove = page.imageBlocks.where((img) => selectedImageIds.contains(img.id)).toList();
    if (strokesToRemove.isEmpty && textsToRemove.isEmpty && imagesToRemove.isEmpty) return;

    final bool inSession = isRealtimeActive && liveNotebookSid != null;
    final int now = DateTime.now().millisecondsSinceEpoch;
    for (var s in strokesToRemove) { s.isDeleted = true; s.deletedInSession = inSession; s.updatedAt = now; }
    for (var t in textsToRemove) { t.isDeleted = true; t.deletedInSession = inSession; t.updatedAt = now; }
    for (var img in imagesToRemove) { img.isDeleted = true; img.deletedInSession = inSession; img.updatedAt = now; }

    _executeAction(DeleteAction(pageNumber: page.pageNumber, strokes: strokesToRemove, texts: textsToRemove, images: imagesToRemove));
    selectedStrokeIds.clear(); selectedTextIds.clear(); selectedImageIds.clear();
    safeNotify();
  }

  void addStroke(LocalPage page, Stroke stroke) => _executeAction(AddStrokeAction(pageNumber: page.pageNumber, stroke: stroke));
  void addTextBlock(LocalPage page, TextBlock block) => _executeAction(AddTextAction(pageNumber: page.pageNumber, block: block));

  void bringImageToFront(LocalPage page, String imageId) {
    final idx = page.imageBlocks.indexWhere((img) => img.id == imageId);
    if (idx != -1 && idx != page.imageBlocks.length - 1) {
      final img = page.imageBlocks.removeAt(idx);
      page.imageBlocks.add(img);
      safeNotify();
      triggerAutoSave(page);
      
      // 📢 Sincronizar ordem com outros via broadcast manual (Z-Index)
      if (isRealtimeActive && liveNotebookSid != null) {
        _realtimeService.broadcastImageBlock(notebookId: liveNotebookSid!, myUserId: myUserId, imageData: {
          'page_number': page.pageNumber,
          'block': img.toJson(),
        });
      }
    }
  }

  void recordImageUpdate(LocalPage page, ImageBlock oldState, ImageBlock newState) {
    // Só gravar se houve mudança real
    if (oldState.position != newState.position || oldState.width != newState.width || oldState.height != newState.height) {
      newState.updatedAt = DateTime.now().millisecondsSinceEpoch; // 🚀 Atualizar tempo
      _executeAction(UpdateImageAction(
        pageNumber: page.pageNumber,
        imageId: newState.id,
        oldState: oldState,
        newState: newState,
      ));
    }
  }

  LocalPage? _getTargetPage(int pageNumber) {
    try {
      return pages.firstWhere((p) => p.pageNumber == pageNumber);
    } catch (e) {
      debugPrint('⚠️ [Canvas] Página $pageNumber não encontrada na lista atual.');
      return null;
    }
  }

  void _executeAction(CanvasAction action, {bool isRemote = false}) {
    final targetPage = _getTargetPage(action.pageNumber);
    if (targetPage == null) return;

    // 🚀 VIEWERS NÃO EXECUTAM AÇÕES PERSISTENTES LOCAIS (OFFLINE)
    if (currentUserRole == 'viewer' && !isRemote) {
      debugPrint('🚫 [Canvas] Viewer impedido de gravar ação persistente.');
      return;
    }

    action.execute(targetPage);
    
    // 🚀 ADICIONAR À PILHA (Sempre, para que todos possam desfazer tudo)
    if (isRemote) {
      // Se for remota, precisamos garantir que o histórico tenha a mesma ordem
      _undoStack.add(action);
      _redoStack.clear();
      if (_undoStack.length > 50) _undoStack.removeAt(0);
    } else {
      _undoStack.add(action);
      _redoStack.clear();
      if (_undoStack.length > 50) _undoStack.removeAt(0);
    }
    
    // Sincronização e Save
    triggerAutoSave(targetPage);

    // 🚀 BROADCAST DA AÇÃO PARA A PILHA DOS OUTROS
    if (!isRemote && isRealtimeActive && liveNotebookSid != null) {
      _realtimeService.broadcastGlobalAction(
        notebookId: liveNotebookSid!, 
        actionData: {
          'sender_id': myUserId,
          'type': action.type,
          'data': action.toMap(),
        }
      );
    }
    
    _broadcastAction(action); // Sincronização visual imediata
    safeNotify(); 
  }

  void _broadcastAction(CanvasAction action) {
    if (!isRealtimeActive || liveNotebookSid == null) return;

    if (action is DeleteAction) {
      for (var s in action.strokes) {
        _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: {
          'page_number': action.pageNumber, 'strokes': [{'id': s.id, 'is_deleted': true}]
        });
      }
      for (var t in action.texts) {
        _realtimeService.broadcastTextBlock(notebookId: liveNotebookSid!, myUserId: myUserId, textData: {
          'page_number': action.pageNumber, 'block': {'id': t.id}, 'is_deleted': true
        });
      }
      for (var img in action.images) {
        _realtimeService.broadcastImageBlock(notebookId: liveNotebookSid!, myUserId: myUserId, imageData: {
          'page_number': action.pageNumber, 'block': {'id': img.id}, 'is_deleted': true
        });
      }
    } else if (action is AddStrokeAction) {
       _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: {
          'page_number': action.pageNumber,
          'strokes': [{
            'id': action.stroke.id, 'color': action.stroke.color, 'thickness': action.stroke.thickness, 'is_final': true,
            'points': action.stroke.points.map((pt) => {'x': pt.dx, 'y': pt.dy}).toList(),
          }]
        });
    } else if (action is AddTextAction) {
      _realtimeService.broadcastTextBlock(notebookId: liveNotebookSid!, myUserId: myUserId, textData: {
        'page_number': action.pageNumber,
        'block': action.block.toJson(),
        'is_editing': false,
      });
    } else if (action is AddImageAction) {
      if (action.block.imagePath.startsWith('http')) {
        _realtimeService.broadcastImageBlock(notebookId: liveNotebookSid!, myUserId: myUserId, imageData: {
          'page_number': action.pageNumber,
          'block': action.block.toJson(),
        });
      }
    } else if (action is UpdateImageAction) {
      _realtimeService.broadcastImageBlock(notebookId: liveNotebookSid!, myUserId: myUserId, imageData: {
        'page_number': action.pageNumber,
        'block': action.newState.toJson(),
      });
    } else if (action is UpdateTextAction) {
      _realtimeService.broadcastTextBlock(notebookId: liveNotebookSid!, myUserId: myUserId, textData: {
        'page_number': action.pageNumber,
        'block': action.newState.toJson(),
        'is_editing': true,
      });
    }
  }

  void _performUndoRemote() {
    if (_undoStack.isEmpty) return;
    final action = _undoStack.removeLast();
    final targetPage = _getTargetPage(action.pageNumber);
    if (targetPage != null) {
      action.undo(targetPage);
      _redoStack.add(action);
      triggerAutoSave(targetPage);
    }
    safeNotify();
  }

  void _performRedoRemote() {
    if (_redoStack.isEmpty) return;
    final action = _redoStack.removeLast();
    final targetPage = _getTargetPage(action.pageNumber);
    if (targetPage != null) {
      action.execute(targetPage);
      _undoStack.add(action);
      triggerAutoSave(targetPage);
    }
    safeNotify();
  }

  void undo(LocalPage page) {
    if (_undoStack.isEmpty) return;
    
    // 📢 AVISAR OUTROS PRIMEIRO
    if (isRealtimeActive && liveNotebookSid != null) {
      _realtimeService.broadcastGlobalAction(
        notebookId: liveNotebookSid!,
        actionData: {'sender_id': myUserId, 'type': 'undo'},
      );
    }

    _performUndoRemote();
  }

  void redo(LocalPage page) {
    if (_redoStack.isEmpty) return;

    if (isRealtimeActive && liveNotebookSid != null) {
      _realtimeService.broadcastGlobalAction(
        notebookId: liveNotebookSid!,
        actionData: {'sender_id': myUserId, 'type': 'redo'},
      );
    }

    _performRedoRemote();
  }

  Future<void> pickAndInsertImage(LocalPage page) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pickedFile != null) {
      final String localId = const Uuid().v4();
      final newImageBlock = ImageBlock(id: localId, imagePath: pickedFile.path, position: const Offset(100, 150), width: 300.0, height: 200.0);
      _executeAction(AddImageAction(pageNumber: page.pageNumber, block: newImageBlock));
      
      currentTool = ToolMode.imageEdit;
      selectedEditingImageId = localId; // 🚀 Seleciona automaticamente para edição
      safeNotify();
      if (isRealtimeActive && liveNotebookSid != null) {
        uploadingImageIds.add(localId);
        failedImageUploads.remove(localId);
        _realtimeService.broadcastImageUploading(notebookId: liveNotebookSid!, myUserId: myUserId, isUploading: true);
        safeNotify();
        _repository.uploadImage(liveNotebookSid!, pickedFile.name, await pickedFile.readAsBytes()).then((remoteUrl) {
          uploadingImageIds.remove(localId);
          _realtimeService.broadcastImageUploading(notebookId: liveNotebookSid!, myUserId: myUserId, isUploading: false);
          if (remoteUrl != null) {
            newImageBlock.imagePath = remoteUrl;
            _repository.saveSingleImageBlock(page.id!, newImageBlock);
            broadcastImageBlockUpdate(page, newImageBlock, myUserId);
            _broadcastSelectionMovement(page); 
            triggerAutoSave(page); 
          } else {
            failedImageUploads.add(localId);
          }
          safeNotify();
        }).catchError((e) {
          uploadingImageIds.remove(localId);
          failedImageUploads.add(localId);
          _realtimeService.broadcastImageUploading(notebookId: liveNotebookSid!, myUserId: myUserId, isUploading: false);
          safeNotify();
        });
      }
    }
  }

  Future<void> retryImageUpload(LocalPage page, ImageBlock img) async {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    final localId = img.id;
    if (!failedImageUploads.contains(localId)) return;
    uploadingImageIds.add(localId);
    failedImageUploads.remove(localId);
    _realtimeService.broadcastImageUploading(notebookId: liveNotebookSid!, myUserId: myUserId, isUploading: true);
    safeNotify();
    try {
      final bytes = await File(img.imagePath).readAsBytes();
      final remoteUrl = await _repository.uploadImage(liveNotebookSid!, img.imagePath.split('/').last, bytes);
      uploadingImageIds.remove(localId);
      _realtimeService.broadcastImageUploading(notebookId: liveNotebookSid!, myUserId: myUserId, isUploading: false);
      if (remoteUrl != null) {
        img.imagePath = remoteUrl;
        _repository.saveSingleImageBlock(page.id!, img);
        broadcastImageBlockUpdate(page, img, myUserId);
      } else {
        failedImageUploads.add(localId);
      }
      safeNotify();
    } catch (e) {
      uploadingImageIds.remove(localId);
      failedImageUploads.add(localId);
      _realtimeService.broadcastImageUploading(notebookId: liveNotebookSid!, myUserId: myUserId, isUploading: false);
      safeNotify();
    }
  }

  Future<void> deleteImageBlock(LocalPage page, ImageBlock img) async {
    final bool inSession = isRealtimeActive && liveNotebookSid != null;
    img.isDeleted = true;
    img.deletedInSession = inSession;
    img.updatedAt = DateTime.now().millisecondsSinceEpoch;
    
    _executeAction(DeleteAction(pageNumber: page.pageNumber, strokes: [], texts: [], images: [img]));
    safeNotify();
  }

  void updateSelectionRect(LocalPage page, Offset currentPos) {
    selectionRectEnd = currentPos;
    if (selectionRectStart != null && selectionRectEnd != null) {
      final rect = Rect.fromPoints(selectionRectStart!, selectionRectEnd!);
      selectedStrokeIds.clear(); selectedTextIds.clear(); selectedImageIds.clear();
      for (var s in page.strokes) if (s.points.any((pt) => rect.contains(pt))) selectedStrokeIds.add(s.id);
      for (var tb in page.textBlocks) if (rect.contains(tb.position)) selectedTextIds.add(tb.id);
      for (var img in page.imageBlocks) if (rect.overlaps(Rect.fromLTWH(img.position.dx, img.position.dy, img.width, img.height))) selectedImageIds.add(img.id);
    }
    safeNotify();
  }

  void moveSelectedStrokes(LocalPage page, Offset delta) {
    for (var id in selectedStrokeIds) {
      final matches = page.strokes.where((s) => s.id == id);
      if (matches.isNotEmpty) for (int i = 0; i < matches.first.points.length; i++) matches.first.points[i] += delta;
    }
    for (var id in selectedTextIds) {
      final matches = page.textBlocks.where((t) => t.id == id);
      if (matches.isNotEmpty) matches.first.position += delta;
    }
    for (var id in selectedImageIds) {
      final matches = page.imageBlocks.where((img) => img.id == id);
      if (matches.isNotEmpty) matches.first.position += delta;
    }
    safeNotify();
    final now = DateTime.now();
    if (now.difference(_lastMoveBroadcastTime).inMilliseconds > 30) {
      _broadcastSelectionMovement(page);
      _lastMoveBroadcastTime = now;
    }
  }

  void _broadcastSelectionMovement(LocalPage page) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    for (var id in selectedStrokeIds) {
      final matches = page.strokes.where((s) => s.id == id);
      if (matches.isNotEmpty) _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: {'page_number': page.pageNumber, 'strokes': [{'id': id, 'color': matches.first.color, 'thickness': matches.first.thickness, 'is_final': true, 'points': matches.first.points.map((pt) => {'x': pt.dx, 'y': pt.dy}).toList()}]});
    }
    for (var id in selectedTextIds) {
      final matches = page.textBlocks.where((t) => t.id == id);
      if (matches.isNotEmpty) broadcastTextBlockUpdate(page, matches.first);
    }
    for (var id in selectedImageIds) {
      final matches = page.imageBlocks.where((img) => img.id == id);
      if (matches.isNotEmpty) broadcastImageBlockUpdate(page, matches.first);
    }
  }

  void setUserActivity(String activity) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    _realtimeService.broadcastUserActivity(notebookId: liveNotebookSid!, myUserId: myUserId, activity: activity);
    _realtimeService.updateUserActivityState(myUserId, activity);
  }

  void onTyping() {
    setUserActivity('typing');
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () => setUserActivity('idle'));
  }

  void broadcastTextBlockUpdate(LocalPage page, TextBlock block, {String? senderId, bool debounced = false, bool isEditing = false, bool isDeleted = false}) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    if (isEditing) onTyping();
    if (debounced) {
      _textBroadcastDebounce?.cancel();
      _textBroadcastDebounce = Timer(const Duration(milliseconds: 150), () => _sendTextBlockSignal(page, block, senderId: senderId, isEditing: isEditing, isDeleted: isDeleted));
    } else {
      _sendTextBlockSignal(page, block, senderId: senderId, isEditing: isEditing, isDeleted: isDeleted);
    }
  }

  void _sendTextBlockSignal(LocalPage page, TextBlock block, {String? senderId, bool isEditing = false, bool isDeleted = false}) => 
      _realtimeService.broadcastTextBlock(
        notebookId: liveNotebookSid!, 
        textData: {
          'sender_id': senderId ?? myUserId, 
          'page_number': page.pageNumber, 
          'block': block.toJson(), 
          'is_editing': isEditing,
          'is_deleted': isDeleted,
        }
      );

  void forceNotify() => safeNotify();

  void broadcastImageBlockUpdate(LocalPage page, ImageBlock block, [String? senderId]) {
    if (isRealtimeActive && liveNotebookSid != null && block.imagePath.startsWith('http')) {
      _realtimeService.broadcastImageBlock(notebookId: liveNotebookSid!, myUserId: senderId ?? myUserId, imageData: {'page_number': page.pageNumber, 'block': block.toJson()});
    }
  }

  void broadcastThrottledImageUpdate(LocalPage page, ImageBlock block) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    final now = DateTime.now();
    if (now.difference(_lastMoveBroadcastTime).inMilliseconds > 30) {
      broadcastImageBlockUpdate(page, block);
      _lastMoveBroadcastTime = now;
    }
  }

  void broadcastThrottledTextBlockUpdate(LocalPage page, TextBlock block) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    final now = DateTime.now();
    if (now.difference(_lastMoveBroadcastTime).inMilliseconds > 50) {
      broadcastTextBlockUpdate(page, block, debounced: false);
      _lastMoveBroadcastTime = now;
    }
  }

  void broadcastPointer(Offset pos) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    final now = DateTime.now();
    if (now.difference(_lastPointerBroadcast).inMilliseconds > 100) {
      _realtimeService.broadcastPointerMove(notebookId: liveNotebookSid!, myUserId: myUserId, pos: pos);
      _lastPointerBroadcast = now;
    }
  }

  void acceptInvite() { pendingInvite = null; toggleCollaboration(true); }
  void dismissInvite() { pendingInvite = null; safeNotify(); }
  void acceptVoiceCall() { incomingVoiceCall = null; toggleVoiceCall(myUserId); }
  void dismissVoiceCall() { incomingVoiceCall = null; safeNotify(); }

  Future<void> toggleVoiceCall(String myUserId) async {
    if (isConnectingVoice) return;
    isConnectingVoice = true; safeNotify();
    if (isLiveSessionActive) {
      isLiveSessionActive = false; usersInLiveSession.remove(myUserId); userAudioLevels.clear();
      _realtimeService.broadcastVoiceStateUpdate(notebookId: liveNotebookSid ?? currentNotebookId, myUserId: myUserId, isInCall: false);
    } else {
      if (isRemoteVoiceCallActive || currentUserRole == 'owner' || currentUserRole == 'editor') {
        isLiveSessionActive = true; usersInLiveSession.add(myUserId);
        _realtimeService.broadcastVoiceStateUpdate(notebookId: liveNotebookSid ?? currentNotebookId, myUserId: myUserId, isInCall: true);
        if (!isRemoteVoiceCallActive) _realtimeService.broadcastVoiceCallStarted(notebookId: liveNotebookSid ?? currentNotebookId, myUserId: myUserId, senderName: "Um colega");
      }
    }
    isConnectingVoice = false; safeNotify();
  }

  Future<void> requestAudioConsent() async { if (!isAudioConsentGiven && await _audioRecorder.hasPermission()) { isAudioConsentGiven = true; safeNotify(); } }
  void handleLiveAudioAction() => isRecording ? stopAndSendAudio() : startRecording();
  void toggleSpeaker() { isSpeakerOn = !isSpeakerOn; _audioPlayer.setVolume(isSpeakerOn ? 1.0 : 0.0); safeNotify(); }
  void toggleHandRaise() {
    isMyHandRaised = !isMyHandRaised;
    safeNotify();
    if (isRealtimeActive && liveNotebookSid != null) {
      _realtimeService.broadcastHandEvent(notebookId: liveNotebookSid!, myUserId: myUserId, isRaised: isMyHandRaised);
      _realtimeService.updateUserHandState(myUserId, isMyHandRaised);
    }
  }

  void toggleFollowUser(String? userId, String myId) {
    if (userId == myId) return;
    followingUserId = (followingUserId == userId) ? null : userId;
    if (liveNotebookSid != null) _realtimeService.broadcastFollowUpdate(notebookId: liveNotebookSid!, myUserId: myId, followingUserId: followingUserId);
    safeNotify();
  }

  void startViewportBroadcasting(String effectiveUserId) {
    if (isBroadcastingViewport) return;
    isBroadcastingViewport = true; safeNotify(); 
    _viewportBroadcastTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!isRealtimeActive || liveNotebookSid == null || !isBroadcastingViewport) { timer.cancel(); return; }
      if (currentViewportCenter != null && currentVisibleWidth != null && effectiveUserId.isNotEmpty) {
        _realtimeService.broadcastViewport(notebookId: liveNotebookSid!, viewportData: {'page_number': currentPageIndex + 1, 'focusX': currentViewportCenter!.dx, 'focusY': currentViewportCenter!.dy, 'visibleWidth': currentVisibleWidth}, myUserId: effectiveUserId);
      }
    });
  }

  void _startSmoothTransition(Matrix4 target) {
    _targetMatrix = target;
    if (_smoothTimer != null && _smoothTimer!.isActive) return;
    _smoothTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_targetMatrix == null) { timer.cancel(); return; }
      final current = transformationController.value;
      final next = Matrix4.identity();
      for (int i = 0; i < 16; i++) next.storage[i] = current.storage[i] + (_targetMatrix!.storage[i] - current.storage[i]) * 0.04;
      transformationController.value = next; safeNotify();
      double diff = 0;
      for (int i = 0; i < 16; i++) diff += (next.storage[i] - _targetMatrix!.storage[i]).abs();
      if (diff < 0.001) { transformationController.value = _targetMatrix!; _targetMatrix = null; timer.cancel(); safeNotify(); }
    });
  }

  void stopViewportBroadcasting() { isBroadcastingViewport = false; _viewportBroadcastTimer?.cancel(); _viewportBroadcastTimer = null; safeNotify(); }

  // =========================================================================
  // 📋 EXPORTAÇÃO E CLIPBOARD
  // =========================================================================
  
  void copyToClipboard(String text, BuildContext context) {
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text)).then((_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Texto copiado para a área de transferência!'),
            backgroundColor: Color(0xFF0F4C5C),
            duration: Duration(seconds: 2),
          ),
        );
      }
    });
  }

  void exportPageText(LocalPage page, BuildContext context) {
    StringBuffer fullText = StringBuffer();
    
    // 1. Título da página
    if (page.title.isNotEmpty) {
      fullText.writeln('Título: ${page.title}');
      fullText.writeln('=' * 20);
    }
    
    // 2. Texto Extraído (OCR)
    if (page.extractedText != null && page.extractedText!.trim().isNotEmpty) {
      fullText.writeln('Texto Escrito à Mão:');
      fullText.writeln(page.extractedText);
      fullText.writeln('-' * 10);
    }
    
    // 3. Blocos de Texto Digital
    if (page.textBlocks.isNotEmpty) {
      fullText.writeln('Anotações Digitais:');
      // Ordenar por posição Y para manter a ordem de leitura
      final sortedBlocks = List<TextBlock>.from(page.textBlocks)
        ..sort((a, b) => a.position.dy.compareTo(b.position.dy));
        
      for (var block in sortedBlocks) {
        if (block.text.trim().isNotEmpty) {
          fullText.writeln(block.text);
        }
      }
    }
    
    final result = fullText.toString().trim();
    if (result.isNotEmpty) {
      copyToClipboard(result, context);
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não há texto nesta folha para exportar.'),
            backgroundColor: Colors.orangeAccent,
          ),
        );
      }
    }
  }
}

abstract class CanvasAction {
  final int pageNumber;
  CanvasAction(this.pageNumber);
  void execute(LocalPage page);
  void undo(LocalPage page);
  
  String get type;
  Map<String, dynamic> toMap();

  static CanvasAction? fromMap(String type, Map<String, dynamic> data, LocalPage? Function(int) getPage) {
    final int pageNum = data['pageNumber'];
    if (type == 'addStroke') {
      return AddStrokeAction(pageNumber: pageNum, stroke: Stroke.fromJson(data['stroke']));
    } else if (type == 'delete') {
      return DeleteAction(
        pageNumber: pageNum,
        strokes: (data['strokes'] as List).map((s) => Stroke.fromJson(s)).toList(),
        texts: (data['texts'] as List).map((t) => TextBlock.fromJson(t)).toList(),
        images: (data['images'] as List).map((i) => ImageBlock.fromJson(i)).toList(),
      );
    } else if (type == 'addText') {
      return AddTextAction(pageNumber: pageNum, block: TextBlock.fromJson(data['block']));
    } else if (type == 'addImage') {
      return AddImageAction(pageNumber: pageNum, block: ImageBlock.fromJson(data['block']));
    } else if (type == 'updateImage') {
      return UpdateImageAction(
        pageNumber: pageNum,
        imageId: data['imageId'],
        oldState: ImageBlock.fromJson(data['oldState']),
        newState: ImageBlock.fromJson(data['newState']),
      );
    } else if (type == 'updateText') {
      return UpdateTextAction(
        pageNumber: pageNum,
        textId: data['textId'],
        oldState: TextBlock.fromJson(data['oldState']),
        newState: TextBlock.fromJson(data['newState']),
      );
    }
    return null;
  }
}

class AddStrokeAction extends CanvasAction {
  final Stroke stroke;
  AddStrokeAction({required int pageNumber, required this.stroke}) : super(pageNumber);

  @override String get type => 'addStroke';
  @override Map<String, dynamic> toMap() => {'pageNumber': pageNumber, 'stroke': stroke.toJson()};

  @override void execute(LocalPage page) {
    if (!page.strokes.any((s) => s.id == stroke.id)) {
      page.strokes.add(stroke.clone());
    }
  }
  @override void undo(LocalPage page) => page.strokes.removeWhere((s) => s.id == stroke.id);
}

class DeleteAction extends CanvasAction {
  final List<Stroke> strokes;
  final List<TextBlock> texts;
  final List<ImageBlock> images;
  DeleteAction({required int pageNumber, required this.strokes, required this.texts, required this.images}) : super(pageNumber);

  @override String get type => 'delete';
  @override Map<String, dynamic> toMap() => {
    'pageNumber': pageNumber,
    'strokes': strokes.map((s) => s.toJson()).toList(),
    'texts': texts.map((t) => t.toJson()).toList(),
    'images': images.map((i) => i.toJson()).toList(),
  };

  @override void execute(LocalPage page) {
    for (var s in strokes) page.strokes.removeWhere((item) => item.id == s.id);
    for (var t in texts) page.textBlocks.removeWhere((item) => item.id == t.id);
    for (var img in images) page.imageBlocks.removeWhere((item) => item.id == img.id);
  }
  @override void undo(LocalPage page) {
    page.strokes.addAll(strokes.map((s) => s.clone()));
    page.textBlocks.addAll(texts.map((t) => t.clone()));
    page.imageBlocks.addAll(images.map((i) => i.clone()));
  }
}

class AddTextAction extends CanvasAction {
  final TextBlock block;
  AddTextAction({required int pageNumber, required this.block}) : super(pageNumber);

  @override String get type => 'addText';
  @override Map<String, dynamic> toMap() => {'pageNumber': pageNumber, 'block': block.toJson()};

  @override void execute(LocalPage page) {
    if (!page.textBlocks.any((t) => t.id == block.id)) {
      page.textBlocks.add(block);
    }
  }
  @override void undo(LocalPage page) => page.textBlocks.removeWhere((t) => t.id == block.id);
}

class AddImageAction extends CanvasAction {
  final ImageBlock block;
  AddImageAction({required int pageNumber, required this.block}) : super(pageNumber);

  @override String get type => 'addImage';
  @override Map<String, dynamic> toMap() => {'pageNumber': pageNumber, 'block': block.toJson()};

  @override void execute(LocalPage page) {
    if (!page.imageBlocks.any((img) => img.id == block.id)) {
      page.imageBlocks.add(block);
    }
  }
  @override void undo(LocalPage page) => page.imageBlocks.removeWhere((img) => img.id == block.id);
}

class UpdateImageAction extends CanvasAction {
  final String imageId;
  final ImageBlock oldState;
  final ImageBlock newState;

  UpdateImageAction({required int pageNumber, required this.imageId, required this.oldState, required this.newState}) : super(pageNumber);

  @override String get type => 'updateImage';
  @override Map<String, dynamic> toMap() => {
    'pageNumber': pageNumber,
    'imageId': imageId,
    'oldState': oldState.toJson(),
    'newState': newState.toJson(),
  };

  @override void execute(LocalPage page) {
    final idx = page.imageBlocks.indexWhere((img) => img.id == imageId);
    if (idx != -1) page.imageBlocks[idx] = newState.clone();
  }

  @override void undo(LocalPage page) {
    final idx = page.imageBlocks.indexWhere((img) => img.id == imageId);
    if (idx != -1) page.imageBlocks[idx] = oldState.clone();
  }
}

class UpdateTextAction extends CanvasAction {
  final String textId;
  final TextBlock oldState;
  final TextBlock newState;

  UpdateTextAction({required int pageNumber, required this.textId, required this.oldState, required this.newState}) : super(pageNumber);

  @override String get type => 'updateText';
  @override Map<String, dynamic> toMap() => {
    'pageNumber': pageNumber,
    'textId': textId,
    'oldState': oldState.toJson(),
    'newState': newState.toJson(),
  };

  @override void execute(LocalPage page) {
    final idx = page.textBlocks.indexWhere((t) => t.id == textId);
    if (idx != -1) page.textBlocks[idx] = newState.clone();
  }

  @override void undo(LocalPage page) {
    final idx = page.textBlocks.indexWhere((t) => t.id == textId);
    if (idx != -1) page.textBlocks[idx] = oldState.clone();
  }
}

final canvasProvider = ChangeNotifierProvider.autoDispose<CanvasController>((ref) {
  return CanvasController(ref.read(realtimeServiceProvider), repository: ref.read(canvasRepositoryProvider));
});
