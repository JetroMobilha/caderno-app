import 'package:flutter/material.dart';
import 'package:caderno_digital_app/core/network/time_service.dart'; // 🚀
import 'local_page_model.dart';
import 'stroke_model.dart';
import 'text_block_model.dart';
import 'image_block_model.dart';

abstract class CanvasAction {
  final String pageClientId;
  final int pageNumber;
  final int timestamp; // 🚀 Crucial para LWW
  
  CanvasAction(this.pageClientId, this.pageNumber, {int? timestamp}) 
    : timestamp = timestamp ?? TimeService().nowMs();

  void execute(LocalPage page);
  void undo(LocalPage page);
  
  String get type;
  Map<String, dynamic> toMap();

  static CanvasAction? fromMap(String type, Map<String, dynamic> data) {
    final String cid = data['pageClientId'] ?? '';
    final int pNum = data['pageNumber'] ?? 1;
    final int? ts = data['timestamp'];

    if (type == 'addStroke') {
      return AddStrokeAction(pageClientId: cid, pageNumber: pNum, stroke: Stroke.fromJson(data['stroke']), timestamp: ts);
    } else if (type == 'delete') {
      return DeleteAction(
        pageClientId: cid,
        pageNumber: pNum,
        strokes: (data['strokes'] as List).map((s) => Stroke.fromJson(s)).toList(),
        texts: (data['texts'] as List).map((t) => TextBlock.fromJson(t)).toList(),
        images: (data['images'] as List).map((i) => ImageBlock.fromJson(i)).toList(),
        timestamp: ts,
      );
    } else if (type == 'addText') {
      return AddTextAction(pageClientId: cid, pageNumber: pNum, block: TextBlock.fromJson(data['block']), timestamp: ts);
    } else if (type == 'addImage') {
      return AddImageAction(pageClientId: cid, pageNumber: pNum, block: ImageBlock.fromJson(data['block']), timestamp: ts);
    } else if (type == 'updateImage') {
      return UpdateImageAction(
        pageClientId: cid,
        pageNumber: pNum,
        imageId: data['imageId'],
        oldState: ImageBlock.fromJson(data['oldState']),
        newState: ImageBlock.fromJson(data['newState']),
        timestamp: ts,
      );
    } else if (type == 'updateText') {
      return UpdateTextAction(
        pageClientId: cid,
        pageNumber: pNum,
        textId: data['textId'],
        oldState: TextBlock.fromJson(data['oldState']),
        newState: TextBlock.fromJson(data['newState']),
        timestamp: ts,
      );
    } else if (type == 'move') {
      return MoveAction(
        pageClientId: cid,
        pageNumber: pNum,
        strokeIds: List<String>.from(data['strokeIds'] ?? []),
        textIds: List<String>.from(data['textIds'] ?? []),
        imageIds: List<String>.from(data['imageIds'] ?? []),
        delta: Offset((data['deltaX'] as num).toDouble(), (data['deltaY'] as num).toDouble()),
        timestamp: ts,
      );
    } else if (type == 'addPage') {
      return AddPageAction(
        pageClientId: cid,
        pageNumber: pNum,
        isLandscape: data['isLandscape'] ?? false,
        paperSize: data['paperSize'] ?? 'A4',
        lineType: data['lineType'],
        lineSpacing: (data['lineSpacing'] as num?)?.toDouble(),
        timestamp: ts,
      );
    } else if (type == 'deletePage') {
      return DeletePageAction(
        pageClientId: cid,
        pageNumber: pNum,
        pageData: data['pageData'], // JSON do estado completo da página
        timestamp: ts,
      );
    }
    return null;
  }
}

class MoveAction extends CanvasAction {
  final List<String> strokeIds;
  final List<String> textIds;
  final List<String> imageIds;
  final Offset delta;

  MoveAction({
    required String pageClientId, 
    required int pageNumber, 
    required this.strokeIds, 
    required this.textIds, 
    required this.imageIds, 
    required this.delta,
    int? timestamp,
  }) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'move';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId,
    'pageNumber': pageNumber,
    'timestamp': timestamp,
    'strokeIds': strokeIds,
    'textIds': textIds,
    'imageIds': imageIds,
    'deltaX': delta.dx,
    'deltaY': delta.dy,
  };

  @override void execute(LocalPage page) => _applyDelta(page, delta);
  @override void undo(LocalPage page) => _applyDelta(page, -delta);

  void _applyDelta(LocalPage page, Offset d) {
    final int now = TimeService().nowMs();
    for (var sid in strokeIds) {
      final idx = page.strokes.indexWhere((s) => s.id == sid);
      if (idx != -1) {
        final s = page.strokes[idx];
        for (int i = 0; i < s.points.length; i++) s.points[i] += d;
        s.updatedAt = now;
      }
    }
    for (var tid in textIds) {
      final idx = page.textBlocks.indexWhere((t) => t.id == tid);
      if (idx != -1) {
        page.textBlocks[idx].position += d;
        page.textBlocks[idx].updatedAt = now;
      }
    }
    for (var iid in imageIds) {
      final idx = page.imageBlocks.indexWhere((i) => i.id == iid);
      if (idx != -1) {
        page.imageBlocks[idx].position += d;
        page.imageBlocks[idx].updatedAt = now;
      }
    }
  }
}

