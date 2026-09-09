import 'package:flutter/material.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'local_page_model.dart';
import 'stroke_model.dart';
import 'text_block_model.dart';
import 'image_block_model.dart';
import 'shape_model.dart'; 
import 'audio_block_model.dart'; 
import 'animation_object_model.dart'; 
import 'table_model.dart';
import 'link_model.dart';
import 'attachment_model.dart';
import 'page_object.dart';

/// 🚀 v9.0: Ações do Canvas redesenhadas para o paradigma imutável.
abstract class CanvasAction {
  final String pageClientId;
  final int pageNumber;
  final int timestamp; 
  
  CanvasAction(this.pageClientId, this.pageNumber, {int? timestamp}) 
    : timestamp = timestamp ?? TimeService().nowMs();

  LocalPage execute(LocalPage page);
  LocalPage undo(LocalPage page);
  
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
        objectIds: List<String>.from(data['objectIds'] ?? []),
        timestamp: ts,
      );
    } else if (type == 'addText') {
      return AddTextAction(pageClientId: cid, pageNumber: pNum, block: TextBlock.fromJson(data['block']), timestamp: ts);
    } else if (type == 'addImage') {
      return AddImageAction(pageClientId: cid, pageNumber: pNum, block: ImageBlock.fromJson(data['block']), timestamp: ts);
    } else if (type == 'addShape') {
      return AddShapeAction(pageClientId: cid, pageNumber: pNum, shape: ShapeObject.fromJson(data['shape']), timestamp: ts);
    } else if (type == 'addAudio') { 
      return AddAudioAction(pageClientId: cid, pageNumber: pNum, audio: AudioBlock.fromJson(data['audio']), timestamp: ts);
    } else if (type == 'addAnimation') { 
      return AddAnimationAction(pageClientId: cid, pageNumber: pNum, animation: AnimationObject.fromJson(data['animation']), timestamp: ts);
    } else if (type == 'addTable') {
      return AddTableAction(pageClientId: cid, pageNumber: pNum, table: TableObject.fromJson(data['table']), timestamp: ts);
    } else if (type == 'addLink') {
      return AddLinkAction(pageClientId: cid, pageNumber: pNum, link: LinkObject.fromJson(data['link']), timestamp: ts);
    } else if (type == 'addAttachment') {
      return AddAttachmentAction(pageClientId: cid, pageNumber: pNum, attach: AttachmentObject.fromJson(data['attach']), timestamp: ts);
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
    } else if (type == 'pixelErase') {
      return PixelEraseAction(
        pageClientId: cid,
        pageNumber: pNum,
        deletedStrokeIds: List<String>.from(data['deletedIds'] ?? []),
        addedStrokes: (data['addedStrokes'] as List? ?? [])
            .map((s) => Stroke.fromJson(s))
            .toList(),
        timestamp: ts,
      );
    } else if (type == 'group') {
      return GroupAction(
        pageClientId: cid,
        pageNumber: pNum,
        objectIds: List<String>.from(data['objectIds'] ?? []),
        newParentId: data['newParentId'],
        oldParentIds: Map<String, String?>.from(data['oldParentIds'] ?? {}),
        timestamp: ts,
      );
    }
    return null;
  }
}

class GroupAction extends CanvasAction {
  final List<String> objectIds;
  final String? newParentId;
  final Map<String, String?> oldParentIds;

  GroupAction({
    required String pageClientId,
    required int pageNumber,
    required this.objectIds,
    this.newParentId,
    required this.oldParentIds,
    int? timestamp,
  }) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'group';

  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId,
    'pageNumber': pageNumber,
    'timestamp': timestamp,
    'objectIds': objectIds,
    'newParentId': newParentId,
    'oldParentIds': oldParentIds,
  };

  @override
  LocalPage execute(LocalPage page) {
    final now = TimeService().nowMs();
    final newObjects = page.objects.map((o) {
      if (objectIds.contains(o.id)) {
        return o.copyWith(parentId: newParentId, updatedAt: now);
      }
      return o;
    }).toList();
    return page.copyWith(objects: newObjects);
  }

  @override
  LocalPage undo(LocalPage page) {
    final now = TimeService().nowMs();
    final newObjects = page.objects.map((o) {
      if (objectIds.contains(o.id)) {
        return o.copyWith(parentId: oldParentIds[o.id], updatedAt: now);
      }
      return o;
    }).toList();
    return page.copyWith(objects: newObjects);
  }
}

