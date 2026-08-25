import 'dart:convert';
import 'dart:async';
import 'dart:io' as io;
import 'package:drift/drift.dart' as drift;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; 
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';
import 'package:vector_math/vector_math_64.dart' hide Colors, Matrix4;

import 'package:caderno_digital_app/core/database/app_database.dart' as db hide Notebook, Subject, User, Page;
import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/core/network/sync_service.dart';
import 'package:caderno_digital_app/core/network/sync_provider.dart'; 
import 'package:caderno_digital_app/core/network/api_service.dart';
import 'package:caderno_digital_app/core/network/time_service.dart'; 
import 'package:caderno_digital_app/features/canvas/models/canvas_enums.dart';
import 'package:caderno_digital_app/features/canvas/models/image_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/models/stroke_model.dart';
import 'package:caderno_digital_app/features/canvas/models/text_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/canvas_action_model.dart';
import 'package:caderno_digital_app/core/utils/geometry_utils.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';
import 'package:caderno_digital_app/features/canvas/services/audio_session_service.dart';
import 'package:caderno_digital_app/features/canvas/services/collaboration_room_service.dart';


class CanvasController extends ChangeNotifier {
  final CanvasRepository _repository;
  final RealtimeService _realtimeService;
  final SyncService _syncService; 
  final ApiService _apiService = ApiService();
  final AudioSessionService audioService;
  final CollaborationRoomService collabService;

  ValueNotifier<RealtimeStatus> get statusNotifier => _realtimeService.statusNotifier; 

  CanvasController(
    this._realtimeService, 
    this._syncService, 
    this.audioService,
    this.collabService,
    {CanvasRepository? repository}
  ) : _repository = repository ?? CanvasRepository(db.AppDatabase.instance) {
    transformationController = TransformationController();
    
    // Listen to service changes to propagate to UI
    audioService.addListener(notifyListeners);
    collabService.addListener(notifyListeners);
  }

  bool _isNotebookDeleted = false;
  bool get isNotebookDeleted => _isNotebookDeleted;

  bool _isDisposed = false; 
  void safeNotify() { if (!_isDisposed) notifyListeners(); }

  // -------------------------------------------------------------------------
  // 🛡️ [STATE DELEGATION] - Collaboration Service
  // -------------------------------------------------------------------------
  ValueNotifier<Map<String, dynamic>> get remotePointers => collabService.remotePointers;
  ValueNotifier<Map<String, Stroke>> get remoteLiveStrokes => collabService.remoteLiveStrokes;
  Set<String> get usersInLiveSession => collabService.usersInLiveSession;
  Map<String, double> get userAudioLevels => collabService.userAudioLevels;
  List<Map<String, dynamic>> get onlineUsers => collabService.onlineUsers;
  Map<String, String?> get userReactions => collabService.userReactions;
  bool get isMyHandRaised => collabService.isMyHandRaised;
  String? get followingUserId => collabService.followingUserId;
  Set<String> get whoIsWatchingMe => collabService.whoIsWatchingMe;
  bool get isBroadcastingViewport => collabService.isBroadcastingViewport;
  Set<String> get remoteMovingStrokeIds => collabService.remoteMovingStrokeIds;
  Set<String> get tearingPageClientIds => collabService.tearingPageClientIds;
  
  List<Map<String, dynamic>> get chatMessages => collabService.chatMessages;
  int get unreadChatCount => collabService.unreadChatCount;
  bool get isChatOpen => collabService.isChatOpen;
  set isChatOpen(bool value) => collabService.isChatOpen = value;

  Stream<Map<String, dynamic>> get onNewMessageAlert => collabService.onNewMessageAlert;
  Stream<String> get onPermissionAlert => collabService.onPermissionAlert;
  Stream<void> get onNotebookDeletedByOwner => collabService.onNotebookDeletedByOwner;
  Stream<Map<String, dynamic>> get onSessionMetaReceived => collabService.onSessionMetaReceived;

  bool get isLiveSessionActive => collabService.isLiveSessionActive;
  bool get isConnectingVoice => collabService.isConnectingVoice;
  bool get isRemoteVoiceCallActive => collabService.isRemoteVoiceCallActive;
  Map<String, dynamic>? get incomingVoiceCall => collabService.incomingVoiceCall;
  Map<String, Color> get userColorsMap => collabService.userColorsMap;

  void toggleVoiceCall(String userId) => collabService.toggleVoiceCall(userId);
  void acceptVoiceCall() => collabService.acceptVoiceCall();
  void dismissVoiceCall() => collabService.dismissVoiceCall();
  void toggleParticipantVoice(String userId, bool enabled) => collabService.toggleParticipantVoice(userId, enabled);
  void fetchEnrolledMembers() => collabService.fetchEnrolledMembers();
  void updateUserRoleLocally(String userId, String role) => collabService.updateUserRoleLocally(userId, role);

  // -------------------------------------------------------------------------
  // 🛡️ [STATE DELEGATION] - Audio Service
  // -------------------------------------------------------------------------
  String? get currentlyPlayingAudioUrl => audioService.currentlyPlayingAudioUrl;
  double get audioPlaybackProgress => audioService.audioPlaybackProgress;
  double get playbackSpeed => audioService.playbackSpeed;
  bool get isAudioPlaying => audioService.isAudioPlaying;
  Duration get audioPosition => audioService.audioPosition;
  Duration get audioDuration => audioService.audioDuration;
  bool get isRecording => audioService.isRecording;
  bool get isLessonRecording => audioService.isLessonRecording;
  List<db.LessonRecording> get lessonRecordings => audioService.lessonRecordings;
  db.LessonRecording? get currentlyPlayingRecording => audioService.currentlyPlayingRecording;
  bool get isSpeakerOn => audioService.isSpeakerOn;
  Duration get recordingDuration => audioService.recordingDuration;

