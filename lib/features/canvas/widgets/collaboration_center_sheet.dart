import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/features/canvas/controllers/canvas_controller.dart';
import 'package:caderno_digital_app/features/canvas/widgets/share_notebook_sheet.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';

class CollaborationCenterSheet extends ConsumerWidget {
  final Notebook notebook;

  const CollaborationCenterSheet({super.key, required this.notebook});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(canvasProvider);
    final realtimeStatus = ref.watch(realtimeServiceProvider).statusNotifier;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Centro de Colaboração 🛰️',
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C)),
              ),
              IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
            ],
          ),
          const SizedBox(height: 20),

          // 🌐 MODO ONLINE TOGGLE
          _buildOnlineToggle(controller),
          const SizedBox(height: 16),

          // 🛰️ STATUS DA LIGAÇÃO
          if (controller.isCollaborationEnabled)
            ValueListenableBuilder<RealtimeStatus>(
              valueListenable: realtimeStatus,
              builder: (context, status, _) => _buildStatusIndicator(status),
            ),

          const Divider(height: 32),

          // 👥 QUEM ESTÁ NA SALA
          Text(
            'Colegas na Sala:',
            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
          ),
          const SizedBox(height: 12),
          if (!controller.isCollaborationEnabled)
            _buildEmptyState('Fica online para veres quem está a estudar contigo.')
          else if (controller.onlineUsers.isEmpty)
            _buildEmptyState('Estás sozinho na sala. Convida alguém!')
          else
            _buildUserList(controller, context),

          const SizedBox(height: 24),

          // 🛠️ AÇÕES RÁPIDAS
          if (controller.isCollaborationEnabled) ...[
            Row(
              children: [
                Expanded(
                  child: _buildActionButton(
                    icon: controller.isInVoiceCall ? Icons.phone_disabled : Icons.phone_callback,
                    label: controller.isInVoiceCall ? 'Sair da Chamada' : 'Iniciar Voz',
                    color: controller.isInVoiceCall ? Colors.redAccent : const Color(0xFF27AE60),
                    onTap: () {
                      controller.toggleVoiceCall(controller.myUserId);
                      Navigator.pop(context);
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildActionButton(
                    icon: Icons.pan_tool,
                    label: controller.isMyHandRaised ? 'Baixar Mão' : 'Pedir Palavra',
                    color: controller.isMyHandRaised ? Colors.orange : Colors.blueAccent,
                    onTap: () {
                      controller.toggleHandRaise();
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],

          // 🤝 BOTÃO DE PARTILHA (Integrado)
          if (notebook.role == 'owner')
            SizedBox(
              width: double.infinity,
              child: _buildActionButton(
                icon: Icons.person_add_alt_1,
                label: 'Convidar Amigos para o Caderno',
                color: const Color(0xFF0F4C5C),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => ShareNotebookBottomSheet(notebook: notebook),
                  );
                },
              ),
            ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildOnlineToggle(CanvasController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: controller.isCollaborationEnabled ? Colors.green.withOpacity(0.1) : Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(
                controller.isCollaborationEnabled ? Icons.wifi_tethering : Icons.wifi_tethering_off,
                color: controller.isCollaborationEnabled ? Colors.green : Colors.grey,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    controller.isCollaborationEnabled ? 'Modo Online Ativo' : 'Modo Offline',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  Text(
                    controller.isCollaborationEnabled ? 'Outros podem ver o teu progresso' : 'Privacidade total garantida',
                    style: GoogleFonts.inter(fontSize: 11, color: Colors.black45),
                  ),
                ],
              ),
            ],
          ),
          Switch(
            value: controller.isCollaborationEnabled,
            activeColor: Colors.green,
            onChanged: (val) => controller.toggleCollaboration(val),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusIndicator(RealtimeStatus status) {
    String text = 'Desconectado';
    Color color = Colors.grey;
    if (status == RealtimeStatus.connected) {
      text = 'Ligação Estável via Reverb';
      color = Colors.green;
    } else if (status == RealtimeStatus.connecting) {
      text = 'A estabelecer ligação...';
      color = Colors.orange;
    } else if (status == RealtimeStatus.error) {
      text = 'Falha na rede (A tentar reconectar)';
      color = Colors.red;
    }

    return Padding(
      padding: const EdgeInsets.only(top: 8, left: 4),
      child: Row(
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(text, style: GoogleFonts.inter(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildUserList(CanvasController controller, BuildContext context) {
    return Container(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: controller.onlineUsers.length,
        itemBuilder: (context, index) {
          final u = controller.onlineUsers[index];
          final String uId = u['id'].toString();
          if (uId == controller.myUserId) return const SizedBox.shrink();

          final bool isFollowing = controller.followingUserId == uId;
          final bool isTalking = u['isTalking'] == true;
          final bool isHandRaised = u['isHandRaised'] == true;

          return GestureDetector(
            onTap: () {
              controller.toggleFollowUser(uId, controller.myUserId);
              Navigator.pop(context);
            },
            child: Container(
              width: 80,
              margin: const EdgeInsets.only(right: 12),
              child: Column(
                children: [
                  Stack(
                    alignment: Alignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: isTalking ? Colors.green : (isFollowing ? Colors.blue : Colors.transparent),
                            width: 2,
                          ),
                        ),
                        child: CircleAvatar(
                          radius: 24,
                          backgroundColor: u['color'] as Color,
                          child: Text(u['name'][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        ),
                      ),
                      if (isHandRaised)
                        const Positioned(
                          right: 0, top: 0,
                          child: CircleAvatar(radius: 10, backgroundColor: Colors.orange, child: Icon(Icons.pan_tool, size: 10, color: Colors.white)),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    u['name'],
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: isFollowing ? FontWeight.bold : FontWeight.normal),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 20),
      decoration: BoxDecoration(color: Colors.grey.withOpacity(0.05), borderRadius: BorderRadius.circular(16)),
      child: Center(
        child: Text(message, textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 12, color: Colors.black38, fontStyle: FontStyle.italic)),
      ),
    );
  }

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback onTap}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }
}
