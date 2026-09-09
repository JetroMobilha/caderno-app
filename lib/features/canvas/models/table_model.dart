import 'package:flutter/material.dart';
import 'page_object.dart';
import 'table_cell_model.dart';
import 'table_types.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

/// 🚀 v10.0: Implementação Imutável de Tabela Strongly Typed.
/// Substitui Strings "r,c" por classes de valor CellCoordinate.
class TableObject implements PageObject {
  @override
  final String id;
  @override
  final String type = 'table';
  @override
  final String? parentId; // 🚀 v10
  
  final int rows;
  final int cols;
  
  final Map<CellCoordinate, TableCellModel> cells;
  final List<double> rowHeights;
  final List<double> columnWidths;
  final Map<CellCoordinate, CellCoordinate> cellSpans;

  @override
  final Offset position;
  
  @override
  Size get size {
    double h = rowHeights.fold(0, (sum, item) => sum + item);
    double w = columnWidths.fold(0, (sum, item) => sum + item);
    return Size(w, h);
  }

  @override
  final double rotation;
  @override
  final int zIndex;
  @override
  final bool isLocked;
  @override
  final bool isVisible;
  @override
  final double opacity; // 🚀 v10
  @override
  final int updatedAt;
  @override
  final int version;
  @override
  final bool isDeleted;
  @override
  final bool syncedWithCloud;
  @override
  final bool deletedInSession;
  @override
  final int? pageNumber;
  @override
  final String? creatorId;
  @override
  final String? layerId;

  final String borderColor;
  final double borderWidth;
  final bool showHeader;
  final String? tableBackgroundColorHex;

  TableObject({
    required this.id,
    this.parentId,
    this.rows = 3,
    this.cols = 3,
    List<double>? rowHeights,
    List<double>? columnWidths,
    Map<CellCoordinate, CellCoordinate>? cellSpans,
    required this.position,
    this.rotation = 0.0,
    this.zIndex = 0,
    this.isLocked = false,
    this.isVisible = true,
    this.opacity = 1.0,
    int? updatedAt,
    this.version = 1,
    this.isDeleted = false,
    this.syncedWithCloud = false,
    this.deletedInSession = false,
    this.pageNumber,
    this.creatorId,
    this.layerId,
    this.borderColor = '#0F4C5C',
    this.borderWidth = 1.0,
    this.showHeader = true,
    this.tableBackgroundColorHex,
    Map<CellCoordinate, TableCellModel>? cells,
  }) : cells = Map.unmodifiable(cells ?? {}),
       rowHeights = List.unmodifiable(rowHeights ?? List.filled(rows, 40.0)),
       columnWidths = List.unmodifiable(columnWidths ?? List.filled(cols, 100.0)),
       cellSpans = Map.unmodifiable(cellSpans ?? {}),
       updatedAt = updatedAt ?? TimeService().nowMs();

  @override
  TableObject copyWith({
    String? id,
    String? parentId,
    Offset? position,
    Size? size,
    double? rotation,
    int? zIndex,
    bool? isLocked,
    bool? isVisible,
    double? opacity,
    int? updatedAt,
    int? version,
    bool? isDeleted,
    bool? syncedWithCloud,
    bool? deletedInSession,
    int? pageNumber,
    String? layerId,
    int? rows,
    int? cols,
    Map<CellCoordinate, TableCellModel>? cells,
    List<double>? rowHeights,
    List<double>? columnWidths,
    Map<CellCoordinate, CellCoordinate>? cellSpans,
    String? borderColor,
    double? borderWidth,
    bool? showHeader,
    String? tableBackgroundColorHex,
  }) {
    List<double>? finalColWidths = columnWidths ?? this.columnWidths;
    List<double>? finalRowHeights = rowHeights ?? this.rowHeights;
    
    if (size != null) {
      double scaleX = size.width / this.size.width;
      double scaleY = size.height / this.size.height;
      finalColWidths = this.columnWidths.map((w) => w * scaleX).toList();
      finalRowHeights = this.rowHeights.map((h) => h * scaleY).toList();
    }

    return TableObject(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      rows: rows ?? this.rows,
      cols: cols ?? this.cols,
      cells: cells ?? this.cells,
      rowHeights: finalRowHeights,
      columnWidths: finalColWidths,
      cellSpans: cellSpans ?? this.cellSpans,
      position: position ?? this.position,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
      updatedAt: updatedAt ?? TimeService().nowMs(),
      version: version ?? (this.version + 1),
      isDeleted: isDeleted ?? this.isDeleted,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      deletedInSession: deletedInSession ?? this.deletedInSession,
      pageNumber: pageNumber ?? this.pageNumber,
      creatorId: creatorId,
      layerId: layerId ?? this.layerId,
      borderColor: borderColor ?? this.borderColor,
      borderWidth: borderWidth ?? this.borderWidth,
      showHeader: showHeader ?? this.showHeader,
      tableBackgroundColorHex: tableBackgroundColorHex ?? this.tableBackgroundColorHex,
    );
  }

