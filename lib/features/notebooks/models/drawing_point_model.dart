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

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'color': color,
      'thickness': thickness,
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    };
  }

  factory Stroke.fromMap(Map<String, dynamic> map) {
    return Stroke(
      id: map['id']?.toString(),
      color: map['color']?.toString() ?? '#1A1A24',
      thickness: (map['thickness'] as num?)?.toDouble() ?? 3.0,
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

// 🚀 ATUALIZADO: Bloco de Texto com Suporte a Tamanho de Fonte (fontSize)
class TextBlock {
  final String id;
  String text;
  Offset position;

  bool isBold;
  bool isItalic;
  bool isUnderline;
  String textColorHex;
  double fontSize; // 🚀 NOVO CAMPO

  TextBlock({
    String? id,
    required this.text,
    required this.position,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.textColorHex = '#1A1A24',
    this.fontSize = 18.0, // Tamanho padrão
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'dx': position.dx,
    'dy': position.dy,
    'isBold': isBold,
    'isItalic': isItalic,
    'isUnderline': isUnderline,
    'textColorHex': textColorHex,
    'fontSize': fontSize, // 🚀 SALVA O TAMANHO
  };

  factory TextBlock.fromMap(Map<String, dynamic> map) => TextBlock(
    id: map['id']?.toString(),
    text: map['text']?.toString() ?? '',
    position: Offset(
      (map['dx'] as num?)?.toDouble() ?? 0.0,
      (map['dy'] as num?)?.toDouble() ?? 0.0,
    ),
    isBold: map['isBold'] ?? false,
    isItalic: map['isItalic'] ?? false,
    isUnderline: map['isUnderline'] ?? false,
    textColorHex: map['textColorHex']?.toString() ?? '#1A1A24',
    fontSize: (map['fontSize'] as num?)?.toDouble() ?? 18.0, // 🚀 LÊ O TAMANHO (protegido)
  );
}

// 🚀 A FOLHA BLINDADA (Compatível com esquemas velhos e novos)
class LocalPage {
  final bool isLandscape;
  List<Stroke> strokes;
  List<Stroke> undoHistory = [];
  List<Stroke> redoHistory = [];

  String title;
  String footer;
  List<TextBlock> textBlocks;

  late TransformationController transformationController;

  LocalPage({
    required this.isLandscape,
    List<Stroke>? strokes,
    this.title = '',
    this.footer = '',
    List<TextBlock>? textBlocks,
  })  : strokes = strokes ?? <Stroke>[],
        textBlocks = textBlocks ?? <TextBlock>[] { // O <TextBlock>[] previne injeções dinâmicas
    transformationController = TransformationController();
  }

  void dispose() {
    transformationController.dispose();
  }

  Map<String, dynamic> toMap() {
    return {
      'isLandscape': isLandscape,
      'title': title,
      'footer': footer,
      'strokes': strokes.map((s) => s.toMap()).toList(),
      'textBlocks': textBlocks.map((t) => t.toMap()).toList(),
    };
  }

  factory LocalPage.fromMap(Map<String, dynamic> map) {
    return LocalPage(
      isLandscape: map['isLandscape'] ?? false,
      title: map['title']?.toString() ?? '',
      footer: map['footer']?.toString() ?? '',
      // 🚀 Defesas ativas: List.from obriga o Dart a respeitar o Tipo, falhando graciosamente com vazios
      strokes: map['strokes'] != null
          ? List<Stroke>.from((map['strokes'] as List).map((s) => Stroke.fromMap(s as Map<String, dynamic>)))
          : <Stroke>[],
      textBlocks: map['textBlocks'] != null
          ? List<TextBlock>.from((map['textBlocks'] as List).map((t) => TextBlock.fromMap(t as Map<String, dynamic>)))
          : <TextBlock>[],
    );
  }
}