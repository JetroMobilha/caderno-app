import 'package:flutter/material.dart';
import 'canvas_enums.dart';

/// Define o estilo visual de uma célula individual.
class TableCellStyle {
  bool bold;
  bool italic;
  bool underline; // 🚀 v5.1
  bool strikethrough; // 🚀 v5.1
  String textColorHex;
  String? backgroundColorHex;
  String? fontFamily; // 🚀 v5.1
  TextAlign textAlign;
  double fontSize;
  int verticalAlign; // 0: top, 1: center, 2: bottom

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

  Map<String, dynamic> toJson() {
    return {
      'bold': bold,
      'italic': italic,
      'underline': underline,
      'strikethrough': strikethrough,
      'text_color': textColorHex,
      'background_color': backgroundColorHex,
      'font_family': fontFamily,
      'text_align': textAlign.index,
      'font_size': fontSize,
      'vertical_align': verticalAlign,
    };
  }

  factory TableCellStyle.fromJson(Map<String, dynamic> json) {
    return TableCellStyle(
      bold: json['bold'] ?? false,
      italic: json['italic'] ?? false,
      underline: json['underline'] ?? false,
      strikethrough: json['strikethrough'] ?? false,
      textColorHex: json['text_color'] ?? '#000000',
      backgroundColorHex: json['background_color'],
      fontFamily: json['font_family'],
      textAlign: TextAlign.values[json['text_align'] ?? 4], // Default center
      fontSize: (json['font_size'] ?? 12.0).toDouble(),
      verticalAlign: json['vertical_align'] ?? 1,
    );
  }

  TableCellStyle clone() {
    return TableCellStyle(
      bold: bold,
      italic: italic,
      underline: underline,
      strikethrough: strikethrough,
      textColorHex: textColorHex,
      backgroundColorHex: backgroundColorHex,
      fontFamily: fontFamily,
      textAlign: textAlign,
      fontSize: fontSize,
      verticalAlign: verticalAlign,
    );
  }
}

/// Modelo de dados de uma célula de tabela.
/// Contém o valor, o tipo (Texto, Checkbox, etc) e o estilo individual.
class TableCellModel {
  String value;
  TableCellType type;
  String? formula;
  TableCellStyle style;

  TableCellModel({
    this.value = '',
    this.type = TableCellType.text,
    this.formula,
    TableCellStyle? style,
  }) : style = style ?? TableCellStyle();

  Map<String, dynamic> toJson() {
    return {
      'value': value,
      'type': type.index,
      'formula': formula,
      'style': style.toJson(),
    };
  }

  factory TableCellModel.fromJson(Map<String, dynamic> json) {
    return TableCellModel(
      value: json['value'] ?? '',
      type: TableCellType.values[json['type'] ?? 0],
      formula: json['formula'],
      style: TableCellStyle.fromJson(json['style'] ?? {}),
    );
  }

  TableCellModel clone() {
    return TableCellModel(
      value: value,
      type: type,
      formula: formula,
      style: style.clone(),
    );
  }
}