  TableObject insertRowAt(int index) {
    final Map<CellCoordinate, TableCellModel> newCells = {};
    for (var entry in cells.entries) {
      if (entry.key.row >= index) newCells[CellCoordinate(entry.key.row + 1, entry.key.col)] = entry.value;
      else newCells[entry.key] = entry.value;
    }
    final Map<CellCoordinate, CellCoordinate> newSpans = {};
    for (var entry in cellSpans.entries) {
      if (entry.key.row >= index) newSpans[CellCoordinate(entry.key.row + 1, entry.key.col)] = entry.value;
      else newSpans[entry.key] = entry.value;
    }
    final List<double> newHeights = List.from(rowHeights)..insert(index, 40.0);
    return copyWith(rows: rows + 1, cells: newCells, cellSpans: newSpans, rowHeights: newHeights);
  }

  TableObject deleteRowAt(int index) {
    if (rows <= 1) return this;
    final Map<CellCoordinate, TableCellModel> newCells = {};
    for (var entry in cells.entries) {
      if (entry.key.row < index) newCells[entry.key] = entry.value;
      else if (entry.key.row > index) newCells[CellCoordinate(entry.key.row - 1, entry.key.col)] = entry.value;
    }
    final Map<CellCoordinate, CellCoordinate> newSpans = {};
    for (var entry in cellSpans.entries) {
      if (entry.key.row < index) newSpans[entry.key] = entry.value;
      else if (entry.key.row > index) newSpans[CellCoordinate(entry.key.row - 1, entry.key.col)] = entry.value;
    }
    final List<double> newHeights = List.from(rowHeights)..removeAt(index);
    return copyWith(rows: rows - 1, cells: newCells, cellSpans: newSpans, rowHeights: newHeights);
  }

  TableObject insertColumnAt(int index) {
    final Map<CellCoordinate, TableCellModel> newCells = {};
    for (var entry in cells.entries) {
      if (entry.key.col >= index) newCells[CellCoordinate(entry.key.row, entry.key.col + 1)] = entry.value;
      else newCells[entry.key] = entry.value;
    }
    final Map<CellCoordinate, CellCoordinate> newSpans = {};
    for (var entry in cellSpans.entries) {
      if (entry.key.col >= index) newSpans[CellCoordinate(entry.key.row, entry.key.col + 1)] = entry.value;
      else newSpans[entry.key] = entry.value;
    }
    final List<double> newWidths = List.from(columnWidths)..insert(index, 100.0);
    return copyWith(cols: cols + 1, cells: newCells, cellSpans: newSpans, columnWidths: newWidths);
  }

  TableObject deleteColumnAt(int index) {
    if (cols <= 1) return this;
    final Map<CellCoordinate, TableCellModel> newCells = {};
    for (var entry in cells.entries) {
      if (entry.key.col < index) newCells[entry.key] = entry.value;
      else if (entry.key.col > index) newCells[CellCoordinate(entry.key.row, entry.key.col - 1)] = entry.value;
    }
    final Map<CellCoordinate, CellCoordinate> newSpans = {};
    for (var entry in cellSpans.entries) {
      if (entry.key.col < index) newSpans[entry.key] = entry.value;
      else if (entry.key.col > index) newSpans[CellCoordinate(entry.key.row, entry.key.col - 1)] = entry.value;
    }
    final List<double> newWidths = List.from(columnWidths)..removeAt(index);
    return copyWith(cols: cols - 1, cells: newCells, cellSpans: newSpans, columnWidths: newWidths);
  }

