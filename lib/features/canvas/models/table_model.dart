import 'package:flutter/material.dart';
import 'page_object.dart';
import 'table_cell_model.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

/// Representação de uma tabela no canvas.
/// Utiliza um sistema baseado em [Stack] e [Positioned] para permitir
/// flexibilidade total em larguras de coluna e alturas de linha, além de spans.
class TableObject implements PageObject {
  @override
  final String id;
  @override
  final String type = 'table';
  
  int rows;
  int cols;
  
  // Chave: "row,col", Valor: TableCellModel
  Map<String, TableCellModel> _cells;
  Map<String, TableCellModel> get cells => _cells;
  set cells(Map<String, TableCellModel> value) => _cells = value;
  
  // 🚀 v4.0: Dimensões individuais por linha/coluna
  List<double> rowHeights;
  List<double> columnWidths;

  // 🚀 v3.1: Suporte a mesclagem (Key: "row,col", Value: "rowSpan,colSpan")
  Map<String, String> cellSpans;

  @override
  Offset position;
  
  @override
  Size get size {
    double h = rowHeights.fold(0, (sum, item) => sum + item);
    double w = columnWidths.fold(0, (sum, item) => sum + item);
    return Size(w, h);
  }
  
  @override
  set size(Size value) {
    // Quando redimensionamos a tabela inteira (alça global), 
    // distribuímos proporcionalmente o novo tamanho.
    double scaleX = value.width / size.width;
    double scaleY = value.height / size.height;
    
    for (int i = 0; i < columnWidths.length; i++) {
      columnWidths[i] *= scaleX;
    }
    for (int i = 0; i < rowHeights.length; i++) {
      rowHeights[i] *= scaleY;
    }
  }

  @override
  double rotation;
  @override
  int zIndex;
  @override
  bool isLocked;
  @override
  bool isVisible;
  @override
  int updatedAt;
  @override
  int version;
  @override
  bool isDeleted;
  @override
  bool syncedWithCloud;
  @override
  bool deletedInSession;
  @override
  int? pageNumber;
  @override
  final String? creatorId;
  @override
  String? layerId;

  // Estilo Global
  String borderColor;
  double borderWidth;
  bool showHeader;
  String? tableBackgroundColorHex;

  TableObject({
    required this.id,
    this.rows = 3,
    this.cols = 3,
    List<double>? rowHeights,
    List<double>? columnWidths,
    Map<String, String>? cellSpans,
    required this.position,
    this.rotation = 0.0,
    this.zIndex = 0,
    this.isLocked = false,
    this.isVisible = true,
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
    Map<String, TableCellModel>? cells,
  }) : _cells = cells ?? {},
       rowHeights = rowHeights ?? List.filled(rows, 40.0),
       columnWidths = columnWidths ?? List.filled(cols, 100.0),
       cellSpans = cellSpans ?? {},
       updatedAt = updatedAt ?? TimeService().nowMs();

  // 🚀 v3.1: LÓGICA DE GESTÃO DE ESTRUTURA
  
  void insertRow(int index) {
    final Map<String, TableCellModel> newCells = {};
    for (var entry in cells.entries) {
      final parts = entry.key.split(',');
      if (parts.length < 2) continue; // 🚀 v6.3: Segurança contra chaves malformatadas

      int? r = int.tryParse(parts[0]);
      int? c = int.tryParse(parts[1]);
      if (r == null || c == null) continue;

      if (r >= index) {
        newCells['${r + 1},$c'] = entry.value;
      } else {
        newCells['$r,$c'] = entry.value;
      }
    }
    _cells = newCells;

    // 🚀 v4.6: Shift Spans
    final Map<String, String> newSpans = {};
    for (var entry in cellSpans.entries) {
      final parts = entry.key.split(',');
      if (parts.length < 2) continue;

      int? r = int.tryParse(parts[0]);
      int? c = int.tryParse(parts[1]);
      if (r == null || c == null) continue;

      if (r >= index) {
        newSpans['${r + 1},$c'] = entry.value;
      } else {
        newSpans['$r,$c'] = entry.value;
      }
    }
    cellSpans = newSpans;

    rows++;
    rowHeights.insert(index, 40.0);
    updatedAt = TimeService().nowMs();
  }

