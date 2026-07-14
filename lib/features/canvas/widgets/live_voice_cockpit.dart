import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LiveVoiceCockpit extends StatefulWidget {
  final List<Map<String, dynamic>> onlineUsers;
  final VoidCallback onHangUp;

  const LiveVoiceCockpit({
    super.key,
    required this.onlineUsers,
    required this.onHangUp,
  });

  @override
  State<LiveVoiceCockpit> createState() => _LiveVoiceCockpitState();
}

class _LiveVoiceCockpitState extends State<LiveVoiceCockpit> {
  bool _isMuted = false;
  bool _isSpeakerOn = true;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A24),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: const Color(0xFF27AE60).withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.graphic_eq, color: Color(0xFF27AE60), size: 18),
          const SizedBox(width: 8),
          Text('Sala de Voz P2P', style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          Container(width: 1, height: 16, color: Colors.white24, margin: const EdgeInsets.symmetric(horizontal: 10)),

          ...widget.onlineUsers.map((s) => Container(
            margin: const EdgeInsets.only(right: 4),
            padding: const EdgeInsets.all(1.5),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: s['isTalking'] == true ? const Color(0xFF27AE60) : Colors.transparent, width: 1.5),
            ),
            child: Tooltip(
              message: s['name'],
              child: CircleAvatar(
                radius: 9,
                backgroundColor: s['color'] as Color?,
                child: Text(s['name'][0].toUpperCase(), style: const TextStyle(fontSize: 9, color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
          )),
          const SizedBox(width: 6),

          _buildVoiceButton(
            icon: _isMuted ? Icons.mic_off : Icons.mic,
            color: _isMuted ? Colors.redAccent : Colors.white12,
            onTap: () => setState(() => _isMuted = !_isMuted),
          ),
          const SizedBox(width: 6),
          _buildVoiceButton(
            icon: _isSpeakerOn ? Icons.volume_up : Icons.headphones,
            color: Colors.white12,
            onTap: () => setState(() => _isSpeakerOn = !_isSpeakerOn),
          ),
          const SizedBox(width: 6),
          _buildVoiceButton(
            icon: Icons.call_end,
            color: Colors.redAccent,
            onTap: widget.onHangUp,
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