import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Stroke {
  final String id; 
  String color;
  double thickness;
  List<Offset> points;
  bool isDeleted; 
  bool deletedInSession; 
  int updatedAt; 
  final int? pageNumber; 

  Stroke({
    String? id,
    required this.color,
    required this.thickness,
    required this.points,
    this.isDeleted = false,
    this.deletedInSession = false,
    int? updatedAt,
    this.pageNumber,
  }) : id = id ?? const Uuid().v4(),
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  // =========================================================================
  // ☁️ COMUNICAÇÃO (JSON / Laravel / Drift)
  // =========================================================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'color': color,
      'thickness': thickness,
      'is_deleted': isDeleted,
      'deleted_in_session': deletedInSession,
      'updated_at': updatedAt,
      if (pageNumber != null) 'page_number': pageNumber,
      'points': points.map((p) => {
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
      pageNumber: json['page_number'] as int?,
      points: json['points'] != null
          ? (json['points'] as List)
          .map((p) => Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()))
          .toList()
          : <Offset>[],
    );
  }

  String toJsonString() => jsonEncode(toJson());
  factory Stroke.fromJsonString(String jsonStr) => Stroke.fromJson(jsonDecode(jsonStr));

  Stroke clone() => Stroke.fromJson(toJson());
}