class PixelEraseAction extends CanvasAction {
  final List<String> deletedStrokeIds;
  final List<Stroke> addedStrokes;

  PixelEraseAction({
    required String pageClientId,
    required int pageNumber,
    required this.deletedStrokeIds,
    required this.addedStrokes,
    int? timestamp,
  }) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'pixelErase';

  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId,
    'pageNumber': pageNumber,
    'timestamp': timestamp,
    'deletedIds': deletedStrokeIds,
    'addedStrokes': addedStrokes.map((s) => s.toJson()).toList(),
  };

  @override
  LocalPage execute(LocalPage page) {
    final now = TimeService().nowMs();
    final newObjects = page.objects.map((o) {
      if (deletedStrokeIds.contains(o.id)) {
        return o.copyWith(isDeleted: true, updatedAt: now);
      }
      return o;
    }).toList();
    newObjects.addAll(addedStrokes);
    return page.copyWith(objects: newObjects.cast<PageObject>());
  }

  @override
  LocalPage undo(LocalPage page) {
    final now = TimeService().nowMs();
    final addedIds = addedStrokes.map((s) => s.id).toSet();
    final newObjects = page.objects.where((o) => !addedIds.contains(o.id)).map((o) {
      if (deletedStrokeIds.contains(o.id)) {
        return o.copyWith(isDeleted: false, updatedAt: now);
      }
      return o;
    }).toList();
    return page.copyWith(objects: newObjects.cast<PageObject>());
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

  @override LocalPage execute(LocalPage page) => _applyDelta(page, delta);
  @override LocalPage undo(LocalPage page) => _applyDelta(page, -delta);

  LocalPage _applyDelta(LocalPage page, Offset d) {
    final int now = TimeService().nowMs();
    final newObjects = page.objects.map((o) {
      if (objectIds.contains(o.id)) {
        return o.copyWith(position: o.position + d, updatedAt: now);
      }
      return o;
    }).toList();
    return page.copyWith(objects: newObjects);
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

  @override LocalPage execute(LocalPage page) => _applyState(page, newState);
  @override LocalPage undo(LocalPage page) => _applyState(page, oldState);

  LocalPage _applyState(LocalPage page, Map<String, dynamic> state) {
    final newObjects = page.objects.map((o) {
      if (o.id == objectId) {
        final type = state['type'];
        if (type == 'stroke') return Stroke.fromJson(state);
        if (type == 'text') return TextBlock.fromJson(state);
        if (type == 'image') return ImageBlock.fromJson(state);
        if (type == 'shape') return ShapeObject.fromJson(state);
        if (type == 'audio') return AudioBlock.fromJson(state);
        if (type == 'animation') return AnimationObject.fromJson(state);
        if (type == 'table') return TableObject.fromJson(state);
        if (type == 'link') return LinkObject.fromJson(state);
        if (type == 'attachment') return AttachmentObject.fromJson(state);
      }
      return o;
    }).toList();
    return page.copyWith(objects: newObjects);
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

  @override LocalPage execute(LocalPage page) {
    final updatedStroke = stroke.copyWith(isDeleted: false, updatedAt: TimeService().nowMs());
    final newObjects = List<PageObject>.from(page.objects);
    final idx = newObjects.indexWhere((o) => o.id == updatedStroke.id);
    if (idx != -1) newObjects[idx] = updatedStroke;
    else newObjects.add(updatedStroke);
    return page.copyWith(objects: newObjects);
  }
  @override LocalPage undo(LocalPage page) {
    final newObjects = page.objects.map((o) {
      if (o.id == stroke.id) return o.copyWith(isDeleted: true, updatedAt: TimeService().nowMs());
      return o;
    }).toList();
    return page.copyWith(objects: newObjects);
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

  @override LocalPage execute(LocalPage page) {
    final int now = TimeService().nowMs();
    final newObjects = page.objects.map((o) {
      if (objectIds.contains(o.id)) return o.copyWith(isDeleted: true, updatedAt: now);
      return o;
    }).toList();
    return page.copyWith(objects: newObjects);
  }
  @override LocalPage undo(LocalPage page) {
    final int now = TimeService().nowMs();
    final newObjects = page.objects.map((o) {
      if (objectIds.contains(o.id)) return o.copyWith(isDeleted: false, updatedAt: now);
      return o;
    }).toList();
    return page.copyWith(objects: newObjects);
  }
}

class AddTextAction extends CanvasAction {
  final TextBlock block;
  AddTextAction({required String pageClientId, required int pageNumber, required this.block, int? timestamp}) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'addText';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId, 'pageNumber': pageNumber, 'timestamp': timestamp, 'block': block.toJson()
  };

  @override LocalPage execute(LocalPage page) {
    final updatedBlock = block.copyWith(isDeleted: false, updatedAt: TimeService().nowMs());
    final newObjects = List<PageObject>.from(page.objects);
    final idx = newObjects.indexWhere((o) => o.id == updatedBlock.id);
    if (idx != -1) newObjects[idx] = updatedBlock;
    else newObjects.add(updatedBlock);
    return page.copyWith(objects: newObjects);
  }
  @override LocalPage undo(LocalPage page) {
    final newObjects = page.objects.map((o) {
      if (o.id == block.id) return o.copyWith(isDeleted: true, updatedAt: TimeService().nowMs());
      return o;
    }).toList();
    return page.copyWith(objects: newObjects);
  }
}

class AddImageAction extends CanvasAction {
  final ImageBlock block;
  AddImageAction({required String pageClientId, required int pageNumber, required this.block, int? timestamp}) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'addImage';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId, 'pageNumber': pageNumber, 'timestamp': timestamp, 'block': block.toJson()
  };

  @override LocalPage execute(LocalPage page) {
    final updatedBlock = block.copyWith(isDeleted: false, updatedAt: TimeService().nowMs());
    final newObjects = List<PageObject>.from(page.objects);
    final idx = newObjects.indexWhere((o) => o.id == updatedBlock.id);
    if (idx != -1) newObjects[idx] = updatedBlock;
    else newObjects.add(updatedBlock);
    return page.copyWith(objects: newObjects);
  }
  @override LocalPage undo(LocalPage page) {
    final newObjects = page.objects.map((o) {
      if (o.id == block.id) return o.copyWith(isDeleted: true, updatedAt: TimeService().nowMs());
      return o;
    }).toList();
    return page.copyWith(objects: newObjects);
  }
}

class AddShapeAction extends CanvasAction {
  final ShapeObject shape;
  AddShapeAction({required String pageClientId, required int pageNumber, required this.shape, int? timestamp}) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'addShape';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId, 'pageNumber': pageNumber, 'timestamp': timestamp, 'shape': shape.toJson()
  };

  @override LocalPage execute(LocalPage page) {
    final updatedShape = shape.copyWith(isDeleted: false, updatedAt: TimeService().nowMs());
    final newObjects = List<PageObject>.from(page.objects);
    final idx = newObjects.indexWhere((o) => o.id == updatedShape.id);
    if (idx != -1) newObjects[idx] = updatedShape;
    else newObjects.add(updatedShape);
    return page.copyWith(objects: newObjects);
  }
  @override LocalPage undo(LocalPage page) {
    final newObjects = page.objects.map((o) {
      if (o.id == shape.id) return o.copyWith(isDeleted: true, updatedAt: TimeService().nowMs());
      return o;
    }).toList();
    return page.copyWith(objects: newObjects);
  }
}

