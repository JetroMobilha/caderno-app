import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'page_object.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

enum LinkType { internalPage, externalUrl }

/// 🚀 v10.0: Implementação Imutável de Objeto de Link Refatorada.
class LinkObject implements PageObject {
  @override
  final String id;
  @override
  final String type = 'link';
  @override
  final String? parentId; // 🚀 v10
  
  final LinkType linkType;
  final String? targetPageClientId;
  final String? url;
  final String label;
  
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

  final String backgroundColor;
  final String textColor;

  LinkObject({
    required this.id,
    this.parentId,
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
    this.opacity = 1.0,
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
  LinkObject copyWith({
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
    String? label,
    String? backgroundColor,
    String? textColor,
  }) {
    return LinkObject(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      linkType: linkType,
      targetPageClientId: targetPageClientId,
      url: url,
      label: label ?? this.label,
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
      backgroundColor: backgroundColor ?? this.backgroundColor,
      textColor: textColor ?? this.textColor,
    );
  }

  @override
  LinkObject clone({String? newId, int? newPageNumber}) {
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
      'opacity': opacity,
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
      parentId: json['parent_id'],
      linkType: LinkType.values.firstWhere((e) => e.name == json['link_type']),
      targetPageClientId: json['target_page_client_id'],
      url: json['url'],
      label: json['label'] ?? 'Link',
      position: Offset((json['x'] as num?)?.toDouble() ?? 0.0, (json['y'] as num?)?.toDouble() ?? 0.0),
      size: Size((json['width'] as num?)?.toDouble() ?? 140.0, (json['height'] as num?)?.toDouble() ?? 40.0),
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      zIndex: (json['z_index'] as num?)?.toInt() ?? 0,
      isLocked: json['is_locked'] == 1 || json['is_locked'] == true,
      isVisible: json['is_visible'] == null ? true : (json['is_visible'] == 1 || json['is_visible'] == true),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
      version: json['version'] ?? 1,
      isDeleted: json['is_deleted'] == 1 || json['is_deleted'] == true,
      syncedWithCloud: json['synced_with_cloud'] == 1 || json['synced_with_cloud'] == true,
      deletedInSession: json['deleted_in_session'] == 1 || json['deleted_in_session'] == true,
      pageNumber: json['page_number'],
      creatorId: json['creator_id'],
      layerId: json['layer_id'],
      backgroundColor: json['bg_color'] ?? '#0F4C5C',
      textColor: json['text_color'] ?? '#FFFFFF',
    );
  }
}
