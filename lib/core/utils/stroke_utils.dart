import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart'; // 🚀 Novo
import 'package:caderno_digital_app/core/network/time_service.dart';
import '../../features/canvas/models/stroke_model.dart';

class StrokeUtils {
  /// Divide um traço em múltiplos segmentos se ele intersetar um círculo (borracha).
  static List<Stroke> erasePartOfStroke(Stroke stroke, Offset eraserPos, double radius) {
    if (stroke.points.isEmpty) return [];

    final List<List<Offset>> newSegments = [];
    List<Offset> currentSegment = [];

    for (int i = 0; i < stroke.points.length; i++) {
      final Offset pt = stroke.points[i];
      final double distance = (pt - eraserPos).distance;

      if (distance > radius) {
        currentSegment.add(pt);
      } else {
        if (currentSegment.isNotEmpty) {
          if (currentSegment.length > 1) {
            newSegments.add(List.from(currentSegment));
          }
          currentSegment = [];
        }
      }
    }

    if (currentSegment.length > 1) {
      newSegments.add(currentSegment);
    }

    return newSegments.map((pts) => Stroke(
      id: const Uuid().v4(), // 🆔 UUID consistente para Sync
      color: stroke.color,
      thickness: stroke.thickness,
      points: pts,
      isHighlighter: stroke.isHighlighter,
      brushType: stroke.brushType,
      isSmoothed: stroke.isSmoothed,
      zIndex: stroke.zIndex,
      layerId: stroke.layerId,
      creatorId: stroke.creatorId,
      pageNumber: stroke.pageNumber,
      updatedAt: TimeService().nowMs(),
    )).toList();
  }
}
