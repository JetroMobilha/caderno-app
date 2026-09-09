import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'canvas_enums.dart';
import 'page_object.dart';

/// 🚀 v10.0: Implementação Imutável de Traço (Desenho).
class Stroke implements PageObject {
  @override
  final String id;
  @override
  String get type => 'stroke';
  @override
  final String? parentId; // 🚀 v10
  
  final BrushType brushType;
  final double smoothingLevel; // 🚀 v10.16: Substitui isSmoothed (0.0 a 1.0)
  final String color;
  final double thickness;
  final List<Offset> points;
  
  @override
  final bool isDeleted; 
  @override
  final bool deletedInSession; 
  @override
  final int updatedAt; 
  @override
  final int version;
  @override
  final int? pageNumber; 
  
  final Offset liveOffset; 
  @override
  final String? creatorId;
  @override
  final bool syncedWithCloud;
  final bool isHighlighter;

  @override
  final int zIndex;
  @override
  final bool isLocked;
  @override
  final bool isVisible;
  @override
  final double opacity; // 🚀 v10
  
  @override
  double get rotation => 0.0;
  
  @override
  final String? layerId;

  Stroke({
    String? id,
    this.parentId,
    required this.color,
    required this.thickness,
    required List<Offset> points,
    this.isDeleted = false,
    this.deletedInSession = false,
    int? updatedAt,
    this.version = 1,
    this.pageNumber,
    this.creatorId,
    this.syncedWithCloud = false,
    this.isHighlighter = false,
    this.brushType = BrushType.gel,
    this.smoothingLevel = 0.0,
    this.zIndex = 0,
    this.isLocked = false,
    this.isVisible = true,
    this.opacity = 1.0,
    this.layerId,
    this.liveOffset = Offset.zero,
  }) : id = id ?? const Uuid().v4(),
       this.points = List.unmodifiable(points),
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
  Stroke copyWith({
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
    BrushType? brushType,
    double? smoothingLevel,
    String? color,
    double? thickness,
    List<Offset>? points,
    Offset? liveOffset,
    bool? isHighlighter,
  }) {
    List<Offset>? finalPoints = points ?? this.points;

    if (position != null) {
      final delta = position - this.position;
      finalPoints = this.points.map((p) => p + delta).toList();
    }

    if (size != null) {
      final currentSize = this.size;
      if (currentSize.width != 0 && currentSize.height != 0) {
        final scaleX = size.width / currentSize.width;
        final scaleY = size.height / currentSize.height;
        final pos = this.position;
        finalPoints = this.points.map((p) => Offset(
          pos.dx + (p.dx - pos.dx) * scaleX,
          pos.dy + (p.dy - pos.dy) * scaleY,
        )).toList();
      }
    }

    return Stroke(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      color: color ?? this.color,
      thickness: thickness ?? this.thickness,
      points: finalPoints,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedInSession: deletedInSession ?? this.deletedInSession,
      updatedAt: updatedAt ?? TimeService().nowMs(),
      version: version ?? (this.version + 1),
      pageNumber: pageNumber ?? this.pageNumber,
      creatorId: creatorId ?? this.creatorId,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      isHighlighter: isHighlighter ?? this.isHighlighter,
      brushType: brushType ?? this.brushType,
      smoothingLevel: smoothingLevel ?? this.smoothingLevel,
      zIndex: zIndex ?? this.zIndex,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
      layerId: layerId ?? this.layerId,
      liveOffset: liveOffset ?? this.liveOffset,
    );
  }

  @override
  Map<String, dynamic> toJson({bool includePoints = true}) {
    return {
      'id': id,
      'type': type,
      'parent_id': parentId,
      'color': color,
      'thickness': thickness,
      'is_deleted': isDeleted,
      'deleted_in_session': deletedInSession,
      'updated_at': updatedAt,
      'version': version,
      'creator_id': creatorId,
      'synced_with_cloud': syncedWithCloud ? 1 : 0,
      'is_highlighter': isHighlighter ? 1 : 0,
      'brush_type': brushType.name,
      'smoothing_level': smoothingLevel,
      'z_index': zIndex,
      'is_locked': isLocked ? 1 : 0,
      'is_visible': isVisible ? 1 : 0,
      'opacity': opacity,
      'layer_id': layerId,
      if (pageNumber != null) 'page_number': pageNumber,
      if (includePoints) 'points': points.map((p) => {
        'dx': double.parse(p.dx.toStringAsFixed(3)),
        'dy': double.parse(p.dy.toStringAsFixed(3))
      }).toList(),
    };
  }

  factory Stroke.fromJson(Map<String, dynamic> json) {
    return Stroke(
      id: json['id']?.toString(),
      parentId: json['parent_id']?.toString(),
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
      brushType: BrushType.values.firstWhere((e) => e.name == (json['brush_type'] ?? 'gel'), orElse: () => BrushType.gel),
      smoothingLevel: (json['smoothing_level'] as num?)?.toDouble() ?? (json['is_smoothed'] == 1 || json['is_smoothed'] == true ? 1.0 : 0.0),
      zIndex: (json['z_index'] as num?)?.toInt() ?? 0,
      isLocked: json['is_locked'] == true || json['is_locked'] == 1,
      isVisible: json['is_visible'] == null ? true : (json['is_visible'] == true || json['is_visible'] == 1),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      layerId: json['layer_id']?.toString(),
      points: json['points'] != null
          ? (json['points'] as List)
          .map((p) => Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()))
          .toList()
          : <Offset>[],
    );
  }

  @override
  Stroke clone({String? newId, int? newPageNumber}) {
    return copyWith(
      id: newId ?? const Uuid().v4(),
      pageNumber: newPageNumber ?? pageNumber,
      updatedAt: TimeService().nowMs(),
      version: 1,
      syncedWithCloud: false,
    );
  }
}
