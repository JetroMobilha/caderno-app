import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/core/theme/app_colors.dart';
import 'package:caderno_digital_app/features/canvas/views/canvas_screen.dart';
import 'package:caderno_digital_app/features/canvas/widgets/share_notebook_sheet.dart';
import 'package:caderno_digital_app/features/marketplace/widgets/publish_notebook_sheet.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:caderno_digital_app/features/notebooks/controllers/notebooks_controller.dart';
import 'notebook_cover.dart';
import 'notebook_dialogs.dart';

class NotebookGridItem extends ConsumerWidget {
  final Notebook notebook;
  final Color dynamicColor;

  const NotebookGridItem({
    super.key,
    required this.notebook,
    required this.dynamicColor,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSubject = ref.watch(activeSubjectProvider);

    return Opacity(
      opacity: notebook.isArchived ? 0.6 : 1.0,
      child: Stack(
        children: [
          Positioned.fill(
            child: NotebookCover(
              notebook: notebook,
              onTap: () async {
                if (notebook.isArchived) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Desarquiva o caderno para poder editar.')),
                  );
                  return;
                }
                await Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => CanvasScreen(notebook: notebook),
                  ),
                );
              },
            ),
          ),
          if (notebook.isArchived)
            const Positioned(
              bottom: 8,
              left: 26,
              child: Icon(Icons.archive_rounded, color: Colors.white, size: 16),
            ),
          if (notebook.isFavorite)
            const Positioned(
              top: 6,
              left: 24,
              child: Icon(Icons.star_rounded, color: Colors.orange, size: 20),
            ),
          Positioned(
            top: 6,
            right: 4,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) async {
                  if (value == 'edit') {
                    NotebookDialogs.showNotebookModal(context, ref, activeSubject, dynamicColor, isEditing: true, notebookToEdit: notebook);
                  } else if (value == 'delete') {
                    NotebookDialogs.confirmDelete(context, ref, notebook);
                  } else if (value == 'share') {
                    Notebook currentNotebook = notebook;
                    if (currentNotebook.serverId == null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('A ligar caderno à nuvem... ☁️'), duration: Duration(seconds: 1)),
                      );
                      await ref.read(subjectsProvider.notifier).syncManuallyWithCloud();
                      final notebooksState = ref.read(notebooksProvider);
                      currentNotebook = notebooksState.notebooks.firstWhere((n) => n.id == notebook.id, orElse: () => notebook);
                    }

                    if (currentNotebook.serverId == null) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Sem internet. Não é possível partilhar agora.'), backgroundColor: Colors.redAccent),
                        );
                      }
                      return;
                    }

                    if (context.mounted) {
                      showModalBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        backgroundColor: Colors.transparent,
                        builder: (context) => ShareNotebookBottomSheet(notebook: currentNotebook),
                      );
                    }
                  } else if (value == 'publish') {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => PublishNotebookSheet(notebook: notebook),
                    );
                  } else if (value == 'view_store') {
                    Clipboard.setData(ClipboardData(text: 'https://app.cadernodigital.ao/loja/caderno/${notebook.serverId}'));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Link de partilha copiado! 🔗 Envia aos teus alunos ou colegas.'),
                        backgroundColor: Color(0xFF27AE60),
                      ),
                    );
                  } else if (value == 'duplicate') {
                    NotebookDialogs.confirmDuplicate(context, ref, notebook, activeSubject);
                  } else if (value == 'move') {
                    NotebookDialogs.showMoveNotebookDialog(context, ref, notebook);
                  } else if (value == 'archive') {
                    ref.read(notebooksProvider.notifier).updateNotebook(notebook.copyWith(isArchived: !notebook.isArchived));
                  } else if (value == 'favorite') {
                    ref.read(notebooksProvider.notifier).updateNotebook(notebook.copyWith(isFavorite: !notebook.isFavorite));
                  } else if (value == 'leave') {
                    NotebookDialogs.confirmLeave(context, ref, notebook);
                  }
                },
                itemBuilder: (context) {
                  final bool isSharedTab = activeSubject?.id == -1;
                  final String currentRole = (notebook.role).toLowerCase().trim();
                  final bool isOwner = !isSharedTab && currentRole == 'owner';
                  final bool isEditor = currentRole == 'editor';

                  return [
                    if (isOwner || isEditor)
                      PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: dynamicColor), const SizedBox(width: 8), Text('Editar', style: GoogleFonts.inter(fontSize: 13))])),
                    if (isOwner)
                      PopupMenuItem(value: 'move', child: Row(children: [const Icon(Icons.drive_file_move_outlined, size: 18, color: Colors.blueGrey), const SizedBox(width: 8), Text('Mover', style: GoogleFonts.inter(fontSize: 13))])),
                    if (isOwner)
                      PopupMenuItem(
                        value: 'favorite', 
                        child: Row(children: [
                          Icon(notebook.isFavorite ? Icons.star_outline_rounded : Icons.star_rounded, size: 18, color: Colors.orange), 
                          const SizedBox(width: 8), 
                          Text(notebook.isFavorite ? 'Remover Favorito' : 'Favoritar', style: GoogleFonts.inter(fontSize: 13))
                        ])
                      ),
                    if (isOwner)
                      PopupMenuItem(
                        value: 'archive', 
                        child: Row(children: [
                          Icon(notebook.isArchived ? Icons.unarchive_outlined : Icons.archive_outlined, size: 18, color: Colors.blueGrey), 
                          const SizedBox(width: 8), 
                          Text(notebook.isArchived ? 'Desarquivar' : 'Arquivar', style: GoogleFonts.inter(fontSize: 13))
                        ])
                      ),
                    if (isOwner || isEditor)
                      PopupMenuItem(value: 'share', child: Row(children: [const Icon(Icons.share_rounded, size: 18, color: Colors.blueAccent), const SizedBox(width: 8), Text('Partilhar', style: GoogleFonts.inter(fontSize: 13, color: Colors.blueAccent))])),
                    PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          const Icon(Icons.copy_rounded, size: 18, color: Colors.teal),
                          const SizedBox(width: 8),
                          Text(isOwner ? 'Duplicar Caderno' : 'Criar Minha Cópia', style: GoogleFonts.inter(fontSize: 13, color: Colors.teal)),
                        ],
                      ),
                    ),
                    if (isOwner)
                      PopupMenuItem(
                        value: 'publish',
                        child: Row(
                          children: [
                            Icon(Icons.storefront_rounded, size: 18, color: notebook.isPublished == 1 ? AppColors.accent : AppColors.primary),
                            const SizedBox(width: 8),
                            Text(
                              notebook.isPublished == 1 ? 'Loja (Publicado) 🟢' : 'Publicar na Loja 🛒',
                              style: GoogleFonts.inter(fontSize: 13, fontWeight: notebook.isPublished == 1 ? FontWeight.bold : FontWeight.normal, color: notebook.isPublished == 1 ? AppColors.accent : AppColors.textDark),
                            ),
                          ],
                        ),
                      ),
                    if (notebook.isPublished == 1)
                      PopupMenuItem(
                        value: 'view_store',
                        child: Row(
                          children: [
                            const Icon(Icons.share_arrival_time_rounded, size: 18, color: Color(0xFF27AE60)),
                            const SizedBox(width: 8),
                            Text('Link da Loja 🔗', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF27AE60))),
                          ],
                        ),
                      ),
                    if (!isOwner)
                      PopupMenuItem(value: 'leave', child: Row(children: [const Icon(Icons.logout_rounded, size: 18, color: Colors.orangeAccent), const SizedBox(width: 8), Text('Sair do Caderno', style: GoogleFonts.inter(fontSize: 13, color: Colors.orangeAccent))])),
                    if (isOwner)
                      PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), const SizedBox(width: 8), Text('Apagar', style: GoogleFonts.inter(fontSize: 13, color: Colors.redAccent))])),
                  ];
                },
              ),
            ),
          ),
          if (notebook.tags.isNotEmpty)
            Positioned(
              bottom: 8,
              right: 8,
              left: 45, // Deixar espaço para o lombada/ícone arquivo
              child: Wrap(
                alignment: WrapAlignment.end,
                spacing: 4,
                runSpacing: 4,
                children: notebook.tags.take(3).map((tag) => Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tag,
                    style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                )).toList(),
              ),
            ),
        ],
      ),
    );
  }
}
