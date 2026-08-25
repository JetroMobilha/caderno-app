import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import '../../../core/utils/geometry_utils.dart';

class Stroke {
  String id;
  String color;
  double thickness;
  List<Offset> points;
  bool isDeleted; 
  bool deletedInSession; 
  int updatedAt; 
  int version;
  final int? pageNumber; 
  Offset liveOffset = Offset.zero; 
  final String? creatorId;
  bool syncedWithCloud;
  bool isHighlighter; // 🚀 NOVO

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
    this.isHighlighter = false, // Padrão falso
  }) : id = id ?? const Uuid().v4(),
       updatedAt = updatedAt ?? TimeService().nowMs();

  Map<String, dynamic> toJson({bool includePoints = true}) {
    return {
      'id': id,
      'color': color,
      'thickness': thickness,
      'is_deleted': isDeleted,
      'deleted_in_session': deletedInSession,
      'updated_at': updatedAt,
      'version': version,
      'creator_id': creatorId,
      'synced_with_cloud': syncedWithCloud ? 1 : 0,
      'is_highlighter': isHighlighter ? 1 : 0, // 🚀
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
      isHighlighter: json['is_highlighter'] == true || json['is_highlighter'] == 1, // 🚀
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
      pageNumber: pageNumber,
      syncedWithCloud: syncedWithCloud,
    );
  }

  Stroke clone() => Stroke.fromJson(toJson());
}
