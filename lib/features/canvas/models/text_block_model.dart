import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class TextBlock {
  final String id;
  String text;
  Offset position;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  String textColorHex;
  double fontSize;

  TextBlock({
    String? id,
    required this.text,
    required this.position,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.textColorHex = '#1A1A24',
    this.fontSize = 18.0,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson() => {
    'id': id,
    'text': text,
    'dx': double.parse(position.dx.toStringAsFixed(1)),
    'dy': double.parse(position.dy.toStringAsFixed(1)),
    'is_bold': isBold,
    'is_italic': isItalic,
    'is_underline': isUnderline,
    'text_color_hex': textColorHex,
    'font_size': fontSize,
  };

  factory TextBlock.fromJson(Map<String, dynamic> json) => TextBlock(
    id: json['id']?.toString(),
    text: json['text']?.toString() ?? '',
    position: Offset(
      (json['dx'] as num?)?.toDouble() ?? 0.0,
      (json['dy'] as num?)?.toDouble() ?? 0.0,
    ),
    isBold: json['is_bold'] ?? json['isBold'] ?? false,
    isItalic: json['is_italic'] ?? json['isItalic'] ?? false,
    isUnderline: json['is_underline'] ?? json['isUnderline'] ?? false,
    textColorHex: json['text_color_hex']?.toString() ?? json['textColorHex']?.toString() ?? '#1A1A24',
    fontSize: (json['font_size'] as num?)?.toDouble() ?? (json['fontSize'] as num?)?.toDouble() ?? 18.0,
  );
}
