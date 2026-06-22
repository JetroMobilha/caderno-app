import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class Stroke {
  final String id;
  final String color;
  final double thickness;
  final List<Offset> points;

  Stroke({
    String? id,
    required this.color,
    required this.thickness,
    required this.points,
  }) : id = id ?? const Uuid().v4();

  // 🚀 RESTAURADO: Para compatibilidade com page_model.dart e testes antigos
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'color': color,
      'thickness': thickness,
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    };
  }

  // 🚀 RESTAURADO: Construtor a partir de Map
  factory Stroke.fromMap(Map<String, dynamic> map) {
    return Stroke(
      id: map['id'] as String?,
      color: map['color'] as String,
      thickness: (map['thickness'] as num).toDouble(),
      points: (map['points'] as List)
          .map((p) => Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()))
          .toList(),
    );
  }

  // Atalhos para JSON string exigidos pelo SQLite
  String toJsonString() => jsonEncode(toMap());
  factory Stroke.fromJsonString(String jsonStr) => Stroke.fromMap(jsonDecode(jsonStr));
}

class LocalPage {
  final bool isLandscape;
  List<Stroke> strokes;
  List<Stroke> undoHistory = [];
  List<Stroke> redoHistory = [];

  late TransformationController transformationController;

  LocalPage({
    required this.isLandscape,
    List<Stroke>? strokes,
  }) : strokes = strokes ?? [] {
    transformationController = TransformationController();
  }

  void dispose() {
    transformationController.dispose();
  }

  Map<String, dynamic> toMap() {
    return {
      'isLandscape': isLandscape,
      'strokes': strokes.map((s) => s.toMap()).toList(),
    };
  }

  factory LocalPage.fromMap(Map<String, dynamic> map) {
    return LocalPage(
      isLandscape: map['isLandscape'] ?? false,
      strokes: (map['strokes'] as List).map((s) => Stroke.fromMap(s)).toList(),
    );
  }
}