class AddAudioAction extends CanvasAction {
  final AudioBlock audio;
  AddAudioAction({required String pageClientId, required int pageNumber, required this.audio, int? timestamp}) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'addAudio';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId, 'pageNumber': pageNumber, 'timestamp': timestamp, 'audio': audio.toJson()
  };

  @override LocalPage execute(LocalPage page) {
    final updatedAudio = audio.copyWith(isDeleted: false, updatedAt: TimeService().nowMs());
    final newObjects = List<PageObject>.from(page.objects);
    final idx = newObjects.indexWhere((o) => o.id == updatedAudio.id);
    if (idx != -1) newObjects[idx] = updatedAudio;
    else newObjects.add(updatedAudio);
    return page.copyWith(objects: newObjects);
  }
  @override LocalPage undo(LocalPage page) {
    final newObjects = page.objects.map((o) {
      if (o.id == audio.id) return o.copyWith(isDeleted: true, updatedAt: TimeService().nowMs());
      return o;
    }).toList();
    return page.copyWith(objects: newObjects);
  }
}

class AddAnimationAction extends CanvasAction {
  final AnimationObject animation;
  AddAnimationAction({required String pageClientId, required int pageNumber, required this.animation, int? timestamp}) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'addAnimation';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId, 'pageNumber': pageNumber, 'timestamp': timestamp, 'animation': animation.toJson()
  };

  @override LocalPage execute(LocalPage page) {
    final updatedAnimation = animation.copyWith(isDeleted: false, updatedAt: TimeService().nowMs());
    final newObjects = List<PageObject>.from(page.objects);
    final idx = newObjects.indexWhere((o) => o.id == updatedAnimation.id);
    if (idx != -1) newObjects[idx] = updatedAnimation;
    else newObjects.add(updatedAnimation);
    return page.copyWith(objects: newObjects);
  }
  @override LocalPage undo(LocalPage page) {
    final newObjects = page.objects.map((o) {
      if (o.id == animation.id) return o.copyWith(isDeleted: true, updatedAt: TimeService().nowMs());
      return o;
    }).toList();
    return page.copyWith(objects: newObjects);
  }
}

