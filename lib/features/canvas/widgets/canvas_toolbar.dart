import 'dart:math' as math;
import 'package:caderno_digital_app/features/canvas/models/page_object.dart';
import 'package:caderno_digital_app/features/shared/widgets/color_engine_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_document_provider.dart';
import '../models/local_page_model.dart';
import '../models/canvas_enums.dart' hide CanvasInteractionStateMode;
import '../providers/canvas_ui_provider.dart';
import '../widgets/canvas_zoom_control.dart';
import '../widgets/dialogs/layer_manager_sheet.dart'; 
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../models/table_model.dart';
import '../models/table_cell_model.dart';
import '../models/shape_model.dart';
import '../models/image_block_model.dart';
import '../models/table_types.dart';
import 'dialogs/thickness_studio_dialog.dart';
import 'dialogs/brush_style_sheet.dart'; 
import 'brush_preview.dart'; 

/// 🚀 v10.23: Barra de ferramentas horizontal altamente categorizada e sem redundâncias.
class CanvasToolbar extends ConsumerWidget {
  final LocalPage currentPage;
  final VoidCallback onColorTap;
  final VoidCallback onThicknessTap;
  final VoidCallback onChangePaperTap;
  final VoidCallback onDeletePageTap;
  final VoidCallback onAiAssistantTap;
  final VoidCallback? onAddImageTap; 

