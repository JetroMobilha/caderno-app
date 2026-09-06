import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'time_service.dart';

/// 🚀 Utilitários para processamento de dados de sincronização v29 (Fase 2)
class SyncIsolates {
  
  static List<dynamic> processCanvasDataBatch(Map<String, dynamic> input) {
    final List<dynamic> serverPages = input['serverPages'];
    final int currentTime = input['currentTime'];
    
    final List<CanvasStrokesCompanion> strokes = [];
    final List<CanvasTextBlocksCompanion> texts = [];
    final List<CanvasImageBlocksCompanion> images = [];
    final List<CanvasShapesCompanion> shapes = [];
    final List<CanvasAudioBlocksCompanion> audios = [];
    final List<CanvasAnimationsCompanion> animations = [];
    final List<CanvasTablesCompanion> tables = [];
    final List<CanvasLinksCompanion> links = [];
    final List<CanvasAttachmentsCompanion> attachments = [];

    for (var sPage in serverPages) {
      final int localPageId = sPage['_localPageId'];
      
      // 🚀 v29: Processar lista unificada de objetos
      final List objects = sPage['objects_data'] ?? [];
      
      for (var obj in objects) {
        final String type = obj['type']?.toString() ?? '';
        final String id = obj['id']?.toString() ?? 'err';
        final int ts = (obj['updated_at'] as num?)?.toInt() ?? currentTime;
        final String layerId = obj['layer_id']?.toString() ?? 'default';

        switch (type) {
          case 'stroke':
            strokes.add(CanvasStrokesCompanion.insert(
              clientStrokeId: id, pageId: localPageId, strokeData: jsonEncode(obj),
              isDeleted: Value(obj['is_deleted'] == true ? 1 : 0),
              syncedWithCloud: const Value(1), updatedAt: Value(ts), layerId: Value(layerId)
            ));
            break;
          case 'text':
            texts.add(CanvasTextBlocksCompanion.insert(
              clientTextId: id, pageId: localPageId, textData: jsonEncode(obj),
              isDeleted: Value(obj['is_deleted'] == true ? 1 : 0),
              syncedWithCloud: const Value(1), updatedAt: Value(ts), layerId: Value(layerId)
            ));
            break;
          case 'image':
            images.add(CanvasImageBlocksCompanion.insert(
              clientImageId: id, pageId: localPageId, imagePath: obj['image_path'] ?? '',
              posX: (obj['dx'] as num?)?.toDouble() ?? 0.0, posY: (obj['dy'] as num?)?.toDouble() ?? 0.0,
              width: (obj['width'] as num?)?.toDouble() ?? 300.0, height: (obj['height'] as num?)?.toDouble() ?? 200.0,
              rotation: (obj['rotation'] as num?)?.toDouble() ?? 0.0,
              isDeleted: Value(obj['is_deleted'] == true ? 1 : 0),
              syncedWithCloud: const Value(1), updatedAt: Value(ts), layerId: Value(layerId)
            ));
            break;
          case 'shape':
            shapes.add(CanvasShapesCompanion.insert(
              clientShapeId: id, pageId: localPageId, shapeData: jsonEncode(obj),
              isDeleted: Value(obj['is_deleted'] == true ? 1 : 0),
              syncedWithCloud: const Value(1), // 🚀 v30
              updatedAt: Value(ts), layerId: Value(layerId)
            ));
            break;
          case 'audio':
            audios.add(CanvasAudioBlocksCompanion.insert(
              clientAudioId: id, pageId: localPageId, audioData: jsonEncode(obj),
              isDeleted: Value(obj['is_deleted'] == true ? 1 : 0),
              syncedWithCloud: const Value(1), // 🚀 v30
              updatedAt: Value(ts), layerId: Value(layerId)
            ));
            break;
          case 'animation':
            animations.add(CanvasAnimationsCompanion.insert(
              clientAnimationId: id, pageId: localPageId, animationData: jsonEncode(obj),
              isDeleted: Value(obj['is_deleted'] == true ? 1 : 0),
              syncedWithCloud: const Value(1), // 🚀 v30
              updatedAt: Value(ts), layerId: Value(layerId)
            ));
            break;
          case 'table':
            tables.add(CanvasTablesCompanion.insert(
              clientTableId: id, pageId: localPageId, tableData: jsonEncode(obj),
              isDeleted: Value(obj['is_deleted'] == true ? 1 : 0),
              syncedWithCloud: const Value(1), // 🚀 v30
              updatedAt: Value(ts), layerId: Value(layerId)
            ));
            break;
          case 'link':
            links.add(CanvasLinksCompanion.insert(
              clientLinkId: id, pageId: localPageId, linkData: jsonEncode(obj),
              isDeleted: Value(obj['is_deleted'] == true ? 1 : 0),
              syncedWithCloud: const Value(1), // 🚀 v30
              updatedAt: Value(ts), layerId: Value(layerId)
            ));
            break;
          case 'attachment':
            attachments.add(CanvasAttachmentsCompanion.insert(
              clientAttachmentId: id, pageId: localPageId, attachmentData: jsonEncode(obj),
              isDeleted: Value(obj['is_deleted'] == true ? 1 : 0),
              syncedWithCloud: const Value(1), // 🚀 v30
              updatedAt: Value(ts), layerId: Value(layerId)
            ));
            break;
        }
      }
    }

    return [strokes, texts, images, shapes, audios, animations, tables, links, attachments];
  }

  // Mapeadores legados mantidos para suporte a pedaços de rede (Chunks) se necessário
  static CanvasStrokesCompanion mapStrokeToCompanion(Map<String, dynamic> st, int localPageId, int currentTime) {
    final String id = st['id']?.toString() ?? 'err';
    return CanvasStrokesCompanion.insert(
      clientStrokeId: id, pageId: localPageId, strokeData: jsonEncode(st),
      isDeleted: Value(st['is_deleted'] == true ? 1 : 0),
      syncedWithCloud: const Value(1), updatedAt: Value((st['updated_at'] as num?)?.toInt() ?? currentTime)
    );
  }

  static CanvasTextBlocksCompanion mapTextToCompanion(Map<String, dynamic> txt, int localPageId, int currentTime) {
    final String id = txt['id']?.toString() ?? 'err';
    return CanvasTextBlocksCompanion.insert(
      clientTextId: id, pageId: localPageId, textData: jsonEncode(txt),
      isDeleted: Value(txt['is_deleted'] == true ? 1 : 0),
      syncedWithCloud: const Value(1), updatedAt: Value((txt['updated_at'] as num?)?.toInt() ?? currentTime)
    );
  }

  static CanvasImageBlocksCompanion mapImageToCompanion(Map<String, dynamic> img, int localPageId, int currentTime) {
    final String id = img['id']?.toString() ?? 'err';
    return CanvasImageBlocksCompanion.insert(
      clientImageId: id, pageId: localPageId, imagePath: img['image_path'] ?? '',
      posX: (img['dx'] as num?)?.toDouble() ?? 0.0, posY: (img['dy'] as num?)?.toDouble() ?? 0.0,
      width: (img['width'] as num?)?.toDouble() ?? 300.0, height: (img['height'] as num?)?.toDouble() ?? 200.0,
      rotation: (img['rotation'] as num?)?.toDouble() ?? 0.0,
      isDeleted: Value(img['is_deleted'] == true ? 1 : 0),
      syncedWithCloud: const Value(1), updatedAt: Value((img['updated_at'] as num?)?.toInt() ?? currentTime)
    );
  }
}
