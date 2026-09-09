import 'dart:convert';
import 'package:flutter/foundation.dart'; // 🚀 v9.7
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'package:vector_math/vector_math_64.dart';

import 'image_block_model.dart';
import 'stroke_model.dart';
import 'text_block_model.dart';
import 'shape_model.dart'; 
import 'audio_block_model.dart'; 
import 'animation_object_model.dart'; 
import 'table_model.dart';
import 'link_model.dart';
import 'attachment_model.dart';
import 'page_object.dart';
import '../../notebooks/models/notebook_configuration.dart';

/// 🚀 v9.0: Definição de Camada Imutável.
class LayerDefinition {
  final String id;
  final String name;
  final bool isVisible;
  final bool isLocked;

  LayerDefinition({
    required this.id,
    required this.name,
    this.isVisible = true,
    this.isLocked = false,
  });

  Map<String, dynamic> toJson() => {'id': id, 'name': name, 'is_visible': isVisible, 'is_locked': isLocked};
  factory LayerDefinition.fromJson(Map<String, dynamic> json) => LayerDefinition(
    id: json['id'],
    name: json['name'],
    isVisible: json['is_visible'] ?? true,
    isLocked: json['is_locked'] ?? false,
  );

  LayerDefinition copyWith({
    String? name,
    bool? isVisible,
    bool? isLocked,
  }) {
    return LayerDefinition(
      id: id,
      name: name ?? this.name,
      isVisible: isVisible ?? this.isVisible,
      isLocked: isLocked ?? this.isLocked,
    );
  }

  LayerDefinition clone() => copyWith();
}

/// 🚀 v9.2: Modelo de Página Imutável Refatorado.
class LocalPage {
  final int? id;
  final int? serverId;
  final String clientId;
  final int notebookId;
  final int pageNumber;
  final bool isLandscape;
  final String paperSize;
  final String? lineType;
  final double? lineSpacing;
  final bool isFrozen; 
  final bool isFavorite; 
  final bool isDeleted;
  final bool isTearing;
  final bool isContentLoaded;
  final bool isInfinite;

  final String title;
  final String? sectionTitle; 
  final String? sectionColor; 
  final String footer;
  final String? extractedText;
  final BackgroundConfig? backgroundConfig; 
  final Matrix4? viewportMatrix; 
  final List<LayerDefinition> layers;

  final List<PageObject> objects;

  List<Stroke> get strokes => objects.whereType<Stroke>().toList();
  List<TextBlock> get textBlocks => objects.whereType<TextBlock>().toList();
  List<ImageBlock> get imageBlocks => objects.whereType<ImageBlock>().toList();
  List<ShapeObject> get shapes => objects.whereType<ShapeObject>().toList();
  List<AudioBlock> get audios => objects.whereType<AudioBlock>().toList();
  List<AnimationObject> get animations => objects.whereType<AnimationObject>().toList();
  List<TableObject> get tables => objects.whereType<TableObject>().toList();
  List<LinkObject> get links => objects.whereType<LinkObject>().toList();
  List<AttachmentObject> get attachments => objects.whereType<AttachmentObject>().toList();

  final List<Stroke> redoHistory;

  final int syncedWithCloud;
  final int updatedAt;
  final int version;

  bool get hasData => objects.any((o) => !o.isDeleted);

  LocalPage({
    this.id,
    this.serverId,
    String? clientId,
    required this.notebookId,
    required this.pageNumber,
    required this.isLandscape,
    this.paperSize = 'A4',
    this.lineType,
    this.lineSpacing,
    this.isFrozen = false,
    this.isFavorite = false,
    this.isDeleted = false,
    this.isInfinite = false,
    this.isTearing = false,
    this.isContentLoaded = false,
    this.title = '',
    this.sectionTitle, 
    this.sectionColor, 
    this.footer = '',
    this.extractedText,
    List<PageObject>? objects,
    this.backgroundConfig,
    this.viewportMatrix,
    List<LayerDefinition>? layers,
    List<Stroke>? redoHistory,
    this.syncedWithCloud = 0,
    int? updatedAt,
    this.version = 1,
  })  : clientId = clientId ?? const Uuid().v4(),
       objects = List.unmodifiable(objects ?? <PageObject>[]),
       layers = List.unmodifiable(layers ?? [
         LayerDefinition(id: 'default', name: 'Geral'),
         LayerDefinition(id: 'background', name: 'Fundo'),
         LayerDefinition(id: 'drawings', name: 'Desenhos'),
         LayerDefinition(id: 'text', name: 'Texto'),
       ]),
       redoHistory = List.unmodifiable(redoHistory ?? []),
       updatedAt = updatedAt ?? TimeService().nowMs();