  const CanvasToolbar({
    super.key,
    required this.currentPage,
    required this.onColorTap,
    required this.onThicknessTap,
    required this.onChangePaperTap,
    required this.onDeletePageTap,
    required this.onAiAssistantTap,
    this.onAddImageTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactionState = ref.watch(canvasInteractionProvider);
    final interactionNotifier = ref.read(canvasInteractionProvider.notifier);
    final docState = ref.watch(canvasDocumentProvider);
    final docNotifier = ref.read(canvasDocumentProvider.notifier);
    final uiState = ref.watch(canvasUiProvider);

    final bool isTextMode = interactionState.activeTextBlock != null || interactionState.activeInlineTarget == InlineTarget.title;
    final bool isTableMode = interactionState.activeTableId != null || interactionState.selectedTableCells.isNotEmpty;
    final bool isBrushMode = interactionState.activeTool == ToolMode.draw && interactionState.selectedObjectIds.isEmpty;
    final bool isEraserMode = (interactionState.activeTool == ToolMode.eraser || interactionState.activeTool == ToolMode.pixelEraser) && interactionState.selectedObjectIds.isEmpty;
    final bool isLassoMode = interactionState.activeTool == ToolMode.lasso && interactionState.selectedObjectIds.isEmpty;

    final bool hideDrawingTools = docState.currentUserRole == 'viewer';
    if (hideDrawingTools) return _buildCompactToolbar(context, docState);

    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: uiState.isHudMode ? 0.15 : 1.0,
      child: IgnorePointer(
        ignoring: uiState.isHudMode,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 4))],
            border: Border.all(color: Colors.black.withOpacity(0.05)),
          ),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? MediaQuery.of(context).size.width - 40 : 600, // 🚀 Compacto
            ),
            child: Wrap(
              alignment: WrapAlignment.center,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 8,
              children: [
                // Zona Contextual
                isTextMode 
                  ? _buildTextContextZone(context, interactionState, interactionNotifier, docNotifier)
                  : isTableMode
                    ? _buildTableContextZone(context, interactionState, interactionNotifier, docNotifier)
                    : isBrushMode
                      ? _buildBrushContextZone(context, interactionState, interactionNotifier)
                      : isEraserMode
                        ? _buildEraserContextZone(context, interactionState, interactionNotifier, docNotifier)
                        : isLassoMode
                          ? _buildLassoContextZone(context, interactionState, interactionNotifier)
                          : _buildGeneralContextZone(context, interactionState, interactionNotifier, docNotifier),

                if (!isSmallScreen) Container(width: 0.5, height: 18, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),

                _buildSystemZone(context, ref, docState, docNotifier, isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGeneralContextZone(BuildContext context, CanvasInteractionState state, CanvasInteractionNotifier notifier, CanvasDocumentNotifier docNotifier) {
    if (state.selectedObjectIds.isEmpty) return const SizedBox.shrink();
    
    final bool singleSelection = state.selectedObjectIds.length == 1;
    final obj = singleSelection ? currentPage.objects.where((o) => o.id == state.selectedObjectIds.first).firstOrNull : null;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActiveGeneralCategoryContent(context, state, notifier, docNotifier, obj),
        const SizedBox(height: 4),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildCategoryTab(GeneralEditCategory.transform, Icons.open_with_rounded, 'Transformar', state.activeGeneralCategory, (c) => notifier.setGeneralCategory(c as GeneralEditCategory)),
            _buildCategoryTab(GeneralEditCategory.style, Icons.palette_outlined, 'Estilo', state.activeGeneralCategory, (c) => notifier.setGeneralCategory(c as GeneralEditCategory)),
            _buildCategoryTab(GeneralEditCategory.actions, Icons.layers_outlined, 'Ações', state.activeGeneralCategory, (c) => notifier.setGeneralCategory(c as GeneralEditCategory)),
          ],
        ),
      ],
    );
  }

  Widget _buildActiveGeneralCategoryContent(BuildContext context, CanvasInteractionState state, CanvasInteractionNotifier notifier, CanvasDocumentNotifier docNotifier, PageObject? obj) {
    switch (state.activeGeneralCategory) {
      case GeneralEditCategory.transform:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          _buildFormatToggle(Icons.transform_rounded, state.isTransformMode, () => notifier.toggleTransformMode()),
          if (obj != null) _buildFormatToggle(obj.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, obj.isLocked, () { docNotifier.updateObject(currentPage, obj.copyWith(isLocked: !obj.isLocked)); }),
          if (obj is ImageBlock) _buildContextIconButton(Icons.rotate_90_degrees_ccw_rounded, () => docNotifier.updateObject(currentPage, obj.copyWith(rotation: obj.rotation + (math.pi / 2))), Colors.blueGrey),
        ]);
      case GeneralEditCategory.style:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          if (obj is Stroke || obj is TextBlock || obj is ShapeObject) _buildContextIconButton(Icons.palette_outlined, onColorTap, Colors.blueAccent),
          if (obj is ShapeObject) ...[
            _buildContextIconButton(Icons.format_color_fill_rounded, () async {
              final hex = await ColorEngine.show(context, initialColor: obj.fillColor ?? '#FFFFFF', title: 'Preenchimento');
              if (hex != null) docNotifier.updateObject(currentPage, obj.copyWith(fillColor: hex));
            }, Colors.purpleAccent),
            _buildContextIconButton(Icons.line_weight_rounded, () => showDialog(context: context, builder: (_) => const ThicknessStudioDialog()), const Color(0xFF1A1A24)),
          ],
          if (obj is ImageBlock) _buildContextIconButton(Icons.image_search_rounded, () => docNotifier.pickAndInsertImage(currentPage), Colors.teal),
        ]);
      case GeneralEditCategory.actions:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          _buildContextIconButton(Icons.flip_to_front_rounded, () { 
            int maxZ = 0; for (var o in currentPage.objects) if (o.zIndex > maxZ) maxZ = o.zIndex;
            for (var id in state.selectedObjectIds) {
              final o = currentPage.objects.firstWhere((ob) => ob.id == id);
              docNotifier.updateObject(currentPage, o.copyWith(zIndex: maxZ + 1));
            }
          }, Colors.black87),
          _buildContextIconButton(Icons.delete_outline_rounded, () { docNotifier.deleteObjects(currentPage, state.selectedObjectIds.toList()); notifier.clearSelection(); }, Colors.redAccent),
        ]);
    }
  }

  Widget _buildBrushContextZone(BuildContext context, CanvasInteractionState state, CanvasInteractionNotifier notifier) {
    return Wrap(
      spacing: 6, runSpacing: 4,
      alignment: WrapAlignment.center,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        // --- NÍVEL 1: BÁSICOS ---
        _buildBrushSelectorButton(context, state),
        _buildColorCircle(context, state.selectedColorHex, (hex) => notifier.setColor(hex)),
        
        const VerticalDivider(width: 8, thickness: 0.5, indent: 8, endIndent: 8),

        // --- NÍVEL 2: ESPESSURA ---
        _buildThicknessButton(context, state),

        const VerticalDivider(width: 8, thickness: 0.5, indent: 8, endIndent: 8),

        // --- NÍVEL 3: TOGGLES ---
        _buildFormatToggle(Icons.border_color_rounded, state.isHighlighter, () => notifier.toggleHighlighterMode(!state.isHighlighter)),
        _buildFormatToggle(Icons.auto_awesome_rounded, state.smoothingLevel > 0, () => notifier.setSmoothingLevel(state.smoothingLevel > 0 ? 0.0 : 0.5)),
        
        // Mais Configurações (Acesso ao Estúdio)
        _buildContextIconButton(Icons.tune_rounded, () => showDialog(context: context, builder: (_) => const ThicknessStudioDialog()), Colors.blueGrey, size: 16),
      ],
    );
  }

  Widget _buildEraserContextZone(BuildContext context, CanvasInteractionState state, CanvasInteractionNotifier notifier, CanvasDocumentNotifier docNotifier) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildFormatToggle(Icons.layers_clear_rounded, state.activeTool == ToolMode.eraser, () => notifier.switchTool(ToolMode.eraser)),
            _buildFormatToggle(Icons.cleaning_services_rounded, state.activeTool == ToolMode.pixelEraser, () => notifier.switchTool(ToolMode.pixelEraser)),
            const VerticalDivider(width: 12),
            _buildContextIconButton(Icons.delete_sweep_rounded, () { docNotifier.deleteObjects(currentPage, currentPage.objects.map((o) => o.id).toList()); notifier.clearSelection(); }, Colors.redAccent),
          ],
        ),
        const SizedBox(height: 4),
        _buildCategoryTab(EraserEditCategory.mode, Icons.settings_accessibility_rounded, 'Modo', state.activeEraserCategory, (c) => notifier.setEraserCategory(c as EraserEditCategory)),
      ],
    );
  }

  Widget _buildLassoContextZone(BuildContext context, CanvasInteractionState state, CanvasInteractionNotifier notifier) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildContextIconButton(Icons.deselect_rounded, () => notifier.clearSelection(), Colors.black54),
        const SizedBox(width: 8),
        const Text('LAÇO ATIVO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black26)),
      ],
    );
  }

  Widget _buildTextContextZone(BuildContext context, CanvasInteractionState state, CanvasInteractionNotifier notifier, CanvasDocumentNotifier docNotifier) {
    final block = state.activeTextBlock;
    if (block == null) return const Text('TÍTULO', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black38));

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Conteúdo da Aba Ativa
        _buildActiveTextCategoryContent(context, state, notifier, docNotifier, block),
        const SizedBox(height: 4),
        // Linha de Abas (Polegar)
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCategoryTab(TextEditCategory.basics, Icons.edit_note_rounded, 'Geral', state.activeTextCategory, (c) => notifier.setTextCategory(c as TextEditCategory)),
              _buildCategoryTab(TextEditCategory.format, Icons.format_size_rounded, 'Estilo', state.activeTextCategory, (c) => notifier.setTextCategory(c as TextEditCategory)),
              _buildCategoryTab(TextEditCategory.organize, Icons.format_align_center_rounded, 'Layout', state.activeTextCategory, (c) => notifier.setTextCategory(c as TextEditCategory)),
              _buildCategoryTab(TextEditCategory.structure, Icons.format_list_bulleted_rounded, 'Lista', state.activeTextCategory, (c) => notifier.setTextCategory(c as TextEditCategory)),
              _buildCategoryTab(TextEditCategory.box, Icons.inventory_2_outlined, 'Caixa', state.activeTextCategory, (c) => notifier.setTextCategory(c as TextEditCategory)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTextCategoryContent(BuildContext context, CanvasInteractionState state, CanvasInteractionNotifier notifier, CanvasDocumentNotifier docNotifier, TextBlock block) {
    switch (state.activeTextCategory) {
      case TextEditCategory.basics:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          _buildContextIconButton(Icons.undo_rounded, () => docNotifier.undo(currentPage), const Color(0xFF1A1A24)),
          _buildContextIconButton(Icons.redo_rounded, () => docNotifier.redo(currentPage), const Color(0xFF1A1A24)),
          _buildContextIconButton(Icons.copy_rounded, () { final clone = block.clone(newId: const Uuid().v4()).copyWith(position: block.position + const Offset(20, 20)); docNotifier.addTextBlock(currentPage, clone as TextBlock); }, Colors.black54),
        ]);
      case TextEditCategory.format:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          _buildFontFamilyDropdown(notifier, docNotifier, block),
          const SizedBox(width: 8),
          _buildFormatToggle(Icons.format_bold, block.isBold, () { final nb = block.copyWith(isBold: !block.isBold); notifier.setTextEditing(InlineTarget.block, nb); _updateTextBlock(docNotifier, nb, notifier); }),
          _buildFormatToggle(Icons.format_italic, block.isItalic, () { final nb = block.copyWith(isItalic: !block.isItalic); notifier.setTextEditing(InlineTarget.block, nb); _updateTextBlock(docNotifier, nb, notifier); }),
          _buildFormatToggle(Icons.format_underlined, block.isUnderline, () { final nb = block.copyWith(isUnderline: !block.isUnderline); notifier.setTextEditing(InlineTarget.block, nb); _updateTextBlock(docNotifier, nb, notifier); }),
          _buildColorCircle(context, block.textColorHex, (hex) { final nb = block.copyWith(textColorHex: hex); notifier.setTextEditing(InlineTarget.block, nb); _updateTextBlock(docNotifier, nb, notifier); }, title: 'Cor do Texto'),
        ]);
      case TextEditCategory.organize:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          _buildFormatToggle(Icons.format_align_left_rounded, block.textAlign == TextAlign.left, () { final nb = block.copyWith(textAlign: TextAlign.left); notifier.setTextEditing(InlineTarget.block, nb); _updateTextBlock(docNotifier, nb, notifier); }),
          _buildFormatToggle(Icons.format_align_center_rounded, block.textAlign == TextAlign.center, () { final nb = block.copyWith(textAlign: TextAlign.center); notifier.setTextEditing(InlineTarget.block, nb); _updateTextBlock(docNotifier, nb, notifier); }),
          _buildFormatToggle(Icons.format_align_right_rounded, block.textAlign == TextAlign.right, () { final nb = block.copyWith(textAlign: TextAlign.right); notifier.setTextEditing(InlineTarget.block, nb); _updateTextBlock(docNotifier, nb, notifier); }),
          const VerticalDivider(width: 12),
          _buildContextIconButton(Icons.text_increase, () { final nb = block.copyWith(fontSize: block.fontSize + 2); notifier.setTextEditing(InlineTarget.block, nb); _updateTextBlock(docNotifier, nb, notifier); }, const Color(0xFF0F4C5C)),
          _buildContextIconButton(Icons.text_decrease, () { if (block.fontSize > 8) { final nb = block.copyWith(fontSize: block.fontSize - 2); notifier.setTextEditing(InlineTarget.block, nb); _updateTextBlock(docNotifier, nb, notifier); } }, const Color(0xFF0F4C5C)),
        ]);
      case TextEditCategory.structure:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          _buildFormatToggle(Icons.format_list_bulleted_rounded, block.listType == ListType.bullet, () { final nb = block.copyWith(listType: block.listType == ListType.bullet ? ListType.none : ListType.bullet); notifier.setTextEditing(InlineTarget.block, nb); _updateTextBlock(docNotifier, nb, notifier); }),
          _buildFormatToggle(Icons.format_list_numbered_rounded, block.listType == ListType.numbered, () { final nb = block.copyWith(listType: block.listType == ListType.numbered ? ListType.none : ListType.numbered); notifier.setTextEditing(InlineTarget.block, nb); _updateTextBlock(docNotifier, nb, notifier); }),
          _buildFormatToggle(Icons.checklist_rounded, block.listType == ListType.checklist, () { final nb = block.copyWith(listType: block.listType == ListType.checklist ? ListType.none : ListType.checklist); notifier.setTextEditing(InlineTarget.block, nb); _updateTextBlock(docNotifier, nb, notifier); }),
        ]);
      case TextEditCategory.box:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          _buildContextIconButton(Icons.flip_to_front_rounded, () { int maxZ = 0; for (var o in currentPage.objects) if (o.zIndex > maxZ) maxZ = o.zIndex; final nb = block.copyWith(zIndex: maxZ + 1); docNotifier.updateObject(currentPage, nb); notifier.setTextEditing(InlineTarget.block, nb); }, Colors.black87),
          _buildContextIconButton(Icons.delete_outline_rounded, () { docNotifier.deleteObjects(currentPage, [block.id]); notifier.exitWritingMode(); }, Colors.redAccent),
        ]);
    }
  }

  Widget _buildTableContextZone(BuildContext context, CanvasInteractionState state, CanvasInteractionNotifier notifier, CanvasDocumentNotifier docNotifier) {
    final table = currentPage.objects.whereType<TableObject>().where((t) => t.id == state.activeTableId || state.selectedObjectIds.contains(t.id)).firstOrNull;
    if (table == null) return const SizedBox.shrink();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildActiveTableCategoryContent(context, state, notifier, docNotifier, table),
        const SizedBox(height: 4),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildCategoryTab(TableEditCategory.structure, Icons.grid_view_rounded, 'Estrutura', state.activeTableCategory, (c) => notifier.setTableCategory(c as TableEditCategory)),
              _buildCategoryTab(TableEditCategory.cell, Icons.edit_attributes_rounded, 'Célula', state.activeTableCategory, (c) => notifier.setTableCategory(c as TableEditCategory)),
              _buildCategoryTab(TableEditCategory.style, Icons.palette_rounded, 'Estilo', state.activeTableCategory, (c) => notifier.setTableCategory(c as TableEditCategory)),
              _buildCategoryTab(TableEditCategory.actions, Icons.layers_outlined, 'Ações', state.activeTableCategory, (c) => notifier.setTableCategory(c as TableEditCategory)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActiveTableCategoryContent(BuildContext context, CanvasInteractionState state, CanvasInteractionNotifier notifier, CanvasDocumentNotifier docNotifier, TableObject table) {
    final selectedKeys = state.selectedTableCells;

    switch (state.activeTableCategory) {
      case TableEditCategory.structure:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          _buildContextIconButton(Icons.table_rows_rounded, () { int insertAt = table.rows; if (selectedKeys.isNotEmpty) insertAt = selectedKeys.first.coordinate.row + 1; docNotifier.updateObject(currentPage, table.insertRowAt(insertAt)); }, const Color(0xFF0F4C5C)),
          _buildContextIconButton(Icons.view_column_rounded, () { int insertAt = table.cols; if (selectedKeys.isNotEmpty) insertAt = selectedKeys.first.coordinate.col + 1; docNotifier.updateObject(currentPage, table.insertColumnAt(insertAt)); }, const Color(0xFF0F4C5C)),
          const VerticalDivider(width: 12),
          _buildContextIconButton(Icons.delete_sweep_rounded, () { if (table.rows > 1) { int deleteAt = table.rows - 1; if (selectedKeys.isNotEmpty) deleteAt = selectedKeys.first.coordinate.row; notifier.selectIds(tableCells: {}); docNotifier.updateObject(currentPage, table.deleteRowAt(deleteAt)); } }, Colors.redAccent),
        ]);
      case TableEditCategory.cell:
        if (selectedKeys.isEmpty) return const Text('SELECIONE CÉLULAS', style: TextStyle(fontSize: 9, color: Colors.black26));
        final refCell = table.cells[selectedKeys.first.coordinate] ?? TableCellModel();
        return Row(mainAxisSize: MainAxisSize.min, children: [
          _buildCellTypeDropdown(table, selectedKeys, docNotifier),
          _buildColorCircle(context, refCell.style.backgroundColorHex ?? '#FFFFFF', (hex) {
            final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
            for (var key in selectedKeys) { final coords = key.coordinate; final cell = table.cells[coords] ?? TableCellModel(); newCells[coords] = cell.copyWith(style: cell.style.copyWith(backgroundColorHex: hex)); }
            docNotifier.updateObject(currentPage, table.copyWith(cells: newCells));
          }, title: 'Fundo da Célula'),
          _buildFormatToggle(Icons.align_vertical_center_rounded, refCell.style.verticalAlign == 1, () {
             final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
             for (var key in selectedKeys) { final coords = key.coordinate; final cell = table.cells[coords] ?? TableCellModel(); newCells[coords] = cell.copyWith(style: cell.style.copyWith(verticalAlign: 1)); }
             docNotifier.updateObject(currentPage, table.copyWith(cells: newCells));
          }),
        ]);
      case TableEditCategory.style:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          _buildColorCircle(context, table.borderColor, (hex) { docNotifier.updateObject(currentPage, table.copyWith(borderColor: hex)); }, title: 'Cor da Borda'),
          _buildFormatToggle(Icons.view_headline_rounded, table.showHeader, () { docNotifier.updateObject(currentPage, table.copyWith(showHeader: !table.showHeader)); }),
        ]);
      case TableEditCategory.actions:
        return Row(mainAxisSize: MainAxisSize.min, children: [
          _buildContextIconButton(Icons.delete_outline_rounded, () { docNotifier.deleteObjects(currentPage, [table.id]); notifier.clearSelection(); }, Colors.redAccent),
          _buildContextIconButton(Icons.select_all_rounded, () { final allKeys = <TableCellKey>{}; for (int r = 0; r < table.rows; r++) { for (int c = 0; c < table.cols; c++) { allKeys.add(TableCellKey(table.id, CellCoordinate(r, c))); } } notifier.selectIds(tableCells: allKeys); }, const Color(0xFF0F4C5C)),
        ]);
    }
  }

  Widget _buildCellTypeDropdown(TableObject table, Set<TableCellKey> selectedKeys, CanvasDocumentNotifier docNotifier) {
    final refCell = table.cells[selectedKeys.first.coordinate] ?? TableCellModel();
    return PopupMenuButton<TableCellType>(
      initialValue: refCell.type,
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(_getCellTypeIcon(refCell.type), size: 14), const SizedBox(width: 6), const Icon(Icons.arrow_drop_down, size: 14)])),
      onSelected: (type) {
        final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
        for (var key in selectedKeys) { final coords = key.coordinate; final cell = table.cells[coords] ?? TableCellModel(); String newVal = cell.value; if (type == TableCellType.checkbox && newVal.isEmpty) newVal = 'false'; newCells[coords] = cell.copyWith(type: type, value: newVal); }
        docNotifier.updateObject(currentPage, table.copyWith(cells: newCells));
      },
      itemBuilder: (ctx) => TableCellType.values.map((t) => PopupMenuItem(value: t, child: Row(children: [Icon(_getCellTypeIcon(t), size: 16), const SizedBox(width: 8), Text(t.name.toUpperCase(), style: const TextStyle(fontSize: 10))]))).toList(),
    );
  }

  IconData _getCellTypeIcon(TableCellType type) {
    switch (type) { case TableCellType.number: return Icons.numbers_rounded; case TableCellType.date: return Icons.calendar_today_rounded; case TableCellType.checkbox: return Icons.check_box_rounded; default: return Icons.text_fields_rounded; }
  }

  Widget _buildCategoryTab(dynamic cat, IconData icon, String label, dynamic activeCat, Function(dynamic) onTap) {
    final bool isActive = activeCat == cat;
    return GestureDetector(
      onTap: () => onTap(cat),
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
            ]
          ],
        ),
      ),
    );
  }

  void _updateTextBlock(CanvasDocumentNotifier docNotifier, TextBlock block, CanvasInteractionNotifier toolNotifier) {
    if (block.id.startsWith('proxy_')) {
      final parts = block.id.split('_'); if (parts.length < 3) return;
      final tableId = parts[1]; 
      final CellCoordinate coord = CellCoordinate.fromString(parts[2]);
      final table = currentPage.objects.whereType<TableObject>().where((t) => t.id == tableId).firstOrNull;
      if (table == null) return;
      final currentCell = table.cells[coord] ?? TableCellModel();
      final updatedCell = currentCell.copyWith(
        value: block.text,
        style: currentCell.style.copyWith(
          bold: block.isBold, italic: block.isItalic, underline: block.isUnderline,
          strikethrough: block.isStrikethrough, fontSize: block.fontSize,
          fontFamily: block.fontFamily, textColorHex: block.textColorHex,
          backgroundColorHex: block.backgroundColorHex, textAlign: block.textAlign,
        ),
      );
      final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
      newCells[coord] = updatedCell;
      docNotifier.updateObject(currentPage, table.copyWith(cells: newCells));
    } else {
      docNotifier.updateObject(currentPage, block);
    }
  }

  Widget _buildBrushSelectorButton(BuildContext context, CanvasInteractionState state) {
    return Tooltip(
      message: 'Estúdio de Canetas',
      child: InkWell(
        onTap: () => _showBrushSelector(context),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8), color: const Color(0xFF0F4C5C).withOpacity(0.03)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            CustomPaint(size: const Size(22, 16), painter: BrushPreviewPainter(type: state.selectedBrushType, color: Color(int.parse(state.selectedColorHex.replaceFirst('#', '0xFF'))), strokeWidth: 2.5)),
            const SizedBox(width: 4),
            const Icon(Icons.tune_rounded, size: 12, color: Colors.black38)
          ]),
        ),
      ),
    );
  }

  Widget _buildThicknessButton(BuildContext context, CanvasInteractionState state) {
    return Tooltip(
      message: 'Ajustar Espessura',
      child: InkWell(
        onTap: () => showDialog(context: context, builder: (_) => const ThicknessStudioDialog()),
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8), color: const Color(0xFF0F4C5C).withOpacity(0.03)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(Icons.line_weight_rounded, size: 16, color: const Color(0xFF0F4C5C).withOpacity(0.6)),
            const SizedBox(width: 4),
            Text('${state.selectedThickness.toInt()}px', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0F4C5C))),
          ]),
        ),
      ),
    );
  }

  Widget _buildSystemZone(BuildContext context, WidgetRef ref, CanvasDocumentState docState, CanvasDocumentNotifier docNotifier, bool isSmallScreen) {
    return Wrap(
      spacing: 4, runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        if (!isSmallScreen) ...[CanvasZoomControl(currentPage: currentPage), const SizedBox(width: 4)],
        _buildContextIconButton(Icons.undo_rounded, docState.canUndo ? () => docNotifier.undo(currentPage) : null, docState.canUndo ? const Color(0xFF1A1A24) : Colors.black12, size: 18),
        _buildContextIconButton(Icons.redo_rounded, docState.canRedo ? () => docNotifier.redo(currentPage) : null, docState.canRedo ? const Color(0xFF1A1A24) : Colors.black12, size: 18),
        _buildContextIconButton(Icons.layers_outlined, () => _showLayerManager(context, currentPage), const Color(0xFF0F4C5C), size: 18),
        _buildPagePopupMenu(context, ref, currentPage),
      ],
    );
  }

  Widget _buildContextIconButton(IconData icon, VoidCallback? onPressed, Color color, {double size = 18}) => IconButton(
    iconSize: size, 
    constraints: const BoxConstraints(minWidth: 32, minHeight: 32), // 🚀 Menor
    padding: EdgeInsets.zero, 
    icon: Icon(icon, color: color), 
    onPressed: onPressed
  );

  Widget _buildColorCircle(BuildContext context, String hex, Function(String) onSelected, {String title = 'Cor'}) => InkWell(onTap: () async { final newHex = await ColorEngine.show(context, initialColor: hex, title: title); if (newHex != null) onSelected(newHex); }, child: Container(padding: const EdgeInsets.all(2), margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black12)), child: CircleAvatar(radius: 10, backgroundColor: Color(int.parse(hex.replaceFirst('#', '0xFF'))))));

  Widget _buildFormatToggle(IconData icon, bool active, VoidCallback onTap) => _buildContextIconButton(icon, onTap, active ? Colors.blueAccent : Colors.black54, size: 18);

  void _showLayerManager(BuildContext context, LocalPage page) => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => LayerManagerSheet(page: page));
  void _showBrushSelector(BuildContext context) => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => const BrushStyleSheet());

  Widget _buildFontFamilyDropdown(CanvasInteractionNotifier notifier, CanvasDocumentNotifier docNotifier, TextBlock block) {
    return PopupMenuButton<String>(
      initialValue: block.fontFamily ?? 'Inter',
      tooltip: 'Mudar Fonte',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
        child: Row(mainAxisSize: MainAxisSize.min, children: [Text(block.fontFamily ?? 'Inter', style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold)), const Icon(Icons.arrow_drop_down, size: 12)]),
      ),
      onSelected: (font) { final nb = block.copyWith(fontFamily: font); notifier.setTextEditing(InlineTarget.block, nb); _updateTextBlock(docNotifier, nb, notifier); },
      itemBuilder: (ctx) => ['Inter', 'Lora', 'Roboto', 'Oswald', 'Dancing Script'].map((f) => PopupMenuItem(value: f, child: Text(f, style: GoogleFonts.getFont(f)))).toList(),
    );
  }

  Widget _buildCompactToolbar(BuildContext context, CanvasDocumentState docState) => Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8))]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(docState.currentUserRole == 'viewer' ? Icons.visibility_outlined : Icons.lock_person_rounded, color: Colors.blueGrey, size: 20), const SizedBox(width: 12), Text(docState.currentUserRole == 'viewer' ? 'Modo Leitura' : 'Sessão Bloqueada', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87))]));

  Widget _buildPagePopupMenu(BuildContext context, WidgetRef ref, LocalPage page) => PopupMenuButton<String>(icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF5F6368)), offset: const Offset(0, -280), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), onSelected: (val) => _handlePageAction(context, ref, page, val), itemBuilder: (context) => [_buildPopupItem('rename', Icons.edit_outlined, 'Renomear Folha'), _buildPopupItem('settings', Icons.settings_outlined, 'Configurações'), _buildPopupItem('paper', Icons.grid_on_rounded, 'Mudar Pauta'), const PopupMenuDivider(), _buildPopupItem('favorite', page.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded, 'Favorito'), _buildPopupItem('duplicate', Icons.copy_rounded, 'Duplicar Página'), _buildPopupItem('delete', Icons.delete_outline_rounded, 'Rasgar Folha')]);

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String label) => PopupMenuItem<String>(value: value, height: 38, child: Row(children: [Icon(icon, size: 18, color: Colors.black54), const SizedBox(width: 12), Text(label, style: const TextStyle(fontSize: 12))]));

  void _handlePageAction(BuildContext context, WidgetRef ref, LocalPage page, String action) { switch (action) { case 'rename': break; case 'settings': break; case 'paper': onChangePaperTap(); break; case 'favorite': ref.read(canvasDocumentProvider.notifier).toggleFavorite(page); break; case 'duplicate': ref.read(canvasDocumentProvider.notifier).duplicatePage(page); break; case 'delete': ref.read(canvasDocumentProvider.notifier).deletePage(page); break; } }
}