  // -------------------------------------------------------------------------
  // Canvas State Properties
  // -------------------------------------------------------------------------
  List<LocalPage> pages = [];
  int currentPageIndex = 0;
  bool isLoading = true;
  bool isUploadingImage = false; 
  bool isGlobalSyncing = false; 
  bool get hasUnsyncedChanges => pages.any((p) => p.syncedWithCloud == 0); 
  bool isAiSummarizing = false; 
  int? liveNotebookSid;
  int currentNotebookId = 0;
  String currentPaperSize = 'A4';
  
  bool get isSessionLocked => collabService.isSessionLocked;
  bool get isAuthorColorEnabled => collabService.isAuthorColorEnabled;
  String get sessionVoiceMode => collabService.sessionVoiceMode;
  bool get isVoiceAuthorized => collabService.isVoiceAuthorized;
  List<Map<String, dynamic>> get enrolledMembers => collabService.enrolledMembers;
  
  late String liveLineType;
  late double liveLineSpacing; 
  String currentUserRole = 'viewer';
  String currentTemplateType = 'study'; 
  Set<String>? visibleAuthorIds; 
  String myUserId = ""; 
  String? get authorityId => collabService.authorityId;
  bool get isAuthority => authorityId == myUserId;
  
  bool get canSpeak {
    if (currentUserRole == 'owner' || currentUserRole == 'editor') return true;
    if (sessionVoiceMode == 'muted') return false;
    return isVoiceAuthorized;
  }

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
  DeleteAction? _activeEraserBatch;

  bool isRealtimeActive = false;
  bool isCollaborationEnabled = false; 
  bool isFocusMode = false; 
  bool isTransformMode = false; 

  String? get sessionTitle => collabService.sessionTitle;
  Set<int>? get authorizedPageIds => collabService.authorizedPageIds;

  final Set<String> uploadingImageIds = {}; 
  final Set<String> failedImageUploads = {}; 
  Map<int, String> get remoteEditingTitles => collabService.remoteEditingTitles;

  late TransformationController transformationController;
  final PageController pageController = PageController(initialPage: 0);
  final ValueNotifier<List<Offset>> activePointsNotifier = ValueNotifier([]);

  int? activeDrawingPageNumber;
  Offset? currentViewportCenter;
  double? currentVisibleWidth;
  Size? lastScreenSize;

  // -------------------------------------------------------------------------
  // DELEGATED METHODS - Audio
  // -------------------------------------------------------------------------
  Future<void> startLessonRecording() => audioService.startLessonRecording();
  Future<void> startRecording({bool isLive = false, bool isLiveSessionActive = false, int? liveNotebookSid, String? myUserId}) => audioService.startRecording(isLive: isLive, isLiveSessionActive: isLiveSessionActive, liveNotebookSid: liveNotebookSid, myUserId: myUserId);
  Future<void> stopAndSendAudio() => audioService.stopAndSendAudio(liveNotebookSid, myUserId);
  Future<void> stopLessonRecording(String title) => audioService.stopLessonRecording(title, currentNotebookId, liveNotebookSid, myUserId);
  Future<void> playRecording(db.LessonRecording rec) => audioService.playRecording(rec);
  Future<void> playAudioMessage(String url) => audioService.playAudioMessage(url);
  Future<void> pauseAudio() => audioService.pauseAudio();
  Future<void> resumeAudio() => audioService.resumeAudio();
  Future<void> stopAudio() => audioService.stopAudio();
  bool isStreamPlaying(String mid) => audioService.isStreamPlaying(mid);
  bool isStreamFinalized(String mid) => audioService.isStreamFinalized(mid);
  int getStreamSegmentCount(String mid) => audioService.getStreamSegmentCount(mid);
  Future<void> playAudioStream(String mid) => audioService.playAudioStream(mid);
  Future<void> seekAudio(double percent) => audioService.seekAudio(percent);
  Future<void> skipAudio(int seconds) => audioService.skipAudio(seconds);
  void setPlaybackSpeed(double speed) => audioService.setPlaybackSpeed(speed);
  void toggleSpeaker() => audioService.toggleSpeaker();

  // -------------------------------------------------------------------------
  // DELEGATED METHODS - Collaboration
  // -------------------------------------------------------------------------
  void sendMessage(String m) => collabService.sendMessage(m);
  void sendChatMessage(String m) => collabService.sendMessage(m);
  void toggleHandRaise() => collabService.toggleHandRaise();
  void sendReaction(String emoji) => collabService.sendReaction(emoji);
  void toggleFollowUser(String? uid, String myId) => collabService.toggleFollowUser(uid);
  void startViewportBroadcasting([String? userId]) {
    collabService.currentViewportCenter = currentViewportCenter;
    collabService.currentVisibleWidth = currentVisibleWidth;
    collabService.lastScreenSize = lastScreenSize;
    collabService.startViewportBroadcasting();
  }
  void stopViewportBroadcasting() => collabService.stopViewportBroadcasting();
  void toggleSessionLock() => collabService.toggleSessionLock();
  void toggleAuthorColors() => collabService.toggleAuthorColors();
  Future<void> setVoiceMode(String mode) => collabService.setVoiceMode(mode);

  @override
  void dispose() {
    _isDisposed = true; 
    audioService.removeListener(notifyListeners);
    collabService.removeListener(notifyListeners);
    activePointsNotifier.dispose(); 
    transformationController.dispose(); 
    pageController.dispose();
    _dbPagesSubscription?.cancel(); 
    _dbNotebookSubscription?.cancel();
    _autoSyncPushTimer?.cancel();
    _typingDebounce?.cancel();
    _textBroadcastDebounce?.cancel();
    _metadataBroadcastThrottle?.cancel();
    _remoteImageSaveTimer?.cancel();
    
    if (isRealtimeActive && liveNotebookSid != null) { 
      _flushPendingStrokes(); 
      _repository.savePageToCloud(pages[currentPageIndex], liveNotebookSid!, myUserId); 
    }
    collabService.leaveSession();
    if (liveNotebookSid != null && liveNotebookSid != 0) _realtimeService.leaveNotebookChannel(liveNotebookSid!);
    SyncService.isCollaborationActive = false; 
    super.dispose();
  }

