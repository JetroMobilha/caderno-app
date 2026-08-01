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

  bool _isDisposed = false; // 🛡️ Flag de segurança

  void safeNotify() {
    if (!_isDisposed) {
      notifyListeners(); 
    }
  }

  List<LocalPage> pages = [];
  int currentPageIndex = 0;
  bool isLoading = true;
  bool isUploadingImage = false; // ☁️ Indicador de upload para a UI
  bool isGlobalSyncing = false; // 🔒 Trava de interface para alinhamento coletivo

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
  final Set<String> selectedImageIds = {};

  // 🚀 NOVO SISTEMA DE UNDO/REDO BASEADO EM AÇÕES
  final List<CanvasAction> _undoStack = [];
  final List<CanvasAction> _redoStack = [];

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  Offset? selectionRectStart;
  Offset? selectionRectEnd;
  bool isMovingStrokes = false;
  Offset? lastPanOffset;

  bool isRealtimeActive = false;
  bool isCollaborationEnabled = false; // 🌐 Decisão do utilizador de ficar online
  bool isLiveSessionActive = false; // 🚀 Substitui isLiveSessionActive
  bool isConnectingVoice = false; // ⏳ Flag de carregamento
  bool isMuted = false;
  bool isSpeakerOn = true;
  bool isMyHandRaised = false; // ✋ Estado local para "Pedir a Palavra"
  bool isAudioConsentGiven = true; // 🚀 CONSENTIMENTO AUTOMÁTICO (Banner resolve segurança)
  Map<String, dynamic>? pendingInvite; // 🔔 Convite de sessão recebido
  Map<String, dynamic>? incomingVoiceCall; // 🎙️ Notificação de chamada iniciada
  bool isRemoteVoiceCallActive = false; // 🟢 Indica se já existe uma chamada na sala
  final Set<String> usersInLiveSession = {}; // 👥 IDs dos utilizadores na sessão live
  
  Map<String, double> userAudioLevels = {}; // 🎙️ Níveis de áudio por user (Simulado por player)

  List<Map<String, dynamic>> onlineUsers = [];
  String? followingUserId;
  final Set<String> whoIsWatchingMe = {}; // 👥 Utilizadores que me estão a seguir
  bool isBroadcastingViewport = false;
  Timer? _viewportBroadcastTimer;
  Timer? _remoteImageSaveTimer; // 🚀 Novo: Para evitar lag no disco ao mover imagens remotas
  
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
  StreamSubscription? _activitySubscription;
  StreamSubscription? _pointerSubscription;
  StreamSubscription? _chatSubscription; // 🚀 Novo
  StreamSubscription? _audioMessageSubscription; // 🚀 Novo
  StreamSubscription? _reactionSubscription; // 🚀 Novo
  StreamSubscription? _collectiveSyncSubscription; // 🚀 Novo
  VoidCallback? _statusListener; // 🚀 Novo

  final ValueNotifier<Map<String, Offset>> remotePointers = ValueNotifier({});
  final List<Map<String, dynamic>> chatMessages = []; // 💬 Mensagens de chat
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
  String? currentlyPlayingAudioUrl; // 🎧 Rastreio de áudio ativo
  double audioPlaybackProgress = 0.0; // 🚀 Progresso real (0.0 a 1.0)
  bool isRecording = false;
  DateTime? _recordingStartTime;
  Duration get recordingDuration => _recordingStartTime != null 
      ? DateTime.now().difference(_recordingStartTime!) 
      : Duration.zero;

  final Map<String, String?> userReactions = {}; // 🎭 userId -> reaction (emoji)
  final Map<String, Timer> _reactionTimers = {};
  DateTime _lastPointerBroadcast = DateTime.now();
  DateTime _lastMoveBroadcastTime = DateTime.now(); // 🚀 Para throttling de movimento

  Timer? _typingDebounce; // ✍️ Timer para idle status
  Timer? _textBroadcastDebounce; // ✍️ Debounce para envio de texto
  StreamSubscription? _followSubscription;
  StreamSubscription? _pageEventSubscription;
  StreamSubscription? _pageUpdatedSubscription;
  StreamSubscription? _handSubscription;
  StreamSubscription? _uploadingSubscription;
  StreamSubscription? _inviteSubscription; // 🚀 Novo
  StreamSubscription? _voiceCallSubscription; // 🚀 Novo
  StreamSubscription? _voiceStateSubscription; // 🚀 Novo
  StreamSubscription? _audioLevelSubscription; // 🚀 Separado para evitar colisão
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

  final Set<String> activeBroadcasters = {}; // 🚀 Restaurado
  final Map<String, String> remoteEditingBlocks = {}; // ✍️ blockId -> userId (Soft Lock)
  final Map<String, Timer> _editingTimers = {}; // Timers para limpar locks órfãos
  final Map<String, Timer> _broadcasterTimers = {};
  final Set<String> remoteUploadingUsers = {}; // 👥 Utilizadores a carregar ficheiros
  final Set<String> uploadingImageIds = {}; // 🖼️ IDs das imagens em upload de fundo
  final Set<String> failedImageUploads = {}; // ❌ IDs das imagens que falharam o upload
  Timer? _autoSyncPushTimer; // 🚀 Timer para o Dono enviar dados para a nuvem
  final List<Map<String, dynamic>> _pendingStrokesQueue = []; // 🚀 Fila para resiliência

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
        debugPrint('⏳ [OfflineSync] Traço guardado na fila (Falha no envio)');
      } else if (_pendingStrokesQueue.isNotEmpty) {
        _flushPendingStrokes();
      }
    } catch (e) {
      _pendingStrokesQueue.add(data);
      debugPrint('⚠️ [OfflineSync] Erro de rede. Traço em fila: $e');
    }
  }

  void _flushPendingStrokes() async {
    if (_pendingStrokesQueue.isEmpty || !isRealtimeActive || liveNotebookSid == null) return;
    
    debugPrint('🚀 [OfflineSync] Despejando ${_pendingStrokesQueue.length} traços pendentes...');
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
      debugPrint('🎧 [Audio] Reprodução concluída.');
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
          // Fallback: usar a duração da mensagem do chat se o player falhar em dar o total
          final msg = chatMessages.firstWhere((m) => m['audio_url'] == currentlyPlayingAudioUrl, orElse: () => {});
          final int msgDuration = (msg['duration'] as int? ?? 1) * 1000;
          if (msgDuration > 0) {
             audioPlaybackProgress = (pos.inMilliseconds / msgDuration).clamp(0.0, 1.0);
          }
        }
        safeNotify();
      });
    });
    
    // 🎧 Inicializar volume para Windows/Desktop
    _audioPlayer.setVolume(1.0);
  }

  @override
  void dispose() {
    _isDisposed = true;
    activePointsNotifier.dispose();
    remoteLiveStrokes.dispose(); // 🚀
    remotePointers.dispose(); // 🚀
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
    _chatSubscription?.cancel(); // 🚀
    _audioMessageSubscription?.cancel(); // 🚀
    _reactionSubscription?.cancel(); // 🚀
    _collectiveSyncSubscription?.cancel(); // 🚀
    if (_statusListener != null) {
      _realtimeService.statusNotifier.removeListener(_statusListener!);
    }
    
    _viewportBroadcastTimer?.cancel();
    _autoSyncPushTimer?.cancel();
    _typingDebounce?.cancel(); // 🚀
    _textBroadcastDebounce?.cancel(); // 🚀
    _roomSyncDebouncer?.cancel(); // 🚀
    
    for (var timer in _broadcasterTimers.values) { timer.cancel(); }
    for (var timer in _editingTimers.values) { timer.cancel(); } // 🚀
    
    _broadcasterTimers.clear();
    _editingTimers.clear();
    chatMessages.clear(); // 🚀 Limpar histórico volátil
    unreadChatCount = 0;

    // 🚀 FINAL PUSH: Tentar salvar a última versão antes de fechar
    if (pages.isNotEmpty && isRealtimeActive && liveNotebookSid != null) {
      _flushPendingStrokes(); // 📢 Enviar traços pendentes
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
    if (isLiveSessionActive) isLiveSessionActive = false;
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
    if (userId != null) {
      myUserId = userId;
      // 📡 LIGAR CANAL PRIVADO PARA CONVITES
      _realtimeService.listenToUserAccount(int.parse(userId), () {
        // Callback para sync global se necessário
      });
    }
    
    SyncService.isCollaborationActive = false;

    // 📡 ASSINAR METADADOS DO CADERNO (Reatividade para o Server ID)
    _dbNotebookSubscription?.cancel();
    final database = db.AppDatabase.instance;
    _dbNotebookSubscription = (database.select(database.notebooks)..where((t) => t.id.equals(notebookId))).watchSingle().listen((row) {
      if (!_isDisposed && row.serverId != null && liveNotebookSid == null) {
        debugPrint('☁️ [Canvas] Server ID detetado via reatividade do banco!');
        liveNotebookSid = row.serverId;
        safeNotify();
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
      safeNotify();
    });
  }

  Future<void> toggleCollaboration(bool enable) async {
    if (isCollaborationEnabled == enable) return;
    
    isCollaborationEnabled = enable;
    SyncService.isCollaborationActive = enable;
    
    if (enable) {
      debugPrint('🌐 [Canvas] Ativando modo colaborativo...');
      
      // 🚀 TENTAR OBTER SERVER ID SE ESTIVER EM FALTA
      if (liveNotebookSid == null || liveNotebookSid == 0) {
        debugPrint('☁️ [Canvas] Server ID em falta. A tentar sincronizar caderno...');
        try {
          await SyncService().pushOfflineSubjects();
          await SyncService().pushNotebooks();
          // O listener no initNotebook deve apanhar o novo serverId via reatividade do Drift
          
          // Aguardar um pouco para a reatividade do banco disparar
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          debugPrint('❌ [Canvas] Falha na sincronização pré-colaboração: $e');
        }
      }

      if (liveNotebookSid != null && liveNotebookSid != 0) {
        await initRealtimeCollaboration();
        isRealtimeActive = true;
        
        // 🚀 NOTIFICAR COLEGAS (Se eu for o dono ou editor a iniciar)
        if (currentUserRole == 'owner' || currentUserRole == 'editor') {
          _realtimeService.broadcastLiveInvite(
            notebookId: liveNotebookSid!, 
            myUserId: myUserId, 
            senderName: "Um colega", // Pode ser melhorado com o nome real
            targetUserIds: [], // O servidor deve enviar para todos os colaboradores
          );
        }
      } else {
        debugPrint('⚠️ [Canvas] Ainda sem Server ID. Colaboração indisponível.');
        isCollaborationEnabled = false;
        SyncService.isCollaborationActive = false;
        isRealtimeActive = false;
      }
    } else {
      debugPrint('📴 [Canvas] Entrando em modo offline (por opção)...');
      if (liveNotebookSid != null) _realtimeService.leaveNotebookChannel(liveNotebookSid!);
      chatMessages.clear(); // 🚀 O chat morre quando a colaboração termina
      unreadChatCount = 0;
      if (isLiveSessionActive) {
        isLiveSessionActive = false;
        isLiveSessionActive = false;
      }
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
      activeTextBlock!.textColorHex = hex;
      safeNotify();
      broadcastTextBlockUpdate(pages[currentPageIndex], activeTextBlock!);
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
      // 🔓 Libertar Soft Lock
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
    
    // 🛡️ SEGURANÇA CRÍTICA: Impedir colisão de IDs locais em canais globais
    if (liveNotebookSid == null || liveNotebookSid == 0) {
      debugPrint('🚨 [Canvas] Erro: Tentativa de colaboração sem ID de Servidor. Abortando.');
      isCollaborationEnabled = false;
      SyncService.isCollaborationActive = false;
      safeNotify();
      return;
    }

    await realtime.initConnection();
    final int channelId = liveNotebookSid!;

    // 🚀 CORREÇÃO DE PRESENÇA: Configurar listeners ANTES de entrar na sala
    _usersSubscription?.cancel();
    _usersSubscription = realtime.onUsersUpdated.listen((usersList) {
      if (_isDisposed) return;
      
      final int previousCount = onlineUsers.length;
      final List<String> currentOnlineIds = usersList.map((u) => u['id'].toString()).toList();
      
      // Limpar quem saiu da lista de seguidores
      whoIsWatchingMe.removeWhere((uid) => !currentOnlineIds.contains(uid));
      usersInLiveSession.removeWhere((uid) => !currentOnlineIds.contains(uid));

      onlineUsers = usersList.map((u) {
        final map = Map<String, dynamic>.from(u);
        final String uid = map['id'].toString();
        
        // 🚀 SINCRONIZAÇÃO DE VOZ: Se o utilizador já diz que está em chamada, respeitamos
        if (map['isInCall'] == true) {
          usersInLiveSession.add(uid);
        }

        int idAsInt = int.tryParse(uid) ?? 0;
        
        return {
          'id': uid,
          'name': map['name'] ?? 'Colega',
          'color': avatarColorsPool[idAsInt % avatarColorsPool.length],
          'isTalking': map['isTalking'] ?? false,
          'activity': map['activity'] ?? 'idle', // 🚀 Novo: Rastreio de atividade
          'isHandRaised': map['isHandRaised'] ?? false,
          'isInCall': usersInLiveSession.contains(uid), // Reflete o estado real
        };
      }).toList();

      isRemoteVoiceCallActive = onlineUsers.any((u) => u['id'].toString() != myUserId && u['isInCall'] == true);

      // 🔭 SE JÁ HÁ ALGUÉM EM CHAMADA, MOSTRAR BANNER AUTOMATICAMENTE
      if (usersInLiveSession.any((uid) => uid != myUserId) && !isLiveSessionActive && incomingVoiceCall == null) {
        incomingVoiceCall = {'sender_name': 'A sala'};
        isRemoteVoiceCallActive = true;
      }

      // 🚀 ALINHAMENTO COLETIVO: Se alguém novo entrou, disparamos um sinal de sincronização global
      if (onlineUsers.length > previousCount && previousCount > 0) {
        debugPrint('🤝 [CollectiveSync] Novo colega detectado. Solicitando alinhamento global...');
        _realtimeService.requestCollectiveSync(myUserId: myUserId);
      }

      // 🚀 ROOM SYNC: Ao entrar, sempre alinhamos os dados com a nuvem para não perder o que foi feito offline
      if (isRealtimeActive) {
        _debounceRoomSync();
      }

      safeNotify();
    });

    _collectiveSyncSubscription?.cancel();
    _collectiveSyncSubscription = realtime.onCollectiveSyncRequested.listen((data) {
      if (_isDisposed) return;
      final String senderId = data['sender_id'].toString();
      if (senderId != myUserId) {
        debugPrint('🤝 [CollectiveSync] Alinhamento global solicitado por $senderId');
        _performCollectiveSync();
      }
    });

    _activitySubscription?.cancel();
    _activitySubscription = realtime.onUserActivityReceived.listen((data) {
      if (_isDisposed) return;
      final String uid = data['sender_id'].toString();
      final String activity = data['activity'].toString();
      _realtimeService.updateUserActivityState(uid, activity);
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

      // 🎧 AUTO-PLAY EM SESSÃO LIVE
      if (isLiveSessionActive && data['is_live'] == true && data['sender_id'] != myUserId) {
        debugPrint('🎧 [LiveSession] Auto-play de áudio recebido de ${data['sender_id']}');
        playAudioMessage(data['audio_url']);
      }
    });

    // 🚀 SINCRONIZAÇÃO DE HISTÓRICO VOLÁTIL
    realtime.onChatSyncRequestReceived.listen((data) {
      if (_isDisposed) return;
      final String requesterId = data['sender_id'].toString();
      if (requesterId != myUserId && chatMessages.isNotEmpty) {
        debugPrint('🤝 [ChatSync] Enviando histórico para $requesterId');
        _realtimeService.sendChatSyncResponse(targetUserId: requesterId, history: chatMessages);
      }
    });

    realtime.onChatSyncResponseReceived.listen((data) {
      if (_isDisposed) return;
      if (data['target_id'].toString() == myUserId) {
        final List<dynamic> history = data['history'] ?? [];
        debugPrint('🤝 [ChatSync] Recebido histórico de ${history.length} mensagens');
        for (var msg in history) {
          _addChatMessage(Map<String, dynamic>.from(msg));
        }
      }
    });

    if (_statusListener != null) {
      realtime.statusNotifier.removeListener(_statusListener!);
    }
    _statusListener = () {
      if (realtime.statusNotifier.value == RealtimeStatus.connected) {
        _flushPendingChat();
      }
    };
    realtime.statusNotifier.addListener(_statusListener!);

    _reactionSubscription?.cancel();
    _reactionSubscription = realtime.onReactionReceived.listen((data) {
      if (_isDisposed) return;
      final String uid = data['sender_id'].toString();
      final String emoji = data['reaction'].toString();

      debugPrint('🎭 [Reaction] Recebida de $uid: $emoji');

      userReactions[uid] = emoji;
      _reactionTimers[uid]?.cancel();
      _reactionTimers[uid] = Timer(const Duration(seconds: 5), () {
        debugPrint('🎭 [Reaction] Limpando reação de $uid');
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
          final bool isDeleted = strokeMap['is_deleted'] == true;
          final bool isFinal = strokeMap['is_final'] == true;

          if (isDeleted) {
            targetPage.strokes.removeWhere((s) => s.id == strokeId);
            
            // Também removemos do preview se existir
            final currentMap = Map<String, Stroke>.from(remoteLiveStrokes.value);
            if (currentMap.containsKey(strokeId)) {
              currentMap.remove(strokeId);
              remoteLiveStrokes.value = currentMap;
            }
            
            safeNotify();
            // 🚀 PERSISTÊNCIA COLETIVA: Todos salvam a remoção no SQLite local de forma cirúrgica
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
              // 🚀 ISOLAMENTO: Atribuímos o número da página ao traço live
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
            // 🚀 CORREÇÃO DO TRAÇO FANTASMA: 
            // Substituímos os pontos pelo payload final completo em vez de concatenar.
            // Isto evita duplicação de pontos que causa a linha reta indesejada.
            final newStroke = Stroke(
              id: strokeId, 
              color: strokeMap['color'], 
              thickness: (strokeMap['thickness'] as num).toDouble(), 
              points: incomingPoints, // 🎯 Pontos finais puros
              pageNumber: incomingPageNum,
            );

            targetPage.strokes.removeWhere((s) => s.id == strokeId);
            targetPage.strokes.add(newStroke);
            
            // Removemos o traço 'live' de preview
            currentMap.remove(strokeId);
            remoteLiveStrokes.value = currentMap;
            
            safeNotify();

            // Todos salvam localmente para evitar perda de dados se saírem da app
            if (targetPage.id != null) {
              _repository.saveSingleStroke(targetPage.id!, newStroke);
              
              // 🚀 MARCAR PÁGINA COMO DIRTY: Se o colega não salvar na nuvem, nós salvaremos eventualmente
              _repository.triggerSyncRadar(targetPage.id!);
            }
          }
        }
      } catch (e) { debugPrint('⚠️ Erro tinta remota: $e'); }
    });

    _textSubscription?.cancel();
    _textSubscription = realtime.onTextReceived.listen((data) {
      if (_isDisposed) return;
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

        // 🔒 Gestão de Soft Lock
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
            targetPage.textBlocks[existingIndex] = newBlock;
          } else {
            targetPage.textBlocks.add(newBlock);
          }
        }
        safeNotify();
        _repository.savePage(targetPage, liveNotebookSid);
      } catch (e) { debugPrint('⚠️ Erro texto remoto: $e'); }
    });

    _imageSubscription?.cancel();
    _imageSubscription = realtime.onImageReceived.listen((data) {
      if (_isDisposed) return;
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
          if (existingIndex != -1) {
            targetPage.imageBlocks[existingIndex] = newBlock;
          } else {
            targetPage.imageBlocks.add(newBlock);
          }
        }
        safeNotify();

        // 🚀 OTIMIZAÇÃO: Adiar o save no SQLite para movimentos intensos
        _remoteImageSaveTimer?.cancel();
        _remoteImageSaveTimer = Timer(const Duration(seconds: 1), () {
          _repository.savePage(targetPage, liveNotebookSid);
          debugPrint('💾 [RemoteSync] Posição final da imagem persistida.');
        });
      } catch (e) { debugPrint('⚠️ Erro imagem remota: $e'); }
    });

    // 🏆 SERVER-AUTHORITATIVE: Ouvir a confirmação final do servidor Laravel
    _pageUpdatedSubscription?.cancel();
    _pageUpdatedSubscription = realtime.onPageUpdated.listen((data) {
      if (_isDisposed) return;
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

        if (data['header_data'] != null) {
          targetPage.title = LocalPage.parseMeta(data['header_data']);
        }
        if (data['footer_data'] != null) {
          targetPage.footer = LocalPage.parseMeta(data['footer_data']);
        }
        
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

        safeNotify();
        _repository.savePage(targetPage, liveNotebookSid);
      } catch (e) {
        debugPrint('⚠️ Erro ao processar PageUpdated: $e');
      }
    });

    _viewportSubscription?.cancel();
    _viewportSubscription = realtime.onViewportReceived.listen((data) {
      if (_isDisposed) return;
      final String senderId = data['sender_id'].toString();
      _markUserBroadcasting(senderId);

      if (followingUserId == null || senderId != followingUserId) return;

      //  telescope SINCRONIZAÇÃO DE PÁGINA
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
      if (_isDisposed) return;
      final String followerId = data['follower_id'].toString();
      final String? followingId = data['following_id']?.toString();
      final String myId = myUserId; // Precisamos do myUserId atualizado

      if (followingId == myId) {
        if (!whoIsWatchingMe.contains(followerId)) {
          whoIsWatchingMe.add(followerId);
          safeNotify();
        }
      } else {
        if (whoIsWatchingMe.contains(followerId)) {
          whoIsWatchingMe.remove(followerId);
          safeNotify();
        }
      }
    });

    _pageEventSubscription?.cancel();
    _pageEventSubscription = realtime.onPageEventReceived.listen((data) async {
      if (_isDisposed) return;
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
            safeNotify();

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
            safeNotify();
            if (pageController.hasClients) pageController.jumpToPage(currentPageIndex);

            // 🛡️ PERSISTÊNCIA UNIVERSAL: Todos removem a folha do SQLite local
            if (pageToDelete.id != null) {
              await _repository.deletePage(pageToDelete.id!);
            }
          }
        } else if (action == 'metadata_update') {
          final int pageNumber = data['page_number'];
          final int index = pages.indexWhere((p) => p.pageNumber == pageNumber);
          if (index != -1) {
            final targetPage = pages[index];
            if (data.containsKey('line_type')) {
              liveLineType = data['line_type'];
            }
            if (data.containsKey('header_data')) {
              targetPage.title = LocalPage.parseMeta(data['header_data']);
            }
            if (data.containsKey('footer_data')) {
              targetPage.footer = LocalPage.parseMeta(data['footer_data']);
            }
            safeNotify();
            // 🛡️ PERSISTÊNCIA UNIVERSAL: Todos salvam a alteração de metadados localmente
            await _repository.savePage(targetPage, liveNotebookSid);
          }
        }
      } catch (e) {
        debugPrint('⚠️ Erro ao processar evento de página remoto: $e');
      }
    });

    _handSubscription?.cancel();
    _handSubscription = realtime.onHandEventReceived.listen((data) {
      if (_isDisposed) return;
      final String senderId = data['sender_id'].toString();
      final bool isRaised = data['is_raised'] == true;
      _realtimeService.updateUserHandState(senderId, isRaised);
      
      // 🚀 AVISO VISUAL: Notificar se alguém pedir a palavra
      if (isRaised) {
        final user = onlineUsers.firstWhere((u) => u['id'].toString() == senderId, orElse: () => {});
        if (user.isNotEmpty) {
          debugPrint('✋ [Hand] O colega ${user['name']} pediu a palavra!');
        }
      }
      safeNotify();
    });

    _uploadingSubscription?.cancel();
    _uploadingSubscription = realtime.onRemoteUploading.listen((data) {
      final String senderId = data['sender_id'].toString();
      final bool isUploading = data['is_uploading'] == true;
      
      if (isUploading) {
        remoteUploadingUsers.add(senderId);
      } else {
        remoteUploadingUsers.remove(senderId);
      }
      safeNotify();
    });

    // 🔔 OUVIR CONVITES (Canal Privado via RealtimeService)
    _inviteSubscription?.cancel();
    _inviteSubscription = realtime.onLiveInviteReceived.listen((data) {
      if (_isDisposed) return;
      if (data['notebook_id'] == liveNotebookSid || data['notebook_id'] == currentNotebookId) {
        // Se já estamos online, ignoramos o convite
        if (isRealtimeActive) return;
        
        pendingInvite = data;
        safeNotify();
        debugPrint('🔔 [Invite] Convite recebido do colega ${data['sender_name']}');
      }
    });

    // 🎙️ OUVIR INÍCIO DE CHAMADAS DE VOZ
    _voiceCallSubscription?.cancel();
    _voiceCallSubscription = realtime.onVoiceCallStarted.listen((data) {
      if (_isDisposed) return;
      if (data['sender_id'] == myUserId) return;
      
      // Se não estamos em chamada, mostramos o convite
      if (!isLiveSessionActive) {
        incomingVoiceCall = data;
        isRemoteVoiceCallActive = true;
        safeNotify();
        debugPrint('🎙️ [Voice] Convite de voz recebido de ${data['sender_name']}');
      } else {
        // Se já estamos em chamada e recebemos um novo sinal de início, apenas garantimos a flag
        isRemoteVoiceCallActive = true;
        safeNotify();
      }
    });

    // 🎙️ OUVIR ESTADOS DE VOZ (QUEM ENTROU/SAIU)
    _voiceStateSubscription?.cancel();
    _voiceStateSubscription = realtime.onVoiceStateReceived.listen((data) {
      if (_isDisposed) return;
      final String uid = data['sender_id'].toString();
      final bool inCall = data['is_in_call'] == true;
      
      // 🛡️ GUARDA: Só reagir se o estado MUDOU de facto
      final bool alreadyIn = usersInLiveSession.contains(uid);
      if (inCall == alreadyIn) return;

      if (inCall) {
        usersInLiveSession.add(uid);
        isRemoteVoiceCallActive = true;
        // 🎙️ SE EU já estou na chamada, aviso o WebRTC que este utilizador entrou
        if (isLiveSessionActive) {
              }
      } else {
        usersInLiveSession.remove(uid);
        userAudioLevels.remove(uid);
        // 🚀 LIMPEZA: Se não sobrar ninguém (ou só eu), desativamos a flag da sala
        if (usersInLiveSession.isEmpty || (usersInLiveSession.length == 1 && usersInLiveSession.contains(myUserId))) {
          isRemoteVoiceCallActive = false;
        }
      }
      safeNotify();
    });

    // Agora sim, entrar no canal
    await realtime.joinNotebookChannel(notebookId: channelId);
    
    // 🚀 FORÇAR ATUALIZAÇÃO INICIAL: Garante que a lista não fica vazia se o stream disparou durante o await
    onlineUsers = realtime.getConnectedUsers();
    
    // 🚀 PEDIR HISTÓRICO DE CHAT AOS MEMBROS ATIVOS
    Future.delayed(const Duration(seconds: 1), () {
      if (!_isDisposed && isRealtimeActive) {
        debugPrint('🤝 [ChatSync] Solicitando histórico de chat...');
        _realtimeService.requestChatSync(myUserId: myUserId);
      }
    });

    safeNotify();
  }

  Timer? _roomSyncDebouncer;
  bool _hasSyncedInThisSession = false;

  void _addChatMessage(Map<String, dynamic> data) {
    final String? msgId = data['msg_id']?.toString();
    
    // 🛡️ DEDUPLICAÇÃO: Não adicionar se já existir
    if (msgId != null && chatMessages.any((m) => m['msg_id'] == msgId)) {
      return;
    }

    chatMessages.add(data);
    if (chatMessages.length > 50) {
      chatMessages.removeAt(0);
    }
    if (!_isChatOpen && data['sender_id'] != myUserId) {
      unreadChatCount++;
      _newMessageAlertController.add(data); // 🚀 Disparar alerta para o SnackBar
    }
    safeNotify();
  }

  Future<void> _performCollectiveSync() async {
    if (isGlobalSyncing) return;
    
    isGlobalSyncing = true;
    safeNotify();

    try {
      debugPrint('📡 [CollectiveSync] Iniciando ciclo de trava e alinhamento...');
      
      // 1. Push: Envia mudanças locais pendentes
      await SyncService().pushPages();
      
      // 2. Pull: Recebe o estado atualizado do servidor
      await SyncService().pullPages();
      
      // 3. Recarregar páginas locais
      final freshPages = await _repository.getPagesByNotebook(currentNotebookId, liveNotebookSid);
      if (freshPages.isNotEmpty) {
        pages = freshPages;
      }
      
      debugPrint('✅ [CollectiveSync] Alinhamento concluído com sucesso.');
    } catch (e) {
      debugPrint('❌ [CollectiveSync] Falha no alinhamento: $e');
    } finally {
      isGlobalSyncing = false;
      safeNotify();
    }
  }

  void _debounceRoomSync() {
    if (_hasSyncedInThisSession) return;
    
    _roomSyncDebouncer?.cancel();
    // 🚀 SINCRONIZAÇÃO ACELERADA: Reduzido de 2s para 500ms para entrada mais rápida
    _roomSyncDebouncer = Timer(const Duration(milliseconds: 500), () async {
      debugPrint('📡 [RoomSync] Iniciando alinhamento imersivo com a Cloud...');
      
      try {
        // 1. Push: Garante que o servidor tem os meus dados locais ANTES de apagar o cache local no Pull
        // 🛡️ CRÍTICO: Se o Push falhar, NÃO prosseguimos para o Pull para evitar perda de dados locais unsynced
        final bool pushSuccess = await SyncService().pushPages();
        
        if (!pushSuccess) {
          debugPrint('❌ [RoomSync] Falha no Push inicial. Abortando Pull para proteger dados locais.');
          return;
        }

        debugPrint('✅ [RoomSync] Push concluído com sucesso. Iniciando Pull...');
        
        // 2. Pull: Traz tudo o que os colegas fizeram (mesmo ausentes)
        await SyncService().pullPages();
        
        // 3. Recarregar a UI com a "verdade" vinda da nuvem
        final remotePages = await _repository.getPagesByNotebook(currentNotebookId, liveNotebookSid);
        if (remotePages.isNotEmpty) {
          pages = remotePages;
          _hasSyncedInThisSession = true;
          safeNotify();
          debugPrint('🏆 [RoomSync] Caderno totalmente sincronizado e persistente!');
        }
      } catch (e) {
        debugPrint('⚠️ [RoomSync] Falha catastrófica no alinhamento inicial: $e');
      }
    });
  }

  void sendChatMessage(String message) {
    if (liveNotebookSid == null) return;
    final msg = {
      'type': 'text',
      'sender_id': myUserId,
      'message': message,
      'timestamp': DateTime.now().toIso8601String(),
    };
    
    if (isRealtimeActive && _realtimeService.isConnected) {
      _addChatMessage(msg);
      _realtimeService.broadcastChatMessage(
        notebookId: liveNotebookSid!,
        myUserId: myUserId,
        message: message,
      );
    } else {
      _addChatMessage(msg);
      _pendingChatQueue.add(msg);
      debugPrint('⏳ [ChatOffline] Mensagem guardada na fila');
    }
  }

  void _flushPendingChat() async {
    if (_pendingChatQueue.isEmpty || !isRealtimeActive || liveNotebookSid == null || !_realtimeService.isConnected) return;
    
    debugPrint('🚀 [ChatOffline] Enviando ${_pendingChatQueue.length} mensagens pendentes...');
    final toSend = List<Map<String, dynamic>>.from(_pendingChatQueue);
    _pendingChatQueue.clear();

    for (var msg in toSend) {
      if (msg['type'] == 'text') {
        await _realtimeService.broadcastChatMessage(
          notebookId: liveNotebookSid!,
          myUserId: myUserId,
          message: msg['message'],
        );
      } else if (msg['type'] == 'audio') {
        await _realtimeService.broadcastAudioMessage(
          notebookId: liveNotebookSid!,
          myUserId: myUserId,
          audioUrl: msg['audio_url'],
          duration: msg['duration'],
        );
      }
    }
  }

  Future<void> startRecording() async {
    try {
      if (_isDisposed) return;
      if (isRecording) return;
      
      debugPrint('🎙️ [Audio] A iniciar gravação para notebook SID: $liveNotebookSid');
      
      if (await _audioRecorder.hasPermission()) {
        final dir = await getTemporaryDirectory();
        final path = '${dir.path}/audio_${DateTime.now().millisecondsSinceEpoch}.m4a';
        
        await _audioRecorder.start(const RecordConfig(), path: path);
        isRecording = true;
        _recordingStartTime = DateTime.now();
        safeNotify();
      }
    } catch (e) {
      debugPrint('❌ Erro ao iniciar gravação: $e');
    }
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
        final file = File(path);
        final bytes = await file.readAsBytes();
        final filename = path.split('/').last;

        // 🚀 CORREÇÃO: Usar liveNotebookSid (Server ID) em vez do local ID
        debugPrint('☁️ [Audio] A enviar áudio para o servidor (Notebook SID: $liveNotebookSid)...');
        final audioUrl = await _repository.uploadAudio(liveNotebookSid!, filename, bytes);
        
        if (audioUrl != null) {
          final msg = {
            'type': 'audio',
            'sender_id': myUserId,
            'audio_url': audioUrl,
            'duration': duration,
            'timestamp': DateTime.now().toIso8601String(),
          };

          if (isRealtimeActive && _realtimeService.isConnected) {
            _addChatMessage(msg);
            _realtimeService.broadcastAudioMessage(
              notebookId: liveNotebookSid!,
              myUserId: myUserId,
              audioUrl: audioUrl,
              duration: duration,
              isLive: isLiveSessionActive, // 🚀 Marca como LIVE se a sessão estiver ativa
            );
          } else {
            _addChatMessage(msg);
            _pendingChatQueue.add(msg);
          }
        }
      }
    } catch (e) {
      debugPrint('❌ Erro ao parar/enviar áudio: $e');
      isRecording = false;
      safeNotify();
    }
  }

  Future<void> playAudioMessage(String url, {String? senderId}) async {
    // ⏸️ SE JÁ ESTIVER A TOCAR ESTE ÁUDIO, PAUSA TUDO
    if (currentlyPlayingAudioUrl == url) {
      currentlyPlayingAudioUrl = null;
      if (senderId != null) userAudioLevels[senderId] = 0.0;
      await _audioPlayer.pause();
      safeNotify();
      return;
    }

    // Limpar níveis anteriores
    userAudioLevels.clear();
    audioPlaybackProgress = 0.0; // 🚀 Reset imediato para a UI

    currentlyPlayingAudioUrl = url;
    
    // Tentar encontrar o senderId se não for fornecido
    final effectiveSenderId = senderId ?? chatMessages.firstWhere((m) => m['audio_url'] == url, orElse: () => {})['sender_id']?.toString();
    
    if (effectiveSenderId != null) {
      userAudioLevels[effectiveSenderId] = 0.5; // Simular que está a falar
    }

    safeNotify();
    try {
      debugPrint('🎧 [Audio] Tentando reproduzir: $url (Sender: $effectiveSenderId)');
      
      // 🛑 Reset agressivo do Player
      await _audioPlayer.stop();
      await _audioPlayer.release(); // 🚀 Liberta recursos nativos (importante no Windows)
      
      await Future.delayed(const Duration(milliseconds: 200)); 

      // 🚀 Configuração para Desktop/Windows
      await _audioPlayer.setVolume(isSpeakerOn ? 1.0 : 0.0);
      
      // No audioplayers 6.1.0, o play aceita o Source diretamente
      await _audioPlayer.play(UrlSource(url));
      
      debugPrint('✅ [Audio] Comando de reprodução disparado com sucesso.');
    } catch (e) {
      debugPrint('❌ [Audio] Erro ao reproduzir áudio: $e');
      userAudioLevels.clear();
      safeNotify();
    }
  }

  void _playNextAudioInQueue() async {
    // 🛡️ Se o utilizador limpou o ID (pausou), não avançamos
    if (currentlyPlayingAudioUrl == null) return;
    
    // 🔍 Encontrar o índice da mensagem atual
    int currentIndex = chatMessages.indexWhere((m) => m['audio_url'] == currentlyPlayingAudioUrl);
    
    // Limpar o estado atual antes de passar ao próximo
    currentlyPlayingAudioUrl = null;
    safeNotify();

    if (currentIndex != -1 && currentIndex < chatMessages.length - 1) {
      // 🚀 Procurar o próximo áudio nas mensagens seguintes
      for (int i = currentIndex + 1; i < chatMessages.length; i++) {
        final nextMsg = chatMessages[i];
        if (nextMsg['type'] == 'audio') {
          debugPrint('🎧 [Audio] Reprodução sequencial detectada. Próximo áudio em 800ms...');
          
          // Pequena pausa para o utilizador perceber a troca
          await Future.delayed(const Duration(milliseconds: 800));
          
          if (!_isDisposed) {
            await playAudioMessage(nextMsg['audio_url']);
          }
          break;
        }
      }
    }
  }

  void sendReaction(String emoji) {
    if (!isRealtimeActive || liveNotebookSid == null) {
      debugPrint('🚫 [Reaction] Bloqueado: Realtime=$isRealtimeActive, NotebookSid=$liveNotebookSid');
      return;
    }
    
    debugPrint('🎭 [Reaction] Enviando minha reação: $emoji (MyID: $myUserId)');
    userReactions[myUserId] = emoji;
    _reactionTimers[myUserId]?.cancel();
    _reactionTimers[myUserId] = Timer(const Duration(seconds: 5), () {
      userReactions[myUserId] = null;
      safeNotify();
    });

    _realtimeService.broadcastReaction(
      notebookId: liveNotebookSid!,
      myUserId: myUserId,
      reaction: emoji,
    );
    safeNotify();
  }

  Future<void> triggerAutoSave(LocalPage page) async {
    debugPrint('💾 [SQLite] A guardar folha ${page.pageNumber} localmente...');
    await _repository.savePage(page, liveNotebookSid);

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
    // 🚀 SELECÇÃO -> BORRACHA: APAGAR TUDO O QUE ESTÁ SELECIONADO
    if (newMode == ToolMode.eraser && (selectedStrokeIds.isNotEmpty || selectedTextIds.isNotEmpty || selectedImageIds.isNotEmpty)) {
      deleteSelection(pages[currentPageIndex]);
      return; // Mantém a ferramenta atual ou muda? Geralmente muda para borracha após apagar
    }

    currentTool = newMode;
    if (newMode != ToolMode.select && newMode != ToolMode.eraser) {
      selectedStrokeIds.clear(); selectedTextIds.clear(); selectedImageIds.clear();
      selectionRectStart = null; selectionRectEnd = null;
      isMovingStrokes = false;
    }
    safeNotify();
  }

  void zoom(double factor, Size screenSize) {
    final Matrix4 matrix = transformationController.value;
    final double centerX = screenSize.width / 2;
    final double centerY = screenSize.height / 2;
    matrix.translate(centerX, centerY);
    matrix.scale(factor);
    matrix.translate(-centerX, -centerY);
    transformationController.value = matrix;
    safeNotify();
  }

  void broadcastPageMetadataUpdate(LocalPage page) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    
    _realtimeService.broadcastPageEvent(
      notebookId: liveNotebookSid!,
      myUserId: myUserId,
      pageData: {
        'action': 'metadata_update',
        'notebook_sid': liveNotebookSid,
        'page_number': page.pageNumber,
        'line_type': liveLineType,
        'header_data': {'title': page.title},
        'footer_data': {'title': page.footer},
      }
    );
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
    // 🛡️ ALGORITMO ROBUSTO: Pega o maior número existente e soma 1
    int maxPage = 0;
    for (var p in pages) { if (p.pageNumber > maxPage) maxPage = p.pageNumber; }
    final int newPageNumber = maxPage + 1;

    final newPage = LocalPage(notebookId: currentNotebookId, pageNumber: newPageNumber, isLandscape: isLandscape);
    _resetZoomForPage(newPage, currentPaperSize);
    pages.add(newPage);
    safeNotify();
    await triggerAutoSave(newPage);

    // 📢 Notificar colegas online
    if (isRealtimeActive && liveNotebookSid != null) {
      _realtimeService.broadcastPageEvent(
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
    
    safeNotify();
    
    Future.microtask(() { if (pageController.hasClients) pageController.jumpToPage(currentPageIndex); });
    
    if (pageToDelete.id != null) {
      await _repository.deletePage(pageToDelete.id!);
      // 🚀 DISPARAR SYNC IMEDIATO PARA PROPAGAR DELEÇÃO
      SyncService().pushPages();
    }
    
    // 📢 Notificar colegas online
    if (isRealtimeActive && liveNotebookSid != null) {
      _realtimeService.broadcastPageEvent(
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

  void eraseAtPosition(Offset pos, LocalPage page) {
    if (selectedStrokeIds.isNotEmpty || selectedTextIds.isNotEmpty || selectedImageIds.isNotEmpty) {
      deleteSelection(page);
      return;
    } else {
      const double eraserRadius = 24.0;
      final List<String> deletedStrokeIds = [];
      final List<String> deletedTextIds = [];
      final List<String> deletedImageIds = [];

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

      final List<ImageBlock> imagesToRemove = [];
      for (var img in page.imageBlocks) {
        final Rect imgRect = Rect.fromLTWH(img.position.dx, img.position.dy, img.width, img.height);
        if (imgRect.contains(pos)) imagesToRemove.add(img);
      }
      if (imagesToRemove.isNotEmpty) {
        deletedImageIds.addAll(imagesToRemove.map((img) => img.id));
        page.imageBlocks.removeWhere((img) => imagesToRemove.contains(img));
      }

      if (deletedStrokeIds.isNotEmpty || deletedTextIds.isNotEmpty || deletedImageIds.isNotEmpty) {
        safeNotify(); triggerAutoSave(page);
        if (isRealtimeActive && liveNotebookSid != null) {
          for (var id in deletedStrokeIds) {
            _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: {
              'page_number': page.pageNumber, 'strokes': [{'id': id, 'is_deleted': true}]
            });
          }
          for (var id in deletedTextIds) {
            _realtimeService.broadcastTextBlock(notebookId: liveNotebookSid!, myUserId: myUserId, textData: {
              'page_number': page.pageNumber, 'block': {'id': id}, 'is_deleted': true
            });
          }
          for (var id in deletedImageIds) {
            _realtimeService.broadcastImageBlock(notebookId: liveNotebookSid!, myUserId: myUserId, imageData: {
              'page_number': page.pageNumber, 'block': {'id': id}, 'is_deleted': true
            });
          }
        }
      }
    }
  }

  void deleteSelection(LocalPage page) {
    if (selectedStrokeIds.isEmpty && selectedTextIds.isEmpty && selectedImageIds.isEmpty) return;

    final strokesToRemove = page.strokes.where((s) => selectedStrokeIds.contains(s.id)).toList();
    final textsToRemove = page.textBlocks.where((t) => selectedTextIds.contains(t.id)).toList();
    final imagesToRemove = page.imageBlocks.where((img) => selectedImageIds.contains(img.id)).toList();

    if (strokesToRemove.isEmpty && textsToRemove.isEmpty && imagesToRemove.isEmpty) return;

    final action = DeleteAction(
      page: page,
      strokes: strokesToRemove,
      texts: textsToRemove,
      images: imagesToRemove,
    );

    _executeAction(action);

    selectedStrokeIds.clear();
    selectedTextIds.clear();
    selectedImageIds.clear();
    safeNotify();
  }

  void addStroke(LocalPage page, Stroke stroke) {
    final action = AddStrokeAction(page: page, stroke: stroke);
    _executeAction(action);
  }

  void _executeAction(CanvasAction action) {
    action.execute();
    _undoStack.add(action);
    _redoStack.clear();
    if (_undoStack.length > 50) _undoStack.removeAt(0);
    
    // Sincronização e Save
    triggerAutoSave(action.page);
    _broadcastAction(action);
  }

  void _broadcastAction(CanvasAction action) {
    if (!isRealtimeActive || liveNotebookSid == null) return;

    if (action is DeleteAction) {
      for (var s in action.strokes) {
        _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: {
          'page_number': action.page.pageNumber, 'strokes': [{'id': s.id, 'is_deleted': true}]
        });
      }
      for (var t in action.texts) {
        _realtimeService.broadcastTextBlock(notebookId: liveNotebookSid!, myUserId: myUserId, textData: {
          'page_number': action.page.pageNumber, 'block': {'id': t.id}, 'is_deleted': true
        });
      }
      for (var img in action.images) {
        _realtimeService.broadcastImageBlock(notebookId: liveNotebookSid!, myUserId: myUserId, imageData: {
          'page_number': action.page.pageNumber, 'block': {'id': img.id}, 'is_deleted': true
        });
      }
    } else if (action is AddStrokeAction) {
       _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: {
          'page_number': action.page.pageNumber,
          'strokes': [{
            'id': action.stroke.id, 'color': action.stroke.color, 'thickness': action.stroke.thickness, 'is_final': true,
            'points': action.stroke.points.map((pt) => {'x': pt.dx, 'y': pt.dy}).toList(),
          }]
        });
    }
  }

  void undo(LocalPage page) {
    if (_undoStack.isEmpty) return;
    final action = _undoStack.removeLast();
    action.undo();
    _redoStack.add(action);
    safeNotify();
    triggerAutoSave(page);
    
    // Nota: A sincronização do Undo remota é complexa, idealmente enviamos o estado inverso
    if (isRealtimeActive && liveNotebookSid != null) {
      if (action is DeleteAction) {
        // Restaurar via broadcast individual
        for (var s in action.strokes) {
          _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: {
            'page_number': page.pageNumber,
            'strokes': [{
              'id': s.id, 'color': s.color, 'thickness': s.thickness, 'is_final': true,
              'points': s.points.map((pt) => {'x': pt.dx, 'y': pt.dy}).toList(),
            }]
          });
        }
        // ... (texto e imagem seriam similares)
      }
    }
  }

  void redo(LocalPage page) {
    if (_redoStack.isEmpty) return;
    final action = _redoStack.removeLast();
    action.execute();
    _undoStack.add(action);
    safeNotify();
    triggerAutoSave(page);
    _broadcastAction(action);
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
      safeNotify();

      // Gravação local imediata
      await _repository.saveSingleImageBlock(page.id!, newImageBlock);
      await triggerAutoSave(page);

      // 🌐 UPLOAD EM BACKGROUND: Se estiver online, sobe para a nuvem sem travar a UI
      if (isRealtimeActive) {
        uploadingImageIds.add(localId);
        failedImageUploads.remove(localId);
        _realtimeService.broadcastImageUploading(notebookId: liveNotebookSid!, myUserId: myUserId, isUploading: true);
        safeNotify();

        final Uint8List bytes = await pickedFile.readAsBytes();
        
        // 🚀 CORREÇÃO: Usar liveNotebookSid (Server ID) em vez do local ID
        _repository.uploadImage(liveNotebookSid!, pickedFile.name, bytes).then((remoteUrl) {
          uploadingImageIds.remove(localId);
          _realtimeService.broadcastImageUploading(notebookId: liveNotebookSid!, myUserId: myUserId, isUploading: false);
          
          if (remoteUrl != null) {
            // Atualiza o path para o URL oficial e avisa os outros
            newImageBlock.imagePath = remoteUrl;
            _repository.saveSingleImageBlock(page.id!, newImageBlock);
            broadcastImageBlockUpdate(page, newImageBlock, myUserId);
            debugPrint('✅ [ImageUpload] Background upload concluído: $remoteUrl');
          } else {
            failedImageUploads.add(localId);
            debugPrint('❌ [ImageUpload] Falha no upload da imagem $localId');
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
      final file = File(img.imagePath);
      if (!await file.exists()) {
        uploadingImageIds.remove(localId);
        failedImageUploads.add(localId);
        safeNotify();
        return;
      }

      final bytes = await file.readAsBytes();
      final filename = img.imagePath.split('/').last;

      final remoteUrl = await _repository.uploadImage(liveNotebookSid!, filename, bytes);
      
      uploadingImageIds.remove(localId);
      _realtimeService.broadcastImageUploading(notebookId: liveNotebookSid!, myUserId: myUserId, isUploading: false);

      if (remoteUrl != null) {
        img.imagePath = remoteUrl;
        _repository.saveSingleImageBlock(page.id!, img);
        broadcastImageBlockUpdate(page, img, myUserId);
        debugPrint('✅ [ImageRetry] Upload concluído: $remoteUrl');
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
    page.imageBlocks.remove(img);
    safeNotify(); await triggerAutoSave(page);
    if (isRealtimeActive && liveNotebookSid != null) {
      _realtimeService.broadcastImageBlock(notebookId: liveNotebookSid!, imageData: {
        'page_number': page.pageNumber, 'block': {'id': img.id}, 'is_deleted': true
      });
    }
  }

  void updateSelectionRect(LocalPage page, Offset currentPos) {
    selectionRectEnd = currentPos;
    if (selectionRectStart != null && selectionRectEnd != null) {
      final rect = Rect.fromPoints(selectionRectStart!, selectionRectEnd!);
      selectedStrokeIds.clear(); selectedTextIds.clear(); selectedImageIds.clear();
      for (var stroke in page.strokes) { if (stroke.points.any((pt) => rect.contains(pt))) selectedStrokeIds.add(stroke.id); }
      for (var tb in page.textBlocks) { if (rect.contains(tb.position)) selectedTextIds.add(tb.id); }
      for (var img in page.imageBlocks) {
        final imgRect = Rect.fromLTWH(img.position.dx, img.position.dy, img.width, img.height);
        if (rect.overlaps(imgRect)) selectedImageIds.add(img.id);
      }
    }
    safeNotify();
  }

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
    for (var id in selectedTextIds) {
      final matches = page.textBlocks.where((t) => t.id == id);
      if (matches.isNotEmpty) {
        matches.first.position = matches.first.position + delta;
      }
    }
    for (var id in selectedImageIds) {
      final matches = page.imageBlocks.where((img) => img.id == id);
      if (matches.isNotEmpty) {
        matches.first.position = matches.first.position + delta;
      }
    }
    safeNotify();

    // 🚀 TRANSMISSÃO AO VIVO DO MOVIMENTO (Throttled)
    final now = DateTime.now();
    if (now.difference(_lastMoveBroadcastTime).inMilliseconds > 50) {
      _broadcastSelectionMovement(page);
      _lastMoveBroadcastTime = now;
    }
  }

  void _broadcastSelectionMovement(LocalPage page) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    for (var id in selectedStrokeIds) {
      final matches = page.strokes.where((s) => s.id == id);
      if (matches.isNotEmpty) {
        final stroke = matches.first;
        _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: {
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
    for (var id in selectedImageIds) {
      final matches = page.imageBlocks.where((img) => img.id == id);
      if (matches.isNotEmpty) broadcastImageBlockUpdate(page, matches.first);
    }
  }

  void setUserActivity(String activity) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    _realtimeService.broadcastUserActivity(
      notebookId: liveNotebookSid!,
      myUserId: myUserId,
      activity: activity,
    );
    // Atualizar localmente também para feedback instantâneo no Cockpit
    _realtimeService.updateUserActivityState(myUserId, activity);
  }

  void onTyping() {
    setUserActivity('typing');
    _typingDebounce?.cancel();
    _typingDebounce = Timer(const Duration(seconds: 2), () {
      setUserActivity('idle');
    });
  }

  void broadcastTextBlockUpdate(LocalPage page, TextBlock block, {String? senderId, bool debounced = false, bool isEditing = false}) {
    if (!isRealtimeActive || liveNotebookSid == null) return;

    if (isEditing) onTyping(); // ✍️ Sinalizar atividade ao escrever/mexer

    if (debounced) {
      _textBroadcastDebounce?.cancel();
      _textBroadcastDebounce = Timer(const Duration(milliseconds: 150), () { // 🚀 Reduzido para 150ms
        _sendTextBlockSignal(page, block, senderId: senderId, isEditing: isEditing);
      });
    } else {
      _sendTextBlockSignal(page, block, senderId: senderId, isEditing: isEditing);
    }
  }

  void _sendTextBlockSignal(LocalPage page, TextBlock block, {String? senderId, bool isEditing = false}) {
    final String id = senderId ?? myUserId;
    _realtimeService.broadcastTextBlock(notebookId: liveNotebookSid!, textData: {
      'sender_id': id,
      'page_number': page.pageNumber,
      'block': block.toJson(),
      'is_editing': isEditing,
    });
  }

  void forceNotify() => safeNotify(); // 🚀 Restaurado

  void broadcastImageBlockUpdate(LocalPage page, ImageBlock block, [String? senderId]) {
    if (isRealtimeActive && liveNotebookSid != null) {
      // 🛡️ SEGURANÇA: Não enviar paths locais para os colegas (evita o quadrado vazio)
      if (!block.imagePath.startsWith('http')) {
        debugPrint('⏳ [ImageSync] Ignorando broadcast de path local: ${block.imagePath}');
        return;
      }

      final String id = senderId ?? myUserId;
      // 🚀 AGORA É SINCRONO E LEVE: Enviamos apenas o URL que já está no block.imagePath
      _realtimeService.broadcastImageBlock(notebookId: liveNotebookSid!, myUserId: id, imageData: {
        'page_number': page.pageNumber,
        'block': block.toJson(),
      });
    }
  }

  void broadcastThrottledImageUpdate(LocalPage page, ImageBlock block) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    final now = DateTime.now();
    if (now.difference(_lastMoveBroadcastTime).inMilliseconds > 30) { // 🚀 Reduzido para 30ms
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
      _realtimeService.broadcastPointerMove(
        notebookId: liveNotebookSid!,
        myUserId: myUserId,
        pos: pos,
      );
      _lastPointerBroadcast = now;
    }
  }

  void acceptInvite() {
    pendingInvite = null;
    toggleCollaboration(true);
  }

  void dismissInvite() {
    pendingInvite = null;
    safeNotify();
  }

  void acceptVoiceCall() {
    incomingVoiceCall = null;
    toggleVoiceCall(myUserId);
  }

  void dismissVoiceCall() {
    incomingVoiceCall = null;
    safeNotify();
  }

  Future<void> toggleVoiceCall(String myUserId) async {
    if (isConnectingVoice) return; // 🛡️ Evitar múltiplos cliques simultâneos
    
    if (isLiveSessionActive) { 
      isConnectingVoice = true;
      safeNotify();
      
      isLiveSessionActive = false; 
      usersInLiveSession.remove(myUserId);
      userAudioLevels.clear(); // 🧹 Limpeza total de áudio
      
      _realtimeService.broadcastVoiceStateUpdate(
        notebookId: liveNotebookSid ?? currentNotebookId, 
        myUserId: myUserId, 
        isInCall: false
      );
      
      isConnectingVoice = false;
      safeNotify();
    }
    else {
      // 🛡️ GUARDA DE PRIVILÉGIOS
      final bool isModerator = currentUserRole == 'owner' || currentUserRole == 'editor';
      if (!isRemoteVoiceCallActive && !isModerator) {
        debugPrint('🚫 [Canvas] Tentativa de iniciar live bloqueada (Sem privilégios)');
        return;
      }

      isConnectingVoice = true;
      safeNotify();

      // No Chat Imersivo, apenas entramos no estado de Sessão Live
      isLiveSessionActive = true;
      usersInLiveSession.add(myUserId);
      
      // Avisar colegas
      _realtimeService.broadcastVoiceStateUpdate(
        notebookId: liveNotebookSid ?? currentNotebookId, 
        myUserId: myUserId, 
        isInCall: true
      );

      if (!isRemoteVoiceCallActive) {
        _realtimeService.broadcastVoiceCallStarted(
          notebookId: liveNotebookSid ?? currentNotebookId, 
          myUserId: myUserId, 
          senderName: "Um colega"
        );
      }

      isConnectingVoice = false;
      safeNotify();
    }
  }

  Future<void> requestAudioConsent() async {
    if (isAudioConsentGiven) return;
    
    // Agora pedimos permissão através do gravador
    if (await _audioRecorder.hasPermission()) {
      isAudioConsentGiven = true;
      safeNotify();
    }
  }

  void handleLiveAudioAction() {
    if (isRecording) {
      stopAndSendAudio();
    } else {
      startRecording();
    }
  }

  void toggleSpeaker() { 
    isSpeakerOn = !isSpeakerOn; 
    _audioPlayer.setVolume(isSpeakerOn ? 1.0 : 0.0);
    safeNotify(); 
  }

  void toggleHandRaise() {
    isMyHandRaised = !isMyHandRaised;
    safeNotify();

    if (isRealtimeActive && liveNotebookSid != null) {
      _realtimeService.broadcastHandEvent(
        notebookId: liveNotebookSid!,
        myUserId: myUserId,
        isRaised: isMyHandRaised,
      );
      // Atualizar o próprio estado na lista local para refletir imediatamente
      _realtimeService.updateUserHandState(myUserId, isMyHandRaised);
    }
  }

  void toggleFollowUser(String? userId, String myId) {
    if (userId == myId) return; // 🛡️ Não podes assistir a ti próprio
    debugPrint('🔭 [CanvasController] Tentar seguir/parar utilizador: $userId');
    if (followingUserId == userId) {
      followingUserId = null;
    } else {
      followingUserId = userId;
    }
    
    // 📢 Avisar os outros sobre a mudança de estado
    if (liveNotebookSid != null) {
      _realtimeService.broadcastFollowUpdate(
        notebookId: liveNotebookSid!,
        myUserId: myId,
        followingUserId: followingUserId,
      );
    }
    
    safeNotify();
  }

  void startViewportBroadcasting(String effectiveUserId) {
    if (isBroadcastingViewport) return;
    debugPrint('🔭 [Viewport] A iniciar transmissão (User ID Oficial: $effectiveUserId)...');
    isBroadcastingViewport = true;
    safeNotify(); 

    _viewportBroadcastTimer = Timer.periodic(const Duration(milliseconds: 80), (timer) {
      if (!isRealtimeActive || liveNotebookSid == null || !isBroadcastingViewport) {
        timer.cancel(); return;
      }
      
      if (currentViewportCenter == null || currentVisibleWidth == null || effectiveUserId.isEmpty) return;

      _realtimeService.broadcastViewport(notebookId: liveNotebookSid!, viewportData: {
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
      safeNotify();

      // Se estivermos muito perto do destino, paramos
      double diff = 0;
      for (int i = 0; i < 16; i++) { diff += (next.storage[i] - _targetMatrix!.storage[i]).abs(); }
      if (diff < 0.001) {
        transformationController.value = _targetMatrix!;
        _targetMatrix = null;
        timer.cancel();
        safeNotify();
      }
    });
  }

  void stopViewportBroadcasting() {
    debugPrint('🔭 [Viewport] Transmissão parada pelo utilizador.');
    isBroadcastingViewport = false;
    _viewportBroadcastTimer?.cancel();
    _viewportBroadcastTimer = null;
    safeNotify();
  }
}

// 🚀 CLASSES AUXILIARES PARA O SISTEMA DE UNDO/REDO
abstract class CanvasAction {
  final LocalPage page;
  CanvasAction(this.page);
  void execute();
  void undo();
}

class AddStrokeAction extends CanvasAction {
  final Stroke stroke;
  AddStrokeAction({required LocalPage page, required this.stroke}) : super(page);

  @override
  void execute() => page.strokes.add(stroke);

  @override
  void undo() => page.strokes.removeWhere((s) => s.id == stroke.id);
}

class DeleteAction extends CanvasAction {
  final List<Stroke> strokes;
  final List<TextBlock> texts;
  final List<ImageBlock> images;

  DeleteAction({
    required LocalPage page,
    required this.strokes,
    required this.texts,
    required this.images,
  }) : super(page);

  @override
  void execute() {
    for (var s in strokes) page.strokes.removeWhere((item) => item.id == s.id);
    for (var t in texts) page.textBlocks.removeWhere((item) => item.id == t.id);
    for (var img in images) page.imageBlocks.removeWhere((item) => item.id == img.id);
  }

  @override
  void undo() {
    page.strokes.addAll(strokes);
    page.textBlocks.addAll(texts);
    page.imageBlocks.addAll(images);
  }
}

final canvasProvider = ChangeNotifierProvider.autoDispose<CanvasController>((ref) {
  final realtime = ref.read(realtimeServiceProvider);
  final repository = ref.read(canvasRepositoryProvider);
  return CanvasController(realtime, repository: repository);
});