  NotebookConfiguration get toConfig => NotebookConfiguration(
    page: PageConfig(
      width: isInfinite ? 1000 : (isLandscape ? _getPaperDimsRaw(paperSize)['h']! : _getPaperDimsRaw(paperSize)['w']!),
      height: isInfinite ? 1000 : (isLandscape ? _getPaperDimsRaw(paperSize)['w']! : _getPaperDimsRaw(paperSize)['h']!),
      orientation: isLandscape ? 'landscape' : 'portrait',
      isInfinite: isInfinite, 
      paperSize: paperSize,
    ),
    background: backgroundConfig ?? BackgroundConfig(
      type: lineType ?? 'blank', 
      spacing: lineSpacing ?? 8.0,
      color: '#CCCCCC',
      opacity: 0.7,
      lineWidth: 0.3
    ),
    margins: MarginsConfig(top: 20, right: 20, bottom: 20, left: 20), 
    header: HeaderFooterConfig(enabled: title.isNotEmpty, fields: title.isNotEmpty ? [title] : []),
    footer: HeaderFooterConfig(enabled: footer.isNotEmpty, fields: footer.isNotEmpty ? [footer] : []),
    numbering: NumberingConfig(enabled: true),
  );

  double get pageWidthPx {
    if (isInfinite) return 5000.0;
    final dims = _getPaperDimsPx(paperSize);
    return isLandscape ? dims['h']! : dims['w']!;
  }

  double get pageHeightPx {
    if (isInfinite) return 5000.0;
    final dims = _getPaperDimsPx(paperSize);
    return isLandscape ? dims['w']! : dims['h']!;
  }

  static Map<String, double> _getPaperDimsRaw(String size) {
    switch (size) {
      case 'A0': return {'w': 841, 'h': 1189};
      case 'A1': return {'w': 594, 'h': 841};
      case 'A2': return {'w': 420, 'h': 594};
      case 'A3': return {'w': 297, 'h': 420};
      case 'A5': return {'w': 148, 'h': 210};
      default: return {'w': 210, 'h': 297};
    }
  }

  static Map<String, double> _getPaperDimsPx(String size) {
    final raw = _getPaperDimsRaw(size);
    return {'w': raw['w']! * 3.78, 'h': raw['h']! * 3.78};
  }

  LocalPage copyWith({
    int? id,
    int? serverId,
    String? clientId,
    int? notebookId,
    int? pageNumber,
    bool? isLandscape,
    String? paperSize,
    String? lineType,
    double? lineSpacing,
    bool? isFrozen,
    bool? isFavorite,
    bool? isDeleted,
    bool? isInfinite,
    bool? isTearing,
    bool? isContentLoaded,
    String? title,
    String? sectionTitle,
    String? sectionColor,
    bool clearSection = false, 
    String? footer,
    String? extractedText,
    List<PageObject>? objects,
    List<LayerDefinition>? layers,
    List<Stroke>? redoHistory,
    BackgroundConfig? backgroundConfig,
    Matrix4? viewportMatrix,
    int? syncedWithCloud,
    int? updatedAt,
    int? version,
  }) {
    return LocalPage(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      clientId: clientId ?? this.clientId,
      notebookId: notebookId ?? this.notebookId,
      pageNumber: pageNumber ?? this.pageNumber,
      isLandscape: isLandscape ?? this.isLandscape,
      paperSize: paperSize ?? this.paperSize,
      lineType: lineType ?? this.lineType,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      isFrozen: isFrozen ?? this.isFrozen,
      isFavorite: isFavorite ?? this.isFavorite,
      isDeleted: isDeleted ?? this.isDeleted,
      isInfinite: isInfinite ?? this.isInfinite,
      isTearing: isTearing ?? this.isTearing,
      isContentLoaded: isContentLoaded ?? this.isContentLoaded,
      title: title ?? this.title,
      sectionTitle: clearSection ? null : (sectionTitle ?? this.sectionTitle),
      sectionColor: clearSection ? null : (sectionColor ?? this.sectionColor),
      footer: footer ?? this.footer,
      extractedText: extractedText ?? this.extractedText,
      objects: objects ?? this.objects,
      layers: layers ?? this.layers,
      redoHistory: redoHistory ?? this.redoHistory,
      backgroundConfig: backgroundConfig ?? this.backgroundConfig,
      viewportMatrix: viewportMatrix ?? this.viewportMatrix,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? TimeService().nowMs(),
      version: version ?? (this.version + 1),
    );
  }

  LocalPage clone({String? newClientId, int? newNotebookId, int? newPageNumber}) {
    final int pNum = newPageNumber ?? pageNumber;
    return copyWith(
      id: null,
      serverId: null,
      clientId: newClientId ?? const Uuid().v4(),
      notebookId: newNotebookId ?? notebookId,
      pageNumber: pNum,
      objects: objects.map((obj) => obj.clone(newPageNumber: pNum)).toList(),
      layers: layers.map((l) => l.clone()).toList(),
      syncedWithCloud: 0,
      updatedAt: TimeService().nowMs(),
      version: 1,
    );
  }

