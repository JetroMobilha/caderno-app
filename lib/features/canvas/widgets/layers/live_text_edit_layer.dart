import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/text_block_model.dart';
import '../../models/table_model.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/local_page_model.dart';
import '../../models/canvas_enums.dart';

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

    // 🚀 v4.3: Otimização de Gestos - Só capturar se houver algo ativo
    final bool isEditing = toolState.activeTextBlock != null || 
                           toolState.activeTableId != null || 
                           toolState.activeInlineTarget == InlineTarget.title;

    return IgnorePointer(
      ignoring: !isEditing, // 🚀 Não bloquear camadas inferiores se não estivermos a editar
      child: Stack(
        fit: StackFit.expand,
        children: [
          // 🚀 v3.4: EDIÇÃO INLINE GHOST (SEM CAIXAS, COM ROTAÇÃO)
          if (toolState.activeTextBlock != null)
            _buildInlineTextEditor(context, ref, toolState.activeTextBlock!),

          // 🚀 v3.4: EDIÇÃO INLINE DE TABELA
          if (toolState.activeTableId != null && toolState.activeTableCell != null)
            _buildInlineTableEditor(context, ref, toolState),
          
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
                          toolNotifier.clearTextEditing();
                        },
                      ),
                    )
                  : const SizedBox.shrink(), // O título "estático" é renderizado pelo InteractionLayer ou Background
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInlineTextEditor(BuildContext context, WidgetRef ref, TextBlock block) {
    final List<String> lines = block.text.split('\n');
    final Color textColor = Color(int.parse(block.textColorHex.replaceFirst('#', '0xFF')));
    final double lineHeightPx = block.fontSize * block.lineHeight;

    return Positioned(
      left: block.position.dx,
      top: block.position.dy,
      child: Transform.rotate(
        angle: block.rotation,
        alignment: Alignment.center,
        child: Container(
          width: 500, 
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          decoration: BoxDecoration(
            color: block.backgroundColorHex != null ? Color(int.parse(block.backgroundColorHex!.replaceFirst('#', '0xFF'))).withOpacity(0.2) : null,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Stack(
            children: [
              // 🚀 v3.6: Camada de Indicadores Alinhada
              if (block.listType != ListType.none)
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
                        height: lineHeightPx * 1.15, // Pequeno ajuste para alinhar com o cursor do TextField
                        width: 25,
                        alignment: Alignment.centerLeft,
                        child: prefix,
                      );
                    }).toList(),
                  ),
                ),

              // O TextField principal com padding dinâmico
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
                  contentPadding: EdgeInsets.only(left: block.listType != ListType.none ? 30 : 0),
                  isDense: true,
                  hintText: 'Escreva aqui...',
                ),
                onChanged: (v) => block.text = v,
              ),
            ],
          ),
        ),
      ),
    );
  }

  CrossAxisAlignment _getCrossAxisAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center: return CrossAxisAlignment.center;
      case TextAlign.right: return CrossAxisAlignment.end;
      default: return CrossAxisAlignment.start;
    }
  }

  Widget _buildInlineTableEditor(BuildContext context, WidgetRef ref, CanvasToolState toolState) {
    final table = page.objects.whereType<TableObject>().firstWhere((t) => t.id == toolState.activeTableId);
    final coords = toolState.activeTableCell!.split(',');
    final int row = int.parse(coords[0]);
    final int col = int.parse(coords[1]);

    final cellWidth = table.size.width / table.cols;
    final cellHeight = table.size.height / table.rows;
    final cellOffset = Offset(col * cellWidth, row * cellHeight);
    
    return Positioned(
      left: table.position.dx,
      top: table.position.dy,
      child: Transform.rotate(
        angle: table.rotation,
        alignment: Alignment.center,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: cellOffset.dx,
              top: cellOffset.dy,
              child: Container(
                width: cellWidth, height: cellHeight,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.blueAccent, width: 2),
                ),
                child: TextField(
                  controller: textController,
                  focusNode: textFocusNode,
                  maxLines: null,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: cellHeight * 0.4),
                  decoration: const InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.all(4), isDense: true),
                  onChanged: (v) => table.cellData['$row,$col'] = v,
                  onSubmitted: (_) {
                    ref.read(canvasToolProvider.notifier).clearTextEditing();
                    ref.read(canvasDocumentProvider.notifier).updateObject(page, table);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
