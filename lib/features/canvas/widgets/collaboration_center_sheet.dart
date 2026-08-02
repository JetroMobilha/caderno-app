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

    return DraggableScrollableSheet( // 🚀 Torna o sheet expansível se houver muitos colegas
      initialChildSize: 0.7,
      minChildSize: 0.4,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: ListView( // 🚀 Usa ListView com o controller do sheet
          controller: scrollController,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Centro de Colaboração 🛰️',
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C)),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      _buildRoleBadge(controller.currentUserRole),
                    ],
                  ),
                ),
                IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
              ],
            ),
            const SizedBox(height: 20),

            // 🎙️ CONVITE DE VOZ ATIVO (Se existir)
            if (controller.incomingVoiceCall != null) ...[
              _buildInternalVoiceInvite(controller),
              const SizedBox(height: 16),
            ],

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

            const SizedBox(height: 32), // 🚀 Espaçamento maior antes das ações

              Row(
                children: [
                  Expanded(
                    child: _buildVoiceButton(controller, context),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildActionButton(
                      icon: controller.isBroadcastingViewport ? Icons.sensors : Icons.sensors_off,
                      label: controller.isBroadcastingViewport ? 'Parar Visão' : 'Transmitir Visão',
                      color: controller.isBroadcastingViewport ? Colors.redAccent : const Color(0xFF0F4C5C),
                      onTap: () {
                        if (controller.isBroadcastingViewport) {
                          controller.stopViewportBroadcasting();
                        } else {
                          controller.startViewportBroadcasting(controller.myUserId);
                        }
                        Navigator.pop(context);
                      },
                    ),
                  ),
                ],
              ),

            const SizedBox(height: 20), // 🚀 Margem entre linhas de botões

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
    final others = controller.onlineUsers.where((u) => u['id'].toString() != controller.myUserId).toList();

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: others.length,
      separatorBuilder: (context, index) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final u = others[index];
        final String uId = u['id'].toString();
        final bool isFollowing = controller.followingUserId == uId;
        final bool isTalking = u['isTalking'] == true;
        final bool isHandRaised = u['isHandRaised'] == true;

        return Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isFollowing ? Colors.blue.withOpacity(0.05) : Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isFollowing ? Colors.blue.withOpacity(0.3) : Colors.transparent),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: u['color'] as Color,
                    child: Text(u['name'][0], style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  if (isTalking)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.green, width: 2),
                        ),
                      ),
                    ),
                  if (isHandRaised)
                    const Positioned(
                      right: -2, top: -2,
                      child: CircleAvatar(radius: 8, backgroundColor: Colors.orange, child: Icon(Icons.pan_tool, size: 8, color: Colors.white)),
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(u['name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                    Text(isFollowing ? 'A assistir visão...' : 'Online agora', 
                         style: GoogleFonts.inter(fontSize: 11, color: isFollowing ? Colors.blue : Colors.black45)),
                  ],
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  controller.toggleFollowUser(uId, controller.myUserId);
                  Navigator.pop(context);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: isFollowing ? Colors.redAccent : Colors.blueAccent,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  minimumSize: const Size(80, 32),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(isFollowing ? 'Parar' : 'Assistir', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        );
      },
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

  Widget _buildActionButton({required IconData icon, required String label, required Color color, required VoidCallback? onTap}) {
    return ElevatedButton.icon(
      style: ElevatedButton.styleFrom(
        backgroundColor: color,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 0,
        disabledBackgroundColor: color.withValues(alpha: 0.3),
        disabledForegroundColor: Colors.white70,
      ),
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildRoleBadge(String role) {
    Color color = Colors.grey;
    String label = 'Visitante';

    if (role == 'owner') { color = Colors.orange; label = 'Dono do Caderno'; }
    else if (role == 'editor') { color = Colors.blue; label = 'Editor'; }
    else if (role == 'student') { color = Colors.teal; label = 'Aluno'; }
    else if (role == 'viewer') { color = Colors.blueGrey; label = 'Leitor'; }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
      decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20), border: Border.all(color: color.withValues(alpha: 0.5), width: 1)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color)),
    );
  }

  Widget _buildVoiceButton(CanvasController controller, BuildContext context) {
    final bool isModerator = controller.currentUserRole == 'owner' || controller.currentUserRole == 'editor';
    final bool canStart = isModerator || controller.isRemoteVoiceCallActive;

    String label = 'Iniciar Estudo Live';
    IconData icon = Icons.podcasts;
    Color color = const Color(0xFF0F4C5C);
    VoidCallback? action = () => controller.toggleVoiceCall(controller.myUserId);

    if (controller.isLiveSessionActive) {
      label = 'Sair do Estudo Live';
      icon = Icons.stop_screen_share;
      color = Colors.redAccent;
    } else if (controller.isRemoteVoiceCallActive) {
      label = 'Entrar no Estudo Live';
      icon = Icons.record_voice_over;
      color = const Color(0xFF27AE60);
    } else if (!isModerator) {
      label = 'Aguardar Moderador';
      icon = Icons.hourglass_empty;
      color = Colors.grey;
      action = null;
    }

    return _buildActionButton(
      icon: icon,
      label: label,
      color: color,
      onTap: action != null ? () { action!(); Navigator.pop(context); } : null,
    );
  }

  Widget _buildInternalVoiceInvite(CanvasController controller) {
    final call = controller.incomingVoiceCall!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF27AE60).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF27AE60), width: 1.5),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.record_voice_over, color: Color(0xFF27AE60)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Conversa de Voz!',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF27AE60)),
                    ),
                    Text(
                      '${call['sender_name'] ?? 'Um colega'} iniciou a chamada.',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => controller.dismissVoiceCall(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Recusar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => controller.acceptVoiceCall(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF27AE60),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('Aceitar'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
