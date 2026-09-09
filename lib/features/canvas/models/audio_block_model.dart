import 'package:flutter/material.dart';
import 'page_object.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

/// 🚀 v10.0: Implementação Imutável de Bloco de Áudio Refatorada.
class AudioBlock implements PageObject {
  @override
  final String id;
  @override
  final String type = 'audio';
  @override
  final String? parentId; // 🚀 v10
  
  final String audioPath;
  final String title;
  final int durationSeconds;
  
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

  AudioBlock({
    required this.id,
    this.parentId,
    required this.audioPath,
    this.title = 'Gravação',
    this.durationSeconds = 0,
    required this.position,
    this.size = const Size(180, 60),
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
  AudioBlock copyWith({
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
    String? title,
  }) {
    return AudioBlock(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      audioPath: audioPath,
      title: title ?? this.title,
      durationSeconds: durationSeconds,
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
  AudioBlock clone({String? newId, int? newPageNumber}) {
    return copyWith(
      id: newId ?? id,
      pageNumber: newPageNumber ?? pageNumber,
      updatedAt: TimeService().nowMs(),
      version: 1,
      syncedWithCloud: false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id, 'type': type, 'parent_id': parentId, 'audio_path': audioPath, 'title': title, 'duration': durationSeconds,
      'x': position.dx, 'y': position.dy, 'width': size.width, 'height': size.height, 'rotation': rotation,
      'z_index': zIndex, 'is_locked': isLocked ? 1 : 0, 'is_visible': isVisible ? 1 : 0, 'opacity': opacity,
      'updated_at': updatedAt, 'version': version, 'is_deleted': isDeleted ? 1 : 0,
      'synced_with_cloud': syncedWithCloud ? 1 : 0, 'deleted_in_session': deletedInSession ? 1 : 0,
      'page_number': pageNumber, 'creator_id': creatorId, 'layer_id': layerId,
    };
  }

  factory AudioBlock.fromJson(Map<String, dynamic> json) {
    return AudioBlock(
      id: json['id'], parentId: json['parent_id'], audioPath: json['audio_path'] ?? '', title: json['title'] ?? 'Gravação',
      durationSeconds: json['duration'] ?? 0,
      position: Offset(json['x']?.toDouble() ?? 0.0, json['y']?.toDouble() ?? 0.0),
      size: Size(json['width']?.toDouble() ?? 180.0, json['height']?.toDouble() ?? 60.0),
      rotation: json['rotation']?.toDouble() ?? 0.0, zIndex: json['z_index'] ?? 0,
      isLocked: json['is_locked'] == 1 || json['is_locked'] == true,
      isVisible: json['is_visible'] == null ? true : (json['is_visible'] == 1 || json['is_visible'] == true),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      updatedAt: json['updated_at'], version: json['version'] ?? 1,
      isDeleted: json['is_deleted'] == 1 || json['is_deleted'] == true,
      syncedWithCloud: json['synced_with_cloud'] == 1 || json['synced_with_cloud'] == true,
      deletedInSession: json['deleted_in_session'] == 1 || json['deleted_in_session'] == true,
      creatorId: json['creator_id'], layerId: json['layer_id'],
    );
  }
}
