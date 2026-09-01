import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/time_utils.dart';
import '../../canvas/providers/collaboration_provider.dart';
import '../models/notebook_model.dart';
import '../models/notebook_template.dart';

class NotebookCover extends ConsumerStatefulWidget {
  final Notebook notebook;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NotebookCover({
    super.key,
    required this.notebook,
    required this.onTap,
    this.onLongPress,
  });

  @override
  ConsumerState<NotebookCover> createState() => _NotebookCoverState();
}

class _NotebookCoverState extends ConsumerState<NotebookCover> with SingleTickerProviderStateMixin {
  late double _scale;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.05,
    )..addListener(() {
      setState(() => _scale = 1 - _controller.value);
    });
    _scale = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    Color coverColor = AppColors.primary;
    try {
      if (widget.notebook.color != null && widget.notebook.color!.isNotEmpty) {
        coverColor = Color(int.parse(widget.notebook.color!.replaceFirst('#', '0xFF')));
      }
    } catch (_) {}

    final bool isUnsynced = widget.notebook.syncedWithCloud == 0 && widget.notebook.serverId == null;
    final bool isShared = widget.notebook.role != 'owner';
    final bool isPublished = widget.notebook.isPublished == 1;

    final templateType = NotebookTemplateType.values.firstWhere(
      (e) => e.name == widget.notebook.templateType,
      orElse: () => NotebookTemplateType.blank,
    );
    final templateConfig = NotebookTemplateConfig.templates[templateType];
    final IconData coverIcon = templateConfig?.icon ?? Icons.book_rounded;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      child: Transform.scale(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: coverColor,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            boxShadow: [
              BoxShadow(color: coverColor.withOpacity(0.3), blurRadius: 8, offset: const Offset(2, 4)),
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 2, offset: const Offset(0, 1)),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
              topLeft: Radius.circular(4),
              bottomLeft: Radius.circular(4),
            ),
            child: Stack(
              children: [
                // 0. Gradiente de profundidade/legibilidade na base
                Positioned.fill(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        stops: const [0.4, 1.0],
                        colors: [Colors.transparent, Colors.black.withOpacity(0.4)],
                      ),
                    ),
                  ),
                ),

                // 🚀 MARCA DE ÁGUA (Ícone do Template)
                Positioned(
                  right: -10,
                  bottom: 40,
                  child: Icon(
                    coverIcon,
                    size: 80,
                    color: Colors.white.withOpacity(0.12),
                  ),
                ),

                // 1. Lombada
                Positioned(
                  left: 0, top: 0, bottom: 0,
                  child: Container(
                    width: 12,
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.25),
                      borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
                    ),
                  ),
                ),

                // 2. Conteúdo Principal
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 16, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // TÍTULO E ÍCONE
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.book_rounded, color: Colors.white, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              widget.notebook.alternativeTitle ?? widget.notebook.title,
                              maxLines: 2, overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.lora(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.white, height: 1.1),
                            ),
                          ),
                        ],
                      ),
                      
                      const Spacer(),

                      // 1. PRESENÇA (Simples: X acessos + Online)
                      if (widget.notebook.participantsTotal > 1)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: _buildPresenceInfo(widget.notebook.participantsTotal, widget.notebook.onlineCount),
                        ),

                      // 2. RODAPÉ DISTRIBUÍDO (RULER | TEMPO | PAGINAS)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          // ESQUERDA: Papel (Ruler)
                          if (isShared)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                _getRoleName(widget.notebook.role).toUpperCase(),
                                style: GoogleFonts.inter(fontSize: 7, color: Colors.white, fontWeight: FontWeight.w900),
                              ),
                            )
                          else
                            const SizedBox(width: 40), // Espaçador para manter o tempo centralizado

                          // CENTRO: Tempo
                          Expanded(
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 4),
                              child: Text(
                                TimeUtils.formatRelativeTime(widget.notebook.updatedAt),
                                textAlign: TextAlign.center,
                                maxLines: 1,
                                style: GoogleFonts.inter(fontSize: 8, color: Colors.white.withOpacity(0.6), fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),

                          // DIREITA: Páginas
                          Text(
                            '${widget.notebook.pageCount} pag',
                            textAlign: TextAlign.right,
                            style: GoogleFonts.inter(fontSize: 9, color: Colors.white, fontWeight: FontWeight.w900),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // 3. BADGES (TOP RIGHT)
                Positioned(
                  top: 8, right: 8,
                  child: Row(
                    children: [
                      if (widget.notebook.isFavorite)
                        const Icon(Icons.star_rounded, size: 14, color: Colors.orangeAccent),
                      if (!widget.notebook.notificationsEnabled)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: Icon(Icons.notifications_off_outlined, size: 12, color: Colors.white.withOpacity(0.5)),
                        ),
                      if (isUnsynced)
                        Padding(
                          padding: const EdgeInsets.only(left: 4),
                          child: const Icon(Icons.cloud_off_rounded, size: 12, color: Colors.white54),
                        ),
                    ],
                  ),
                ),

                // 4. ORIGEM (BOTTOM RIGHT)
                if (widget.notebook.origin != null)
                  Positioned(
                    bottom: 8, right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                      decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(4)),
                      child: Text(
                        widget.notebook.origin!.toUpperCase(),
                        style: GoogleFonts.inter(fontSize: 7, color: Colors.white60, fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPresenceInfo(int total, int online) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícone de Pessoas + Total
        Icon(Icons.people_outline_rounded, size: 12, color: Colors.white.withOpacity(0.8)),
        const SizedBox(width: 4),
        Text(
          '$total',
          style: GoogleFonts.inter(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
        ),

        // Indicador Online (se houver alguém)
        if (online > 0) ...[
          const SizedBox(width: 8),
          Container(
            width: 6, height: 6,
            decoration: const BoxDecoration(color: Colors.greenAccent, shape: BoxShape.circle),
          ),
          const SizedBox(width: 4),
          Text(
            'Online',
            style: GoogleFonts.inter(fontSize: 9, color: Colors.greenAccent, fontWeight: FontWeight.w900),
          ),
        ],
      ],
    );
  }

  IconData _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'owner': return Icons.verified_user_rounded;
      case 'editor': return Icons.edit_rounded;
      case 'student': return Icons.school_rounded;
      case 'viewer': return Icons.visibility_rounded;
      default: return Icons.person_rounded;
    }
  }

  String _getRoleName(String role) {
    switch (role.toLowerCase()) {
      case 'owner': return 'Dono';
      case 'editor': return 'Editor';
      case 'student': return 'Aluno';
      case 'viewer': return 'Leitor';
      default: return role;
    }
  }

  Color _getAvatarColor(String name) {
    final colors = [
      Colors.blueAccent, Colors.redAccent, Colors.greenAccent, 
      Colors.orangeAccent, Colors.purpleAccent, Colors.tealAccent
    ];
    return colors[name.length % colors.length];
  }
}
