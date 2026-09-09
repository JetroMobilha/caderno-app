import 'package:flutter/material.dart';
import 'stroke_model.dart';
import 'text_block_model.dart';
import 'image_block_model.dart';
import 'shape_model.dart';
import 'table_model.dart';
import 'link_model.dart';
import 'attachment_model.dart';
import 'audio_block_model.dart';
import 'animation_object_model.dart';
import 'local_page_model.dart';
import 'page_object.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

/// 🚀 v10.1: Sistema de Ações de Canvas Imutáveis para Undo/Redo e Colaboração.
abstract class CanvasAction {
  final String pageClientId;
  final int pageNumber;
  final int timestamp;

  CanvasAction({
    required this.pageClientId,
    required this.pageNumber,
    int? timestamp,
  }) : timestamp = timestamp ?? TimeService().nowMs();

  LocalPage execute(LocalPage page);
  LocalPage undo(LocalPage page);

  Map<String, dynamic> toMap();

  static CanvasAction? fromMap(String type, Map<String, dynamic> data) {
    switch (type) {
      case 'add_stroke': return AddStrokeAction.fromMap(data);
      case 'add_text': return AddTextAction.fromMap(data);
      case 'delete': return DeleteAction.fromMap(data);
      case 'move': return MoveAction.fromMap(data);
      case 'update_object': return UpdateObjectAction.fromMap(data);
      case 'group': return GroupAction.fromMap(data);
      default: return null;
    }
  }
}

class AddStrokeAction extends CanvasAction {
  final Stroke stroke;
  AddStrokeAction({required super.pageClientId, required super.pageNumber, required this.stroke});

  @override
  LocalPage execute(LocalPage page) {
    final newObjects = List<PageObject>.from(page.objects)..add(stroke);
    return page.copyWith(objects: newObjects, updatedAt: timestamp);
  }

  @override
  LocalPage undo(LocalPage page) {
    final newObjects = page.objects.where((o) => o.id != stroke.id).toList();
    return page.copyWith(objects: newObjects, updatedAt: timestamp);
  }

  @override
  Map<String, dynamic> toMap() => {'type': 'add_stroke', 'page_client_id': pageClientId, 'page_number': pageNumber, 'stroke': stroke.toJson()};
  factory AddStrokeAction.fromMap(Map<String, dynamic> map) => AddStrokeAction(pageClientId: map['page_client_id'], pageNumber: map['page_number'], stroke: Stroke.fromJson(map['stroke']));
}

class AddTextAction extends CanvasAction {
  final TextBlock block;
  AddTextAction({required super.pageClientId, required super.pageNumber, required this.block});
  @override
  LocalPage execute(LocalPage page) => page.copyWith(objects: List.from(page.objects)..add(block), updatedAt: timestamp);
  @override
  LocalPage undo(LocalPage page) => page.copyWith(objects: page.objects.where((o) => o.id != block.id).toList(), updatedAt: timestamp);
  @override
  Map<String, dynamic> toMap() => {'type': 'add_text', 'page_client_id': pageClientId, 'page_number': pageNumber, 'block': block.toJson()};
  factory AddTextAction.fromMap(Map<String, dynamic> map) => AddTextAction(pageClientId: map['page_client_id'], pageNumber: map['page_number'], block: TextBlock.fromJson(map['block']));
}

class AddImageAction extends CanvasAction {
  final ImageBlock block;
  AddImageAction({required super.pageClientId, required super.pageNumber, required this.block});
  @override
  LocalPage execute(LocalPage page) => page.copyWith(objects: List.from(page.objects)..add(block), updatedAt: timestamp);
  @override
  LocalPage undo(LocalPage page) => page.copyWith(objects: page.objects.where((o) => o.id != block.id).toList(), updatedAt: timestamp);
  @override
  Map<String, dynamic> toMap() => {'type': 'add_image', 'page_client_id': pageClientId, 'page_number': pageNumber, 'block': block.toJson()};
  factory AddImageAction.fromMap(Map<String, dynamic> map) => AddImageAction(pageClientId: map['page_client_id'], pageNumber: map['page_number'], block: ImageBlock.fromJson(map['block']));
}

