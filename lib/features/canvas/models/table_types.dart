import 'package:flutter/foundation.dart';

/// 🚀 v9.7: Coordenada de célula fortemente tipada.
@immutable
class CellCoordinate {
  final int row;
  final int col;

  const CellCoordinate(this.row, this.col);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CellCoordinate &&
          runtimeType == other.runtimeType &&
          row == other.row &&
          col == other.col;

  @override
  int get hashCode => row.hashCode ^ col.hashCode;

  @override
  String toString() => '$row,$col';

  factory CellCoordinate.fromString(String s) {
    try {
      final parts = s.split(',');
      if (parts.length < 2) return const CellCoordinate(0, 0);
      return CellCoordinate(int.parse(parts[0]), int.parse(parts[1]));
    } catch (e) {
      return const CellCoordinate(0, 0);
    }
  }
}

/// 🚀 v9.7: Identidade única de uma célula no canvas global.
@immutable
class TableCellKey {
  final String tableId;
  final CellCoordinate coordinate;

  const TableCellKey(this.tableId, this.coordinate);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TableCellKey &&
          runtimeType == other.runtimeType &&
          tableId == other.tableId &&
          coordinate == other.coordinate;

  @override
  int get hashCode => tableId.hashCode ^ coordinate.hashCode;

  @override
  String toString() => '$tableId:${coordinate.toString()}';

  factory TableCellKey.fromString(String s) {
    try {
      final parts = s.split(':');
      if (parts.length < 2) return TableCellKey('', CellCoordinate.fromString(s));
      return TableCellKey(parts[0], CellCoordinate.fromString(parts[1]));
    } catch (e) {
      return const TableCellKey('', CellCoordinate(0, 0));
    }
  }
}
