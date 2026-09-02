import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/core/theme/app_colors.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import '../models/notebook_model.dart';
import '../models/notebook_template.dart';
import '../controllers/notebooks_controller.dart';
import '../../shared/widgets/color_engine_widget.dart';

class NotebookDialogs {
  static void showNotebookModal(BuildContext context, WidgetRef ref, Subject? activeSubject, Color themeColor, {required bool isEditing, Notebook? notebookToEdit}) {
    final titleController = TextEditingController(text: isEditing ? notebookToEdit!.title : '');
    final tagsController = TextEditingController(text: isEditing ? notebookToEdit!.tags.join(', ') : '');
    final formKey = GlobalKey<FormState>();
    String selectedTemplate = isEditing ? (notebookToEdit!.templateType) : NotebookTemplateType.blank.name;
    bool isFavorite = isEditing ? notebookToEdit!.isFavorite : false;
    bool showTemplatesList = !isEditing; // 🚀 Esconder por padrão se estiver a editar

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
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), // 🚀 Preencher mais horizontal em mobile
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
                child: Icon(isEditing ? Icons.edit_note_rounded : Icons.library_add_rounded, color: themeColor, size: 22),
              ),
              const SizedBox(width: 12),
              Text(isEditing ? 'Editar Caderno' : 'Novo Caderno', 
                style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 18, color: themeColor),
              ),
            ],
          ),
          content: SizedBox(
            width: 450,
            child: SingleChildScrollView(
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
                        hintText: 'ex: Matemática, Diário...',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: Icon(Icons.book_outlined, color: themeColor, size: 20),
                      ),
                      validator: (value) => value == null || value.trim().isEmpty ? 'Introduz o título' : null,
                    ),
                    const SizedBox(height: 24),
                    
                    // 🚀 SELETOR DE TEMPLATE (COMPACTO NA EDIÇÃO)
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Modelo do Caderno', 
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)
                        ),
                        if (isEditing)
                          TextButton.icon(
                            onPressed: () => setModalState(() => showTemplatesList = !showTemplatesList),
                            icon: Icon(showTemplatesList ? Icons.expand_less : Icons.swap_horiz_rounded, size: 16),
                            label: Text(showTemplatesList ? 'Recolher' : 'Alterar', style: const TextStyle(fontSize: 12)),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),

                    if (!showTemplatesList)
                      _buildSelectedTemplatePreview(selectedTemplate, themeColor)
                    else
                      _buildTemplatesGrid(selectedTemplate, (typeName, suggestedColor) {
                        setModalState(() {
                          selectedTemplate = typeName;
                          pickedColorHex = suggestedColor;
                          if (!isEditing) showTemplatesList = true; // Mantém aberto na criação
                        });
                      }),

                    const SizedBox(height: 24),
                    
                    // 🚀 TAGS E FAVORITO
                    Text('Organização', 
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: tagsController,
                      decoration: InputDecoration(
                        labelText: 'Etiquetas (Tags)',
                        hintText: 'Faculdade, Urgente...',
                        helperText: 'Separa por vírgulas',
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                        prefixIcon: const Icon(Icons.tag_rounded, size: 20),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Adicionar aos Favoritos', style: TextStyle(fontSize: 14)),
                      secondary: Icon(Icons.star_rounded, color: isFavorite ? Colors.orange : Colors.grey.shade300),
                      value: isFavorite,
                      activeColor: Colors.orange,
                      onChanged: (val) => setModalState(() => isFavorite = val),
                    ),

                    Text('Cor da Capa', 
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)
                    ),
                    const SizedBox(height: 12),
                    InkWell(
                      onTap: () async {
                        final newColor = await ColorEngine.show(
                          context, 
                          initialColor: pickedColorHex,
                          title: 'Cor da Capa',
                          showNotebookPreview: true,
                        );
                        if (newColor != null) {
                          setModalState(() => pickedColorHex = newColor);
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.black.withOpacity(0.05)),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(backgroundColor: Color(int.parse(pickedColorHex.replaceFirst('#', '0xFF'))), radius: 12),
                            const SizedBox(width: 12),
                            Text('Alterar Cor...', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: const Color(0xFF0F4C5C))),
                            const Spacer(),
                            const Icon(Icons.palette_outlined, size: 20, color: Color(0xFF0F4C5C)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(contextDialog), 
              child: const Text('CANCELAR', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold))
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
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
                    }
                  }
                }
              },
              child: Text(isEditing ? 'GUARDAR' : 'CRIAR', style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSelectedTemplatePreview(String templateTypeName, Color themeColor) {
    final type = NotebookTemplateType.values.firstWhere((e) => e.name == templateTypeName, orElse: () => NotebookTemplateType.blank);
    final config = NotebookTemplateConfig.templates[type]!;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: config.suggestedColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: config.suggestedColor.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(config.icon, color: config.suggestedColor, size: 24),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(config.label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
              Text('Modelo selecionado', style: GoogleFonts.inter(fontSize: 11, color: Colors.black38)),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildTemplatesGrid(String selectedTemplate, Function(String, String) onSelect) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.02),
        borderRadius: BorderRadius.circular(16),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // 🚀 GRELHA DE 3 COLUNAS FIXA
          final double itemWidth = (constraints.maxWidth - (8 * 2)) / 3;

          return Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: NotebookTemplateConfig.templates.entries.map((entry) {
              final type = entry.key;
              final config = entry.value;
              final isSelected = selectedTemplate == type.name;
              
              return GestureDetector(
                onTap: () => onSelect(type.name, '#${config.suggestedColor.value.toRadixString(16).substring(2).toUpperCase()}'),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: itemWidth, 
                  padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
                  decoration: BoxDecoration(
                    color: isSelected ? config.suggestedColor.withOpacity(0.1) : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: isSelected ? config.suggestedColor : Colors.black.withOpacity(0.05), 
                      width: isSelected ? 2 : 1
                    ),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(config.icon, 
                        color: isSelected ? config.suggestedColor : Colors.grey, 
                        size: 22
                      ),
                      const SizedBox(height: 8),
                      Text(config.label, 
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(
                          fontSize: 9, 
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, 
                          color: isSelected ? config.suggestedColor : Colors.black87
                        )
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          );
        }
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
