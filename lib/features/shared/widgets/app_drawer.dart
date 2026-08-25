import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:caderno_digital_app/core/theme/app_colors.dart';
import 'package:caderno_digital_app/features/auth/controllers/auth_controller.dart';
import 'package:caderno_digital_app/features/auth/views/profile_screen.dart';
import 'package:caderno_digital_app/features/auth/views/login_screen.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';
import 'package:caderno_digital_app/core/theme/app_profile.dart';
import 'package:caderno_digital_app/features/agenda/screens/quick_notes_screen.dart';
import 'package:caderno_digital_app/features/marketplace/views/marketplace_screen.dart';

// Modular Components
import 'drawer/drawer_header.dart';
import 'drawer/drawer_subjects_list.dart';
import '../../subjects/widgets/subject_dialogs.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _isSyncing = false;

  Future<void> _handleManualSync() async {
    setState(() => _isSyncing = true);
    final subNotifier = ref.read(subjectsProvider.notifier);
    final snackbarMessenger = ScaffoldMessenger.of(context);

    try {
      await subNotifier.syncManuallyWithCloud();
      if (mounted) {
        snackbarMessenger.showSnackBar(
          const SnackBar(
            content: Text('Sincronização concluída! ✨'),
            backgroundColor: Color(0xFF27AE60),
            duration: Duration(seconds: 2),
          )
        );
      }
    } catch (e) {
      if (mounted) {
        snackbarMessenger.showSnackBar(
          SnackBar(
            content: Text(kIsWeb ? 'Falha ao atualizar dados da rede.' : 'Falha ao sincronizar. Verifica a internet.'),
            backgroundColor: Colors.redAccent
          )
        );
      }
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  void _confirmLogout(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Terminar Sessão?', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: AppColors.textDark)),
        content: Text(
          'Tens a certeza? O teu conteúdo local será limpo por segurança.',
          style: GoogleFonts.inter(color: AppColors.textMuted),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted))),
          Consumer(
            builder: (context, ref, child) {
              final isLoading = ref.watch(authProvider).isLoading;
              return ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
                onPressed: isLoading ? null : () async {
                  final rootNavigator = Navigator.of(context, rootNavigator: true);
                  await ref.read(authProvider.notifier).logout();
                  rootNavigator.pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const LoginScreen()),
                    (route) => false
                  );
                },
                child: isLoading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Sair', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              );
            }
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).currentUser;
    final subjectsList = ref.watch(subjectsProvider);
    final activeSubject = ref.watch(activeSubjectProvider);
    final dynamicColor = Theme.of(context).colorScheme.primary;

    return Drawer(
      backgroundColor: AppColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          DrawerHeaderWidget(
            user: user,
            themeColor: dynamicColor,
            isSyncing: _isSyncing,
            onSync: _handleManualSync,
            onProfileOpen: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
          ),
          DrawerSubjectsList(
            subjects: subjectsList,
            activeSubject: activeSubject,
            dynamicColor: dynamicColor,
            onSubjectTap: (sub) {
              ref.read(activeSubjectProvider.notifier).setSubject(sub);
              Navigator.pop(context);
            },
            onSubjectEdit: (sub) {
              if (user != null) {
                SubjectDialogs.showSubjectModal(context, ref, user, isEditing: true, subjectToEdit: sub, themeColor: dynamicColor);
              }
            },
            onSubjectDelete: (sub) => SubjectDialogs.confirmDeleteSubject(context, ref, sub),
            onAddSubject: () {
              if (user != null) {
                SubjectDialogs.showSubjectModal(context, ref, user, isEditing: false, themeColor: dynamicColor);
              }
            },
            onMarketplaceTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen()));
            },
            onAgendaTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const QuickNotesScreen()));
            },
            onSharedTap: () {
              Navigator.pop(context);
              final virtualSharedSubject = Subject(
                id: -1,
                userId: 0,
                name: 'Partilhados Comigo',
                color: '#0F4C5C',
                icon: 'team',
              );
              ref.read(activeSubjectProvider.notifier).setSubject(virtualSharedSubject);
            },
          ),
          const Divider(height: 1, color: Colors.black12),
          Material(
            color: Colors.black.withOpacity(0.02),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                dense: true,
                leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                title: Text('Terminar Sessão', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                onTap: () => _confirmLogout(context),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}
