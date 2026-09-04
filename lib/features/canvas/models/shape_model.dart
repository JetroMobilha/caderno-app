import 'package:flutter/material.dart';
import 'page_object.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

enum ShapeType { rectangle, circle, line, arrow, triangle }

class ShapeObject implements PageObject {
  @override
  final String id;
  @override
  final String type = 'shape';
  
  final ShapeType shapeType;
  
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
  
  String? layerId;

  String strokeColor;
  String? fillColor;
  double strokeWidth;
  bool isClosed;

  ShapeObject({
    required this.id,
    required this.shapeType,
    required this.position,
    required this.size,
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
    this.strokeColor = '#000000',
    this.fillColor,
    this.strokeWidth = 2.0,
    this.isClosed = true,
  }) : updatedAt = updatedAt ?? TimeService().nowMs();

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'shape_type': shapeType.name,
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
      'stroke_color': strokeColor,
      'fill_color': fillColor,
      'stroke_width': strokeWidth,
      'is_closed': isClosed ? 1 : 0,
    };
  }

  factory ShapeObject.fromJson(Map<String, dynamic> json) {
    return ShapeObject(
      id: json['id'],
      shapeType: ShapeType.values.firstWhere((e) => e.name == json['shape_type']),
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
      strokeColor: json['stroke_color'] ?? '#000000',
      fillColor: json['fill_color'],
      strokeWidth: json['stroke_width']?.toDouble() ?? 2.0,
      isClosed: json['is_closed'] == 1,
    );
  }

  @override
  ShapeObject clone({String? newId, int? newPageNumber}) {
    return ShapeObject(
      id: newId ?? id,
      shapeType: shapeType,
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
      strokeColor: strokeColor,
      fillColor: fillColor,
      strokeWidth: strokeWidth,
      isClosed: isClosed,
    );
  }
}
