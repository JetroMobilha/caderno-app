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
    // 🚀 v10.85: Seletores otimizados para evitar re-renderizações por movimentos de outros objetos
    final activeBlock = ref.watch(canvasToolProvider.select((s) => s.activeTextBlock));
    final activeTableId = ref.watch(canvasToolProvider.select((s) => s.activeTableId));
    final activeInlineTarget = ref.watch(canvasToolProvider.select((s) => s.activeInlineTarget));

    final bool isEditing = activeBlock != null || 
                           activeTableId != null || 
                           activeInlineTarget == InlineTarget.title;

    if (!isEditing) return const SizedBox.shrink();

    return Stack(
      children: [
        if (activeBlock != null)
          _buildInlineTextEditor(context, ref, activeBlock, activeTableId),
        
        Positioned(
          top: 35, left: 0, right: 0,
          child: Center(
            child: activeInlineTarget == InlineTarget.title
                ? SizedBox(
                    width: 400,
                    child: TextField(
                      textAlign: TextAlign.center, autofocus: true,
                      controller: textController, focusNode: textFocusNode,
                      style: _getSafeTextStyle('Lora', fontSize: 28, fontWeight: FontWeight.bold),
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

  Widget _buildInlineTextEditor(BuildContext context, WidgetRef ref, TextBlock block, String? activeTableId) {
    final Color textColor = _parseColorHex(block.textColorHex);
    final bool isProxy = block.id.startsWith('proxy_');
    final toolState = ref.read(canvasToolProvider);
    
    // 🚀 v10.60: Contadores por nível
    final Map<int, int> levelCounters = {};

    double editorWidth = 500;
    double? minHeight;
    Offset position = block.position; // 🚀 v10.60: Posição dinâmica reativa
    
    if (isProxy && activeTableId != null && toolState.activeTableCell != null) {
       final table = page.objects.whereType<TableObject>().where((t) => t.id == activeTableId).firstOrNull;
       if (table != null) {
          final CellCoordinate coords = toolState.activeTableCell!.coordinate;
          
          // 🚀 v10.60: Utilizar nova API de geometria do modelo (Centralizado)
          position = table.position + table.getCellOffset(coords);
          final cellSize = table.getCellSize(coords);
          
          editorWidth = cellSize.width;
          minHeight = cellSize.height;
       }
    }

    return Positioned(
      left: position.dx, top: position.dy,
      child: Transform.rotate(
        angle: block.rotation, alignment: Alignment.center,
        child: Container(
          width: editorWidth, constraints: minHeight != null ? BoxConstraints(minHeight: minHeight) : null,
          padding: EdgeInsets.zero, // 🚀 v10.60: Padding movido para o TextField para precisão
          decoration: BoxDecoration(
            color: block.backgroundColorHex != null ? _parseColorHex(block.backgroundColorHex).withValues(alpha: 0.2) : (isProxy ? Colors.white : null),
            borderRadius: BorderRadius.circular(isProxy ? 0 : 4), // Quadrado se for tabela
            border: isProxy ? Border.all(color: Colors.blueAccent.withValues(alpha: 0.8), width: 1.5) : null,
            boxShadow: isProxy ? [BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)] : null,
          ),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
                Padding(
                  padding: const EdgeInsets.only(left: 4.0, top: 4.0), // 🚀 v10.63: Sincronizado com contentPadding.top e left do ObjectRenderer
                  child: IgnorePointer(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: block.text.split('\n').asMap().entries.map((entry) {
                        final line = entry.value;
                        int spaces = 0;
                        for (int i = 0; i < line.length; i++) {
                          if (line[i] == ' ') {
                            spaces++;
                          } else {
                            break;
                          }
                        }
                        int level = spaces ~/ 2;

                        Widget prefix = const SizedBox.shrink();
                        if (block.listType == ListType.bullet) {
                          IconData icon = Icons.circle;
                          if (level == 1) icon = Icons.circle_outlined;
                          else if (level >= 2) icon = Icons.square_rounded;
                          prefix = Icon(icon, size: block.fontSize * (level == 0 ? 0.4 : 0.35), color: textColor.withValues(alpha: 0.4));
                        } else if (block.listType == ListType.numbered) {
                          levelCounters.removeWhere((k, v) => k > level);
                          levelCounters[level] = (levelCounters[level] ?? 0) + 1;

                          String label = '${levelCounters[level]}.';
                          if (level == 1) {
                            label = '${String.fromCharCode(96 + (levelCounters[level]! % 26))}.';
                          } else if (level >= 2) {
                            label = '-';
                          }
                          prefix = Text(label, style: TextStyle(fontSize: block.fontSize * 0.8, color: textColor.withValues(alpha: 0.4), fontWeight: FontWeight.bold));
                        } else if (block.listType == ListType.checklist) {
                          prefix = Icon(Icons.check_box_outline_blank_rounded, size: block.fontSize, color: textColor.withValues(alpha: 0.3));
                        }

                        // 🚀 v10.63: Cálculo de altura REAL sem margens extras para evitar deriva vertical
                        final double paragraphHeight = _calculateHeight(
                          line.trimLeft(), 
                          block.fontFamily, 
                          block.fontSize, 
                          block.lineHeight, 
                          editorWidth, 
                          true
                        );

                        return Container(
                          key: ValueKey('list_prefix_${entry.key}'), // 🚀 v10.85: Chave única para diffing otimizado
                          height: paragraphHeight, 
                          alignment: Alignment.topLeft, 
                          padding: EdgeInsets.only(left: 1.0 + (level * 10.0), top: block.fontSize * 0.22), // 🚀 v10.63: Compensação de leading exata
                          child: SizedBox(
                            width: 24, 
                            child: prefix,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ),
              TextField(
                controller: textController, focusNode: textFocusNode, maxLines: null, autofocus: true, textAlign: block.textAlign,
                style: _getSafeTextStyle(
                  block.fontFamily,
                  fontSize: block.fontSize,
                  height: block.lineHeight,
                  fontWeight: block.isBold ? FontWeight.bold : FontWeight.normal,
                  fontStyle: block.isItalic ? FontStyle.italic : FontStyle.normal,
                  decoration: TextDecoration.combine([
                    if (block.isUnderline) TextDecoration.underline,
                    if (block.isStrikethrough) TextDecoration.lineThrough
                  ]),
                  color: textColor,
                ),
                decoration: InputDecoration(border: InputBorder.none, contentPadding: EdgeInsets.only(left: (block.listType != ListType.none) ? 28 : 4, right: 4, top: 4, bottom: isProxy ? 4 : 60), isDense: true, hintText: isProxy ? '' : 'Escreva aqui...'),
                onChanged: (v) {
                  String finalValue = v;
                  final selection = textController.selection;

                  if (v.length > block.text.length && selection.baseOffset > 0) {
                    final lastChar = v[selection.baseOffset - 1];
                    if (lastChar == '\n') {
                      final textBeforeCursor = v.substring(0, selection.baseOffset - 1);
                      final linesBefore = textBeforeCursor.split('\n');
                      if (linesBefore.isNotEmpty) {
                        final lastLine = linesBefore.last;
                        int spacesCount = 0;
                        for (int i = 0; i < lastLine.length; i++) {
                          if (lastLine[i] == ' ') spacesCount++;
                          else break;
                        }
                        if (spacesCount > 0) {
                          final spacesStr = ' ' * spacesCount;
                          final newValue = v.substring(0, selection.baseOffset) + spacesStr + v.substring(selection.baseOffset);
                          finalValue = newValue;

                          textController.text = newValue;
                          textController.selection = TextSelection.fromPosition(
                            TextPosition(offset: selection.baseOffset + spacesCount),
                          );
                        }
                      }
                    }
                  }

                  final updatedBlock = block.copyWith(text: finalValue);
                  ref.read(canvasToolProvider.notifier).setTextEditing(InlineTarget.block, updatedBlock);
                  if (isProxy) {
                    _syncProxyToTable(ref, updatedBlock);
                    _autoAdjustRowHeight(finalValue, updatedBlock, editorWidth, ref);
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
        listType: proxy.listType, // 🚀 v10.60
        checkedLineIndices: proxy.checkedLineIndices, // 🚀 v10.60
      ),
    );

    final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
    newCells[coords] = updatedCell;
    ref.read(canvasDocumentProvider.notifier).updateObject(page, table.copyWith(cells: newCells));
  }

  double _calculateHeight(String text, String? fontFamily, double fontSize, double lineHeight, double width, bool hasList) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text.isEmpty ? " " : text, 
        style: _getSafeTextStyle(fontFamily, fontSize: fontSize, height: lineHeight),
      ), 
      textDirection: TextDirection.ltr
    )..layout(maxWidth: math.max(10.0, width - (hasList ? 32 : 8))); 
    return textPainter.height; // 🚀 v10.63: Altura PURA para sincronização absoluta
  }

  void _autoAdjustRowHeight(String text, TextBlock block, double width, WidgetRef ref) {
    final toolState = ref.read(canvasToolProvider);
    if (toolState.activeTableId == null || toolState.activeTableCell == null) return;
    
    final table = page.objects.whereType<TableObject>().where((t) => t.id == toolState.activeTableId).firstOrNull;
    if (table == null) return;
    
    final int rowIndex = toolState.activeTableCell!.coordinate.row;
    final CellCoordinate activeCoords = toolState.activeTableCell!.coordinate;
    
    // 🚀 v10.60: Utiliza nova lógica centralizada no modelo para varrimento de linha
    final double maxHeight = table.calculateRequiredRowHeight(rowIndex, (coords, cellWidth) {
      if (coords == activeCoords) {
        return _calculateHeight(text, block.fontFamily, block.fontSize, block.lineHeight, cellWidth, block.listType != ListType.none) + 8.0;
      } else {
        final cell = table.cells[coords] ?? TableCellModel();
        return _calculateHeight(cell.value, cell.style.fontFamily, cell.style.fontSize, 1.6, cellWidth, cell.style.listType != ListType.none) + 8.0;
      }
    });
    
    if ((maxHeight - table.rowHeights[rowIndex]).abs() > 0.5) {
      final List<double> newHeights = List<double>.from(table.rowHeights);
      newHeights[rowIndex] = maxHeight;
      
      // 🚀 v10.85: Adiamento de mutação de estado para evitar colisão no ciclo de build
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(canvasDocumentProvider.notifier).updateObject(page, table.copyWith(rowHeights: newHeights));
      });
    }
  }

  // 🚀 v10.85: Helpers de segurança e performance

  Color _parseColorHex(String? hex, {Color fallback = Colors.black}) {
    if (hex == null || hex.isEmpty) return fallback;
    try {
      final String cleanHex = hex.replaceFirst('#', '');
      if (cleanHex.length == 6) return Color(int.parse('0xFF$cleanHex'));
      if (cleanHex.length == 8) return Color(int.parse('0x$cleanHex'));
      return Color(int.parse(hex.replaceFirst('#', '0xFF')));
    } catch (_) {
      return fallback;
    }
  }

  TextStyle _getSafeTextStyle(String? fontFamily, {
    double? fontSize,
    double? height,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    TextDecoration? decoration,
    Color? color,
  }) {
    final String family = fontFamily ?? 'Inter';
    try {
      return GoogleFonts.getFont(
        family,
        fontSize: fontSize,
        height: height,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        decoration: decoration,
        color: color,
      );
    } catch (_) {
      return TextStyle(
        fontFamily: family,
        fontSize: fontSize,
        height: height,
        fontWeight: fontWeight,
        fontStyle: fontStyle,
        decoration: decoration,
        color: color,
      );
    }
  }
}