  void toggleFocusMode() { isFocusMode = !isFocusMode; safeNotify(); }

  void _markPageDirty(LocalPage page) {
    page.syncedWithCloud = 0;
    page.updatedAt = TimeService().nowMs();
    page.version++;
  }

  void togglePageFreeze(LocalPage page) {
    if (currentUserRole != 'owner') return;
    page.isFrozen = !page.isFrozen;
    _markPageDirty(page);
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

  Future<void> _ensurePageLoaded(int index) async {
    if (index < 0 || index >= pages.length) return;
    final page = pages[index];
    if (page.isContentLoaded || page.id == null) return;
    try {
      final content = await _repository.loadPageContent(page.id!);
      page.strokes = content['strokes'];
      page.textBlocks = content['textBlocks'];
      page.imageBlocks = content['image_blocks'] ?? content['imageBlocks'];
      page.isContentLoaded = true;
      safeNotify();
    } catch (e) {
      debugPrint('LazyLoad error: $e');
    }
  }

  Timer? _metadataBroadcastThrottle;
  Timer? _remoteImageSaveTimer; 
  Timer? _autoSyncPushTimer;
  Timer? _typingDebounce;
  Timer? _textBroadcastDebounce;

  Map<String, dynamic>? pendingInvite; 
  final List<Map<String, dynamic>> _pendingStrokesQueue = [];
  DateTime _lastMoveBroadcastTime = DateTime.now();

  StreamSubscription? _dbPagesSubscription;
  StreamSubscription? _dbNotebookSubscription;

  void exitNotebook() {
    pages.clear();
    currentPageIndex = 0;
    liveNotebookSid = null;
    isRealtimeActive = false;
    isCollaborationEnabled = false;
    safeNotify();
  }

  void clearTextEditing() {
    activeInlineTarget = InlineTarget.none;
    activeTextBlock = null;
    safeNotify();
  }

  void _resetZoomForPage(LocalPage page, String paperSize, {Size? screenSize}) { 
    double scale = 1.4;
    final pSize = GeometryUtils.getPaperSize(paperSize);
    if (screenSize != null) {
      final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
      final pageCenter = Offset(pSize.width / 2, pSize.height / 2);
      transformationController.value = Matrix4.identity()..translate(screenCenter.dx, screenCenter.dy)..scale(scale, scale, 1.0)..translate(-pageCenter.dx, -pageCenter.dy);
    } else {
      transformationController.value = Matrix4.diagonal3Values(scale, scale, 1.0); 
    }
  }

  Future<void> initNotebook(int notebookId, int? notebookSid, String lineType, String paperSize, String role, String? userId, {double? lineSpacing, String? templateType, String? collaborationMode}) async {
    isLoading = true; currentNotebookId = notebookId; liveNotebookSid = notebookSid; liveLineType = lineType; currentPaperSize = paperSize; liveLineSpacing = lineSpacing ?? 28.0; currentUserRole = role; 
    currentTemplateType = templateType ?? 'study';
    myUserId = userId ?? '';

    collabService.getPages = () => pages;
    collabService.getCurrentPageIndex = () => currentPageIndex;
    collabService.getCurrentScale = () => transformationController.value.getMaxScaleOnAxis();

    collabService.onSyncRequested = () => _performCollectiveSync();
    collabService.onExecuteAction = (d) => _handleRemoteAction(d);
    collabService.onPageEvent = (d) => _handlePageEvent(d);
    collabService.onFullStateRequested = (d) => _handleFullStateRequest(d);
    collabService.onFullStateReceived = (d) => _handleFullStateReceived(d);
    collabService.onCloudSyncSignal = (d) => _syncService.pullSpecificPage(liveNotebookSid!, d['page_number']);
    collabService.onSmoothTransition = (m) => _startSmoothTransition(m);
    collabService.onPageNavigationRequested = (i) => jumpToPage(i);
    collabService.onAutoNavigateAfterDeletion = () => _autoNavigateAfterDeletion();
    
    audioService.onAudioMessageProcessed = (d) => collabService.chatMessages.add(d);

    SyncService.activeNotebookId = notebookId; 
    await audioService.loadLessonRecordings(notebookId); 
    _initNotebookSubscriptions(notebookId, userId, paperSize);
    _ensurePageLoaded(0);
  }

  void _initNotebookSubscriptions(int notebookId, String? userId, String paperSize) {
    _dbNotebookSubscription?.cancel();
    final d = db.AppDatabase.instance;
    _dbNotebookSubscription = (d.select(d.notebooks)..where((t) => t.id.equals(notebookId))).watchSingleOrNull().listen((row) { 
      if (row == null || row.isDeleted == 1) { _isNotebookDeleted = true; return; }
      if (row.serverId != null && liveNotebookSid == null) { liveNotebookSid = row.serverId; safeNotify(); }
      if (row.role != null) { currentUserRole = row.role!; safeNotify(); }
    });
    
    _dbPagesSubscription?.cancel();
    _dbPagesSubscription = _repository.watchPagesByNotebook(notebookId).listen((fps) async {
      final List<LocalPage> activePages = fps.where((p) => !p.isDeleted).toList();
      pages = activePages;
      pages.sort((a, b) => a.pageNumber.compareTo(b.pageNumber));
      if (isLoading && pages.isNotEmpty) _resetZoomForPage(pages.first, pages.first.paperSize, screenSize: lastScreenSize);
      isLoading = false; safeNotify();
      if (pages.isNotEmpty) _ensurePageLoaded(currentPageIndex);
      if (activePages.isNotEmpty && currentPageIndex >= activePages.length) _autoNavigateAfterDeletion();
    });
  }

  void _autoNavigateAfterDeletion() {
    if (pages.isEmpty) return;
    int targetIndex = (currentPageIndex >= pages.length) ? pages.length - 1 : currentPageIndex;
    jumpToPage(targetIndex < 0 ? 0 : targetIndex);
  }

  Future<void> toggleCollaboration(bool enable, {bool suppressBroadcast = false, List<int>? pageIds, String? alternativeTitle, String? sharingType}) async {
    if (isCollaborationEnabled == enable) return; 
    if (enable) { 
      isGlobalSyncing = true; safeNotify();
      try {
        await _syncService.pushNotebooks();
        if (liveNotebookSid != null && liveNotebookSid != 0) await _syncService.pushPages(onlyNotebookId: currentNotebookId);
      } finally { isGlobalSyncing = false; safeNotify(); }
      isCollaborationEnabled = true; SyncService.isCollaborationActive = true;
      if (liveNotebookSid != null && liveNotebookSid != 0) { 
        await collabService.init(liveNotebookSid!, myUserId, currentUserRole, pageIds: pageIds, alternativeTitle: alternativeTitle, sharingType: sharingType);
        isRealtimeActive = true; 
        if (!suppressBroadcast) _realtimeService.broadcastLiveInvite(notebookId: liveNotebookSid!, myUserId: myUserId, senderName: "Um colega", targetUserIds: []); 
      } 
    }
    else { isCollaborationEnabled = false; SyncService.isCollaborationActive = false; collabService.dispose(); isRealtimeActive = false; }
    safeNotify();
  }

  Future<void> addNewPage(bool isLandscape, {String paperSize = 'A4', String? lineType, double? lineSpacing}) async {
    final requestedPageNumber = (pages.isEmpty ? 0 : pages.last.pageNumber) + 1;
    final String clientId = const Uuid().v4();
    if (isCollaborationEnabled && liveNotebookSid != null) {
      final response = await _apiService.post('/notebooks/$liveNotebookSid/pages', {'client_id': clientId, 'page_number': requestedPageNumber, 'paper_size': paperSize, 'is_landscape': isLandscape});
      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        final np = LocalPage(serverId: data['id'], notebookId: currentNotebookId, pageNumber: data['page_number'], isLandscape: isLandscape, paperSize: paperSize, clientId: clientId, syncedWithCloud: 1);
        await _repository.savePage(np, liveNotebookSid); await _repository.reindexPages(currentNotebookId);
        final fresh = await _repository.getPagesByNotebook(currentNotebookId, liveNotebookSid);
        pages = fresh; jumpToPage(pages.indexWhere((p) => p.clientId == clientId));
      }
      return;
    }
    final np = LocalPage(notebookId: currentNotebookId, pageNumber: requestedPageNumber, isLandscape: isLandscape, paperSize: paperSize, clientId: clientId);
    await _executeAction(AddPageAction(pageClientId: np.clientId, pageNumber: np.pageNumber, isLandscape: isLandscape, paperSize: paperSize), targetPage: np);
    jumpToPage(pages.indexOf(np));
  }

