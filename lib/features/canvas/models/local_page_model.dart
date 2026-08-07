import 'dart:convert';
import 'dart:math';
import 'package:uuid/uuid.dart';
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

  LocalPage({
    this.id,
    this.serverId,
    String? clientId,
    required this.notebookId,
    required this.pageNumber,
    required this.isLandscape,
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
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

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

    return LocalPage(
      serverId: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      clientId: json['client_id']?.toString(), // 🆔 Recuperar clientId
      notebookId: int.tryParse(json['notebook_id']?.toString() ?? '0') ?? 0,
      pageNumber: int.tryParse(json['page_number']?.toString() ?? '0') ?? 0,
      isLandscape: json['is_landscape'] == true || json['is_landscape'] == 1,
      title: parseMeta(json['header_data']),
      footer: parseMeta(json['footer_data']),
      extractedText: json['extracted_text']?.toString(),
      strokes: strokesList.map((s) => Stroke.fromJson(s)).toList(),
      textBlocks: textList.map((t) => TextBlock.fromJson(t)).toList(),
      imageBlocks: imageList.map((img) => ImageBlock.fromJson(img)).toList(),
      syncedWithCloud: 1,
      updatedAt: (json['updated_at'] as num?)?.toInt(),
      version: int.tryParse(json['version']?.toString() ?? '1') ?? 1,
    );
  }
}
