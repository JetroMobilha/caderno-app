import 'package:flutter/material.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'local_page_model.dart';
import 'stroke_model.dart';
import 'text_block_model.dart';
import 'image_block_model.dart';
import 'page_object.dart';

abstract class CanvasAction {
  final String pageClientId;
  final int pageNumber;
  final int timestamp; 
  
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
      // 🚀 Adaptado para objetos genéricos
      return DeleteAction(
        pageClientId: cid,
        pageNumber: pNum,
        objectIds: List<String>.from(data['objectIds'] ?? []),
        timestamp: ts,
      );
    } else if (type == 'addText') {
      return AddTextAction(pageClientId: cid, pageNumber: pNum, block: TextBlock.fromJson(data['block']), timestamp: ts);
    } else if (type == 'addImage') {
      return AddImageAction(pageClientId: cid, pageNumber: pNum, block: ImageBlock.fromJson(data['block']), timestamp: ts);
    } else if (type == 'move') {
      return MoveAction(
        pageClientId: cid,
        pageNumber: pNum,
        objectIds: List<String>.from(data['objectIds'] ?? []),
        delta: Offset((data['deltaX'] as num).toDouble(), (data['deltaY'] as num).toDouble()),
        timestamp: ts,
      );
    } else if (type == 'updateObject') {
      return UpdateObjectAction(
        pageClientId: cid,
        pageNumber: pNum,
        objectId: data['objectId'],
        oldState: data['oldState'],
        newState: data['newState'],
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
        pageData: data['pageData'],
        timestamp: ts,
      );
    }
    return null;
  }
}

class MoveAction extends CanvasAction {
  final List<String> objectIds;
  final Offset delta;

  MoveAction({
    required String pageClientId, 
    required int pageNumber, 
    required this.objectIds, 
    required this.delta,
    int? timestamp,
  }) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'move';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId,
    'pageNumber': pageNumber,
    'timestamp': timestamp,
    'objectIds': objectIds,
    'deltaX': delta.dx,
    'deltaY': delta.dy,
  };

  @override void execute(LocalPage page) => _applyDelta(page, delta);
  @override void undo(LocalPage page) => _applyDelta(page, -delta);

  void _applyDelta(LocalPage page, Offset d) {
    final int now = TimeService().nowMs();
    for (var oid in objectIds) {
      final idx = page.objects.indexWhere((o) => o.id == oid);
      if (idx != -1) {
        page.objects[idx].position += d;
        page.objects[idx].updatedAt = now;
      }
    }
  }
}

class UpdateObjectAction extends CanvasAction {
  final String objectId;
  final Map<String, dynamic> oldState;
  final Map<String, dynamic> newState;

  UpdateObjectAction({
    required String pageClientId, 
    required int pageNumber, 
    required this.objectId, 
    required this.oldState, 
    required this.newState, 
    int? timestamp
  }) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'updateObject';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId,
    'pageNumber': pageNumber,
    'timestamp': timestamp,
    'objectId': objectId,
    'oldState': oldState,
    'newState': newState,
  };

  @override void execute(LocalPage page) => _applyState(page, newState);
  @override void undo(LocalPage page) => _applyState(page, oldState);

  void _applyState(LocalPage page, Map<String, dynamic> state) {
    final idx = page.objects.indexWhere((o) => o.id == objectId);
    if (idx != -1) {
      final type = state['type'];
      PageObject? newObj;
      if (type == 'stroke') newObj = Stroke.fromJson(state);
      else if (type == 'text') newObj = TextBlock.fromJson(state);
      else if (type == 'image') newObj = ImageBlock.fromJson(state);
      
      if (newObj != null) {
        page.objects[idx] = newObj;
        page.objects[idx].updatedAt = TimeService().nowMs();
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
    stroke.updatedAt = TimeService().nowMs();
    final idx = page.objects.indexWhere((o) => o.id == stroke.id);
    if (idx != -1) {
      page.objects[idx] = stroke;
    } else {
      page.objects.add(stroke);
    }
  }
  @override void undo(LocalPage page) {
    final idx = page.objects.indexWhere((o) => o.id == stroke.id);
    if (idx != -1) {
      page.objects[idx].isDeleted = true;
      page.objects[idx].updatedAt = TimeService().nowMs();
    }
  }
}

class DeleteAction extends CanvasAction {
  final List<String> objectIds;
  DeleteAction({required String pageClientId, required int pageNumber, required this.objectIds, int? timestamp}) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'delete';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId,
    'pageNumber': pageNumber,
    'timestamp': timestamp,
    'objectIds': objectIds,
  };

  @override void execute(LocalPage page) {
    final int now = TimeService().nowMs();
    for (var oid in objectIds) {
      final idx = page.objects.indexWhere((o) => o.id == oid);
      if (idx != -1) {
        page.objects[idx].isDeleted = true;
        page.objects[idx].updatedAt = now;
      }
    }
  }
  @override void undo(LocalPage page) {
    final int now = TimeService().nowMs();
    for (var oid in objectIds) {
      final idx = page.objects.indexWhere((o) => o.id == oid);
      if (idx != -1) {
        page.objects[idx].isDeleted = false;
        page.objects[idx].updatedAt = now;
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
    block.updatedAt = TimeService().nowMs();
    final idx = page.objects.indexWhere((o) => o.id == block.id);
    if (idx != -1) {
      page.objects[idx] = block;
    } else {
      page.objects.add(block);
    }
  }
  @override void undo(LocalPage page) {
    final idx = page.objects.indexWhere((o) => o.id == block.id);
    if (idx != -1) {
      page.objects[idx].isDeleted = true;
      page.objects[idx].updatedAt = TimeService().nowMs();
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
    block.updatedAt = TimeService().nowMs();
    final idx = page.objects.indexWhere((o) => o.id == block.id);
    if (idx != -1) {
      page.objects[idx] = block;
    } else {
      page.objects.add(block);
    }
  }
  @override void undo(LocalPage page) {
    final idx = page.objects.indexWhere((o) => o.id == block.id);
    if (idx != -1) {
      page.objects[idx].isDeleted = true;
      page.objects[idx].updatedAt = TimeService().nowMs();
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
    page.isDeleted = false;
    if (lineType != null) page.lineType = lineType;
    if (lineSpacing != null) page.lineSpacing = lineSpacing;
    page.updatedAt = TimeService().nowMs();
  }

  @override void undo(LocalPage page) {
    page.isDeleted = true;
    page.updatedAt = TimeService().nowMs();
  }
}

class DeletePageAction extends CanvasAction {
  final Map<String, dynamic> pageData; 

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
    page.updatedAt = TimeService().nowMs();
  }

  @override void undo(LocalPage page) {
    page.isDeleted = false;
    page.updatedAt = TimeService().nowMs();
  }
}