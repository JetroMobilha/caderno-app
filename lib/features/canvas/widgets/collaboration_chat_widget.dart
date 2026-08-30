import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/collaboration_provider.dart';
import '../providers/audio_session_provider.dart';
import '../../canvas/services/audio_session_service.dart';
import '../../canvas/services/collaboration_room_service.dart';
import '../../../core/network/realtime_service.dart';
import 'dart:async';

class CollaborationChatWidget extends ConsumerStatefulWidget {
  const CollaborationChatWidget({super.key});

  @override
  ConsumerState<CollaborationChatWidget> createState() => _CollaborationChatWidgetState();
}

class _CollaborationChatWidgetState extends ConsumerState<CollaborationChatWidget> {
  final TextEditingController _msgController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
    _msgController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collabService = ref.watch(collaborationProvider);
    final audioService = ref.watch(audioSessionProvider);
    
    if (!collabService.isCollaborationEnabled) return const SizedBox.shrink();

    // 🚀 AUTO-SCROLL quando chegam novas mensagens
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    
    final double availableHeight = screenHeight - bottomInset;
    final chatHeight = (availableHeight - (bottomInset > 0 ? 80 : 160)).clamp(200.0, 420.0);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: collabService.isChatOpen ? 300 : 56,
      height: collabService.isChatOpen ? chatHeight : 56,
      decoration: BoxDecoration(
        color: collabService.isChatOpen ? Colors.white : const Color(0xFF0F4C5C),
        borderRadius: BorderRadius.circular(collabService.isChatOpen ? 16 : 28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(collabService.isChatOpen ? 16 : 28),
        child: collabService.isChatOpen 
            ? _buildFullChatWrapper(collabService, audioService, chatHeight) 
            : _buildChatIcon(collabService),
      ),
    );
  }

  // 🚀 WRAPPER PARA EVITAR OVERFLOW
  Widget _buildFullChatWrapper(CollaborationRoomService collabService, AudioSessionService audioService, double height) {
    return OverflowBox(
      minWidth: 300, maxWidth: 300,
      minHeight: height, maxHeight: height,
      alignment: Alignment.topLeft,
      child: _buildFullChat(collabService, audioService, height),
    );
  }

  Widget _buildChatIcon(CollaborationRoomService collabService) {
    final bool isConnecting = collabService.statusNotifier.value != RealtimeStatus.connected;

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
                width: 24, height: 24,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70),
              )
            else
              const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 26),
            
            if (collabService.unreadChatCount > 0)
              Positioned(
                top: -2,
                right: -2,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.redAccent, 
                    shape: BoxShape.circle,
                    border: Border.all(color: const Color(0xFF0F4C5C), width: 1.5),
                  ),
                  constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                  child: Text(
                    '${collabService.unreadChatCount}',
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFullChat(CollaborationRoomService collabService, AudioSessionService audioService, double height) {
    return Column(
      children: [
        // Header
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: Color(0xFF0F4C5C),
          ),
          child: Row(
            children: [
              const Icon(Icons.forum_rounded, color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Chat de Colaboração',
                  style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                onPressed: () => collabService.isChatOpen = false,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, color: Colors.white, size: 22),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
        ),

        Expanded(
          child: Container(
            color: const Color(0xFFF8F9FA),
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(12),
              itemCount: collabService.chatMessages.length,
              itemBuilder: (context, index) {
                final msg = collabService.chatMessages[index];
                final isMe = msg['sender_id'] == collabService.myUserId;
                final type = msg['type'] ?? 'text';
                
                final sender = collabService.onlineUsers.firstWhere(
                  (u) => u['id'].toString() == msg['sender_id'],
                  orElse: () => {'name': 'Colega'},
                );

                return Align(
                  alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: BoxDecoration(
                      color: isMe ? const Color(0xFF0F4C5C) : Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(isMe ? 14 : 0),
                        bottomRight: Radius.circular(isMe ? 0 : 14),
                      ),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (!isMe)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text(
                              sender['name'],
                              style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF0F4C5C)),
                            ),
                          ),
                        if (type == 'text')
                          Text(
                            msg['message'] ?? '',
                            style: GoogleFonts.inter(fontSize: 13, color: isMe ? Colors.white : Colors.black87),
                          )
                        else if (type == 'audio')
                          _AudioPlayerWidget(
                            url: msg['audio_url'],
                            duration: msg['duration'],
                            isMe: isMe,
                          )
                        else if (type == 'audio_stream')
                          _StreamingAudioPlayerWidget(
                            streamId: msg['msg_id'],
                            initialDuration: msg['duration'],
                            isMe: isMe,
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        if (audioService.isRecording)
          _RecordingIndicator(collabService: collabService, audioService: audioService)
        else
          Container(
            height: 60,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.withOpacity(0.2))),
            ),
            child: Row(
              children: [
                Material(
                  color: const Color(0xFF0F4C5C).withOpacity(0.1),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => audioService.startRecording(
                      isLive: false,
                      liveNotebookSid: collabService.liveNotebookSid,
                      myUserId: collabService.myUserId,
                    ),
                    icon: const Icon(Icons.mic_rounded, color: Color(0xFF0F4C5C), size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: TextField(
                    controller: _msgController,
                    decoration: InputDecoration(
                      hintText: 'Escrever...',
                      hintStyle: GoogleFonts.inter(fontSize: 12, color: Colors.grey),
                      border: InputBorder.none,
                      isDense: true,
                    ),
                    style: GoogleFonts.inter(fontSize: 13),
                    onSubmitted: (val) => _sendMessage(collabService),
                  ),
                ),
                IconButton(
                  onPressed: () => _sendMessage(collabService),
                  icon: const Icon(Icons.send_rounded, color: Color(0xFF0F4C5C), size: 20),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                ),
              ],
            ),
          ),
      ],
    );
  }

  void _sendMessage(CollaborationRoomService collabService) {
    if (_msgController.text.trim().isEmpty) return;
    collabService.sendMessage(_msgController.text.trim());
    _msgController.clear();
  }
}