  Future<void> deletePage(LocalPage pd) async {
    if (pd.id == null) return;
    if (isCollaborationEnabled && liveNotebookSid != null && pd.serverId != null) {
      final response = await _apiService.post('/sync/pages/push', {'pages': [{'client_id': pd.clientId, 'is_deleted': 1, 'notebook_id': liveNotebookSid, 'updated_at': DateTime.now().millisecondsSinceEpoch}]});
      if (response.statusCode == 200) {
        await (db.AppDatabase.instance.delete(db.AppDatabase.instance.pages)..where((t) => t.id.equals(pd.id!))).go();
        await _repository.reindexPages(currentNotebookId);
        pages = await _repository.getPagesByNotebook(currentNotebookId, liveNotebookSid);
        _autoNavigateAfterDeletion();
      }
      return;
    }
    tearingPageClientIds.add(pd.clientId); safeNotify();
    await Future.delayed(const Duration(milliseconds: 400));
    await _executeAction(DeletePageAction(pageClientId: pd.clientId, pageNumber: pd.pageNumber, pageData: pd.toJson()), targetPage: pd);
    tearingPageClientIds.remove(pd.clientId);
    if (isRealtimeActive && liveNotebookSid != null) {
      _realtimeService.broadcastPageEvent(notebookId: liveNotebookSid!, myUserId: myUserId, pageData: {'action': 'delete', 'page_client_id': pd.clientId, 'page_number': pd.pageNumber});
      await _performCollectiveSync();
    }
  }

  void setPageIndex(int i) { 
    if (currentPageIndex == i) return; 
    currentPageIndex = i; 
    if (i < pages.length) {
      _ensurePageLoaded(i);
      _resetZoomForPage(pages[i], pages[i].paperSize, screenSize: lastScreenSize);
    }
    safeNotify(); 
    if (isCollaborationEnabled && liveNotebookSid != null && i < pages.length) _syncService.pullSpecificPage(liveNotebookSid!, pages[i].pageNumber);
  }
  
  void jumpToPage(int i) { if (i >= 0 && i < pages.length) { setPageIndex(i); pageController.jumpToPage(i); } }

  void switchTool(ToolMode m) {
    if (m == ToolMode.eraser && (selectedStrokeIds.isNotEmpty || selectedTextIds.isNotEmpty || selectedImageIds.isNotEmpty)) { deleteSelection(pages[currentPageIndex]); return; }
    currentTool = m; selectedEditingImageId = null; isTransformMode = false;
    if (isRealtimeActive && liveNotebookSid != null && currentViewportCenter != null) collabService.broadcastPointer(currentViewportCenter!, currentPageIndex + 1, m.name);
    safeNotify();
  }

