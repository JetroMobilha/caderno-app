import 'dart:convert';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'image_block_model.dart';
import 'stroke_model.dart';
import 'text_block_model.dart';

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
  bool isDeleted;
  bool isTearing = false;
  bool isContentLoaded = false;

  String title;
  String footer;
  String? extractedText;

  List<Stroke> strokes;
  List<TextBlock> textBlocks;
  List<ImageBlock> imageBlocks;

  List<Stroke> redoHistory;

  int syncedWithCloud;
  int updatedAt;
  int version;

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
    this.isDeleted = false,
    List<Stroke>? strokes,
    this.title = '',
    this.footer = '',
    this.extractedText,
    List<TextBlock>? textBlocks,
    List<ImageBlock>? imageBlocks,
    this.syncedWithCloud = 0,
    int? updatedAt,
    this.version = 1,
  })  : clientId = clientId ?? const Uuid().v4(),
       strokes = strokes ?? <Stroke>[],
       textBlocks = textBlocks ?? <TextBlock>[],
       imageBlocks = imageBlocks ?? <ImageBlock>[],
       redoHistory = [],
       updatedAt = updatedAt ?? TimeService().nowMs();

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
    bool? isDeleted,
    String? title,
    String? footer,
    String? extractedText,
    List<Stroke>? strokes,
    List<TextBlock>? textBlocks,
    List<ImageBlock>? imageBlocks,
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
      isDeleted: isDeleted ?? this.isDeleted,
      title: title ?? this.title,
      footer: footer ?? this.footer,
      extractedText: extractedText ?? this.extractedText,
      strokes: strokes ?? List.from(this.strokes),
      textBlocks: textBlocks ?? List.from(this.textBlocks),
      imageBlocks: imageBlocks ?? List.from(this.imageBlocks),
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  String generateFingerprint() {
    final List<String> components = [];
    final activeStrokes = strokes.where((s) => !s.isDeleted).toList()..sort((a, b) => a.id.compareTo(b.id));
    for (var s in activeStrokes) components.add('s:${s.id}:${s.updatedAt}');
    final activeTexts = textBlocks.where((t) => !t.isDeleted).toList()..sort((a, b) => a.id.compareTo(b.id));
    for (var t in activeTexts) components.add('t:${t.id}:${t.updatedAt}');
    final activeImages = imageBlocks.where((i) => !i.isDeleted).toList()..sort((a, b) => a.id.compareTo(b.id));
    for (var i in activeImages) components.add('i:${i.id}:${i.updatedAt}');
    components.add('f:${isFrozen ? 1 : 0}');
    components.add('ps:$paperSize');
    components.add('lt:${lineType ?? 'ruled'}');
    components.add('ls:${lineSpacing ?? '28'}');
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
      'is_deleted': isDeleted ? 1 : 0,
      'synced_with_cloud': syncedWithCloud,
      'header_data': {'title': title},
      'footer_data': {'title': footer},
      'extracted_text': extractedText,
      'stroke_data': strokes.map((s) => s.toJson()).toList(),
      'text_data': textBlocks.map((t) => t.toJson()).toList(),
      'image_data': imageBlocks.map((img) => img.toJson()).toList(),
      'updated_at': updatedAt,
      'version': 1,
    };
  }

  Future<Map<String, dynamic>> toJsonAsync() async {
    final List<Map<String, dynamic>> asyncImages = [];
    for (var img in imageBlocks) asyncImages.add(await img.toJsonAsync());
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
      'is_deleted': isDeleted ? 1 : 0,
      'synced_with_cloud': syncedWithCloud,
      'header_data': {'title': title},
      'footer_data': {'title': footer},
      'extracted_text': extractedText,
      'stroke_data': strokes.map((s) => s.toJson()).toList(),
      'text_data': textBlocks.map((t) => t.toJson()).toList(),
      'image_data': asyncImages,
      'updated_at': updatedAt,
      'version': 1,
    };
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
      } else break;
    }
    return current?.toString() ?? '';
  }

  static String encodeMeta(String text) => jsonEncode({'title': text});

  factory LocalPage.fromJson(Map<String, dynamic> json) {
    final List<dynamic> strokesList = json['stroke_data'] ?? [];
    final List<dynamic> textList = json['text_data'] ?? [];
    final List<dynamic> imageList = json['image_data'] ?? [];
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
      isDeleted: json['is_deleted'] == true || json['is_deleted'] == 1,
      title: parseMeta(json['header_data']),
      footer: parseMeta(json['footer_data']),
      extractedText: json['extracted_text']?.toString(),
      strokes: strokesList.map((s) => Stroke.fromJson(s)).toList(),
      textBlocks: textList.map((t) => TextBlock.fromJson(t)).toList(),
      imageBlocks: imageList.map((img) => ImageBlock.fromJson(img)).toList(),
      syncedWithCloud: 1,
      updatedAt: upAt,
      version: int.tryParse(json['version']?.toString() ?? '1') ?? 1,
    );
  }
}
