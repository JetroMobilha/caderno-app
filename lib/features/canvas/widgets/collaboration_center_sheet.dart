// VERSION 2026-08-06-V1 (UI COLLABORATION SHIELD)
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/core/network/realtime_service.dart';
import 'package:caderno_digital_app/features/canvas/controllers/canvas_controller.dart';
import 'package:caderno_digital_app/features/canvas/widgets/share_notebook_sheet.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';

// -------------------------------------------------------------------------
// 🛡️ [ZONA PROTEGIDA] CENTRO DE COLABORAÇÃO UI 🛡️
// ESTE COMPONENTE GERE A INTERFACE CRÍTICA DE LIGAÇÃO E SESSÕES LIVE.
// -------------------------------------------------------------------------
class CollaborationCenterSheet extends ConsumerWidget {
  final Notebook notebook;

  const CollaborationCenterSheet({super.key, required this.notebook});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.watch(canvasProvider);
    final realtimeStatus = ref.watch(realtimeServiceProvider).statusNotifier;

    return DraggableScrollableSheet( 
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
        child: ListView( 
          controller: scrollController,
          children: [
            Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const SizedBox(width: 48), 
                    Expanded(
                      child: Text(
                        'Centro de Colaboração 🛰️',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C)),
                      ),
                    ),
                    IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close)),
                  ],
                ),
                const SizedBox(height: 8),
                if (controller.isCollaborationEnabled)
                  ValueListenableBuilder<RealtimeStatus>(
                    valueListenable: realtimeStatus,
                    builder: (context, status, _) => Center(child: _buildStatusIndicator(status)),
                  ),
              ],
            ),
            const SizedBox(height: 24),

            if (controller.incomingVoiceCall != null) ...[
              _buildInternalVoiceInvite(controller),
              const SizedBox(height: 16),
            ],

            _buildOnlineToggle(controller),
            const SizedBox(height: 16),

            // 🚀 SELETOR DE DINÂMICA (Apenas para o Dono no template Pessoal/Estudo)
            if (notebook.role == 'owner' && controller.currentTemplateType == 'study' && controller.isCollaborationEnabled) ...[
              const Divider(height: 32),
              Text(
                'Dinâmica da Sessão:',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C)),
              ),
              const SizedBox(height: 12),
              _buildDynamicsSelector(controller),
              const SizedBox(height: 16),
            ],

            const Divider(height: 32),

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

            const SizedBox(height: 32), 

            ValueListenableBuilder<RealtimeStatus>(
              valueListenable: realtimeStatus,
              builder: (context, status, _) {
                if (!controller.isCollaborationEnabled || status != RealtimeStatus.connected) {
                  return const SizedBox.shrink();
                }

                return Column(
                  children: [
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
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),

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

  // -------------------------------------------------------------------------
  // 🛡️ MÉTODOS DE CONSTRUÇÃO DE INTERFACE PROTEGIDOS 🛡️
  // -------------------------------------------------------------------------

  Widget _buildOnlineToggle(CanvasController controller) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: controller.isCollaborationEnabled ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
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
            activeThumbColor: Colors.green,
            activeTrackColor: Colors.green.withValues(alpha: 0.5),
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
      text = 'Ligação estável';
      color = Colors.green;
    } else if (status == RealtimeStatus.connecting) {
      text = 'A ligar...';
      color = Colors.orange;
    } else if (status == RealtimeStatus.error) {
      text = 'Erro de rede';
      color = Colors.red;
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(text, style: GoogleFonts.inter(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
      ],
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
            color: isFollowing ? Colors.blue.withValues(alpha: 0.05) : Colors.grey.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isFollowing ? Colors.blue.withValues(alpha: 0.3) : Colors.transparent),
          ),
          child: Row(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: (u['color'] as Color?) ?? Colors.blueGrey,
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
                    Row(
                      children: [
                        Flexible(child: Text(u['name'], style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14))),
                        const SizedBox(width: 8),
                        _buildRoleBadge(u['role'] ?? 'student', isSmall: true), 
                      ],
                    ),
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
      decoration: BoxDecoration(color: Colors.grey.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(16)),
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

  Widget _buildRoleBadge(String role, {bool isSmall = false}) {
    Color color = Colors.grey;
    String label = 'Visitante';

    if (role == 'owner') { color = Colors.orange; label = 'Dono'; }
    else if (role == 'editor') { color = Colors.blue; label = 'Editor'; }
    else if (role == 'student') { color = Colors.teal; label = 'Aluno'; }
    else if (role == 'viewer') { color = Colors.blueGrey; label = 'Leitor'; }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: isSmall ? 6 : 10, vertical: isSmall ? 1 : 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15), 
        borderRadius: BorderRadius.circular(20), 
        border: Border.all(color: color.withValues(alpha: 0.5), width: 0.5)
      ),
      child: Text(
        label, 
        style: GoogleFonts.inter(
          fontSize: isSmall ? 9 : 11, 
          fontWeight: FontWeight.bold, 
          color: color
        )
      ),
    );
  }

  Widget _buildDynamicsSelector(CanvasController controller) {
    return Column(
      children: [
        _buildDynamicPolicyToggle(
          controller, 
          controller.isSessionLocked, 
          'Bloquear Edição Coletiva', 
          'Impedir que outros desenhem enquanto explicas.',
          Icons.lock_person_rounded,
          const Color(0xFFE74C3C),
          onTap: () => controller.toggleSessionLock(),
        ),
        const SizedBox(height: 12),
        _buildDynamicPolicyToggle(
          controller, 
          controller.isAuthorColorEnabled, 
          'Identificar Autores por Cor', 
          'Cada utilizador terá uma cor única (Tutoria).',
          Icons.palette_rounded,
          const Color(0xFF0F4C5C),
          onTap: () => controller.toggleAuthorColors(),
        ),
      ],
    );
  }

  Widget _buildDynamicPolicyToggle(CanvasController controller, bool value, String title, String subtitle, IconData icon, Color color, {required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? color.withValues(alpha: 0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: value ? color : Colors.grey.shade200, width: 2),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: value ? color : Colors.grey.shade100, shape: BoxShape.circle),
              child: Icon(icon, color: value ? Colors.white : Colors.grey, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: value ? color : Colors.black87)),
                  Text(subtitle, style: GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: (_) => onTap(),
              activeColor: color,
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // 🛡️ GESTÃO DE CONVITES E ACÇÕES DE VOZ 🛡️
  // -------------------------------------------------------------------------

  Widget _buildVoiceButton(CanvasController controller, BuildContext context) {
    final bool isModerator = controller.currentUserRole == 'owner' || controller.currentUserRole == 'editor';

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
