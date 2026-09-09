import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'page_object.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

/// 🚀 v10.0: Implementação Imutável de Objeto de Anexo Refatorada.
class AttachmentObject implements PageObject {
  @override
  final String id;
  @override
  final String type = 'attachment';
  @override
  final String? parentId; // 🚀 v10
  
  final String fileName;
  final String fileExtension;
  final int fileSize;
  final String localPath;
  final String? remoteUrl;
  
  @override
  final Offset position;
  @override
  final Size size;
  @override
  final double rotation;
  @override
  final int zIndex;
  @override
  final bool isLocked;
  @override
  final bool isVisible;
  @override
  final double opacity; // 🚀 v10
  @override
  final int updatedAt;
  @override
  final int version;
  @override
  final bool isDeleted;
  @override
  final bool syncedWithCloud;
  @override
  final bool deletedInSession;
  @override
  final int? pageNumber;
  @override
  final String? creatorId;
  @override
  final String? layerId;

  AttachmentObject({
    required this.id,
    this.parentId,
    required this.fileName,
    required this.fileExtension,
    this.fileSize = 0,
    required this.localPath,
    this.remoteUrl,
    required this.position,
    this.size = const Size(180, 50),
    this.rotation = 0.0,
    this.zIndex = 0,
    this.isLocked = false,
    this.isVisible = true,
    this.opacity = 1.0,
    int? updatedAt,
    this.version = 1,
    this.isDeleted = false,
    this.syncedWithCloud = false,
    this.deletedInSession = false,
    this.pageNumber,
    this.creatorId,
    this.layerId,
  }) : updatedAt = updatedAt ?? TimeService().nowMs();

  @override
  AttachmentObject copyWith({
    String? id,
    String? parentId,
    Offset? position,
    Size? size,
    double? rotation,
    int? zIndex,
    bool? isLocked,
    bool? isVisible,
    double? opacity,
    int? updatedAt,
    int? version,
    bool? isDeleted,
    bool? syncedWithCloud,
    bool? deletedInSession,
    int? pageNumber,
    String? layerId,
  }) {
    return AttachmentObject(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      fileName: fileName,
      fileExtension: fileExtension,
      fileSize: fileSize,
      localPath: localPath,
      remoteUrl: remoteUrl,
      position: position ?? this.position,
      size: size ?? this.size,
      rotation: rotation ?? this.rotation,
      zIndex: zIndex ?? this.zIndex,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
      updatedAt: updatedAt ?? TimeService().nowMs(),
      version: version ?? (this.version + 1),
      isDeleted: isDeleted ?? this.isDeleted,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      deletedInSession: deletedInSession ?? this.deletedInSession,
      pageNumber: pageNumber ?? this.pageNumber,
      creatorId: creatorId,
      layerId: layerId ?? this.layerId,
    );
  }

  @override
  AttachmentObject clone({String? newId, int? newPageNumber}) {
    return copyWith(
      id: newId ?? const Uuid().v4(),
      pageNumber: newPageNumber ?? pageNumber,
      updatedAt: TimeService().nowMs(),
      version: 1,
      syncedWithCloud: false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'parent_id': parentId,
      'file_name': fileName,
      'file_ext': fileExtension,
      'file_size': fileSize,
      'local_path': localPath,
      'remote_url': remoteUrl,
      'x': position.dx,
      'y': position.dy,
      'width': size.width,
      'height': size.height,
      'rotation': rotation,
      'z_index': zIndex,
      'is_locked': isLocked ? 1 : 0,
      'is_visible': isVisible ? 1 : 0,
      'opacity': opacity,
      'updated_at': updatedAt,
      'version': version,
      'is_deleted': isDeleted ? 1 : 0,
      'synced_with_cloud': syncedWithCloud ? 1 : 0,
      'deleted_in_session': deletedInSession ? 1 : 0,
      'page_number': pageNumber,
      'creator_id': creatorId,
      'layer_id': layerId,
    };
  }

  factory AttachmentObject.fromJson(Map<String, dynamic> json) {
    return AttachmentObject(
      id: json['id'],
      parentId: json['parent_id'],
      fileName: json['file_name'] ?? 'ficheiro',
      fileExtension: json['file_ext'] ?? '',
      fileSize: json['file_size'] ?? 0,
      localPath: json['local_path'] ?? '',
      remoteUrl: json['remote_url'],
      position: Offset((json['x'] as num?)?.toDouble() ?? 0.0, (json['y'] as num?)?.toDouble() ?? 0.0),
      size: Size((json['width'] as num?)?.toDouble() ?? 180.0, (json['height'] as num?)?.toDouble() ?? 50.0),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      zIndex: (json['z_index'] as num?)?.toInt() ?? 0,
      isLocked: json['is_locked'] == 1,
      isVisible: json['is_visible'] == 1,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
      version: json['version'] ?? 1,
      isDeleted: json['is_deleted'] == 1,
      syncedWithCloud: json['synced_with_cloud'] == 1,
      deletedInSession: json['deleted_in_session'] == 1,
      pageNumber: json['page_number'],
      creatorId: json['creator_id'],
      layerId: json['layer_id'],
    );
  }
}
