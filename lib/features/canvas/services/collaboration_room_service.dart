import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/core/network/api_service.dart';
import 'package:caderno_digital_app/core/network/sync_service.dart';
import 'package:caderno_digital_app/core/network/sync_provider.dart';
import 'package:caderno_digital_app/core/network/api_provider.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/models/stroke_model.dart';
import 'package:caderno_digital_app/features/canvas/models/text_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/image_block_model.dart';

/// Service responsible for managing collaboration, presence, and real-time interaction
/// in a notebook room. It extracts logic from CanvasController to keep it clean.
class CollaborationRoomService extends ChangeNotifier {
  final RealtimeService _realtimeService;
  final ApiService _apiService;
  final SyncService _syncService;
  final CanvasRepository _repository;

  CollaborationRoomService(
    this._realtimeService,
    this._apiService,
    this._syncService,
    this._repository,
  );

  bool _isDisposed = false;
  String? _myUserId;
  int? _liveNotebookSid;
  String? _currentUserRole;
  int? _localNotebookId;

  // -------------------------------------------------------------------------
  // 🛡️ [STATE] PRESENCE & CURSORS
  // -------------------------------------------------------------------------
  final ValueNotifier<Map<String, dynamic>> remotePointers = ValueNotifier({});
  final ValueNotifier<Map<String, Stroke>> remoteLiveStrokes = ValueNotifier({});
  final Set<String> usersInLiveSession = {};
  Map<String, double> userAudioLevels = {};
  List<Map<String, dynamic>> onlineUsers = [];
  Map<String, String?> userReactions = {};
  final Set<String> whoIsWatchingMe = {};
  final Set<String> remoteUploadingUsers = {};
  final Set<String> tearingPageClientIds = {};
  final Set<String> remoteMovingStrokeIds = {};
  final Map<String, DateTime> _lastRemoteStrokeUpdate = {};
  final Map<String, Color> userColorsMap = {};
  final List<Color> avatarColorsPool = [
    const Color(0xFFE67E22), const Color(0xFF9B59B6), const Color(0xFF27AE60),
    const Color(0xFF2980B9), const Color(0xFFE74C3C), const Color(0xFF1ABC9C)
  ];
  
  // -------------------------------------------------------------------------
  // 🛡️ [STATE] SESSION POLICIES
  // -------------------------------------------------------------------------
  bool isCollaborationEnabled = false;
  bool isGlobalSyncing = false;
  String currentTemplateType = 'study';

  bool isSessionLocked = false;
  bool isAuthorColorEnabled = false;
  String sessionVoiceMode = 'open';
  bool _isVoiceAuthorized = true;
  bool get isVoiceAuthorized => _isVoiceAuthorized;
  List<Map<String, dynamic>> enrolledMembers = [];
  String? authorityId;
  String? sessionTitle;
  Set<int>? authorizedPageIds;

  ValueNotifier<RealtimeStatus> get statusNotifier => _realtimeService.statusNotifier;
  int? get liveNotebookSid => _liveNotebookSid;
  String get myUserId => _myUserId ?? '';
  String get currentUserRole => _currentUserRole ?? 'viewer';
  bool get isSyncing => isGlobalSyncing; // Alias for UI consistency

  // -------------------------------------------------------------------------
  // 🛡️ [STATE] CHAT & COMUNICAÇÃO
  // -------------------------------------------------------------------------
  final List<Map<String, dynamic>> chatMessages = [];
  int unreadChatCount = 0;
  bool _isChatOpen = false;
  bool get isChatOpen => _isChatOpen;
  set isChatOpen(bool value) {
    _isChatOpen = value;
    if (value) unreadChatCount = 0;
    notifyListeners();
  }

  // -------------------------------------------------------------------------
  // 🛡️ [STATE] LIVE INTERACTION
  // -------------------------------------------------------------------------
  bool isMyHandRaised = false;
  String? followingUserId;
  bool isBroadcastingViewport = false;
  Offset? currentViewportCenter;
  double? currentVisibleWidth;
  Size? lastScreenSize;
  Offset? _lastSentViewportCenter;
  
  final Map<int, String> remoteEditingTitles = {};
  final Set<String> _deniedActionKeys = {};
  Map<String, dynamic>? incomingVoiceCall;
  bool isConnectingVoice = false;
  bool isLiveSessionActive = false;
  bool get isRemoteVoiceCallActive => incomingVoiceCall != null;
  
  // -------------------------------------------------------------------------
  // 🚀 [CALLBACKS] PARA MODIFICAÇÃO DE PÁGINAS & NAVEGAÇÃO
  // -------------------------------------------------------------------------
  List<LocalPage> Function()? getPages;
  int Function()? getCurrentPageIndex;
  double Function()? getCurrentScale;

  Future<void> Function(Map<String, dynamic> data)? onStrokeReceived;
  Future<void> Function(Map<String, dynamic> data)? onTextReceived;
  Future<void> Function(Map<String, dynamic> data)? onImageReceived;
  Future<void> Function(Map<String, dynamic> data)? onPageEvent;
  void Function(Map<String, dynamic> data)? onExecuteAction;
  Future<void> Function()? onSyncRequested;
  Future<void> Function(Map<String, dynamic> data)? onFullStateRequested;
  Future<void> Function(Map<String, dynamic> data)? onFullStateReceived;
  Future<void> Function(Map<String, dynamic> data)? onFingerprintReceived;
  Future<void> Function(Map<String, dynamic> data)? onCloudSyncSignal;
  void Function()? onNotebookDeleted;
  void Function()? onAccessRevoked;
  Future<void> Function(Map<String, dynamic> data)? onNotebookStructureUpdated;
  void Function(Matrix4 matrix)? onSmoothTransition;
  void Function(int index)? onPageNavigationRequested;
  void Function()? onAutoNavigateAfterDeletion;

  // -------------------------------------------------------------------------
  // 🚀 [STREAMS] ALERTAS E EVENTOS
  // -------------------------------------------------------------------------
  final StreamController<Map<String, dynamic>> _newMessageAlertController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onNewMessageAlert => _newMessageAlertController.stream;

  final StreamController<String> _permissionAlertController = StreamController.broadcast();
  Stream<String> get onPermissionAlert => _permissionAlertController.stream;

