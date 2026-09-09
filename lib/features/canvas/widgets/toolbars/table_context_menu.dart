import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/table_model.dart';
import '../../providers/canvas_document_provider.dart';
import '../../providers/canvas_tool_provider.dart';

/// 🚀 v10.8: Menu contextual flutuante para gestão de tabelas.
class TableContextMenu extends ConsumerWidget {
  final TableObject table;
  final Offset position;

  const TableContextMenu({
    super.key,
    required this.table,
    required this.position,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docNotifier = ref.read(canvasDocumentProvider.notifier);
    final toolState = ref.watch(canvasToolProvider);
    final pageClientId = table.pageNumber != null ? ref.read(canvasDocumentProvider).pages.firstWhere((p) => p.pageNumber == table.pageNumber).clientId : null;
    
    if (pageClientId == null) return const SizedBox.shrink();
    final page = ref.read(canvasDocumentProvider).pages.firstWhere((p) => p.clientId == pageClientId);

    return Material(
      elevation: 4,
      borderRadius: BorderRadius.circular(8),
      color: Colors.white,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
        decoration: BoxDecoration(
          border: Border.all(color: const Color(0xFF0F4C5C).withOpacity(0.2)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildAction(
              icon: Icons.add_chart_rounded, 
              label: 'Linha', 
              onTap: () => docNotifier.updateObject(page, table.insertRowAt(table.rows)),
            ),
            _buildDivider(),
            _buildAction(
              icon: Icons.playlist_add_rounded, 
              label: 'Col', 
              onTap: () => docNotifier.updateObject(page, table.insertColumnAt(table.cols)),
            ),
            _buildDivider(),
            _buildAction(
              icon: Icons.delete_sweep_rounded, 
              label: 'Eliminar', 
              color: Colors.red,
              onTap: () => docNotifier.deleteObjects(page, [table.id]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAction({required IconData icon, required String label, required VoidCallback onTap, Color? color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color ?? const Color(0xFF0F4C5C)),
            Text(label, style: TextStyle(fontSize: 9, color: color ?? const Color(0xFF0F4C5C))),
          ],
        ),
      ),
    );
  }

  Widget _buildDivider() => Container(height: 20, width: 1, color: Colors.grey.withOpacity(0.2), margin: const EdgeInsets.symmetric(horizontal: 4));
}