class AddShapeAction extends CanvasAction {
  final ShapeObject shape;
  AddShapeAction({required super.pageClientId, required super.pageNumber, required this.shape});
  @override
  LocalPage execute(LocalPage page) => page.copyWith(objects: List.from(page.objects)..add(shape), updatedAt: timestamp);
  @override
  LocalPage undo(LocalPage page) => page.copyWith(objects: page.objects.where((o) => o.id != shape.id).toList(), updatedAt: timestamp);
  @override
  Map<String, dynamic> toMap() => {'type': 'add_shape', 'page_client_id': pageClientId, 'page_number': pageNumber, 'shape': shape.toJson()};
  factory AddShapeAction.fromMap(Map<String, dynamic> map) => AddShapeAction(pageClientId: map['page_client_id'], pageNumber: map['page_number'], shape: ShapeObject.fromJson(map['shape']));
}

class AddAudioAction extends CanvasAction {
  final AudioBlock audio;
  AddAudioAction({required super.pageClientId, required super.pageNumber, required this.audio});
  @override
  LocalPage execute(LocalPage page) => page.copyWith(objects: List.from(page.objects)..add(audio), updatedAt: timestamp);
  @override
  LocalPage undo(LocalPage page) => page.copyWith(objects: page.objects.where((o) => o.id != audio.id).toList(), updatedAt: timestamp);
  @override
  Map<String, dynamic> toMap() => {'type': 'add_audio', 'page_client_id': pageClientId, 'page_number': pageNumber, 'audio': audio.toJson()};
  factory AddAudioAction.fromMap(Map<String, dynamic> map) => AddAudioAction(pageClientId: map['page_client_id'], pageNumber: map['page_number'], audio: AudioBlock.fromJson(map['audio']));
}

class AddAnimationAction extends CanvasAction {
  final AnimationObject animation;
  AddAnimationAction({required super.pageClientId, required super.pageNumber, required this.animation});
  @override
  LocalPage execute(LocalPage page) => page.copyWith(objects: List.from(page.objects)..add(animation), updatedAt: timestamp);
  @override
  LocalPage undo(LocalPage page) => page.copyWith(objects: page.objects.where((o) => o.id != animation.id).toList(), updatedAt: timestamp);
  @override
  Map<String, dynamic> toMap() => {'type': 'add_animation', 'page_client_id': pageClientId, 'page_number': pageNumber, 'animation': animation.toJson()};
  factory AddAnimationAction.fromMap(Map<String, dynamic> map) => AddAnimationAction(pageClientId: map['page_client_id'], pageNumber: map['page_number'], animation: AnimationObject.fromJson(map['animation']));
}

class AddTableAction extends CanvasAction {
  final TableObject table;
  AddTableAction({required super.pageClientId, required super.pageNumber, required this.table});
  @override
  LocalPage execute(LocalPage page) => page.copyWith(objects: List.from(page.objects)..add(table), updatedAt: timestamp);
  @override
  LocalPage undo(LocalPage page) => page.copyWith(objects: page.objects.where((o) => o.id != table.id).toList(), updatedAt: timestamp);
  @override
  Map<String, dynamic> toMap() => {'type': 'add_table', 'page_client_id': pageClientId, 'page_number': pageNumber, 'table': table.toJson()};
  factory AddTableAction.fromMap(Map<String, dynamic> map) => AddTableAction(pageClientId: map['page_client_id'], pageNumber: map['page_number'], table: TableObject.fromJson(map['table']));
}

class AddLinkAction extends CanvasAction {
  final LinkObject link;
  AddLinkAction({required super.pageClientId, required super.pageNumber, required this.link});
  @override
  LocalPage execute(LocalPage page) => page.copyWith(objects: List.from(page.objects)..add(link), updatedAt: timestamp);
  @override
  LocalPage undo(LocalPage page) => page.copyWith(objects: page.objects.where((o) => o.id != link.id).toList(), updatedAt: timestamp);
  @override
  Map<String, dynamic> toMap() => {'type': 'add_link', 'page_client_id': pageClientId, 'page_number': pageNumber, 'link': link.toJson()};
  factory AddLinkAction.fromMap(Map<String, dynamic> map) => AddLinkAction(pageClientId: map['page_client_id'], pageNumber: map['page_number'], link: LinkObject.fromJson(map['link']));
}

