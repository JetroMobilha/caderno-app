import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/core/theme/app_colors.dart';
import 'package:caderno_digital_app/features/auth/models/user_model.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';

class SubjectDialogs {
  static void confirmDeleteSubject(BuildContext context, WidgetRef ref, Subject subject) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.paper,
        title: Text('Apagar Pasta?', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text('A pasta "${subject.name}" e os cadernos serão apagados.', style: GoogleFonts.inter()),
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
                    const SnackBar(content: Text('Pasta eliminada! 🗑️'), backgroundColor: Colors.green, duration: Duration(seconds: 2))
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

  static void showSubjectModal(BuildContext context, WidgetRef ref, User user, {required bool isEditing, Subject? subjectToEdit, required Color themeColor}) {
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
                    Flexible(
                      child: Text(isEditing ? 'Editar Pasta' : 'Nova Pasta', 
                        style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: themeColor),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nome da Pasta', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
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
