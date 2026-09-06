import 'package:flutter/material.dart';
import 'page_object.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

class TableObject implements PageObject {
  @override
  final String id;
  @override
  final String type = 'table';
  
  int rows;
  int cols;
  
  // Chave: "row,col", Valor: conteúdo de texto
  Map<String, String> cellData;
  
  // 🚀 v3.1: Suporte a mesclagem (Key: "row,col", Value: "rowSpan,colSpan")
  Map<String, String> cellSpans;

  @override
  Offset position;
  @override
  Size size;
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

  // Estilo
  String borderColor;
  double borderWidth;
  bool showHeader;

  TableObject({
    required this.id,
    this.rows = 3,
    this.cols = 3,
    Map<String, String>? cellData,
    Map<String, String>? cellSpans,
    required this.position,
    this.size = const Size(300, 150),
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
  }) : cellData = cellData ?? {},
       cellSpans = cellSpans ?? {},
       updatedAt = updatedAt ?? TimeService().nowMs();

  // 🚀 v3.1: LÓGICA DE GESTÃO DE ESTRUTURA
  
  void insertRow(int index) {
    final Map<String, String> newData = {};
    for (var entry in cellData.entries) {
      final parts = entry.key.split(',');
      int r = int.parse(parts[0]);
      int c = int.parse(parts[1]);
      if (r >= index) {
        newData['${r + 1},$c'] = entry.value;
      } else {
        newData['$r,$c'] = entry.value;
      }
    }
    cellData = newData;
    rows++;
    size = Size(size.width, size.height + (size.height / (rows - 1)));
    updatedAt = TimeService().nowMs();
  }

  void deleteRow(int index) {
    if (rows <= 1) return;
    final Map<String, String> newData = {};
    for (var entry in cellData.entries) {
      final parts = entry.key.split(',');
      int r = int.parse(parts[0]);
      int c = int.parse(parts[1]);
      if (r < index) {
        newData['$r,$c'] = entry.value;
      } else if (r > index) {
        newData['${r - 1},$c'] = entry.value;
      }
    }
    cellData = newData;
    rows--;
    size = Size(size.width, size.height - (size.height / (rows + 1)));
    updatedAt = TimeService().nowMs();
  }

  void insertColumn(int index) {
    final Map<String, String> newData = {};
    for (var entry in cellData.entries) {
      final parts = entry.key.split(',');
      int r = int.parse(parts[0]);
      int c = int.parse(parts[1]);
      if (c >= index) {
        newData['$r,${c + 1}'] = entry.value;
      } else {
        newData['$r,$c'] = entry.value;
      }
    }
    cellData = newData;
    cols++;
    size = Size(size.width + (size.width / (cols - 1)), size.height);
    updatedAt = TimeService().nowMs();
  }

  void deleteColumn(int index) {
    if (cols <= 1) return;
    final Map<String, String> newData = {};
    for (var entry in cellData.entries) {
      final parts = entry.key.split(',');
      int r = int.parse(parts[0]);
      int c = int.parse(parts[1]);
      if (c < index) {
        newData['$r,$c'] = entry.value;
      } else if (c > index) {
        newData['$r,${c - 1}'] = entry.value;
      }
    }
    cellData = newData;
    cols--;
    size = Size(size.width - (size.width / (cols + 1)), size.height);
    updatedAt = TimeService().nowMs();
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'rows': rows,
      'cols': cols,
      'cell_data': cellData,
      'cell_spans': cellSpans,
      'x': position.dx,
      'y': position.dy,
      'width': size.width,
      'height': size.height,
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
    };
  }

  factory TableObject.fromJson(Map<String, dynamic> json) {
    return TableObject(
      id: json['id'],
      rows: json['rows'] ?? 3,
      cols: json['cols'] ?? 3,
      cellData: Map<String, String>.from(json['cell_data'] ?? {}),
      cellSpans: Map<String, String>.from(json['cell_spans'] ?? {}),
      position: Offset(json['x'], json['y']),
      size: Size(json['width'], json['height']),
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
    );
  }

  @override
  TableObject clone({String? newId, int? newPageNumber}) {
    return TableObject(
      id: newId ?? id,
      rows: rows,
      cols: cols,
      cellData: Map.from(cellData),
      cellSpans: Map.from(cellSpans),
      position: position,
      size: size,
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
    );
  }
}
