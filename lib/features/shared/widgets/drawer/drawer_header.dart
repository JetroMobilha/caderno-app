import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/features/auth/models/user_model.dart';

class DrawerHeaderWidget extends StatelessWidget {
  final User? user;
  final Color themeColor;
  final bool isSyncing;
  final VoidCallback onSync;
  final VoidCallback onProfileOpen;

  const DrawerHeaderWidget({
    super.key,
    required this.user,
    required this.themeColor,
    required this.isSyncing,
    required this.onSync,
    required this.onProfileOpen,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 48, 16, 20),
      decoration: BoxDecoration(
        color: themeColor,
        image: DecorationImage(
          image: const NetworkImage('https://images.unsplash.com/photo-1557683316-973673baf926?q=80&w=800&auto=format&fit=crop'),
          fit: BoxFit.cover,
          colorFilter: ColorFilter.mode(
            themeColor.withOpacity(0.75),
            BlendMode.srcOver,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: themeColor.withOpacity(0.4),
            blurRadius: 12,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 🌟 LOGOTIPO / TÍTULO DA APP NA GAVETA
              Row(
                children: [
                  const Icon(Icons.menu_book_rounded, color: Colors.white, size: 24),
                  const SizedBox(width: 8),
                  Text(
                    'Caderno Digital',
                    style: GoogleFonts.lora(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              Row(
                children: [
                  _buildHeaderActionButton(
                    tooltip: isSyncing ? 'A sincronizar...' : 'Sincronizar Nuvem',
                    customChild: isSyncing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 20),
                    onTap: isSyncing ? null : onSync,
                  ),
                  const SizedBox(width: 8),
                  _buildHeaderActionButton(
                    tooltip: 'Meu Perfil e Dados',
                    customChild: const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 20),
                    onTap: onProfileOpen,
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            user?.name ?? 'Estudante',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 19,
              color: Colors.white,
              letterSpacing: 0.3,
              shadows: [Shadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))],
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              Icon(Icons.alternate_email_rounded, size: 13, color: Colors.white.withOpacity(0.9)),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  user?.email ?? 'sem_email@caderno.app',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    color: Colors.white.withOpacity(0.9),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderActionButton({required String tooltip, required Widget customChild, VoidCallback? onTap}) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.2),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(10.0),
            child: customChild,
          ),
        ),
      ),
    );
  }
}
