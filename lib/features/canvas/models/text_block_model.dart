import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

class TextBlock {
  String id;
  String text;
  Offset position;
  bool isBold;
  bool isItalic;
  bool isUnderline;
  String textColorHex;
  double fontSize;
  bool isDeleted;
  bool deletedInSession;
  int updatedAt;
  int version;
  bool isChecklist;
  List<int> checkedLineIndices;
  final int? pageNumber; // 🚀 Adicionado para contexto de página
  final String? creatorId;
  bool syncedWithCloud;

  TextBlock({
    String? id,
    required this.text,
    required this.position,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.textColorHex = '#1A1A24',
    this.fontSize = 18.0,
    this.isDeleted = false,
    this.deletedInSession = false,
    this.isChecklist = false,
    List<int>? checkedLineIndices,
    this.pageNumber, // 🚀
    int? updatedAt,
    this.version = 1,
    this.creatorId,
    this.syncedWithCloud = false,
  }) : id = id ?? const Uuid().v4(),
       checkedLineIndices = checkedLineIndices ?? [],
       updatedAt = updatedAt ?? TimeService().nowMs();

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
    'is_deleted': isDeleted,
    'deleted_in_session': deletedInSession,
    'updated_at': updatedAt,
    'is_checklist': isChecklist,
    'checked_line_indices': checkedLineIndices,
    'page_number': pageNumber, // 🚀
    'creator_id': creatorId,
    'synced_with_cloud': syncedWithCloud ? 1 : 0,
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
    isDeleted: json['is_deleted'] == true || json['is_deleted'] == 1,
    deletedInSession: json['deleted_in_session'] == true || json['deleted_in_session'] == 1,
    isChecklist: json['is_checklist'] == true || json['is_checklist'] == 1,
    checkedLineIndices: (json['checked_line_indices'] as List<dynamic>?)?.map((e) => e as int).toList(),
    pageNumber: json['page_number'] as int?, // 🚀
    updatedAt: (json['updated_at'] as num?)?.toInt() ?? (json['updatedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    version: int.tryParse(json['version']?.toString() ?? '1') ?? 1,
    creatorId: json['creator_id']?.toString(),
    syncedWithCloud: json['synced_with_cloud'] == null ? true : (json['synced_with_cloud'] == true || json['synced_with_cloud'] == 1),
  );

  TextBlock clone({String? newId, int? newPageNumber}) {
    return TextBlock(
      id: newId ?? const Uuid().v4(),
      text: text,
      position: position,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      textColorHex: textColorHex,
      fontSize: fontSize,
      isDeleted: isDeleted,
      deletedInSession: deletedInSession,
      isChecklist: isChecklist,
      checkedLineIndices: List.from(checkedLineIndices),
      pageNumber: newPageNumber ?? pageNumber,
      updatedAt: TimeService().nowMs(),
      version: 1,
      creatorId: creatorId,
      syncedWithCloud: false,
    );
  }
}