  final StreamController<void> _notebookDeletedByOwnerController = StreamController.broadcast();
  Stream<void> get onNotebookDeletedByOwner => _notebookDeletedByOwnerController.stream;

  final StreamController<Map<String, dynamic>> _sessionMetaStreamController = StreamController.broadcast();
  Stream<Map<String, dynamic>> get onSessionMetaReceived => _sessionMetaStreamController.stream;

  // -------------------------------------------------------------------------
  // 🕒 [INTERNOS] TIMERS & SUBSCRIPTIONS
  // -------------------------------------------------------------------------
  
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
  StreamSubscription? _fingerprintSubscription;
  StreamSubscription? _globalActionSubscription;
  StreamSubscription? _followSubscription;
  StreamSubscription? _pageEventSubscription;
  StreamSubscription? _pageUpdatedSubscription;
  StreamSubscription? _pageDeletedSubscription;
  StreamSubscription? _notebookDeletedSubscription;
  StreamSubscription? _accessRevokedSubscription;
  StreamSubscription? _handSubscription;
  StreamSubscription? _uploadingSubscription;
  StreamSubscription? _voiceCallSubscription;
  StreamSubscription? _voiceStateSubscription;
  StreamSubscription? _roleUpdateSubscription;
  StreamSubscription? _audioLevelSubscription;
  StreamSubscription? _sessionMetaSubscription;
  StreamSubscription? _notebookStructureSubscription;
  StreamSubscription? _voicePolicySubscription;
  StreamSubscription? _cloudSyncSignalSubscription;

  final Map<String, Timer> _reactionTimers = {};
  final Map<String, Timer> _broadcasterTimers = {};
  final Map<String, Timer> _editingTimers = {};
  final Map<int, DateTime> _lastFullStateRequestTime = {};
  Timer? _viewportBroadcastTimer;
  Timer? _fingerprintTimer;
  Timer? _cleanupTimer;
  Timer? _backgroundSyncTimer;
  Timer? _roomSyncDebouncer;
  VoidCallback? _statusListener;

  // -------------------------------------------------------------------------
  // 🚀 [MÉTODOS PÚBLICOS] INICIALIZAÇÃO & CICLO DE VIDA
  // -------------------------------------------------------------------------
  
  Future<void> init(
    int liveNotebookSid,
    String myUserId,
    String currentUserRole, {
    List<int>? pageIds,
    String? alternativeTitle,
    String? sharingType,
  }) async {
    _liveNotebookSid = liveNotebookSid;
    _myUserId = myUserId;
    _currentUserRole = currentUserRole;

    await _realtimeService.initConnection();

    if (_statusListener != null) {
      _realtimeService.statusNotifier.removeListener(_statusListener!);
    }

    _statusListener = () {
      if (!_isDisposed && _realtimeService.isConnected) {
        fetchSessionStatus(pageIds: pageIds, alternativeTitle: alternativeTitle, sharingType: sharingType);
        _debounceRoomSync();
        _startHeartbeat();
        _startCleanupTimer();
        _startBackgroundSync();

        if (_currentUserRole == 'owner') {
          _realtimeService.broadcastSessionMeta(
            notebookId: _liveNotebookSid!,
            metaData: {
              'is_locked': isSessionLocked,
              'is_colors_enabled': isAuthorColorEnabled,
            },
          );
        }
      }
    };

    _realtimeService.statusNotifier.addListener(_statusListener!);

    if (_realtimeService.isConnected) {
      _statusListener!();
    }

    _setupSubscriptions();
  }

  Future<void> toggleCollaboration(bool enable, {
    int? localId,
    int? remoteId,
    String? userId,
    String? role,
    bool suppressBroadcast = false,
    List<int>? pageIds,
    String? alternativeTitle,
    String? sharingType,
  }) async {
    if (isCollaborationEnabled == enable) return;

    if (enable) {
      isGlobalSyncing = true;
      notifyListeners();
      try {
        await _syncService.pushNotebooks();
        // Se tivermos os IDs, fazemos o push das páginas do caderno atual
        final targetLocalId = localId ?? _localNotebookId;
        final targetRemoteId = remoteId ?? _liveNotebookSid;
        if (targetRemoteId != null && targetRemoteId != 0 && targetLocalId != null) {
          await _syncService.pushPages(onlyNotebookId: targetLocalId);
        }
      } finally {
        isGlobalSyncing = false;
        notifyListeners();
      }

      isCollaborationEnabled = true;
      SyncService.isCollaborationActive = true;

      final targetRemoteId = remoteId ?? _liveNotebookSid;
      final targetUserId = userId ?? _myUserId;
      final targetRole = role ?? _currentUserRole ?? 'viewer';

      if (targetRemoteId != null && targetRemoteId != 0 && targetUserId != null) {
        _localNotebookId = localId ?? _localNotebookId;
        await init(targetRemoteId, targetUserId, targetRole,
            pageIds: pageIds, alternativeTitle: alternativeTitle, sharingType: sharingType);
        
        if (!suppressBroadcast) {
          _realtimeService.broadcastLiveInvite(
            notebookId: targetRemoteId,
            myUserId: targetUserId,
            senderName: "Um colega",
            targetUserIds: [],
          );
        }
      }
    } else {
      isCollaborationEnabled = false;
      SyncService.isCollaborationActive = false;
      isLiveSessionActive = false;
      _realtimeService.disconnect();
    }
    notifyListeners();
  }

