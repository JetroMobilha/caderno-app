import 'dart:convert';
import 'dart:math';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/network/time_service.dart'; // 🚀
import 'image_block_model.dart';
import 'stroke_model.dart';
import 'text_block_model.dart';

class LocalPage {
  int? id;
  int? serverId;
  final String clientId; // 🆔 Identidade única global
  final int notebookId;
  final int pageNumber;
  final bool isLandscape;
  final String paperSize;
  String? lineType; // 🚀 Pauta específica por folha
  double? lineSpacing; // 📏 Espaçamento por folha
  bool isFrozen; 
  bool isDeleted; // 🚀
  bool isTearing = false; // 🚀 Feedback visual

  String title;
  String footer;
  String? extractedText; // 🧠 Texto convertido da escrita manual

  List<Stroke> strokes;
  List<TextBlock> textBlocks;
  List<ImageBlock> imageBlocks;

  // 🚀 A VARIÁVEL QUE FALTAVA PARA O REDO FUNCIONAR!
  List<Stroke> redoHistory;

  int syncedWithCloud;
  int updatedAt;
  int version; // 🔄 Versão local para trigger de UI

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
       redoHistory = [], // Inicializa a lista vazia
       updatedAt = updatedAt ?? TimeService().nowMs(); // 🕒 Hora do servidor

  // 🆔 Gera um "Fingerprint" da página para detectar divergências em tempo real
  String generateFingerprint() {
    final List<String> components = [];

    // 1. Coletar IDs e timestamps de strokes não deletados
    final activeStrokes = strokes.where((s) => !s.isDeleted).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (var s in activeStrokes) {
      components.add('s:${s.id}:${s.updatedAt}');
    }

    // 2. Coletar IDs e timestamps de textos não deletados
    final activeTexts = textBlocks.where((t) => !t.isDeleted).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (var t in activeTexts) {
      components.add('t:${t.id}:${t.updatedAt}');
    }

    // 3. Coletar IDs e timestamps de imagens não deletadas
    final activeImages = imageBlocks.where((i) => !i.isDeleted).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
    for (var i in activeImages) {
      components.add('i:${i.id}:${i.updatedAt}');
    }

    // 4. Metadados Críticos
    components.add('f:${isFrozen ? 1 : 0}');
    components.add('ps:$paperSize');
    components.add('lt:${lineType ?? 'ruled'}');
    components.add('ls:${lineSpacing ?? '28'}');

    // Retorna uma string que representa o estado atual (ordenado para consistência)
    return components.join('|');
  }

  // =========================================================================
  // ☁️ COMUNICAÇÃO (JSON / Laravel / Drift)
  // =========================================================================
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
      'header_data': {'title': title},
      'footer_data': {'title': footer},
      'extracted_text': extractedText,
      'stroke_data': strokes.map((s) => s.toJson()).toList(),
      'text_data': textBlocks.map((t) => t.toJson()).toList(),
      'image_data': imageBlocks.map((img) => img.toJson()).toList(),
      'updated_at': updatedAt,
      'version': 1, // Mantido fixo para compatibilidade com servidor
    };
  }

  Future<Map<String, dynamic>> toJsonAsync() async {
    final List<Map<String, dynamic>> asyncImages = [];
    for (var img in imageBlocks) {
      asyncImages.add(await img.toJsonAsync());
    }

    return {
      if (serverId != null) 'id': serverId,
      'client_id': clientId, // 🆔 Usar clientId global
      'notebook_id': notebookId,
      'page_number': pageNumber,
      'is_landscape': isLandscape,
      'paper_size': paperSize,
      'line_type': lineType,
      'line_spacing': lineSpacing,
      'is_frozen': isFrozen ? 1 : 0,
      'is_deleted': isDeleted ? 1 : 0,
      'header_data': {'title': title}, // 🚀 JSON estruturado para o MySQL
      'footer_data': {'title': footer}, // 🚀 JSON estruturado para o MySQL
      'extracted_text': extractedText,
      'stroke_data': strokes.map((s) => s.toJson()).toList(),
      'text_data': textBlocks.map((t) => t.toJson()).toList(),
      'image_data': asyncImages,
      'updated_at': updatedAt,
      'version': 1, // Fixo para o backend
    };
  }

  // 🛡️ Extração robusta para colunas JSON do MySQL/SQLite (Lida com aninhamento acidental)
  static String parseMeta(dynamic data) {
    if (data == null) return '';
    
    dynamic current = data;
    // Tenta desempacotar até 5 níveis de JSON para limpar dados corrompidos
    for (int i = 0; i < 5; i++) {
      if (current is Map) {
        current = current['title'];
      } else if (current is String && current.trim().startsWith('{')) {
        try {
          final decoded = jsonDecode(current);
          if (decoded is Map && decoded.containsKey('title')) {
            current = decoded['title'];
          } else {
            break;
          }
        } catch (_) {
          break;
        }
      } else {
        break;
      }
    }
    
    return current?.toString() ?? '';
  }

  static String encodeMeta(String text) {
    return jsonEncode({'title': text});
  }

  factory LocalPage.fromJson(Map<String, dynamic> json) {
    final List<dynamic> strokesList = json['stroke_data'] ?? [];
    final List<dynamic> textList = json['text_data'] ?? [];
    final List<dynamic> imageList = json['image_data'] ?? [];

    // 🚀 Lógica resiliente para data de atualização
    int? upAt;
    if (json['updated_at_ms'] != null) {
      upAt = (json['updated_at_ms'] as num).toInt();
    } else if (json['updated_at'] != null) {
      final val = json['updated_at'];
      if (val is num) {
        upAt = val.toInt();
      } else if (val is String) {
        upAt = DateTime.tryParse(val)?.millisecondsSinceEpoch;
      }
    }

    return LocalPage(
      serverId: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      clientId: json['client_id']?.toString(), // 🆔 Recuperar clientId
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
