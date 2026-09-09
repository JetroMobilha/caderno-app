import 'dart:convert';
import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'page_object.dart';

/// 🚀 v10.0: Implementação Imutável de Bloco de Imagem.
class ImageBlock implements PageObject {
  @override
  final String id;
  @override
  final String type = 'image';
  @override
  final String? parentId; // 🚀 v10

  final String imagePath;
  
  @override
  final Offset position;
  final double width;
  final double height;
  @override
  final double rotation;
  
  @override
  final bool isDeleted;
  @override
  final bool deletedInSession;
  @override
  final int updatedAt;
  @override
  final int version;
  @override
  final int? pageNumber; 
  @override
  final String? creatorId;
  @override
  final bool syncedWithCloud;

  @override
  final int zIndex;
  @override
  final bool isLocked;
  @override
  final bool isVisible;
  @override
  final double opacity; // 🚀 v10
  
  @override
  final String? layerId;

  ImageBlock({
    String? id,
    this.parentId,
    required this.imagePath,
    required this.position,
    this.width = 300.0,
    this.height = 200.0,
    this.rotation = 0.0,
    this.isDeleted = false,
    this.deletedInSession = false,
    this.pageNumber, 
    int? updatedAt,
    this.version = 1,
    this.creatorId,
    this.syncedWithCloud = false,
    this.zIndex = 0,
    this.isLocked = false,
    this.isVisible = true,
    this.opacity = 1.0,
    this.layerId,
  }) : id = id ?? const Uuid().v4(),
       updatedAt = updatedAt ?? TimeService().nowMs();

  @override
  Size get size => Size(width, height);

  @override
  ImageBlock copyWith({
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
    String? imagePath,
  }) {
    return ImageBlock(
      id: id ?? this.id,
      parentId: parentId ?? this.parentId,
      imagePath: imagePath ?? this.imagePath,
      position: position ?? this.position,
      width: size?.width ?? this.width,
      height: size?.height ?? this.height,
      rotation: rotation ?? this.rotation,
      isDeleted: isDeleted ?? this.isDeleted,
      deletedInSession: deletedInSession ?? this.deletedInSession,
      pageNumber: pageNumber ?? this.pageNumber,
      updatedAt: updatedAt ?? TimeService().nowMs(),
      version: version ?? (this.version + 1),
      creatorId: creatorId,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      zIndex: zIndex ?? this.zIndex,
      isLocked: isLocked ?? this.isLocked,
      isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
      layerId: layerId ?? this.layerId,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type,
      'parent_id': parentId,
      'dx': double.parse(position.dx.toStringAsFixed(1)),
      'dy': double.parse(position.dy.toStringAsFixed(1)),
      'width': double.parse(width.toStringAsFixed(1)),
      'height': double.parse(height.toStringAsFixed(1)),
      'rotation': double.parse(rotation.toStringAsFixed(2)),
      'image_path': imagePath,
      'is_deleted': isDeleted,
      'deleted_in_session': deletedInSession,
      'page_number': pageNumber,
      'updated_at': updatedAt,
      'version': version,
      'creator_id': creatorId,
      'synced_with_cloud': syncedWithCloud ? 1 : 0,
      'z_index': zIndex,
      'is_locked': isLocked ? 1 : 0,
      'is_visible': isVisible ? 1 : 0,
      'opacity': opacity,
      'layer_id': layerId,
    };
  }

  Future<Map<String, dynamic>> toJsonAsync() async {
    String? base64Image;
    if (!imagePath.startsWith('http')) {
      try {
        if (kIsWeb) {
          if (imagePath.startsWith('blob:')) {
            final response = await http.get(Uri.parse(imagePath));
            if (response.statusCode == 200) base64Image = base64Encode(response.bodyBytes);
          }
        } else {
          final bytes = await io.File(imagePath).readAsBytes();
          base64Image = base64Encode(bytes);
        }
      } catch (e) { debugPrint('⚠️ Erro imagem sync: $e'); }
    }
    final map = toJson();
    map['image_base64'] = base64Image;
    return map;
  }

  factory ImageBlock.fromJson(Map<String, dynamic> json) {
    String path = json['image_path']?.toString() ?? '';
    if (!kIsWeb && json['image_base64'] != null && json['image_base64'].toString().isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(json['image_base64']);
        final tempDir = io.Directory.systemTemp;
        final io.File file = io.File('${tempDir.path}/sync_img_${json['id']}.png');
        file.writeAsBytesSync(bytes);
        path = file.path;
      } catch (e) {}
    }
    return ImageBlock(
      id: json['id']?.toString() ?? const Uuid().v4(),
      parentId: json['parent_id']?.toString(),
      imagePath: path,
      position: Offset((json['dx'] as num?)?.toDouble() ?? 0.0, (json['dy'] as num?)?.toDouble() ?? 0.0),
      width: (json['width'] as num?)?.toDouble() ?? 300.0,
      height: (json['height'] as num?)?.toDouble() ?? 200.0,
      rotation: (json['rotation'] as num?)?.toDouble() ?? 0.0,
      isDeleted: json['is_deleted'] == true || json['is_deleted'] == 1,
      deletedInSession: json['deleted_in_session'] == true || json['deleted_in_session'] == 1,
      pageNumber: json['page_number'] as int?,
      updatedAt: (json['updated_at'] as num?)?.toInt() ?? (json['updatedAt'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      version: int.tryParse(json['version']?.toString() ?? '1') ?? 1,
      creatorId: json['creator_id']?.toString(),
      syncedWithCloud: json['synced_with_cloud'] == null ? true : (json['synced_with_cloud'] == true || json['synced_with_cloud'] == 1),
      zIndex: (json['z_index'] as num?)?.toInt() ?? 0,
      isLocked: json['is_locked'] == true || json['is_locked'] == 1,
      isVisible: json['is_visible'] == null ? true : (json['is_visible'] == true || json['is_visible'] == 1),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      layerId: json['layer_id']?.toString(),
    );
  }

  @override
  ImageBlock clone({String? newId, int? newPageNumber}) {
    return copyWith(
      id: newId ?? const Uuid().v4(),
      pageNumber: newPageNumber ?? pageNumber,
      updatedAt: TimeService().nowMs(),
      version: 1,
      syncedWithCloud: false,
    );
  }
}
