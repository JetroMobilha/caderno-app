import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'image_block_model.dart';
import 'stroke_model.dart';
import 'text_block_model.dart';
import 'page_object.dart';
import '../../notebooks/models/notebook_configuration.dart';

class LocalPage {
  int? id;
  int? serverId;
  final String clientId;
  final int notebookId;
  final int pageNumber;
  final bool isLandscape;
  final String paperSize;
  String? lineType;
  double? lineSpacing;
  bool isFrozen; 
  bool isFavorite; 
  bool isDeleted;
  bool isTearing = false;
  bool isContentLoaded = false;
  bool isInfinite;

  String title;
  String? sectionTitle; 
  String? sectionColor; 
  String footer;
  String? extractedText;
  BackgroundConfig? backgroundConfig; 

  // 🚀 LISTA UNIFICADA DE OBJETOS
  List<PageObject> objects;

  // 🔄 Mapeadores para retrocompatibilidade
  List<Stroke> get strokes => objects.whereType<Stroke>().toList();
  List<TextBlock> get textBlocks => objects.whereType<TextBlock>().toList();
  List<ImageBlock> get imageBlocks => objects.whereType<ImageBlock>().toList();

  List<Stroke> redoHistory;

  int syncedWithCloud;
  int updatedAt;
  int version;

  /// 🚀 Verifica se a página possui conteúdo visível (não apagado)
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
    this.title = '',
    this.sectionTitle, 
    this.sectionColor, 
    this.footer = '',
    this.extractedText,
    List<PageObject>? objects,
    this.backgroundConfig,
    this.syncedWithCloud = 0,
    int? updatedAt,
    this.version = 1,
  })  : clientId = clientId ?? const Uuid().v4(),
       objects = objects ?? <PageObject>[],
       redoHistory = [],
       updatedAt = updatedAt ?? TimeService().nowMs();

  // 🚀 UNIDADES PADRONIZADAS: toConfig deve retornar dimensões em MM
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

  // 🚀 DIMENSÕES PARA RENDERIZAÇÃO (PIXELS)
  double get pageWidthPx => isInfinite ? 5000 : (isLandscape ? _getPaperDimsPx(paperSize)['h']! : _getPaperDimsPx(paperSize)['w']!);
  double get pageHeightPx => isInfinite ? 5000 : (isLandscape ? _getPaperDimsPx(paperSize)['w']! : _getPaperDimsPx(paperSize)['h']!);

  static Map<String, double> _getPaperDimsRaw(String size) {
    switch (size) {
      case 'A0': return {'w': 841, 'h': 1189};
      case 'A1': return {'w': 594, 'h': 841};
      case 'A2': return {'w': 420, 'h': 594};
      case 'A3': return {'w': 297, 'h': 420};
      case 'A5': return {'w': 148, 'h': 210};
      default: return {'w': 210, 'h': 297}; // A4
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
    String? title,
    String? sectionTitle,
    String? sectionColor,
    bool clearSection = false, 
    String? footer,
    String? extractedText,
    List<PageObject>? objects,
    BackgroundConfig? backgroundConfig,
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
      title: title ?? this.title,
      sectionTitle: clearSection ? null : (sectionTitle ?? this.sectionTitle),
      sectionColor: clearSection ? null : (sectionColor ?? this.sectionColor),
      footer: footer ?? this.footer,
      extractedText: extractedText ?? this.extractedText,
      objects: objects ?? List.from(this.objects),
      backgroundConfig: backgroundConfig ?? this.backgroundConfig,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  LocalPage clone({String? newClientId, int? newNotebookId, int? newPageNumber}) {
    return LocalPage(
      id: null,
      serverId: null,
      clientId: newClientId ?? const Uuid().v4(),
      notebookId: newNotebookId ?? notebookId,
      pageNumber: newPageNumber ?? pageNumber,
      isLandscape: isLandscape,
      paperSize: paperSize,
      lineType: lineType,
      lineSpacing: lineSpacing,
      isFrozen: isFrozen,
      isFavorite: isFavorite,
      isDeleted: isDeleted,
      isInfinite: isInfinite,
      title: title,
      sectionTitle: sectionTitle,
      sectionColor: sectionColor,
      footer: footer,
      extractedText: extractedText,
      objects: objects.map((obj) => obj.clone(newPageNumber: newPageNumber ?? pageNumber)).toList(),
      backgroundConfig: backgroundConfig != null ? BackgroundConfig.fromJson(backgroundConfig!.toJson()) : null,
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
      'background_config': backgroundConfig?.toJson(),
      'updated_at': updatedAt,
      'version': version,
    };
  }

  Future<Map<String, dynamic>> toJsonAsync() async {
    final List<Map<String, dynamic>> asyncObjects = [];
    for (var obj in objects) {
      if (obj is ImageBlock) {
        asyncObjects.add(await obj.toJsonAsync());
      } else {
        asyncObjects.add(obj.toJson());
      }
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
      }
    } else {
      final List<dynamic> strokesList = json['stroke_data'] ?? [];
      final List<dynamic> textList = json['text_data'] ?? [];
      final List<dynamic> imageList = json['image_data'] ?? [];
      objs.addAll(strokesList.map((s) => Stroke.fromJson(s)));
      objs.addAll(textList.map((t) => TextBlock.fromJson(t)));
      objs.addAll(imageList.map((img) => ImageBlock.fromJson(img)));
    }

    int? upAt;
    if (json['updated_at_ms'] != null) upAt = (json['updated_at_ms'] as num).toInt();
    else if (json['updated_at'] != null) {
      final val = json['updated_at'];
      if (val is num) upAt = val.toInt();
      else if (val is String) upAt = DateTime.tryParse(val)?.millisecondsSinceEpoch;
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
      title: parseMeta(json['header_data']),
      sectionTitle: parseSection(json['header_data']),
      sectionColor: parseSectionColor(json['header_data']),
      footer: parseMeta(json['footer_data']),
      extractedText: json['extracted_text']?.toString(),
      objects: objs,
      backgroundConfig: json['background_config'] != null ? BackgroundConfig.fromJson(json['background_config']) : null,
      syncedWithCloud: json['synced_with_cloud'] ?? 0,
      updatedAt: upAt,
      version: int.tryParse(json['version']?.toString() ?? '1') ?? 1,
    );
  }

  static String parseMeta(dynamic data) {
    if (data == null) return '';
    dynamic current = data;
    for (int i = 0; i < 5; i++) {
      if (current is Map) current = current['title'];
      else if (current is String && current.trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(current);
          if (decoded is Map && decoded.containsKey('title')) current = decoded['title'];
          else break;
        } catch (_) { break; }
      } else {
        break;
      }
    }
    return current?.toString() ?? '';
  }

  static String? parseSection(dynamic data) {
    if (data == null) return null;
    if (data is Map) return data['section']?.toString();
    if (data is String && data.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return decoded['section']?.toString();
      } catch (_) {}
    }
    return null;
  }

  static String? parseSectionColor(dynamic data) {
    if (data == null) return null;
    if (data is Map) return data['section_color']?.toString();
    if (data is String && data.trim().startsWith('{')) {
      try {
        final decoded = jsonDecode(data);
        if (decoded is Map) return decoded['section_color']?.toString();
      } catch (_) {}
    }
    return null;
  }
}
