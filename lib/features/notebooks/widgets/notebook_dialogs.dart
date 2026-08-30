import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/core/theme/app_colors.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import '../models/notebook_model.dart';
import '../controllers/notebooks_controller.dart';

class NotebookDialogs {
  static void showNotebookModal(BuildContext context, WidgetRef ref, Subject? activeSubject, Color themeColor, {required bool isEditing, Notebook? notebookToEdit}) {
    final titleController = TextEditingController(text: isEditing ? notebookToEdit!.title : '');
    final tagsController = TextEditingController(text: isEditing ? notebookToEdit!.tags.join(', ') : '');
    final formKey = GlobalKey<FormState>();
    String selectedTemplate = isEditing ? (notebookToEdit!.templateType) : 'study';
    bool isFavorite = isEditing ? notebookToEdit!.isFavorite : false;
    final List<String> availableColors = [
      '#8B0000', '#0F4C5C', '#1F4E79', '#3F51B5',
      '#6C3483', '#9B59B6', '#D81B60', '#E91E63',
      '#E67E22', '#D35400', '#F1C40F', '#1E8449',
      '#27AE60', '#16A085', '#4E342E', '#607D8B',
    ];
    String pickedColorHex = isEditing ? (notebookToEdit!.color ?? '#8B0000') : '#8B0000';

    showDialog(
      context: context,
      builder: (contextDialog) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_note_rounded : Icons.library_add_rounded, color: themeColor),
              const SizedBox(width: 10),
              Flexible(
                child: Text(isEditing ? 'Editar Caderno' : 'Novo Caderno', 
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
                  TextFormField(
                    controller: titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Título do Caderno',
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: themeColor, width: 1.5)),
                    ),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Introduz o título' : null,
                  ),
                  const SizedBox(height: 20),
                  TextFormField(
                    controller: tagsController,
                    decoration: InputDecoration(
                      labelText: 'Etiquetas (Tags)',
                      hintText: 'ex: Faculdade, Urgente, Projeto',
                      helperText: 'Separa as tags por vírgula',
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: themeColor, width: 1.5)),
                      prefixIcon: Icon(Icons.tag_rounded, color: themeColor, size: 20),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Marcar como Favorito', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: themeColor)),
                    subtitle: const Text('Fixar no topo da lista', style: TextStyle(fontSize: 12)),
                    secondary: Icon(Icons.star_rounded, color: isFavorite ? Colors.orange : Colors.grey),
                    value: isFavorite,
                    activeColor: Colors.orange,
                    onChanged: (val) => setModalState(() => isFavorite = val),
                  ),
                  const SizedBox(height: 20),
                  Text('Propósito do Caderno:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: themeColor)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTemplateCard(context, 'Pessoal / Estudo', Icons.school_rounded, 'study', selectedTemplate, themeColor, () => setModalState(() => selectedTemplate = 'study')),
                      const SizedBox(width: 8),
                      _buildTemplateCard(context, 'Técnico', Icons.engineering_rounded, 'technical', selectedTemplate, Colors.blueGrey, () => setModalState(() => selectedTemplate = 'technical')),
                      const SizedBox(width: 8),
                      _buildTemplateCard(context, 'Formal', Icons.business_center_rounded, 'formal', selectedTemplate, const Color(0xFF2C3E50), () => setModalState(() => selectedTemplate = 'formal')),
                      const SizedBox(width: 8),
                      _buildTemplateCard(context, 'Criativo', Icons.palette_rounded, 'creative', selectedTemplate, const Color(0xFFD81B60), () => setModalState(() => selectedTemplate = 'creative')),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text('Cor da Capa:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: availableColors.map((hex) {
                      final isSelected = pickedColorHex == hex;
                      final colorValue = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                      return GestureDetector(
                        onTap: () => setModalState(() => pickedColorHex = hex),
                        child: CircleAvatar(
                          backgroundColor: colorValue,
                          radius: 14,
                          child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(contextDialog), child: const Text('Cancelar', style: TextStyle(color: Colors.black45))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: themeColor),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final notifier = ref.read(notebooksProvider.notifier);
                  final List<String> tags = tagsController.text.split(',').map((t) => t.trim()).where((t) => t.isNotEmpty).toList();

                  if (isEditing) {
                    final cadernoEditado = notebookToEdit!.copyWith(
                      title: titleController.text.trim(),
                      color: pickedColorHex,
                      templateType: selectedTemplate,
                      tags: tags,
                      isFavorite: isFavorite,
                    );
                    await notifier.updateNotebook(cadernoEditado);
                    if (contextDialog.mounted) Navigator.pop(contextDialog);
                  } else {
                    final newNotebook = Notebook(
                      subjectId: activeSubject?.id ?? 0,
                      title: titleController.text.trim(),
                      coverType: 'color',
                      color: pickedColorHex,
                      templateType: selectedTemplate,
                      tags: tags,
                      isFavorite: isFavorite,
                    );

                    newNotebook.id = await notifier.addNotebook(newNotebook, activeSubject?.serverId);
                    if (contextDialog.mounted) {
                      Navigator.pop(contextDialog);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Caderno "${newNotebook.title}" criado com sucesso! 📓'),
                          backgroundColor: themeColor,
                          duration: const Duration(seconds: 2),
                        ),
                      );
                    }
                  }
                }
              },
              child: Text(isEditing ? 'Atualizar' : 'Criar', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildTemplateCard(BuildContext context, String label, IconData icon, String type, String selected, Color color, VoidCallback onTap) {
    final isSelected = selected == type;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 24),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.grey)),
            ],
          ),
        ),
      ),
    );
  }

  static void confirmDelete(BuildContext context, WidgetRef ref, Notebook notebook) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Apagar Caderno?', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text('O caderno "${notebook.title}" e todas as suas folhas serão arquivados.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(notebooksProvider.notifier).deleteNotebook(notebook);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Caderno movido para a lixeira! 🗑️'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
              );
            },
            child: const Text('Apagar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  static void confirmDuplicate(BuildContext context, WidgetRef ref, Notebook notebook, Subject? activeSubject) {
    int? selectedSubId;
    final subjects = ref.read(subjectsProvider).where((s) => s.id != -1).toList();

    if (subjects.isNotEmpty) {
      selectedSubId = (activeSubject != null && activeSubject.id != -1) ? activeSubject.id : subjects.first.id;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.copy_rounded, color: Colors.teal),
              const SizedBox(width: 10),
              Text(notebook.role == 'owner' ? 'Duplicar Caderno' : 'Criar Minha Cópia', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Onde desejas guardar a cópia de "${notebook.title}"?', style: GoogleFonts.inter(fontSize: 14)),
              const SizedBox(height: 20),
              Text('Pasta de Destino:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedSubId,
                    isExpanded: true,
                    items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name, style: GoogleFonts.inter(fontSize: 14)))).toList(),
                    onChanged: (val) => setStateModal(() => selectedSubId = val),
                  ),
                ),
              ),
              if (notebook.role != 'owner') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.privacy_tip_outlined, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Apenas as folhas autorizadas pelo dono serão copiadas.', style: GoogleFonts.inter(fontSize: 11, color: Colors.amber.shade900))),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.teal, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: selectedSubId == null ? null : () async {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A criar a tua cópia... ⏳'), duration: Duration(seconds: 2)));
                await ref.read(notebooksProvider.notifier).duplicateNotebook(notebook, selectedSubId!);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Cópia criada com sucesso! 📓'), backgroundColor: Colors.green));
                }
              },
              child: const Text('Confirmar Cópia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  static void showMoveNotebookDialog(BuildContext context, WidgetRef ref, Notebook notebook) {
    int? selectedSubId;
    final subjects = ref.read(subjectsProvider);

    if (subjects.isNotEmpty) {
      selectedSubId = subjects.firstWhere((s) => s.id != notebook.subjectId, orElse: () => subjects.first).id;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.drive_file_move_outlined, color: Colors.blueGrey),
              const SizedBox(width: 10),
              Text('Mover Caderno', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Para qual pasta desejas mover "${notebook.title}"?', style: GoogleFonts.inter(fontSize: 14)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(12)),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedSubId,
                    isExpanded: true,
                    items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (val) => setStateModal(() => selectedSubId = val),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: () async {
                if (selectedSubId != null) {
                  await ref.read(notebooksProvider.notifier).moveNotebook(notebook, selectedSubId!);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caderno movido com sucesso! 🚀'), backgroundColor: Colors.green));
                  }
                }
              },
              child: const Text('Mover Agora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  static void confirmLeave(BuildContext context, WidgetRef ref, Notebook notebook) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sair do Caderno?', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
        content: Text('Deixarás de ter acesso a "${notebook.title}". Terás de pedir um novo convite ao dono para voltar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(notebooksProvider.notifier).leaveNotebook(notebook);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Removeste o teu acesso com sucesso. 👋'), backgroundColor: Colors.blueGrey));
              }
            },
            child: const Text('Sair Agora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
