import 'dart:math' as math;
import 'package:caderno_digital_app/features/shared/widgets/color_engine_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/features/canvas/models/text_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/canvas_enums.dart';
import 'package:caderno_digital_app/features/canvas/providers/canvas_tool_provider.dart';
import 'package:caderno_digital_app/features/canvas/providers/canvas_document_provider.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';

import '../../models/table_cell_model.dart';
import '../../models/table_model.dart';

enum TextEditCategory { basics, format, organize, structure, box }

/// Barra de ferramentas contextual para edição de texto.
/// Oferece opções de formatação, alinhamento, listas e gestão de blocos.
/// É reutilizada para edições de células de tabela via Proxy.
class TextEditToolbar extends ConsumerStatefulWidget {
  final TextBlock? block;
  final LocalPage currentPage;

  const TextEditToolbar({
    super.key,
    required this.block,
    required this.currentPage,
  });

  @override
  ConsumerState<TextEditToolbar> createState() => _TextEditToolbarState();
}

class _TextEditToolbarState extends ConsumerState<TextEditToolbar> {
  TextEditCategory _activeCategory = TextEditCategory.format;

  void _handleExit() async {
    debugPrint('🔙 [TextToolbar] Saindo do modo escrita...');
    
    // 1. Fechar teclado imediatamente
    FocusManager.instance.primaryFocus?.unfocus();

    if (widget.block != null) {
      await ref.read(canvasDocumentProvider.notifier).cleanupIfEmpty(widget.currentPage, widget.block!.id);
    }

    // 2. Limpar estado no provider
    ref.read(canvasToolProvider.notifier).exitWritingMode();
  }