  void _setupSubscriptions() {
    final rt = _realtimeService;
    final notebookId = _liveNotebookSid!;

    _usersSubscription?.cancel();
    _usersSubscription = rt.onUsersUpdated.listen((ul) {
      if (_isDisposed) return;
      final prevCount = onlineUsers.length;
      onlineUsers = _mapUserList(ul.toList());
      
      if (onlineUsers.length > prevCount && (_currentUserRole == 'owner' || _currentUserRole == 'editor')) {
         final pages = getPages?.call() ?? [];
         final currentIndex = getCurrentPageIndex?.call() ?? 0;
         if (pages.isNotEmpty && currentIndex < pages.length) {
            final cp = pages[currentIndex];
            rt.broadcastPageFingerprint(
              notebookId: notebookId,
              myUserId: _myUserId!,
              pageNumber: cp.pageNumber,
              fingerprint: cp.generateFingerprint(),
              updatedAt: cp.updatedAt,
            );
         }
      }
      notifyListeners();
    });

    _sessionMetaSubscription?.cancel();
    _sessionMetaSubscription = rt.onSessionMetaReceived.listen((d) {
      if (_isDisposed) return;
      if (d['is_locked'] != null) isSessionLocked = d['is_locked'] == true;
      if (d['is_colors_enabled'] != null) isAuthorColorEnabled = d['is_colors_enabled'] == true;
      if (d['voice_mode'] != null) sessionVoiceMode = d['voice_mode'];
      _sessionMetaStreamController.add(d);
      notifyListeners();
    });

    _voicePolicySubscription?.cancel();
    _voicePolicySubscription = rt.onVoicePolicyUpdated.listen((d) {
      if (_isDisposed || d['notebook_id'] != notebookId) return;
      if (d['voice_mode'] != null) sessionVoiceMode = d['voice_mode'];

      if (d['target_id']?.toString() == _myUserId) {
        final bool canISpeakNow = d['can_speak'] == true;
        if (canISpeakNow != _isVoiceAuthorized) {
          _permissionAlertController.add(canISpeakNow 
            ? 'O professor deu-te a palavra. Podes falar!' 
            : 'O teu microfone foi desativado pelo professor.');
        }
        _isVoiceAuthorized = canISpeakNow;
      }

      if (d['target_id'] != null && enrolledMembers.isNotEmpty) {
        final idx = enrolledMembers.indexWhere((m) => m['id'].toString() == d['target_id'].toString());
        if (idx != -1) enrolledMembers[idx]['can_speak'] = d['can_speak'];
      }
      notifyListeners();
    });

    _roleUpdateSubscription?.cancel();
    _roleUpdateSubscription = rt.onRoleUpdateReceived.listen((d) {
      if (_isDisposed) return;
      final String targetId = d['target_id'].toString();
      final String newRole = d['role'].toString();

      if (targetId == _myUserId) {
        _currentUserRole = newRole;
      }

      final idx = onlineUsers.indexWhere((u) => u['id'].toString() == targetId);
      if (idx != -1) {
        onlineUsers[idx]['role'] = newRole;
      }
      notifyListeners();
    });

    _voiceCallSubscription?.cancel();
    _voiceCallSubscription = rt.onVoiceCallStarted.listen((d) {
      if (_isDisposed || isLiveSessionActive) return;
      final String? senderId = d['sender_id']?.toString() ?? d['senderId']?.toString();
      if (senderId == _myUserId || senderId == null) return;
      if (_deniedActionKeys.contains('voice_call_$senderId')) return;
      incomingVoiceCall = d;
      notifyListeners();
    });

    _voiceStateSubscription?.cancel();
    _voiceStateSubscription = rt.onVoiceStateReceived.listen((d) {
      if (_isDisposed) return;
      final String uid = d['sender_id'].toString();
      if (uid == _myUserId) return;
      
      final bool isInCall = d['is_in_call'] == true;
      final bool isTalking = d['is_talking'] == true;
      final double level = (d['audio_level'] as num?)?.toDouble() ?? 0.0;
      
      if (isInCall) usersInLiveSession.add(uid); else usersInLiveSession.remove(uid);
      userAudioLevels[uid] = isTalking ? level : 0.0;
      
      final userIdx = onlineUsers.indexWhere((u) => u['id'].toString() == uid);
      if (userIdx != -1) {
        onlineUsers[userIdx]['isTalking'] = isTalking;
        onlineUsers[userIdx]['isInCall'] = isInCall;
      }
      notifyListeners();
    });

    _strokesSubscription?.cancel();
    _strokesSubscription = rt.onStrokeReceived.listen((d) async {
      if (_isDisposed || d['sender_id']?.toString() == _myUserId) return;
      
      final pages = getPages?.call() ?? [];
      if (pages.isEmpty) return;

      final String? pcid = d['page_client_id']?.toString();
      final int ipn = d['page_number'] ?? 0;

      int idx = -1;
      if (pcid != null) idx = pages.indexWhere((p) => p.clientId == pcid);
      if (idx == -1 && ipn > 0) idx = pages.indexWhere((p) => p.pageNumber == ipn);
      
      if (idx == -1) return;
      final tp = pages[idx];

      if (tp.id == null) await _repository.savePage(tp, notebookId);

      bool hasChanges = false;
      final curM = Map<String, Stroke>.from(remoteLiveStrokes.value);
      final bool isMove = d['is_move'] == true;

      for (var sm in d['strokes']) {
        final sid = sm['id'];
        
        if (sm['is_deleted'] == true) {
          final exI = tp.strokes.indexWhere((s) => s.id == sid);
          if (exI != -1) {
            tp.strokes[exI].isDeleted = true;
            tp.strokes[exI].updatedAt = sm['updated_at'] ?? TimeService().nowMs();
            hasChanges = true;
          }
          _repository.deleteSingleStroke(sid);
          continue;
        }

        if (sm['is_final'] != true) {
          if (isMove) remoteMovingStrokeIds.add(sid);
          _lastRemoteStrokeUpdate[sid] = DateTime.now();

          if (sm['offset'] != null) {
            final off = Offset((sm['offset']['x'] as num).toDouble(), (sm['offset']['y'] as num).toDouble());
            final baseS = tp.strokes.firstWhere((s) => s.id == sid, orElse: () => Stroke(color: '#000000', thickness: 1, points: []));
            curM[sid] = Stroke(
              id: sid, color: baseS.color, thickness: baseS.thickness, 
              points: baseS.points, 
              pageNumber: ipn
            )..liveOffset = off;
          } else {
            final pts = (sm['points'] as List).map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble())).toList();
            final exS = curM[sid];
            if (exS != null && !isMove) {
              curM[sid] = Stroke(id: sid, color: exS.color, thickness: exS.thickness, points: List<Offset>.from(exS.points)..addAll(pts), pageNumber: ipn);
            } else {
              curM[sid] = Stroke(id: sid, color: sm['color'], thickness: (sm['thickness'] as num).toDouble(), points: List.from(pts), pageNumber: ipn);
            }

            final String? senderId = d['sender_id']?.toString();
            if (pts.isNotEmpty && followingUserId != null && senderId == followingUserId && lastScreenSize != null) {
              final lastPt = pts.last;
              final screenCenter = Offset(lastScreenSize!.width / 2, lastScreenSize!.height / 2);
              final double currentScale = getCurrentScale?.call() ?? 1.0;
              final targetMatrix = Matrix4.translationValues(screenCenter.dx, screenCenter.dy, 0.0)
                ..scale(currentScale, currentScale, 1.0)
                ..translate(-lastPt.dx, -lastPt.dy, 0.0);
              onSmoothTransition?.call(targetMatrix);
            }
          }
          hasChanges = true;
        } else {
          final int remoteTs = sm['updated_at'] ?? DateTime.now().millisecondsSinceEpoch;
          final pts = (sm['points'] as List).map((p) => Offset((p['x'] as num).toDouble(), (p['y'] as num).toDouble())).toList();
          final ns = Stroke(id: sid, color: sm['color'], thickness: (sm['thickness'] as num).toDouble(), points: pts, pageNumber: ipn, updatedAt: remoteTs);

          final exI = tp.strokes.indexWhere((s) => s.id == sid);
          if (exI != -1 && tp.strokes[exI].updatedAt > remoteTs) {
             curM.remove(sid);
             remoteMovingStrokeIds.remove(sid);
             hasChanges = true;
             continue;
          }

          curM.remove(sid);
          remoteMovingStrokeIds.remove(sid);
          tp.strokes.removeWhere((s) => s.id == sid);
          tp.strokes.add(ns);
          tp.updatedAt = remoteTs;
          hasChanges = true;
          _repository.saveSingleStroke(tp.clientId, ns);
        }
      }

      if (hasChanges) {
        remoteLiveStrokes.value = curM;
        if (!isMove) tp.version++;
        notifyListeners();
      }
      if (onStrokeReceived != null) await onStrokeReceived!(d);
    });

    _textSubscription?.cancel();
    _textSubscription = rt.onTextReceived.listen((d) async {
      if (_isDisposed || d['sender_id']?.toString() == _myUserId) return;
      
      final pages = getPages?.call() ?? [];
      final String? pcid = d['page_client_id']?.toString();
      final int ipn = d['page_number'] ?? 0;

      int idx = -1;
      if (pcid != null) idx = pages.indexWhere((p) => p.clientId == pcid);
      if (idx == -1) idx = pages.indexWhere((p) => p.pageNumber == ipn);
      if (idx == -1) return;

      final tp = pages[idx];
      if (tp.id == null) await _repository.savePage(tp, notebookId);

      final bd = d['block'];
      final bid = bd['id'];
      
      if (d['is_deleted'] == true) {
        tp.textBlocks.removeWhere((t) => t.id == bid);
      } else {
        final int remoteTs = bd['updated_at'] ?? TimeService().nowMs();
        final exI = tp.textBlocks.indexWhere((t) => t.id == bid);
        if (exI != -1 && tp.textBlocks[exI].updatedAt > remoteTs) return;

        final nb = TextBlock.fromJson(bd);
        if (exI != -1) tp.textBlocks[exI] = nb; else tp.textBlocks.add(nb);
      }
      
      tp.version++;
      notifyListeners();
      await _repository.savePage(tp, notebookId);
      if (onTextReceived != null) await onTextReceived!(d);
    });

    _imageSubscription?.cancel();
    _imageSubscription = rt.onImageReceived.listen((d) async {
      if (_isDisposed || d['sender_id']?.toString() == _myUserId) return;
      
      final pages = getPages?.call() ?? [];
      final String? pcid = d['page_client_id']?.toString();
      final int ipn = d['page_number'] ?? 0;

      int idx = -1;
      if (pcid != null) idx = pages.indexWhere((p) => p.clientId == pcid);
      if (idx == -1) idx = pages.indexWhere((p) => p.pageNumber == ipn);
      if (idx == -1) return;

      final tp = pages[idx];
      if (tp.id == null) await _repository.savePage(tp, notebookId);

      final bd = d['block'];
      final bid = bd['id'];
      
      if (d['is_deleted'] == true) {
        tp.imageBlocks.removeWhere((i) => i.id == bid);
      } else {
        final int remoteTs = bd['updated_at'] ?? TimeService().nowMs();
        final exI = tp.imageBlocks.indexWhere((i) => i.id == bid);
        if (exI != -1 && tp.imageBlocks[exI].updatedAt > remoteTs) return;

        final nib = ImageBlock.fromJson(bd);
        if (exI != -1) tp.imageBlocks[exI] = nib; else tp.imageBlocks.add(nib);
      }
      
      tp.version++;
      notifyListeners();
      await _repository.savePage(tp, notebookId);
      if (onImageReceived != null) await onImageReceived!(d);
    });

    _collectiveSyncSubscription?.cancel();
    _collectiveSyncSubscription = rt.onCollectiveSyncRequested.listen((d) {
      if (!_isDisposed && d['sender_id'].toString() != _myUserId) {
        if (onSyncRequested != null) onSyncRequested!();
      }
    });

    _fullStateRequestSubscription?.cancel();
    _fullStateRequestSubscription = rt.onFullStateRequested.listen((d) async {
      if (_isDisposed) return;
      if (onFullStateRequested != null) await onFullStateRequested!(d);
    });

    _fullStateReceivedSubscription?.cancel();
    _fullStateReceivedSubscription = rt.onFullStateReceived.listen((d) async {
      if (_isDisposed || d['target_id'].toString() != _myUserId) return;
      if (onFullStateReceived != null) await onFullStateReceived!(d);
    });

    _fingerprintSubscription?.cancel();
    _fingerprintSubscription = rt.onPageFingerprintReceived.listen((d) {
      if (_isDisposed || d['sender_id'].toString() == _myUserId) return;
      
      final int pNum = d['page_number'];
      final String remoteFingerprint = d['fingerprint'];
      final int remoteTs = d['updated_at'] ?? 0;
      final String senderId = d['sender_id'].toString();
      
      final pages = getPages?.call() ?? [];
      final idx = pages.indexWhere((p) => p.pageNumber == pNum);
      if (idx != -1) {
        final localFingerprint = pages[idx].generateFingerprint();
        if (localFingerprint != remoteFingerprint) {
          final now = DateTime.now();
          final lastReq = _lastFullStateRequestTime[pNum];

          if (lastReq == null || now.difference(lastReq).inSeconds > 20) {
             bool shouldSync = (senderId == authorityId) || (remoteTs > pages[idx].updatedAt);
             if (shouldSync) {
               _lastFullStateRequestTime[pNum] = now;
               rt.requestFullState(notebookId: notebookId, targetUserId: senderId, pageNumber: pNum);
               
               Future.delayed(const Duration(seconds: 2), () async {
                 if (!_isDisposed) {
                   await _syncService.pullSpecificPage(notebookId, pNum);
                   if (onSyncRequested != null) onSyncRequested!();
                 }
               });
             }
          }
        }
      }
      if (onFingerprintReceived != null) onFingerprintReceived!(d);
    });

    _cloudSyncSignalSubscription?.cancel();
    _cloudSyncSignalSubscription = rt.onCloudSyncSignalReceived.listen((d) async {
      if (_isDisposed || d['sender_id'].toString() == _myUserId) return;
      if (onCloudSyncSignal != null) await onCloudSyncSignal!(d);
    });

    _globalActionSubscription?.cancel();
    _globalActionSubscription = rt.onGlobalActionReceived.listen((d) {
      if (_isDisposed || d['sender_id'].toString() == _myUserId) return;
      if (onExecuteAction != null) onExecuteAction!(d);
    });

    _activitySubscription?.cancel();
    _activitySubscription = rt.onUserActivityReceived.listen((d) {
      rt.updateUserActivityState(d['sender_id'].toString(), d['activity'].toString());
    });

    _pointerSubscription?.cancel();
    _pointerSubscription = rt.onPointerMoveReceived.listen((d) {
      if (_isDisposed) return;
      final uid = d['sender_id'].toString();
      if (uid == _myUserId) return;
      
      final cur = Map<String, dynamic>.from(remotePointers.value);
      cur[uid] = {
        'pos': Offset((d['x'] as num).toDouble(), (d['y'] as num).toDouble()),
        'page_number': d['page_number'],
        'tool': d['tool'],
        'role': onlineUsers.firstWhere((u) => u['id'].toString() == uid, orElse: () => {})['role'] ?? 'student'
      };
      remotePointers.value = cur;
    });

    _chatSubscription?.cancel();
    _chatSubscription = rt.onChatMessageReceived.listen((d) => _addChatMessage(d));

    _audioMessageSubscription?.cancel();
    _audioMessageSubscription = rt.onAudioMessageReceived.listen((d) {
      if (_isDisposed) return;
      final bool isLive = d['is_live'] == true || d['type'] == 'audio_stream';
      if (isLive && d['sender_id'] != _myUserId) {
        // Handled by controller/audio service via RT service directly
      } else {
        _addChatMessage(d);
      }
    });

    _reactionSubscription?.cancel();
    _reactionSubscription = rt.onReactionReceived.listen((d) {
      if (_isDisposed) return;
      final uid = d['sender_id'].toString();
      userReactions[uid] = d['reaction'].toString();
      _reactionTimers[uid]?.cancel();
      _reactionTimers[uid] = Timer(const Duration(seconds: 5), () {
        userReactions[uid] = null;
        notifyListeners();
      });
      notifyListeners();
    });

    _handSubscription?.cancel();
    _handSubscription = rt.onHandEventReceived.listen((d) {
      if (_isDisposed) return;
      final uid = d['sender_id'].toString();
      rt.updateUserHandState(uid, d['is_raised'] == true);
    });

    _uploadingSubscription?.cancel();
    _uploadingSubscription = rt.onRemoteUploading.listen((d) {
      if (_isDisposed) return;
      final uid = d['sender_id'].toString();
      if (d['is_uploading'] == true) remoteUploadingUsers.add(uid);
      else remoteUploadingUsers.remove(uid);
      notifyListeners();
    });

    _pageEventSubscription?.cancel();
    _pageEventSubscription = rt.onPageEventReceived.listen((d) async {
      if (_isDisposed || d['sender_id']?.toString() == _myUserId) return;
      if (onPageEvent != null) await onPageEvent!(d);
    });

    _pageUpdatedSubscription?.cancel();
    _pageUpdatedSubscription = rt.onPageUpdated.listen((d) async {
      if (_isDisposed || d['notebook_id'] != notebookId) return;
      if (onSyncRequested != null) await onSyncRequested!();
    });

    _notebookDeletedSubscription?.cancel();
    _notebookDeletedSubscription = rt.onNotebookDeleted.listen((d) {
      if (_isDisposed) return;
      _notebookDeletedByOwnerController.add(null);
      if (onNotebookDeleted != null) onNotebookDeleted!();
    });

    _accessRevokedSubscription?.cancel();
    _accessRevokedSubscription = rt.onNotebookAccessRevoked.listen((d) {
      if (_isDisposed || d['server_id'] != notebookId) return;
      _notebookDeletedByOwnerController.add(null);
      if (onAccessRevoked != null) onAccessRevoked!();
    });

    _notebookStructureSubscription?.cancel();
    _notebookStructureSubscription = rt.onNotebookStructureUpdated.listen((d) async {
      if (_isDisposed || d['notebook_id'] != notebookId) return;
      sessionTitle = d['alternative_title']?.toString();
      
      if (d['authorized_page_ids'] != null) {
        authorizedPageIds = Set<int>.from((d['authorized_page_ids'] as List).map((id) => int.parse(id.toString())));
      } else {
        authorizedPageIds = null;
      }

      if (onNotebookStructureUpdated != null) await onNotebookStructureUpdated!(d);
      notifyListeners();
    });

    _viewportSubscription?.cancel();
    _viewportSubscription = rt.onViewportReceived.listen((d) {
      if (_isDisposed || d['sender_id'].toString() == _myUserId) return;
      final String uid = d['sender_id'].toString();
      
      if (uid == followingUserId) {
         if (d['page_number'] != null) {
            final currentIndex = getCurrentPageIndex?.call() ?? 0;
            if (currentIndex + 1 != d['page_number']) {
              onPageNavigationRequested?.call(d['page_number'] - 1);
            }
         }

         if (lastScreenSize != null && (d['visibleWidth'] as num).toDouble() > 0) {
            final screenCenter = Offset(lastScreenSize!.width / 2, lastScreenSize!.height / 2);
            final double scale = (lastScreenSize!.width / (d['visibleWidth'] as num).toDouble()).clamp(0.8, 3.5);
            
            final targetMatrix = Matrix4.translationValues(screenCenter.dx, screenCenter.dy, 0.0)
              ..scale(scale, scale, 1.0)
              ..translate(-(d['focusX'] as num).toDouble(), -(d['focusY'] as num).toDouble(), 0.0);
            
            onSmoothTransition?.call(targetMatrix);
         }
      }
      _markUserBroadcasting(uid);
    });
  }

  // -------------------------------------------------------------------------
  // 🚀 [MÉTODOS DE AÇÃO]
  // -------------------------------------------------------------------------

  Future<void> fetchSessionStatus({List<int>? pageIds, String? alternativeTitle, String? sharingType}) async {
    if (_liveNotebookSid == null) return;
    try {
      final response = await _apiService.post('/notebooks/$_liveNotebookSid/session/join', {
        if (pageIds != null) 'page_ids': pageIds,
        if (alternativeTitle != null) 'alternative_title': alternativeTitle,
        if (sharingType != null) 'sharing_type': sharingType,
      });
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['active'] == true) {
          authorityId = data['authority_id']?.toString();
          sessionTitle = data['alternative_title']?.toString();
          sessionVoiceMode = data['voice_mode'] ?? 'open';
          _isVoiceAuthorized = data['can_speak'] == true;
          
          if (data['authorized_page_ids'] != null) {
            authorizedPageIds = Set<int>.from((data['authorized_page_ids'] as List).map((id) => int.parse(id.toString())));
          }

          if (data['pages_summary'] != null) {
            await _syncSmartByFingerprint(data['pages_summary']);
          }

          notifyListeners();
        }
      }
    } catch (e) {
      debugPrint('🚨 [Collaboration] Erro ao buscar status: $e');
    }
  }

  Future<void> _syncSmartByFingerprint(List summary) async {
    final pages = getPages?.call() ?? [];
    if (pages.isEmpty && summary.isNotEmpty) {
      await _syncService.pullPages(forceFull: true, onlyNotebookId: _liveNotebookSid);
      if (onSyncRequested != null) await onSyncRequested!();
      return;
    }

    final List<int> dirtyPageNumbers = [];
    final int currentPageNumber = pages.isNotEmpty ? pages[getCurrentPageIndex?.call() ?? 0].pageNumber : -1;

    for (var item in summary) {
      final int pNum = item['page_number'];
      final String remoteFingerprint = item['fingerprint'];
      final int remoteTs = item['updated_at_ms'] ?? 0;
      final dynamic hData = item['header_data'];
      final dynamic fData = item['footer_data'];

      final idx = pages.indexWhere((p) => p.pageNumber == pNum);
      if (idx != -1) {
        final p = pages[idx];
        
        bool metaChanged = false;
        if (hData != null) {
          final String newTitle = LocalPage.parseMeta(hData);
          if (p.title != newTitle) { p.title = newTitle; metaChanged = true; }
        }
        if (fData != null) {
          final String newFooter = LocalPage.parseMeta(fData);
          if (p.footer != newFooter) { p.footer = newFooter; metaChanged = true; }
        }

        if (metaChanged) {
           await _repository.savePage(p, _liveNotebookSid);
        }

        final localFingerprint = p.generateFingerprint();
        if (localFingerprint != remoteFingerprint) {
          if (remoteTs > p.updatedAt || _currentUserRole != 'owner') {
            dirtyPageNumbers.add(pNum);
          }
        }
      } else {
        dirtyPageNumbers.add(pNum);
      }
    }

    if (dirtyPageNumbers.isEmpty) return;

    if (currentPageNumber != -1 && dirtyPageNumbers.contains(currentPageNumber)) {
      await _syncService.pullSpecificPage(_liveNotebookSid!, currentPageNumber);
      dirtyPageNumbers.remove(currentPageNumber);
    }

    if (dirtyPageNumbers.isNotEmpty) {
      for (var pNum in dirtyPageNumbers) {
        await _syncService.pullSpecificPage(_liveNotebookSid!, pNum);
      }
    }
    
    if (onSyncRequested != null) await onSyncRequested!();
  }

  void _addChatMessage(Map<String, dynamic> d) {
    final String? id = d['msg_id']?.toString();
    if (id != null && chatMessages.any((m) => m['msg_id'] == id)) return;
    chatMessages.add(d);
    if (chatMessages.length > 50) chatMessages.removeAt(0);
    if (!_isChatOpen && d['sender_id'] != _myUserId) {
      unreadChatCount++;
      _newMessageAlertController.add(d);
    }
    notifyListeners();
  }

  void sendMessage(String m) {
    if (_isDisposed || _liveNotebookSid == null || _myUserId == null) return;
    final msg = {
      'type': 'text',
      'sender_id': _myUserId,
      'message': m,
      'msg_id': TimeService().nowMs().toString(),
      'timestamp': TimeService().now().toIso8601String()
    };
    _addChatMessage(msg);
    _realtimeService.broadcastChatMessage(notebookId: _liveNotebookSid!, myUserId: _myUserId!, message: m);
  }

  void broadcastPointer(Offset pos, int pageNumber, String tool) {
    if (_isDisposed || _liveNotebookSid == null || _myUserId == null) return;
    _realtimeService.broadcastPointerMove(
      notebookId: _liveNotebookSid!,
      myUserId: _myUserId!,
      pos: pos,
      pageNumber: pageNumber,
      tool: tool,
    );
  }

  void broadcastPageEvent(String action, Map<String, dynamic> data) {
    if (_isDisposed || _liveNotebookSid == null || _myUserId == null) return;
    _realtimeService.broadcastPageEvent(
      notebookId: _liveNotebookSid!,
      myUserId: _myUserId!,
      pageData: {'action': action, ...data},
    );
  }

  void toggleHandRaise() {
    if (_isDisposed || _myUserId == null || _liveNotebookSid == null) return;
    isMyHandRaised = !isMyHandRaised;
    notifyListeners();
    _realtimeService.broadcastHandEvent(notebookId: _liveNotebookSid!, myUserId: _myUserId!, isRaised: isMyHandRaised);
    _realtimeService.updateUserHandState(_myUserId!, isMyHandRaised);
  }

  void sendReaction(String emoji) {
    if (_isDisposed || _myUserId == null || _liveNotebookSid == null) return;
    userReactions[_myUserId!] = emoji;
    _reactionTimers[_myUserId!]?.cancel();
    _reactionTimers[_myUserId!] = Timer(const Duration(seconds: 5), () {
      if (!_isDisposed) {
        userReactions[_myUserId!] = null;
        notifyListeners();
      }
    });
    _realtimeService.broadcastReaction(notebookId: _liveNotebookSid!, myUserId: _myUserId!, reaction: emoji);
    notifyListeners();
  }

  void toggleFollowUser(String? uid) {
    if (_isDisposed || uid == _myUserId) return;
    followingUserId = (followingUserId == uid) ? null : uid;
    if (_liveNotebookSid != null && _myUserId != null) {
      _realtimeService.broadcastFollowUpdate(notebookId: _liveNotebookSid!, myUserId: _myUserId!, followingUserId: followingUserId);
    }
    notifyListeners();
  }

  void startViewportBroadcasting() {
    if (_isDisposed || isBroadcastingViewport) return;
    isBroadcastingViewport = true;
    notifyListeners();
    _viewportBroadcastTimer = Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (_isDisposed || !isBroadcastingViewport || _liveNotebookSid == null || _myUserId == null) {
        t.cancel();
        return;
      }
      if (currentViewportCenter != null) {
        final d = _lastSentViewportCenter == null ? 999 : (currentViewportCenter! - _lastSentViewportCenter!).distance;
        if (d > 3.0) {
          _realtimeService.broadcastViewport(
            notebookId: _liveNotebookSid!,
            viewportData: {
              'page_number': (getCurrentPageIndex?.call() ?? 0) + 1,
              'focusX': currentViewportCenter!.dx,
              'focusY': currentViewportCenter!.dy,
              'visibleWidth': currentVisibleWidth ?? 600.0,
            },
            myUserId: _myUserId!,
          );
          _lastSentViewportCenter = currentViewportCenter;
        }
      }
    });
  }

  void stopViewportBroadcasting() {
    isBroadcastingViewport = false;
    _viewportBroadcastTimer?.cancel();
    _viewportBroadcastTimer = null;
    if (!_isDisposed) notifyListeners();
  }

  void toggleVoiceCall(String userId) {
    if (_isDisposed) return;
    if (isLiveSessionActive) {
      _realtimeService.stopVoiceCall(notebookId: _liveNotebookSid!, myUserId: _myUserId!);
      isLiveSessionActive = false;
    } else {
      _realtimeService.startVoiceCall(notebookId: _liveNotebookSid!, myUserId: _myUserId!);
      isLiveSessionActive = true;
    }
    notifyListeners();
  }

  void acceptVoiceCall() {
    if (_isDisposed || incomingVoiceCall == null) return;
    _realtimeService.startVoiceCall(notebookId: _liveNotebookSid!, myUserId: _myUserId!);
    isLiveSessionActive = true;
    incomingVoiceCall = null;
    notifyListeners();
  }

  void dismissVoiceCall() {
    incomingVoiceCall = null;
    if (!_isDisposed) notifyListeners();
  }

  Future<void> toggleParticipantVoice(String userId, bool enabled) async {
    if (_isDisposed || (_currentUserRole != 'owner' && _currentUserRole != 'editor')) return;
    try {
      await _apiService.post('/notebooks/$_liveNotebookSid/session/update-permission', {
        'target_id': userId,
        'can_speak': enabled
      });
      _realtimeService.broadcastVoicePolicy(notebookId: _liveNotebookSid!, targetId: userId, canSpeak: enabled);
    } catch (e) {
      debugPrint('🚨 [Collaboration] Erro ao atualizar voz do participante: $e');
    }
  }

  Future<void> fetchEnrolledMembers() async {
    if (_isDisposed || _liveNotebookSid == null) return;
    try {
      final response = await _apiService.get('/notebooks/$_liveNotebookSid/members');
      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        enrolledMembers = data.map((m) => Map<String, dynamic>.from(m)).toList();
        notifyListeners();
      }
    } catch (e) {
      debugPrint('🚨 [Collaboration] Erro ao buscar membros inscritos: $e');
    }
  }

  void updateUserRoleLocally(String userId, String role) {
    if (_isDisposed) return;
    final idx = onlineUsers.indexWhere((u) => u['id'].toString() == userId);
    if (idx != -1) {
      onlineUsers[idx]['role'] = role;
    }
    // Também atualizar no enrolledMembers se estiver lá
    final enrolledIdx = enrolledMembers.indexWhere((m) => m['id'].toString() == userId);
    if (enrolledIdx != -1) {
      enrolledMembers[enrolledIdx]['role'] = role;
    }
    notifyListeners();
  }

  void toggleSessionLock() {
    if (_isDisposed || _currentUserRole != 'owner') return;
    isSessionLocked = !isSessionLocked;
    _broadcastSessionPolicies();
    notifyListeners();
  }

  void toggleAuthorColors() {
    if (_isDisposed || _currentUserRole != 'owner') return;
    isAuthorColorEnabled = !isAuthorColorEnabled;
    _broadcastSessionPolicies();
    notifyListeners();
  }

  Future<void> setVoiceMode(String mode) async {
    if (_isDisposed || (_currentUserRole != 'owner' && _currentUserRole != 'editor')) return;
    sessionVoiceMode = mode;
    notifyListeners();
    try {
      await _apiService.post('/notebooks/$_liveNotebookSid/session/update-settings', {'voice_mode': mode});
      _broadcastSessionPolicies();
    } catch (e) {
      debugPrint('🚨 [Collaboration] Erro ao atualizar modo de voz: $e');
    }
  }

  void _broadcastSessionPolicies() {
    if (_liveNotebookSid != null) {
      _realtimeService.broadcastSessionMeta(
        notebookId: _liveNotebookSid!,
        metaData: {
          'is_locked': isSessionLocked,
          'is_colors_enabled': isAuthorColorEnabled,
          'voice_mode': sessionVoiceMode,
        },
      );
    }
  }

  void _markUserBroadcasting(String userId) {
    _broadcasterTimers[userId]?.cancel();
    _broadcasterTimers[userId] = Timer(const Duration(seconds: 4), () {
      _broadcasterTimers.remove(userId);
      notifyListeners();
    });
    notifyListeners();
  }

  Set<String> get activeBroadcasters => _broadcasterTimers.keys.toSet();

  List<Map<String, dynamic>> _mapUserList(List<dynamic> rawList) {
    return rawList.map((u) {
      final m = Map<String, dynamic>.from(u as Map);
      final String uid = m['id'].toString();
      final bool userInCall = m['isInCall'] == true || usersInLiveSession.contains(uid);
      if (userInCall) usersInLiveSession.add(uid);
      
      String role = m['role'] ?? 'student';
      if (uid == _myUserId) role = _currentUserRole ?? 'student';

      return {
        'id': uid, 
        'name': m['name'] ?? 'Colega', 
        'email': m['email'] ?? '',
        'color': avatarColorsPool[(int.tryParse(uid) ?? 0) % avatarColorsPool.length], 
        'isTalking': m['isTalking'] ?? false, 
        'activity': m['activity'] ?? 'idle', 
        'isHandRaised': m['isHandRaised'] ?? false, 
        'isInCall': userInCall, 
        'role': role,
      }; 
    }).toList();
  }

  // -------------------------------------------------------------------------
  // 🕒 [INTERNOS] AUXILIARES
  // -------------------------------------------------------------------------

  void _debounceRoomSync() {
    _roomSyncDebouncer?.cancel();
    _roomSyncDebouncer = Timer(const Duration(milliseconds: 500), () {
      if (_myUserId != null) _realtimeService.requestCollectiveSync(myUserId: _myUserId!);
    });
  }

  void _startHeartbeat() {
    if (_currentUserRole != 'owner') return;
    _fingerprintTimer?.cancel();
    _fingerprintTimer = Timer.periodic(const Duration(seconds: 15), (timer) {
      if (_isDisposed || _liveNotebookSid == null || _myUserId == null) return;
      
      final pages = getPages?.call() ?? [];
      final currentIndex = getCurrentPageIndex?.call() ?? 0;
      
      if (pages.isNotEmpty && currentIndex < pages.length) {
        final currentPage = pages[currentIndex];
        _realtimeService.broadcastPageFingerprint(
          notebookId: _liveNotebookSid!,
          myUserId: _myUserId!,
          pageNumber: currentPage.pageNumber,
          fingerprint: currentPage.generateFingerprint(),
          updatedAt: currentPage.updatedAt,
        );
      }
    });
  }

  void _startCleanupTimer() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 5), (timer) {
      if (_isDisposed) return;
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
          notifyListeners();
        }
      }
    });
  }

  void _startBackgroundSync() {
    _backgroundSyncTimer?.cancel();
    _backgroundSyncTimer = Timer.periodic(const Duration(minutes: 2), (timer) async {
      if (_isDisposed || _liveNotebookSid == null) return;
      await _syncService.pushPages(onlyNotebookId: _liveNotebookSid!);
      await _syncService.pushRecordings();
      notifyListeners();
    });
  }

  void leaveSession() {
    _realtimeService.statusNotifier.removeListener(_statusListener!);
    dispose();
  }

  @override
  void dispose() {
    _isDisposed = true;
    _viewportBroadcastTimer?.cancel();
    _fingerprintTimer?.cancel();
    _cleanupTimer?.cancel();
    _backgroundSyncTimer?.cancel();
    _roomSyncDebouncer?.cancel();
    
    for (var t in _reactionTimers.values) t.cancel();
    for (var t in _broadcasterTimers.values) t.cancel();
    for (var t in _editingTimers.values) t.cancel();
    
    _usersSubscription?.cancel();
    _strokesSubscription?.cancel();
    _textSubscription?.cancel();
    _imageSubscription?.cancel();
    _viewportSubscription?.cancel();
    _activitySubscription?.cancel();
    _pointerSubscription?.cancel();
    _chatSubscription?.cancel();
    _audioMessageSubscription?.cancel();
    _reactionSubscription?.cancel();
    _collectiveSyncSubscription?.cancel();
    _fullStateRequestSubscription?.cancel();
    _fullStateReceivedSubscription?.cancel();
    _fingerprintSubscription?.cancel();
    _globalActionSubscription?.cancel();
    _followSubscription?.cancel();
    _pageEventSubscription?.cancel();
    _pageUpdatedSubscription?.cancel();
    _pageDeletedSubscription?.cancel();
    _notebookDeletedSubscription?.cancel();
    _accessRevokedSubscription?.cancel();
    _handSubscription?.cancel();
    _uploadingSubscription?.cancel();
    _voiceCallSubscription?.cancel();
    _voiceStateSubscription?.cancel();
    _roleUpdateSubscription?.cancel();
    _audioLevelSubscription?.cancel();
    _sessionMetaSubscription?.cancel();
    _notebookStructureSubscription?.cancel();
    _voicePolicySubscription?.cancel();
    _cloudSyncSignalSubscription?.cancel();
    
    _newMessageAlertController.close();
    _permissionAlertController.close();
    _notebookDeletedByOwnerController.close();
    _sessionMetaStreamController.close();
    
    if (_statusListener != null) {
      _realtimeService.statusNotifier.removeListener(_statusListener!);
    }
    
    super.dispose();
  }
}

final collaborationRoomServiceProvider = ChangeNotifierProvider.autoDispose<CollaborationRoomService>((ref) {
  final realtime = ref.read(realtimeServiceProvider);
  final api = ref.read(apiServiceProvider); // Assuming apiServiceProvider exists
  final sync = ref.read(appSyncServiceProvider);
  final repository = ref.read(canvasRepositoryProvider);
  return CollaborationRoomService(realtime, api, sync, repository);
});
