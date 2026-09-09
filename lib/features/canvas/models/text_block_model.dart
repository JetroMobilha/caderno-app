import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'page_object.dart';
import 'canvas_enums.dart';

/// 🚀 v10.0: Implementação Imutável de Bloco de Texto.
class TextBlock implements PageObject {
  @override
  final String id;
  @override
  String get type => 'text';
  @override
  final String? parentId; // 🚀 v10

  final String text;
  
  @override
  final Offset position;
  
  final bool isBold;
  final bool isItalic;
  final bool isUnderline;
  final bool isStrikethrough;
  final String textColorHex;
  final String? backgroundColorHex;
  final double fontSize;
  final TextAlign textAlign;
  final String? fontFamily;
  final double lineHeight;
  final ListType listType;
  final double letterSpacing;
  final double paragraphSpacing;
  final double internalPadding;
  
  @override
  final bool isDeleted;
  @override
  final bool deletedInSession;
  @override
  final int updatedAt;
  @override
  final int version;
  
  final bool isChecklist;
  final List<int> checkedLineIndices;
  
  @override
  final int? pageNumber; 
  @override
  final String? creatorId;
  @override
  final bool syncedWithCloud;

  @override
  final int zIndex;
  @override
  final bool isLocked;
  @override
  final bool isVisible;
  @override
  final double opacity; // 🚀 v10
  @override
  final double rotation;
  
  @override
  final String? layerId;

  TextBlock({
    String? id,
    this.parentId,
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
    this.opacity = 1.0,
    this.rotation = 0.0,
    this.layerId,
  }) : id = id ?? const Uuid().v4(),
       checkedLineIndices = List.unmodifiable(checkedLineIndices ?? []),
       updatedAt = updatedAt ?? TimeService().nowMs();

  @override
  Size get size {
    double width = text.length * fontSize * 0.65;
    if (width < 60) width = 60;
    if (width > 500) width = 500;
    
    double height = fontSize * 1.6;
    if (text.contains('\n')) {
      height = (text.split('\n').length) * fontSize * 1.4;
    }
    if (height < 44) height = 44; 
    
    return Size(width, height);
  }

  @override
  TextBlock copyWith({
    String? id,
    String? parentId,
    String? text,
    Offset? position,
    Size? size, 
    double? rotation,
    int? zIndex,
    bool? isLocked,
    bool? isVisible,
    double? opacity,
    int? updatedAt,
    int? version,
    bool? isDeleted,
    bool? syncedWithCloud,
    bool? deletedInSession,
    int? pageNumber,
    String? creatorId,
    String? layerId,
    bool? isBold,
    bool? isItalic,
    bool? isUnderline,
    bool? isStrikethrough,
    String? textColorHex,
    String? backgroundColorHex,
    double? fontSize,
    TextAlign? textAlign,
    String? fontFamily,
    double? lineHeight,
    ListType? listType,
    double? letterSpacing,
    double? paragraphSpacing,
    double? internalPadding,
    List<int>? checkedLineIndices,
  }) {
    double finalFontSize = fontSize ?? this.fontSize;
    if (size != null) finalFontSize = size.height / 1.2;

    return TextBlock(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      text: text ?? this.text,
      position: position ?? this.position,
      isBold: isBold ?? this.isBold,
      isItalic: isItalic ?? this.isItalic,
      isUnderline: isUnderline ?? this.isUnderline,
      isStrikethrough: isStrikethrough ?? this.isStrikethrough,
      textColorHex: textColorHex ?? this.textColorHex,
      backgroundColorHex: backgroundColorHex ?? this.backgroundColorHex,
      fontSize: finalFontSize,
      textAlign: textAlign ?? this.textAlign,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      listType: listType ?? this.listType,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      internalPadding: internalPadding ?? this.internalPadding,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedInSession: deletedInSession ?? this.deletedInSession,
      isChecklist: isChecklist,
      checkedLineIndices: checkedLineIndices ?? this.checkedLineIndices,
      pageNumber: pageNumber ?? this.pageNumber,
      updatedAt: updatedAt ?? TimeService().nowMs(),
      version: version ?? (this.version + 1),
      creatorId: creatorId ?? this.creatorId,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      zIndex: zIndex ?? this.zIndex,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
      rotation: rotation ?? this.rotation,
      layerId: layerId ?? this.layerId,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type,
    'parent_id': parentId,
    'text': text,
    'dx': double.parse(position.dx.toStringAsFixed(3)),
    'dy': double.parse(position.dy.toStringAsFixed(3)),
    'is_bold': isBold,
    'is_italic': isItalic,
    'is_underline': isUnderline,
    'is_strikethrough': isStrikethrough,
    'text_color_hex': textColorHex,
    'background_color_hex': backgroundColorHex,
    'font_size': double.parse(fontSize.toStringAsFixed(2)),
    'text_align': textAlign.index,
    'font_family': fontFamily,
    'line_height': lineHeight,
    'list_type': listType.name,
    'letter_spacing': letterSpacing,
    'paragraph_spacing': paragraphSpacing,
    'internal_padding': internalPadding,
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
    'opacity': opacity,
    'rotation': rotation,
    'layer_id': layerId,
  };

  factory TextBlock.fromJson(Map<String, dynamic> json) => TextBlock(
    id: json['id']?.toString(),
    parentId: json['parent_id']?.toString(),
    text: json['text']?.toString() ?? '',
    position: Offset((json['dx'] as num?)?.toDouble() ?? 0.0, (json['dy'] as num?)?.toDouble() ?? 0.0),
    isBold: json['is_bold'] ?? json['isBold'] ?? false,
    isItalic: json['is_italic'] ?? json['isItalic'] ?? false,
    isUnderline: json['is_underline'] ?? json['isUnderline'] ?? false,
    isStrikethrough: json['is_strikethrough'] ?? false,
    textColorHex: json['text_color_hex']?.toString() ?? json['textColorHex']?.toString() ?? '#1A1A24',
    backgroundColorHex: json['background_color_hex']?.toString(),
    fontSize: (json['font_size'] as num?)?.toDouble() ?? (json['fontSize'] as num?)?.toDouble() ?? 18.0,
    textAlign: TextAlign.values[(json['text_align'] as int?) ?? 0],
    fontFamily: json['font_family']?.toString(),
    lineHeight: (json['line_height'] as num?)?.toDouble() ?? 1.2,
    listType: ListType.values.firstWhere((e) => e.name == (json['list_type'] ?? 'none'), orElse: () => ListType.none),
    letterSpacing: (json['letter_spacing'] as num?)?.toDouble() ?? 0.0,
    paragraphSpacing: (json['paragraph_spacing'] as num?)?.toDouble() ?? 0.0,
    internalPadding: (json['internal_padding'] as num?)?.toDouble() ?? 4.0,
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
    opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
    layerId: json['layer_id']?.toString(),
  );

  @override
  TextBlock clone({String? newId, int? newPageNumber}) {
    return copyWith(
      id: newId ?? const Uuid().v4(),
      pageNumber: newPageNumber ?? pageNumber,
      updatedAt: TimeService().nowMs(),
      version: 1,
      syncedWithCloud: false,
    );
  }
}