  @override
  Widget build(BuildContext context) {
    final toolState = ref.watch(canvasToolProvider);
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final docState = ref.watch(canvasDocumentProvider);
    final docNotifier = ref.read(canvasDocumentProvider.notifier);

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;

    return Container(
      constraints: BoxConstraints(maxWidth: isSmallScreen ? screenWidth - 24 : 500),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8))
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              _buildCustomIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: _handleExit, 
                color: const Color(0xFF0F4C5C),
                size: 18,
              ),
              // 🚀 v6.5: Modo de Transformação Deliberado para Texto
              _buildCustomIconButton(
                icon: Icons.open_with_rounded, 
                onTap: () => toolNotifier.toggleTransformMode(), 
                color: toolState.isTransformMode ? Colors.orangeAccent : Colors.black54,
                size: 20,
              ),
              const VerticalDivider(width: 24, indent: 8, endIndent: 8),
              Expanded(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildCategoryTab(TextEditCategory.basics, Icons.edit_note_rounded, 'Geral'),
                      _buildCategoryTab(TextEditCategory.format, Icons.format_size_rounded, 'Estilo'),
                      _buildCategoryTab(TextEditCategory.organize, Icons.format_align_center_rounded, 'Layout'),
                      _buildCategoryTab(TextEditCategory.structure, Icons.format_list_bulleted_rounded, 'Lista'),
                      _buildCategoryTab(TextEditCategory.box, Icons.inventory_2_outlined, 'Caixa'),
                    ],
                  ),
                ),
              ),
            ],
          ),

          const Divider(height: 16, color: Colors.black12, indent: 4, endIndent: 4),

          Center(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.block != null) 
                    _buildActiveCategoryContent(context, toolNotifier, docState, docNotifier, widget.block!)
                  else
                    const Text('TOQUE NUM TEXTO PARA FORMATAR',
                      style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black26, letterSpacing: 1.2)
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(TextEditCategory cat, IconData icon, String label) {
    final bool isActive = _activeCategory == cat;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = cat),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.symmetric(horizontal: 4),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF0F4C5C).withOpacity(0.08) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: isActive ? const Color(0xFF0F4C5C) : Colors.black38),
            if (isActive) ...[
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0F4C5C))),
            ],
          ],
        ),
      ),
    );
  }

  /// 🚀 v6.6: Helper para persistir alterações, suportando Blocos de Texto e Proxies de Tabela.
  void _updateBlock(CanvasDocumentNotifier docNotifier, TextBlock block) {
    if (block.id.startsWith('proxy_')) {
      final parts = block.id.split('_');
      if (parts.length < 3) return;
      final tableId = parts[1];
      final cellCoords = parts[2];

      final docState = ref.read(canvasDocumentProvider);
      final page = docState.pages.firstWhere((p) => p.clientId == widget.currentPage.clientId);
      final table = page.objects.whereType<TableObject>().firstWhere((t) => t.id == tableId);

      // Sincronizar estilos do Proxy com a célula real da tabela
      final cell = table.cells[cellCoords] ?? TableCellModel();
      cell.value = block.text;
      cell.style.bold = block.isBold;
      cell.style.italic = block.isItalic;
      cell.style.underline = block.isUnderline;
      cell.style.strikethrough = block.isStrikethrough;
      cell.style.fontSize = block.fontSize;
      cell.style.fontFamily = block.fontFamily;
      cell.style.textColorHex = block.textColorHex;
      cell.style.backgroundColorHex = block.backgroundColorHex;
      cell.style.textAlign = block.textAlign;
      
      table.cells[cellCoords] = cell;
      docNotifier.updateObject(page, table);
    } else {
      final page = ref.read(canvasDocumentProvider).pages.firstWhere((p) => p.clientId == widget.currentPage.clientId);
      docNotifier.updateObject(page, block);
    }
  }

  Widget _buildActiveCategoryContent(BuildContext context, CanvasToolNotifier notifier, CanvasDocumentState docState, CanvasDocumentNotifier docNotifier, TextBlock block) {
    switch (_activeCategory) {
      case TextEditCategory.basics:
        return Row(
          children: [
            _buildCustomIconButton(icon: Icons.content_copy_rounded, onTap: () {}, color: Colors.black87),
            _buildCustomIconButton(icon: Icons.undo_rounded,
              onTap: docState.undoStack.isNotEmpty ? () => docNotifier.undo(widget.currentPage) : null,
              color: docState.undoStack.isNotEmpty ? Colors.black87 : Colors.black12),
            _buildCustomIconButton(icon: Icons.redo_rounded,
              onTap: docState.redoStack.isNotEmpty ? () => docNotifier.redo(widget.currentPage) : null,
              color: docState.redoStack.isNotEmpty ? Colors.black87 : Colors.black12),
            _buildCustomIconButton(icon: Icons.select_all_rounded, onTap: () {}, color: Colors.black87),
          ],
        );
      case TextEditCategory.format:
        return Row(
          children: [
            _buildFontFamilyDropdown(notifier, docNotifier, block),
            const SizedBox(width: 12),
            _buildFormatToggle(Icons.format_bold, block.isBold, () {
              setState(() {
                block.isBold = !block.isBold;
              });
              _updateBlock(docNotifier, block);
              notifier.setTextEditing(InlineTarget.block, block);
            }),
            _buildFormatToggle(Icons.format_italic, block.isItalic, () {
              setState(() {
                block.isItalic = !block.isItalic;
              });
              _updateBlock(docNotifier, block);
              notifier.setTextEditing(InlineTarget.block, block);
            }),
            _buildFormatToggle(Icons.format_underlined, block.isUnderline, () {
              setState(() {
                block.isUnderline = !block.isUnderline;
              });
              _updateBlock(docNotifier, block);
              notifier.setTextEditing(InlineTarget.block, block);
            }),
            const SizedBox(width: 12),
            _buildColorCircle(context, notifier, docNotifier, block),
            _buildCustomIconButton(icon: Icons.format_color_fill_rounded, onTap: () async {
               final hex = await ColorEngine.show(context, initialColor: block.backgroundColorHex ?? '#FFFFFF', title: 'Cor de Realce');
               if (hex != null) {
                 block.backgroundColorHex = hex;
                 notifier.setTextEditing(InlineTarget.block, block);
                 _updateBlock(docNotifier, block);
               }
            }, color: block.backgroundColorHex != null ? Color(int.parse(block.backgroundColorHex!.replaceFirst('#', '0xFF'))) : Colors.black26),
          ],
        );
      case TextEditCategory.organize:
        return Row(
          children: [
            _buildFormatToggle(Icons.format_align_left_rounded, block.textAlign == TextAlign.left, () {
              setState(() { block.textAlign = TextAlign.left; });
              _updateBlock(docNotifier, block);
              notifier.setTextEditing(InlineTarget.block, block);
            }),
            _buildFormatToggle(Icons.format_align_center_rounded, block.textAlign == TextAlign.center, () {
              setState(() { block.textAlign = TextAlign.center; });
              _updateBlock(docNotifier, block);
              notifier.setTextEditing(InlineTarget.block, block);
            }),
            _buildFormatToggle(Icons.format_align_right_rounded, block.textAlign == TextAlign.right, () {
              setState(() { block.textAlign = TextAlign.right; });
              _updateBlock(docNotifier, block);
              notifier.setTextEditing(InlineTarget.block, block);
            }),
            _buildFormatToggle(Icons.format_align_justify_rounded, block.textAlign == TextAlign.justify, () {
              setState(() { block.textAlign = TextAlign.justify; });
              _updateBlock(docNotifier, block);
              notifier.setTextEditing(InlineTarget.block, block);
            }),
            const SizedBox(width: 12),
            _buildCustomIconButton(icon: Icons.text_increase, onTap: () {
              setState(() { block.fontSize += 2; });
              _updateBlock(docNotifier, block);
              notifier.setTextEditing(InlineTarget.block, block);
            }, color: const Color(0xFF0F4C5C)),
            _buildCustomIconButton(icon: Icons.text_decrease, onTap: () {
              if (block.fontSize > 8) {
                setState(() { block.fontSize -= 2; });
                _updateBlock(docNotifier, block);
                notifier.setTextEditing(InlineTarget.block, block);
              }
            }, color: const Color(0xFF0F4C5C)),
          ],
        );
      case TextEditCategory.structure:
        return Row(
          children: [
            _buildFormatToggle(Icons.format_list_bulleted_rounded, block.listType == ListType.bullet, () {
              setState(() {
                block.listType = block.listType == ListType.bullet ? ListType.none : ListType.bullet;
              });
              _updateBlock(docNotifier, block);
              notifier.setTextEditing(InlineTarget.block, block);
            }),
            _buildFormatToggle(Icons.format_list_numbered_rounded, block.listType == ListType.numbered, () {
              setState(() {
                block.listType = block.listType == ListType.numbered ? ListType.none : ListType.numbered;
              });
              _updateBlock(docNotifier, block);
              notifier.setTextEditing(InlineTarget.block, block);
            }),
            _buildFormatToggle(Icons.checklist_rounded, block.listType == ListType.checklist, () {
              setState(() {
                block.listType = block.listType == ListType.checklist ? ListType.none : ListType.checklist;
              });
              _updateBlock(docNotifier, block);
              notifier.setTextEditing(InlineTarget.block, block);
            }),
            const SizedBox(width: 12),
            _buildFormatToggle(Icons.title_rounded, block.fontSize > 24, () {
               setState(() {
                 block.fontSize = (block.fontSize > 24) ? 18 : 32;
                 block.isBold = block.fontSize > 24;
               });
               _updateBlock(docNotifier, block);
               notifier.setTextEditing(InlineTarget.block, block);
            }),
          ],
        );
      case TextEditCategory.box:
        return Row(
          children: [
            _buildCustomIconButton(icon: Icons.copy_rounded, onTap: () {
               final page = docState.pages.firstWhere((p) => p.clientId == widget.currentPage.clientId);
               final clone = block.clone(newId: const Uuid().v4())..position += const Offset(20, 20);
               docNotifier.addTextBlock(page, clone);
            }, color: Colors.black54),
            _buildCustomIconButton(icon: Icons.flip_to_front_rounded, onTap: () {
               final page = docState.pages.firstWhere((p) => p.clientId == widget.currentPage.clientId);
               int maxZ = 0;
               if (page.objects.isNotEmpty) {
                 for (var o in page.objects) { if (o.zIndex > maxZ) maxZ = o.zIndex; }
               }
               block.zIndex = maxZ + 1;
               docNotifier.updateObject(page, block);
            }, color: Colors.black87),
            _buildCustomIconButton(icon: block.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, onTap: () {
               block.isLocked = !block.isLocked;
               notifier.setTextEditing(InlineTarget.block, block);
               _updateBlock(docNotifier, block);
            }, color: block.isLocked ? Colors.orange : Colors.black87),
            _buildCustomIconButton(icon: Icons.delete_outline_rounded, onTap: () {
               final page = docState.pages.firstWhere((p) => p.clientId == widget.currentPage.clientId);
               docNotifier.deleteObjects(page, [block.id]);
               notifier.exitWritingMode();
            }, color: Colors.redAccent),
          ],
        );
    }
  }

  Widget _buildFontFamilyDropdown(CanvasToolNotifier notifier, CanvasDocumentNotifier docNotifier, TextBlock block) {
    final fonts = ['Inter', 'Lora', 'Roboto', 'Oswald', 'Dancing Script'];
    return PopupMenuButton<String>(
      initialValue: block.fontFamily ?? 'Inter',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
        child: Row(
          children: [
            Text(block.fontFamily ?? 'Inter', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)),
            const Icon(Icons.arrow_drop_down, size: 14),
          ],
        ),
      ),
      onSelected: (font) {
        setState(() {
          block.fontFamily = font;
        });
        _updateBlock(docNotifier, block);
        notifier.setTextEditing(InlineTarget.block, block);
      },
      itemBuilder: (ctx) => fonts.map((f) => PopupMenuItem(value: f, child: Text(f, style: GoogleFonts.getFont(f)))).toList(),
    );
  }

  Widget _buildCustomIconButton({required IconData icon, required VoidCallback? onTap, required Color color, double size = 20}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Padding(
          padding: const EdgeInsets.all(10.0),
          child: Icon(icon, color: color, size: size),
        ),
      ),
    );
  }

  Widget _buildFormatToggle(IconData icon, bool active, VoidCallback onTap) {
    return _buildCustomIconButton(
      icon: icon,
      onTap: onTap,
      color: active ? Colors.blueAccent : Colors.black54,
      size: 18,
    );
  }

  Widget _buildColorCircle(BuildContext context, CanvasToolNotifier notifier, CanvasDocumentNotifier docNotifier, TextBlock block) {
    return InkWell(
      onTap: () async {
        final hex = await ColorEngine.show(context, initialColor: block.textColorHex, title: 'Cor do Texto');
        if (hex != null) {
          setState(() {
            block.textColorHex = hex;
          });
          _updateBlock(docNotifier, block);
          notifier.setTextEditing(InlineTarget.block, block);
        }
      },
      child: Padding(
        padding: const EdgeInsets.all(6.0),
        child: CircleAvatar(
          radius: 11,
          backgroundColor: Color(int.parse(block.textColorHex.replaceFirst('#', '0xFF'))),
          child: Container(decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black12, width: 1))),
        ),
      ),
    );
  }
}
