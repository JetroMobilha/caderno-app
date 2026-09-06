import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/table_model.dart';
import '../../models/canvas_enums.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/local_page_model.dart';

class TableEditToolbar extends ConsumerWidget {
  final LocalPage currentPage;
  final bool isCellEditing;

  const TableEditToolbar({
    super.key,
    required this.currentPage,
    this.isCellEditing = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolState = ref.watch(canvasToolProvider);
    final toolNotifier = ref.read(canvasToolProvider.notifier);

    if (isCellEditing) {
      return _buildTableCellEditToolbar(context, ref, toolNotifier);
    }

    return _buildTableManagementToolbar(context, ref, toolState, toolNotifier);
  }

  Widget _buildTableCellEditToolbar(BuildContext context, WidgetRef ref, CanvasToolNotifier toolNotifier) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C5C),
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black26, blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCustomIconButton(
            icon: Icons.arrow_back_rounded, 
            onTap: () async {
               FocusManager.instance.primaryFocus?.unfocus();
               await Future.delayed(Duration.zero);
               toolNotifier.exitWritingMode();
            }, 
            color: Colors.white70
          ),
          const VerticalDivider(color: Colors.white24, width: 24),
          const Icon(Icons.table_chart_rounded, color: Colors.white70, size: 18),
          const SizedBox(width: 12),
          const Text('EDITANDO CÉLULA', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
          const VerticalDivider(color: Colors.white24, width: 24),
          _buildCustomIconButton(
            icon: Icons.check_circle_rounded, 
            onTap: () async {
               FocusManager.instance.primaryFocus?.unfocus();
               await Future.delayed(Duration.zero);
               toolNotifier.exitWritingMode();
            }, 
            color: Colors.greenAccent
          ),
        ],
      ),
    );
  }

  Widget _buildTableManagementToolbar(BuildContext context, WidgetRef ref, CanvasToolState toolState, CanvasToolNotifier toolNotifier) {
    final docState = ref.read(canvasDocumentProvider);
    final page = docState.pages.firstWhere((p) => p.clientId == currentPage.clientId);
    final table = page.objects.whereType<TableObject>().firstWhere((t) => toolState.selectedTableIds.contains(t.id));

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10)],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCustomIconButton(
            icon: Icons.arrow_back_rounded, 
            onTap: () {
              toolNotifier.exitWritingMode();
            }, 
            color: const Color(0xFF0F4C5C)
          ),
          const VerticalDivider(width: 20),
          _buildCustomIconButton(
            icon: Icons.table_rows_rounded, 
            onTap: () {
              table.insertRow(table.rows);
              ref.read(canvasDocumentProvider.notifier).updateObject(page, table);
            }, 
            color: const Color(0xFF0F4C5C)
          ),
          _buildCustomIconButton(
            icon: Icons.view_column_rounded, 
            onTap: () {
              table.insertColumn(table.cols);
              ref.read(canvasDocumentProvider.notifier).updateObject(page, table);
            }, 
            color: const Color(0xFF0F4C5C)
          ),
          const VerticalDivider(width: 20),
          _buildCustomIconButton(
            icon: Icons.delete_outline_rounded, 
            onTap: () {
              if (table.rows > 1) table.deleteRow(table.rows - 1);
              ref.read(canvasDocumentProvider.notifier).updateObject(page, table);
            }, 
            color: Colors.redAccent
          ),
          _buildCustomIconButton(
            icon: Icons.format_color_fill_rounded, 
            onTap: () {}, 
            color: const Color(0xFFE67E22)
          ),
          const VerticalDivider(width: 20),
          _buildCustomIconButton(
            icon: Icons.close_rounded, 
            onTap: () => toolNotifier.clearSelection(), 
            color: Colors.black54
          ),
        ],
      ),
    );
  }

  Widget _buildCustomIconButton({required IconData icon, required VoidCallback onTap, required Color color, double size = 20}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }
}
