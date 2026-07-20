import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class Stroke {
  final String id; // 🚀 Gerado localmente com UUID
  final String color;
  final double thickness;
  final List<Offset> points;
  final bool isDeleted; // Para suporte ao Undo/Redo e Borracha
  final int? pageNumber; // 📄 Opcional: Para isolamento em colaboração

  Stroke({
    String? id,
    required this.color,
    required this.thickness,
    required this.points,
    this.isDeleted = false,
    this.pageNumber,
  }) : id = id ?? const Uuid().v4();

  // =========================================================================
  // ☁️ COMUNICAÇÃO COM A NUVEM (JSON / Laravel)
  // =========================================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'color': color,
      'thickness': thickness,
      'is_deleted': isDeleted,
      if (pageNumber != null) 'page_number': pageNumber,
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    };
  }

  factory Stroke.fromMap(Map<String, dynamic> map) {
    return Stroke(
      id: map['id']?.toString(),
      color: map['color']?.toString() ?? '#1A1A24',
      thickness: (map['thickness'] as num?)?.toDouble() ?? 3.0,
      isDeleted: map['is_deleted'] == true || map['is_deleted'] == 1,
      pageNumber: map['page_number'] as int?,
      points: map['points'] != null
          ? (map['points'] as List)
          .map((p) => Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()))
          .toList()
          : <Offset>[],
    );
  }

  String toJsonString() => jsonEncode(toMap());
  factory Stroke.fromJsonString(String jsonStr) => Stroke.fromMap(jsonDecode(jsonStr));
}