  void eraseAtPosition(Offset pos, LocalPage page) {
    if (page.isFrozen) return;
    final bool canDeleteAll = currentUserRole == 'owner' || (currentUserRole == 'editor' && currentTemplateType != 'formal');
    final sR = page.strokes.where((s) => !s.isDeleted && s.points.any((pt) => (pt - pos).distance < 24.0) && (canDeleteAll || s.creatorId == myUserId)).toList();
    final tR = page.textBlocks.where((tb) => !tb.isDeleted && (Rect.fromLTWH(tb.position.dx, tb.position.dy, 150, tb.fontSize * 1.5).contains(pos) || (tb.position - pos).distance < 24.0) && (canDeleteAll || tb.creatorId == myUserId)).toList();
    final iR = page.imageBlocks.where((img) => !img.isDeleted && Rect.fromLTWH(img.position.dx, img.position.dy, img.width, img.height).contains(pos) && (canDeleteAll || img.creatorId == myUserId)).toList();
    if (sR.isNotEmpty || tR.isNotEmpty || iR.isNotEmpty) {
      for (var s in sR) s.isDeleted = true; for (var t in tR) t.isDeleted = true; for (var img in iR) img.isDeleted = true;
      _executeAction(DeleteAction(
        pageClientId: page.clientId, 
        pageNumber: page.pageNumber, 
        strokes: sR.map((s)=>s.clone()).toList(), 
        texts: tR.map((t)=>t.clone()).toList(), 
        images: iR.map((i)=>i.clone()).toList()
      ));
    }
  }

  bool _deleteSelectionOnPage(LocalPage page) {
    final bool canDeleteAll = currentUserRole == 'owner' || (currentUserRole == 'editor' && currentTemplateType != 'formal');
    final sR = page.strokes.where((s) => !s.isDeleted && selectedStrokeIds.contains(s.id) && (canDeleteAll || s.creatorId == myUserId)).toList();
    final tR = page.textBlocks.where((t) => !t.isDeleted && selectedTextIds.contains(t.id) && (canDeleteAll || t.creatorId == myUserId)).toList();
    final iR = page.imageBlocks.where((img) => !img.isDeleted && selectedImageIds.contains(img.id) && (canDeleteAll || img.creatorId == myUserId)).toList();
    if (sR.isEmpty && tR.isEmpty && iR.isEmpty) return false;
    for (var s in sR) s.isDeleted = true; for (var t in tR) t.isDeleted = true; for (var img in iR) img.isDeleted = true;
    _executeAction(DeleteAction(pageClientId: page.clientId, pageNumber: page.pageNumber, strokes: sR.map((s)=>s.clone()).toList(), texts: tR.map((t)=>t.clone()).toList(), images: iR.map((i)=>i.clone()).toList()));
    selectedStrokeIds.clear(); selectedTextIds.clear(); selectedImageIds.clear(); safeNotify();
    return true;
  }

  void deleteSelection(LocalPage page) => _deleteSelectionOnPage(page);

  void addStroke(LocalPage p, Stroke s) {
    final ns = Stroke(id: s.id, color: s.color, thickness: s.thickness, points: s.points, creatorId: myUserId, pageNumber: p.pageNumber, isHighlighter: currentTool == ToolMode.highlighter);
    _executeAction(AddStrokeAction(pageClientId: p.clientId, pageNumber: p.pageNumber, stroke: ns));
  }

  void moveSelectedStrokes(LocalPage page, Offset delta) {
    if (page.isFrozen) return;
    final bool canMoveAll = currentUserRole == 'owner' || (currentUserRole == 'editor' && currentTemplateType != 'formal');
    for (var id in selectedStrokeIds) { 
      final m = page.strokes.where((s) => s.id == id); 
      if (m.isNotEmpty && (canMoveAll || m.first.creatorId == myUserId)) { final s = m.first; for (int i = 0; i < s.points.length; i++) s.points[i] += delta; }
    }
    for (var id in selectedTextIds) { final m = page.textBlocks.where((t) => t.id == id); if (m.isNotEmpty && (canMoveAll || m.first.creatorId == myUserId)) m.first.position += delta; }
    for (var id in selectedImageIds) { final m = page.imageBlocks.where((img) => img.id == id); if (m.isNotEmpty && (canMoveAll || m.first.creatorId == myUserId)) m.first.position += delta; }
    page.version++; _totalSelectionDelta += delta; safeNotify(); 
    final now = DateTime.now(); if (now.difference(_lastMoveBroadcastTime).inMilliseconds > 30) { _broadcastSelectionMovement(page, isFinal: false); _lastMoveBroadcastTime = now; }
  }

  void finalizeSelectionMovement(LocalPage page) {
    if (_totalSelectionDelta != Offset.zero) {
      final action = MoveAction(pageClientId: page.clientId, pageNumber: page.pageNumber, strokeIds: List.from(selectedStrokeIds), textIds: List.from(selectedTextIds), imageIds: List.from(selectedImageIds), delta: _totalSelectionDelta);
      _markPageDirty(page); _undoStack.add(action); _redoStack.clear(); _broadcastSelectionMovement(page, isFinal: true); _repository.savePage(page, liveNotebookSid); triggerAutoSave(page);
    }
    _totalSelectionDelta = Offset.zero; safeNotify();
  }

  void setTextEditing(InlineTarget t, [TextBlock? b]) {
    activeInlineTarget = t; activeTextBlock = b; safeNotify();
    if (b != null) broadcastTextBlockUpdate(pages[currentPageIndex], b, isEditing: true);
  }

  void recordTextUpdate(LocalPage p, TextBlock o, TextBlock n) {
    n.updatedAt = DateTime.now().millisecondsSinceEpoch;
    _executeAction(UpdateTextAction(pageClientId: p.clientId, pageNumber: p.pageNumber, textId: n.id, oldState: o, newState: n));
    broadcastTextBlockUpdate(p, n);
  }

  LocalPage? _getTargetPage(String cid) { try { return pages.firstWhere((p) => p.clientId == cid); } catch (e) { return null; } }

  Future<void> _executeAction(CanvasAction action, {bool isRemote = false, LocalPage? targetPage}) async {
    final target = targetPage ?? _getTargetPage(action.pageClientId); if (target == null) return;
    if (target.isFrozen && !isRemote) return;
    if (!isRemote) _markPageDirty(target);
    action.execute(target);
    _undoStack.add(action); _redoStack.clear(); if (_undoStack.length > 50) _undoStack.removeAt(0);
    if (action is DeletePageAction || action is AddPageAction) { await _repository.savePage(target, liveNotebookSid); await _repository.reindexPages(currentNotebookId); } 
    else await _persistIncrementalAction(target, action);
    if (!isRemote) _broadcastAction(action); 
    safeNotify();
  }

