import 'package:flutter/material.dart';
import 'page_object.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

enum LinkType { internalPage, externalUrl }

class LinkObject implements PageObject {
  @override
  final String id;
  @override
  final String type = 'link';
  
  final LinkType linkType;
  final String? targetPageClientId;
  final String? url;
  String label;
  
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

  // Estilo
  String backgroundColor;
  String textColor;

  LinkObject({
    required this.id,
    required this.linkType,
    this.targetPageClientId,
    this.url,
    this.label = 'Link',
    required this.position,
    this.size = const Size(140, 40),
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
    this.backgroundColor = '#0F4C5C',
    this.textColor = '#FFFFFF',
  }) : updatedAt = updatedAt ?? TimeService().nowMs();

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'link_type': linkType.name,
      'target_page_client_id': targetPageClientId,
      'url': url,
      'label': label,
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
      'bg_color': backgroundColor,
      'text_color': textColor,
    };
  }

  factory LinkObject.fromJson(Map<String, dynamic> json) {
    return LinkObject(
      id: json['id'],
      linkType: LinkType.values.firstWhere((e) => e.name == json['link_type']),
      targetPageClientId: json['target_page_client_id'],
      url: json['url'],
      label: json['label'] ?? 'Link',
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
      backgroundColor: json['bg_color'] ?? '#0F4C5C',
      textColor: json['text_color'] ?? '#FFFFFF',
    );
  }

  @override
  LinkObject clone({String? newId, int? newPageNumber}) {
    return LinkObject(
      id: newId ?? id,
      linkType: linkType,
      targetPageClientId: targetPageClientId,
      url: url,
      label: label,
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
      backgroundColor: backgroundColor,
      textColor: textColor,
    );
  }
}
