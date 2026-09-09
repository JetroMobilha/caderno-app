import 'package:flutter/material.dart';
import 'canvas_enums.dart';

/// 🚀 v9.0: Estilo de Célula Imutável.
class TableCellStyle {
  final bool bold;
  final bool italic;
  final bool underline;
  final bool strikethrough;
  final String textColorHex;
  final String? backgroundColorHex;
  final String? fontFamily;
  final TextAlign textAlign;
  final double fontSize;
  final int verticalAlign;

  TableCellStyle({
    this.bold = false,
    this.italic = false,
    this.underline = false,
    this.strikethrough = false,
    this.textColorHex = '#000000',
    this.backgroundColorHex,
    this.fontFamily,
    this.textAlign = TextAlign.center,
    this.fontSize = 12.0,
    this.verticalAlign = 1,
  });

  TableCellStyle copyWith({
    bool? bold,
    bool? italic,
    bool? underline,
    bool? strikethrough,
    String? textColorHex,
    String? backgroundColorHex,
    String? fontFamily,
    TextAlign? textAlign,
    double? fontSize,
    int? verticalAlign,
  }) {
    return TableCellStyle(
      bold: bold ?? this.bold,
      italic: italic ?? this.italic,
      underline: underline ?? this.underline,
      strikethrough: strikethrough ?? this.strikethrough,
      textColorHex: textColorHex ?? this.textColorHex,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      fontFamily: fontFamily ?? this.fontFamily,
      textAlign: textAlign ?? this.textAlign,
      fontSize: fontSize ?? this.fontSize,
      verticalAlign: verticalAlign ?? this.verticalAlign,
    );
  }

  Map<String, dynamic> toJson() => {
    'bold': bold, 'italic': italic, 'underline': underline, 'strikethrough': strikethrough,
    'text_color': textColorHex, 'background_color': backgroundColorHex,
    'font_family': fontFamily, 'text_align': textAlign.index,
    'font_size': fontSize, 'vertical_align': verticalAlign,
  };

  factory TableCellStyle.fromJson(Map<String, dynamic> json) => TableCellStyle(
    bold: json['bold'] ?? false, italic: json['italic'] ?? false,
    underline: json['underline'] ?? false, strikethrough: json['strikethrough'] ?? false,
    textColorHex: json['text_color'] ?? '#000000', backgroundColorHex: json['background_color'],
    fontFamily: json['font_family'], textAlign: TextAlign.values[json['text_align'] ?? 4],
    fontSize: (json['font_size'] ?? 12.0).toDouble(), verticalAlign: json['vertical_align'] ?? 1,
  );

  TableCellStyle clone() => copyWith();
}

/// 🚀 v9.0: Modelo de Célula Imutável.
class TableCellModel {
  final String value;
  final TableCellType type;
  final String? formula;
  final TableCellStyle style;

  TableCellModel({
    this.value = '',
    this.type = TableCellType.text,
    this.formula,
    TableCellStyle? style,
  }) : style = style ?? TableCellStyle();

  TableCellModel copyWith({
    String? value,
    TableCellType? type,
    String? formula,
    TableCellStyle? style,
  }) {
    return TableCellModel(
      value: value ?? this.value,
      type: type ?? this.type,
      formula: formula ?? this.formula,
      style: style ?? this.style,
    );
  }

  Map<String, dynamic> toJson() => {
    'value': value, 'type': type.index, 'formula': formula, 'style': style.toJson(),
  };

  factory TableCellModel.fromJson(Map<String, dynamic> json) => TableCellModel(
    value: json['value'] ?? '',
    type: TableCellType.values[json['type'] ?? 0],
    formula: json['formula'],
    style: TableCellStyle.fromJson(json['style'] ?? {}),
  );

  TableCellModel clone() => copyWith(style: style.clone());
}
