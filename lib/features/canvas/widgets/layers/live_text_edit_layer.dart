import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/text_block_model.dart';
import '../../models/table_model.dart';
import '../../models/table_cell_model.dart';
import '../../models/table_types.dart'; // 🚀 v9.7
import '../../providers/canvas_tool_provider.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/local_page_model.dart';
import '../../models/canvas_enums.dart';

/// 🚀 v9.7: Camada de edição imutável e fortemente tipada.
class LiveTextEditLayer extends ConsumerWidget {
  final LocalPage page;
  final TextEditingController textController;
  final FocusNode textFocusNode;
  final VoidCallback onTitleTap;

  const LiveTextEditLayer({
    super.key,
    required this.page,
    required this.textController,
    required this.textFocusNode,
    required this.onTitleTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolState = ref.watch(canvasToolProvider);
    final bool isEditing = toolState.activeTextBlock != null || 
                           toolState.activeTableId != null || 
                           toolState.activeInlineTarget == InlineTarget.title;

    if (!isEditing) return const SizedBox.shrink();

    return Stack(
      children: [
        if (toolState.activeTextBlock != null)
          _buildInlineTextEditor(context, ref, toolState.activeTextBlock!),
        
        Positioned(
          top: 35, left: 0, right: 0,
          child: Center(
            child: toolState.activeInlineTarget == InlineTarget.title
                ? SizedBox(
                    width: 400,
                    child: TextField(
                      textAlign: TextAlign.center, autofocus: true,
                      controller: textController, focusNode: textFocusNode,
                      style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(border: InputBorder.none, hintText: 'Título'),
                      onSubmitted: (v) {
                        final updatedPage = page.copyWith(title: v);
                        ref.read(canvasDocumentProvider.notifier).renamePage(updatedPage, v);
                        ref.read(canvasToolProvider.notifier).clearTextEditing();
                      },
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildInlineTextEditor(BuildContext context, WidgetRef ref, TextBlock block) {
    final Color textColor = Color(int.parse(block.textColorHex.replaceFirst('#', '0xFF')));
    final double lineHeightPx = block.fontSize * block.lineHeight;
    final bool isProxy = block.id.startsWith('proxy_');
    final toolState = ref.read(canvasToolProvider);
    
    double editorWidth = 500;
    double? minHeight;
    
    if (isProxy && toolState.activeTableId != null && toolState.activeTableCell != null) {
       final table = page.objects.whereType<TableObject>().where((t) => t.id == toolState.activeTableId).firstOrNull;
       if (table != null) {
          final CellCoordinate coords = toolState.activeTableCell!.coordinate;
          int cs = 1; if (table.cellSpans.containsKey(coords)) cs = table.cellSpans[coords]!.col;
          editorWidth = 0; for (int i = 0; i < cs; i++) if (coords.col + i < table.columnWidths.length) editorWidth += table.columnWidths[coords.col + i];
          int rs = 1; if (table.cellSpans.containsKey(coords)) rs = table.cellSpans[coords]!.row;
          minHeight = 0; for (int i = 0; i < rs; i++) if (coords.row + i < table.rowHeights.length) minHeight = (minHeight ?? 0) + table.rowHeights[coords.row + i];
       }
    }

    return Positioned(
      left: block.position.dx, top: block.position.dy,
      child: Transform.rotate(
        angle: block.rotation, alignment: Alignment.center,
        child: Container(
          width: editorWidth, constraints: minHeight != null ? BoxConstraints(minHeight: minHeight) : null,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: block.backgroundColorHex != null ? Color(int.parse(block.backgroundColorHex!.replaceFirst('#', '0xFF'))).withOpacity(0.2) : (isProxy ? Colors.white : null),
            borderRadius: BorderRadius.circular(4), border: isProxy ? Border.all(color: Colors.blueAccent, width: 2) : null,
            boxShadow: isProxy ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              if (block.listType != ListType.none && !isProxy)
                IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: block.text.split('\n').asMap().entries.map((entry) {
                      Widget prefix = const SizedBox.shrink();
                      if (block.listType == ListType.bullet) prefix = Icon(Icons.circle, size: block.fontSize * 0.4, color: textColor.withOpacity(0.4));
                      else if (block.listType == ListType.numbered) prefix = Text('${entry.key + 1}.', style: TextStyle(fontSize: block.fontSize * 0.8, color: textColor.withOpacity(0.4), fontWeight: FontWeight.bold));
                      else if (block.listType == ListType.checklist) prefix = Icon(Icons.check_box_outline_blank_rounded, size: block.fontSize, color: textColor.withOpacity(0.3));
                      return Container(height: lineHeightPx * 1.15, width: 25, alignment: Alignment.centerLeft, child: prefix);
                    }).toList(),
                  ),
                ),
              TextField(
                controller: textController, focusNode: textFocusNode, maxLines: null, autofocus: true, textAlign: block.textAlign,
                style: GoogleFonts.getFont(block.fontFamily ?? 'Inter', fontSize: block.fontSize, height: block.lineHeight, fontWeight: block.isBold ? FontWeight.bold : FontWeight.normal, fontStyle: block.isItalic ? FontStyle.italic : FontStyle.normal, decoration: TextDecoration.combine([if (block.isUnderline) TextDecoration.underline, if (block.isStrikethrough) TextDecoration.lineThrough]), color: Color(int.parse(block.textColorHex.replaceFirst('#', '0xFF')))),
                decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.only(left: (block.listType != ListType.none && !isProxy) ? 30 : 8, top: 4, bottom: 4), isDense: true, hintText: isProxy ? '' : 'Escreva aqui...'),
                onChanged: (v) {
                  final updatedBlock = block.copyWith(text: v);
                  ref.read(canvasToolProvider.notifier).setTextEditing(InlineTarget.block, updatedBlock);
                  if (isProxy) {
                    _syncProxyToTable(ref, updatedBlock);
                    _autoAdjustRowHeight(v, updatedBlock, editorWidth, ref);
                  } else {
                    ref.read(canvasDocumentProvider.notifier).updateObject(page, updatedBlock);
                  }
                },
                onSubmitted: (_) => ref.read(canvasToolProvider.notifier).stopEditing(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _syncProxyToTable(WidgetRef ref, TextBlock proxy) {
    final toolState = ref.read(canvasToolProvider);
    if (toolState.activeTableId == null || toolState.activeTableCell == null) return;
    final table = page.objects.whereType<TableObject>().where((t) => t.id == toolState.activeTableId).firstOrNull;
    if (table == null) return;
    final CellCoordinate coords = toolState.activeTableCell!.coordinate;
    final currentCell = table.cells[coords] ?? TableCellModel();
    final updatedCell = currentCell.copyWith(
      value: proxy.text,
      style: currentCell.style.copyWith(
        bold: proxy.isBold, italic: proxy.isItalic, underline: proxy.isUnderline,
        strikethrough: proxy.isStrikethrough, fontSize: proxy.fontSize,
        textAlign: proxy.textAlign, fontFamily: proxy.fontFamily,
        textColorHex: proxy.textColorHex, backgroundColorHex: proxy.backgroundColorHex,
      ),
    );

    final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
    newCells[coords] = updatedCell;
    ref.read(canvasDocumentProvider.notifier).updateObject(page, table.copyWith(cells: newCells));
  }

  void _autoAdjustRowHeight(String text, TextBlock block, double width, WidgetRef ref) {
    final toolState = ref.read(canvasToolProvider);
    if (toolState.activeTableId == null || toolState.activeTableCell == null) return;
    final table = page.objects.whereType<TableObject>().firstWhere((t) => t.id == toolState.activeTableId);
    final int rowIndex = toolState.activeTableCell!.coordinate.row;
    final textPainter = TextPainter(text: TextSpan(text: text.isEmpty ? " " : text, style: GoogleFonts.getFont(block.fontFamily ?? 'Inter', fontSize: block.fontSize)), textDirection: TextDirection.ltr)..layout(maxWidth: width - 16);
    double finalHeight = math.max(40.0, textPainter.height + 16);
    if (finalHeight != table.rowHeights[rowIndex]) {
      final List<double> newHeights = List.from(table.rowHeights);
      newHeights[rowIndex] = finalHeight;
      ref.read(canvasDocumentProvider.notifier).updateObject(page, table.copyWith(rowHeights: newHeights));
    }
  }
}