  void deleteRow(int index) {
    if (rows <= 1) return;
    final Map<String, TableCellModel> newCells = {};
    for (var entry in cells.entries) {
      final parts = entry.key.split(',');
      if (parts.length < 2) continue;

      int? r = int.tryParse(parts[0]);
      int? c = int.tryParse(parts[1]);
      if (r == null || c == null) continue;

      if (r < index) {
        newCells['$r,$c'] = entry.value;
      } else if (r > index) {
        newCells['${r - 1},$c'] = entry.value;
      }
    }
    _cells = newCells;

    // Shift Spans
    final Map<String, String> newSpans = {};
    for (var entry in cellSpans.entries) {
      final parts = entry.key.split(',');
      if (parts.length < 2) continue;

      int? r = int.tryParse(parts[0]);
      int? c = int.tryParse(parts[1]);
      if (r == null || c == null) continue;

      if (r < index) {
        newSpans['$r,$c'] = entry.value;
      } else if (r > index) {
        newSpans['${r - 1},$c'] = entry.value;
      }
    }
    cellSpans = newSpans;

    rows--;
    rowHeights.removeAt(index);
    updatedAt = TimeService().nowMs();
  }

  void insertColumn(int index) {
    final Map<String, TableCellModel> newCells = {};
    for (var entry in cells.entries) {
      final parts = entry.key.split(',');
      if (parts.length < 2) continue;

      int? r = int.tryParse(parts[0]);
      int? c = int.tryParse(parts[1]);
      if (r == null || c == null) continue;

      if (c >= index) {
        newCells['$r,${c + 1}'] = entry.value;
      } else {
        newCells['$r,$c'] = entry.value;
      }
    }
    _cells = newCells;

    // Shift Spans
    final Map<String, String> newSpans = {};
    for (var entry in cellSpans.entries) {
      final parts = entry.key.split(',');
      if (parts.length < 2) continue;

      int? r = int.tryParse(parts[0]);
      int? c = int.tryParse(parts[1]);
      if (r == null || c == null) continue;

      if (c >= index) {
        newSpans['$r,${c + 1}'] = entry.value;
      } else {
        newSpans['$r,$c'] = entry.value;
      }
    }
    cellSpans = newSpans;

    cols++;
    columnWidths.insert(index, 100.0);
    updatedAt = TimeService().nowMs();
  }

  void deleteColumn(int index) {
    if (cols <= 1) return;
    final Map<String, TableCellModel> newCells = {};
    for (var entry in cells.entries) {
      final parts = entry.key.split(',');
      if (parts.length < 2) continue;

      int? r = int.tryParse(parts[0]);
      int? c = int.tryParse(parts[1]);
      if (r == null || c == null) continue;

      if (c < index) {
        newCells['$r,$c'] = entry.value;
      } else if (c > index) {
        newCells['$r,${c - 1}'] = entry.value;
      }
    }
    _cells = newCells;

    // Shift Spans
    final Map<String, String> newSpans = {};
    for (var entry in cellSpans.entries) {
      final parts = entry.key.split(',');
      if (parts.length < 2) continue;

      int? r = int.tryParse(parts[0]);
      int? c = int.tryParse(parts[1]);
      if (r == null || c == null) continue;

      if (c < index) {
        newSpans['$r,$c'] = entry.value;
      } else if (c > index) {
        newSpans['$r,${c - 1}'] = entry.value;
      }
    }
    cellSpans = newSpans;

    cols--;
    columnWidths.removeAt(index);
    updatedAt = TimeService().nowMs();
  }

  // 🚀 v5.4: Utilitário para seleção de intervalo com ID da tabela
  Set<String> getKeysInRange(String startKey, String endKey) {
    // Suportar tanto formato antigo "r,c" quanto novo "id:r,c"
    final sStr = startKey.contains(':') ? startKey.split(':')[1] : startKey;
    final eStr = endKey.contains(':') ? endKey.split(':')[1] : endKey;

    final startParts = sStr.split(',');
    final endParts = eStr.split(',');
    
    if (startParts.length < 2 || endParts.length < 2) return {startKey};

    int? r1 = int.tryParse(startParts[0]);
    int? c1 = int.tryParse(startParts[1]);
    int? r2 = int.tryParse(endParts[0]);
    int? c2 = int.tryParse(endParts[1]);

    if (r1 == null || c1 == null || r2 == null || c2 == null) return {startKey};

    int minR = r1 < r2 ? r1 : r2;
    int maxR = r1 > r2 ? r1 : r2;
    int minC = c1 < c2 ? c1 : c2;
    int maxC = c1 > c2 ? c1 : c2;

    final Set<String> result = {};
    for (int r = minR; r <= maxR; r++) {
      for (int c = minC; c <= maxC; c++) {
        result.add('$id:$r,$c'); // 🚀 v5.4: Adicionado prefixo de ID
      }
    }
    return result;
  }