  Future<void> _persistIncrementalAction(LocalPage target, CanvasAction action) async {
    final String cid = target.clientId;
    if (action is AddStrokeAction) await _repository.saveSingleStroke(cid, action.stroke);
    else if (action is AddTextAction) await _repository.saveSingleTextBlock(cid, action.block);
    else if (action is AddImageAction) await _repository.saveSingleImageBlock(cid, action.block);
    else if (action is UpdateTextAction) await _repository.saveSingleTextBlock(cid, action.newState);
    else if (action is UpdateImageAction) await _repository.saveSingleImageBlock(cid, action.newState);
    if (action is DeleteAction) { for (var s in action.strokes) await _repository.deleteSingleStroke(s.id); for (var t in action.texts) await _repository.deleteSingleTextBlock(t.id); for (var i in action.images) await _repository.saveSingleImageBlock(cid, i); }
    else if (action is MoveAction) { for (var id in action.strokeIds) await _repository.saveSingleStroke(cid, target.strokes.firstWhere((s) => s.id == id)); }
    triggerAutoSave(target);
  }

  void _broadcastAction(CanvasAction action) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    final target = _getTargetPage(action.pageClientId); if (target == null) return;
    if (action is DeleteAction) {
      for (var s in action.strokes) _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: { 'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'strokes': [{'id': s.id, 'is_deleted': true}] });
    } else if (action is AddStrokeAction) {
      final s = action.stroke.simplify(epsilon: 0.2); 
      _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: { 'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'strokes': [{ 'id': s.id, 'color': s.color, 'thickness': s.thickness, 'is_final': true, 'is_highlighter': s.isHighlighter ? 1 : 0, 'points': s.points.map((pt) => {'x': pt.dx, 'y': pt.dy}).toList() }] });
    } else if (action is AddTextAction) { _realtimeService.broadcastTextBlock(notebookId: liveNotebookSid!, myUserId: myUserId, textData: { 'page_client_id': action.pageClientId, 'page_number': action.pageNumber, 'block': action.block.toJson(), 'is_editing': false }); }
  }

  void sendStrokeUpdate({required String pageClientId, required int pageNumber, required String strokeId, required List<Offset> points, bool isFinal = false}) async {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    final data = { 'page_client_id': pageClientId, 'page_number': pageNumber, 'strokes': [{ 'id': strokeId, 'color': selectedColorHex, 'thickness': selectedThickness, 'is_final': isFinal, 'is_highlighter': currentTool == ToolMode.highlighter ? 1 : 0, 'points': (isFinal ? GeometryUtils.simplifyPoints(points, epsilon: 0.2) : points).map((pt) => {'x': pt.dx, 'y': pt.dy}).toList() }] };
    try {
      final success = await _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: data);
      if (!success) _pendingStrokesQueue.add(data); else if (_pendingStrokesQueue.isNotEmpty) _flushPendingStrokes();
    } catch (e) { _pendingStrokesQueue.add(data); }
  }

