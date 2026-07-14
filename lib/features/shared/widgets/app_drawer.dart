import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/network/api_service.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../auth/models/user_model.dart';
import '../../auth/views/profile_screen.dart';
import '../../auth/views/login_screen.dart';
import '../../subjects/controllers/subjects_controller.dart';
import '../../subjects/models/subject_model.dart';
import '../../notebooks/controllers/notebooks_controller.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _isSyncing = false;

  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'science': return Icons.science_rounded;
      case 'math': return Icons.calculate_rounded;
      case 'language': return Icons.language_rounded;
      case 'history': return Icons.history_edu_rounded;
      case 'art': return Icons.palette_rounded;
      case 'computer': return Icons.computer_rounded;
      case 'sport': return Icons.sports_basketball_rounded;
      case 'book':
      default: return Icons.menu_book_rounded;
    }
  }

  Future<void> _handleManualSync() async {
    setState(() => _isSyncing = true);
    try {
      // 🚀 Chama a Sincronização centralizada e blindada
      await ref.read(subjectsProvider.notifier).syncManuallyWithCloud();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Sincronização concluída! ☁️✨'), backgroundColor: Color(0xFF27AE60)));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao sincronizar. Verifica a internet.'), backgroundColor: Colors.redAccent));
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
        content: Text('Tens a certeza que desejas sair? O teu conteúdo local será limpo por segurança.', style: GoogleFonts.inter(color: AppColors.textMuted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar', style: TextStyle(color: AppColors.textMuted))),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              // 🚀 NAVEGAÇÃO SUPREMA (Sem crashes!)
              // 1. Capturamos a rota "raíz" da app ANTES de qualquer await
              final rootNavigator = Navigator.of(context, rootNavigator: true);
              final authCtrl = ref.read(authProvider);

              // 2. Apagamos a Base de Dados
              await authCtrl.logout();

              // 3. Forçamos a App a ir para o Login destruindo TUDO pelo caminho (Diálogo + Gaveta)
              rootNavigator.pushAndRemoveUntil(
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                      (route) => false
              );
            },
            child: const Text('Sair', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteSubject(BuildContext context, Subject subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('Apagar Disciplina?', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text('A disciplina "${subject.name}" e todos os seus cadernos serão eliminados do dispositivo.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final subNotifier = ref.read(subjectsProvider.notifier);

              Navigator.pop(ctx); // Fecha modal
              if (context.mounted) Navigator.pop(context); // Fecha Gaveta

              await subNotifier.deleteSubject(subject);
            },
            child: const Text('Apagar Tudo', style: TextStyle(color: Colors.white)),
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

    ImageProvider? userAvatarProvider;
    if (user?.avatar != null && user!.avatar!.isNotEmpty) {
      if (!user.avatar!.contains('C:/') && !user.avatar!.startsWith('file://')) {
        final avatarUrl = user.avatar!.startsWith('http') ? user.avatar! : "${ApiService.baseUrlImagem}${user.avatar!}";
        userAvatarProvider = NetworkImage(avatarUrl);
      }
    }

    return Drawer(
      backgroundColor: AppColors.paper,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () {
              Navigator.pop(context);
              Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
            },
            child: UserAccountsDrawerHeader(
              decoration: const BoxDecoration(color: AppColors.primary),
              accountName: Text(user?.name ?? 'Estudante', style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 18)),
              accountEmail: Row(
                children: [
                  Expanded(child: Text(user?.email ?? '', style: GoogleFonts.inter(fontSize: 12, color: Colors.white70))),
                  const Icon(Icons.edit_outlined, size: 14, color: Colors.white70),
                  const SizedBox(width: 4),
                  Text('Editar', style: GoogleFonts.inter(fontSize: 11, color: Colors.white70)),
                ],
              ),
              currentAccountPicture: CircleAvatar(
                backgroundColor: Colors.white,
                backgroundImage: userAvatarProvider,
                child: userAvatarProvider == null ? const Icon(Icons.person, color: AppColors.primary, size: 40) : null,
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 8, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('AS MINHAS DISCIPLINAS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
                Tooltip(
                  message: 'Criar Nova Disciplina',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (user != null) _showSubjectModal(context, ref, user, isEditing: false);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.add_rounded, color: AppColors.primary, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),

          Expanded(
            child: subjectsList.isEmpty
                ? Center(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Text('Nenhuma disciplina criada.\nClica no (+) em cima para começares!', textAlign: TextAlign.center, style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13)),
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.only(top: 4),
              itemCount: subjectsList.length,
              itemBuilder: (context, index) {
                final sub = subjectsList[index];
                final bool isSelected = activeSubject?.id == sub.id && sub.id != null;

                Color subColor = AppColors.primary;
                try { subColor = Color(int.parse(sub.color.replaceFirst('#', '0xFF'))); } catch (_) {}

                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: isSelected ? BorderSide(color: subColor.withOpacity(0.4), width: 1.5) : BorderSide.none,
                      ),
                      tileColor: isSelected ? subColor.withOpacity(0.12) : null,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: subColor.withOpacity(0.2),
                        child: Icon(_getIconData(sub.icon), color: subColor, size: 18),
                      ),
                      title: Text(
                        sub.name,
                        style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? subColor : AppColors.textDark),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isSelected) Icon(Icons.check_circle_rounded, color: subColor, size: 18),
                          PopupMenuButton<String>(
                            icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            color: AppColors.paper,
                            onSelected: (value) {
                              if (value == 'edit') {
                                if (user != null) _showSubjectModal(context, ref, user, isEditing: true, subjectToEdit: sub);
                              } else if (value == 'delete') {
                                _confirmDeleteSubject(context, sub);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'edit', child: Row(children: [const Icon(Icons.edit, size: 18, color: AppColors.primary), const SizedBox(width: 8), Text('Editar', style: GoogleFonts.inter(fontSize: 13))])),
                              PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), const SizedBox(width: 8), Text('Apagar', style: GoogleFonts.inter(fontSize: 13, color: Colors.redAccent))])),
                            ],
                          ),
                        ],
                      ),
                      onTap: () {
                        final activeSubNotifier = ref.read(activeSubjectProvider.notifier);
                        final nbNotifier = ref.read(notebooksProvider.notifier);
                        Navigator.pop(context);
                        activeSubNotifier.setSubject(sub);
                        nbNotifier.loadNotebooks(sub.id ?? 0, subjectServerId: sub.serverId);
                      },
                    ),
                  ),
                );
              },
            ),
          ),

          const Divider(height: 1, color: Colors.black12),
          Material(
            color: Colors.black.withOpacity(0.02),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Column(
                children: [
                  ListTile(
                    dense: true,
                    leading: _isSyncing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary))
                        : const Icon(Icons.cloud_sync_outlined, color: AppColors.primary, size: 22),
                    title: Text(_isSyncing ? 'A sincronizar...' : 'Sincronizar Nuvem', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.primary)),
                    onTap: _isSyncing ? null : _handleManualSync,
                  ),
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.logout_rounded, color: Colors.redAccent, size: 22),
                    title: Text('Terminar Sessão', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.redAccent)),
                    onTap: () => _confirmLogout(context),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _showSubjectModal(BuildContext context, WidgetRef ref, User user, {required bool isEditing, Subject? subjectToEdit}) {
    final TextEditingController nameController = TextEditingController(text: isEditing ? subjectToEdit!.name : '');
    final formKey = GlobalKey<FormState>();

    final List<String> availableColors = ['#0F4C5C', '#2C3E50', '#1E8449', '#D35400', '#6C3483', '#B03A2E'];
    String pickedColorHex = isEditing ? subjectToEdit!.color : availableColors[0];

    final List<Map<String, dynamic>> availableIcons = [
      {'name': 'book', 'icon': Icons.menu_book_rounded},
      {'name': 'science', 'icon': Icons.science_rounded},
      {'name': 'math', 'icon': Icons.calculate_rounded},
      {'name': 'language', 'icon': Icons.language_rounded},
      {'name': 'history', 'icon': Icons.history_edu_rounded},
      {'name': 'art', 'icon': Icons.palette_rounded},
      {'name': 'computer', 'icon': Icons.computer_rounded},
      {'name': 'sport', 'icon': Icons.sports_basketball_rounded},
    ];
    String pickedIconName = isEditing ? (subjectToEdit!.icon ?? 'book') : 'book';

    showDialog(
      context: context,
      builder: (contextDialog) {
        return StatefulBuilder(
            builder: (context, setModalState) {
              return AlertDialog(
                backgroundColor: AppColors.paper,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                title: Row(
                  children: [
                    Icon(isEditing ? Icons.edit_rounded : Icons.library_add_rounded, color: AppColors.primary),
                    const SizedBox(width: 10),
                    Text(isEditing ? 'Editar Matéria' : 'Nova Disciplina', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: AppColors.primary)),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nome da Matéria', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: nameController,
                          autofocus: !isEditing,
                          textCapitalization: TextCapitalization.words,
                          decoration: InputDecoration(
                            hintText: 'Ex: Matemática...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: AppColors.primary, width: 1.5)),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Insira um nome válido' : null,
                        ),
                        const SizedBox(height: 24),
                        Text('Ícone', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: availableIcons.map((item) {
                            final isSelected = pickedIconName == item['name'];
                            return GestureDetector(
                              onTap: () => setModalState(() => pickedIconName = item['name'] as String),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: isSelected ? AppColors.primary.withOpacity(0.1) : Colors.transparent,
                                  border: isSelected ? Border.all(color: AppColors.primary, width: 2) : Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(item['icon'] as IconData, color: isSelected ? AppColors.primary : Colors.grey, size: 24),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Text('Cor de Destaque', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: availableColors.map((hex) {
                            final isSelected = pickedColorHex == hex;
                            final colorValue = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                            return GestureDetector(
                              onTap: () => setModalState(() => pickedColorHex = hex),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: isSelected ? 36 : 30,
                                height: isSelected ? 36 : 30,
                                decoration: BoxDecoration(
                                  color: colorValue,
                                  shape: BoxShape.circle,
                                  border: isSelected ? Border.all(color: AppColors.paper, width: 2) : null,
                                  boxShadow: isSelected ? [BoxShadow(color: colorValue.withOpacity(0.5), blurRadius: 8, offset: const Offset(0, 3))] : null,
                                ),
                                child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  ),
                ),
                actionsPadding: const EdgeInsets.only(right: 20, bottom: 20),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(contextDialog),
                    child: Text('Cancelar', style: GoogleFonts.inter(color: AppColors.textMuted, fontWeight: FontWeight.w600)),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                    ),
                    onPressed: () async {
                      if (formKey.currentState!.validate()) {
                        final subNotifier = ref.read(subjectsProvider.notifier);
                        final activeNotifier = ref.read(activeSubjectProvider.notifier);
                        final currentActive = ref.read(activeSubjectProvider);

                        if (isEditing) {
                          final disciplinaEditada = subjectToEdit!.copyWith(
                            name: nameController.text.trim(),
                            color: pickedColorHex,
                            icon: pickedIconName,
                          );
                          await subNotifier.updateSubject(disciplinaEditada);
                          if (currentActive?.id == subjectToEdit.id) {
                            activeNotifier.setSubject(disciplinaEditada);
                          }
                        } else {
                          final novaDisciplina = Subject(
                            name: nameController.text.trim(),
                            color: pickedColorHex,
                            userId: user.serverId,
                            icon: pickedIconName,
                            syncedWithCloud: 0,
                          );
                          await subNotifier.addSubject(novaDisciplina);
                          activeNotifier.setSubject(novaDisciplina);
                        }

                        // Fecha o Modal (sem forçar contextos destruídos)
                        Navigator.pop(contextDialog);
                      }
                    },
                    child: Text(isEditing ? 'Atualizar' : 'Criar', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                ],
              );
            }
        );
      },
    );
  }
}