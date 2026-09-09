import 'package:flutter/material.dart';
import 'page_object.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

enum AnimationObjectType { lottie, physics, sequence }

/// 🚀 v10.0: Implementação Imutável de Objeto de Animação Refatorada.
class AnimationObject implements PageObject {
  @override
  final String id;
  @override
  final String type = 'animation';
  @override
  final String? parentId; // 🚀 v10
  
  final AnimationObjectType animationType;
  
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

  final String? assetPath;
  final bool autoPlay;
  final bool isLooping;
  final double speed;
  final Map<String, dynamic>? configData;

  AnimationObject({
    required this.id,
    this.parentId,
    required this.animationType,
    required this.position,
    this.size = const Size(100, 100),
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
    this.assetPath,
    this.autoPlay = true,
    this.isLooping = true,
    this.speed = 1.0,
    this.configData,
  }) : updatedAt = updatedAt ?? TimeService().nowMs();

  @override
  AnimationObject copyWith({
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
    bool? autoPlay,
    bool? isLooping,
    double? speed,
    Map<String, dynamic>? configData,
  }) {
    return AnimationObject(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      animationType: animationType,
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
      assetPath: assetPath,
      autoPlay: autoPlay ?? this.autoPlay,
      isLooping: isLooping ?? this.isLooping,
      speed: speed ?? this.speed,
      configData: configData ?? this.configData,
    );
  }

  @override
  AnimationObject clone({String? newId, int? newPageNumber}) {
    return copyWith(
      id: newId ?? id,
      pageNumber: newPageNumber ?? pageNumber,
      updatedAt: TimeService().nowMs(),
      version: 1,
      syncedWithCloud: false,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'parent_id': parentId, 'animation_type': animationType.name,
    'x': position.dx, 'y': position.dy, 'width': size.width, 'height': size.height,
    'rotation': rotation, 'z_index': zIndex, 'is_locked': isLocked ? 1 : 0,
    'is_visible': isVisible ? 1 : 0, 'opacity': opacity, 'updated_at': updatedAt, 'version': version,
    'is_deleted': isDeleted ? 1 : 0, 'synced_with_cloud': syncedWithCloud ? 1 : 0,
    'deleted_in_session': deletedInSession ? 1 : 0, 'page_number': pageNumber,
    'creator_id': creatorId, 'layer_id': layerId, 'asset_path': assetPath,
    'auto_play': autoPlay ? 1 : 0, 'is_looping': isLooping ? 1 : 0,
    'speed': speed, 'config_data': configData,
  };

  factory AnimationObject.fromJson(Map<String, dynamic> json) {
    return AnimationObject(
      id: json['id'],
      parentId: json['parent_id'],
      animationType: AnimationObjectType.values.firstWhere((e) => e.name == json['animation_type']),
      position: Offset(json['x']?.toDouble() ?? 0.0, json['y']?.toDouble() ?? 0.0),
      size: Size(json['width']?.toDouble() ?? 100.0, json['height']?.toDouble() ?? 100.0),
      rotation: json['rotation']?.toDouble() ?? 0.0, zIndex: json['z_index'] ?? 0,
      isLocked: json['is_locked'] == 1, isVisible: json['is_visible'] == 1,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      updatedAt: json['updated_at'], version: json['version'] ?? 1,
      isDeleted: json['is_deleted'] == 1, syncedWithCloud: json['synced_with_cloud'] == 1,
      deletedInSession: json['deleted_in_session'] == 1, pageNumber: json['page_number'],
      creatorId: json['creator_id'], layerId: json['layer_id'],
      assetPath: json['asset_path'], autoPlay: json['auto_play'] == 1,
      isLooping: json['is_looping'] == 1, speed: json['speed']?.toDouble() ?? 1.0,
      configData: json['config_data'],
    );
  }
}
