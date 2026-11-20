import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart'; // 🚀 Novo

import '../services/collaboration_room_service.dart';
import '../providers/audio_session_provider.dart';
import '../providers/canvas_ui_provider.dart';
import '../../canvas/services/audio_session_service.dart';
import '../../../core/network/realtime_service.dart';
import '../repositories/canvas_repository.dart';
import 'dialogs/chat_image_viewer_dialog.dart'; // 🚀 Novo

class CollaborationChatWidget extends ConsumerStatefulWidget {
  const CollaborationChatWidget({super.key});

  @override
  ConsumerState<CollaborationChatWidget> createState() =>
      _CollaborationChatWidgetState();
}

class _CollaborationChatWidgetState
    extends ConsumerState<CollaborationChatWidget> with SingleTickerProviderStateMixin {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  late TabController _tabController; // 🚀 Novo
  final ImagePicker _imagePicker = ImagePicker(); // 🚀 Novo
  Timer? _typingTimer; // 🚀 Debouncer para indicador de escrita

  @override
  void initState() {
      super.initState();
      _tabController = TabController(length: 2, vsync: this);
      _msgController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    final collabService = ref.read(collaborationRoomServiceProvider);
    if (!collabService.isCollaborationEnabled) return;

    if (_msgController.text.trim().isNotEmpty) {
      collabService.broadcastActivity('typing');
      _typingTimer?.cancel();
      _typingTimer = Timer(const Duration(seconds: 3), () {
        collabService.broadcastActivity('idle');
      });
    } else {
      _typingTimer?.cancel();
      collabService.broadcastActivity('idle');
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  void dispose() {
    _typingTimer?.cancel();
    _msgController.removeListener(_onTextChanged);
    _msgController.dispose();
    _scrollController.dispose();
    _tabController.dispose();
    super.dispose();
  }

  int _previousMessageCount = 0;

  @override
  Widget build(BuildContext context) {
    final collabService = ref.watch(collaborationRoomServiceProvider);
    final audioService = ref.watch(audioSessionProvider);
    final uiState = ref.watch(canvasUiProvider);

    if (!collabService.isCollaborationEnabled) return const SizedBox.shrink();

    // 🚀 AUTO-SCROLL apenas quando chegam mensagens novas
    if (collabService.chatMessages.length != _previousMessageCount) {
      _previousMessageCount = collabService.chatMessages.length;
      WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
    }

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;

    final double availableHeight = screenHeight - bottomInset;
    final chatHeight =
        (availableHeight - (bottomInset > 0 ? 80 : 160)).clamp(220.0, 440.0);

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: uiState.isHudMode ? 0.10 : 1.0,
      child: IgnorePointer(
        ignoring: uiState.isHudMode,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeInOut,
          width: collabService.isChatOpen ? 320 : 56,
          height: collabService.isChatOpen ? chatHeight : 56,
          decoration: BoxDecoration(
            color: collabService.isChatOpen
                ? Colors.white
                : const Color(0xFF0F4C5C),
            borderRadius: BorderRadius.circular(
              collabService.isChatOpen ? 18 : 28,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.20),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(
              collabService.isChatOpen ? 18 : 28,
            ),
            child: collabService.isChatOpen
                ? _buildFullChatWrapper(collabService, audioService, chatHeight)
                : _buildChatIcon(collabService),
          ),
        ),
      ),
    );
  }

  Widget _buildFullChatWrapper(
    CollaborationRoomService collabService,
    AudioSessionService audioService,
    double height,
  ) {
    return OverflowBox(
      minWidth: 320,
      maxWidth: 320,
      minHeight: height,
      maxHeight: height,
      alignment: Alignment.topLeft,
      child: _buildFullChat(collabService, audioService, height),
    );
  }

  Widget _buildChatIcon(CollaborationRoomService collabService) {
    final bool isConnecting =
        collabService.statusNotifier.value != RealtimeStatus.connected;

    return InkWell(
      onTap: () => collabService.isChatOpen = true,
      borderRadius: BorderRadius.circular(28),
      child: Center(
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.center,
          children: [
            if (isConnecting)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white70,
                ),
              )
            else
              const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 24,
              ),

            if (collabService.unreadChatCount > 0)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF0F4C5C),
                      width: 1.5,
                    ),
                  ),
                  constraints: const BoxConstraints(
                    minWidth: 18,
                    minHeight: 18,
                  ),
                  child: Text(
                    '${collabService.unreadChatCount}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullChat(
    CollaborationRoomService collabService,
    AudioSessionService audioService,
    double height,
  ) {
    return Column(
      children: [
        // 🚀 Header do Chat com Tabs
        Container(
          padding: const EdgeInsets.only(top: 8, left: 16, right: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF0F4C5C),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
                Row(
                  children: [
                    const Icon(
                      Icons.forum_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Comunicação',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${collabService.onlineUsers.length} online',
                        style: GoogleFonts.inter(
                          color: Colors.white70,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    IconButton(
                      onPressed: () => collabService.isChatOpen = false,
                      icon: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                TabBar(
                    controller: _tabController,
                    indicatorColor: Colors.white,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white54,
                    labelStyle: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold),
                    tabs: const [
                        Tab(text: '💬 MENSAGENS'),
                        Tab(text: '🎙️ RÁDIO ABERTA'),
                    ],
                ),
            ],
          ),
        ),

        // 🚀 Corpo do Chat ou Podcasting
        Expanded(
          child: TabBarView(
              controller: _tabController,
              children: [
                  _buildChatTab(collabService, audioService),
                  _buildPodcastTab(collabService, audioService),
              ],
          ),
        ),
      ],
    );
  }

  Widget _buildChatTab(CollaborationRoomService collabService, AudioSessionService audioService) {
      // 🚀 Marcar mensagens como lidas assim que a aba de chat renderizar
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Redundância segura
        if (!collabService.isChatOpen) {
           collabService.isChatOpen = true; 
        }
      });

      return Column(
          children: [
              Expanded(
                  child: Container(
                    color: const Color(0xFFF4F6F8),
                    child: collabService.chatMessages.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 40,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Nenhuma mensagem ainda.\nEnvie um texto ou nota de voz!',
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(12),
                    itemCount: collabService.chatMessages.length,
                    itemBuilder: (context, index) {
                      final msg = collabService.chatMessages[index];
                      final isMe =
                          msg['sender_id']?.toString() == collabService.myUserId;
                      final type = msg['type'] ?? 'text';

                      final sender = collabService.onlineUsers.firstWhere(
                        (u) => u['id'].toString() == msg['sender_id']?.toString(),
                        orElse: () => {
                          'name': isMe ? 'Você' : 'Colega',
                          'color': const Color(0xFF2980B9),
                        },
                      );

                      final String formattedTime = _formatMsgTime(
                        msg['timestamp'],
                      );

                      return Align(
                        alignment:
                            isMe ? Alignment.centerRight : Alignment.centerLeft,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          constraints: const BoxConstraints(maxWidth: 240),
                          decoration: BoxDecoration(
                            gradient: isMe
                                ? const LinearGradient(
                                    colors: [
                                      Color(0xFF0F4C5C),
                                      Color(0xFF1B4958),
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  )
                                : null,
                            color: isMe ? null : Colors.white,
                            borderRadius: BorderRadius.only(
                              topLeft: const Radius.circular(14),
                              topRight: const Radius.circular(14),
                              bottomLeft: Radius.circular(isMe ? 14 : 2),
                              bottomRight: Radius.circular(isMe ? 2 : 14),
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.04),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: isMe
                                ? CrossAxisAlignment.end
                                : CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (!isMe)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 4),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Container(
                                        width: 8,
                                        height: 8,
                                        decoration: BoxDecoration(
                                          color: (sender['color'] as Color?) ??
                                              const Color(0xFF2980B9),
                                          shape: BoxShape.circle,
                                        ),
                                      ),
                                      const SizedBox(width: 5),
                                      Flexible(
                                        child: Text(
                                          collabService.resolveSenderName(msg['sender_id'], msg['sender_name']),
                                          style: GoogleFonts.inter(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFF0F4C5C),
                                          ),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              if (type == 'text')
                                Text(
                                  msg['message'] ?? '',
                                  style: GoogleFonts.inter(
                                    fontSize: 12.5,
                                    color: isMe ? Colors.white : Colors.black87,
                                  ),
                                )
                              else if (type == 'image') // 🚀
                                GestureDetector(
                                    onTap: () {
                                        showDialog(
                                            context: context, 
                                            builder: (_) => ChatImageViewerDialog(imageUrl: msg['image_url'] ?? '')
                                        );
                                    },
                                    child: ClipRRect(
                                        borderRadius: BorderRadius.circular(8),
                                        child: CachedNetworkImage(
                                            imageUrl: msg['image_url'] ?? '',
                                            width: 180,
                                            fit: BoxFit.cover,
                                            placeholder: (context, url) => const SizedBox(width: 180, height: 180, child: Center(child: CircularProgressIndicator())),
                                            errorWidget: (context, url, error) => const Icon(Icons.broken_image, size: 50, color: Colors.grey),
                                        ),
                                    ),
                                )
                              else if (type == 'audio')
                                _AudioPlayerWidget(
                                  url: msg['audio_url'] ?? '',
                                  duration: (msg['duration'] as num?)?.toInt() ?? 0,
                                  isMe: isMe,
                                )
                              else if (type == 'audio_stream')
                                _StreamingAudioPlayerWidget(
                                  streamId: msg['msg_id']?.toString() ?? '',
                                  initialDuration: (msg['duration'] as num?)?.toInt() ?? 0,
                                  isMe: isMe,
                                ),
                              const SizedBox(height: 2),
                              Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    formattedTime,
                                    style: GoogleFonts.inter(
                                      fontSize: 8.5,
                                      color: isMe
                                          ? Colors.white60
                                          : Colors.black38,
                                    ),
                                  ),
                                  if (isMe) ...[
                                    const SizedBox(width: 4),
                                    _buildReadReceipts(
                                      msgId: msg['msg_id']?.toString() ?? '',
                                      collabService: collabService,
                                    ),
                                  ],
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ),

        // 🚀 Indicador Visual de Digitação ("✍️ Jetro está a escrever...")
        if (collabService.typingUserNames.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            color: const Color(0xFFF4F6F8),
            child: Row(
              children: [
                const _BlinkingDot(size: 6, color: Color(0xFF0F4C5C)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    _formatTypingText(collabService.typingUserNames),
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontStyle: FontStyle.italic,
                      color: const Color(0xFF0F4C5C),
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

        // 🚀 Indicador de Gravação de Áudio ou Input do Chat
        if (audioService.isRecording || audioService.isProcessingAudio)
          _RecordingIndicator(
            collabService: collabService,
            audioService: audioService,
          )
        else
          Container(
            constraints: const BoxConstraints(minHeight: 56, maxHeight: 130),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(
                top: BorderSide(color: Colors.grey.withOpacity(0.18)),
              ),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: Colors.transparent,
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () async {
                          final XFile? image = await _imagePicker.pickImage(source: ImageSource.gallery, imageQuality: 70);
                          if (image != null && collabService.liveNotebookSid != null) {
                              final bytes = await image.readAsBytes();
                              final repository = ref.read(canvasRepositoryProvider);
                              final url = await repository.uploadImage(collabService.liveNotebookSid!, image.name, bytes);
                              if (url != null) {
                                  collabService.sendImageMessage(url);
                              }
                          }
                      },
                      icon: const Icon(
                        Icons.image_outlined,
                        color: Colors.grey,
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      tooltip: 'Enviar imagem',
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: const Color(0xFF0F4C5C).withOpacity(0.08),
                    shape: const CircleBorder(),
                    child: IconButton(
                      onPressed: () => audioService.startRecording(
                        isLive: false,
                        isPodcast: false, // 🚀
                        liveNotebookSid: collabService.liveNotebookSid,
                        myUserId: collabService.myUserId,
                      ),
                      icon: const Icon(
                        Icons.mic_rounded,
                        color: Color(0xFF0F4C5C),
                        size: 20,
                      ),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(
                        minWidth: 34,
                        minHeight: 34,
                      ),
                      tooltip: 'Gravar nota de voz',
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    minLines: 1,
                    maxLines: 4,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    decoration: InputDecoration(
                      hintText: 'Escrever mensagem...',
                      hintStyle: GoogleFonts.inter(
                        fontSize: 12,
                        color: Colors.grey.shade400,
                      ),
                      border: InputBorder.none,
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    style: GoogleFonts.inter(fontSize: 12.5),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(bottom: 2),
                  child: Material(
                    color: const Color(0xFF0F4C5C),
                    borderRadius: BorderRadius.circular(20),
                    child: InkWell(
                      onTap: () => _sendMessage(collabService),
                      borderRadius: BorderRadius.circular(20),
                      child: const Padding(
                        padding: EdgeInsets.all(8.0),
                        child: Icon(
                          Icons.send_rounded,
                          color: Colors.white,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  // 🚀 NOVO MODO PODCASTING (RÁDIO ABERTA)
  Widget _buildPodcastTab(CollaborationRoomService collabService, AudioSessionService audioService) {
      final isOccupied = collabService.isPodcastChannelOccupied;
      final speakerName = collabService.activePodcastSpeakerName ?? 'Alguém';
      final isMeSpeaking = collabService.activePodcastSpeakerId == collabService.myUserId;
      final isListening = audioService.isAudioPlaying && audioService.currentlyPlayingAudioUrl != null;

      return Container(
          color: const Color(0xFFF4F6F8),
          child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                  Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                          color: isOccupied ? Colors.redAccent.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                              Icon(
                                  isOccupied ? Icons.sensors : Icons.sensors_off,
                                  color: isOccupied ? Colors.redAccent : Colors.green,
                                  size: 16,
                              ),
                              const SizedBox(width: 8),
                              Text(
                                  isOccupied 
                                    ? '🔴 $speakerName no ar...' 
                                    : '🟢 Canal Livre',
                                  style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      color: isOccupied ? Colors.redAccent : Colors.green,
                                      fontSize: 12,
                                  ),
                              )
                          ],
                      ),
                  ),
                  const SizedBox(height: 30),
                  
                  // Indicador visual de gravação ou escuta
                  if (audioService.isRecording && isMeSpeaking)
                      const _BlinkingDot(size: 80, color: Colors.redAccent)
                  else if (isListening && isOccupied && !isMeSpeaking)
                      const Icon(Icons.graphic_eq, size: 80, color: Colors.blueAccent)
                  else
                      Icon(Icons.podcasts, size: 80, color: Colors.grey.shade400),
                  
                  const SizedBox(height: 30),

                  GestureDetector(
                      onPanDown: (_) {
                          if (isOccupied && !isMeSpeaking) return;
                          collabService.acquirePodcastLock();
                          audioService.startRecording(
                              isLive: false,
                              isPodcast: true,
                              liveNotebookSid: collabService.liveNotebookSid,
                              myUserId: collabService.myUserId,
                          );
                      },
                      onPanEnd: (_) {
                          if (!isMeSpeaking) return;
                          collabService.releasePodcastLock();
                          audioService.stopAndSendAudio(
                              collabService.liveNotebookSid, 
                              collabService.myUserId
                          );
                      },
                      onPanCancel: () {
                          if (!isMeSpeaking) return;
                          collabService.releasePodcastLock();
                          audioService.stopAndSendAudio(
                              collabService.liveNotebookSid, 
                              collabService.myUserId
                          );
                      },
                      child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: 90,
                          height: 90,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: (isOccupied && !isMeSpeaking) 
                                ? Colors.grey 
                                : (isMeSpeaking ? Colors.redAccent : const Color(0xFF0F4C5C)),
                              boxShadow: isMeSpeaking ? [
                                  BoxShadow(
                                      color: Colors.redAccent.withOpacity(0.5),
                                      blurRadius: 20,
                                      spreadRadius: 5,
                                  )
                              ] : null,
                          ),
                          child: Icon(
                              isMeSpeaking ? Icons.mic : Icons.mic_none,
                              color: Colors.white,
                              size: 40,
                          ),
                      ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                      (isOccupied && !isMeSpeaking) 
                        ? 'Canal ocupado.\nAguarde a sua vez.'
                        : 'Mantenha pressionado\npara falar para todos',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                          fontSize: 12,
                          color: (isOccupied && !isMeSpeaking) ? Colors.redAccent : Colors.grey.shade600,
                          fontWeight: (isOccupied && !isMeSpeaking) ? FontWeight.bold : FontWeight.normal,
                      ),
                  ),
              ],
          ),
      );
  }

  void _sendMessage(CollaborationRoomService collabService) {
    final text = _msgController.text.trim();
    if (text.isEmpty) return;
    _typingTimer?.cancel();
    collabService.broadcastActivity('idle');
    collabService.sendMessage(text);
    _msgController.clear();
  }

  // 🚀 NOVO: Renderizar Vistos de Leitura (Read Receipts)
  Widget _buildReadReceipts({
    required String msgId,
    required CollaborationRoomService collabService,
  }) {
    if (msgId.isEmpty) return const SizedBox.shrink();

    // 1. Quem leu?
    final Set<String> readers = collabService.messageReads[msgId] ?? {};
    
    // Ignorar a própria leitura para contagem de terceiros
    final int readCount = readers.where((id) => id != collabService.myUserId).length;
    final int otherUsersCount = collabService.onlineUsers.length > 1 
                                ? (collabService.onlineUsers.length - 1) 
                                : 0;

    // Ainda ninguém leu (apenas entregue)
    if (readCount == 0) {
      return const Icon(Icons.check, size: 12, color: Colors.white70);
    }

    // Todos os que estão na sala viram
    final bool readByAll = (readCount >= otherUsersCount) && otherUsersCount > 0;
    final Color activeColor = readByAll ? const Color(0xFF2ECC71) : Colors.white70;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          Icons.done_all,
          size: 13,
          color: activeColor,
        ),
        if (!readByAll && readCount > 0) ...[
          const SizedBox(width: 2),
          Text(
            '$readCount',
            style: GoogleFonts.inter(
              fontSize: 8,
              fontWeight: FontWeight.bold,
              color: Colors.white70,
            ),
          ),
        ],
      ],
    );
  }

  String _formatTypingText(List<String> names) {
    if (names.isEmpty) return '';
    if (names.length == 1) return '✍️ ${names.first} está a escrever...';
    if (names.length == 2) return '✍️ ${names[0]} e ${names[1]} estão a escrever...';
    return '✍️ ${names.first} e mais ${names.length - 1} estão a escrever...';
  }

  String _formatMsgTime(dynamic rawTs) {
    if (rawTs == null) return '';
    try {
      final dt = DateTime.tryParse(rawTs.toString()) ??
          DateTime.fromMillisecondsSinceEpoch(
            int.tryParse(rawTs.toString()) ?? 0,
          );
      return DateFormat('HH:mm').format(dt.toLocal());
    } catch (_) {
      return '';
    }
  }
}

class _StreamingAudioPlayerWidget extends ConsumerWidget {
  final String streamId;
  final int initialDuration;
  final bool isMe;

  const _StreamingAudioPlayerWidget({
    required this.streamId,
    required this.initialDuration,
    required this.isMe,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioSessionProvider);
    final bool isPlaying = audioService.isStreamPlaying(streamId);
    final bool isFinal = audioService.isStreamFinalized(streamId);
    final int segmentCount = audioService.getStreamSegmentCount(streamId);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isFinal)
          Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.12),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BlinkingDot(),
                const SizedBox(width: 4),
                Text(
                  'EM DIRETO',
                  style: GoogleFonts.inter(
                    fontSize: 8,
                    fontWeight: FontWeight.w900,
                    color: Colors.redAccent,
                  ),
                ),
              ],
            ),
          ),
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
              onPressed: () => audioService.playAudioStream(streamId),
              icon: Icon(
                isPlaying
                    ? Icons.stop_circle_rounded
                    : Icons.play_circle_filled_rounded,
                color: isMe ? Colors.white : const Color(0xFF0F4C5C),
                size: 28,
              ),
            ),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFinal ? 'Voz gravada' : 'A explicar...',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.white70 : Colors.black87,
                  ),
                ),
                Text(
                  '${initialDuration}s • $segmentCount partes',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: isMe ? Colors.white60 : Colors.black45,
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}

class _BlinkingDot extends StatefulWidget {
  final double size; // 🚀
  final Color color; // 🚀

  const _BlinkingDot({
      this.size = 6.0,
      this.color = Colors.redAccent,
  });

  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _controller,
      child: Container(
        width: widget.size,
        height: widget.size,
        decoration: BoxDecoration(
          color: widget.color,
          shape: BoxShape.circle,
        ),
      ),
    );
  }
}

