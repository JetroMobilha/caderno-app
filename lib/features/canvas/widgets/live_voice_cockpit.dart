import 'package:flutter/material.dart';

class LiveVoiceCockpit extends StatelessWidget {
  final List<Map<String, dynamic>> onlineUsers;
  final Map<String, double> userAudioLevels;
  final Map<String, String?> userReactions; 
  final String? followingUserId;
  final String myUserId; // 🚀 Novo
  final bool isSpeakerOn;
  final bool isRecording; // 🎙️ Novo
  final bool isLoading; 
  final VoidCallback onSpeakerToggle;
  final VoidCallback onMicTap; // 🎙️ Novo
  final Function(String) onReactionSend; 
  final Function(String) onUserTap; // 🚀 Novo: Seguir utilizador
  final bool isBroadcasting; 
  final VoidCallback onBroadcastToggle; 
  final bool isHandRaised; // 🚀
  final VoidCallback onHandToggle; // 🚀
  final VoidCallback onHangUp;

  const LiveVoiceCockpit({
    super.key,
    required this.onlineUsers,
    required this.userAudioLevels,
    required this.userReactions,
    this.followingUserId,
    required this.myUserId, 
    required this.isSpeakerOn,
    this.isRecording = false, 
    this.isLoading = false,
    required this.onSpeakerToggle,
    required this.onMicTap, 
    required this.onReactionSend, 
    required this.onUserTap, 
    this.isBroadcasting = false, 
    required this.onBroadcastToggle, 
    required this.isHandRaised, // 🚀
    required this.onHandToggle, // 🚀
    required this.onHangUp,
  });