class AddStrokeAction extends CanvasAction {
  final Stroke stroke;
  AddStrokeAction({required String pageClientId, required int pageNumber, required this.stroke, int? timestamp}) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'addStroke';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId,
    'pageNumber': pageNumber, 
    'timestamp': timestamp,
    'stroke': stroke.toJson()
  };

  @override void execute(LocalPage page) {
    stroke.isDeleted = false;
    stroke.updatedAt = DateTime.now().millisecondsSinceEpoch;
    final idx = page.strokes.indexWhere((s) => s.id == stroke.id);
    if (idx != -1) {
      page.strokes[idx] = stroke;
    } else {
      page.strokes.add(stroke);
    }
  }
  @override void undo(LocalPage page) {
    final idx = page.strokes.indexWhere((s) => s.id == stroke.id);
    if (idx != -1) {
      page.strokes[idx].isDeleted = true;
      page.strokes[idx].updatedAt = DateTime.now().millisecondsSinceEpoch;
    }
  }
}

class DeleteAction extends CanvasAction {
  final List<Stroke> strokes;
  final List<TextBlock> texts;
  final List<ImageBlock> images;
  DeleteAction({required String pageClientId, required int pageNumber, required this.strokes, required this.texts, required this.images, int? timestamp}) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'delete';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId,
    'pageNumber': pageNumber,
    'timestamp': timestamp,
    'strokes': strokes.map((s) => s.toJson()).toList(),
    'texts': texts.map((t) => t.toJson()).toList(),
    'images': images.map((i) => i.toJson()).toList(),
  };

  @override void execute(LocalPage page) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    for (var s in strokes) { 
      final idx = page.strokes.indexWhere((item) => item.id == s.id);
      if (idx != -1) {
        page.strokes[idx].isDeleted = true;
        page.strokes[idx].updatedAt = now;
      }
    }
    for (var t in texts) {
      final idx = page.textBlocks.indexWhere((item) => item.id == t.id);
      if (idx != -1) {
        page.textBlocks[idx].isDeleted = true;
        page.textBlocks[idx].updatedAt = now;
      }
    }
    for (var img in images) {
      final idx = page.imageBlocks.indexWhere((item) => item.id == img.id);
      if (idx != -1) {
        page.imageBlocks[idx].isDeleted = true;
        page.imageBlocks[idx].updatedAt = now;
      }
    }
  }
  @override void undo(LocalPage page) {
    final int now = DateTime.now().millisecondsSinceEpoch;
    for (var s in strokes) {
      final idx = page.strokes.indexWhere((item) => item.id == s.id);
      if (idx != -1) {
        page.strokes[idx].isDeleted = false;
        page.strokes[idx].updatedAt = now;
      }
    }
    for (var t in texts) {
      final idx = page.textBlocks.indexWhere((item) => item.id == t.id);
      if (idx != -1) {
        page.textBlocks[idx].isDeleted = false;
        page.textBlocks[idx].updatedAt = now;
      }
    }
    for (var img in images) {
      final idx = page.imageBlocks.indexWhere((item) => item.id == img.id);
      if (idx != -1) {
        page.imageBlocks[idx].isDeleted = false;
        page.imageBlocks[idx].updatedAt = now;
      }
    }
  }
}

class AddTextAction extends CanvasAction {
  final TextBlock block;
  AddTextAction({required String pageClientId, required int pageNumber, required this.block, int? timestamp}) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'addText';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId,
    'pageNumber': pageNumber, 
    'timestamp': timestamp,
    'block': block.toJson()
  };

  @override void execute(LocalPage page) {
    block.isDeleted = false;
    block.updatedAt = DateTime.now().millisecondsSinceEpoch;
    final idx = page.textBlocks.indexWhere((t) => t.id == block.id);
    if (idx != -1) {
      page.textBlocks[idx] = block;
    } else {
      page.textBlocks.add(block);
    }
  }
  @override void undo(LocalPage page) {
    final idx = page.textBlocks.indexWhere((t) => t.id == block.id);
    if (idx != -1) {
      page.textBlocks[idx].isDeleted = true;
      page.textBlocks[idx].updatedAt = DateTime.now().millisecondsSinceEpoch;
    }
  }
}

