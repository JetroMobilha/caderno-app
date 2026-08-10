import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter/foundation.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors, Matrix4;

import 'package:caderno_digital_app/core/database/app_database.dart' as db hide Notebook, Subject, User, Page;
import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/core/network/sync_service.dart';
import 'package:caderno_digital_app/core/network/api_service.dart';
import 'package:caderno_digital_app/features/canvas/models/image_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/models/stroke_model.dart';
import 'package:caderno_digital_app/features/canvas/models/text_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/canvas_action_model.dart';
import 'package:caderno_digital_app/features/canvas/models/audio_stream_buffer.dart';
import 'package:caderno_digital_app/core/utils/geometry_utils.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';

enum ToolMode { draw, pan, select, text, eraser, insertImage, imageEdit }
enum InlineTarget { none, block, title, footer }
// 🚀 LiveRoomType removido em favor de flags de política de sessão

class CanvasController extends ChangeNotifier {
  final CanvasRepository _repository;
  final RealtimeService _realtimeService;
  final ApiService _apiService = ApiService();

  CanvasController(this._realtimeService, {CanvasRepository? repository}) 
      : _repository = repository ?? CanvasRepository(db.AppDatabase.instance) {
    transformationController = TransformationController();
    _audioPlayer.onPlayerComplete.listen((_) {
      audioPlaybackProgress = 0.0;
      _currentAudioDuration = null;
      safeNotify();
    });
    _audioPlayer.onPositionChanged.listen((pos) {
      if (currentlyPlayingAudioUrl == null) return;
      
      if (_currentAudioDuration != null && _currentAudioDuration!.inMilliseconds > 0) {
        audioPlaybackProgress = (pos.inMilliseconds / _currentAudioDuration!.inMilliseconds).clamp(0.0, 1.0);
        safeNotify();
      } else {
        // Tentar obter a duração se ainda não tivermos ou se mudou
        _audioPlayer.getDuration().then((dur) {
          if (dur != null && dur.inMilliseconds > 0) {
            _currentAudioDuration = dur;
            audioPlaybackProgress = (pos.inMilliseconds / dur.inMilliseconds).clamp(0.0, 1.0);
            safeNotify();
          }
        });
      }
    });
    _audioPlayer.setVolume(1.0);
  }

  bool _isDisposed = false; 
  void safeNotify() { if (!_isDisposed) notifyListeners(); }

  // -------------------------------------------------------------------------
  // 🛡️ [ZONA PROTEGIDA] SISTEMA DE PRESENÇA E SINALIZAÇÃO 🛡️
  // -------------------------------------------------------------------------
  final ValueNotifier<Map<String, dynamic>> remotePointers = ValueNotifier({});
  final Set<String> usersInLiveSession = {}; 
  Map<String, double> userAudioLevels = {}; 
  List<Map<String, dynamic>> onlineUsers = [];
  Map<String, String?> userReactions = {}; 
  final Map<String, Timer> _reactionTimers = {};
  bool isMyHandRaised = false; 
  String? followingUserId;
  final Set<String> whoIsWatchingMe = {}; 
  bool isBroadcastingViewport = false;
  Offset? currentViewportCenter;
  double? currentVisibleWidth; 
  Size? lastScreenSize;
  DateTime _lastPointerBroadcast = DateTime.now();
  final Map<String, Timer> _broadcasterTimers = {};
  final List<Color> avatarColorsPool = [ const Color(0xFFE67E22), const Color(0xFF9B59B6), const Color(0xFF27AE60), const Color(0xFF2980B9), const Color(0xFFE74C3C), const Color(0xFF1ABC9C) ];
  final Set<String> remoteMovingStrokeIds = {}; // 🚀 IDs de traços que colegas estão a mover
  final Map<String, DateTime> _lastRemoteStrokeUpdate = {}; // 🕒 Controle de expiração

  // 🛡️ [ZONA PROTEGIDA] CHAT E COMUNICAÇÃO 🛡️
  final List<Map<String, dynamic>> chatMessages = []; 
  int unreadChatCount = 0;
  bool _isChatOpen = false;
  bool get isChatOpen => _isChatOpen;
  set isChatOpen(bool value) { _isChatOpen = value; if (value) unreadChatCount = 0; safeNotify(); }
  final StreamController<Map<String, dynamic>> _newMessageAlertController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onNewMessageAlert => _newMessageAlertController.stream;
  
  final StreamController<String> _permissionAlertController = StreamController.broadcast();
  Stream<String> get onPermissionAlert => _permissionAlertController.stream;

  final StreamController<Map<String, dynamic>> _sessionMetaStreamController = StreamController.broadcast(); // 🚀
  Stream<Map<String, dynamic>> get onSessionMetaReceived => _sessionMetaStreamController.stream;

  final List<Map<String, dynamic>> _pendingChatQueue = [];

  // 🛡️ [ZONA PROTEGIDA] MOTOR DE ÁUDIO E STREAMING 🛡️
  final AudioPlayer _audioPlayer = AudioPlayer();
  AudioRecorder? _audioRecorderInstance;
  AudioRecorder get _audioRecorder => _audioRecorderInstance ??= AudioRecorder();
  String? currentlyPlayingAudioUrl; 
  double audioPlaybackProgress = 0.0; 
  double playbackSpeed = 1.0; 
  Duration? _currentAudioDuration; // 🚀 Cache de duração

  void setPlaybackSpeed(double speed) {
    playbackSpeed = speed;
    _audioPlayer.setPlaybackRate(speed);
    safeNotify();
  }

  Future<void> seekAudio(double percent) async {
    final dur = await _audioPlayer.getDuration();
    if (dur != null) {
      final target = dur * percent;
      await _audioPlayer.seek(target);
    }
  }

  Future<void> skipAudio(int seconds) async {
    final pos = await _audioPlayer.getCurrentPosition();
    if (pos != null) {
      final target = pos + Duration(seconds: seconds);
      await _audioPlayer.seek(target);
    }
  }
  bool isRecording = false;
  bool _isRecordingLive = false; 
  DateTime? _recordingStartTime;
  String? _activeStreamMessageId;
  int _currentSegmentIndex = 0;
  final Map<String, AudioStreamBuffer> _audioBuffers = {};
  final Set<String> _playingStreamIds = {};
  final List<Map<String, dynamic>> _failedSegmentsQueue = [];
  final Map<int, DateTime> _lastFullStateRequestTime = {};
  // -------------------------------------------------------------------------

  // State Properties (Canvas)
  List<LocalPage> pages = [];
  int currentPageIndex = 0;
  bool isLoading = true;
  bool isUploadingImage = false; 
  bool isGlobalSyncing = false; 
  bool isAiSummarizing = false; // 🚀
  bool isLessonRecording = false; // 🚀

  int? liveNotebookSid;
  int currentNotebookId = 0;
  String currentPaperSize = 'A4';
  
  // 🚀 POLÍTICAS DE SESSÃO (SUBSTITUEM LIVE_ROOM_TYPE)
  bool isSessionLocked = false; // Bloqueia escrita para não-donos
  bool isAuthorColorEnabled = false; // Identifica quem escreve por cor
  
  late String liveLineType;
  late double liveLineSpacing; 
  String currentUserRole = 'viewer';
  String currentTemplateType = 'study'; // 🚀 study, technical, formal
  Set<String>? visibleAuthorIds; // 🚀 Nulo significa "Todos"
  String myUserId = ""; 

  String? selectedEditingImageId; 
  ToolMode currentTool = ToolMode.draw;
  InlineTarget activeInlineTarget = InlineTarget.none; 
  TextBlock? activeTextBlock; 
  ToolMode? _previousToolBeforeGesture; 
  int _activePointerCount = 0;

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
  bool isFocusMode = false; 

  void toggleFocusMode() { isFocusMode = !isFocusMode; safeNotify(); }

  void toggleAuthorVisibility(String authorId) {
    visibleAuthorIds ??= onlineUsers.map((u) => u['id'].toString()).toSet();
    if (visibleAuthorIds!.contains(authorId)) {
      visibleAuthorIds!.remove(authorId);
    } else {
      visibleAuthorIds!.add(authorId);
    }
    safeNotify();
  }

  void togglePageFreeze(LocalPage page) {
    if (currentUserRole != 'owner') {
      _permissionAlertController.add('Apenas o proprietário pode (des)congelar páginas.');
      return;
    }
    page.isFrozen = !page.isFrozen;
    page.updatedAt = DateTime.now().millisecondsSinceEpoch;
    safeNotify();
    triggerAutoSave(page);
    if (isRealtimeActive && liveNotebookSid != null) {
      _realtimeService.broadcastPageEvent(notebookId: liveNotebookSid!, myUserId: myUserId, pageData: {
        'action': 'metadata_update', 
        'page_number': page.pageNumber,
        'is_frozen': page.isFrozen
      });
    }
  }

  void resetAuthorVisibility() {
    visibleAuthorIds = null;
    safeNotify();
  }

  // Timers and Debouncers
  Timer? _metadataBroadcastThrottle;
  Timer? _viewportBroadcastTimer;
  Timer? _remoteImageSaveTimer; 
  Timer? _roomSyncDebouncer;
  Timer? _autoSyncPushTimer;
  Timer? _typingDebounce;
  Timer? _textBroadcastDebounce;
  Timer? _smoothTimer;
  Timer? _segmentTimer;
  Timer? _amplitudeTimer;
  Timer? _fingerprintTimer;
  Timer? _cleanupTimer;

  // Session state
  bool isLiveSessionActive = false; 
  bool isConnectingVoice = false; 
  bool isSpeakerOn = true;
  bool isAudioConsentGiven = true; 
  bool isRemoteVoiceCallActive = false;
  Map<String, dynamic>? pendingInvite; 
  Map<String, dynamic>? incomingVoiceCall; 
  final Set<String> _deniedActionKeys = {}; 
  Matrix4? _targetMatrix;
  bool _hasSyncedInThisSession = false;
  bool _isCreatingFirstPage = false;
  
  final List<Map<String, dynamic>> _pendingStrokesQueue = [];
  DateTime _lastMoveBroadcastTime = DateTime.now();
  Offset? _lastSentViewportCenter;

  // Subscriptions
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
  StreamSubscription? _fullStateRequestSubscription;
  StreamSubscription? _fullStateReceivedSubscription;
  StreamSubscription? _globalActionSubscription;
  StreamSubscription? _followSubscription;
  StreamSubscription? _pageEventSubscription;
  StreamSubscription? _pageUpdatedSubscription;
  StreamSubscription? _handSubscription;
  StreamSubscription? _uploadingSubscription;
  StreamSubscription? _inviteSubscription; 
  StreamSubscription? _voiceCallSubscription; 
  StreamSubscription? _voiceStateSubscription; 
  StreamSubscription? _fingerprintSubscription;
  StreamSubscription? _cloudSyncSignalSubscription;
  StreamSubscription? _audioLevelSubscription; 
  StreamSubscription? _dbPagesSubscription;
  StreamSubscription? _dbNotebookSubscription;
  StreamSubscription? _sessionMetaSubscription; // 🚀
  VoidCallback? _statusListener;

  final ValueNotifier<Map<String, Stroke>> remoteLiveStrokes = ValueNotifier({});
  final ValueNotifier<List<Offset>> activePointsNotifier = ValueNotifier([]);
  late TransformationController transformationController;
  final PageController pageController = PageController(initialPage: 0);
  final Set<String> remoteUploadingUsers = {}; 
  final Set<String> uploadingImageIds = {}; 
  final Set<String> failedImageUploads = {}; 
  final Map<String, String> remoteEditingBlocks = {}; 
  final Map<String, Timer> _editingTimers = {}; 
  int? activeDrawingPageNumber;
  Duration get recordingDuration => _recordingStartTime != null ? DateTime.now().difference(_recordingStartTime!) : Duration.zero;

  @override
  void dispose() {
    _isDisposed = true; activePointsNotifier.dispose(); remoteLiveStrokes.dispose(); remotePointers.dispose(); transformationController.dispose(); pageController.dispose();
    _cancelRealtimeSubscriptions();
    _dbPagesSubscription?.cancel(); _dbNotebookSubscription?.cancel();
    if (_statusListener != null) _realtimeService.statusNotifier.removeListener(_statusListener!);
    _viewportBroadcastTimer?.cancel(); _autoSyncPushTimer?.cancel(); _typingDebounce?.cancel(); _textBroadcastDebounce?.cancel(); _roomSyncDebouncer?.cancel(); _remoteImageSaveTimer?.cancel(); _metadataBroadcastThrottle?.cancel(); _smoothTimer?.cancel(); _segmentTimer?.cancel(); _amplitudeTimer?.cancel(); _fingerprintTimer?.cancel(); _cleanupTimer?.cancel();
    for (var t in _broadcasterTimers.values) t.cancel(); for (var t in _editingTimers.values) t.cancel(); 
    chatMessages.clear(); unreadChatCount = 0;
    if (pages.isNotEmpty && isRealtimeActive && liveNotebookSid != null) { _flushPendingStrokes(); _repository.savePageToCloud(pages[currentPageIndex], liveNotebookSid!, myUserId); }
    _audioPlayer.dispose(); _audioRecorderInstance?.dispose(); 
    _newMessageAlertController.close();
    _permissionAlertController.close();
    _sessionMetaStreamController.close(); // 🚀
    if (liveNotebookSid != null && liveNotebookSid != 0) _realtimeService.leaveNotebookChannel(liveNotebookSid!);
    SyncService.isCollaborationActive = false; super.dispose();
  }

  // -------------------------------------------------------------------------
  // Lifecycle & Core Methods
  // -------------------------------------------------------------------------
  void _resetZoomForPage(LocalPage page, String paperSize) { 
    double scale = 1.4;
    if (paperSize == 'A0') scale = 0.25;
    else if (paperSize == 'A1') scale = 0.35;
    else if (paperSize == 'A2') scale = 0.5;
    else if (paperSize == 'A3') scale = 0.8;
    else if (paperSize == 'A5') scale = 1.8;

    transformationController.value = Matrix4.diagonal3Values(scale, scale, 1.0); 
  }

  List<db.LessonRecording> lessonRecordings = []; // 🚀

  Future<void> _loadLessonRecordings() async {
    final d = db.AppDatabase.instance;
    final rows = await (d.select(d.lessonRecordings)..where((t) => t.notebookId.equals(currentNotebookId))).get();
    lessonRecordings = rows;
    safeNotify();
  }

