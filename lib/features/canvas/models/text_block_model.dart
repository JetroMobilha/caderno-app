import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'page_object.dart';
import 'canvas_enums.dart'; // 🚀 v3.4

class TextBlock implements PageObject {
  @override
  String id;
  @override
  String get type => 'text';

  String text;
  
  @override
  Offset position;
  
  bool isBold;
  bool isItalic;
  bool isUnderline;
  bool isStrikethrough; // 🚀 v3.4
  String textColorHex;
  String? backgroundColorHex; // 🚀 v3.4
  double fontSize;
  TextAlign textAlign;   // 🚀 v3.4
  String? fontFamily;    // 🚀 v3.4
  double lineHeight;     // 🚀 v3.4
  ListType listType;     // 🚀 v3.4
  double letterSpacing;  // 🚀 v3.7
  double paragraphSpacing; // 🚀 v3.7
  double internalPadding;  // 🚀 v3.7
  
  @override
  bool isDeleted;
  @override
  bool deletedInSession;
  @override
  int updatedAt;
  @override
  int version;
  bool isChecklist; // Legado v3.1, será migrado para listType no futuro
  List<int> checkedLineIndices;
  @override
  int? pageNumber; 
  @override
  final String? creatorId;
  @override
  bool syncedWithCloud;

  @override
  int zIndex;
  @override
  bool isLocked;
  @override
  bool isVisible;
  @override
  double rotation;
  
  @override
  String? layerId;

  TextBlock({
    String? id,
    required this.text,
    required this.position,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.isStrikethrough = false,
    this.textColorHex = '#1A1A24',
    this.backgroundColorHex,
    this.fontSize = 18.0,
    this.textAlign = TextAlign.left,
    this.fontFamily,
    this.lineHeight = 1.2,
    this.listType = ListType.none,
    this.letterSpacing = 0.0,
    this.paragraphSpacing = 0.0,
    this.internalPadding = 4.0,
    this.isDeleted = false,
    this.deletedInSession = false,
    this.isChecklist = false,
    List<int>? checkedLineIndices,
    this.pageNumber, 
    int? updatedAt,
    this.version = 1,
    this.creatorId,
    this.syncedWithCloud = false,
    this.zIndex = 0,
    this.isLocked = false,
    this.isVisible = true,
    this.rotation = 0.0,
    this.layerId,
  }) : id = id ?? const Uuid().v4(),
       checkedLineIndices = checkedLineIndices ?? [],
       updatedAt = updatedAt ?? TimeService().nowMs();

  @override
  Size get size {
    // 🚀 v3.1: Cálculo dinâmico mais preciso para a caixa de texto
    // O TextField no LiveTextEditLayer cuidará da largura máxima (300px por padrão)
    double width = text.length * fontSize * 0.65;
    if (width < 60) width = 60; // Mínimo para seleção
    if (width > 500) width = 500; // Máximo
    
    double height = fontSize * 1.6;
    if (text.contains('\n')) {
      height = (text.split('\n').length) * fontSize * 1.4;
    }
    if (height < 44) height = 44; 
    
    return Size(width, height);
  }