class AddImageAction extends CanvasAction {
  final ImageBlock block;
  AddImageAction({required String pageClientId, required int pageNumber, required this.block, int? timestamp}) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'addImage';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId,
    'pageNumber': pageNumber, 
    'timestamp': timestamp,
    'block': block.toJson()
  };

  @override void execute(LocalPage page) {
    block.isDeleted = false;
    block.updatedAt = DateTime.now().millisecondsSinceEpoch;
    final idx = page.imageBlocks.indexWhere((img) => img.id == block.id);
    if (idx != -1) {
      page.imageBlocks[idx] = block;
    } else {
      page.imageBlocks.add(block);
    }
  }
  @override void undo(LocalPage page) {
    final idx = page.imageBlocks.indexWhere((img) => img.id == block.id);
    if (idx != -1) {
      page.imageBlocks[idx].isDeleted = true;
      page.imageBlocks[idx].updatedAt = DateTime.now().millisecondsSinceEpoch;
    }
  }
}

class UpdateImageAction extends CanvasAction {
  final String imageId;
  final ImageBlock oldState;
  final ImageBlock newState;

  UpdateImageAction({required String pageClientId, required int pageNumber, required this.imageId, required this.oldState, required this.newState, int? timestamp}) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'updateImage';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId,
    'pageNumber': pageNumber,
    'timestamp': timestamp,
    'imageId': imageId,
    'oldState': oldState.toJson(),
    'newState': newState.toJson(),
  };

  @override void execute(LocalPage page) {
    final idx = page.imageBlocks.indexWhere((img) => img.id == imageId);
    if (idx != -1) {
      page.imageBlocks[idx] = newState.clone();
    }
  }

  @override void undo(LocalPage page) {
    final idx = page.imageBlocks.indexWhere((img) => img.id == imageId);
    if (idx != -1) {
      page.imageBlocks[idx] = oldState.clone();
    }
  }
}

class UpdateTextAction extends CanvasAction {
  final String textId;
  final TextBlock oldState;
  final TextBlock newState;

  UpdateTextAction({required String pageClientId, required int pageNumber, required this.textId, required this.oldState, required this.newState, int? timestamp}) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'updateText';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId,
    'pageNumber': pageNumber,
    'timestamp': timestamp,
    'textId': textId,
    'oldState': oldState.toJson(),
    'newState': newState.toJson(),
  };

  @override void execute(LocalPage page) {
    final idx = page.textBlocks.indexWhere((t) => t.id == textId);
    if (idx != -1) {
      page.textBlocks[idx] = newState.clone();
    }
  }

  @override void undo(LocalPage page) {
    final idx = page.textBlocks.indexWhere((t) => t.id == textId);
    if (idx != -1) {
      page.textBlocks[idx] = oldState.clone();
    }
  }
}

class AddPageAction extends CanvasAction {
  final bool isLandscape;
  final String paperSize;
  final String? lineType;
  final double? lineSpacing;

  AddPageAction({
    required String pageClientId, 
    required int pageNumber, 
    required this.isLandscape, 
    required this.paperSize,
    this.lineType,
    this.lineSpacing,
    int? timestamp,
  }) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'addPage';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId,
    'pageNumber': pageNumber,
    'timestamp': timestamp,
    'isLandscape': isLandscape,
    'paperSize': paperSize,
    'lineType': lineType,
    'lineSpacing': lineSpacing,
  };

  @override void execute(LocalPage page) {
    // A página em si é gerida pelo controlador, a ação apenas marca como ativa
    page.isDeleted = false;
    if (lineType != null) page.lineType = lineType;
    if (lineSpacing != null) page.lineSpacing = lineSpacing;
    page.updatedAt = DateTime.now().millisecondsSinceEpoch;
  }

  @override void undo(LocalPage page) {
    page.isDeleted = true;
    page.updatedAt = DateTime.now().millisecondsSinceEpoch;
  }
}

class DeletePageAction extends CanvasAction {
  final Map<String, dynamic> pageData; // Para restaurar se houver Undo

  DeletePageAction({
    required String pageClientId, 
    required int pageNumber, 
    required this.pageData,
    int? timestamp,
  }) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'deletePage';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId,
    'pageNumber': pageNumber,
    'timestamp': timestamp,
    'pageData': pageData,
  };

  @override void execute(LocalPage page) {
    page.isDeleted = true;
    page.updatedAt = DateTime.now().millisecondsSinceEpoch;
  }

  @override void undo(LocalPage page) {
    page.isDeleted = false;
    page.updatedAt = DateTime.now().millisecondsSinceEpoch;
  }
}
