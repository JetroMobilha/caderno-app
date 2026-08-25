import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/features/canvas/controllers/canvas_controller.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';

class NotebookDeletedDialog extends ConsumerStatefulWidget {
  final CanvasController controller;

  const NotebookDeletedDialog({super.key, required this.controller});

  @override
  ConsumerState<NotebookDeletedDialog> createState() => _NotebookDeletedDialogState();
}

class _NotebookDeletedDialogState extends ConsumerState<NotebookDeletedDialog> {
  int? selectedSubjectId;
  String newSubjectName = "";
  bool isCreatingSubject = false;

  @override
  Widget build(BuildContext context) {
    final subjects = ref.watch(subjectsProvider);

    return PopScope(
      canPop: false,
      child: AlertDialog(
        backgroundColor: const Color(0xFFFDFBF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.orange, size: 28),
            const SizedBox(width: 12),
            Text(
              'Caderno Apagado!',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C)),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('O proprietário removeu este caderno. Podes salvar uma cópia local nas tuas disciplinas.'),
              const SizedBox(height: 20),
              if (!isCreatingSubject) ...[
                DropdownButton<int>(
                  isExpanded: true,
                  hint: const Text('Selecionar Disciplina'),
                  value: selectedSubjectId,
                  items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                  onChanged: (val) => setState(() => selectedSubjectId = val),
                ),
                TextButton(
                  onPressed: () => setState(() => isCreatingSubject = true),
                  child: const Text('Criar Nova'),
                ),
              ] else ...[
                TextField(
                  decoration: const InputDecoration(hintText: 'Nome...'),
                  onChanged: (val) => newSubjectName = val,
                ),
                TextButton(
                  onPressed: () => setState(() => isCreatingSubject = false),
                  child: const Text('Voltar'),
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              widget.controller.exitNotebook();
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('Sair'),
          ),
          ElevatedButton(
            onPressed: () async {
              int? finalSubId = selectedSubjectId;
              if (isCreatingSubject && newSubjectName.isNotEmpty) {
                final newSub = Subject(name: newSubjectName, color: "#0F4C5C");
                final added = await ref.read(subjectsProvider.notifier).addSubject(newSub);
                finalSubId = added?.id;
              }
              if (finalSubId != null) {
                await widget.controller.saveCopyOfNotebook(finalSubId);
                if (!context.mounted) return;
                Navigator.pop(context);
                Navigator.pop(context);
              }
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
  }
}