class AddAttachmentAction extends CanvasAction {
  final AttachmentObject attach;
  AddAttachmentAction({required super.pageClientId, required super.pageNumber, required this.attach});
  @override
  LocalPage execute(LocalPage page) => page.copyWith(objects: List.from(page.objects)..add(attach), updatedAt: timestamp);
  @override
  LocalPage undo(LocalPage page) => page.copyWith(objects: page.objects.where((o) => o.id != attach.id).toList(), updatedAt: timestamp);
  @override
  Map<String, dynamic> toMap() => {'type': 'add_attachment', 'page_client_id': pageClientId, 'page_number': pageNumber, 'attach': attach.toJson()};
  factory AddAttachmentAction.fromMap(Map<String, dynamic> map) => AddAttachmentAction(pageClientId: map['page_client_id'], pageNumber: map['page_number'], attach: AttachmentObject.fromJson(map['attach']));
}

class DeleteAction extends CanvasAction {
  final List<String> objectIds;
  DeleteAction({required super.pageClientId, required super.pageNumber, required this.objectIds});
  @override
  LocalPage execute(LocalPage page) => page.copyWith(objects: page.objects.map((o) => objectIds.contains(o.id) ? o.copyWith(isDeleted: true, updatedAt: timestamp) : o).toList(), updatedAt: timestamp);
  @override
  LocalPage undo(LocalPage page) => page.copyWith(objects: page.objects.map((o) => objectIds.contains(o.id) ? o.copyWith(isDeleted: false, updatedAt: timestamp) : o).toList(), updatedAt: timestamp);
  @override
  Map<String, dynamic> toMap() => {'type': 'delete', 'page_client_id': pageClientId, 'page_number': pageNumber, 'object_ids': objectIds};
  factory DeleteAction.fromMap(Map<String, dynamic> map) => DeleteAction(pageClientId: map['page_client_id'], pageNumber: map['page_number'], objectIds: List<String>.from(map['object_ids']));
}

class MoveAction extends CanvasAction {
  final List<String> objectIds;
  final Offset delta;
  MoveAction({required super.pageClientId, required super.pageNumber, required this.objectIds, required this.delta});
  @override
  LocalPage execute(LocalPage page) => page.copyWith(objects: page.objects.map((o) => objectIds.contains(o.id) ? o.copyWith(position: o.position + delta, updatedAt: timestamp) : o).toList(), updatedAt: timestamp);
  @override
  LocalPage undo(LocalPage page) => page.copyWith(objects: page.objects.map((o) => objectIds.contains(o.id) ? o.copyWith(position: o.position - delta, updatedAt: timestamp) : o).toList(), updatedAt: timestamp);
  @override
  Map<String, dynamic> toMap() => {'type': 'move', 'page_client_id': pageClientId, 'page_number': pageNumber, 'object_ids': objectIds, 'dx': delta.dx, 'dy': delta.dy};
  factory MoveAction.fromMap(Map<String, dynamic> map) => MoveAction(pageClientId: map['page_client_id'], pageNumber: map['page_number'], objectIds: List<String>.from(map['object_ids']), delta: Offset(map['dx'], map['dy']));
}

class UpdateObjectAction extends CanvasAction {
  final String objectId;
  final Map<String, dynamic> oldState;
  final Map<String, dynamic> newState;
  UpdateObjectAction({required super.pageClientId, required super.pageNumber, required this.objectId, required this.oldState, required this.newState});
  @override
  LocalPage execute(LocalPage page) => page.copyWith(objects: page.objects.map((o) => o.id == objectId ? _reconstruct(o, newState) : o).toList(), updatedAt: timestamp);
  @override
  LocalPage undo(LocalPage page) => page.copyWith(objects: page.objects.map((o) => o.id == objectId ? _reconstruct(o, oldState) : o).toList(), updatedAt: timestamp);
  PageObject _reconstruct(PageObject original, Map<String, dynamic> json) {
    if (original is Stroke) return Stroke.fromJson(json);
    if (original is TextBlock) return TextBlock.fromJson(json);
    if (original is ImageBlock) return ImageBlock.fromJson(json);
    if (original is ShapeObject) return ShapeObject.fromJson(json);
    if (original is TableObject) return TableObject.fromJson(json);
    if (original is LinkObject) return LinkObject.fromJson(json);
    if (original is AttachmentObject) return AttachmentObject.fromJson(json);
    if (original is AudioBlock) return AudioBlock.fromJson(json);
    if (original is AnimationObject) return AnimationObject.fromJson(json);
    return original;
  }
  @override
  Map<String, dynamic> toMap() => {'type': 'update_object', 'page_client_id': pageClientId, 'page_number': pageNumber, 'object_id': objectId, 'old_state': oldState, 'new_state': newState};
  factory UpdateObjectAction.fromMap(Map<String, dynamic> map) => UpdateObjectAction(pageClientId: map['page_client_id'], pageNumber: map['page_number'], objectId: map['object_id'], oldState: map['old_state'], newState: map['new_state']);
}

