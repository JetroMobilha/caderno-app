import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/text_block_model.dart';
import '../../models/table_model.dart';
import '../../models/table_cell_model.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/local_page_model.dart';
import '../../models/canvas_enums.dart';

/// Camada de edição de texto ativa (Inline).
/// Responsável por renderizar os [TextField]s sobre os objetos reais (Ghost Mode)
/// permitindo uma edição fluida e WYSIWYG.
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
    final toolNotifier = ref.read(canvasToolProvider.notifier);

    // 🚀 v5.3: Sync Automático de Estilo (Toolbar -> Tabela) via Listener
    ref.listen(canvasToolProvider, (prev, next) {
       if (next.activeTextBlock != null && next.activeTextBlock!.id.startsWith('proxy_')) {
          _syncProxyToTable(ref, next.activeTextBlock!);
       }
    });

    final bool isEditing = toolState.activeTextBlock != null || 
                           toolState.activeTableId != null || 
                           toolState.activeInlineTarget == InlineTarget.title;

    // 🚀 v5.5: Melhoria de Hit-Testing. 
    // Se não estivermos editando, ignoramos TUDO para não bloquear a InteractionLayer.
    if (!isEditing) return const SizedBox.shrink();

    return Stack(
      children: [
        // 🚀 v5.3: Reuso Absoluto - O editor de blocos agora lida com células via Proxy
        if (toolState.activeTextBlock != null)
          _buildInlineTextEditor(context, ref, toolState.activeTextBlock!),
        
        // Título da Página
        Positioned(
          top: 35, left: 0, right: 0,
          child: Center(
            child: toolState.activeInlineTarget == InlineTarget.title
                ? SizedBox(
                    width: 400,
                    child: TextField(
                      textAlign: TextAlign.center,
                      autofocus: true,
                      controller: textController,
                      focusNode: textFocusNode,
                      style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.bold),
                      decoration: const InputDecoration(border: InputBorder.none, hintText: 'Título'),
                      onSubmitted: (v) {
                        page.title = v;
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
    final List<String> lines = block.text.split('\n');
    final Color textColor = Color(int.parse(block.textColorHex.replaceFirst('#', '0xFF')));
    final double lineHeightPx = block.fontSize * block.lineHeight;

    // 🚀 v5.4: Calcular largura real se for um Proxy de Tabela
    double editorWidth = 500;
    double? minHeight;
    final toolState = ref.read(canvasToolProvider);
    final bool isProxy = block.id.startsWith('proxy_');
    
    if (isProxy && toolState.activeTableId != null && toolState.activeTableCell != null) {
       final table = page.objects.whereType<TableObject>().where((t) => t.id == toolState.activeTableId).firstOrNull;
       if (table != null) {
          final coords = toolState.activeTableCell!.split(':').last.split(',');
          final col = int.parse(coords[1]);
          final row = int.parse(coords[0]);
          
          int cs = 1;
          if (table.cellSpans.containsKey('${coords[0]},${coords[1]}')) {
            cs = int.parse(table.cellSpans['${coords[0]},${coords[1]}']!.split(',')[1]);
          }
          editorWidth = 0;
          for (int i = 0; i < cs; i++) {
            if (col + i < table.columnWidths.length) editorWidth += table.columnWidths[col + i];
          }

          int rs = 1;
          if (table.cellSpans.containsKey('${coords[0]},${coords[1]}')) {
            rs = int.parse(table.cellSpans['${coords[0]},${coords[1]}']!.split(',')[0]);
          }
          minHeight = 0;
          for (int i = 0; i < rs; i++) {
            if (row + i < table.rowHeights.length) minHeight = (minHeight ?? 0) + table.rowHeights[row + i];
          }
       }
    }

    return Positioned(
      left: block.position.dx,
      top: block.position.dy,
      child: Transform.rotate(
        angle: block.rotation,
        alignment: Alignment.center,
        child: Container(
          width: editorWidth, 
          constraints: minHeight != null ? BoxConstraints(minHeight: minHeight) : null,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: block.backgroundColorHex != null 
                ? Color(int.parse(block.backgroundColorHex!.replaceFirst('#', '0xFF'))).withOpacity(0.2) 
                : (isProxy ? Colors.white : null),
            borderRadius: BorderRadius.circular(4),
            border: isProxy ? Border.all(color: Colors.blueAccent, width: 2) : null,
            boxShadow: isProxy ? [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4)] : null, // 🚀 v5.8
          ),
          child: Stack(
            clipBehavior: Clip.none, // 🚀 v5.8
            children: [
              if (block.listType != ListType.none && !isProxy)
                IgnorePointer(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: lines.asMap().entries.map((entry) {
                      final int idx = entry.key;
                      Widget prefix = const SizedBox.shrink();
                      
                      if (block.listType == ListType.bullet) {
                        prefix = Icon(Icons.circle, size: block.fontSize * 0.4, color: textColor.withOpacity(0.4));
                      } else if (block.listType == ListType.numbered) {
                        prefix = Text('${idx + 1}.', style: TextStyle(fontSize: block.fontSize * 0.8, color: textColor.withOpacity(0.4), fontWeight: FontWeight.bold));
                      } else if (block.listType == ListType.checklist) {
                        prefix = Icon(Icons.check_box_outline_blank_rounded, size: block.fontSize, color: textColor.withOpacity(0.3));
                      }

                      return Container(
                        height: lineHeightPx * 1.15,
                        width: 25,
                        alignment: Alignment.centerLeft,
                        child: prefix,
                      );
                    }).toList(),
                  ),
                ),

              TextField(
                controller: textController,
                focusNode: textFocusNode,
                maxLines: null,
                autofocus: true,
                textAlign: block.textAlign,
                style: GoogleFonts.getFont(
                  block.fontFamily ?? 'Inter',
                  fontSize: block.fontSize,
                  height: block.lineHeight,
                  fontWeight: block.isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: block.isItalic ? FontStyle.italic : FontStyle.normal,
                  decoration: TextDecoration.combine([
                    if (block.isUnderline) TextDecoration.underline,
                    if (block.isStrikethrough) TextDecoration.lineThrough,
                  ]),
                  color: Color(int.parse(block.textColorHex.replaceFirst('#', '0xFF'))),
                ),
                decoration: InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.only(left: (block.listType != ListType.none && !isProxy) ? 30 : 8, top: 4, bottom: 4),
                  isDense: true,
                  hintText: isProxy ? '' : 'Escreva aqui...',
                ),
                onSubmitted: (_) {
                  // 🚀 v5.8: Parar edição mas manter ferramenta ativa (Preenchimento contínuo)
                  ref.read(canvasToolProvider.notifier).stopEditing();
                },
                onChanged: (v) {
                  block.text = v;
                  if (isProxy) {
                    _syncProxyToTable(ref, block);
                    final toolState = ref.read(canvasToolProvider);
                    if (toolState.activeTableCell != null) {
                      final table = page.objects.whereType<TableObject>().where((t) => t.id == toolState.activeTableId).firstOrNull;
                      if (table != null) {
                        final coords = toolState.activeTableCell!.split(':').last.split(',');
                        final int col = int.parse(coords[1]);
                        int cs = 1;
                        if (table.cellSpans.containsKey('${coords[0]},${coords[1]}')) {
                          cs = int.parse(table.cellSpans['${coords[0]},${coords[1]}']!.split(',')[1]);
                        }
                        double cellWidth = 0;
                        for (int i = 0; i < cs; i++) {
                           if (col + i < table.columnWidths.length) cellWidth += table.columnWidths[col + i];
                        }
                        _autoAdjustRowHeight(v, block, cellWidth, ref);
                      }
                    }
                  }
                },
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
    
    final cellCoords = toolState.activeTableCell!.split(':').last;
    final cell = table.cells[cellCoords] ?? TableCellModel();
    
    cell.value = proxy.text;
    cell.style.bold = proxy.isBold;
    cell.style.italic = proxy.isItalic;
    cell.style.underline = proxy.isUnderline;
    cell.style.strikethrough = proxy.isStrikethrough;
    cell.style.fontSize = proxy.fontSize;
    cell.style.textAlign = proxy.textAlign;
    cell.style.fontFamily = proxy.fontFamily;
    cell.style.textColorHex = proxy.textColorHex;
    cell.style.backgroundColorHex = proxy.backgroundColorHex;

    table.cells[cellCoords] = cell;
    ref.read(canvasDocumentProvider.notifier).updateObject(page, table);
  }

  CrossAxisAlignment _getCrossAxisAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center: return CrossAxisAlignment.center;
      case TextAlign.right: return CrossAxisAlignment.end;
      default: return CrossAxisAlignment.start;
    }
  }

  void _autoAdjustRowHeight(String text, TextBlock block, double width, WidgetRef ref) {
    final toolState = ref.read(canvasToolProvider);
    if (block.id.startsWith('proxy_') && toolState.activeTableId != null && toolState.activeTableCell != null) {
      final table = page.objects.whereType<TableObject>().firstWhere((t) => t.id == toolState.activeTableId);
      final rowIndex = int.parse(toolState.activeTableCell!.split(':').last.split(',')[0]);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: text.isEmpty ? " " : text,
          style: GoogleFonts.getFont(block.fontFamily ?? 'Inter', fontSize: block.fontSize),
        ),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: width - 16);

      double neededHeight = textPainter.height + 16; 
      const double minHeight = 40.0;
      double finalHeight = neededHeight > minHeight ? neededHeight : minHeight;

      if (finalHeight != table.rowHeights[rowIndex]) {
        table.rowHeights[rowIndex] = finalHeight;
        ref.read(canvasDocumentProvider.notifier).updateObject(page, table);
      }
    }
  }
}
