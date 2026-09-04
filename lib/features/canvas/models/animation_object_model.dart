import 'package:flutter/material.dart';
import 'page_object.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import '../../explanations/models/explanation_model.dart';

enum AnimationObjectType { lottie, physics, sequence }

class AnimationObject implements PageObject {
  @override
  final String id;
  @override
  final String type = 'animation';
  
  final AnimationObjectType animationType;
  
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
  
  String? layerId;

  // Propriedades específicas
  String? assetPath;
  bool autoPlay;
  bool isLooping;
  double speed;
  
  // Para persistência de mecanismos (engrenagens, etc.)
  Map<String, dynamic>? configData;

  AnimationObject({
    required this.id,
    required this.animationType,
    required this.position,
    this.size = const Size(100, 100),
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
    this.assetPath,
    this.autoPlay = true,
    this.isLooping = true,
    this.speed = 1.0,
    this.configData,
  }) : updatedAt = updatedAt ?? TimeService().nowMs();

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'animation_type': animationType.name,
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
      'asset_path': assetPath,
      'auto_play': autoPlay ? 1 : 0,
      'is_looping': isLooping ? 1 : 0,
      'speed': speed,
      'config_data': configData,
    };
  }

  factory AnimationObject.fromJson(Map<String, dynamic> json) {
    return AnimationObject(
      id: json['id'],
      animationType: AnimationObjectType.values.firstWhere((e) => e.name == json['animation_type']),
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
      assetPath: json['asset_path'],
      autoPlay: json['auto_play'] == 1,
      isLooping: json['is_looping'] == 1,
      speed: json['speed']?.toDouble() ?? 1.0,
      configData: json['config_data'],
    );
  }

  @override
  AnimationObject clone({String? newId, int? newPageNumber}) {
    return AnimationObject(
      id: newId ?? id,
      animationType: animationType,
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
      assetPath: assetPath,
      autoPlay: autoPlay,
      isLooping: isLooping,
      speed: speed,
      configData: configData != null ? Map.from(configData!) : null,
    );
  }
}
