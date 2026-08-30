import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';
import 'package:caderno_digital_app/features/notebooks/repositories/notebook_repository.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';

class SelectNotebookDialog extends ConsumerStatefulWidget {
  final String title;
  final int? excludeNotebookId;

  const SelectNotebookDialog({
    super.key,
    required this.title,
    this.excludeNotebookId,
  });

  @override
  ConsumerState<SelectNotebookDialog> createState() => _SelectNotebookDialogState();
}

class _SelectNotebookDialogState extends ConsumerState<SelectNotebookDialog> {
  List<Notebook>? _notebooks;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadNotebooks();
  }

  Future<void> _loadNotebooks() async {
    final all = await ref.read(notebookRepositoryProvider).getAllNotebooks();
    if (mounted) {
      setState(() {
        _notebooks = all.where((n) => n.id != widget.excludeNotebookId).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text(widget.title, style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
      content: SizedBox(
        width: double.maxFinite,
        height: 400,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : _notebooks == null || _notebooks!.isEmpty
                ? const Center(child: Text('Nenhum outro caderno encontrado.'))
                : ListView.builder(
                    itemCount: subjects.length,
                    itemBuilder: (context, sIndex) {
                      final subject = subjects[sIndex];
                      final subjectNotebooks = _notebooks!
                          .where((n) => n.subjectId == subject.id)
                          .toList();

                      if (subjectNotebooks.isEmpty) return const SizedBox.shrink();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                            child: Row(
                              children: [
                                Container(
                                  width: 4, height: 16,
                                  decoration: BoxDecoration(
                                    color: Color(int.parse(subject.color.replaceFirst('#', '0xFF'))),
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  subject.name.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black45,
                                    letterSpacing: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          ...subjectNotebooks.map((n) => ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
                                leading: Icon(Icons.book_rounded, color: n.color != null ? Color(int.parse(n.color!.replaceFirst('#', '0xFF'))) : const Color(0xFF0F4C5C)),
                                title: Text(n.title, style: const TextStyle(fontSize: 14)),
                                onTap: () => Navigator.pop(context, n),
                              )),
                          const Divider(),
                        ],
                      );
                    },
                  ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('CANCELAR'),
        ),
      ],
    );
  }
}
