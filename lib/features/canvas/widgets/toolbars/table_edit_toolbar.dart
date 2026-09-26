import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/table_model.dart';
import '../../models/table_cell_model.dart';
import '../../models/canvas_enums.dart';
import '../../models/table_types.dart'; // 🚀 v9.7
import '../../providers/canvas_tool_provider.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/local_page_model.dart';
import '../../../shared/widgets/color_engine_widget.dart';

enum TableEditCategory { structure, cell, style, actions }

class TableEditToolbar extends ConsumerStatefulWidget {
  final LocalPage currentPage;
  final bool isCellEditing;
  const TableEditToolbar({super.key, required this.currentPage, this.isCellEditing = false});
  @override
  ConsumerState<TableEditToolbar> createState() => _TableEditToolbarState();
}

class _TableEditToolbarState extends ConsumerState<TableEditToolbar> {
  TableEditCategory _activeCategory = TableEditCategory.structure;

  void _handleExit() {
    FocusManager.instance.primaryFocus?.unfocus();
    ref.read(canvasToolProvider.notifier).forceExitTableMode();
  }

  @override
  Widget build(BuildContext context) {
    final toolState = ref.watch(canvasToolProvider);
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final docState = ref.watch(canvasDocumentProvider);
    final docNotifier = ref.read(canvasDocumentProvider.notifier);
    final page = docState.pages.firstWhere((p) => p.clientId == widget.currentPage.clientId);
    
    TableObject? table;
    try {
      table = page.objects.whereType<TableObject>().firstWhere((t) => toolState.selectedTableIds.contains(t.id) || t.id == toolState.activeTableId);
    } catch (_) {
      if (toolState.selectedTableIds.isNotEmpty) {
        try { table = page.objects.whereType<TableObject>().firstWhere((t) => toolState.selectedTableIds.contains(t.id)); } catch (_) {}
      }
    }
    if (table == null) return const SizedBox.shrink();

    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isSmallScreen = screenWidth < 600;

    return Container(
      constraints: BoxConstraints(maxWidth: isSmallScreen ? screenWidth - 24 : 550),
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(32), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 20, offset: const Offset(0, 8))], border: Border.all(color: Colors.black.withOpacity(0.05))),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(children: [
            _buildCustomIconButton(icon: Icons.check_circle_rounded, onTap: _handleExit, color: Colors.greenAccent, size: 22),
            _buildCustomIconButton(icon: Icons.open_with_rounded, onTap: () => toolNotifier.toggleTransformMode(), color: toolState.isTransformMode ? Colors.orangeAccent : Colors.black54, size: 22),
            const VerticalDivider(width: 24, indent: 8, endIndent: 8),
            Expanded(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: [_buildCategoryTab(TableEditCategory.structure, Icons.grid_on_rounded, 'Estrutura'), _buildCategoryTab(TableEditCategory.cell, Icons.border_all_rounded, 'Célula'), _buildCategoryTab(TableEditCategory.style, Icons.color_lens_rounded, 'Estilo'), _buildCategoryTab(TableEditCategory.actions, Icons.auto_awesome_rounded, 'Ações')]))),
          ]),
          const Divider(height: 16, color: Colors.black12, indent: 4, endIndent: 4),
          Center(child: SingleChildScrollView(scrollDirection: Axis.horizontal, child: _buildActiveCategoryContent(context, table, toolNotifier, docNotifier, page))),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(TableEditCategory cat, IconData icon, String label) {
    final bool isActive = _activeCategory == cat;
    return GestureDetector(
      onTap: () => setState(() => _activeCategory = cat),
      child: AnimatedContainer(duration: const Duration(milliseconds: 200), margin: const EdgeInsets.symmetric(horizontal: 4), padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5), decoration: BoxDecoration(color: isActive ? const Color(0xFF0F4C5C).withOpacity(0.08) : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Row(children: [Icon(icon, size: 14, color: isActive ? const Color(0xFF0F4C5C) : Colors.black38), if (isActive) ...[const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0F4C5C)))]])),
    );
  }

  Widget _buildActiveCategoryContent(BuildContext context, TableObject table, CanvasToolNotifier toolNotifier, CanvasDocumentNotifier docNotifier, LocalPage page) {
    final toolState = ref.read(canvasToolProvider);
    final selectedKeys = toolState.selectedTableCells;

    switch (_activeCategory) {
      case TableEditCategory.structure:
        return Row(children: [
          _buildCustomIconButton(icon: Icons.architecture_rounded, onTap: () {
            toolNotifier.toggleTableStructuralMode();
            if (toolState.selectedObjectIds.isEmpty) toolNotifier.selectIds(objectIds: {table.id});
          }, color: toolState.isTableStructuralMode ? Colors.orangeAccent : const Color(0xFF0F4C5C)),
          _buildCustomIconButton(icon: Icons.playlist_add_rounded, onTap: () {
            int insertAt = table.rows;
            if (selectedKeys.isNotEmpty) insertAt = selectedKeys.first.coordinate.row + 1;
            docNotifier.updateObject(page, table.insertRowAt(insertAt));
          }, color: const Color(0xFF0F4C5C)),
          _buildCustomIconButton(icon: Icons.view_week_rounded, onTap: () {
            int insertAt = table.cols;
            if (selectedKeys.isNotEmpty) insertAt = selectedKeys.first.coordinate.col + 1;
            docNotifier.updateObject(page, table.insertColumnAt(insertAt));
          }, color: const Color(0xFF0F4C5C)),
          const VerticalDivider(width: 12),
          _buildCustomIconButton(icon: Icons.view_stream_rounded, onTap: () {
            if (selectedKeys.isEmpty) return;
            final int row = selectedKeys.first.coordinate.row;
            final Set<TableCellKey> keys = {}; for (int c = 0; c < table.cols; c++) { keys.add(TableCellKey(table.id, CellCoordinate(row, c))); }
            toolNotifier.selectIds(tableCells: keys);
          }, color: Colors.blueAccent, size: 18),
          _buildCustomIconButton(icon: Icons.view_column_outlined, onTap: () {
            if (selectedKeys.isEmpty) return;
            final int col = selectedKeys.first.coordinate.col;
            final Set<TableCellKey> keys = {}; for (int r = 0; r < table.rows; r++) { keys.add(TableCellKey(table.id, CellCoordinate(r, col))); }
            toolNotifier.selectIds(tableCells: keys);
          }, color: Colors.blueAccent, size: 18),
          const VerticalDivider(width: 20),
          _buildCustomIconButton(icon: Icons.layers_clear_rounded, onTap: () {
            if (table.rows > 1) {
              int deleteAt = table.rows - 1;
              if (selectedKeys.isNotEmpty) deleteAt = selectedKeys.first.coordinate.row;
              toolNotifier.selectIds(tableCells: {});
              docNotifier.updateObject(page, table.deleteRowAt(deleteAt));
            }
          }, color: Colors.redAccent),
          _buildCustomIconButton(icon: Icons.view_array_rounded, onTap: () {
            if (table.cols > 1) {
              int deleteAt = table.cols - 1;
              if (selectedKeys.isNotEmpty) deleteAt = selectedKeys.first.coordinate.col;
              toolNotifier.selectIds(tableCells: {});
              docNotifier.updateObject(page, table.deleteColumnAt(deleteAt));
            }
          }, color: Colors.redAccent),
        ]);
      case TableEditCategory.cell:
        if (selectedKeys.isEmpty) return const Text('SELECIONE CÉLULAS PARA EDITAR', style: TextStyle(fontSize: 9, color: Colors.black26));
        final refCell = table.cells[selectedKeys.first.coordinate] ?? TableCellModel();
        return Row(children: [
          _buildCellTypeDropdown(table, selectedKeys, docNotifier, page),
          const VerticalDivider(width: 20),
          _buildFormatToggle(Icons.format_bold, refCell.style.bold, () {
            final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
            final bool newVal = !refCell.style.bold;
            for (var key in selectedKeys) {
              final CellCoordinate coords = key.coordinate;
              final cell = table.cells[coords] ?? TableCellModel();
              newCells[coords] = cell.copyWith(style: cell.style.copyWith(bold: newVal));
            }
            docNotifier.updateObject(page, table.copyWith(cells: newCells));
          }),
          _buildFormatToggle(Icons.format_italic, refCell.style.italic, () {
            final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
            final bool newVal = !refCell.style.italic;
            for (var key in selectedKeys) {
              final CellCoordinate coords = key.coordinate;
              final cell = table.cells[coords] ?? TableCellModel();
              newCells[coords] = cell.copyWith(style: cell.style.copyWith(italic: newVal));
            }
            docNotifier.updateObject(page, table.copyWith(cells: newCells));
          }),
          const VerticalDivider(width: 20),
          _buildColorCircle(context, refCell.style.textColorHex, (hex) {
            final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
            for (var key in selectedKeys) {
              final CellCoordinate coords = key.coordinate;
              final cell = table.cells[coords] ?? TableCellModel();
              newCells[coords] = cell.copyWith(style: cell.style.copyWith(textColorHex: hex));
            }
            docNotifier.updateObject(page, table.copyWith(cells: newCells));
          }),
          _buildCustomIconButton(icon: Icons.format_color_fill_rounded, onTap: () async {
            final hex = await ColorEngine.show(context, initialColor: refCell.style.backgroundColorHex ?? '#FFFFFF', title: 'Fundo da Célula');
            if (hex != null) {
              final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
              for (var key in selectedKeys) {
                final CellCoordinate coords = key.coordinate;
                final cell = table.cells[coords] ?? TableCellModel();
                newCells[coords] = cell.copyWith(style: cell.style.copyWith(backgroundColorHex: hex));
              }
              docNotifier.updateObject(page, table.copyWith(cells: newCells));
            }
          }, color: refCell.style.backgroundColorHex != null ? Color(int.parse(refCell.style.backgroundColorHex!.replaceFirst('#', '0xFF'))) : Colors.black26),
          const VerticalDivider(width: 20),
          _buildFormatToggle(Icons.align_vertical_top_rounded, refCell.style.verticalAlign == 0, () {
            final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
            for (var key in selectedKeys) {
              final CellCoordinate coords = key.coordinate;
              final cell = table.cells[coords] ?? TableCellModel();
              newCells[coords] = cell.copyWith(style: cell.style.copyWith(verticalAlign: 0));
            }
            docNotifier.updateObject(page, table.copyWith(cells: newCells));
          }),
          _buildFormatToggle(Icons.align_vertical_center_rounded, refCell.style.verticalAlign == 1, () {
            final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
            for (var key in selectedKeys) {
              final CellCoordinate coords = key.coordinate;
              final cell = table.cells[coords] ?? TableCellModel();
              newCells[coords] = cell.copyWith(style: cell.style.copyWith(verticalAlign: 1));
            }
            docNotifier.updateObject(page, table.copyWith(cells: newCells));
          }),
          _buildFormatToggle(Icons.align_vertical_bottom_rounded, refCell.style.verticalAlign == 2, () {
            final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
            for (var key in selectedKeys) {
              final CellCoordinate coords = key.coordinate;
              final cell = table.cells[coords] ?? TableCellModel();
              newCells[coords] = cell.copyWith(style: cell.style.copyWith(verticalAlign: 2));
            }
            docNotifier.updateObject(page, table.copyWith(cells: newCells));
          }),
        ]);
      case TableEditCategory.style:
        return Row(children: [
          _buildColorCircle(context, table.borderColor, (hex) { docNotifier.updateObject(page, table.copyWith(borderColor: hex)); }, title: 'Cor da Borda'),
          const VerticalDivider(width: 12, indent: 8, endIndent: 8),
          
          // 🚀 v10.91: Controle Unificado de Exterior
          _buildBorderSideControl(
            label: 'EXTERIOR',
            currentStyle: table.lineStyle,
            currentThickness: table.borderWidth,
            onStyleChanged: (s) => docNotifier.updateObject(page, table.copyWith(lineStyle: s)),
            onThicknessChanged: (v) => docNotifier.updateObject(page, table.copyWith(borderWidth: v)),
          ),

          const VerticalDivider(width: 12, indent: 8, endIndent: 8),

          // 🚀 v10.91: Controle Unificado de Interior
          _buildBorderSideControl(
            label: 'GRADE',
            currentStyle: table.internalLineStyle,
            currentThickness: table.internalBorderWidth,
            onStyleChanged: (s) => docNotifier.updateObject(page, table.copyWith(internalLineStyle: s)),
            onThicknessChanged: (v) => docNotifier.updateObject(page, table.copyWith(internalBorderWidth: v)),
          ),

          const VerticalDivider(width: 12, indent: 8, endIndent: 8),
          
          _buildCustomIconButton(icon: Icons.format_paint_rounded, onTap: () async {
            final hex = await ColorEngine.show(context, initialColor: table.tableBackgroundColorHex ?? '#FFFFFF', title: 'Fundo da Tabela');
            if (hex != null) docNotifier.updateObject(page, table.copyWith(tableBackgroundColorHex: hex));
          }, color: table.tableBackgroundColorHex != null ? Color(int.parse(table.tableBackgroundColorHex!.replaceFirst('#', '0xFF'))) : Colors.black26),
          _buildFormatToggle(Icons.view_headline_rounded, table.showHeader, () { docNotifier.updateObject(page, table.copyWith(showHeader: !table.showHeader)); }),
        ]);
      case TableEditCategory.actions:
        return Row(children: [
          _buildCustomIconButton(icon: Icons.merge_type_rounded, onTap: selectedKeys.length > 1 ? () => _handleMerge(table, selectedKeys, docNotifier, page) : null, color: selectedKeys.length > 1 ? Colors.blueAccent : Colors.black12),
          _buildCustomIconButton(icon: Icons.call_split_rounded, onTap: () => _handleSplit(table, selectedKeys, docNotifier, page), color: Colors.orangeAccent),
          const VerticalDivider(width: 20),
          _buildCustomIconButton(icon: Icons.delete_outline_rounded, onTap: () {
            final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
            for (var key in selectedKeys) { final CellCoordinate coords = key.coordinate; final cell = table.cells[coords] ?? TableCellModel(); newCells[coords] = cell.copyWith(value: ''); }
            docNotifier.updateObject(page, table.copyWith(cells: newCells));
          }, color: Colors.redAccent),
          const VerticalDivider(width: 20),
          _buildCustomIconButton(icon: Icons.select_all_rounded, onTap: () { final allKeys = <TableCellKey>{}; for (int r = 0; r < table.rows; r++) { for (int c = 0; c < table.cols; c++) { allKeys.add(TableCellKey(table.id, CellCoordinate(r, c))); } } toolNotifier.selectIds(tableCells: allKeys); }, color: const Color(0xFF0F4C5C)),
        ]);
    }
  }

  void _handleMerge(TableObject table, Set<TableCellKey> selectedKeys, CanvasDocumentNotifier docNotifier, LocalPage page) {
    if (selectedKeys.length < 2) return;
    int minR = 999, maxR = -1, minC = 999, maxC = -1;
    for (var key in selectedKeys) {
      final coords = key.coordinate;
      if (coords.row < minR) minR = coords.row; if (coords.row > maxR) maxR = coords.row;
      if (coords.col < minC) minC = coords.col; if (coords.col > maxC) maxC = coords.col;
    }
    int rowSpan = (maxR - minR) + 1; int colSpan = (maxC - minC) + 1;
    final topLeftCoord = CellCoordinate(minR, minC);
    final Map<CellCoordinate, CellCoordinate> newSpans = Map.from(table.cellSpans);
    newSpans[topLeftCoord] = CellCoordinate(rowSpan, colSpan);
    final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
    for (int r = minR; r <= maxR; r++) { for (int c = minC; c <= maxC; c++) { if (r == minR && c == minC) continue; newCells.remove(CellCoordinate(r, c)); } }
    docNotifier.updateObject(page, table.copyWith(cellSpans: newSpans, cells: newCells));
    ref.read(canvasToolProvider.notifier).selectIds(tableCells: {TableCellKey(table.id, topLeftCoord)});
  }

  void _handleSplit(TableObject table, Set<TableCellKey> selectedKeys, CanvasDocumentNotifier docNotifier, LocalPage page) {
    final Map<CellCoordinate, CellCoordinate> newSpans = Map.from(table.cellSpans);
    final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
    for (var key in selectedKeys) {
      final coords = key.coordinate;
      if (newSpans.containsKey(coords)) {
        final span = newSpans[coords]!;
        newSpans.remove(coords);
        for (int r = coords.row; r < coords.row + span.row; r++) { for (int c = coords.col; c < coords.col + span.col; c++) { if (r == coords.row && c == coords.col) continue; newCells[CellCoordinate(r, c)] = TableCellModel(); } }
      }
    }
    docNotifier.updateObject(page, table.copyWith(cellSpans: newSpans, cells: newCells));
  }

  Widget _buildCellTypeDropdown(TableObject table, Set<TableCellKey> selectedKeys, CanvasDocumentNotifier docNotifier, LocalPage page) {
    final refCell = table.cells[selectedKeys.first.coordinate] ?? TableCellModel();
    return PopupMenuButton<TableCellType>(
      initialValue: refCell.type,
      child: Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)), child: Row(children: [Icon(_getCellTypeIcon(refCell.type), size: 14), const SizedBox(width: 6), const Icon(Icons.arrow_drop_down, size: 14)])),
      onSelected: (type) {
        final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
        for (var key in selectedKeys) {
          final coords = key.coordinate;
          final cell = table.cells[coords] ?? TableCellModel();
          String newVal = cell.value; if (type == TableCellType.checkbox && newVal.isEmpty) newVal = 'false';
          newCells[coords] = cell.copyWith(type: type, value: newVal);
        }
        docNotifier.updateObject(page, table.copyWith(cells: newCells));
      },
      itemBuilder: (ctx) => TableCellType.values.map((t) => PopupMenuItem(value: t, child: Row(children: [Icon(_getCellTypeIcon(t), size: 16), const SizedBox(width: 8), Text(t.name.toUpperCase(), style: const TextStyle(fontSize: 10))]))).toList(),
    );
  }

  IconData _getCellTypeIcon(TableCellType type) {
    switch (type) { case TableCellType.number: return Icons.numbers_rounded; case TableCellType.date: return Icons.calendar_today_rounded; case TableCellType.checkbox: return Icons.check_box_rounded; default: return Icons.text_fields_rounded; }
  }

  Widget _buildCustomIconButton({required IconData icon, required VoidCallback? onTap, required Color color, double size = 20}) {
    return Material(color: Colors.transparent, child: InkWell(onTap: onTap, customBorder: const CircleBorder(), child: Padding(padding: const EdgeInsets.all(10.0), child: Icon(icon, color: color, size: size))));
  }

  Widget _buildFormatToggle(IconData icon, bool active, VoidCallback onTap) {
    return _buildCustomIconButton(icon: icon, onTap: onTap, color: active ? Colors.blueAccent : Colors.black54, size: 18);
  }

  Widget _buildColorCircle(BuildContext context, String hex, Function(String) onSelected, {String title = 'Cor'}) => InkWell(onTap: () async { final newHex = await ColorEngine.show(context, initialColor: hex, title: title); if (newHex != null) onSelected(newHex); }, child: Container(padding: const EdgeInsets.all(2), margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black12)), child: CircleAvatar(radius: 10, backgroundColor: Color(int.parse(hex.replaceFirst('#', '0xFF'))))));

  Widget _buildBorderSideControl({
    required String label,
    required LineStyle currentStyle,
    required double currentThickness,
    required Function(LineStyle) onStyleChanged,
    required Function(double) onThicknessChanged,
  }) {
    return MenuAnchor(
      builder: (context, controller, child) {
        return InkWell(
          onTap: () => controller.isOpen ? controller.close() : controller.open(),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(label, style: const TextStyle(fontSize: 7, fontWeight: FontWeight.bold, color: Colors.black38)),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(_getLineStyleIcon(currentStyle), size: 14, color: const Color(0xFF0F4C5C)),
                    const SizedBox(width: 4),
                    Text('${currentThickness.toStringAsFixed(1)}', style: const TextStyle(fontSize: 8, fontWeight: FontWeight.bold, color: Colors.black54)),
                  ],
                ),
              ],
            ),
          ),
        );
      },
      menuChildren: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: StatefulBuilder(
            builder: (context, setMenuState) {
              return SizedBox(
                width: 220,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Estilo de $label', style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: LineStyle.values.map((style) {
                        final bool isSelected = currentStyle == style;
                        return InkWell(
                          onTap: () => onStyleChanged(style),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: isSelected ? const Color(0xFF0F4C5C).withOpacity(0.1) : Colors.transparent,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSelected ? const Color(0xFF0F4C5C) : Colors.transparent),
                            ),
                            child: Icon(_getLineStyleIcon(style), color: isSelected ? const Color(0xFF0F4C5C) : Colors.black45, size: 20),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Espessura', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                        Text('${currentThickness.toStringAsFixed(1)}px', style: const TextStyle(fontSize: 10, color: Color(0xFF0F4C5C), fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Slider(
                      value: currentThickness,
                      min: 0.0,
                      max: 10.0,
                      divisions: 100,
                      activeColor: const Color(0xFF0F4C5C),
                      onChanged: (v) {
                        setMenuState(() {}); // Força build do StatefulBuilder local
                        onThicknessChanged(v); // Atualiza o Riverpod
                      },
                    ),
                  ],
                ),
              );
            }
          ),
        ),
      ],
    );
  }

  IconData _getLineStyleIcon(LineStyle style) {
    switch (style) {
      case LineStyle.dashed: return Icons.more_horiz_rounded;
      case LineStyle.dotted: return Icons.more_vert_rounded;
      default: return Icons.maximize_rounded;
    }
  }
}