  @override
  set size(Size value) {
    // Redimensionar texto altera o font size proporcionalmente no MVP
    fontSize = value.height / 1.2;
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'text': text,
    'dx': double.parse(position.dx.toStringAsFixed(1)),
    'dy': double.parse(position.dy.toStringAsFixed(1)),
    'is_bold': isBold,
    'is_italic': isItalic,
    'is_underline': isUnderline,
    'is_strikethrough': isStrikethrough, // 🚀 v3.4
    'text_color_hex': textColorHex,
    'background_color_hex': backgroundColorHex, // 🚀 v3.4
    'font_size': fontSize,
    'text_align': textAlign.index, // 🚀 v3.4
    'font_family': fontFamily,      // 🚀 v3.4
    'line_height': lineHeight,      // 🚀 v3.4
    'list_type': listType.name,     // 🚀 v3.4
    'letter_spacing': letterSpacing, // 🚀 v3.7
    'paragraph_spacing': paragraphSpacing, // 🚀 v3.7
    'internal_padding': internalPadding,   // 🚀 v3.7
    'is_deleted': isDeleted,
    'deleted_in_session': deletedInSession,
    'updated_at': updatedAt,
    'version': version,
    'is_checklist': isChecklist,
    'checked_line_indices': checkedLineIndices,
    'page_number': pageNumber,
    'creator_id': creatorId,
    'synced_with_cloud': syncedWithCloud ? 1 : 0,
    'z_index': zIndex,
    'is_locked': isLocked ? 1 : 0,
    'is_visible': isVisible ? 1 : 0,
    'rotation': rotation,
    'layer_id': layerId,
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
    isStrikethrough: json['is_strikethrough'] ?? false, // 🚀 v3.4
    textColorHex: json['text_color_hex']?.toString() ?? json['textColorHex']?.toString() ?? '#1A1A24',
    backgroundColorHex: json['background_color_hex']?.toString(), // 🚀 v3.4
    fontSize: (json['font_size'] as num?)?.toDouble() ?? (json['fontSize'] as num?)?.toDouble() ?? 18.0,
    textAlign: TextAlign.values[(json['text_align'] as int?) ?? 0], // 🚀 v3.4
    fontFamily: json['font_family']?.toString(), // 🚀 v3.4
    lineHeight: (json['line_height'] as num?)?.toDouble() ?? 1.2, // 🚀 v3.4
    listType: ListType.values.firstWhere((e) => e.name == (json['list_type'] ?? 'none'), orElse: () => ListType.none), // 🚀 v3.4
    letterSpacing: (json['letter_spacing'] as num?)?.toDouble() ?? 0.0, // 🚀 v3.7
    paragraphSpacing: (json['paragraph_spacing'] as num?)?.toDouble() ?? 0.0, // 🚀 v3.7
    internalPadding: (json['internal_padding'] as num?)?.toDouble() ?? 4.0, // 🚀 v3.7
    isDeleted: json['is_deleted'] == true || json['is_deleted'] == 1,
    deletedInSession: json['deleted_in_session'] == true || json['deleted_in_session'] == 1,
    isChecklist: json['is_checklist'] == true || json['is_checklist'] == 1,
    checkedLineIndices: (json['checked_line_indices'] as List<dynamic>?)?.map((e) => e as int).toList(),
    pageNumber: json['page_number'] as int?, 
    updatedAt: (json['updated_at'] as num?)?.toInt() ?? (json['updatedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
    version: int.tryParse(json['version']?.toString() ?? '1') ?? 1,
    creatorId: json['creator_id']?.toString(),
    syncedWithCloud: json['synced_with_cloud'] == null ? true : (json['synced_with_cloud'] == true || json['synced_with_cloud'] == 1),
    zIndex: (json['z_index'] as num?)?.toInt() ?? 0,
    isLocked: json['is_locked'] == true || json['is_locked'] == 1,
    isVisible: json['is_visible'] == null ? true : (json['is_visible'] == true || json['is_visible'] == 1),
    rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    layerId: json['layer_id']?.toString(),
  );

  TextBlock clone({String? newId, int? newPageNumber}) {
    return TextBlock(
      id: newId ?? const Uuid().v4(),
      text: text,
      position: position,
      isBold: isBold,
      isItalic: isItalic,
      isUnderline: isUnderline,
      isStrikethrough: isStrikethrough,
      textColorHex: textColorHex,
      backgroundColorHex: backgroundColorHex,
      fontSize: fontSize,
      textAlign: textAlign,
      fontFamily: fontFamily,
      lineHeight: lineHeight,
      listType: listType,
      letterSpacing: letterSpacing,
      paragraphSpacing: paragraphSpacing,
      internalPadding: internalPadding,
      isDeleted: isDeleted,
      deletedInSession: deletedInSession,
      isChecklist: isChecklist,
      checkedLineIndices: List.from(checkedLineIndices),
      pageNumber: newPageNumber ?? pageNumber,
      updatedAt: TimeService().nowMs(),
      version: 1,
      creatorId: creatorId,
      syncedWithCloud: false,
      zIndex: zIndex,
      isLocked: isLocked,
      isVisible: isVisible,
      rotation: rotation,
    );
  }
}
