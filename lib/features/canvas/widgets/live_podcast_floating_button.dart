import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/collaboration_room_service.dart';
import '../services/ptt_walkie_talkie_service.dart';
import '../providers/canvas_ui_provider.dart';

class LivePodcastFloatingButton extends ConsumerWidget {
  const LivePodcastFloatingButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collabService = ref.watch(collaborationRoomServiceProvider);
    final pttService = ref.watch(pttWalkieTalkieServiceProvider);
    final uiState = ref.watch(canvasUiProvider);

    if (!collabService.isCollaborationEnabled || uiState.isHudMode) {
      return const SizedBox.shrink();
    }

    // 🚀 Exibir SnackBar amigável se a plataforma não suportar gravação em stream (ex: Windows Desktop)
    if (pttService.pttErrorMessage != null) {
      final msg = pttService.pttErrorMessage!;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg, style: GoogleFonts.inter(fontSize: 12)),
            backgroundColor: Colors.orange.shade900,
            duration: const Duration(seconds: 4),
          ),
        );
        pttService.clearErrorMessage();
      });
    }

    final isOccupied = pttService.isChannelBusy || collabService.isPodcastChannelOccupied;
    final speakerName = pttService.activeSpeakerName ?? collabService.activePodcastSpeakerName ?? 'Alguém';
    final isMeSpeaking = pttService.isTransmitting || (collabService.activePodcastSpeakerId == collabService.myUserId);

    final String myUserName = collabService.onlineUsers.firstWhere(
      (u) => u['id'].toString() == collabService.myUserId,
      orElse: () => {'name': 'Eu'},
    )['name'];

    return GestureDetector(
      onPanDown: (_) async {
        if (isOccupied && !isMeSpeaking) return;
        await pttService.initWebAudioContext(); // 🌐 Web Autoplay unlock

        if (collabService.liveNotebookSid != null) {
          pttService.acquireLock(
            notebookId: collabService.liveNotebookSid!,
            myUserId: collabService.myUserId,
            myUserName: myUserName,
          );
        }
      },
      onPanEnd: (_) => _releasePtt(collabService, pttService),
      onPanCancel: () => _releasePtt(collabService, pttService),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        height: 56,
        padding: isOccupied ? const EdgeInsets.symmetric(horizontal: 16) : EdgeInsets.zero,
        constraints: isOccupied ? const BoxConstraints(maxWidth: 220) : null,
        width: isOccupied ? null : 56,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          color: isMeSpeaking ? Colors.redAccent : Colors.white,
          boxShadow: [
            BoxShadow(
              color: isMeSpeaking
                  ? Colors.redAccent.withOpacity(0.5)
                  : Colors.black.withOpacity(0.15),
              blurRadius: isMeSpeaking ? 16 : 10,
              spreadRadius: isMeSpeaking ? 4 : 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: isOccupied
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isMeSpeaking
                        ? Icons.mic
                        : Icons.sensors,
                    color: isMeSpeaking
                        ? Colors.white
                        : Colors.redAccent,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      '🔴 $speakerName no ar',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isMeSpeaking
                            ? Colors.white
                            : Colors.redAccent,
                      ),
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                    ),
                  ),
                ],
              )
            : const Icon(
                Icons.podcasts,
                color: Color(0xFF0F4C5C),
                size: 28,
              ),
      ),
    );
  }

  void _releasePtt(
    CollaborationRoomService collabService,
    PttWalkieTalkieService pttService,
  ) {
    if (collabService.liveNotebookSid != null) {
      pttService.releaseLock(
        notebookId: collabService.liveNotebookSid!,
        myUserId: collabService.myUserId,
      );
    }
  }
}