  /// 🚀 v7.2: Resolve a célula mestre caso a posição dada esteja coberta por um span.
  /// Retorna a chave no formato "row,col".
  String resolveMasterCell(int r, int c) {
    // 1. Verificar se a própria célula é mestre de um span
    final currentKey = '$r,$c';
    if (cellSpans.containsKey(currentKey)) return currentKey;

    // 2. Procurar spans que cubram esta coordenada
    for (var entry in cellSpans.entries) {
      final masterCoords = entry.key.split(',');
      final spanValue = entry.value.split(',');
      
      int masterR = int.parse(masterCoords[0]);
      int masterC = int.parse(masterCoords[1]);
      int rowSpan = int.parse(spanValue[0]);
      int colSpan = int.parse(spanValue[1]);

      if (r >= masterR && r < masterR + rowSpan &&
          c >= masterC && c < masterC + colSpan) {
        return entry.key; // Encontrou a mestre que cobre esta área
      }
    }

    return currentKey; // Não faz parte de nenhum span especial
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'rows': rows,
      'cols': cols,
      'cells': cells.map((key, value) => MapEntry(key, value.toJson())),
      'row_heights': rowHeights,
      'column_widths': columnWidths,
      'cell_spans': cellSpans,
      'x': position.dx,
      'y': position.dy,
      'rotation': rotation,
      'z_index': zIndex,
      'is_locked': isLocked ? 1 : 0,
      'is_visible': isVisible ? 1 : 0,
      'updated_at': updatedAt,
      'version': version,
      'is_deleted': isDeleted ? 1 : 0,
      'synced_with_cloud': syncedWithCloud ? 1 : 0,
      'deleted_in_session': deletedInSession ? 1 : 0,
      'page_number': pageNumber,
      'creator_id': creatorId,
      'layer_id': layerId,
      'border_color': borderColor,
      'border_width': borderWidth,
      'show_header': showHeader ? 1 : 0,
      'table_bg_color': tableBackgroundColorHex,
    };
  }

  factory TableObject.fromJson(Map<String, dynamic> json) {
    final Map<String, TableCellModel> cellsMap = {};
    if (json['cells'] != null) {
      (json['cells'] as Map).forEach((k, v) {
        cellsMap[k.toString()] = TableCellModel.fromJson(Map<String, dynamic>.from(v));
      });
    }

    int rows = json['rows'] ?? 3;
    int cols = json['cols'] ?? 3;

    return TableObject(
      id: json['id'],
      rows: rows,
      cols: cols,
      rowHeights: json['row_heights'] != null ? List<double>.from(json['row_heights']) : List.filled(rows, 40.0),
      columnWidths: json['column_widths'] != null ? List<double>.from(json['column_widths']) : List.filled(cols, 100.0),
      cells: cellsMap,
      cellSpans: Map<String, String>.from(json['cell_spans'] ?? {}),
      position: Offset(json['x']?.toDouble() ?? 0, json['y']?.toDouble() ?? 0),
      rotation: json['rotation']?.toDouble() ?? 0.0,
      zIndex: json['z_index'] ?? 0,
      isLocked: json['is_locked'] == 1,
      isVisible: json['is_visible'] == 1,
      updatedAt: json['updated_at'],
      version: json['version'] ?? 1,
      isDeleted: json['is_deleted'] == 1,
      syncedWithCloud: json['synced_with_cloud'] == 1,
      deletedInSession: json['deleted_in_session'] == 1,
      pageNumber: json['page_number'],
      creatorId: json['creator_id'],
      layerId: json['layer_id'],
      borderColor: json['border_color'] ?? '#0F4C5C',
      borderWidth: json['border_width']?.toDouble() ?? 1.0,
      showHeader: json['show_header'] == 1,
      tableBackgroundColorHex: json['table_bg_color'],
    );
  }

  @override
  TableObject clone({String? newId, int? newPageNumber}) {
    return TableObject(
      id: newId ?? id,
      rows: rows,
      cols: cols,
      rowHeights: List.from(rowHeights),
      columnWidths: List.from(columnWidths),
      cells: cells.map((k, v) => MapEntry(k, v.clone())),
      cellSpans: Map.from(cellSpans),
      position: position,
      rotation: rotation,
      zIndex: zIndex,
      isLocked: isLocked,
      isVisible: isVisible,
      updatedAt: updatedAt,
      version: version,
      isDeleted: isDeleted,
      syncedWithCloud: false,
      deletedInSession: false,
      pageNumber: newPageNumber ?? pageNumber,
      creatorId: creatorId,
      layerId: layerId,
      borderColor: borderColor,
      borderWidth: borderWidth,
      showHeader: showHeader,
      tableBackgroundColorHex: tableBackgroundColorHex,
    );
  }
}
