import 'dart:convert';
import 'package:drift/drift.dart';
import '../database/app_database.dart';
import 'time_service.dart';

/// 🚀 Utilitários para processamento de dados de sincronização em Isolate (Background).
class SyncIsolates {
  
  /// Transforma dados brutos do servidor em Companions do Drift para inserção em lote.
  /// 🚀 OTIMIZAÇÃO: Removemos a comparação item a item (LWW) para itens sincronizados,
  /// confiando que o motor de sync no Flutter já limpou os "clean" antes desta chamada.
  static List<dynamic> processCanvasDataBatch(Map<String, dynamic> input) {
    final List<dynamic> serverPages = input['serverPages'];
    final int currentTime = input['currentTime'];
    
    final List<CanvasStrokesCompanion> strokes = [];
    final List<CanvasTextBlocksCompanion> texts = [];
    final List<CanvasImageBlocksCompanion> images = [];

    for (var sPage in serverPages) {
      final int localPageId = sPage['_localPageId'];
      
      // 1. Processar Strokes (Sem merge manual, apenas mapeamento)
      final List strokeList = sPage['stroke_data'] ?? [];
      for (var st in strokeList) {
        strokes.add(mapStrokeToCompanion(st, localPageId, currentTime));
      }

      // 2. Processar Textos
      final List textList = sPage['text_data'] ?? [];
      for (var txt in textList) {
        texts.add(mapTextToCompanion(txt, localPageId, currentTime));
      }

      // 3. Processar Imagens
      final List imageList = sPage['image_data'] ?? [];
      for (var img in imageList) {
        images.add(mapImageToCompanion(img, localPageId, currentTime));
      }
    }

    return [strokes, texts, images];
  }

  // 🚀 Mapeadores reutilizáveis (Isolates e Web Chunks)
  static CanvasStrokesCompanion mapStrokeToCompanion(Map<String, dynamic> st, int localPageId, int currentTime) {
    final String id = st['id']?.toString() ?? 'err';
    final int serverTime = (st['updated_at'] as num?)?.toInt() ?? 0;
    final bool serverDeleted = st['is_deleted'] == true || st['is_deleted'] == 1;

    return CanvasStrokesCompanion.insert(
      clientStrokeId: id, 
      pageId: localPageId, 
      strokeData: jsonEncode(st), 
      isDeleted: Value(serverDeleted ? 1 : 0), 
      deletedInSession: Value(st['deleted_in_session'] == true ? 1 : 0), 
      syncedWithCloud: const Value(1), 
      updatedAt: Value(serverTime > 0 ? serverTime : currentTime)
    );
  }

  static CanvasTextBlocksCompanion mapTextToCompanion(Map<String, dynamic> txt, int localPageId, int currentTime) {
    final String id = txt['id']?.toString() ?? 'err';
    final int serverTime = (txt['updated_at'] as num?)?.toInt() ?? 0;

    return CanvasTextBlocksCompanion.insert(
      clientTextId: id, 
      pageId: localPageId, 
      textData: jsonEncode(txt), 
      isDeleted: Value((txt['is_deleted'] == true || txt['is_deleted'] == 1) ? 1 : 0), 
      deletedInSession: Value(txt['deleted_in_session'] == true ? 1 : 0), 
      syncedWithCloud: const Value(1), 
      updatedAt: Value(serverTime > 0 ? serverTime : currentTime)
    );
  }

  static CanvasImageBlocksCompanion mapImageToCompanion(Map<String, dynamic> img, int localPageId, int currentTime) {
    final String id = img['id']?.toString() ?? 'err';
    final int serverTime = (img['updated_at'] as num?)?.toInt() ?? 0;

    return CanvasImageBlocksCompanion.insert(
      clientImageId: id, 
      pageId: localPageId, 
      imagePath: img['image_path']?.toString() ?? '', 
      posX: (img['dx'] as num?)?.toDouble() ?? 0.0, 
      posY: (img['dy'] as num?)?.toDouble() ?? 0.0, 
      width: (img['width'] as num?)?.toDouble() ?? 300.0, 
      height: (img['height'] as num?)?.toDouble() ?? 200.0, 
      rotation: (img['rotation'] as num?)?.toDouble() ?? 0.0, 
      isDeleted: Value((img['is_deleted'] == true || img['is_deleted'] == 1) ? 1 : 0), 
      deletedInSession: Value(img['deleted_in_session'] == true ? 1 : 0), 
      syncedWithCloud: const Value(1), 
      updatedAt: Value(serverTime > 0 ? serverTime : currentTime)
    );
  }
}