class PixelEraseAction extends CanvasAction {
  final List<String> deletedStrokeIds;
  final List<Stroke> addedStrokes;
  PixelEraseAction({required super.pageClientId, required super.pageNumber, required this.deletedStrokeIds, required this.addedStrokes});
  @override
  LocalPage execute(LocalPage page) {
    var objs = page.objects.map((o) => deletedStrokeIds.contains(o.id) ? o.copyWith(isDeleted: true, updatedAt: timestamp) : o).toList();
    objs.addAll(addedStrokes);
    return page.copyWith(objects: objs, updatedAt: timestamp);
  }
  @override
  LocalPage undo(LocalPage page) {
    var addedIds = addedStrokes.map((s) => s.id).toSet();
    var objs = page.objects.where((o) => !addedIds.contains(o.id)).toList();
    objs = objs.map((o) => deletedStrokeIds.contains(o.id) ? o.copyWith(isDeleted: false, updatedAt: timestamp) : o).toList();
    return page.copyWith(objects: objs, updatedAt: timestamp);
  }
  @override
  Map<String, dynamic> toMap() => {'type': 'pixel_erase', 'page_client_id': pageClientId, 'page_number': pageNumber, 'deleted_ids': deletedStrokeIds, 'added_strokes': addedStrokes.map((s) => s.toJson()).toList()};
  factory PixelEraseAction.fromMap(Map<String, dynamic> map) => PixelEraseAction(pageClientId: map['page_client_id'], pageNumber: map['page_number'], deletedStrokeIds: List<String>.from(map['deleted_ids']), addedStrokes: (map['added_strokes'] as List).map((s) => Stroke.fromJson(s)).toList());
}

/// 🚀 v10.1: Ação de Agrupamento/Desagrupamento.
class GroupAction extends CanvasAction {
  final List<String> objectIds;
  final String? newParentId;
  final Map<String, String?> oldParentIds;

  GroupAction({
    required super.pageClientId,
    required super.pageNumber,
    required this.objectIds,
    required this.newParentId,
    required this.oldParentIds,
  });

  @override
  LocalPage execute(LocalPage page) {
    final updatedObjects = page.objects.map((o) {
      if (objectIds.contains(o.id)) {
        return o.copyWith(parentId: newParentId, updatedAt: timestamp);
      }
      return o;
    }).toList();
    return page.copyWith(objects: updatedObjects, updatedAt: timestamp);
  }

  @override
  LocalPage undo(LocalPage page) {
    final updatedObjects = page.objects.map((o) {
      if (objectIds.contains(o.id)) {
        return o.copyWith(parentId: oldParentIds[o.id], updatedAt: timestamp);
      }
      return o;
    }).toList();
    return page.copyWith(objects: updatedObjects, updatedAt: timestamp);
  }

  @override
  Map<String, dynamic> toMap() => {
    'type': 'group',
    'page_client_id': pageClientId,
    'page_number': pageNumber,
    'object_ids': objectIds,
    'new_parent_id': newParentId,
    'old_parent_ids': oldParentIds,
  };

  factory GroupAction.fromMap(Map<String, dynamic> map) => GroupAction(
    pageClientId: map['page_client_id'],
    pageNumber: map['page_number'],
    objectIds: List<String>.from(map['object_ids']),
    newParentId: map['new_parent_id'],
    oldParentIds: Map<String, String?>.from(map['old_parent_ids']),
  );
}
