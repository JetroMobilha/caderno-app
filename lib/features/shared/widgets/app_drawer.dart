import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:caderno_digital_app/core/theme/app_colors.dart';
import 'package:caderno_digital_app/core/network/api_service.dart';
import 'package:caderno_digital_app/features/auth/controllers/auth_controller.dart';
import 'package:caderno_digital_app/features/auth/models/user_model.dart';
import 'package:caderno_digital_app/features/auth/views/profile_screen.dart';
import 'package:caderno_digital_app/features/auth/views/login_screen.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';
import 'package:caderno_digital_app/features/notebooks/controllers/notebooks_controller.dart';

import '../../marketplace/views/marketplace_screen.dart';

class AppDrawer extends ConsumerStatefulWidget {
  const AppDrawer({super.key});

  @override
  ConsumerState<AppDrawer> createState() => _AppDrawerState();
}

class _AppDrawerState extends ConsumerState<AppDrawer> {
  bool _isSyncing = false;

  // =========================================================================
  // 🧭 TRADUTOR DE ÍCONES (24 Categorias Híbridas)
  // =========================================================================
  IconData _getIconData(String? iconName) {
    switch (iconName) {
      case 'school': return Icons.school_rounded;
      case 'science': return Icons.science_rounded;
      case 'math': return Icons.calculate_rounded;
      case 'language': return Icons.language_rounded;
      case 'history': return Icons.history_edu_rounded;
      case 'law': return Icons.gavel_rounded;
      case 'health': return Icons.medical_services_rounded;
      case 'psychology': return Icons.psychology_rounded;
      case 'business': return Icons.business_center_rounded;
      case 'analytics': return Icons.analytics_rounded;
      case 'workspaces': return Icons.workspaces_rounded;
      case 'team': return Icons.groups_rounded;
      case 'presentation': return Icons.present_to_all_rounded;
      case 'security': return Icons.security_rounded;
      case 'computer': return Icons.computer_rounded;
      case 'code': return Icons.code_rounded;
      case 'idea': return Icons.lightbulb_rounded;
      case 'art': return Icons.palette_rounded;
      case 'music': return Icons.music_note_rounded;
      case 'calendar': return Icons.calendar_month_rounded;
      case 'notes': return Icons.sticky_note_2_rounded;
      case 'folder': return Icons.folder_special_rounded;
      case 'sport': return Icons.sports_basketball_rounded;
      case 'book':
      default: return Icons.menu_book_rounded;
    }
  }

