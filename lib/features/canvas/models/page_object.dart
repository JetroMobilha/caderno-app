import 'package:flutter/material.dart';

/// 🚀 v10.0: Interface base para todos os objetos do canvas.
/// Suporta hierarquia (parentId), estados de exibição (isVisible, opacity) 
/// e segurança (isLocked).
abstract class PageObject {
  String get id;
  String get type;
  String? get parentId; // 🚀 v10: Suporte a Grupos
  
  Offset get position;
  Size get size;
  double get rotation;
  int get zIndex;
  
  bool get isLocked;
  bool get isVisible;
  double get opacity; // 🚀 v10: Transparência global do objeto
  
  int get updatedAt;
  int get version;
  bool get isDeleted;
  bool get syncedWithCloud;
  bool get deletedInSession;
  int? get pageNumber;
  String? get creatorId;
  String? get layerId;

  Map<String, dynamic> toJson();
  
  PageObject clone({String? newId, int? newPageNumber});
  
  PageObject copyWith({
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
  });
}
