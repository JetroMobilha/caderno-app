import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/subject_model.dart';
import '../utils/subject_utils.dart';
import '../../notebooks/controllers/notebooks_controller.dart';
import '../../notebooks/models/notebook_model.dart';
import '../../notebooks/views/notebooks_list_screen.dart';

class SubjectListItem extends ConsumerWidget {
  final Subject subject;

  const SubjectListItem({
    super.key,
    required this.subject,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final NotebooksState notebooksState = ref.watch(notebooksProvider);

    final notebookCount = notebooksState.notebooks.where((Notebook n) =>
      n.subjectId == subject.id ||
      (subject.serverId != null && n.subjectId == subject.serverId)
    ).length;

    final Color subjectColor = Color(int.parse((subject.color).replaceFirst('#', '0xFF')));

    return Card(
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
              ),
            ),
          ],
        ),
        trailing: Container(
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
      ),
    );
  }
}
