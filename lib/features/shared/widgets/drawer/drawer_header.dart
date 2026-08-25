import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/features/auth/models/user_model.dart';
import 'package:caderno_digital_app/core/theme/app_profile.dart';

class DrawerHeaderWidget extends StatelessWidget {
  final User? user;
  final Color themeColor;
  final AppProfile activeProfile;
  final bool isSyncing;
  final VoidCallback onSync;
  final VoidCallback onProfileOpen;
  final Function(AppProfile) onProfileChanged;

  const DrawerHeaderWidget({
    super.key,
    required this.user,
    required this.themeColor,
    required this.activeProfile,
    required this.isSyncing,
    required this.onSync,
    required this.onProfileOpen,
    required this.onProfileChanged,
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
              _buildProfileSwitcher(context, activeProfile),
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
            user?.name ?? (activeProfile == AppProfile.academico ? 'Estudante' : 'Profissional'),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.lora(
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

  Widget _buildProfileSwitcher(BuildContext context, AppProfile active) {
    return PopupMenuButton<AppProfile>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: onProfileChanged,
      itemBuilder: (context) => AppProfile.values.map((p) => PopupMenuItem(
        value: p,
        child: Row(
          children: [
            Icon(p.icon, size: 20, color: p == active ? Theme.of(context).primaryColor : Colors.grey),
            const SizedBox(width: 12),
            Text(p.name, style: TextStyle(fontWeight: p == active ? FontWeight.bold : FontWeight.normal)),
          ],
        ),
      )).toList(),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: Colors.white.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            Icon(active.icon, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Text(
              active.name.split(' ').first,
              style: GoogleFonts.inter(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
            const Icon(Icons.arrow_drop_down, color: Colors.white, size: 18),
          ],
        ),
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
