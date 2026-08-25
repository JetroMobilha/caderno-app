import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/core/theme/app_colors.dart';
import 'package:caderno_digital_app/core/theme/app_profile.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';
import 'package:caderno_digital_app/features/subjects/utils/subject_utils.dart';

class DrawerSubjectsList extends StatelessWidget {
  final List<Subject> subjects;
  final Subject? activeSubject;
  final AppProfile activeProfile;
  final Color dynamicColor;
  final Function(Subject) onSubjectTap;
  final Function(Subject) onSubjectEdit;
  final Function(Subject) onSubjectDelete;
  final VoidCallback onAddSubject;
  final VoidCallback onMarketplaceTap;
  final VoidCallback onAgendaTap;
  final VoidCallback onSharedTap;

  const DrawerSubjectsList({
    super.key,
    required this.subjects,
    required this.activeSubject,
    required this.activeProfile,
    required this.dynamicColor,
    required this.onSubjectTap,
    required this.onSubjectEdit,
    required this.onSubjectDelete,
    required this.onAddSubject,
    required this.onMarketplaceTap,
    required this.onAgendaTap,
    required this.onSharedTap,
  });

  @override
  Widget build(BuildContext context) {
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
                  activeProfile == AppProfile.academico ? 'AS MINHAS DISCIPLINAS' : 'OS MEUS PROJETOS', 
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textMuted, letterSpacing: 1.2)
                ),
                Tooltip(
                  message: 'Criar Nova Disciplina',
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
          ),

          // Lista Principal
          Expanded(
            child: subjects.isEmpty
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
                    itemCount: subjects.length,
                    itemBuilder: (context, index) {
                      final sub = subjects[index];
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
                              child: Icon(SubjectUtils.getSubjectIcon(sub.icon), color: subColor, size: 18),
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
                                      onSubjectEdit(sub);
                                    } else if (value == 'delete') {
                                      onSubjectDelete(sub);
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: dynamicColor), const SizedBox(width: 8), Text('Editar', style: GoogleFonts.inter(fontSize: 13))])),
                                    PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), const SizedBox(width: 8), Text('Apagar', style: GoogleFonts.inter(fontSize: 13, color: Colors.redAccent))])),
                                  ],
                                ),
                              ],
                            ),
                            onTap: () => onSubjectTap(sub),
                          ),
                        ),
                      );
                    },
                  ),
          ),

          const Divider(height: 1, color: Colors.black12),

          // Productivity Hub
          if (activeProfile == AppProfile.agenda || activeProfile == AppProfile.corporativo)
            ListTile(
              leading: const Icon(Icons.calendar_today_rounded, color: Color(0xFF0F4C5C)),
              title: Text('Agenda & Notas Rápidas', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              onTap: onAgendaTap,
            ),

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
}
