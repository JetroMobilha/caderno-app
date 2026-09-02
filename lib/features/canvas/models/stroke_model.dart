import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import '../../../core/utils/geometry_utils.dart';
import 'page_object.dart';

class Stroke implements PageObject {
  @override
  String id;
  @override
  String get type => 'stroke';
  
  String color;
  double thickness;
  List<Offset> points;
  
  @override
  bool isDeleted; 
  @override
  bool deletedInSession; 
  @override
  int updatedAt; 
  @override
  int version;
  @override
  int? pageNumber; 
  Offset liveOffset = Offset.zero; 
  @override
  final String? creatorId;
  @override
  bool syncedWithCloud;
  bool isHighlighter;

  @override
  int zIndex;
  @override
  bool isLocked;
  @override
  bool isVisible;

  Stroke({
    String? id,
    required this.color,
    required this.thickness,
    required this.points,
    this.isDeleted = false,
    this.deletedInSession = false,
    int? updatedAt,
    this.version = 1,
    this.pageNumber,
    this.creatorId,
    this.syncedWithCloud = false,
    this.isHighlighter = false,
    this.zIndex = 0,
    this.isLocked = false,
    this.isVisible = true,
  }) : id = id ?? const Uuid().v4(),
       updatedAt = updatedAt ?? TimeService().nowMs();

  @override
  Offset get position {
    if (points.isEmpty) return Offset.zero;
    double minX = points.first.dx;
    double minY = points.first.dy;
    for (var p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dy < minY) minY = p.dy;
    }
    return Offset(minX, minY);
  }

  @override
  set position(Offset value) {
    final delta = value - position;
    for (int i = 0; i < points.length; i++) {
      points[i] += delta;
    }
  }

  @override
  Size get size {
    if (points.isEmpty) return Size.zero;
    double minX = points.first.dx, maxX = points.first.dx;
    double minY = points.first.dy, maxY = points.first.dy;
    for (var p in points) {
      if (p.dx < minX) minX = p.dx;
      if (p.dx > maxX) maxX = p.dx;
      if (p.dy < minY) minY = p.dy;
      if (p.dy > maxY) maxY = p.dy;
    }
    return Size(maxX - minX, maxY - minY);
  }

  @override
  set size(Size value) {
    // Redimensionar strokes é complexo, para MVP podemos ignorar ou escalar pontos
    final currentSize = size;
    if (currentSize.width == 0 || currentSize.height == 0) return;
    final scaleX = value.width / currentSize.width;
    final scaleY = value.height / currentSize.height;
    final pos = position;
    for (int i = 0; i < points.length; i++) {
      points[i] = Offset(
        pos.dx + (points[i].dx - pos.dx) * scaleX,
        pos.dy + (points[i].dy - pos.dy) * scaleY,
      );
    }
  }

  @override
  double get rotation => 0.0; // Strokes geralmente não rotacionam individualmente no MVP
  @override
  set rotation(double value) {}

  @override
  Map<String, dynamic> toJson({bool includePoints = true}) {
    return {
      'id': id,
      'type': type,
      'color': color,
      'thickness': thickness,
      'is_deleted': isDeleted,
      'deleted_in_session': deletedInSession,
      'updated_at': updatedAt,
      'version': version,
      'creator_id': creatorId,
      'synced_with_cloud': syncedWithCloud ? 1 : 0,
      'is_highlighter': isHighlighter ? 1 : 0,
      'z_index': zIndex,
      'is_locked': isLocked ? 1 : 0,
      'is_visible': isVisible ? 1 : 0,
      if (pageNumber != null) 'page_number': pageNumber,
      if (includePoints) 'points': points.map((p) => {
        'dx': double.parse(p.dx.toStringAsFixed(1)),
        'dy': double.parse(p.dy.toStringAsFixed(1))
      }).toList(),
    };
  }

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      id: json['id']?.toString(),
      color: json['color']?.toString() ?? '#1A1A24',
      thickness: (json['thickness'] as num?)?.toDouble() ?? 3.0,
      isDeleted: json['is_deleted'] == true || json['is_deleted'] == 1,
      deletedInSession: json['deleted_in_session'] == true || json['deleted_in_session'] == 1,
      updatedAt: (json['updated_at'] as num?)?.toInt() ?? (json['updatedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      version: int.tryParse(json['version']?.toString() ?? '1') ?? 1,
      pageNumber: json['page_number'] as int?,
      creatorId: json['creator_id']?.toString(),
      syncedWithCloud: json['synced_with_cloud'] == null ? true : (json['synced_with_cloud'] == true || json['synced_with_cloud'] == 1),
      isHighlighter: json['is_highlighter'] == true || json['is_highlighter'] == 1,
      zIndex: (json['z_index'] as num?)?.toInt() ?? 0,
      isLocked: json['is_locked'] == true || json['is_locked'] == 1,
      isVisible: json['is_visible'] == null ? true : (json['is_visible'] == true || json['is_visible'] == 1),
      points: json['points'] != null
          ? (json['points'] as List)
          .map((p) => Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()))
          .toList()
          : <Offset>[],
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory Stroke.fromJsonString(String jsonStr) => Stroke.fromJson(jsonDecode(jsonStr));

  Stroke simplify({double epsilon = 0.5}) {
    return Stroke(
      id: id,
      color: color,
      thickness: thickness,
      points: GeometryUtils.simplifyPoints(points, epsilon: epsilon),
      isDeleted: isDeleted,
      deletedInSession: deletedInSession,
      updatedAt: updatedAt,
      version: version,
      pageNumber: pageNumber,
      creatorId: creatorId,
      syncedWithCloud: syncedWithCloud,
      isHighlighter: isHighlighter,
      zIndex: zIndex,
      isLocked: isLocked,
      isVisible: isVisible,
    );
  }

  Stroke clone({String? newId, int? newPageNumber}) {
    return Stroke(
      id: newId ?? const Uuid().v4(),
      color: color,
      thickness: thickness,
      points: List.from(points),
      isDeleted: isDeleted,
      deletedInSession: deletedInSession,
      updatedAt: TimeService().nowMs(),
      version: 1,
      pageNumber: newPageNumber ?? pageNumber,
      creatorId: creatorId,
      syncedWithCloud: false,
      isHighlighter: isHighlighter,
      zIndex: zIndex,
      isLocked: isLocked,
      isVisible: isVisible,
    );
  }
}
