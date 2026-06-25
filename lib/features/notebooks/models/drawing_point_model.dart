import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';

class Stroke {
  final String id;
  final String color;
  final double thickness;
  final List<Offset> points;

  Stroke({
    String? id,
    required this.color,
    required this.thickness,
    required this.points,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'color': color,
      'thickness': thickness,
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    };
  }

  factory Stroke.fromMap(Map<String, dynamic> map) {
    return Stroke(
      id: map['id']?.toString(),
      color: map['color']?.toString() ?? '#1A1A24',
      thickness: (map['thickness'] as num?)?.toDouble() ?? 3.0,
      points: map['points'] != null
          ? (map['points'] as List)
          .map((p) => Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()))
          .toList()
          : <Offset>[],
    );
  }

  String toJsonString() => jsonEncode(toMap());
  factory Stroke.fromJsonString(String jsonStr) => Stroke.fromMap(jsonDecode(jsonStr));
}

// 🚀 ATUALIZADO: Bloco de Texto com Suporte a Tamanho de Fonte (fontSize)
class TextBlock {
  final String id;
  String text;
  Offset position;

  bool isBold;
  bool isItalic;
  bool isUnderline;
  String textColorHex;
  double fontSize; // 🚀 NOVO CAMPO

  TextBlock({
    String? id,
    required this.text,
    required this.position,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.textColorHex = '#1A1A24',
    this.fontSize = 18.0, // Tamanho padrão
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'dx': position.dx,
    'dy': position.dy,
    'isBold': isBold,
    'isItalic': isItalic,
    'isUnderline': isUnderline,
    'textColorHex': textColorHex,
    'fontSize': fontSize, // 🚀 SALVA O TAMANHO
  };

  factory TextBlock.fromMap(Map<String, dynamic> map) => TextBlock(
    id: map['id']?.toString(),
    text: map['text']?.toString() ?? '',
    position: Offset(
      (map['dx'] as num?)?.toDouble() ?? 0.0,
      (map['dy'] as num?)?.toDouble() ?? 0.0,
    ),
    isBold: map['isBold'] ?? false,
    isItalic: map['isItalic'] ?? false,
    isUnderline: map['isUnderline'] ?? false,
    textColorHex: map['textColorHex']?.toString() ?? '#1A1A24',
    fontSize: (map['fontSize'] as num?)?.toDouble() ?? 18.0, // 🚀 LÊ O TAMANHO (protegido)
  );
}

class LocalPage {
  int? id;             // 🚀 ID Local (INTEGER AUTOINCREMENT do teu SQLite)
  int? serverId;       // server_id vindo do Laravel
  final int notebookId;      // notebook_id (chave estrangeira)
  final int pageNumber;      // page_number sequencial
  final bool isLandscape;

  List<Stroke> strokes;
  List<Stroke> undoHistory = [];
  List<Stroke> redoHistory = [];

  String title;
  String footer;
  List<TextBlock> textBlocks;

  int syncedWithCloud;       // 🚀 0 = Não sincronizado, 1 = Sincronizado (Seguindo o teu padrão)
  int updatedAt;             // Timestamp para controlo de modificação

  late TransformationController transformationController;

  LocalPage({
    this.id,
    this.serverId,
    required this.notebookId,
    required this.pageNumber,
    required this.isLandscape,
    List<Stroke>? strokes,
    this.title = '',
    this.footer = '',
    List<TextBlock>? textBlocks,
    this.syncedWithCloud = 0,
    int? updatedAt,
  })  : strokes = strokes ?? <Stroke>[],
        textBlocks = textBlocks ?? <TextBlock>[],
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch {
    transformationController = TransformationController();
  }

  void dispose() {
    transformationController.dispose();
  }

  // Mapeia para corresponder exatamente à tua tabela 'pages'
  Map<String, dynamic> toDatabaseMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'notebook_id': notebookId,
      'page_number': pageNumber,
      'is_landscape': isLandscape ? 1 : 0,
      'header_data': title,        // O teu campo header_data recebe o título
      'footer_data': footer,       // O teu campo footer_data recebe o rodapé
      'synced_with_cloud': syncedWithCloud,
    };
  }

  // Cria o objeto a partir da tua tabela 'pages' (as listas de strokes e textBlocks serão carregadas à parte)
  factory LocalPage.fromDatabaseMap(Map<String, dynamic> map) {
    return LocalPage(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      notebookId: map['notebook_id'] as int,
      pageNumber: map['page_number'] as int,
      isLandscape: map['is_landscape'] == 1,
      title: map['header_data']?.toString() ?? '',
      footer: map['footer_data']?.toString() ?? '',
      syncedWithCloud: map['synced_with_cloud'] as int? ?? 0,
    );
  }
}