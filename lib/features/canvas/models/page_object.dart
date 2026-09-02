import 'package:flutter/material.dart';

abstract class PageObject {
  String get id;
  String get type;
  
  Offset get position;
  set position(Offset value);

  Size get size;
  set size(Size value);

  double get rotation;
  set rotation(double value);

  int get zIndex;
  set zIndex(int value);

  bool get isLocked;
  set isLocked(bool value);

  bool get isVisible;
  set isVisible(bool value);

  int get updatedAt;
  set updatedAt(int value);

  int get version;
  set version(int value);

  bool get isDeleted;
  set isDeleted(bool value);

  bool get syncedWithCloud;
  set syncedWithCloud(bool value);

  bool get deletedInSession;
  set deletedInSession(bool value);

  int? get pageNumber;
  set pageNumber(int? value);

  String? get creatorId;

  Map<String, dynamic> toJson();
  
  PageObject clone({String? newId, int? newPageNumber});
}
