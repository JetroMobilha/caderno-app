import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/local_page_model.dart';

class PaperStyleDialog extends ConsumerWidget {
  final LocalPage currentPage;

  const PaperStyleDialog({
    super.key,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docNotifier = ref.read(canvasDocumentProvider.notifier);

    return AlertDialog(
      title: const Text('Estilo de Papel'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.view_headline),
            title: const Text('Pautado'),
            onTap: () {
              docNotifier.setLineType(currentPage, 'ruled');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.grid_4x4),
            title: const Text('Quadriculado'),
            onTap: () {
              docNotifier.setLineType(currentPage, 'grid');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.check_box_outline_blank),
            title: const Text('Liso'),
            onTap: () {
              docNotifier.setLineType(currentPage, 'blank');
              Navigator.pop(context);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.description_outlined),
            title: const Text('Cornell Notes'),
            onTap: () {
              docNotifier.setLineType(currentPage, 'cornell');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.grid_on_rounded),
            title: const Text('Grelha Engenharia'),
            onTap: () {
              docNotifier.setLineType(currentPage, 'engineering');
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
