import 'package:flutter/material.dart';
import 'page_object.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

class AttachmentObject implements PageObject {
  @override
  final String id;
  @override
  final String type = 'attachment';
  
  final String fileName;
  final String fileExtension;
  final int fileSize;
  final String localPath;
  final String? remoteUrl;
  
  @override
  Offset position;
  @override
  Size size;
  @override
  double rotation;
  @override
  int zIndex;
  @override
  bool isLocked;
  @override
  bool isVisible;
  @override
  int updatedAt;
  @override
  int version;
  @override
  bool isDeleted;
  @override
  bool syncedWithCloud;
  @override
  bool deletedInSession;
  @override
  int? pageNumber;
  @override
  final String? creatorId;
  @override
  String? layerId;

  AttachmentObject({
    required this.id,
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
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
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
      fileName: json['file_name'] ?? 'ficheiro',
      fileExtension: json['file_ext'] ?? '',
      fileSize: json['file_size'] ?? 0,
      localPath: json['local_path'] ?? '',
      remoteUrl: json['remote_url'],
      position: Offset(json['x'], json['y']),
      size: Size(json['width'], json['height']),
      rotation: json['rotation']?.toDouble() ?? 0.0,
      zIndex: json['z_index'] ?? 0,
      isLocked: json['is_locked'] == 1,
      isVisible: json['is_visible'] == 1,
      updatedAt: json['updated_at'],
      version: json['version'] ?? 1,
      isDeleted: json['is_deleted'] == 1,
      syncedWithCloud: json['synced_with_cloud'] == 1,
      deletedInSession: json['deleted_in_session'] == 1,
      pageNumber: json['page_number'],
      creatorId: json['creator_id'],
      layerId: json['layer_id'],
    );
  }

  @override
  AttachmentObject clone({String? newId, int? newPageNumber}) {
    return AttachmentObject(
      id: newId ?? id,
      fileName: fileName,
      fileExtension: fileExtension,
      fileSize: fileSize,
      localPath: localPath,
      remoteUrl: remoteUrl,
      position: position,
      size: size,
      rotation: rotation,
      zIndex: zIndex,
      isLocked: isLocked,
      isVisible: isVisible,
      updatedAt: updatedAt,
      version: version,
      isDeleted: isDeleted,
      syncedWithCloud: false,
      deletedInSession: false,
      pageNumber: newPageNumber ?? pageNumber,
      creatorId: creatorId,
      layerId: layerId,
    );
  }
}
