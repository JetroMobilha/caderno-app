import 'dart:convert';
import 'package:flutter/material.dart';
import 'drawing_point_model.dart'; // Onde estão os teus Stroke, TextBlock e ImageBlock

class LocalPage {
  int? id;             // 💻 ID Local (SQLite AUTOINCREMENT)
  int? serverId;       // ☁️ ID Oficial na Nuvem (Laravel)
  final int notebookId;
  final int pageNumber;
  final bool isLandscape;


  List<Stroke> strokes;
  List<Stroke> undoHistory = [];
  List<Stroke> redoHistory = [];

  String title;
  String footer;
  List<TextBlock> textBlocks;
  List<ImageBlock> imageBlocks;

  int syncedWithCloud; // 0 = Pendente de Envio, 1 = Sincronizado
  int updatedAt;

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
    List<ImageBlock>? imageBlocks,
    this.syncedWithCloud = 0,
    int? updatedAt,
  })  : strokes = strokes ?? <Stroke>[],
        textBlocks = textBlocks ?? <TextBlock>[],
        imageBlocks = imageBlocks ?? <ImageBlock>[],
        updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch {
    transformationController = TransformationController();
  }

  void dispose() {
    transformationController.dispose();
  }

  // =========================================================================
  // 💻 LINGUAGEM 1: COMUNICAÇÃO COM O DISCO LOCAL (SQLite)
  // =========================================================================
  Map<String, dynamic> toDatabaseMap() {
    return {
      if (id != null) 'id': id,
      'server_id': serverId,
      'notebook_id': notebookId,
      'page_number': pageNumber,
      'is_landscape': isLandscape ? 1 : 0,
      'header_data': title,
      'footer_data': footer,
      'synced_with_cloud': syncedWithCloud,
    };
  }

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

  // =========================================================================
  // ☁️ LINGUAGEM 2: COMUNICAÇÃO COM O QUARTEL-GENERAL (Laravel API / JSON)
  // =========================================================================
  Map<String, dynamic> toMap() {
    return {
      if (serverId != null) 'id': serverId,
      'client_id': id,
      'notebook_id': notebookId,
      'page_number': pageNumber,
      'is_landscape': isLandscape,
      'header_data': title,
      'footer_data': footer,
      // Serializamos os vetores da caneta e os textos teclar para viajar na rede
      'stroke_data': strokes.map((s) => s.toMap()).toList(),
      'text_data': textBlocks.map((t) => t.toMap()).toList(),
      'image_data': imageBlocks.map((img) => img.toMap()).toList(),
    };
  }

  factory LocalPage.fromMap(Map<String, dynamic> map) {
    final List<dynamic> strokesList = map['stroke_data'] ?? [];
    final List<dynamic> textList = map['text_data'] ?? [];
    final List<dynamic> imageList = map['image_data'] ?? [];

    return LocalPage(
      id: map['client_id'] != null ? int.tryParse(map['client_id'].toString()) : null,
      serverId: map['id'] != null ? int.tryParse(map['id'].toString()) : null,
      notebookId: int.parse(map['notebook_id'].toString()),
      pageNumber: int.parse(map['page_number'].toString()),
      isLandscape: map['is_landscape'] == true || map['is_landscape'] == 1,
      title: map['header_data']?.toString() ?? '',
      footer: map['footer_data']?.toString() ?? '',
      strokes: strokesList.map((s) => Stroke.fromMap(s)).toList(),
      textBlocks: textList.map((t) => TextBlock.fromMap(t)).toList(),
      imageBlocks: imageList.map((img) => ImageBlock.fromMap(img)).toList(),
      syncedWithCloud: 1, // Se veio do Laravel, já está 100% sincronizado!
    );
  }
}