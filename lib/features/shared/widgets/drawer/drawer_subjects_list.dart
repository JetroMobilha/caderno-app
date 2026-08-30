import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/core/theme/app_colors.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';
import 'package:caderno_digital_app/features/subjects/utils/subject_utils.dart';
import 'package:caderno_digital_app/features/subjects/views/subjects_list_screen.dart';
import 'package:caderno_digital_app/features/trash/views/trash_screen.dart';

class DrawerSubjectsList extends ConsumerWidget {
  final List<Subject> subjects;
  final Subject? activeSubject;
  final Color dynamicColor;
  final Function(Subject) onSubjectTap;
  final Function(Subject) onSubjectEdit;
  final Function(Subject) onSubjectDelete;
  final VoidCallback onAddSubject;
  final VoidCallback onMarketplaceTap;
  final VoidCallback onSharedTap;

  const DrawerSubjectsList({
    super.key,
    required this.subjects,
    required this.activeSubject,
    required this.dynamicColor,
    required this.onSubjectTap,
    required this.onSubjectEdit,
    required this.onSubjectDelete,
    required this.onAddSubject,
    required this.onMarketplaceTap,
    required this.onSharedTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final uiSettings = ref.watch(subjectsUiProvider);
    final showArchived = uiSettings.showArchivedInDrawer;

    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Título da Secção
          Padding(
            padding: const EdgeInsets.only(left: 16, right: 8, top: 12, bottom: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  showArchived ? 'PASTAS ARQUIVADAS' : 'AS MINHAS PASTAS', 
                  style: GoogleFonts.inter(
                    fontSize: 11, 
                    fontWeight: FontWeight.bold, 
                    color: showArchived ? Colors.brown : AppColors.textMuted, 
                    letterSpacing: 1.2
                  )
                ),
                Row(
                  children: [
                    Tooltip(
                      message: 'Ver Lixeira',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () {
                          Navigator.pop(context);
                          Navigator.push(context, MaterialPageRoute(builder: (context) => TrashScreen(initialTabIndex: 0)));
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                          child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 18),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Tooltip(
                      message: showArchived ? 'Ver Pastas Ativas' : 'Ver Pastas Arquivadas',
                      child: InkWell(
                        borderRadius: BorderRadius.circular(8),
                        onTap: () => ref.read(subjectsUiProvider.notifier).toggleDrawerArchive(),
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: showArchived ? Colors.brown.withOpacity(0.12) : Colors.blueGrey.withOpacity(0.08), 
                            borderRadius: BorderRadius.circular(8)
                          ),
                          child: Icon(
                            showArchived ? Icons.inventory_2_rounded : Icons.archive_outlined, 
                            color: showArchived ? Colors.brown : Colors.blueGrey, 
                            size: 18
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    if (!showArchived)
                      Tooltip(
                        message: 'Criar Nova Pasta',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(8),
                          onTap: onAddSubject,
                          child: Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(color: dynamicColor.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                            child: Icon(Icons.add_rounded, color: dynamicColor, size: 18),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Lista Principal
          Expanded(
            child: _buildList(context, ref, showArchived),
          ),

          const Divider(height: 1, color: Colors.black12),

          // Partilhados Comigo
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
                onTap: onSharedTap,
              ),
            ),
          ),

          ListTile(
            leading: const Icon(Icons.storefront_rounded, color: Color(0xFFD81B60)),
            title: Text('Loja de Cadernos', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            onTap: onMarketplaceTap,
          ),
        ],
      ),
    );
  }

  Widget _buildList(BuildContext context, WidgetRef ref, bool showArchived) {
    final filteredSubjects = subjects.where((s) => s.isArchived == showArchived).toList();
    filteredSubjects.sort((a, b) => a.name.compareTo(b.name));

    if (filteredSubjects.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(
            showArchived 
                ? 'Nenhuma pasta arquivada.' 
                : 'Nenhuma pasta ativa.\nClica no (+) em cima para começares!',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: AppColors.textMuted, fontSize: 13),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 4),
      itemCount: filteredSubjects.length,
      itemBuilder: (context, index) {
        final sub = filteredSubjects[index];
        final bool isSelected = activeSubject?.id == sub.id && sub.id != null;
        Color subColor = AppColors.primary;
        try {
          subColor = Color(int.parse(sub.color.replaceFirst('#', '0xFF')));
        } catch (_) {}

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
                child: Icon(SubjectUtils.getSubjectIcon(sub.icon), color: subColor, size: 18),
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      sub.name,
                      style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: isSelected ? subColor : AppColors.textDark),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              trailing: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: AppColors.textMuted),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                color: AppColors.paper,
                onSelected: (value) async {
                  if (value == 'edit') {
                    onSubjectEdit(sub);
                  } else if (value == 'delete') {
                    onSubjectDelete(sub);
                  } else if (value == 'clone') {
                    await ref.read(subjectsProvider.notifier).duplicateSubject(sub);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Pasta e cadernos clonados com sucesso! 📑')),
                      );
                    }
                  } else if (value == 'archive') {
                    await ref.read(subjectsProvider.notifier).updateSubject(sub.copyWith(isArchived: !sub.isArchived));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(sub.isArchived ? 'Pasta desarquivada! 📂' : 'Pasta enviada para o arquivo! 📥')),
                      );
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit', 
                    child: Row(children: [Icon(Icons.edit, size: 18, color: dynamicColor), const SizedBox(width: 8), const Text('Editar', style: TextStyle(fontSize: 13))])
                  ),
                  PopupMenuItem(
                    value: 'clone', 
                    child: Row(children: [const Icon(Icons.copy_rounded, size: 18, color: Colors.teal), const SizedBox(width: 8), const Text('Clonar', style: TextStyle(fontSize: 13))])
                  ),
                  PopupMenuItem(
                    value: 'archive', 
                    child: Row(children: [
                      Icon(sub.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 18, color: Colors.brown), 
                      const SizedBox(width: 8), 
                      Text(sub.isArchived ? 'Desarquivar' : 'Enviar para o arquivo', style: const TextStyle(fontSize: 13))
                    ])
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete', 
                    child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), const SizedBox(width: 8), Text('Apagar', style: TextStyle(fontSize: 13, color: Colors.redAccent))])
                  ),
                ],
              ),
              onTap: () => onSubjectTap(sub),
            ),
          ),
        );
      },
    );
  }
}