  void _flushPendingStrokes() async {
    if (_pendingStrokesQueue.isEmpty || !isRealtimeActive || liveNotebookSid == null) return;
    for (var d in _pendingStrokesQueue) await _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: d);
    _pendingStrokesQueue.clear();
  }

  void broadcastTextBlockUpdate(LocalPage p, TextBlock b, {String? senderId, bool debounced = false, bool isEditing = false, bool isDeleted = false}) { 
    if (!isRealtimeActive || liveNotebookSid == null) return; 
    _realtimeService.broadcastTextBlock(notebookId: liveNotebookSid!, textData: { 'sender_id': senderId ?? myUserId, 'page_number': p.pageNumber, 'block': b.toJson(), 'is_editing': isEditing, 'is_deleted': isDeleted, });
  }

  void _broadcastSelectionMovement(LocalPage page, {bool isFinal = false}) { 
    if (!isRealtimeActive || liveNotebookSid == null) return; 
    if (selectedStrokeIds.isNotEmpty) {
      final List<Map<String, dynamic>> strokeBatch = [];
      for (var id in selectedStrokeIds) { 
        final s = page.strokes.firstWhere((s) => s.id == id);
        if (!isFinal) strokeBatch.add({'id': id, 'offset': {'x': _totalSelectionDelta.dx, 'y': _totalSelectionDelta.dy}});
        else strokeBatch.add({'id': id, 'color': s.color, 'thickness': s.thickness, 'is_final': true, 'points': s.points.map((pt) => {'x': pt.dx, 'y': pt.dy}).toList()});
      } 
      _realtimeService.broadcastStroke(notebookId: liveNotebookSid!, myUserId: myUserId, strokeData: {'page_number': page.pageNumber, 'is_move': true, 'strokes': strokeBatch});
    }
  }

  void handleLiveAudioAction() {
    if (!canSpeak) return;
    isRecording ? audioService.stopAndSendAudio(liveNotebookSid, myUserId) : audioService.startRecording(isLive: true, isLiveSessionActive: isCollaborationEnabled, liveNotebookSid: liveNotebookSid, myUserId: myUserId);
  }

  Future<void> undo(LocalPage p) async { 
    if (_undoStack.isEmpty) return; 
    final action = _undoStack.removeLast();
    final target = _getTargetPage(action.pageClientId);
    if (target != null) {
      action.undo(target); _redoStack.add(action);
      if (isRealtimeActive && liveNotebookSid != null) _realtimeService.broadcastGlobalAction(notebookId: liveNotebookSid!, actionData: {'sender_id': myUserId, 'type': 'sync_undo', 'action_type': action.type, 'data': action.toMap()});
      await _persistIncrementalAction(target, action); 
    }
    safeNotify();
  }

  Future<void> redo(LocalPage p) async { 
    if (_redoStack.isEmpty) return; 
    final action = _redoStack.removeLast();
    final target = _getTargetPage(action.pageClientId);
    if (target != null) {
      action.execute(target); _undoStack.add(action);
      if (isRealtimeActive && liveNotebookSid != null) _realtimeService.broadcastGlobalAction(notebookId: liveNotebookSid!, actionData: {'sender_id': myUserId, 'type': 'sync_redo', 'action_type': action.type, 'data': action.toMap()});
      await _persistIncrementalAction(target, action);
    }
    safeNotify();
  }

  Future<void> _performCollectiveSync() async {
    if (isGlobalSyncing) return;
    isGlobalSyncing = true; safeNotify();
    try {
      if (currentUserRole == 'owner' || currentUserRole == 'editor') await _syncService.pushPages(onlyNotebookId: currentNotebookId);
      await _syncService.pullPages(forceFull: true, onlyNotebookId: liveNotebookSid);
      pages = await _repository.getPagesByNotebook(currentNotebookId, liveNotebookSid);
    } finally { isGlobalSyncing = false; safeNotify(); }
  }

  Future<void> triggerAutoSave(LocalPage page) async { 
    page.syncedWithCloud = 0; 
    final int effectiveId = await _repository.savePage(page, liveNotebookSid); 
    if (page.id != effectiveId) {
      debugPrint('🆔 [Canvas] Página remapeada em memória: ${page.id} -> $effectiveId');
      page.id = effectiveId;
    }
    if (isRealtimeActive && liveNotebookSid != null) { 
      _autoSyncPushTimer?.cancel(); 
      _autoSyncPushTimer = Timer(const Duration(milliseconds: 800), () => _syncService.fastPushPage(page, liveNotebookSid!, myUserId));
    } 
  }

  Future<void> _handleRemoteAction(Map<String, dynamic> d) async {
    final action = CanvasAction.fromMap(d['action_type'] ?? d['type'], d['data']);
    if (action != null) {
      final tp = _getTargetPage(action.pageClientId);
      if (tp != null) { if (d['type'] == 'sync_undo') action.undo(tp); else action.execute(tp); tp.version++; safeNotify(); }
    }
  }

  Future<void> _handlePageEvent(Map<String, dynamic> d) async {
    if (d['action'] == 'add' || d['action'] == 'delete') await _performCollectiveSync();
  }

  Future<void> _handleFullStateRequest(Map<String, dynamic> d) async {
    final idx = pages.indexWhere((p) => p.pageNumber == d['page_number']);
    if (idx != -1) _realtimeService.deliverFullState(notebookId: liveNotebookSid!, targetUserId: d['sender_id'].toString(), pageData: pages[idx].toJson());
  }

  Future<void> _handleFullStateReceived(Map<String, dynamic> d) async {
    final Map<String, dynamic> pageData = d['page_data'];
    final idx = pages.indexWhere((p) => p.pageNumber == pageData['page_number']);
    if (idx != -1) { final np = LocalPage.fromJson(pageData); np.id = pages[idx].id; pages[idx] = np; await _repository.savePage(np, liveNotebookSid); safeNotify(); }
  }

  void _startSmoothTransition(Matrix4 target) {
    Timer.periodic(const Duration(milliseconds: 16), (t) {
      final current = transformationController.value;
      final next = Matrix4.identity();
      for (int i = 0; i < 16; i++) next.storage[i] = current.storage[i] + (target.storage[i] - current.storage[i]) * 0.04;
      transformationController.value = next; safeNotify();
      double diff = 0; for (int i = 0; i < 16; i++) diff += (next.storage[i] - target.storage[i]).abs();
      if (diff < 0.001) { transformationController.value = target; t.cancel(); safeNotify(); }
    });
  }

  Offset _totalSelectionDelta = Offset.zero;

  Future<void> pickAndInsertImage(LocalPage p) async {
    final pf = await ImagePicker().pickImage(source: ImageSource.gallery, imageQuality: 85);
    if (pf != null) {
      final appDir = await getApplicationDocumentsDirectory();
      final String path = '${appDir.path}/img_${DateTime.now().millisecondsSinceEpoch}';
      await io.File(pf.path).copy(path);
      final nib = ImageBlock(id: const Uuid().v4(), imagePath: path, position: const Offset(100, 150), width: 300.0, height: 200.0, creatorId: myUserId);
      await _executeAction(AddImageAction(pageClientId: p.clientId, pageNumber: p.pageNumber, block: nib));
    }
  }
  
  Future<int?> cloneNotebookToSubject(int targetSubjectId) async {
    final d = db.AppDatabase.instance;
    return await d.into(d.notebooks).insert(db.NotebooksCompanion.insert(subjectId: drift.Value(targetSubjectId), clientId: drift.Value(const Uuid().v4()), title: 'Cópia', coverType: 'color'));
  }

  void selectTextBlockAt(Offset localPosition, LocalPage page) {
    for (var tb in page.textBlocks) {
      if ((tb.position - localPosition).distance < 50.0) {
        selectedTextIds.add(tb.id);
        safeNotify();
        return;
      }
    }
  }

  void addTextBlock(LocalPage page, TextBlock newBlock) {
    _executeAction(AddTextAction(pageClientId: page.clientId, pageNumber: page.pageNumber, block: newBlock));
  }

  void setLineType(String t, LocalPage localPage) {
    localPage.lineType = t;
    _repository.savePage(localPage, liveNotebookSid);
    safeNotify();
  }

  void setThickness(double v) {
    selectedThickness = v;
    safeNotify();
  }

  void setColor(String s) {
    selectedColorHex = s;
    safeNotify();
  }

  void setTextColor(String hex) {
    if (activeTextBlock != null) {
      final old = activeTextBlock!.clone();
      activeTextBlock!.textColorHex = hex;
      recordTextUpdate(pages[currentPageIndex], old, activeTextBlock!);
    }
  }

  void savePageMetadata(LocalPage page) {
    _repository.savePage(page, liveNotebookSid);
    safeNotify();
  }

  void broadcastPageMetadataUpdate(LocalPage page, {bool isEditing = false}) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    _realtimeService.broadcastPageEvent(
      notebookId: liveNotebookSid!,
      myUserId: myUserId,
      pageData: {
        'action': 'metadata_update',
        'page_number': page.pageNumber,
        'title': page.title,
        'line_type': page.lineType,
        'is_editing': isEditing,
      },
    );
  }

  void deleteTextBlock(LocalPage page, TextBlock block) {
    block.isDeleted = true;
    _executeAction(DeleteAction(
      pageClientId: page.clientId,
      pageNumber: page.pageNumber,
      strokes: [],
      texts: [block.clone()],
      images: [],
    ));
    broadcastTextBlockUpdate(page, block, isDeleted: true);
  }

  void recordTextBlockUpdate(LocalPage page, TextBlock oldBlock, TextBlock newBlock) {
    recordTextUpdate(page, oldBlock, newBlock);
  }

  void saveTextBlock(LocalPage page, TextBlock block) {
    _repository.saveSingleTextBlock(page.clientId, block);
    safeNotify();
  }

  void broadcastThrottledTextBlockUpdate(LocalPage page, TextBlock block) {
    _textBroadcastDebounce?.cancel();
    _textBroadcastDebounce = Timer(const Duration(milliseconds: 50), () {
      broadcastTextBlockUpdate(page, block, debounced: true);
    });
  }

  void broadcastThrottledImageUpdate(LocalPage page, ImageBlock block) {
    if (!isRealtimeActive || liveNotebookSid == null) return;
    // Implementation for throttled image broadcast if needed
  }

  void bringImageToFront(LocalPage page, String imageId) {
    final idx = page.imageBlocks.indexWhere((img) => img.id == imageId);
    if (idx != -1) {
      final img = page.imageBlocks.removeAt(idx);
      page.imageBlocks.add(img);
      triggerAutoSave(page);
    }
  }

  Rect? getSelectionBounds(LocalPage page) {
    if (selectedStrokeIds.isEmpty && selectedTextIds.isEmpty && selectedImageIds.isEmpty) return null;
    // Calculate bounding box of selection
    return null; // Placeholder for now
  }

  void toggleTransformMode() {
    isTransformMode = !isTransformMode;
    safeNotify();
  }

  void smoothSelectedStroke(LocalPage page) {
    // Smooth stroke logic
  }

  void generateAiSummary(LocalPage page) {
    // AI summary logic
  }

  void toggleAuthorVisibility(String userId) {
    if (visibleAuthorIds == null) {
      visibleAuthorIds = {userId};
    } else if (visibleAuthorIds!.contains(userId)) {
      visibleAuthorIds!.remove(userId);
      if (visibleAuthorIds!.isEmpty) visibleAuthorIds = null;
    } else {
      visibleAuthorIds!.add(userId);
    }
    safeNotify();
  }

  void resetAuthorVisibility() {
    visibleAuthorIds = null;
    safeNotify();
  }

  Future<void> saveCopyOfNotebook(int targetSubjectId) async {
    await cloneNotebookToSubject(targetSubjectId);
  }

  void startEraserDrag(LocalPage page) {
    _activeEraserBatch = DeleteAction(
      pageClientId: page.clientId, 
      pageNumber: page.pageNumber,
      strokes: [],
      texts: [],
      images: [],
    );
  }

  void endEraserDrag(LocalPage page) {
    if (_activeEraserBatch != null && (_activeEraserBatch!.strokes.isNotEmpty || _activeEraserBatch!.texts.isNotEmpty || _activeEraserBatch!.images.isNotEmpty)) {
       _undoStack.add(_activeEraserBatch!);
       _redoStack.clear();
       triggerAutoSave(page);
    }
    _activeEraserBatch = null;
    safeNotify();
  }
  
  bool tryToggleChecklistAt(Offset localPosition, LocalPage page) {
    // Basic implementation for tool checking
    return false;
  }
  
  void updatePointerCount(int length) {
    _activePointerCount = length;
  }

  void zoom(double factor, Size screenSize) {
     final currentScale = transformationController.value.getMaxScaleOnAxis();
     final targetScale = (currentScale * factor).clamp(0.1, 6.0);
     final double effectiveFactor = targetScale / currentScale;
     
     final screenCenter = Offset(screenSize.width / 2, screenSize.height / 2);
     
     transformationController.value = Matrix4.identity()
      ..translate(screenCenter.dx, screenCenter.dy)
      ..scale(targetScale, targetScale, 1.0)
      ..translate(-screenCenter.dx / currentScale, -screenCenter.dy / currentScale);
     safeNotify();
  }
  
  void exportPageText(LocalPage page, BuildContext context) {
    String text = page.title + "\n\n";
    for (var tb in page.textBlocks) { if (!tb.isDeleted) text += tb.text + "\n"; }
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Texto copiado para a área de transferência!')));
  }

  void updateSelectionRect(LocalPage page, Offset localPos) {
    selectionRectEnd = localPos;
    if (selectionRectStart != null) {
      final rect = Rect.fromPoints(selectionRectStart!, selectionRectEnd!);
      selectedStrokeIds.clear();
      for (var s in page.strokes) {
        if (!s.isDeleted && s.points.any((pt) => rect.contains(pt))) selectedStrokeIds.add(s.id);
      }
      selectedTextIds.clear();
      for (var t in page.textBlocks) {
        if (!t.isDeleted && rect.contains(t.position)) selectedTextIds.add(t.id);
      }
    }
    safeNotify();
  }
}

final canvasProvider = ChangeNotifierProvider.autoDispose<CanvasController>((ref) {
  final realtime = ref.read(realtimeServiceProvider);
  final syncService = ref.read(appSyncServiceProvider);
  final repository = ref.read(canvasRepositoryProvider);
  final audioService = ref.read(audioSessionServiceProvider);
  final collabService = ref.read(collaborationRoomServiceProvider);
  return CanvasController(realtime, syncService, audioService, collabService, repository: repository);
});