class AddTableAction extends CanvasAction {
  final TableObject table;
  AddTableAction({required String pageClientId, required int pageNumber, required this.table, int? timestamp}) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'addTable';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId, 'pageNumber': pageNumber, 'timestamp': timestamp,
    'table': table.toJson()
  };

  @override LocalPage execute(LocalPage page) {
    final updatedTable = table.copyWith(isDeleted: false, updatedAt: TimeService().nowMs());
    final newObjects = List<PageObject>.from(page.objects);
    final idx = newObjects.indexWhere((o) => o.id == updatedTable.id);
    if (idx != -1) newObjects[idx] = updatedTable;
    else newObjects.add(updatedTable);
    return page.copyWith(objects: newObjects);
  }
  @override LocalPage undo(LocalPage page) {
    final newObjects = page.objects.map((o) {
      if (o.id == table.id) return o.copyWith(isDeleted: true, updatedAt: TimeService().nowMs());
      return o;
    }).toList();
    return page.copyWith(objects: newObjects);
  }
}

class AddLinkAction extends CanvasAction {
  final LinkObject link;
  AddLinkAction({required String pageClientId, required int pageNumber, required this.link, int? timestamp}) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'addLink';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId, 'pageNumber': pageNumber, 'timestamp': timestamp,
    'link': link.toJson()
  };

  @override LocalPage execute(LocalPage page) {
    final updatedLink = link.copyWith(isDeleted: false, updatedAt: TimeService().nowMs());
    final newObjects = List<PageObject>.from(page.objects);
    final idx = newObjects.indexWhere((o) => o.id == updatedLink.id);
    if (idx != -1) newObjects[idx] = updatedLink;
    else newObjects.add(updatedLink);
    return page.copyWith(objects: newObjects);
  }
  @override LocalPage undo(LocalPage page) {
    final newObjects = page.objects.map((o) {
      if (o.id == link.id) return o.copyWith(isDeleted: true, updatedAt: TimeService().nowMs());
      return o;
    }).toList();
    return page.copyWith(objects: newObjects);
  }
}

class AddAttachmentAction extends CanvasAction {
  final AttachmentObject attach;
  AddAttachmentAction({required String pageClientId, required int pageNumber, required this.attach, int? timestamp}) : super(pageClientId, pageNumber, timestamp: timestamp);

  @override String get type => 'addAttachment';
  @override Map<String, dynamic> toMap() => {
    'pageClientId': pageClientId, 'pageNumber': pageNumber, 'timestamp': timestamp,
    'attach': attach.toJson()
  };

  @override LocalPage execute(LocalPage page) {
    final updatedAttach = attach.copyWith(isDeleted: false, updatedAt: TimeService().nowMs());
    final newObjects = List<PageObject>.from(page.objects);
    final idx = newObjects.indexWhere((o) => o.id == updatedAttach.id);
    if (idx != -1) newObjects[idx] = updatedAttach;
    else newObjects.add(updatedAttach);
    return page.copyWith(objects: newObjects);
  }
  @override LocalPage undo(LocalPage page) {
    final newObjects = page.objects.map((o) {
      if (o.id == attach.id) return o.copyWith(isDeleted: true, updatedAt: TimeService().nowMs());
      return o;
    }).toList();
    return page.copyWith(objects: newObjects);
  }
}