  Future<void> startLessonRecording() async {
    if (isLessonRecording) return;
    try {
      if (await _audioRecorder.hasPermission()) {
        isLessonRecording = true;
        _recordingStartTime = DateTime.now();
        _activeStreamMessageId = const Uuid().v4();
        
        String? path;
        if (!kIsWeb) {
          final dir = await getTemporaryDirectory();
          // 🚀 Padronizado para .m4a em todas as plataformas desktop/mobile
          path = '${dir.path}/lesson_${_activeStreamMessageId}.m4a';
        }
        
        await _audioRecorder.start(_getRecordConfig(), path: path ?? '');
        
        safeNotify();
      }
    } catch (e) {
      isLessonRecording = false;
      safeNotify();
    }
  }

  Future<void> stopLessonRecording(String title) async {
    if (!isLessonRecording) return;
    try {
      final String? tempPath = await _audioRecorder.stop();
      final duration = recordingDuration.inSeconds;
      final clientId = _activeStreamMessageId!;
      isLessonRecording = false;
      _recordingStartTime = null;
      safeNotify();

      if (tempPath != null) {
        // 🚀 OFFLINE-FIRST: Mover de temp para diretório permanente
        final appDir = await getApplicationDocumentsDirectory();
        final recordingsDir = Directory('${appDir.path}/recordings');
        if (!await recordingsDir.exists()) await recordingsDir.create(recursive: true);
        
        // 🚀 Padronizado para .m4a em todas as plataformas desktop/mobile
        final permanentPath = '${recordingsDir.path}/lesson_$clientId.m4a';
        await File(tempPath).copy(permanentPath);

        // Salvar localmente no Drift imediatamente (Referência Local)
        final d = db.AppDatabase.instance;
        await d.into(d.lessonRecordings).insert(db.LessonRecordingsCompanion.insert(
          notebookId: currentNotebookId,
          clientId: drift.Value(clientId),
          title: title,
          audioUrl: permanentPath, 
          durationSeconds: drift.Value(duration),
          updatedAt: drift.Value(DateTime.now().millisecondsSinceEpoch),
        ));
        _loadLessonRecordings();

        // 🚀 TENTAR UPLOAD (Se houver conexão e liveNotebookSid)
        if (liveNotebookSid != null && liveNotebookSid != 0) {
          final bytes = await File(permanentPath).readAsBytes();
          final remoteUrl = await _repository.uploadLessonAudio(
            liveNotebookSid!, 
            'lesson_$clientId.m4a', 
            bytes,
            title: title,
            duration: duration,
            clientId: clientId
          );

          if (remoteUrl != null) {
            // Atualizar para URL remota e marcar como sincronizado na nuvem
            await (d.update(d.lessonRecordings)..where((t) => t.clientId.equals(clientId))).write(
              db.LessonRecordingsCompanion(
                audioUrl: drift.Value(remoteUrl),
                syncedWithCloud: const drift.Value(1),
              )
            );
            _loadLessonRecordings();
          }
        }
      }
    } catch (e) {
      isLessonRecording = false;
      safeNotify();
    }
  }