class _StreamingAudioPlayerWidget extends ConsumerWidget {
  final String streamId;
  final int initialDuration;
  final bool isMe;
  const _StreamingAudioPlayerWidget({required this.streamId, required this.initialDuration, required this.isMe});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final audioService = ref.watch(audioSessionProvider);
    final bool isPlaying = audioService.isStreamPlaying(streamId);
    final bool isFinal = audioService.isStreamFinalized(streamId);
    final int segmentCount = audioService.getStreamSegmentCount(streamId);
    
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        if (!isFinal)
          Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.redAccent.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const _BlinkingDot(),
                const SizedBox(width: 4),
                Text(
                  'EM DIRECTO',
                  style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w900, color: Colors.redAccent),
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
                isPlaying ? Icons.stop_circle_rounded : Icons.play_circle_filled_rounded, 
                color: isMe ? Colors.white : const Color(0xFF0F4C5C),
                size: 32,
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isFinal ? 'Voz gravada' : 'A explicar...',
                  style: GoogleFonts.inter(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold,
                    color: isMe ? Colors.white70 : Colors.black54
                  ),
                ),
                Text(
                  '${initialDuration}s • $segmentCount partes',
                  style: GoogleFonts.inter(
                    fontSize: 10, 
                    color: isMe ? Colors.white60 : Colors.black38
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
  const _BlinkingDot();
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
  }
  @override
  void dispose() { _controller.dispose(); super.dispose(); }
  @override
  Widget build(BuildContext context) {
    return FadeTransition(opacity: _controller, child: Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle)));
  }
}

class _RecordingIndicator extends StatelessWidget {
  final CollaborationRoomService collabService;
  final AudioSessionService audioService;
  const _RecordingIndicator({required this.collabService, required this.audioService});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(12),
      color: Colors.red.withOpacity(0.05),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                final dur = audioService.recordingDuration;
                return Text(
                  'GRAVANDO... ${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () => audioService.stopAndSendAudio(collabService.liveNotebookSid, collabService.myUserId),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C5C),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              minimumSize: const Size(60, 32),
            ),
            child: const Text('ENVIAR', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11)),
          ),
        ],
      ),
    );
  }
}

class _AudioPlayerWidget extends ConsumerStatefulWidget {
  final String url;
  final int duration;
  final bool isMe;
  const _AudioPlayerWidget({required this.url, required this.duration, required this.isMe});

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
      crossAxisAlignment: widget.isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_isLoading && !isPlaying)
              const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.blueAccent),
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
                  isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, 
                  color: widget.isMe ? Colors.white : const Color(0xFF0F4C5C),
                  size: 32,
                ),
              ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Mensagem de voz',
                  style: GoogleFonts.inter(
                    fontSize: 10, 
                    fontWeight: FontWeight.bold,
                    color: widget.isMe ? Colors.white70 : Colors.black54
                  ),
                ),
                Text(
                  '${widget.duration}s',
                  style: GoogleFonts.inter(
                    fontSize: 10, 
                    color: widget.isMe ? Colors.white60 : Colors.black38
                  ),
                ),
              ],
            ),
          ],
        ),
        if (isPlaying || (progress > 0 && progress < 1))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
              width: 120,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: widget.isMe ? Colors.white24 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isMe ? Colors.white : const Color(0xFF2ECC71),
                ),
                minHeight: 2,
              ),
            ),
          ),
      ],
    );
  }
}
