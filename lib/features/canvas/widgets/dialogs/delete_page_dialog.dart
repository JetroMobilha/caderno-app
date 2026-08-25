import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/local_page_model.dart';

class DeletePageDialog extends ConsumerWidget {
  final LocalPage page;

  const DeletePageDialog({
    super.key,
    required this.page,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return AlertDialog(
      title: const Text('Eliminar Folha'),
      content: const Text('Tens a certeza?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        TextButton(
          onPressed: () {
            ref.read(canvasDocumentProvider.notifier).deletePage(page);
            Navigator.pop(context);
          },
          child: const Text('Eliminar', style: const TextStyle(color: Colors.red)),
        ),
      ],
    );
  }
}
