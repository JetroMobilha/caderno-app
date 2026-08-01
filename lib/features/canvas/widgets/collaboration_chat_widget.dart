import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/canvas_controller.dart';
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
    final controller = ref.watch(canvasProvider);
    if (!controller.isCollaborationEnabled) return const SizedBox.shrink();

    // 🚀 AUTO-SCROLL quando chegam novas mensagens
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      width: controller.isChatOpen ? 300 : 56,
      height: controller.isChatOpen ? 450 : 56,
      decoration: BoxDecoration(
        color: controller.isChatOpen ? Colors.white : const Color(0xFF0F4C5C),
        borderRadius: BorderRadius.circular(controller.isChatOpen ? 16 : 28),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(controller.isChatOpen ? 16 : 28),
        child: controller.isChatOpen 
            ? _buildFullChatWrapper(controller) 
            : _buildChatIcon(controller),
      ),
    );
  }

  // 🚀 WRAPPER PARA EVITAR OVERFLOW: Garante que o chat "pensa" que tem o tamanho final
  // mesmo durante a animação de crescimento do container pai.
  Widget _buildFullChatWrapper(CanvasController controller) {
    return OverflowBox(
      minWidth: 300, maxWidth: 300,
      minHeight: 450, maxHeight: 450,
      alignment: Alignment.topLeft,
      child: _buildFullChat(controller),
    );
  }

  Widget _buildChatIcon(CanvasController controller) {
    final bool isConnecting = !controller.isRealtimeActive;

    return InkWell(
      onTap: () => controller.isChatOpen = true,
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
            
            if (controller.unreadChatCount > 0)
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
                    '${controller.unreadChatCount}',
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

  Widget _buildFullChat(CanvasController controller) {
    return Column(
      children: [
        // Header
        Container(
          height: 50, // 🚀 Altura fixa para evitar pulos no layout
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
                onPressed: () => controller.isChatOpen = false,
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
              itemCount: controller.chatMessages.length,
              itemBuilder: (context, index) {
                final msg = controller.chatMessages[index];
                final isMe = msg['sender_id'] == controller.myUserId;
                final type = msg['type'] ?? 'text';
                
                final sender = controller.onlineUsers.firstWhere(
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
                        BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))
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
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ),

        if (controller.isRecording)
          _RecordingIndicator(controller: controller)
        else
          Container(
            height: 60, // 🚀 Altura fixa
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2))),
            ),
            child: Row(
              children: [
                Material(
                  color: const Color(0xFF0F4C5C).withValues(alpha: 0.1),
                  shape: const CircleBorder(),
                  child: IconButton(
                    onPressed: () => controller.startRecording(),
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
                    onSubmitted: (val) => _sendMessage(controller),
                  ),
                ),
                IconButton(
                  onPressed: () => _sendMessage(controller),
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

  void _sendMessage(CanvasController controller) {
    if (_msgController.text.trim().isEmpty) return;
    controller.sendChatMessage(_msgController.text.trim());
    _msgController.clear();
  }
}

class _RecordingIndicator extends StatelessWidget {
  final CanvasController controller;
  const _RecordingIndicator({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 60,
      padding: const EdgeInsets.all(12),
      color: Colors.red.withValues(alpha: 0.05),
      child: Row(
        children: [
          const Icon(Icons.fiber_manual_record, color: Colors.red, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 1)),
              builder: (context, snapshot) {
                final dur = controller.recordingDuration;
                return Text(
                  'GRAVANDO... ${dur.inMinutes}:${(dur.inSeconds % 60).toString().padLeft(2, '0')}',
                  style: GoogleFonts.inter(color: Colors.red, fontWeight: FontWeight.bold, fontSize: 12),
                );
              },
            ),
          ),
          ElevatedButton(
            onPressed: () => controller.stopAndSendAudio(),
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
    final controller = ref.watch(canvasProvider);
    final bool isPlaying = controller.currentlyPlayingAudioUrl == widget.url;
    final double progress = isPlaying ? controller.audioPlaybackProgress : 0.0;

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
                    await controller.playAudioMessage(widget.url);
                    return;
                  }
                  
                  setState(() => _isLoading = true);
                  try {
                    await controller.playAudioMessage(widget.url);
                    if (mounted) setState(() => _isLoading = false);
                  } catch (e) {
                    if (mounted) setState(() => _isLoading = false);
                  }
                },
                icon: Icon(
                  isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded, 
                  color: widget.isMe ? Colors.white : const Color(0xFF0F4C5C),
                  size: 28,
                ),
              ),
            const SizedBox(width: 6),
            Text(
              '${widget.duration}s',
              style: GoogleFonts.inter(
                fontSize: 11, 
                fontWeight: FontWeight.bold,
                color: widget.isMe ? Colors.white70 : Colors.black54
              ),
            ),
          ],
        ),
        if (isPlaying || (progress > 0 && progress < 1))
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: SizedBox(
              width: 100,
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: widget.isMe ? Colors.white24 : Colors.black12,
                valueColor: AlwaysStoppedAnimation<Color>(
                  widget.isMe ? Colors.white : const Color(0xFF2ECC71),
                ),
                minHeight: 3,
              ),
            ),
          ),
      ],
    );
  }
}