  @override
  Widget build(BuildContext context) {
    // 🛡️ Proteção contra overflow: Mostra no máximo 4 avatares
    final displayUsers = onlineUsers.take(4).toList();
    final remainingCount = onlineUsers.length - displayUsers.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF27AE60).withValues(alpha: 0.25),
              blurRadius: 20,
              offset: const Offset(0, 8)
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildSoundWaveIcon(onlineUsers.any((u) => u['isTalking'] == true)),
          Container(
              width: 1,
              height: 16,
              color: Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 6)
          ),

          // Lista de Avatares Segura
          ...onlineUsers.take(4).map((s) {
            final String name = (s['name'] ?? '?').toString();
            final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';
            final String uid = (s['id'] ?? '').toString();
            final double level = userAudioLevels[uid] ?? 0.0;
            final bool isTalking = s['isTalking'] == true || level > 0.001;
            final String activity = s['activity'] ?? 'idle';
            final String? currentReaction = userReactions[uid];
            final bool isFollowing = uid == followingUserId; 
            final bool isMe = uid == myUserId; // 🛡️

            return GestureDetector(
              onTap: isMe ? null : () => onUserTap(uid), // 🛡️ Bloqueia se for eu
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                margin: const EdgeInsets.only(right: 4),
                padding: const EdgeInsets.all(2.0),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                      color: isTalking 
                          ? const Color(0xFF2ECC71) 
                          : (isFollowing ? Colors.blue : (activity == 'drawing' ? Colors.orangeAccent : (s['isInCall'] == true ? Colors.blueAccent : Colors.transparent))),
                      width: isTalking ? 2.5 : 1.5
                  ),
                  boxShadow: isTalking ? [
                    BoxShadow(
                      color: const Color(0xFF2ECC71).withValues(alpha: (level * 8).clamp(0.4, 0.9)), 
                      blurRadius: 10 + (level * 60), 
                      spreadRadius: 2 + (level * 15)
                    )
                  ] : (isFollowing ? [
                    const BoxShadow(color: Colors.blue, blurRadius: 8, spreadRadius: 1)
                  ] : (activity != 'idle' ? [
                    BoxShadow(
                      color: activity == 'drawing' ? Colors.orangeAccent.withValues(alpha: 0.3) : Colors.blueAccent.withValues(alpha: 0.3),
                      blurRadius: 8,
                      spreadRadius: 1
                    )
                  ] : null)),
                ),
                child: Tooltip(
                  message: isFollowing ? 'A assistir $name (Clica para parar)' : '$name (Clica para assistir visão)',
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 10,
                        backgroundColor: (s['color'] as Color?) ?? Colors.blueGrey,
                        child: Text(
                            initial,
                            style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)
                        ),
                      ),
                      if (currentReaction != null)
                        Positioned(
                          top: -24, left: 0, right: 0,
                          child: Center(
                            child: Material( 
                              color: Colors.transparent,
                              elevation: 0,
                              child: Text(
                                currentReaction, 
                                style: const TextStyle(fontSize: 22),
                              ),
                            ),
                          ),
                        ),
                      if (activity == 'drawing')
                        const Positioned(
                          right: -4, bottom: -4,
                          child: Icon(Icons.edit, color: Colors.orange, size: 10),
                        ),
                      if (activity == 'typing')
                        const Positioned(
                          right: -4, bottom: -4,
                          child: Icon(Icons.keyboard, color: Colors.blueAccent, size: 10),
                        ),
                      if (s['isInCall'] == true && activity == 'idle')
                        const Positioned(
                          left: -3, bottom: -3,
                          child: Icon(Icons.mic, color: Color(0xFF27AE60), size: 12),
                        ),
                      if (s['isHandRaised'] == true)
                        const Positioned(
                          right: -5, top: -5,
                          child: Icon(Icons.pan_tool, color: Colors.orange, size: 11),
                        ),
                    ],
                  ),
                ),
              ),
            );
          }),

          // Contador para alunos extra (ex: "+2")
          if (remainingCount > 0)
            Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(4),
              decoration: const BoxDecoration(color: Colors.white12, shape: BoxShape.circle),
              child: Text(
                  '+$remainingCount',
                  style: const TextStyle(fontSize: 8, color: Colors.white70, fontWeight: FontWeight.bold)
              ),
            ),

          const SizedBox(width: 4),

          _buildVoiceButton(
            icon: isSpeakerOn ? Icons.volume_up : Icons.headphones,
            color: Colors.white12,
            onTap: onSpeakerToggle,
          ),
          const SizedBox(width: 4),

          // 🎙️ MICROFONE (Live Audio)
          _buildVoiceButton(
            icon: isRecording ? Icons.mic : Icons.mic_none,
            color: isRecording ? Colors.redAccent : Colors.white12,
            onTap: onMicTap,
            isRecording: isRecording,
          ),
          const SizedBox(width: 4),

          // 🔭 Transmitir Visão
          _buildVoiceButton(
            icon: isBroadcasting ? Icons.sensors : Icons.sensors_off,
            color: isBroadcasting ? Colors.redAccent : Colors.white12,
            onTap: onBroadcastToggle,
          ),
          const SizedBox(width: 4),

          // ✋ Mão Levantada
          _buildVoiceButton(
            icon: Icons.pan_tool,
            color: isHandRaised ? Colors.orangeAccent : Colors.white12,
            onTap: onHandToggle,
          ),
          const SizedBox(width: 4),

          // 🎭 Reações Rápidas
          _buildReactionPicker(context),
          const SizedBox(width: 4),

          // 📞 Terminar Chamada ou Spinner
          isLoading 
            ? const SizedBox(width: 26, height: 26, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white70))
            : _buildVoiceButton(
                icon: Icons.call_end,
                color: Colors.redAccent,
                onTap: onHangUp,
              ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton({required IconData icon, required Color color, required VoidCallback onTap, bool isRecording = false}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: color, 
          shape: BoxShape.circle,
          boxShadow: isRecording ? [
            BoxShadow(color: Colors.redAccent.withValues(alpha: 0.5), blurRadius: 10, spreadRadius: 2)
          ] : null,
        ),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }

  Widget _buildReactionPicker(BuildContext context) {
    final reactions = ['❤️', '👏', '🔥', '🤣', '💡', '❓'];
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add_reaction_outlined, color: Colors.white, size: 14),
      padding: EdgeInsets.zero,
      constraints: const BoxConstraints(),
      onSelected: onReactionSend,
      itemBuilder: (context) => reactions.map((r) => PopupMenuItem(
        value: r,
        height: 32,
        child: Center(child: Text(r, style: const TextStyle(fontSize: 18))),
      )).toList(),
      offset: const Offset(0, -40),
    );
  }

  Widget _buildSoundWaveIcon(bool active) {
    return SizedBox(
      width: 18, height: 18,
      child: active 
        ? const Icon(Icons.graphic_eq, color: Color(0xFF2ECC71), size: 18)
        : const Icon(Icons.graphic_eq, color: Colors.white24, size: 18),
    );
  }
}