  // =========================================================================
  // ☁️/🌐 SINCRONIZAÇÃO OU REFRESH (Híbrido Mobile vs Web)
  // =========================================================================
  Future<void> _handleManualSync() async {
    setState(() => _isSyncing = true);

    final subNotifier = ref.read(subjectsProvider.notifier);
    final notebooksNotifier = ref.read(notebooksProvider.notifier);
    final snackbarMessenger = ScaffoldMessenger.of(context);

    try {
      // Ciclo completo de Push & Pull (SQLite <-> Nuvem)
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
    } catch (e, stackTrace) {
      debugPrint('🚨 [SYNC/REFRESH] ERRO FATAL: $e');
      debugPrint('🚨 [RASTRO]: $stackTrace');

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
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final rootNavigator = Navigator.of(context, rootNavigator: true);
              final authCtrl = ref.read(authProvider);
              
              // 🚀 O logout agora trata da limpeza de ficheiros, SQLite e Notifiers internamente
              await authCtrl.logout();
              
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
        content: Text('A disciplina "${subject.name}" e os cadernos serão apagados.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              final subNotifier = ref.read(subjectsProvider.notifier);
              final drawerNavigator = Navigator.of(context);
              final snackBarMessenger = ScaffoldMessenger.of(context);

              Navigator.pop(ctx);
              try {
                await subNotifier.deleteSubject(subject);
                drawerNavigator.pop();
                snackBarMessenger.showSnackBar(
                    const SnackBar(content: Text('Disciplina eliminada! 🗑️'), backgroundColor: Colors.green, duration: Duration(seconds: 2))
                );
              } catch (e) {
                snackBarMessenger.showSnackBar(
                    SnackBar(content: Text('Erro interno no controlador: $e'), backgroundColor: Colors.redAccent)
                );
              }
            },
            child: const Text('Apagar Tudo', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
          // =========================================================================
          // 🎨 COMPONENTE DO HEADER MODERNO DO UTILIZADOR
          // =========================================================================
          _buildModernUserHeader(context, user, dynamicColor, userAvatarProvider),

          // Título da Secção de Disciplinas
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('AS MINHAS DISCIPLINAS', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)),
                Tooltip(
                  message: 'Criar Nova Disciplina',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(8),
                    onTap: () {
                      if (user != null) _showSubjectModal(context, ref, user, isEditing: false, themeColor: dynamicColor);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(color: dynamicColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                      child: Icon(Icons.add_rounded, color: dynamicColor, size: 18),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Lista de Disciplinas
          Expanded(
            child: Column(
              children: [
                Expanded(
                  child: subjectsList.isEmpty
                      ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Text(
                        'Nenhuma disciplina criada.\nClica no (+) em cima para começares!',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
                      ),
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
                                      if (user != null) _showSubjectModal(context, ref, user, isEditing: true, subjectToEdit: sub, themeColor: dynamicColor);
                                    } else if (value == 'delete') {
                                      _confirmDeleteSubject(context, sub);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: dynamicColor), const SizedBox(width: 8), Text('Editar', style: GoogleFonts.inter(fontSize: 13))])),
                                    PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), const SizedBox(width: 8), Text('Apagar', style: GoogleFonts.inter(fontSize: 13, color: Colors.redAccent))])),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () {
                              ref.read(activeSubjectProvider.notifier).setSubject(sub);
                              Navigator.pop(context);
                            },
                          ),
                        ),
                      );
                    },
                  ),
                ),

                const Divider(height: 1, color: Colors.black12),

                // 🤝 ABA FIXA INDUSTRIAL: Partilhados Comigo
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Material(
                    color: Colors.transparent,
                    child: ListTile(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      tileColor: activeSubject?.id == -1 ? dynamicColor.withOpacity(0.12) : null,
                      leading: CircleAvatar(
                        radius: 16,
                        backgroundColor: activeSubject?.id == -1 ? dynamicColor.withOpacity(0.2) : Colors.grey.withOpacity(0.15),
                        child: Icon(Icons.groups_rounded, color: activeSubject?.id == -1 ? dynamicColor : Colors.black54, size: 18),
                      ),
                      title: Text(
                        'Partilhados Comigo',
                        style: GoogleFonts.inter(
                          fontWeight: activeSubject?.id == -1 ? FontWeight.bold : FontWeight.w500,
                          color: activeSubject?.id == -1 ? dynamicColor : AppColors.textDark,
                        ),
                      ),
                      onTap: () {
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
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.storefront_rounded, color: Color(0xFFD81B60)),
                  title: Text('Loja de Cadernos', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const MarketplaceScreen()));
                  },
                ),
              ],
            ),
          ),

          // =========================================================================
          // 🚪 RODAPÉ LIMPO (APENAS TERMINAR SESSÃO)
          // =========================================================================
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

  // =========================================================================
  // 🎨 COMPONENTE DO HEADER MODERNO DO UTILIZADOR (COM IMAGEM DE FUNDO)
  // =========================================================================
  Widget _buildModernUserHeader(BuildContext context, User? user, Color themeColor, ImageProvider? avatarProvider) {
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
          // ROW SUPERIOR: Avatar + Botões de Ação
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2.5),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 8, offset: const Offset(0, 3))
                  ],
                ),
                child: CircleAvatar(
                  radius: 28,
                  backgroundColor: Colors.white,
                  backgroundImage: avatarProvider,
                  child: avatarProvider == null
                      ? Icon(Icons.person_rounded, color: themeColor, size: 32)
                      : null,
                ),
              ),

              // BOTÕES DE AÇÃO INTERATIVOS
              Row(
                children: [
                  // 1. Botão de Sincronizar/Atualizar (Adaptado para Web e Mobile)
                  _buildHeaderActionButton(
                    tooltip: _isSyncing
                        ? 'A sincronizar...'
                        : 'Sincronizar Nuvem',
                    customChild: _isSyncing
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                        : const Icon(Icons.cloud_sync_rounded, color: Colors.white, size: 20),
                    onTap: _isSyncing ? null : _handleManualSync,
                  ),
                  const SizedBox(width: 8),
                  // 2. Botão do Perfil do Utilizador
                  _buildHeaderActionButton(
                    tooltip: 'Meu Perfil e Dados',
                    customChild: const Icon(Icons.manage_accounts_rounded, color: Colors.white, size: 20),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ROW INFERIOR: Nome e Email do Estudante
          Text(
            user?.name ?? 'Estudante',
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

  void _showSubjectModal(BuildContext context, WidgetRef ref, User user, {required bool isEditing, Subject? subjectToEdit, required Color themeColor}) {
    final TextEditingController nameController = TextEditingController(text: isEditing ? subjectToEdit!.name : '');
    final formKey = GlobalKey<FormState>();

    final List<String> availableColors = [
      '#0F4C5C', '#1F4E79', '#3F51B5', '#6C3483',
      '#9B59B6', '#D81B60', '#E91E63', '#B03A2E',
      '#E67E22', '#D35400', '#F1C40F', '#1E8449',
      '#27AE60', '#16A085', '#4E342E', '#607D8B',
    ];
    String pickedColorHex = isEditing ? subjectToEdit!.color : availableColors[0];

    final List<Map<String, dynamic>> availableIcons = [
      {'name': 'book', 'icon': Icons.menu_book_rounded},
      {'name': 'school', 'icon': Icons.school_rounded},
      {'name': 'science', 'icon': Icons.science_rounded},
      {'name': 'math', 'icon': Icons.calculate_rounded},
      {'name': 'language', 'icon': Icons.language_rounded},
      {'name': 'history', 'icon': Icons.history_edu_rounded},
      {'name': 'law', 'icon': Icons.gavel_rounded},
      {'name': 'health', 'icon': Icons.medical_services_rounded},
      {'name': 'psychology', 'icon': Icons.psychology_rounded},
      {'name': 'business', 'icon': Icons.business_center_rounded},
      {'name': 'analytics', 'icon': Icons.analytics_rounded},
      {'name': 'workspaces', 'icon': Icons.workspaces_rounded},
      {'name': 'team', 'icon': Icons.groups_rounded},
      {'name': 'presentation', 'icon': Icons.present_to_all_rounded},
      {'name': 'security', 'icon': Icons.security_rounded},
      {'name': 'computer', 'icon': Icons.computer_rounded},
      {'name': 'code', 'icon': Icons.code_rounded},
      {'name': 'idea', 'icon': Icons.lightbulb_rounded},
      {'name': 'art', 'icon': Icons.palette_rounded},
      {'name': 'music', 'icon': Icons.music_note_rounded},
      {'name': 'calendar', 'icon': Icons.calendar_month_rounded},
      {'name': 'notes', 'icon': Icons.sticky_note_2_rounded},
      {'name': 'folder', 'icon': Icons.folder_special_rounded},
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
                    Icon(isEditing ? Icons.edit_rounded : Icons.library_add_rounded, color: themeColor),
                    const SizedBox(width: 10),
                    Text(isEditing ? 'Editar Matéria' : 'Nova Disciplina', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: themeColor)),
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
                            hintText: 'Ex: Finanças ou Química...',
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: themeColor, width: 1.5)),
                          ),
                          validator: (value) => value == null || value.trim().isEmpty ? 'Insira um nome válido' : null,
                        ),
                        const SizedBox(height: 24),
                        Text('Ícone Representativo (24 Opções)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
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
                                  color: isSelected ? themeColor.withOpacity(0.15) : Colors.transparent,
                                  border: isSelected ? Border.all(color: themeColor, width: 2) : Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(item['icon'] as IconData, color: isSelected ? themeColor : Colors.grey, size: 24),
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24),
                        Text('Cor de Destaque (16 Tons)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
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
                      backgroundColor: themeColor,
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
                            userId: user.id ?? 1,
                            icon: pickedIconName,
                            syncedWithCloud: 0,
                          );
                          await subNotifier.addSubject(novaDisciplina).then((s) {
                            if (s != null) activeNotifier.setSubject(s);
                          });
                        }

                        if (contextDialog.mounted) Navigator.pop(contextDialog);
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