  Set<CellCoordinate> getKeysInRange(CellCoordinate start, CellCoordinate end) {
    int minR = start.row < end.row ? start.row : end.row;
    int maxR = start.row > end.row ? start.row : end.row;
    int minC = start.col < end.col ? start.col : end.col;
    int maxC = start.col > end.col ? start.col : end.col;

    final Set<CellCoordinate> result = {};
    for (int r = minR; r <= maxR; r++) {
      for (int c = minC; c <= maxC; c++) result.add(CellCoordinate(r, c));
    }
    return result;
  }

  CellCoordinate resolveMasterCell(int r, int c) {
    final CellCoordinate current = CellCoordinate(r, c);
    if (cellSpans.containsKey(current)) return current;
    for (var entry in cellSpans.entries) {
      if (r >= entry.key.row && r < entry.key.row + entry.value.row &&
          c >= entry.key.col && c < entry.key.col + entry.value.col) {
        return entry.key;
      }
    }
    return current;
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'parent_id': parentId, 'rows': rows, 'cols': cols,
    'cells': cells.map((key, value) => MapEntry(key.toString(), value.toJson())),
    'row_heights': rowHeights, 'column_widths': columnWidths, 
    'cell_spans': cellSpans.map((k, v) => MapEntry(k.toString(), v.toString())),
    'x': position.dx, 'y': position.dy, 'rotation': rotation, 'z_index': zIndex,
    'is_locked': isLocked ? 1 : 0, 'is_visible': isVisible ? 1 : 0, 'opacity': opacity,
    'updated_at': updatedAt, 'version': version, 'is_deleted': isDeleted ? 1 : 0,
    'synced_with_cloud': syncedWithCloud ? 1 : 0, 'deleted_in_session': deletedInSession ? 1 : 0,
    'page_number': pageNumber, 'creator_id': creatorId, 'layer_id': layerId,
    'border_color': borderColor, 'border_width': borderWidth,
    'show_header': showHeader ? 1 : 0, 'table_bg_color': tableBackgroundColorHex,
  };

  factory TableObject.fromJson(Map<String, dynamic> json) {
    final Map<CellCoordinate, TableCellModel> cellsMap = {};
    if (json['cells'] != null) {
      (json['cells'] as Map).forEach((k, v) => cellsMap[CellCoordinate.fromString(k.toString())] = TableCellModel.fromJson(Map<String, dynamic>.from(v)));
    }
    final Map<CellCoordinate, CellCoordinate> spansMap = {};
    if (json['cell_spans'] != null) {
      (json['cell_spans'] as Map).forEach((k, v) => spansMap[CellCoordinate.fromString(k.toString())] = CellCoordinate.fromString(v.toString()));
    }
    int rows = json['rows'] ?? 3, cols = json['cols'] ?? 3;
    return TableObject(
      id: json['id'], parentId: json['parent_id'], rows: rows, cols: cols,
      rowHeights: json['row_heights'] != null ? List<double>.from(json['row_heights']) : List.filled(rows, 40.0),
      columnWidths: json['column_widths'] != null ? List<double>.from(json['column_widths']) : List.filled(cols, 100.0),
      cells: cellsMap, cellSpans: spansMap,
      position: Offset(json['x']?.toDouble() ?? 0, json['y']?.toDouble() ?? 0),
      rotation: json['rotation']?.toDouble() ?? 0.0, zIndex: json['z_index'] ?? 0,
      isLocked: json['is_locked'] == 1, isVisible: json['is_visible'] == 1,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      updatedAt: json['updated_at'], version: json['version'] ?? 1,
      isDeleted: json['is_deleted'] == 1, syncedWithCloud: json['synced_with_cloud'] == 1,
      deletedInSession: json['deleted_in_session'] == 1, pageNumber: json['page_number'],
      creatorId: json['creator_id'], layerId: json['layer_id'],
      borderColor: json['border_color'] ?? '#0F4C5C', borderWidth: json['border_width']?.toDouble() ?? 1.0,
      showHeader: json['show_header'] == 1, tableBackgroundColorHex: json['table_bg_color'],
    );
  }

  @override
  TableObject clone({String? newId, int? newPageNumber}) {
    return copyWith(
      id: newId ?? id,
      pageNumber: newPageNumber ?? pageNumber,
      updatedAt: TimeService().nowMs(),
      version: 1,
      syncedWithCloud: false,
    );
  }
}