  Future<void> generateAiSummary(LocalPage page) async {
    if (page.extractedText == null || page.extractedText!.trim().isEmpty) {
      _permissionAlertController.add('Ainda não há texto reconhecido nesta folha para resumir.');
      return;
    }

    if (isAiSummarizing) return;
    isAiSummarizing = true;
    safeNotify();

    try {
      final response = await _apiService.post('/ai/summarize', {
        'page_id': page.serverId ?? page.id, // O backend espera o ID real
      });

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final summary = data['summary'];
        
        // Criar um novo bloco de texto com o resumo
        final summaryBlock = TextBlock(
          id: const Uuid().v4(),
          text: "📌 RESUMO IA:\n\n$summary",
          position: const Offset(50, 100),
          fontSize: 14,
          isBold: false,
          textColorHex: '#0F4C5C',
        );
        
        addTextBlock(page, summaryBlock);
        _permissionAlertController.add('Resumo gerado e adicionado à folha! ✨');
      } else {
        _permissionAlertController.add('Falha ao gerar resumo. Tente novamente mais tarde.');
      }
    } catch (e) {
      _permissionAlertController.add('Erro na comunicação com a IA.');
    } finally {
      isAiSummarizing = false;
      safeNotify();
    }
  }

  Future<void> initNotebook(int notebookId, int? notebookSid, String lineType, String paperSize, String role, String? userId, {double? lineSpacing, String? templateType, String? collaborationMode}) async {
    isLoading = true; currentNotebookId = notebookId; liveNotebookSid = notebookSid; liveLineType = lineType; currentPaperSize = paperSize; liveLineSpacing = lineSpacing ?? ((lineType == 'grid' || lineType == 'dots') ? 25.0 : 28.0); currentUserRole = role; 
    currentTemplateType = templateType ?? 'study';
    
    // 🚀 INICIALIZAR POLÍTICAS A PARTIR DA PERSISTÊNCIA (Ex: "locked,colors")
    if (collaborationMode != null) {
      isSessionLocked = collaborationMode.contains('locked');
      isAuthorColorEnabled = collaborationMode.contains('colors');
    } else {
      isSessionLocked = false;
      isAuthorColorEnabled = false;
    }

    SyncService.activeNotebookId = notebookId; // 🚀 Notificar SyncService qual o caderno ativo

    // 🚀 OFFLINE-FIRST: Removida ativação automática de colaboração.
    // O utilizador deve agora clicar explicitamente para entrar em modo live.
    
    _loadLessonRecordings(); // 🚀 Carregar gravações ao abrir
    _initNotebookSubscriptions(notebookId, userId, paperSize);
  }

  void _initNotebookSubscriptions(int notebookId, String? userId, String paperSize) {
    if (userId != null) { 
      myUserId = userId; 
      _realtimeService.listenToUserAccount(int.parse(userId), () {
        _performCollectiveSync(); // 🚀 Reagir a pedido de sync global
      }); 
    }
    SyncService.isCollaborationActive = false; _dbNotebookSubscription?.cancel();
    final d = db.AppDatabase.instance;
    _dbNotebookSubscription = (d.select(d.notebooks)..where((t) => t.id.equals(notebookId))).watchSingleOrNull().listen((row) { 
      if (!_isDisposed && row != null && row.serverId != null && liveNotebookSid == null) { 
        liveNotebookSid = row.serverId; 
        safeNotify(); 
      } 
    });
    
    _dbPagesSubscription?.cancel();
    _dbPagesSubscription = _repository.watchPagesByNotebook(notebookId).listen((fps) async {
      // 🚀 FILTRAR PÁGINAS DELETADAS (Soft-delete reativo)
      final List<LocalPage> activePages = fps.where((p) => !p.isDeleted).toList();

      // 🚀 AUTO-CORREÇÃO DE PÁGINAS DUPLICADAS OU SEM NÚMERO
      if (activePages.isNotEmpty) {
        bool hasConflict = false;
        final Set<int> seenNumbers = {};
        for (var p in activePages) {
          if (seenNumbers.contains(p.pageNumber) || p.pageNumber <= 0) { 
            hasConflict = true; 
            break; 
          }
          seenNumbers.add(p.pageNumber);
        }
        
        if (hasConflict) {
          debugPrint('⚠️ [Canvas] Conflito de números de página detectado.');
          if (currentUserRole == 'owner' || currentUserRole == 'editor') {
            debugPrint('🔧 [Canvas] Disparando re-indexação no DB...');
            _repository.reindexPages(notebookId);
          }
          return; 
        }
      }

      // 🚀 LÓGICA DE MERGE (ANTI-FLICKER)
      if (pages.isEmpty || isLoading) {
        pages = activePages;
      } else {
        for (var freshPage in activePages) {
          final idx = pages.indexWhere((p) => p.clientId == freshPage.clientId);
          if (idx != -1) {
            final existing = pages[idx];
            if (freshPage.version > existing.version || freshPage.updatedAt > existing.updatedAt) {
              pages[idx] = freshPage;
            }
          } else {
            pages.add(freshPage);
          }
        }
        pages.removeWhere((p) => !activePages.any((f) => f.clientId == p.clientId));
        pages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
      }

      if (activeTextBlock != null && activeInlineTarget == InlineTarget.block) { 
        try { 
          final cp = pages.length > currentPageIndex ? pages[currentPageIndex] : null; 
          if (cp != null) activeTextBlock = cp.textBlocks.firstWhere((t) => t.id == activeTextBlock!.id); 
        } catch (_) { activeInlineTarget = InlineTarget.none; activeTextBlock = null; } 
      } 
      
      if (isLoading && pages.isNotEmpty) {
        _resetZoomForPage(pages.first, pages.first.paperSize);
      }
      
      isLoading = false; 
      safeNotify();

      if (activePages.isNotEmpty && liveNotebookSid != null && currentUserRole != 'owner') {
         SyncService().pullSpecificPage(liveNotebookSid!, 1);
      }
    });

    _inviteSubscription?.cancel();
    _inviteSubscription = _realtimeService.onLiveInviteReceived.listen((d) {
      if (_isDisposed || isCollaborationEnabled) return; 
      final String? senderId = d['sender_id']?.toString() ?? d['senderId']?.toString();
      if (senderId != null && (senderId == myUserId || senderId.trim() == myUserId.trim())) return;
      if (senderId != null && _deniedActionKeys.contains('live_invite_$senderId')) return;
      final targets = d['targets'] as List?;
      if (targets != null && targets.isNotEmpty && !targets.contains(myUserId)) return;
      pendingInvite = d; 
      safeNotify();
    });
  }

  void _autoNavigateAfterDeletion() {
    if (pages.isEmpty) return;
    int targetIndex = currentPageIndex;
    if (targetIndex >= pages.length) targetIndex = pages.length - 1;
    if (targetIndex < 0) targetIndex = 0;
    
    jumpToPage(targetIndex);
  }

  void _cancelRealtimeSubscriptions() {
    if (_statusListener != null) _realtimeService.statusNotifier.removeListener(_statusListener!);
    _usersSubscription?.cancel(); _strokesSubscription?.cancel(); _textSubscription?.cancel(); _imageSubscription?.cancel(); _viewportSubscription?.cancel(); _activitySubscription?.cancel(); _pointerSubscription?.cancel(); _chatSubscription?.cancel(); _audioMessageSubscription?.cancel(); _reactionSubscription?.cancel(); _collectiveSyncSubscription?.cancel(); _fullStateRequestSubscription?.cancel(); _fullStateReceivedSubscription?.cancel(); _fingerprintSubscription?.cancel(); _globalActionSubscription?.cancel(); _followSubscription?.cancel(); _pageEventSubscription?.cancel(); _pageUpdatedSubscription?.cancel(); _handSubscription?.cancel(); _uploadingSubscription?.cancel(); _voiceCallSubscription?.cancel(); _voiceStateSubscription?.cancel(); _audioLevelSubscription?.cancel();
    _sessionMetaSubscription?.cancel(); // 🚀
  }

  Future<void> initRealtimeCollaboration() async {
    final rt = _realtimeService; if (liveNotebookSid == null || liveNotebookSid == 0) return; await rt.initConnection();
    
    if (_statusListener != null) _realtimeService.statusNotifier.removeListener(_statusListener!);
    _statusListener = () { 
      if (!_isDisposed && _realtimeService.isConnected && liveNotebookSid != null) { 
        _debounceRoomSync(); 
        _startHeartbeat(); 
        _startCleanupTimer(); 
        
        // 🚀 AO LIGAR: Se for owner, anunciar políticas atuais
        if (currentUserRole == 'owner') {
          rt.broadcastSessionMeta(notebookId: liveNotebookSid!, metaData: {
            'is_locked': isSessionLocked,
            'is_colors_enabled': isAuthorColorEnabled,
          });
        }
      } 
    };
    _realtimeService.statusNotifier.addListener(_statusListener!);

    _sessionMetaSubscription?.cancel(); 
    _sessionMetaSubscription = rt.onSessionMetaReceived.listen((d) {
      if (_isDisposed) return;
      if (d['is_locked'] != null) isSessionLocked = d['is_locked'] == true;
      if (d['is_colors_enabled'] != null) isAuthorColorEnabled = d['is_colors_enabled'] == true;
      _sessionMetaStreamController.add(d); // 🚀
      safeNotify();
    });

    _voiceCallSubscription?.cancel();
    _voiceCallSubscription = rt.onVoiceCallStarted.listen((d) {
      if (_isDisposed || isLiveSessionActive) return;
      final String? senderId = d['sender_id']?.toString() ?? d['senderId']?.toString();
      if (senderId != null && (senderId == myUserId || senderId.trim() == myUserId.trim())) return;
      if (senderId != null && _deniedActionKeys.contains('voice_call_$senderId')) return;
      incomingVoiceCall = d; safeNotify();
    });

    _voiceStateSubscription?.cancel();
    _voiceStateSubscription = rt.onVoiceStateReceived.listen((d) {
      if (_isDisposed) return; final String uid = d['sender_id'].toString(); if (uid == myUserId) return;
      final bool isInCall = d['is_in_call'] == true; final bool isTalking = d['is_talking'] == true; final double level = (d['audio_level'] as num?)?.toDouble() ?? 0.0;
      if (isInCall) usersInLiveSession.add(uid); else usersInLiveSession.remove(uid);
      userAudioLevels[uid] = isTalking ? level : 0.0;
      final userIdx = onlineUsers.indexWhere((u) => u['id'].toString() == uid);
      if (userIdx != -1) { onlineUsers[userIdx]['isTalking'] = isTalking; onlineUsers[userIdx]['isInCall'] = isInCall; }
      safeNotify();
    });

    _strokesSubscription?.cancel();
    _strokesSubscription = rt.onStrokeReceived.listen((d) {
      if (_isDisposed || !isCollaborationEnabled) return; 
      try { 
        final String? pcid = d['page_client_id']?.toString();
        final int ipn = d['page_number'] ?? 0;
        
        if (d['sender_id']?.toString() == myUserId || pages.isEmpty) return; 
        
        // 🚀 ROUTING ROBUSTO: Priorizar ClientId, fallback para PageNumber
        int idx = -1;
        if (pcid != null) idx = pages.indexWhere((p) => p.clientId == pcid);
        if (idx == -1 && ipn > 0) idx = pages.indexWhere((p) => p.pageNumber == ipn);
        
        if (idx == -1) return; 
        final tp = pages[idx]; 
        final int rv = d['version'] ?? 0; 
        
        bool hasChanges = false;
        final curM = Map<String, Stroke>.from(remoteLiveStrokes.value); 
        final bool isMove = d['is_move'] == true; 

        for (var sm in d['strokes']) { 
          final sid = sm['id']; 

          // 🚀 SANEAMENTO DE IDs (ANTI-GHOST)
          for (var p in pages) {
            if (p.pageNumber != ipn) {
              p.strokes.removeWhere((s) => s.id == sid);
            }
          }

          if (sm['is_deleted'] == true) { 
            final exI = tp.strokes.indexWhere((s) => s.id == sid); 
            if (exI != -1) { 
              tp.strokes[exI].isDeleted = true; 
              tp.strokes[exI].updatedAt = sm['updated_at'] ?? DateTime.now().millisecondsSinceEpoch;
              hasChanges = true;
            }
            _repository.deleteSingleStroke(tp.id!, sid); 
            continue; 
          }
          
          if (sm['is_final'] != true) { 
            if (isMove) remoteMovingStrokeIds.add(sid); 

            if (sm['offset'] != null) {
              // 🚀 MOVIMENTO LEVE (OFFSET)
              final off = Offset((sm['offset']['x'] as num).toDouble(), (sm['offset']['y'] as num).toDouble());
              final baseS = tp.strokes.firstWhere((s) => s.id == sid, orElse: () => Stroke(color: '#000000', thickness: 1, points: []));
              
              curM[sid] = Stroke(
                id: sid, color: baseS.color, thickness: baseS.thickness, 
                points: baseS.points, // Usa pontos base
                pageNumber: ipn
              )..liveOffset = off; // Aplica offset visual
            } else {
              // 🚀 DESENHO OU MOVIMENTO COMPLETO
              final pts = (sm['points'] as List).map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble())).toList(); 
              final exS = curM[sid]; 
              if (exS != null && !isMove) {
                curM[sid] = Stroke(id: sid, color: exS.color, thickness: exS.thickness, points: List<Offset>.from(exS.points)..addAll(pts), pageNumber: ipn);
              } else {
                curM[sid] = Stroke(id: sid, color: sm['color'], thickness: (sm['thickness'] as num).toDouble(), points: List.from(pts), pageNumber: ipn); 
              }
            }
            hasChanges = true;
          } else { 
            // 🚀 FINALIZAÇÃO: Consolidar pontos finais
            final int remoteTs = sm['updated_at'] ?? DateTime.now().millisecondsSinceEpoch;
            final pts = (sm['points'] as List).map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble())).toList(); 
            final ns = Stroke(id: sid, color: sm['color'], thickness: (sm['thickness'] as num).toDouble(), points: pts, pageNumber: ipn, updatedAt: remoteTs); 
            
            // 🚀 LÓGICA LWW: Só aplicar se for mais recente que o traço local estático
            final exI = tp.strokes.indexWhere((s) => s.id == sid);
            if (exI != -1 && tp.strokes[exI].updatedAt > remoteTs) {
               curM.remove(sid); 
               remoteMovingStrokeIds.remove(sid); 
               hasChanges = true; // Forçar atualização para limpar ghost
               continue; 
            }

            // 🚀 LIMPEZA CRÍTICA
            curM.remove(sid); 
            remoteMovingStrokeIds.remove(sid); 
            
            tp.strokes.removeWhere((s) => s.id == sid); 
            tp.strokes.add(ns); 
            
            // 🚀 ATUALIZAR TIMESTAMP DA PÁGINA PARA REATIVIDADE
            tp.updatedAt = remoteTs;
            hasChanges = true; 
            
            _repository.saveSingleStroke(tp.id!, ns); 
          } 
        } 
        
        if (hasChanges) {
          remoteLiveStrokes.value = curM; 
          // 🚀 Não incrementar tp.version aqui se for movimento, o Painter já usa curM
          if (!isMove) {
             if (rv > tp.version) tp.version = rv; else tp.version++; 
          }
          safeNotify();
        }
      } catch (e) { debugPrint('🚨 [Realtime] Erro ao processar traço: $e'); }
    });

    _textSubscription?.cancel();
    _textSubscription = rt.onTextReceived.listen((d) {
      if (_isDisposed || !isCollaborationEnabled) return; 
      try { 
        final String? sid = d['sender_id']?.toString(); if (sid == myUserId || pages.isEmpty) return; 
        final String? pcid = d['page_client_id']?.toString();
        final int ipn = d['page_number'] ?? 0;

        int idx = -1;
        if (pcid != null) idx = pages.indexWhere((p) => p.clientId == pcid);
        if (idx == -1) idx = pages.indexWhere((p) => p.pageNumber == ipn);
        if (idx == -1) return; 

        final tp = pages[idx]; final bd = d['block']; final bid = bd['id']; 
        
        if (d['is_deleted'] == true) { 
          tp.textBlocks.removeWhere((t) => t.id == bid); 
        } else {
          final int remoteTs = bd['updated_at'] ?? DateTime.now().millisecondsSinceEpoch;
          final exI = tp.textBlocks.indexWhere((t) => t.id == bid); 
          if (exI != -1 && tp.textBlocks[exI].updatedAt > remoteTs) return; // 🚀 LWW

          final nb = TextBlock.fromJson(bd); 
          if (exI != -1) tp.textBlocks[exI] = nb; else tp.textBlocks.add(nb); 
        }
        
        tp.version++; // 🚀 Forçar redesenho
        safeNotify(); 
        _repository.savePage(tp, liveNotebookSid); 
      } catch (e) {}
    });

    _imageSubscription?.cancel();
    _imageSubscription = rt.onImageReceived.listen((d) {
      if (_isDisposed || !isCollaborationEnabled) return; 
      try { 
        final String? sid = d['sender_id']?.toString(); if (sid == myUserId || pages.isEmpty) return; 
        final String? pcid = d['page_client_id']?.toString();
        final int ipn = d['page_number'] ?? 0;

        int idx = -1;
        if (pcid != null) idx = pages.indexWhere((p) => p.clientId == pcid);
        if (idx == -1) idx = pages.indexWhere((p) => p.pageNumber == ipn);
        if (idx == -1) return; 

        final tp = pages[idx]; final bd = d['block']; final bid = bd['id']; 
        
        if (d['is_deleted'] == true) { 
          tp.imageBlocks.removeWhere((i) => i.id == bid); 
        } else {
          final int remoteTs = bd['updated_at'] ?? DateTime.now().millisecondsSinceEpoch;
          final exI = tp.imageBlocks.indexWhere((i) => i.id == bid); 
          if (exI != -1 && tp.imageBlocks[exI].updatedAt > remoteTs) return; // 🚀 LWW

          final nib = ImageBlock.fromJson(bd); 
          if (exI != -1) tp.imageBlocks[exI] = nib; else tp.imageBlocks.add(nib); 
        }
        
        tp.version++; // 🚀 Forçar redesenho
        safeNotify(); 
        _remoteImageSaveTimer?.cancel(); 
        _remoteImageSaveTimer = Timer(const Duration(seconds: 1), () => _repository.savePage(tp, liveNotebookSid)); 
      } catch (e) {}
    });

    _collectiveSyncSubscription?.cancel();
    _collectiveSyncSubscription = rt.onCollectiveSyncRequested.listen((d) { if (!_isDisposed && d['sender_id'].toString() != myUserId) _performCollectiveSync(); });
    
    _fullStateRequestSubscription?.cancel();
    _fullStateRequestSubscription = rt.onFullStateRequested.listen((d) async {
      if (_isDisposed) return;
      final int pNum = d['page_number'];
      final targetId = d['sender_id'].toString();
      final idx = pages.indexWhere((p) => p.pageNumber == pNum);
      if (idx != -1) {
        final pageJson = pages[idx].toJson();
        final jsonString = jsonEncode(pageJson);
        
        // 🚀 Lógica Híbrida: Respeitar o limite do Reverb (256KB)
        // Usamos 200KB como margem de segurança
        if (jsonString.length < 200000) {
          rt.deliverFullState(
            notebookId: liveNotebookSid!,
            targetUserId: targetId,
            pageData: pageJson,
          );
        } else {
          // 🚀 Grande demais: Salvar na nuvem e avisar os outros
          debugPrint('⚠️ [Sync] Página $pNum muito grande (${jsonString.length} bytes). Usando Cloud Sync.');
          await _repository.savePageToCloud(pages[idx], liveNotebookSid!, myUserId);
          rt.broadcastCloudSyncSignal(notebookId: liveNotebookSid!, myUserId: myUserId, pageNumber: pNum);
        }
      }
    });

    _fullStateReceivedSubscription?.cancel();
    _fullStateReceivedSubscription = rt.onFullStateReceived.listen((d) async {
      if (_isDisposed || d['target_id'].toString() != myUserId) return;
      final Map<String, dynamic> pageData = d['page_data'];
      final int pNum = pageData['page_number'];
      final idx = pages.indexWhere((p) => p.pageNumber == pNum);
      if (idx != -1) {
        final newPage = LocalPage.fromJson(pageData);
        final oldFingerprint = pages[idx].generateFingerprint();
        pages[idx] = newPage;
        pages[idx].version++;
        final newFingerprint = pages[idx].generateFingerprint();
        
        await _repository.savePage(pages[idx], liveNotebookSid);
        safeNotify();
        debugPrint('✅ [Sync] Página $pNum sincronizada via Handshake. Fingerprint: $oldFingerprint -> $newFingerprint');
      }
    });

    _fingerprintSubscription?.cancel();
    _fingerprintSubscription = rt.onPageFingerprintReceived.listen((d) {
      if (_isDisposed || d['sender_id'].toString() == myUserId) return;
      
      final int pNum = d['page_number'];
      final String remoteFingerprint = d['fingerprint'];
      final int remoteTs = d['updated_at'] ?? 0;
      
      final idx = pages.indexWhere((p) => p.pageNumber == pNum);
      if (idx != -1) {
        final localFingerprint = pages[idx].generateFingerprint();
        if (localFingerprint != remoteFingerprint) {
          // 🚀 ELEIÇÃO DE FONTE: Só peço dados se o remoto for mais recente
          if (remoteTs > pages[idx].updatedAt) {
            debugPrint('🔄 [Sync] Divergência detectada na página $pNum. Fonte remota é mais recente.');
            
            final now = DateTime.now();
            final lastReq = _lastFullStateRequestTime[pNum];
            if (lastReq == null || now.difference(lastReq).inSeconds > 10) {
              _lastFullStateRequestTime[pNum] = now;
              debugPrint('📡 [Sync] Solicitando Full State para página $pNum...');
              rt.requestFullState(notebookId: liveNotebookSid!, targetUserId: d['sender_id'].toString(), pageNumber: pNum);
              
              // 🚀 FAIL-SAFE: Disparar também um PULL direto via REST para garantir a integridade
              Future.delayed(const Duration(milliseconds: 500), () async {
                if (!_isDisposed) {
                  debugPrint('🔗 [Sync] Disparando REST Fail-safe para página $pNum...');
                  await SyncService().pullSpecificPage(liveNotebookSid!, pNum);
                }
              });
            }
          }
        }
      }
    });

    _cloudSyncSignalSubscription?.cancel();
    _cloudSyncSignalSubscription = rt.onCloudSyncSignalReceived.listen((d) async {
      if (_isDisposed || d['sender_id'].toString() == myUserId) return;
      final int pNum = d['page_number'];
      debugPrint('☁️ [Sync] Sinal de Cloud Sync recebido para página $pNum. Descarregando...');
      await SyncService().pullSpecificPage(liveNotebookSid!, pNum);
      
      // Forçar atualização visual
      final idx = pages.indexWhere((p) => p.pageNumber == pNum);
      if (idx != -1) {
        pages[idx].version++;
        safeNotify();
      }
    });

    _globalActionSubscription?.cancel();
    _globalActionSubscription = rt.onGlobalActionReceived.listen((d) {
      if (_isDisposed || d['sender_id'].toString() == myUserId) return;
      
      if (d['type'] == 'sync_undo' || d['type'] == 'sync_redo') {
        final action = CanvasAction.fromMap(d['action_type'], d['data']);
        if (action != null) {
          final tp = _getTargetPage(action.pageClientId);
          if (tp != null) {
             if (d['type'] == 'sync_undo') action.undo(tp); else action.execute(tp);
             tp.version++;
             safeNotify();
          }
        }
        return;
      }

      final action = CanvasAction.fromMap(d['type'], d['data']); 
      if (action != null) { 
        final tp = _getTargetPage(action.pageClientId); 
        if (tp != null) {
          final int rv = d['version'] ?? 0; 
          if (rv > 0 && rv < tp.version) return; 
          if (rv > tp.version) tp.version = rv; 
          // 🚀 PRIVATIZAÇÃO: Ações remotas NÃO entram na stack local de Undo
          action.execute(tp);
          safeNotify(); 
        }
      } 
    });
    
    _activitySubscription?.cancel();
    _activitySubscription = rt.onUserActivityReceived.listen((d) => rt.updateUserActivityState(d['sender_id'].toString(), d['activity'].toString()));
    
    _pointerSubscription?.cancel();
    _pointerSubscription = rt.onPointerMoveReceived.listen((d) { 
      if (_isDisposed) return; 
      final uid = d['sender_id'].toString(); if (uid == myUserId) return; 
      final cur = Map<String, dynamic>.from(remotePointers.value); 
      
      cur[uid] = { 
        'pos': Offset((d['x'] as num).toDouble(), (d['y'] as num).toDouble()), 
        'page_number': d['page_number'],
        'role': onlineUsers.firstWhere((u) => u['id'].toString() == uid, orElse: () => {})['role'] ?? 'student'
      }; 
      remotePointers.value = cur; 
    });
    
    _chatSubscription?.cancel();
    _chatSubscription = rt.onChatMessageReceived.listen((d) => _addChatMessage(d));
    
    _audioMessageSubscription?.cancel();
    _audioMessageSubscription = rt.onAudioMessageReceived.listen((d) { 
      if (_isDisposed) return; 
      final String? sid = d['msg_id']?.toString(); 
      final bool isLive = d['is_live'] == true || d['type'] == 'audio_stream';
      
      if (isLive && sid != null && d['sender_id'] != myUserId) {
        _handleIncomingAudioStream(d); 
      } else { 
        _addChatMessage(d); 
      } 
    });
    
    _reactionSubscription?.cancel();
    _reactionSubscription = rt.onReactionReceived.listen((d) { if (_isDisposed) return; final uid = d['sender_id'].toString(); userReactions[uid] = d['reaction'].toString(); _reactionTimers[uid]?.cancel(); _reactionTimers[uid] = Timer(const Duration(seconds: 5), () { userReactions[uid] = null; safeNotify(); }); safeNotify(); });
    
    _handSubscription?.cancel();
    _handSubscription = rt.onHandEventReceived.listen((d) { if (_isDisposed) return; final uid = d['sender_id'].toString(); rt.updateUserHandState(uid, d['is_raised'] == true); });
    
    _uploadingSubscription?.cancel();
    _uploadingSubscription = rt.onRemoteUploading.listen((d) { if (_isDisposed) return; final uid = d['sender_id'].toString(); if (d['is_uploading'] == true) remoteUploadingUsers.add(uid); else remoteUploadingUsers.remove(uid); safeNotify(); });
    
    _pageEventSubscription?.cancel();
    _pageEventSubscription = rt.onPageEventReceived.listen((d) async {
      if (_isDisposed || d['sender_id'].toString() == myUserId) return;
      
      if (d['action'] == 'add' || d['action'] == 'delete') {
        await _performCollectiveSync();
        
        // 🚀 NAVEGAÇÃO COLETIVA: Se foi uma deleção, garantir que estamos numa página válida
        if (d['action'] == 'delete') {
          _autoNavigateAfterDeletion();
        }
      }
      else if (d['action'] == 'metadata_update') {
        final int pNum = d['page_number']; final idx = pages.indexWhere((p) => p.pageNumber == pNum);
        if (idx != -1) {
          final p = pages[idx]; if (d['line_type'] != null) liveLineType = d['line_type']; if (d['line_spacing'] != null) liveLineSpacing = (d['line_spacing'] as num).toDouble();
          if (d['header_data'] != null) p.title = LocalPage.parseMeta(d['header_data']); if (d['footer_data'] != null) p.footer = LocalPage.parseMeta(d['footer_data']); safeNotify();
        }
      }
    });
    
    _pageUpdatedSubscription?.cancel();
    _pageUpdatedSubscription = rt.onPageUpdated.listen((d) async {
      if (_isDisposed) return;
      final int? sNotebookId = d['notebook_id'];
      final int? pNum = d['page_number'];

      if (sNotebookId == liveNotebookSid && pNum != null) {
        debugPrint('🔔 [Sync] Sinal de atualização da Nuvem recebido para página $pNum. Sincronizando...');
        
        // 🚀 OTIMIZAÇÃO: Em vez de push/pull total, fazemos apenas pull da página afetada
        await SyncService().pullSpecificPage(liveNotebookSid!, pNum);
        
        // Atualizar lista local de páginas para refletir mudanças (ex: metadados, strokes)
        final fresh = await _repository.getPagesByNotebook(currentNotebookId, liveNotebookSid);
        if (fresh.isNotEmpty) {
          pages = fresh;
          final idx = pages.indexWhere((p) => p.pageNumber == pNum);
          if (idx != -1) pages[idx].version++;
          safeNotify();
        }
      } else {
        // Fallback para sincronização total se não tivermos detalhes
        _performCollectiveSync();
      }
    });
    
    _viewportSubscription?.cancel();
    _viewportSubscription = rt.onViewportReceived.listen((data) {
      if (_isDisposed) return; final String senderId = data['sender_id'].toString(); _markUserBroadcasting(senderId);
      if (followingUserId == null || senderId != followingUserId) return;
      if (data['page_number'] != null && currentPageIndex + 1 != data['page_number']) jumpToPage(data['page_number'] - 1);
      if (lastScreenSize != null && (data['visibleWidth'] as num).toDouble() > 0) {
        final screenCenter = Offset(lastScreenSize!.width / 2, lastScreenSize!.height / 2);
        double scale = (lastScreenSize!.width / (data['visibleWidth'] as num).toDouble()).clamp(lastScreenSize!.width < 600 ? 1.2 : 0.8, 3.5);
        final currentMatrix = transformationController.value;
        final screenPoint = currentMatrix.transform3(Vector3((data['focusX'] as num).toDouble(), (data['focusY'] as num).toDouble(), 0));
        if (!Rect.fromCenter(center: screenCenter, width: lastScreenSize!.width * 0.95, height: lastScreenSize!.height * 0.6).contains(Offset(screenPoint.x, screenPoint.y)) || (currentMatrix.getMaxScaleOnAxis() - scale).abs() > 0.1) {
          _startSmoothTransition(Matrix4.translationValues(screenCenter.dx, screenCenter.dy, 0.0)..scale(scale, scale, 1.0)..translate(-(data['focusX'] as num).toDouble(),(-(data['focusY'] as num).toDouble()), 0.0));
        }
      }
    });

    _usersSubscription?.cancel();
    _usersSubscription = _realtimeService.onUsersUpdated.listen((ul) {
      if (_isDisposed) return; 
      final int prev = onlineUsers.length;
      final newList = _mapUserList(ul.toList());
      
      // 🚀 Detectar novos membros (especialmente estudantes) para enviar fingerprint
      if (newList.length > prev && (currentUserRole == 'owner' || currentUserRole == 'editor')) {
        final newUsers = newList.where((nu) => !onlineUsers.any((ou) => ou['id'] == nu['id'])).toList();
        if (newUsers.any((u) => u['role'] == 'student' || u['id'] != myUserId)) {
           final currentPage = pages[currentPageIndex];
           _realtimeService.broadcastPageFingerprint(
             notebookId: liveNotebookSid!,
             myUserId: myUserId,
             pageNumber: currentPage.pageNumber,
             fingerprint: currentPage.generateFingerprint(),
             updatedAt: currentPage.updatedAt, // 🚀
           );
        }
      }

      onlineUsers = newList;
      isRemoteVoiceCallActive = onlineUsers.any((u) => u['id'].toString() != myUserId && u['isInCall'] == true);
      if (onlineUsers.length > prev && prev > 0 && isCollaborationEnabled) { _debounceRoomSync(); _realtimeService.requestCollectiveSync(myUserId: myUserId); }
      safeNotify();
    });

    onlineUsers = _mapUserList(rt.getConnectedUsers()); 
    _flushPendingChat(); 
    
    // 🚀 NOVO: CATCH-UP IMEDIATO AO ENTRAR
    // Se já existem outros usuários, eu provavelmente estou atrasado
    if (onlineUsers.any((u) => u['id'] != myUserId)) {
      debugPrint('📥 [Canvas] Detectados colegas na sala. Disparando sincronização inicial...');
      _performCollectiveSync();
    }

    safeNotify();
  }

  List<Map<String, dynamic>> _mapUserList(List<dynamic> rawList) {
    return rawList.map((u) {
      final m = Map<String, dynamic>.from(u as Map);
      final String uid = m['id'].toString();
      final bool userInCall = m['isInCall'] == true || usersInLiveSession.contains(uid);
      if (userInCall) usersInLiveSession.add(uid);
      
      // 🚀 Priorizar Role do canal Presence, mas fallback para Role da tabela NotebookUser
      String role = m['role'] ?? 'student';
      if (uid == myUserId) role = currentUserRole;

      return {
        'id': uid, 
        'name': m['name'] ?? 'Colega', 
        'color': avatarColorsPool[(int.tryParse(uid) ?? 0) % avatarColorsPool.length], 
        'isTalking': m['isTalking'] ?? false, 
        'activity': m['activity'] ?? 'idle', 
        'isHandRaised': m['isHandRaised'] ?? false, 
        'isInCall': userInCall, 
        'role': role,
      }; 
    }).toList();
  }

  Future<void> toggleCollaboration(bool enable, {bool suppressBroadcast = false}) async {
    if (isCollaborationEnabled == enable) return; 
    isCollaborationEnabled = enable; SyncService.isCollaborationActive = enable;
    if (enable) { 
      if (liveNotebookSid == null || liveNotebookSid == 0) { try { await SyncService().pushOfflineSubjects(); await SyncService().pushNotebooks(); await Future.delayed(const Duration(seconds: 1)); } catch (e) {} } 
      if (liveNotebookSid != null && liveNotebookSid != 0) { 
        await _realtimeService.joinNotebookChannel(notebookId: liveNotebookSid!);
        await initRealtimeCollaboration(); 
        isRealtimeActive = true; 
        if (!suppressBroadcast && (currentUserRole == 'owner' || currentUserRole == 'editor')) {
          _realtimeService.broadcastLiveInvite(notebookId: liveNotebookSid!, myUserId: myUserId, senderName: "Um colega", targetUserIds: []); 
        }
      } 
      else { isCollaborationEnabled = false; SyncService.isCollaborationActive = false; isRealtimeActive = false; } 
    }
    else { 
      if (liveNotebookSid != null) _realtimeService.leaveNotebookChannel(liveNotebookSid!); 
      _cancelRealtimeSubscriptions();
      chatMessages.clear(); unreadChatCount = 0; isLiveSessionActive = false; isRealtimeActive = false; onlineUsers = []; usersInLiveSession.clear(); userAudioLevels.clear();
    }
    safeNotify();
  }

  Future<void> addNewPage(bool isLandscape, {String paperSize = 'A4'}) async {
    int maxP = 0; for (var p in pages) if (p.pageNumber > maxP) maxP = p.pageNumber;
    final np = LocalPage(notebookId: currentNotebookId, pageNumber: maxP + 1, isLandscape: isLandscape, paperSize: paperSize);
    
    // 🚀 INTEGRAR COM MOTOR DE UNDO
    final action = AddPageAction(
      pageClientId: np.clientId,
      pageNumber: np.pageNumber,
      isLandscape: isLandscape,
      paperSize: paperSize,
    );
    
    _executeAction(action, targetPage: np);

    if (pageController.hasClients) pageController.animateToPage(pages.length - 1, duration: const Duration(milliseconds: 400), curve: Curves.easeOutCubic);
  }

  void deletePage(LocalPage pd) async {
    if (pd.id == null) return;
    
    // 🚀 FEEDBACK VISUAL: Ativar animação de rasgar
    pd.isTearing = true;
    safeNotify();
    
    // Aguardar a animação no UI (300ms)
    await Future.delayed(const Duration(milliseconds: 300));

    // 🚀 INTEGRAR COM MOTOR DE UNDO
    final action = DeletePageAction(
      pageClientId: pd.clientId,
      pageNumber: pd.pageNumber,
      pageData: pd.toJson(),
    );
    
    _executeAction(action, targetPage: pd);
    
    // 🚀 NAVEGAÇÃO AUTOMÁTICA IMEDIATA: Remover da lista local e pular para válida
    pages.removeWhere((p) => p.clientId == pd.clientId);
    
    if (pages.isNotEmpty) {
      int nextIndex = currentPageIndex;
      if (nextIndex >= pages.length) nextIndex = pages.length - 1;
      if (nextIndex < 0) nextIndex = 0;
      jumpToPage(nextIndex);
    }

    if (isRealtimeActive && liveNotebookSid != null) {
      _realtimeService.broadcastPageEvent(
        notebookId: liveNotebookSid!, 
        myUserId: myUserId, 
        pageData: {'action': 'delete', 'notebook_sid': liveNotebookSid, 'page_number': pd.pageNumber}
      );
    }
  }

  final Map<int, Matrix4> _pageViewStates = {}; // 🚀 Memória de posicionamento por página

  void setPageIndex(int i) { 
    if (currentPageIndex == i) return; 
    
    // 🚀 SALVAR ESTADO DE VISUALIZAÇÃO ATUAL
    _pageViewStates[currentPageIndex] = transformationController.value.clone();

    selectedStrokeIds.clear(); selectedTextIds.clear(); selectedImageIds.clear(); 
    currentPageIndex = i; 
    
    // 🚀 RESTAURAR ESTADO DE VISUALIZAÇÃO DA PÁGINA DESTINO
    if (_pageViewStates.containsKey(i)) {
      transformationController.value = _pageViewStates[i]!;
    } else {
      // Se for a primeira vez na página, ajusta o zoom inicial baseado no tamanho
      if (i < pages.length) {
        _resetZoomForPage(pages[i], pages[i].paperSize);
      }
    }
    
    safeNotify(); 

    // 🚀 SYNC ON VIEW
    if (isCollaborationEnabled && liveNotebookSid != null && i < pages.length) {
       SyncService().pullSpecificPage(liveNotebookSid!, pages[i].pageNumber);
    }
  }
  void jumpToPage(int i) { 
    if (i >= 0 && i < pages.length) { 
      selectedStrokeIds.clear(); selectedTextIds.clear(); selectedImageIds.clear(); // 🚀 Limpar seleção ao mudar
      setPageIndex(i); pageController.jumpToPage(i); 
    } 
  }

  void updatePointerCount(int count) {
    if (_activePointerCount == count) return;
    _activePointerCount = count;
    if (_activePointerCount >= 2) { if (currentTool != ToolMode.pan) { _previousToolBeforeGesture = currentTool; currentTool = ToolMode.pan; safeNotify(); } }
    else if (_activePointerCount < 2) { if (_previousToolBeforeGesture != null) { currentTool = _previousToolBeforeGesture!; _previousToolBeforeGesture = null; safeNotify(); } }
  }

  void zoom(double factor, Size screenSize) {
    final currentMatrix = transformationController.value;
    final double currentScale = currentMatrix.getMaxScaleOnAxis();
    final double newScale = (currentScale * factor).clamp(0.1, 6.0);
    final double actualFactor = newScale / currentScale;
    final center = Offset(screenSize.width / 2, screenSize.height / 2);
    final Matrix4 newMatrix = currentMatrix.clone();
    newMatrix.translate(center.dx, center.dy); newMatrix.scale(actualFactor, actualFactor, 1.0); newMatrix.translate(-center.dx, -center.dy);
    transformationController.value = newMatrix; safeNotify();
  }

  void switchTool(ToolMode m) {
    if (m == ToolMode.eraser && (selectedStrokeIds.isNotEmpty || selectedTextIds.isNotEmpty || selectedImageIds.isNotEmpty)) { deleteSelection(pages[currentPageIndex]); return; }
    currentTool = m; selectedEditingImageId = null;
    if (m != ToolMode.select && m != ToolMode.eraser) { selectedStrokeIds.clear(); selectedTextIds.clear(); selectedImageIds.clear(); selectionRectStart = null; selectionRectEnd = null; isMovingStrokes = false; }
    safeNotify();
  }

  void clearImageSelection() { selectedEditingImageId = null; safeNotify(); }
  void selectEditingImage(String? id) { selectedEditingImageId = id; safeNotify(); }

  void selectTextBlockAt(Offset localPos, LocalPage page) {
    final matches = page.textBlocks.where((t) => Rect.fromLTWH(t.position.dx - 15, t.position.dy - 15, 200, t.fontSize * 2).contains(localPos) || (t.position - localPos).distance < 25.0).toList();
    if (matches.isNotEmpty) {
      matches.sort((a, b) => (a.position - localPos).distance.compareTo((b.position - localPos).distance));
      final selectedId = matches.first.id;
      if (!selectedTextIds.contains(selectedId)) { selectedTextIds.clear(); selectedStrokeIds.clear(); selectedImageIds.clear(); selectedEditingImageId = null; selectedTextIds.add(selectedId); safeNotify(); }
    } else { if (selectedTextIds.isNotEmpty || selectedEditingImageId != null) { selectedTextIds.clear(); selectedEditingImageId = null; safeNotify(); } }
  }

  bool tryToggleChecklistAt(Offset localPos, LocalPage page) {
    for (var tb in page.textBlocks) {
      if (!tb.isChecklist || tb.isDeleted) continue;
      final double boxSize = tb.fontSize * 1.2;
      final Rect blockRect = Rect.fromLTWH(tb.position.dx, tb.position.dy, boxSize + 10, (tb.text.split('\n').length * liveLineSpacing).clamp(boxSize, 5000));
      if (blockRect.contains(localPos)) {
        final int lineIndex = ((localPos.dy - tb.position.dy) / liveLineSpacing).floor();
        if (lineIndex >= 0 && lineIndex < tb.text.split('\n').length) { toggleLineChecked(tb, lineIndex); return true; }
      }
    }
    return false;
  }

  void toggleLineChecked(TextBlock tb, int idx) {
    final old = tb.clone(); if (tb.checkedLineIndices.contains(idx)) tb.checkedLineIndices.remove(idx); else tb.checkedLineIndices.add(idx);
    recordTextUpdate(pages[currentPageIndex], old, tb.clone()); safeNotify();
  }

  void eraseAtPosition(Offset pos, LocalPage page) {
    if (page.isFrozen) {
      _permissionAlertController.add('Esta página está congelada e não pode ser editada.');
      return;
    }
    if (selectedStrokeIds.isNotEmpty || selectedTextIds.isNotEmpty || selectedImageIds.isNotEmpty) { deleteSelection(page); return; }
    
    // 🚀 LÓGICA DE PERMISSÕES PARA BORRACHA
    final bool canDeleteAll = currentUserRole == 'owner' || (currentUserRole == 'editor' && currentTemplateType != 'formal');
    bool deniedByPermission = false;

    final sR = page.strokes.where((s) {
      if (s.isDeleted) return false;
      final hit = s.points.any((pt) => (pt - pos).distance < 24.0);
      if (hit && !canDeleteAll && s.creatorId != myUserId) { deniedByPermission = true; return false; }
      return hit;
    }).toList();
        
    final tR = page.textBlocks.where((tb) {
      if (tb.isDeleted) return false;
      final hit = (Rect.fromLTWH(tb.position.dx, tb.position.dy, 150, tb.fontSize * 1.5).contains(pos) || (tb.position - pos).distance < 24.0);
      if (hit && !canDeleteAll && tb.creatorId != myUserId) { deniedByPermission = true; return false; }
      return hit;
    }).toList();
        
    final iR = page.imageBlocks.where((img) {
      if (img.isDeleted) return false;
      final hit = Rect.fromLTWH(img.position.dx, img.position.dy, img.width, img.height).contains(pos);
      if (hit && !canDeleteAll && img.creatorId != myUserId) { deniedByPermission = true; return false; }
      return hit;
    }).toList();

    if (deniedByPermission) {
      _permissionAlertController.add('Apenas o criador pode apagar este objeto.');
    }
    
    // 🚀 TAMBÉM LIMPAR TRAÇOS REMOTOS EM CURSO (Evita "fantasmas" se o colega cair)
    final curM = Map<String, Stroke>.from(remoteLiveStrokes.value);
    bool remoteChanged = false;
    curM.removeWhere((id, s) {
      if (s.points.any((pt) => (pt - pos).distance < 24.0)) {
        remoteChanged = true;
        return true;
      }
      return false;
    });
    if (remoteChanged) remoteLiveStrokes.value = curM;

    if (sR.isNotEmpty || tR.isNotEmpty || iR.isNotEmpty) {
      final inS = isRealtimeActive && liveNotebookSid != null; final now = DateTime.now().millisecondsSinceEpoch;
      for (var s in sR) { s.isDeleted = true; s.deletedInSession = inS; s.updatedAt = now; }
      for (var t in tR) { t.isDeleted = true; t.deletedInSession = inS; t.updatedAt = now; }
      for (var img in iR) { img.isDeleted = true; img.deletedInSession = inS; img.updatedAt = now; }
      _executeAction(DeleteAction(pageClientId: page.clientId, pageNumber: page.pageNumber, strokes: sR.map((s)=>s.clone()).toList(), texts: tR.map((t)=>t.clone()).toList(), images: iR.map((i)=>i.clone()).toList()));
    }
  }

  void deleteSelection(LocalPage page) {
    if (page.isFrozen) {
      _permissionAlertController.add('Esta página está congelada.');
      return;
    }
    if (selectedStrokeIds.isEmpty && selectedTextIds.isEmpty && selectedImageIds.isEmpty) return;
    
    final bool canDeleteAll = currentUserRole == 'owner' || (currentUserRole == 'editor' && currentTemplateType != 'formal');

    final sR = page.strokes.where((s) => !s.isDeleted && 
        selectedStrokeIds.contains(s.id) && 
        (canDeleteAll || s.creatorId == myUserId) // 🛡️ Trava de segurança
    ).toList();
    
    final tR = page.textBlocks.where((t) => !t.isDeleted && 
        selectedTextIds.contains(t.id) &&
        (canDeleteAll || t.creatorId == myUserId) // 🛡️ Trava de segurança
    ).toList();
    
    final iR = page.imageBlocks.where((img) => !img.isDeleted && 
        selectedImageIds.contains(img.id) &&
        (canDeleteAll || img.creatorId == myUserId) // 🛡️ Trava de segurança
    ).toList();
    final inS = isRealtimeActive && liveNotebookSid != null; final now = DateTime.now().millisecondsSinceEpoch;
    for (var s in sR) { s.isDeleted = true; s.deletedInSession = inS; s.updatedAt = now; }
    for (var t in tR) { t.isDeleted = true; t.deletedInSession = inS; t.updatedAt = now; }
    for (var img in iR) { img.isDeleted = true; img.deletedInSession = inS; img.updatedAt = now; }
    _executeAction(DeleteAction(pageClientId: page.clientId, pageNumber: page.pageNumber, strokes: sR.map((s)=>s.clone()).toList(), texts: tR.map((t)=>t.clone()).toList(), images: iR.map((i)=>i.clone()).toList()));
    selectedStrokeIds.clear(); selectedTextIds.clear(); selectedImageIds.clear(); safeNotify();
  }

  void addStroke(LocalPage p, Stroke s) {
    // 🚀 Injetar dono ao criar
    final ns = Stroke(
      id: s.id, color: s.color, thickness: s.thickness, points: s.points, 
      creatorId: myUserId, pageNumber: p.pageNumber
    );
    _executeAction(AddStrokeAction(pageClientId: p.clientId, pageNumber: p.pageNumber, stroke: ns));
  }

  void addTextBlock(LocalPage p, TextBlock b) {
    // 🚀 Injetar dono ao criar
    final nb = TextBlock(
      id: b.id, text: b.text, position: b.position, fontSize: b.fontSize,
      textColorHex: b.textColorHex, isBold: b.isBold, isItalic: b.isItalic,
      isUnderline: b.isUnderline, isChecklist: b.isChecklist, 
      creatorId: myUserId
    );
    _executeAction(AddTextAction(pageClientId: p.clientId, pageNumber: p.pageNumber, block: nb));
  }

  void moveSelectedStrokes(LocalPage page, Offset delta) {
    if (page.isFrozen) {
      _permissionAlertController.add('Página congelada.');
      return;
    }
    final bool canMoveAll = currentUserRole == 'owner' || (currentUserRole == 'editor' && currentTemplateType != 'formal');
    bool deniedByPermission = false;

    for (var id in selectedStrokeIds) { 
      final m = page.strokes.where((s) => s.id == id); 
      if (m.isNotEmpty) {
        final s = m.first;
        if (!canMoveAll && s.creatorId != myUserId) { deniedByPermission = true; continue; } 
        for (int i = 0; i < s.points.length; i++) s.points[i] += delta; 
      }
    }
    for (var id in selectedTextIds) { 
      final m = page.textBlocks.where((t) => t.id == id); 
      if (m.isNotEmpty) {
        if (!canMoveAll && m.first.creatorId != myUserId) { deniedByPermission = true; continue; } 
        m.first.position += delta; 
      }
    }
    for (var id in selectedImageIds) { 
      final m = page.imageBlocks.where((img) => img.id == id); 
      if (m.isNotEmpty) {
        if (!canMoveAll && m.first.creatorId != myUserId) { deniedByPermission = true; continue; } 
        m.first.position += delta; 
      }
    }

    if (deniedByPermission) {
      _permissionAlertController.add('Apenas o criador pode mover estes objetos.');
    }
    
    page.version++; // 🚀 Forçar repaint local
    _totalSelectionDelta += delta; // 🚀 Acumular para o broadcast
    safeNotify(); 
    
    final now = DateTime.now(); 
    if (now.difference(_lastMoveBroadcastTime).inMilliseconds > 30) { 
      _broadcastSelectionMovement(page, isFinal: false); // 🚀 Usar camada Live durante movimento
      _lastMoveBroadcastTime = now; 
    }
  }

  void updateSelectionRect(LocalPage p, Offset cur) {
    selectionRectEnd = cur; if (selectionRectStart != null && selectionRectEnd != null) {
      final r = Rect.fromPoints(selectionRectStart!, selectionRectEnd!); selectedStrokeIds.clear(); selectedTextIds.clear(); selectedImageIds.clear();
      for (var s in p.strokes) if (s.points.any((pt) => r.contains(pt))) selectedStrokeIds.add(s.id);
      for (var t in p.textBlocks) if (r.contains(t.position)) selectedTextIds.add(t.id);
      for (var i in p.imageBlocks) if (r.overlaps(Rect.fromLTWH(i.position.dx, i.position.dy, i.width, i.height))) selectedImageIds.add(i.id);
    }
    safeNotify();
  }

  void finalizeSelectionMovement(LocalPage page) {
    if (isMovingStrokes && _totalSelectionDelta != Offset.zero) {
      // 🚀 Registrar o movimento final no sistema de ações (Undo/Redo)
      final action = MoveAction(
        pageClientId: page.clientId,
        pageNumber: page.pageNumber,
        strokeIds: List.from(selectedStrokeIds),
        textIds: List.from(selectedTextIds),
        imageIds: List.from(selectedImageIds),
        delta: _totalSelectionDelta,
      );
      
      // Adicionar ao histórico local
      _undoStack.add(action);
      _redoStack.clear();
      if (_undoStack.length > 50) _undoStack.removeAt(0);

      // Sincronizar com os colegas (Versão Final)
      _broadcastSelectionMovement(page, isFinal: true); 
      
      // Salvar no banco local
      _repository.savePage(page, liveNotebookSid);
      triggerAutoSave(page);
    }
    
    _totalSelectionDelta = Offset.zero; // 🚀 Reset delta acumulado
    selectionRectStart = null;
    selectionRectEnd = null;
    isMovingStrokes = false;
    safeNotify();
  }

  void bringImageToFront(LocalPage p, String id) {
    final idx = p.imageBlocks.indexWhere((i) => i.id == id);
    if (idx != -1 && idx != p.imageBlocks.length - 1) {
      final img = p.imageBlocks.removeAt(idx); p.imageBlocks.add(img); safeNotify(); triggerAutoSave(p);
      if (isRealtimeActive && liveNotebookSid != null) _realtimeService.broadcastImageBlock(notebookId: liveNotebookSid!, myUserId: myUserId, imageData: { 'page_number': p.pageNumber, 'block': img.toJson() });
    }
  }

  void recordImageUpdate(LocalPage p, ImageBlock o, ImageBlock n) {
    if (o.position != n.position || o.width != n.width || o.height != n.height || o.rotation != n.rotation) {
      n.updatedAt = DateTime.now().millisecondsSinceEpoch;
      _executeAction(UpdateImageAction(pageClientId: p.clientId, pageNumber: p.pageNumber, imageId: n.id, oldState: o, newState: n));
    }
  }

  Future<void> deleteImageBlock(LocalPage page, ImageBlock img) async {
    final bool inS = isRealtimeActive && liveNotebookSid != null; img.isDeleted = true; img.deletedInSession = inS; img.updatedAt = DateTime.now().millisecondsSinceEpoch;
    _executeAction(DeleteAction(pageClientId: page.clientId, pageNumber: page.pageNumber, strokes: [], texts: [], images: [img])); safeNotify();
  }

  void setThickness(double t) { selectedThickness = t; safeNotify(); }
  void setColor(String h) { selectedColorHex = h; safeNotify(); }
  void setTextColor(String h) { if (activeTextBlock != null) { final old = activeTextBlock!.clone(); activeTextBlock!.textColorHex = h; recordTextUpdate(pages[currentPageIndex], old, activeTextBlock!.clone()); safeNotify(); } }
  void toggleBold() { if (activeTextBlock != null) { final old = activeTextBlock!.clone(); activeTextBlock!.isBold = !activeTextBlock!.isBold; recordTextUpdate(pages[currentPageIndex], old, activeTextBlock!.clone()); safeNotify(); } }
  void toggleItalic() { if (activeTextBlock != null) { final old = activeTextBlock!.clone(); activeTextBlock!.isItalic = !activeTextBlock!.isItalic; recordTextUpdate(pages[currentPageIndex], old, activeTextBlock!.clone()); safeNotify(); } }
  void toggleUnderline() { if (activeTextBlock != null) { final old = activeTextBlock!.clone(); activeTextBlock!.isUnderline = !activeTextBlock!.isUnderline; recordTextUpdate(pages[currentPageIndex], old, activeTextBlock!.clone()); safeNotify(); } }
  void updateFontSize(double d) { if (activeTextBlock != null) { final old = activeTextBlock!.clone(); activeTextBlock!.fontSize = (activeTextBlock!.fontSize + d).clamp(10.0, 72.0); recordTextUpdate(pages[currentPageIndex], old, activeTextBlock!.clone()); safeNotify(); } }
  void toggleChecklist() { if (activeTextBlock != null) { final old = activeTextBlock!.clone(); activeTextBlock!.isChecklist = !activeTextBlock!.isChecklist; recordTextUpdate(pages[currentPageIndex], old, activeTextBlock!.clone()); safeNotify(); } }

  void setTextEditing(InlineTarget t, [TextBlock? b]) {
    final old = activeTextBlock; activeInlineTarget = t; activeTextBlock = b; safeNotify();
    if (b != null) broadcastTextBlockUpdate(pages[currentPageIndex], b, isEditing: true);
    else if (old != null) broadcastTextBlockUpdate(pages[currentPageIndex], old, isEditing: false);
  }

  void recordTextUpdate(LocalPage p, TextBlock o, TextBlock n) {
    n.updatedAt = DateTime.now().millisecondsSinceEpoch;
    _executeAction(UpdateTextAction(pageClientId: p.clientId, pageNumber: p.pageNumber, textId: n.id, oldState: o, newState: n));
    broadcastTextBlockUpdate(p, n);
    final upd = p.textBlocks.firstWhere((t) => t.id == n.id, orElse: () => n);
    if (activeTextBlock?.id == n.id) activeTextBlock = upd;
  }

  LocalPage? _getTargetPage(String cid) { try { return pages.firstWhere((p) => p.clientId == cid); } catch (e) { return null; } }

  void _executeAction(CanvasAction action, {bool isRemote = false, LocalPage? targetPage}) {
    final target = targetPage ?? _getTargetPage(action.pageClientId); if (target == null) return;
    if (target.isFrozen && !isRemote) {
       _permissionAlertController.add('Página congelada.');
       return;
    }
    if (currentUserRole == 'viewer' && !isRemote) return;
    
    if (!isRemote) { 
      target.version++; 
      target.updatedAt = DateTime.now().millisecondsSinceEpoch; 
    }
    
    action.execute(target);
    _undoStack.add(action); _redoStack.clear(); if (_undoStack.length > 50) _undoStack.removeAt(0);
    
    // 🚀 LÓGICA ESPECIAL PARA ESTRUTURA
    if (action is DeletePageAction || action is AddPageAction) {
       _repository.savePage(target, liveNotebookSid);
       _repository.reindexPages(currentNotebookId);
    } else {
       triggerAutoSave(target);
    }
    
    if (!isRemote) _broadcastAction(action); 
    safeNotify();
  }

  void _broadcastAction(CanvasAction action) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    final target = _getTargetPage(action.pageClientId); if (target == null) return;
    final int v = target.version;
    if (action is DeleteAction) {
      for (var s in action.strokes) _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: { 'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'version': v, 'strokes': [{'id': s.id, 'is_deleted': true, 'version': s.version}] });
      for (var t in action.texts) _realtimeService.broadcastTextBlock(notebookId: liveNotebookSid!, myUserId: myUserId, textData: { 'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'version': v, 'block': {'id': t.id, 'version': t.version}, 'is_deleted': true });
      for (var i in action.images) _realtimeService.broadcastImageBlock(notebookId: liveNotebookSid!, myUserId: myUserId, imageData: { 'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'version': v, 'block': {'id': i.id, 'version': i.version}, 'is_deleted': true });
    } else if (action is AddStrokeAction) {
      final s = action.stroke;
      // 🚀 REINTRODUZIDO FILTRO LEVE (0.2) para evitar erro 500 "Payload too large"
      final simplified = s.simplify(epsilon: 0.2); 
      _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: { 'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'version': v, 'strokes': [{ 'id': simplified.id, 'color': simplified.color, 'thickness': simplified.thickness, 'is_final': true, 'points': simplified.points.map((pt) => {'x': pt.dx, 'y': pt.dy}).toList() }] });
    } else if (action is AddTextAction) { _realtimeService.broadcastTextBlock(notebookId: liveNotebookSid!, myUserId: myUserId, textData: { 'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'version': v, 'block': action.block.toJson(), 'is_editing': false }); }
    else if (action is AddImageAction) { if (action.block.imagePath.startsWith('http')) _realtimeService.broadcastImageBlock(notebookId: liveNotebookSid!, myUserId: myUserId, imageData: { 'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'block': action.block.toJson() }); }
    else if (action is UpdateImageAction) { _realtimeService.broadcastImageBlock(notebookId: liveNotebookSid!, myUserId: myUserId, imageData: { 'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'version': v, 'block': action.newState.toJson() }); }
    else if (action is UpdateTextAction) { _realtimeService.broadcastTextBlock(notebookId: liveNotebookSid!, myUserId: myUserId, textData: { 'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'version': v, 'block': action.newState.toJson(), 'is_editing': true }); }
    else if (action is MoveAction) { 
      // 🚀 Garantir sincronização final após movimento consolidado no histórico
      _broadcastSelectionMovement(target, isFinal: true);
    }

    // 🚀 Notificar todos sobre o novo Fingerprint da página após a ação
    _realtimeService.broadcastPageFingerprint(
      notebookId: liveNotebookSid!,
      myUserId: myUserId,
      pageNumber: target.pageNumber,
      fingerprint: target.generateFingerprint(),
      updatedAt: target.updatedAt,
    );
  }

  void sendStrokeUpdate({required String pageClientId, required int pageNumber, required String strokeId, required List<Offset> points, bool isFinal = false}) async {
    if (!isRealtimeActive || liveNotebookSid == null) return;

    // 🚀 OTIMIZAÇÃO POR TEMPLATE:
    // No modo 'technical' (Engenharia), priorizamos fidelidade (epsilon menor).
    // No modo 'study', priorizamos velocidade (epsilon maior para pacotes menores).
    double epsilon = currentTemplateType == 'technical' ? 0.1 : 0.25;

    List<Offset> pointsToSend = isFinal ? GeometryUtils.simplifyPoints(points, epsilon: epsilon) : points;
    final data = { 
      'page_client_id': pageClientId, // 🚀 Prioridade máxima de roteamento
      'page_number': pageNumber, 
      'strokes': [{ 
        'id': strokeId, 
        'color': selectedColorHex, 
        'thickness': num.parse(selectedThickness.toStringAsFixed(1)), 
        'is_final': isFinal, 
        'updated_at': DateTime.now().millisecondsSinceEpoch, // 🚀 Enviar timestamp
        'points': pointsToSend.map((pt) => { 
          'x': num.parse(pt.dx.toStringAsFixed(1)), 
          'y': num.parse(pt.dy.toStringAsFixed(1)), 
        }).toList(), 
      }] 
    };
    try {
      final success = await _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: data);
      if (!success) _pendingStrokesQueue.add(data); else if (_pendingStrokesQueue.isNotEmpty) _flushPendingStrokes();
    } catch (e) { _pendingStrokesQueue.add(data); }
  }

  void _flushPendingStrokes() async {
    if (_pendingStrokesQueue.isEmpty || !isRealtimeActive || liveNotebookSid == null) return;
    final toSend = List<Map<String, dynamic>>.from(_pendingStrokesQueue); _pendingStrokesQueue.clear();
    for (var d in toSend) await _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: d);
  }

  void broadcastTextBlockUpdate(LocalPage p, TextBlock b, {String? senderId, bool debounced = false, bool isEditing = false, bool isDeleted = false}) { 
    if (!isRealtimeActive || liveNotebookSid == null) return; if (isEditing) onTyping(); 
    if (debounced) { _textBroadcastDebounce?.cancel(); _textBroadcastDebounce = Timer(const Duration(milliseconds: 150), () => _sendTextBlockSignal(p, b, senderId: senderId, isEditing: isEditing, isDeleted: isDeleted)); } 
    else _sendTextBlockSignal(p, b, senderId: senderId, isEditing: isEditing, isDeleted: isDeleted); 
  }

  void _sendTextBlockSignal(LocalPage p, TextBlock b, {String? senderId, bool isEditing = false, bool isDeleted = false}) => _realtimeService.broadcastTextBlock(notebookId: liveNotebookSid!, textData: { 'sender_id': senderId ?? myUserId, 'page_number': p.pageNumber, 'block': b.toJson(), 'is_editing': isEditing, 'is_deleted': isDeleted, });

  void broadcastImageBlockUpdate(LocalPage p, ImageBlock b, {String? senderId}) { 
    if (isRealtimeActive && liveNotebookSid != null && b.imagePath.startsWith('http')) _realtimeService.broadcastImageBlock(notebookId: liveNotebookSid!, myUserId: senderId ?? myUserId, imageData: { 'page_number': p.pageNumber, 'block': b.toJson(), 'is_deleted': b.isDeleted, 'version': p.version }); 
  }

  void broadcastThrottledImageUpdate(LocalPage p, ImageBlock b) { if (!isRealtimeActive || liveNotebookSid == null) return; final now = DateTime.now(); if (now.difference(_lastMoveBroadcastTime).inMilliseconds > 30) { broadcastImageBlockUpdate(p, b); _lastMoveBroadcastTime = now; } }
  void broadcastThrottledTextBlockUpdate(LocalPage p, TextBlock b) { if (!isRealtimeActive || liveNotebookSid == null) return; final now = DateTime.now(); if (now.difference(_lastMoveBroadcastTime).inMilliseconds > 50) { broadcastTextBlockUpdate(p, b, debounced: false); _lastMoveBroadcastTime = now; } }
  void broadcastPageMetadataUpdate(LocalPage page) { if (!isRealtimeActive || liveNotebookSid == null) return; _realtimeService.broadcastPageEvent(notebookId: liveNotebookSid!, myUserId: myUserId, pageData: { 'action': 'metadata_update', 'notebook_sid': liveNotebookSid, 'page_number': page.pageNumber, 'version': page.version, 'line_type': liveLineType, 'line_spacing': liveLineSpacing, 'header_data': {'title': page.title}, 'footer_data': {'title': page.footer} }); }
  void broadcastThrottledPageMetadataUpdate(LocalPage page) { _metadataBroadcastThrottle?.cancel(); _metadataBroadcastThrottle = Timer(const Duration(milliseconds: 100), () => broadcastPageMetadataUpdate(page)); }

  void broadcastPointer(Offset pos) { if (!isRealtimeActive || liveNotebookSid == null) return; final now = DateTime.now(); if (now.difference(_lastPointerBroadcast).inMilliseconds > 100) { _realtimeService.broadcastPointerMove(notebookId: liveNotebookSid!, myUserId: myUserId, pos: pos, pageNumber: currentPageIndex + 1); _lastPointerBroadcast = now; } }
  
  Offset _totalSelectionDelta = Offset.zero;

  void _broadcastSelectionMovement(LocalPage page, {bool isFinal = false}) { 
    if (!isRealtimeActive || liveNotebookSid == null || selectedStrokeIds.isEmpty) return; 
    
    final List<Map<String, dynamic>> batch = [];
    for (var id in selectedStrokeIds) { 
      final matches = page.strokes.where((s) => s.id == id); 
      if (matches.isNotEmpty) {
        final s = matches.first;

        if (!isFinal) {
          // 🚀 MOVIMENTO LIVE: Enviar apenas o offset (dx, dy) como números
          batch.add({
            'id': id, 
            'offset': {
              'x': double.parse(_totalSelectionDelta.dx.toStringAsFixed(1)), 
              'y': double.parse(_totalSelectionDelta.dy.toStringAsFixed(1))
            },
          });
        } else {
          // 🚀 FINALIZAÇÃO: Enviar pontos consolidados
          batch.add({
            'id': id, 
            'color': s.color, 
            'thickness': s.thickness, 
            'is_final': true,
            'points': s.points.map((pt) => {
              'x': double.parse(pt.dx.toStringAsFixed(1)), 
              'y': double.parse(pt.dy.toStringAsFixed(1))
            }).toList()
          });
        }
      } 
    } 

    if (batch.isNotEmpty) {
      _realtimeService.broadcastStroke(
        notebookId: liveNotebookSid!, 
        myUserId: myUserId, 
        strokeData: {
          'page_number': page.pageNumber, 
          'version': page.version,
          'is_move': true, 
          'strokes': batch
        }
      );
    }
    // ... restante (texto, imagens) mantido
  }

  void onTyping() { setUserActivity('typing'); _typingDebounce?.cancel(); _typingDebounce = Timer(const Duration(seconds: 2), () => setUserActivity('idle')); }
  void setUserActivity(String act) { if (!isRealtimeActive || liveNotebookSid == null) return; _realtimeService.broadcastUserActivity(notebookId: liveNotebookSid!, myUserId: myUserId, activity: act); _realtimeService.updateUserActivityState(myUserId, act); }

  // 🚀 MAPEAMENTO DE CORES PARA DINÂMICAS LIVE
  Map<String, Color> get userColorsMap {
    final map = <String, Color>{};
    for (var u in onlineUsers) {
      map[u['id'].toString()] = u['color'] as Color;
    }
    return map;
  }

  void _markUserBroadcasting(String userId) { _broadcasterTimers[userId]?.cancel(); _broadcasterTimers[userId] = Timer(const Duration(seconds: 4), () { _broadcasterTimers.remove(userId); safeNotify(); }); safeNotify(); }
  Set<String> get activeBroadcasters => _broadcasterTimers.keys.toSet();

  bool get isAnyUserInVoice => onlineUsers.any((u) {
    final String uid = u['id'].toString();
    return uid != myUserId && u['isInCall'] == true && !_deniedActionKeys.contains('voice_call_$uid');
  });

  Map<String, dynamic>? get firstActiveVoiceUser => onlineUsers.firstWhere((u) {
    final String uid = u['id'].toString();
    return uid != myUserId && u['isInCall'] == true && !_deniedActionKeys.contains('voice_call_$uid');
  }, orElse: () => {});

  void acceptInvite() { pendingInvite = null; toggleCollaboration(true, suppressBroadcast: true); }
  void dismissInvite() { if (pendingInvite != null) { final String? sid = pendingInvite!['sender_id']?.toString() ?? pendingInvite!['senderId']?.toString(); if (sid != null) _deniedActionKeys.add('live_invite_$sid'); } pendingInvite = null; safeNotify(); }
  void acceptVoiceCall() { incomingVoiceCall = null; toggleVoiceCall(myUserId, suppressBroadcast: true); }
  void dismissVoiceCall({String? userId}) { 
    if (userId != null) {
      _deniedActionKeys.add('voice_call_$userId');
    } else if (incomingVoiceCall != null) { 
      final String? sid = incomingVoiceCall!['sender_id']?.toString() ?? incomingVoiceCall!['senderId']?.toString(); 
      if (sid != null) _deniedActionKeys.add('voice_call_$sid'); 
    } 
    incomingVoiceCall = null; 
    safeNotify(); 
  }

  Future<void> toggleVoiceCall(String userId, {bool suppressBroadcast = false}) async {
    if (isConnectingVoice) return; isConnectingVoice = true; safeNotify();
    if (isLiveSessionActive) { isLiveSessionActive = false; usersInLiveSession.remove(userId); userAudioLevels.clear(); _realtimeService.broadcastVoiceStateUpdate(notebookId: liveNotebookSid ?? currentNotebookId, myUserId: userId, isInCall: false); }
    else { if (isRemoteVoiceCallActive || currentUserRole == 'owner' || currentUserRole == 'editor') { isLiveSessionActive = true; usersInLiveSession.add(userId); _realtimeService.broadcastVoiceStateUpdate(notebookId: liveNotebookSid ?? currentNotebookId, myUserId: userId, isInCall: true); if (!isRemoteVoiceCallActive && !suppressBroadcast) _realtimeService.broadcastVoiceCallStarted(notebookId: liveNotebookSid ?? currentNotebookId, myUserId: userId, senderName: "Um colega"); } }
    isConnectingVoice = false; safeNotify();
  }

  void toggleSessionLock() {
    if (currentUserRole != 'owner') return;
    isSessionLocked = !isSessionLocked;
    _persistSessionPolicies();
    _broadcastSessionPolicies();
    safeNotify();
  }

  void toggleAuthorColors() {
    if (currentUserRole != 'owner') return;
    isAuthorColorEnabled = !isAuthorColorEnabled;
    _persistSessionPolicies();
    _broadcastSessionPolicies();
    safeNotify();
  }

  void toggleHandRaise() { 
    isMyHandRaised = !isMyHandRaised; 
    safeNotify(); 
    if (isRealtimeActive && liveNotebookSid != null) { 
      _realtimeService.broadcastHandEvent(notebookId: liveNotebookSid!, myUserId: myUserId, isRaised: isMyHandRaised); 
      _realtimeService.updateUserHandState(myUserId, isMyHandRaised); 
    } 
  }

  void _persistSessionPolicies() {
    final policies = <String>[];
    if (isSessionLocked) policies.add('locked');
    if (isAuthorColorEnabled) policies.add('colors');
    final policyString = policies.join(',');

    final d = db.AppDatabase.instance;
    (d.update(d.notebooks)..where((t) => t.id.equals(currentNotebookId))).write(
      db.NotebooksCompanion(collaborationMode: drift.Value(policyString))
    );
  }

  void _broadcastSessionPolicies() {
    if (isRealtimeActive && liveNotebookSid != null) {
      _realtimeService.broadcastSessionMeta(notebookId: liveNotebookSid!, metaData: {
        'is_locked': isSessionLocked,
        'is_colors_enabled': isAuthorColorEnabled,
      });
    }
  }

  void toggleFollowUser(String? uid, String myId) { if (uid == myId) return; followingUserId = (followingUserId == uid) ? null : uid; if (liveNotebookSid != null) _realtimeService.broadcastFollowUpdate(notebookId: liveNotebookSid!, myUserId: myId, followingUserId: followingUserId); safeNotify(); }
  void sendReaction(String emoji) { if (!isRealtimeActive || liveNotebookSid == null) return; userReactions[myUserId] = emoji; _reactionTimers[myUserId]?.cancel(); _reactionTimers[myUserId] = Timer(const Duration(seconds: 5), () { userReactions[myUserId] = null; safeNotify(); }); _realtimeService.broadcastReaction(notebookId: liveNotebookSid!, myUserId: myUserId, reaction: emoji); safeNotify(); }

  void startViewportBroadcasting(String effId) {
    if (isBroadcastingViewport) return; isBroadcastingViewport = true; safeNotify(); 
    _viewportBroadcastTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!isRealtimeActive || liveNotebookSid == null || !isBroadcastingViewport) { t.cancel(); return; }
      if (currentViewportCenter != null && effId.isNotEmpty) {
        final d = _lastSentViewportCenter == null ? 999 : (currentViewportCenter! - _lastSentViewportCenter!).distance;
        if (d > 3.0) { _realtimeService.broadcastViewport(notebookId: liveNotebookSid!, viewportData: { 'page_number': currentPageIndex + 1, 'focusX': currentViewportCenter!.dx, 'focusY': currentViewportCenter!.dy, 'visibleWidth': currentVisibleWidth ?? 600.0 }, myUserId: effId); _lastSentViewportCenter = currentViewportCenter; }
      }
    });
  }

  void stopViewportBroadcasting() { isBroadcastingViewport = false; _viewportBroadcastTimer?.cancel(); _viewportBroadcastTimer = null; safeNotify(); }
  
  void _startSmoothTransition(Matrix4 target) {
    _targetMatrix = target; if (_smoothTimer != null && _smoothTimer!.isActive) return;
    _smoothTimer = Timer.periodic(const Duration(milliseconds: 16), (t) { if (_targetMatrix == null) { t.cancel(); return; } final current = transformationController.value; final next = Matrix4.identity(); for (int i = 0; i < 16; i++) next.storage[i] = current.storage[i] + (_targetMatrix!.storage[i] - current.storage[i]) * 0.04; transformationController.value = next; safeNotify(); double diff = 0; for (int i = 0; i < 16; i++) diff += (next.storage[i] - _targetMatrix!.storage[i]).abs(); if (diff < 0.001) { transformationController.value = _targetMatrix!; _targetMatrix = null; t.cancel(); safeNotify(); } });
  }

  void setLineType(String type, LocalPage page) { liveLineType = type; liveLineSpacing = (type == 'grid' || type == 'dots') ? 25.0 : 28.0; safeNotify(); broadcastPageMetadataUpdate(page); _repository.updateNotebookMetadata(currentNotebookId, liveLineType, liveLineSpacing); triggerAutoSave(page); }
  void setLineSpacing(double s, LocalPage page) { liveLineSpacing = s; safeNotify(); broadcastThrottledPageMetadataUpdate(page); _repository.updateNotebookMetadata(currentNotebookId, liveLineType, liveLineSpacing); triggerAutoSave(page); }
  void copyToClipboard(String text, BuildContext context) { if (text.isEmpty) return; Clipboard.setData(ClipboardData(text: text)).then((_) { if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Texto copiado para a área de transferência!'), backgroundColor: Color(0xFF0F4C5C), duration: Duration(seconds: 2))); }); }
  void exportPageText(LocalPage page, BuildContext context) { StringBuffer ft = StringBuffer(); if (page.title.isNotEmpty) { ft.writeln('Título: ${page.title}'); ft.writeln('=' * 20); } if (page.extractedText != null && page.extractedText!.trim().isNotEmpty) { ft.writeln('Texto Escrito à Mão:'); ft.writeln(page.extractedText); ft.writeln('-' * 10); } if (page.textBlocks.isNotEmpty) { ft.writeln('Anotações Digitais:'); final sorted = List<TextBlock>.from(page.textBlocks)..sort((a, b) => a.position.dy.compareTo(b.position.dy)); for (var b in sorted) if (b.text.trim().isNotEmpty) ft.writeln(b.text); } final res = ft.toString().trim(); if (res.isNotEmpty) copyToClipboard(res, context); else if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Não há texto nesta folha para exportar.'), backgroundColor: Colors.orangeAccent)); }
  void undo(LocalPage p) { 
    if (_undoStack.isEmpty) return; 
    final action = _undoStack.removeLast();
    final target = _getTargetPage(action.pageClientId);
    if (target != null) {
      target.version++;
      target.updatedAt = DateTime.now().millisecondsSinceEpoch;
      action.undo(target);
      _redoStack.add(action);
      
      // 🚀 LÓGICA ESPECIAL PARA ESTRUTURA NO UNDO
      if (action is DeletePageAction || action is AddPageAction) {
         _repository.savePage(target, liveNotebookSid);
         _repository.reindexPages(currentNotebookId);
         
         // 🚀 NAVEGAÇÃO NO UNDO: Voltar para a página restaurada/criada
         final idx = pages.indexWhere((p) => p.clientId == action.pageClientId);
         if (idx != -1) jumpToPage(idx);
      }

      if (isRealtimeActive && liveNotebookSid != null) {
        _realtimeService.broadcastGlobalAction(notebookId: liveNotebookSid!, actionData: {
          'sender_id': myUserId, 
          'type': 'sync_undo', 
          'action_type': action.type,
          'data': action.toMap()
        });
      }
      
      if (!(action is DeletePageAction || action is AddPageAction)) {
        triggerAutoSave(target);
      }
    }
    safeNotify();
  }

  void redo(LocalPage p) { 
    if (_redoStack.isEmpty) return; 
    final action = _redoStack.removeLast();
    final target = _getTargetPage(action.pageClientId);
    if (target != null) {
      target.version++;
      target.updatedAt = DateTime.now().millisecondsSinceEpoch;
      action.execute(target);
      _undoStack.add(action);
      
      // 🚀 LÓGICA ESPECIAL PARA ESTRUTURA NO REDO
      if (action is DeletePageAction || action is AddPageAction) {
         _repository.savePage(target, liveNotebookSid);
         _repository.reindexPages(currentNotebookId);

         // 🚀 NAVEGAÇÃO NO REDO
         final idx = pages.indexWhere((p) => p.clientId == action.pageClientId);
         if (idx != -1) jumpToPage(idx);
      }

      if (isRealtimeActive && liveNotebookSid != null) {
        _realtimeService.broadcastGlobalAction(notebookId: liveNotebookSid!, actionData: {
          'sender_id': myUserId, 
          'type': 'sync_redo', 
          'action_type': action.type,
          'data': action.toMap()
        });
      }
      
      if (!(action is DeletePageAction || action is AddPageAction)) {
        triggerAutoSave(target);
      }
    }
    safeNotify();
  }
  
  Future<void> _performCollectiveSync() async { 
    if (isGlobalSyncing) return; 
    isGlobalSyncing = true; safeNotify(); 
    try { 
      debugPrint('🤝 [Sync] Iniciando Reconciliação Colaborativa...');

      // 1. Se sou editor/dono, envio imediatamente o meu estado local pendente
      if (currentUserRole == 'owner' || currentUserRole == 'editor') {
        debugPrint('📤 [Sync] Contribuindo com dados locais para a fusão coletiva...');
        await SyncService().pushPages(onlyNotebookId: currentNotebookId); 
      }

      // 2. Aguardar um breve momento para que os outros contribuidores também enviem os seus dados
      // e o servidor consiga processar a fusão via mergeJsonItems
      await Future.delayed(const Duration(milliseconds: 1500));

      // 3. Todos (incluindo viewers) puxam a nova "verdade fundida"
      debugPrint('📥 [Sync] Puxando estado fundido do servidor...');
      await SyncService().pullPages(); 

      // 4. Atualizar a UI com os dados frescos
      final fresh = await _repository.getPagesByNotebook(currentNotebookId, liveNotebookSid); 
      if (fresh.isNotEmpty) {
        pages = fresh;
        // 🚀 FORÇAR ATUALIZAÇÃO VISUAL EM TODOS OS USUÁRIOS
        for (var p in pages) p.version++;
      }
      debugPrint('✅ [Sync] Reconciliação concluída.');
    } finally { 
      isGlobalSyncing = false; 
      safeNotify(); 
    } 
  }
  void _debounceRoomSync() { 
    if (_hasSyncedInThisSession || !isCollaborationEnabled) return; 
    _roomSyncDebouncer?.cancel(); 
    _roomSyncDebouncer = Timer(const Duration(milliseconds: 500), () async { 
      isGlobalSyncing = true; 
      safeNotify(); 
      try { 
        bool s = currentUserRole == 'viewer' || await SyncService().pushPages(onlyNotebookId: currentNotebookId); 
        if (s) { 
          await SyncService().pullPages(); 
          final r = await _repository.getPagesByNotebook(currentNotebookId, liveNotebookSid); 
          if (r.isNotEmpty) { pages = r; _hasSyncedInThisSession = true; } 
        } 
      } finally { 
        isGlobalSyncing = false; 
        safeNotify(); 
      } 
    }); 
  }
  Future<void> triggerAutoSave(LocalPage page) async { await _repository.savePage(page, liveNotebookSid); if (isRealtimeActive && liveNotebookSid != null && liveNotebookSid != 0) { _autoSyncPushTimer?.cancel(); _autoSyncPushTimer = Timer(const Duration(milliseconds: 1500), () async => await _repository.savePageToCloud(page, liveNotebookSid!, myUserId)); } }

  void _startHeartbeat() {
    if (currentUserRole != 'owner') return;
    _fingerprintTimer?.cancel();
    _fingerprintTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      if (_isDisposed || !isRealtimeActive || liveNotebookSid == null || pages.isEmpty) {
        timer.cancel();
        return;
      }
      final currentPage = pages[currentPageIndex];
      _realtimeService.broadcastPageFingerprint(
        notebookId: liveNotebookSid!,
        myUserId: myUserId,
        pageNumber: currentPage.pageNumber,
        fingerprint: currentPage.generateFingerprint(),
        updatedAt: currentPage.updatedAt, // 🚀 Para eleição de fonte
      );
    });
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isDisposed) { timer.cancel(); return; }
      final now = DateTime.now();
      bool changed = false;
      
      final toRemove = <String>[];
      _lastRemoteStrokeUpdate.forEach((id, lastUpdate) {
        if (now.difference(lastUpdate).inSeconds > 15) {
          toRemove.add(id);
        }
      });
      
      if (toRemove.isNotEmpty) {
        final curM = Map<String, Stroke>.from(remoteLiveStrokes.value);
        for (var id in toRemove) {
          remoteMovingStrokeIds.remove(id);
          _lastRemoteStrokeUpdate.remove(id);
          if (curM.containsKey(id)) {
            curM.remove(id);
            changed = true;
          }
        }
        if (changed) {
          remoteLiveStrokes.value = curM;
          safeNotify();
        }
      }
    });
  }

  // -------------------------------------------------------------------------
  // 🛡️ [ZONA PROTEGIDA] MÉTODOS DE CHAT E ÁUDIO LIVE 🛡️
  // -------------------------------------------------------------------------
  void _addChatMessage(Map<String, dynamic> d) { final String? id = d['msg_id']?.toString(); if (id != null && chatMessages.any((m) => m['msg_id'] == id)) return; chatMessages.add(d); if (chatMessages.length > 50) chatMessages.removeAt(0); if (!_isChatOpen && d['sender_id'] != myUserId) { unreadChatCount++; _newMessageAlertController.add(d); } safeNotify(); }
  void _flushPendingChat() async { if (_pendingChatQueue.isEmpty || !isRealtimeActive || liveNotebookSid == null) return; final ts = List<Map<String, dynamic>>.from(_pendingChatQueue); _pendingChatQueue.clear(); for (var m in ts) { if (m['type'] == 'text') await _realtimeService.broadcastChatMessage(notebookId: liveNotebookSid!, myUserId: myUserId, message: m['message']); else if (m['type'] == 'audio') await _realtimeService.broadcastAudioMessage(notebookId: liveNotebookSid!, myUserId: myUserId, audioUrl: m['audio_url'], duration: m['duration'] as int? ?? 0); } }
  void sendChatMessage(String m) { if (liveNotebookSid == null) return; final msg = {'type': 'text', 'sender_id': myUserId, 'message': m, 'timestamp': DateTime.now().toIso8601String()}; _addChatMessage(msg); if (isRealtimeActive && _realtimeService.isConnected) _realtimeService.broadcastChatMessage(notebookId: liveNotebookSid!, myUserId: myUserId, message: m); else _pendingChatQueue.add(msg); }

  RecordConfig _getRecordConfig() => RecordConfig(
    encoder: kIsWeb ? AudioEncoder.opus : AudioEncoder.aacLc, // 🚀 AAC/M4A como padrão universal
    bitRate: 48000, 
    sampleRate: 44100, 
    numChannels: 1, 
    echoCancel: true, 
    noiseSuppress: true, 
    autoGain: true
  );
  
  Future<void> startRecording({bool isLive = false}) async { 
    try { 
      if (_isDisposed || isRecording) return; 
      if (await _audioRecorder.hasPermission()) { 
        isRecording = true; _isRecordingLive = isLive; _recordingStartTime = DateTime.now(); _activeStreamMessageId = const Uuid().v4(); _currentSegmentIndex = 0; 
        
        String? path; 
        if (!kIsWeb) { 
          final dir = await getTemporaryDirectory(); 
          // 🚀 Padronizado para .m4a em todas as plataformas desktop/mobile
          path = '${dir.path}/audio_${_activeStreamMessageId}_0.m4a'; 
        } 
        
        await _audioRecorder.start(_getRecordConfig(), path: path ?? ''); safeNotify(); 
        if (isLive) { _segmentTimer = Timer.periodic(const Duration(seconds: 3), (timer) => _rotateRecordingSegment()); _startAmplitudeMonitoring(); }
      } 
    } catch (e) { isRecording = false; _isRecordingLive = false; safeNotify(); } 
  }
  
  void _startAmplitudeMonitoring() {
    _amplitudeTimer?.cancel(); bool lastTalkingState = false; double lastBroadcastLevel = 0.0; int ticksSinceUpdate = 0;
    _amplitudeTimer = Timer.periodic(const Duration(milliseconds: 200), (t) async {
      if (!isRecording || !isLiveSessionActive) { t.cancel(); return; }
      final amp = await _audioRecorder.getAmplitude(); final bool isTalkingNow = amp.current > -35.0; double currentLevel = isTalkingNow ? (amp.current + 50).clamp(0.0, 50.0) / 50.0 : 0.0;
      if (isTalkingNow != lastTalkingState || (isTalkingNow && ((currentLevel - lastBroadcastLevel).abs() > 0.15 || ticksSinceUpdate >= 5))) {
        lastTalkingState = isTalkingNow; lastBroadcastLevel = currentLevel; ticksSinceUpdate = 0;
        _realtimeService.broadcastVoiceStateUpdate(notebookId: liveNotebookSid ?? 0, myUserId: myUserId, isInCall: true, isTalking: isTalkingNow, audioLevel: currentLevel);
        userAudioLevels[myUserId] = currentLevel; final myIdx = onlineUsers.indexWhere((u) => u['id'].toString() == myUserId);
        if (myIdx != -1) onlineUsers[myIdx]['isTalking'] = isTalkingNow; safeNotify();
      } else ticksSinceUpdate++;
    });
  }
  
  void _rotateRecordingSegment() async { 
    if (!isRecording || _activeStreamMessageId == null) return; 
    final String mid = _activeStreamMessageId!; final int idx = _currentSegmentIndex; 
    final bool isLive = _isRecordingLive;
    try { 
      final String? stopPath = await _audioRecorder.stop(); _currentSegmentIndex++; 
      String? next; 
      if (!kIsWeb) { 
        final dir = await getTemporaryDirectory(); 
        next = '${dir.path}/audio_${mid}_$idx.m4a'; 
      } 
      await _audioRecorder.start(_getRecordConfig(), path: next ?? ''); 
      if (stopPath != null) { 
        await Future.delayed(const Duration(milliseconds: 100)); 
        _processAndSendSegment(stopPath, mid, idx, 3, isFinal: false, isLive: isLive); 
      } 
    } catch (e) { debugPrint('🚨 [Audio] Erro na rotação de segmento: $e'); } 
  }
  
  Future<void> stopAndSendAudio() async { 
    try { 
      if (_isDisposed || !isRecording) return; _segmentTimer?.cancel(); _segmentTimer = null; 
      final String mid = _activeStreamMessageId!; final int idx = _currentSegmentIndex; final int dur = recordingDuration.inSeconds; 
      final bool isLive = _isRecordingLive;
      final path = await _audioRecorder.stop(); await Future.delayed(const Duration(milliseconds: 150));
      isRecording = false; _isRecordingLive = false; _recordingStartTime = null; _activeStreamMessageId = null; safeNotify(); 
      if (path != null) _processAndSendSegment(path, mid, idx, dur % 3 == 0 ? 3 : dur % 3, isFinal: true, isLive: isLive); 
    } catch (e) { isRecording = false; _isRecordingLive = false; safeNotify(); } 
  }
  
  void handleLiveAudioAction() => isRecording ? stopAndSendAudio() : startRecording(isLive: true);
  void toggleSpeaker() { isSpeakerOn = !isSpeakerOn; _audioPlayer.setVolume(isSpeakerOn ? 1.0 : 0.0); safeNotify(); }

  bool isStreamPlaying(String streamId) => _playingStreamIds.contains(streamId);
  bool isStreamFinalized(String streamId) => _audioBuffers[streamId]?.isFinalized ?? false;
  int getStreamSegmentCount(String streamId) => _audioBuffers[streamId]?.bufferedCount ?? 0;

  Future<void> playAudioStream(String streamId) async {
    if (_playingStreamIds.contains(streamId)) { await _audioPlayer.stop(); _playingStreamIds.remove(streamId); currentlyPlayingAudioUrl = null; _currentAudioDuration = null; safeNotify(); return; }
    final buffer = _audioBuffers[streamId]; if (buffer == null) return;
    _playingStreamIds.add(streamId); safeNotify();
    while (!buffer.isReadyToStart && _playingStreamIds.contains(streamId)) await Future.delayed(const Duration(milliseconds: 200));
    int starvationRetries = 0;
    while (_playingStreamIds.contains(streamId)) {
      final String? nextUrl = buffer.popNext();
      if (nextUrl != null) {
        starvationRetries = 0; currentlyPlayingAudioUrl = nextUrl; _currentAudioDuration = null; audioPlaybackProgress = 0.0; safeNotify();
        try {
          if (isSpeakerOn) await _audioPlayer.setVolume(1.0); // 🚀 Garantir volume máximo
          await _audioPlayer.play(UrlSource(nextUrl));
          final Completer<void> doneCompleter = Completer<void>();
          final sub = _audioPlayer.onPlayerStateChanged.listen((state) { if (state == PlayerState.completed || state == PlayerState.stopped) { if (!doneCompleter.isCompleted) doneCompleter.complete(); } });
          try { await doneCompleter.future.timeout(const Duration(seconds: 5)); } catch (_) {} finally { await sub.cancel(); }
        } catch (e) { await Future.delayed(const Duration(milliseconds: 500)); }
      } else {
        if (buffer.isFinalized && !buffer.hasMoreToPlay) break;
        await Future.delayed(const Duration(milliseconds: 300)); starvationRetries++;
        if (starvationRetries > 20) break;
      }
    }
    _playingStreamIds.remove(streamId); currentlyPlayingAudioUrl = null; safeNotify();
  }

  Future<void> playAudioMessage(String url) async {
    if (currentlyPlayingAudioUrl == url) { 
      await _audioPlayer.stop(); 
      currentlyPlayingAudioUrl = null; 
      _currentAudioDuration = null; // 🚀 Reset
      safeNotify(); 
      return; 
    }
    
    // Novo áudio a começar
    currentlyPlayingAudioUrl = url; 
    _currentAudioDuration = null; // 🚀 Reset para calcular nova duração
    audioPlaybackProgress = 0.0;
    safeNotify(); 

    if (isSpeakerOn) await _audioPlayer.setVolume(1.0); 
    
    if (url.startsWith('http')) {
      await _audioPlayer.play(UrlSource(url));
    } else {
      await _audioPlayer.play(DeviceFileSource(url));
    }
  }

  void _handleIncomingAudioStream(Map<String, dynamic> data) {
    final String? sid = data['msg_id']?.toString(); final String? url = data['audio_url']?.toString(); final int? index = data['index'] as int?; final String? senderId = data['sender_id']?.toString();
    if (sid == null || url == null || index == null || senderId == null) return; final bool isFinal = data['is_final'] == true;
    final buffer = _audioBuffers.putIfAbsent(sid, () => AudioStreamBuffer(msgId: sid, senderId: senderId));
    if (buffer.bufferedCount == 0) _addChatMessage(data);
    else { final idx = chatMessages.indexWhere((m) => m['msg_id'] == sid); if (idx != -1) { chatMessages[idx]['duration'] = (chatMessages[idx]['duration'] as int? ?? 0) + (data['duration'] as int? ?? 0); chatMessages[idx]['is_final'] = isFinal; safeNotify(); } }
    buffer.addSegment(index, url, isFinal: isFinal);
    if (_audioBuffers.length > 50) { final now = DateTime.now(); _audioBuffers.removeWhere((id, b) => !_playingStreamIds.contains(id) && now.difference(b.lastActivity).inMinutes > 5); }
    if (isLiveSessionActive && senderId != myUserId && !_playingStreamIds.contains(sid)) { if (buffer.isReadyToStart) playAudioStream(sid); }
    safeNotify();
  }

  void _processAndSendSegment(String path, String msgId, int index, int duration, {bool isFinal = false, bool isLive = false, int retryCount = 0}) async {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    try {
      final bytes = await File(path).readAsBytes(); final url = await _repository.uploadAudio(liveNotebookSid!, 'segment_${msgId}_$index.m4a', bytes);
      if (url != null) { 
        _realtimeService.broadcastAudioMessage(
          notebookId: liveNotebookSid!, 
          myUserId: myUserId, 
          audioUrl: url, 
          duration: duration, 
          isLive: isLive, 
          streamMsgId: msgId, 
          segmentIndex: index, 
          isFinal: isFinal
        ); 
        
        // 🚀 ADICIONAR AO CHAT LOCAL (Para o proprietário ver a própria mensagem)
        if (index == 0 && !isLive) {
          _addChatMessage({
            'msg_id': msgId,
            'type': 'audio',
            'sender_id': myUserId,
            'audio_url': url,
            'duration': duration, 
            'timestamp': DateTime.now().toIso8601String(),
          });
        }

        if (_failedSegmentsQueue.isNotEmpty) { 
          final next = _failedSegmentsQueue.removeAt(0); 
          _processAndSendSegment(next['path'], next['msgId'], next['index'], next['duration'], isFinal: next['isFinal'], isLive: next['isLive'] ?? false, retryCount: next['retryCount'] + 1); 
        } 
      }
      else { if (retryCount < 3) _failedSegmentsQueue.add({'path': path, 'msgId': msgId, 'index': index, 'duration': duration, 'isFinal': isFinal, 'isLive': isLive, 'retryCount': retryCount}); }
    } catch (e) {}
  }
  // -------------------------------------------------------------------------

  Future<void> pickAndInsertImage(LocalPage p) async {
    final picker = ImagePicker(); final pf = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pf != null) {
      final String lid = const Uuid().v4(); 
      // 🚀 Injetar dono ao criar
      final nib = ImageBlock(
        id: lid, imagePath: pf.path, position: const Offset(100, 150), 
        width: 300.0, height: 200.0, creatorId: myUserId
      );
      _executeAction(AddImageAction(pageClientId: p.clientId, pageNumber: p.pageNumber, block: nib)); selectedEditingImageId = lid; safeNotify();
      if (isRealtimeActive && liveNotebookSid != null) {
        uploadingImageIds.add(lid); _realtimeService.broadcastImageUploading(notebookId: liveNotebookSid!, myUserId: myUserId, isUploading: true);
        _repository.uploadImage(liveNotebookSid!, pf.name, await pf.readAsBytes()).then((url) {
          uploadingImageIds.remove(lid); _realtimeService.broadcastImageUploading(notebookId: liveNotebookSid!, myUserId: myUserId, isUploading: false);
          if (url != null) { nib.imagePath = url; _repository.saveSingleImageBlock(p.id!, nib); broadcastImageBlockUpdate(p, nib, senderId: myUserId); triggerAutoSave(p); } else failedImageUploads.add(lid); safeNotify();
        });
      }
    }
  }
}

final canvasProvider = ChangeNotifierProvider.autoDispose<CanvasController>((ref) {
  return CanvasController(ref.read(realtimeServiceProvider), repository: ref.read(canvasRepositoryProvider));
});
