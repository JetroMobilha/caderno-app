import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/local_page_model.dart';
import '../../models/canvas_enums.dart';
import '../../../notebooks/models/notebook_model.dart';
import 'add_page_dialog.dart';
import 'page_settings_dialog.dart';
import 'select_notebook_dialog.dart';

class PageActionHelper {
  static void showRenameDialog(BuildContext context, WidgetRef ref, LocalPage page) {
    final controller = TextEditingController(text: page.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renomear Folha'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ex: Resumo Aula 1'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              ref.read(canvasDocumentProvider.notifier).renamePage(page, controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  static void showSettingsDialog(BuildContext context, WidgetRef ref, LocalPage page) {
    showDialog(
      context: context,
      builder: (_) => PageSettingsDialog(page: page),
    );
  }

  static void showSectionDialog(BuildContext context, WidgetRef ref, LocalPage page) {
    final docState = ref.read(canvasDocumentProvider);
    final List<String> existingSections = docState.pages
        .map((p) => p.sectionTitle)
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    final controller = TextEditingController(text: page.sectionTitle);
    String? selectedColor = page.sectionColor;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Mover para Secção'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Autocomplete<String>(
                initialValue: TextEditingValue(text: page.sectionTitle ?? ''),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return existingSections;
                  return existingSections.where((s) => s.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (selection) => controller.text = selection,
                fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
                  fieldController.addListener(() => controller.text = fieldController.text);
                  return TextField(
                    controller: fieldController,
                    focusNode: focusNode,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Nome da Secção',
                      helperText: 'Deixe vazio para remover da secção',
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text('Cor da Secção (Opcional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black38)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  '#0F4C5C', '#E36414', '#5F0F40', '#9A031E', '#2D6A4F', '#3C096C', '#264653'
                ].map((colorHex) {
                  final bool isSel = selectedColor == colorHex;
                  return InkWell(
                    onTap: () => setDialogState(() => selectedColor = colorHex),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: Color(int.parse(colorHex.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: Border.all(color: isSel ? Colors.black : Colors.transparent, width: 2),
                      ),
                      child: isSel ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                ref.read(canvasDocumentProvider.notifier).updatePageSection(
                  page, 
                  controller.text.trim(),
                  sectionColor: selectedColor,
                );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C5C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('MOVER'),
            ),
          ],
        ),
      ),
    );
  }

  static Future<void> handleMovePage(BuildContext context, WidgetRef ref, LocalPage page) async {
    final Notebook? target = await showDialog<Notebook>(
      context: context,
      builder: (_) => const SelectNotebookDialog(title: 'Mover Folha para...'),
    );
    if (target != null && target.id != null) {
      await ref.read(canvasDocumentProvider.notifier).movePageToOtherNotebook(page, target.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folha movida para "${target.title}"')),
        );
      }
    }
  }

  static Future<void> handleCopyPage(BuildContext context, WidgetRef ref, LocalPage page) async {
    final Notebook? target = await showDialog<Notebook>(
      context: context,
      builder: (_) => const SelectNotebookDialog(title: 'Copiar Folha para...'),
    );
    if (target != null && target.id != null) {
      await ref.read(canvasDocumentProvider.notifier).copyPageToOtherNotebook(page, target.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cópia criada em "${target.title}"')),
        );
      }
    }
  }

  static void showConfirmDelete(BuildContext context, WidgetRef ref, LocalPage page) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar Folha?'),
        content: const Text('Esta ação enviará a folha para a lixeira.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              ref.read(canvasDocumentProvider.notifier).deletePage(page);
              Navigator.pop(ctx);
            },
            child: const Text('APAGAR', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }

  static void showAddPageDialog(BuildContext context, WidgetRef ref, {int? insertIndex}) {
    showDialog(
      context: context, 
      builder: (_) => AddPageDialog(
        defaultLineType:'ruled',
        defaultLineSpacing: 28.0,
        insertIndex: insertIndex,
      )
    );
  }
}
