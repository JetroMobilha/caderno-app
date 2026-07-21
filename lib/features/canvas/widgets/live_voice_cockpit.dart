import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveVoiceCockpit extends StatelessWidget {
  final List<Map<String, dynamic>> onlineUsers;
  final bool isMuted;
  final bool isSpeakerOn;
  final bool isHandRaised;
  final VoidCallback onMuteToggle;
  final VoidCallback onSpeakerToggle;
  final VoidCallback onHandToggle;
  final VoidCallback onHangUp;

  const LiveVoiceCockpit({
    super.key,
    required this.onlineUsers,
    required this.isMuted,
    required this.isSpeakerOn,
    required this.isHandRaised,
    required this.onMuteToggle,
    required this.onSpeakerToggle,
    required this.onHandToggle,
    required this.onHangUp,
  });

  @override
  Widget build(BuildContext context) {
    // 🛡️ Proteção contra overflow: Mostra no máximo 4 avatares
    final displayUsers = onlineUsers.take(4).toList();
    final remainingCount = onlineUsers.length - displayUsers.length;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF27AE60).withOpacity(0.25),
              blurRadius: 20,
              offset: const Offset(0, 8)
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.graphic_eq, color: Color(0xFF27AE60), size: 18),
          const SizedBox(width: 8),
          Text(
              'Sala de Voz P2P',
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)
          ),
          Container(
              width: 1,
              height: 16,
              color: Colors.white24,
              margin: const EdgeInsets.symmetric(horizontal: 10)
          ),

          // Lista de Avatares Segura
          ...displayUsers.map((s) {
            final String name = (s['name'] ?? '?').toString();
            final String initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

            return Container(
              margin: const EdgeInsets.only(right: 4),
              padding: const EdgeInsets.all(1.5),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                    color: s['isTalking'] == true ? const Color(0xFF27AE60) : Colors.transparent,
                    width: 1.5
                ),
              ),
              child: Tooltip(
                message: name,
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    CircleAvatar(
                      radius: 9,
                      backgroundColor: (s['color'] as Color?) ?? Colors.blueGrey,
                      child: Text(
                          initial,
                          style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)
                      ),
                    ),
                    if (s['isHandRaised'] == true)
                      const Positioned(
                        right: -4, top: -4,
                        child: Icon(Icons.pan_tool, color: Colors.orange, size: 10),
                      ),
                  ],
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

          const SizedBox(width: 6),

          // 🎤 Controlo de Mute ligado ao Controller
          _buildVoiceButton(
            icon: isMuted ? Icons.mic_off : Icons.mic,
            color: isMuted ? Colors.redAccent : Colors.white12,
            onTap: onMuteToggle,
          ),
          const SizedBox(width: 6),

          // 🔊 Controlo de Coluna ligado ao Controller
          _buildVoiceButton(
            icon: isSpeakerOn ? Icons.volume_up : Icons.headphones,
            color: Colors.white12,
            onTap: onSpeakerToggle,
          ),
          const SizedBox(width: 6),

          // ✋ Pedir a Palavra
          _buildVoiceButton(
            icon: Icons.pan_tool,
            color: isHandRaised ? Colors.orange : Colors.white12,
            onTap: onHandToggle,
          ),
          const SizedBox(width: 6),

          // 📞 Terminar Chamada
          _buildVoiceButton(
            icon: Icons.call_end,
            color: Colors.redAccent,
            onTap: onHangUp,
          ),
        ],
      ),
    );
  }

  Widget _buildVoiceButton({required IconData icon, required Color color, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: Icon(icon, size: 14, color: Colors.white),
      ),
    );
  }
}