class _RecordingIndicator extends StatelessWidget {
  final CollaborationRoomService collabService;
  final AudioSessionService audioService;

  const _RecordingIndicator({
    required this.collabService,
    required this.audioService,
  });

  @override
  Widget build(BuildContext context) {
    final bool isProcessing = audioService.isProcessingAudio;

    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      color: isProcessing
          ? const Color(0xFF0F4C5C).withOpacity(0.08)
          : Colors.red.withOpacity(0.06),
      child: Row(
        children: [
          if (isProcessing)
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF0F4C5C),
              ),
            )
          else
            const _BlinkingDot(),
          const SizedBox(width: 8),
          Expanded(
            child: isProcessing
                ? Text(
                    'A PROCESSAR ÁUDIO...',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0F4C5C),
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  )
                : StreamBuilder(
                    stream: Stream.periodic(const Duration(seconds: 1)),
                    builder: (context, snapshot) {
                      final dur = audioService.recordingDuration;
                      final String formatted =
                          '${dur.inMinutes.toString().padLeft(2, '0')}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}';
                      return Text(
                        'GRAVANDO... $formatted',
                        style: GoogleFonts.inter(
                          color: Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      );
                    },
                  ),
          ),
          if (!isProcessing) ...[
            IconButton(
              onPressed: () => audioService.cancelRecording(),
              icon: const Icon(
                Icons.delete_outline_rounded,
                color: Colors.redAccent,
                size: 20,
              ),
              tooltip: 'Cancelar Gravação',
            ),
            const SizedBox(width: 4),
            ElevatedButton.icon(
              onPressed: () => audioService.stopAndSendAudio(
                collabService.liveNotebookSid,
                collabService.myUserId,
              ),
              icon: const Icon(Icons.send_rounded, size: 14),
              label: const Text(
                'ENVIAR',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 10),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C5C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: const Size(60, 32),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AudioPlayerWidget extends ConsumerStatefulWidget {
  final String url;
  final int duration;
  final bool isMe;

  const _AudioPlayerWidget({
    required this.url,
    required this.duration,
    required this.isMe,
  });

  @override
  ConsumerState<_AudioPlayerWidget> createState() => _AudioPlayerWidgetState();
}

class _AudioPlayerWidgetState extends ConsumerState<_AudioPlayerWidget> {
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    final audioService = ref.watch(audioSessionProvider);
    final bool isPlaying = audioService.currentlyPlayingAudioUrl == widget.url;
    final double progress = isPlaying ? audioService.audioPlaybackProgress : 0.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment:
          widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading && !isPlaying)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.blueAccent,
                ),
              )
            else
              IconButton(
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () async {
                  if (isPlaying) {
                    await audioService.playAudioMessage(widget.url);
                    return;
                  }

                  setState(() => _isLoading = true);
                  try {
                    await audioService.playAudioMessage(widget.url);
                    if (mounted) setState(() => _isLoading = false);
                  } catch (e) {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                icon: Icon(
                  isPlaying
                      ? Icons.pause_circle_filled_rounded
                      : Icons.play_circle_filled_rounded,
                  color: widget.isMe ? Colors.white : const Color(0xFF0F4C5C),
                  size: 30,
                ),
              ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nota de voz',
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: widget.isMe ? Colors.white70 : Colors.black87,
                  ),
                ),
                Text(
                  '${widget.duration}s',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    color: widget.isMe ? Colors.white60 : Colors.black45,
                  ),
                ),
              ],
            ),
          ],
        ),
        if (isPlaying || (progress > 0 && progress < 1))
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor:
                    widget.isMe ? Colors.white24 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isMe ? Colors.white : const Color(0xFF2ECC71),
                ),
                minHeight: 2.5,
              ),
            ),
          ),
      ],
    );
  }
}
