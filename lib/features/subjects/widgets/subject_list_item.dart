import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/features/auth/controllers/auth_controller.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';
import 'package:caderno_digital_app/features/subjects/utils/subject_utils.dart';
import 'package:caderno_digital_app/features/subjects/widgets/subject_dialogs.dart';
import 'package:caderno_digital_app/features/notebooks/controllers/notebooks_controller.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:caderno_digital_app/features/notebooks/views/notebooks_list_screen.dart';

class SubjectListItem extends ConsumerWidget {
  final Subject subject;

  const SubjectListItem({
    super.key,
    required this.subject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notebooksState = ref.watch(notebooksProvider);

    final notebookCount = notebooksState.notebooks.where((n) =>
      n.subjectId == subject.id ||
      (subject.serverId != null && n.subjectId == subject.serverId)
    ).length;

    final Color subjectColor = Color(int.parse((subject.color).replaceFirst('#', '0xFF')));

    return Opacity(
      opacity: subject.isArchived ? 0.6 : 1.0,
      child: Card(
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: Colors.black.withOpacity(0.05)),
        ),
        color: Colors.white,
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          onTap: () {
            if (subject.isArchived) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Desarquiva a pasta para poder aceder aos cadernos.')),
              );
              return;
            }
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const NotebooksListScreen(),
              ),
            );
          },
          leading: Container(
            width: 6,
            height: double.infinity,
            decoration: BoxDecoration(color: subjectColor, borderRadius: BorderRadius.circular(4)),
          ),
          title: Row(
            children: [
              Icon(SubjectUtils.getSubjectIcon(subject.icon), color: Colors.black54, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  subject.name,
                  style: GoogleFonts.lora(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (subject.isArchived)
                const Padding(
                  padding: EdgeInsets.only(left: 8.0),
                  child: Icon(Icons.archive_outlined, color: Colors.blueGrey, size: 18),
                ),
            ],
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8F9FA),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$notebookCount ${notebookCount == 1 ? 'caderno' : 'cadernos'}',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
                ),
              ),
              const SizedBox(width: 4),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, color: Colors.black45),
                onSelected: (value) async {
                  final notifier = ref.read(subjectsProvider.notifier);
                  if (value == 'archive') {
                    await notifier.updateSubject(subject.copyWith(isArchived: !subject.isArchived));
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(subject.isArchived ? 'Pasta enviada para o arquivo! 📂' : 'Pasta desarquivada! 📥')),
                  );
                }
              } else if (value == 'clone') {
                await notifier.duplicateSubject(subject);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pasta e cadernos clonados com sucesso! 📑')),
                  );
                }
              } else if (value == 'delete') {
                    SubjectDialogs.confirmDeleteSubject(context, ref, subject);
                  } else if (value == 'edit') {
                    final user = ref.read(authProvider).currentUser;
                    if (user != null) {
                      SubjectDialogs.showSubjectModal(context, ref, user, isEditing: true, subjectToEdit: subject, themeColor: subjectColor);
                    }
                  }
                },
                itemBuilder: (context) => [
                  PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [const Icon(Icons.edit_outlined, size: 20, color: Colors.blueGrey), const SizedBox(width: 10), const Text('Editar')]),
                  ),
                  PopupMenuItem(
                    value: 'clone',
                    child: Row(children: [const Icon(Icons.copy_rounded, size: 20, color: Colors.teal), const SizedBox(width: 10), const Text('Clonar')]),
                  ),
                  PopupMenuItem(
                    value: 'archive',
                    child: Row(children: [Icon(subject.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 20, color: Colors.brown), const SizedBox(width: 10), Text(subject.isArchived ? 'Desarquivar' : 'Enviar para o arquivo')]),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent), const SizedBox(width: 10), const Text('Apagar', style: TextStyle(color: Colors.redAccent))]),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
