import 'package:flutter/material.dart';
import 'page_object.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

enum ShapeType { rectangle, circle, line, arrow, triangle }

/// 🚀 v10.0: Implementação Imutável de Objeto de Forma Refatorada.
class ShapeObject implements PageObject {
  @override
  final String id;
  @override
  final String type = 'shape';
  @override
  final String? parentId; // 🚀 v10
  
  final ShapeType shapeType;
  
  @override
  final Offset position;
  @override
  final Size size;
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

  final String strokeColor;
  final String? fillColor;
  final double strokeWidth;
  final bool isClosed;

  ShapeObject({
    required this.id,
    this.parentId,
    required this.shapeType,
    required this.position,
    required this.size,
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
    this.strokeColor = '#000000',
    this.fillColor,
    this.strokeWidth = 2.0,
    this.isClosed = true,
  }) : updatedAt = updatedAt ?? TimeService().nowMs();

  @override
  ShapeObject copyWith({
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
    String? creatorId,
    String? layerId,
    String? strokeColor,
    String? fillColor,
    double? strokeWidth,
    bool? isClosed,
  }) {
    return ShapeObject(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      shapeType: shapeType,
      position: position ?? this.position,
      size: size ?? this.size,
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
      strokeColor: strokeColor ?? this.strokeColor,
      fillColor: fillColor ?? this.fillColor,
      strokeWidth: strokeWidth ?? this.strokeWidth,
      isClosed: isClosed ?? this.isClosed,
    );
  }

  @override
  ShapeObject clone({String? newId, int? newPageNumber}) {
    return copyWith(
      id: newId ?? id,
      pageNumber: newPageNumber ?? pageNumber,
      updatedAt: TimeService().nowMs(),
      version: 1,
      syncedWithCloud: false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'parent_id': parentId,
      'shape_type': shapeType.name,
      'x': position.dx,
      'y': position.dy,
      'width': size.width,
      'height': size.height,
      'rotation': rotation,
      'z_index': zIndex,
      'is_locked': isLocked ? 1 : 0,
      'is_visible': isVisible ? 1 : 0,
      'opacity': opacity,
      'updated_at': updatedAt,
      'version': version,
      'is_deleted': isDeleted ? 1 : 0,
      'synced_with_cloud': syncedWithCloud ? 1 : 0,
      'deleted_in_session': deletedInSession ? 1 : 0,
      'page_number': pageNumber,
      'creator_id': creatorId,
      'layer_id': layerId,
      'stroke_color': strokeColor,
      'fill_color': fillColor,
      'stroke_width': strokeWidth,
      'is_closed': isClosed ? 1 : 0,
    };
  }

  factory ShapeObject.fromJson(Map<String, dynamic> json) {
    return ShapeObject(
      id: json['id'],
      parentId: json['parent_id'],
      shapeType: ShapeType.values.firstWhere((e) => e.name == json['shape_type']),
      position: Offset(json['x']?.toDouble() ?? 0.0, json['y']?.toDouble() ?? 0.0),
      size: Size(json['width']?.toDouble() ?? 100.0, json['height']?.toDouble() ?? 100.0),
      rotation: json['rotation']?.toDouble() ?? 0.0,
      zIndex: json['z_index'] ?? 0,
      isLocked: json['is_locked'] == 1 || json['is_locked'] == true,
      isVisible: json['is_visible'] == null ? true : (json['is_visible'] == 1 || json['is_visible'] == true),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      updatedAt: json['updated_at'],
      version: json['version'] ?? 1,
      isDeleted: json['is_deleted'] == 1 || json['is_deleted'] == true,
      syncedWithCloud: json['synced_with_cloud'] == 1 || json['synced_with_cloud'] == true,
      deletedInSession: json['deleted_in_session'] == 1 || json['deleted_in_session'] == true,
      pageNumber: json['page_number'],
      creatorId: json['creator_id'],
      layerId: json['layer_id'],
      strokeColor: json['stroke_color'] ?? '#000000',
      fillColor: json['fill_color'],
      strokeWidth: json['stroke_width']?.toDouble() ?? 2.0,
      isClosed: json['is_closed'] == 1,
    );
  }
}
