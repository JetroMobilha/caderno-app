import 'image_block_model.dart';
import 'stroke_model.dart';
import 'text_block_model.dart';

class LocalPage {
  int? id;
  int? serverId;
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

  LocalPage({
    this.id,
    this.serverId,
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
  })  : strokes = strokes ?? <Stroke>[],
        textBlocks = textBlocks ?? <TextBlock>[],
        imageBlocks = imageBlocks ?? <ImageBlock>[],
        redoHistory = [], // Inicializa a lista vazia
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  // =========================================================================
  // ☁️ COMUNICAÇÃO (JSON / Laravel / Drift)
  // =========================================================================
  Future<Map<String, dynamic>> toJsonAsync() async {
    final List<Map<String, dynamic>> asyncImages = [];
    for (var img in imageBlocks) {
      asyncImages.add(await img.toJsonAsync());
    }

    return {
      if (serverId != null) 'id': serverId,
      'client_id': id,
      'notebook_id': notebookId,
      'page_number': pageNumber,
      'is_landscape': isLandscape,
      'header_data': title,
      'footer_data': footer,
      'extracted_text': extractedText,
      'stroke_data': strokes.map((s) => s.toJson()).toList(),
      'text_data': textBlocks.map((t) => t.toJson()).toList(),
      'image_data': asyncImages,
    };
  }

  factory LocalPage.fromJson(Map<String, dynamic> json) {
    final List<dynamic> strokesList = json['stroke_data'] ?? [];
    final List<dynamic> textList = json['text_data'] ?? [];
    final List<dynamic> imageList = json['image_data'] ?? [];

    return LocalPage(
      id: json['client_id'] != null ? int.tryParse(json['client_id'].toString()) : null,
      serverId: json['id'] != null ? int.tryParse(json['id'].toString()) : null,
      notebookId: int.tryParse(json['notebook_id']?.toString() ?? '0') ?? 0,
      pageNumber: int.tryParse(json['page_number']?.toString() ?? '0') ?? 0,
      isLandscape: json['is_landscape'] == true || json['is_landscape'] == 1,
      title: json['header_data']?.toString() ?? '',
      footer: json['footer_data']?.toString() ?? '',
      extractedText: json['extracted_text']?.toString(),
      strokes: strokesList.map((s) => Stroke.fromJson(s)).toList(),
      textBlocks: textList.map((t) => TextBlock.fromJson(t)).toList(),
      imageBlocks: imageList.map((img) => ImageBlock.fromJson(img)).toList(),
      syncedWithCloud: 1,
    );
  }
}
