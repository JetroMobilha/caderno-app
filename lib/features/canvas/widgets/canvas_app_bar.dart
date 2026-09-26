import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:caderno_digital_app/features/notebooks/repositories/notebook_repository.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';
import 'package:caderno_digital_app/features/canvas/services/pdf_export_service.dart';
import 'package:caderno_digital_app/features/canvas/services/pdf_import_service.dart';
import 'dialogs/export_pdf_dialog.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_viewport_provider.dart';

class CanvasAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Notebook notebook;
  final VoidCallback onCollaborationTap;

  const CanvasAppBar({
    super.key,
    required this.notebook,
    required this.onCollaborationTap,
  });

  void _handleExportPdf(BuildContext context, WidgetRef ref) async {
    final docState = ref.read(canvasDocumentProvider);
    if (docState.pages.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhuma página para exportar.')),
      );
      return;
    }

    final selectedPages = await ExportPdfDialog.show(
      context,
      notebookTitle: notebook.title,
      allPages: docState.pages,
    );

    if (selectedPages == null || selectedPages.isEmpty) return;

    if (!context.mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 16),
            Text('A exportar PDF...'),
          ],
        ),
        duration: Duration(seconds: 15),
      ),
    );

    final canvasRepo = ref.read(canvasRepositoryProvider);
    final result = await PdfExportService.exportNotebookToPdf(
      notebook: notebook,
      pages: selectedPages,
      canvasRepository: canvasRepo,
      openAfterExport: true,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PDF exportado com sucesso! 📄'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(result.error ?? 'Erro ao exportar PDF.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _handleImportPdfIntoNotebook(BuildContext context, WidgetRef ref) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Row(
          children: [
            SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            SizedBox(width: 16),
            Text('A importar páginas do PDF...'),
          ],
        ),
        duration: Duration(seconds: 15),
      ),
    );

    final notebookRepo = ref.read(notebookRepositoryProvider);
    final canvasRepo = ref.read(canvasRepositoryProvider);
    final service = PdfImportService(notebookRepo, canvasRepo);

    final result = await service.importPdf(
      subjectId: notebook.subjectId ?? 0,
      targetNotebookId: notebook.id,
    );

    if (context.mounted) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();

      if (result.isSuccess) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result.pageCount} páginas de PDF adicionadas com sucesso! 📄'),
            backgroundColor: Colors.green,
          ),
        );
        if (notebook.id != null) {
          final docState = ref.read(canvasDocumentProvider);
          ref.read(canvasDocumentProvider.notifier).initNotebook(
            notebook.id!,
            notebook.serverId,
            docState.currentUserRole,
            docState.myUserId,
          );
        }
      } else if (result.error != null && !result.error!.contains('Nenhum arquivo selecionado')) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: SelectableText(result.error!),
            backgroundColor: Colors.redAccent,
            duration: const Duration(seconds: 12),
            action: SnackBarAction(
              label: 'OK',
              textColor: Colors.white,
              onPressed: () {},
            ),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docState = ref.watch(canvasDocumentProvider);
    final viewportState = ref.watch(canvasViewportProvider);
    final bool hasPages = docState.pages.isNotEmpty;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Builder(
        builder: (scaffoldContext) => InkWell(
          onTap: hasPages ? () => Scaffold.of(scaffoldContext).openEndDrawer() : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  notebook.title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasPages) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A24).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${viewportState.currentPageIndex + 1} / ${docState.pages.length}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24)),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                docState.pages.any((p) => p.syncedWithCloud == 0) ? Icons.cloud_off : Icons.cloud_done,
                size: 16,
                color: docState.pages.any((p) => p.syncedWithCloud == 0) ? Colors.orange : Colors.green,
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFDFBF7),
      foregroundColor: const Color(0xFF1A1A24),
      actions: [
        if (hasPages) ...[
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_rounded),
            tooltip: 'Exportar PDF',
            onPressed: () => _handleExportPdf(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.post_add_rounded),
            tooltip: 'Inserir PDF nesta folha',
            onPressed: () => _handleImportPdfIntoNotebook(context, ref),
          ),
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: onCollaborationTap,
          ),
          Builder(
            builder: (scaffoldContext) => IconButton(
              icon: const Icon(Icons.menu_open_rounded),
              onPressed: () => Scaffold.of(scaffoldContext).openEndDrawer(),
              tooltip: 'Lista de Folhas',
            ),
          ),
        ]
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