  String generateFingerprint() {
    final List<String> components = [];
    final activeObjects = objects.where((o) => !o.isDeleted).toList()..sort((a, b) => a.id.compareTo(b.id));
    for (var o in activeObjects) components.add('${o.type}:${o.id}:${o.updatedAt}');
    components.add('f:${isFrozen ? 1 : 0}');
    components.add('fav:${isFavorite ? 1 : 0}');
    components.add('ps:$paperSize');
    components.add('inf:${isInfinite ? 1 : 0}');
    if (sectionTitle != null) components.add('sc:$sectionTitle:$sectionColor');
    return components.join('|');
  }

  Map<String, dynamic> toJson() {
    return {
      if (serverId != null) 'id': serverId,
      'client_id': clientId,
      'notebook_id': notebookId,
      'page_number': pageNumber,
      'is_landscape': isLandscape,
      'paper_size': paperSize,
      'line_type': lineType,
      'line_spacing': lineSpacing,
      'is_frozen': isFrozen ? 1 : 0,
      'is_favorite': isFavorite ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'is_infinite': isInfinite ? 1 : 0,
      'synced_with_cloud': syncedWithCloud,
      'header_data': {'title': title, 'section': sectionTitle, 'section_color': sectionColor},
      'footer_data': {'title': footer},
      'extracted_text': extractedText,
      'objects_data': objects.map((o) => o.toJson()).toList(),
      'layers': layers.map((l) => l.toJson()).toList(),
      'background_config': backgroundConfig?.toJson(),
      'viewport_matrix': viewportMatrix != null ? viewportMatrix!.storage.toList() : null,
      'updated_at': updatedAt,
      'version': version,
    };
  }

  Future<Map<String, dynamic>> toJsonAsync() async {
    final List<Map<String, dynamic>> asyncObjects = [];
    for (var obj in objects) {
      if (obj is ImageBlock) asyncObjects.add(await obj.toJsonAsync());
      else asyncObjects.add(obj.toJson());
    }
    final map = toJson();
    map['objects_data'] = asyncObjects;
    return map;
  }

  factory LocalPage.fromJson(Map<String, dynamic> json) {
    final List<PageObject> objs = [];
    if (json['objects_data'] != null) {
      for (var item in json['objects_data']) {
        final type = item['type'];
        if (type == 'stroke') objs.add(Stroke.fromJson(item));
        else if (type == 'text') objs.add(TextBlock.fromJson(item));
        else if (type == 'image') objs.add(ImageBlock.fromJson(item));
        else if (type == 'shape') objs.add(ShapeObject.fromJson(item));
        else if (type == 'audio') objs.add(AudioBlock.fromJson(item));
        else if (type == 'animation') objs.add(AnimationObject.fromJson(item));
        else if (type == 'table') objs.add(TableObject.fromJson(item));
        else if (type == 'link') objs.add(LinkObject.fromJson(item));
        else if (type == 'attachment') objs.add(AttachmentObject.fromJson(item));
      }
    }
    return LocalPage(
      serverId: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      clientId: json['client_id']?.toString(),
      notebookId: int.tryParse(json['notebook_id']?.toString() ?? '0') ?? 0,
      pageNumber: int.tryParse(json['page_number']?.toString() ?? '0') ?? 0,
      isLandscape: json['is_landscape'] == true || json['is_landscape'] == 1,
      paperSize: json['paper_size']?.toString() ?? 'A4',
      lineType: json['line_type']?.toString(),
      lineSpacing: json['line_spacing'] != null ? double.tryParse(json['line_spacing'].toString()) : null,
      isFrozen: json['is_frozen'] == true || json['is_frozen'] == 1,
      isFavorite: json['is_favorite'] == true || json['is_favorite'] == 1,
      isDeleted: json['is_deleted'] == true || json['is_deleted'] == 1,
      isInfinite: json['is_infinite'] == true || json['is_infinite'] == 1,
      title: LocalPage.parseMeta(json['header_data']),
      sectionTitle: LocalPage.parseSection(json['header_data']),
      sectionColor: LocalPage.parseSectionColor(json['header_data']),
      footer: LocalPage.parseMeta(json['footer_data']),
      extractedText: json['extracted_text']?.toString(),
      objects: objs,
      layers: json['layers'] != null ? (json['layers'] as List).map((l) => LayerDefinition.fromJson(l)).toList() : null,
      backgroundConfig: json['background_config'] != null ? BackgroundConfig.fromJson(json['background_config']) : null,
      viewportMatrix: json['viewport_matrix'] != null ? Matrix4.fromList(List<double>.from(json['viewport_matrix'])) : null,
      syncedWithCloud: json['synced_with_cloud'] ?? 0,
      updatedAt: (json['updated_at_ms'] ?? json['updated_at']) as int?,
      version: int.tryParse(json['version']?.toString() ?? '1') ?? 1,
    );
  }

  static String parseMeta(dynamic data) {
    if (data == null) return '';
    if (data is Map) return data['title']?.toString() ?? '';
    return '';
  }
  static String? parseSection(dynamic data) { if (data is Map) return data['section']?.toString(); return null; }
  static String? parseSectionColor(dynamic data) { if (data is Map) return data['section_color']?.toString(); return null; }
}
