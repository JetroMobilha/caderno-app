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

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'dx': position.dx,
    'dy': position.dy,
    'isBold': isBold,
    'isItalic': isItalic,
    'isUnderline': isUnderline,
    'textColorHex': textColorHex,
    'fontSize': fontSize,
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
    fontSize: (map['fontSize'] as num?)?.toDouble() ?? 18.0,
  );
}