import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import '../../features/canvas/models/stroke_model.dart';

class StrokeUtils {
  /// Divide um traço em múltiplos segmentos se ele intersetar um círculo (borracha).
  /// Corta com precisão geométrica nos pontos de interseção exatos do perímetro do raio.
  static List<Stroke> erasePartOfStroke(Stroke stroke, Offset eraserPos, double radius) {
    if (stroke.points.isEmpty) return [];

    final double R = radius;
    final List<List<Offset>> newSegments = [];
    List<Offset> currentSegment = [];

    for (int i = 0; i < stroke.points.length; i++) {
      final Offset pt = stroke.points[i];
      final bool ptInside = (pt - eraserPos).distance <= R;

      if (i == 0) {
        if (!ptInside) {
          currentSegment.add(pt);
        }
        continue;
      }

      final Offset prevPt = stroke.points[i - 1];
      final bool prevInside = (prevPt - eraserPos).distance <= R;

      final Offset V = pt - prevPt;
      final Offset D = prevPt - eraserPos;
      final double a = V.dx * V.dx + V.dy * V.dy;

      if (a == 0) {
        if (!ptInside && currentSegment.isEmpty) {
          currentSegment.add(pt);
        }
        continue;
      }

      final double b = 2 * (D.dx * V.dx + D.dy * V.dy);
      final double c = D.dx * D.dx + D.dy * D.dy - R * R;
      final double disc = b * b - 4 * a * c;

      final List<double> validTs = [];
      if (disc >= 0) {
        final double sqrtDisc = math.sqrt(disc);
        final double t1 = (-b - sqrtDisc) / (2 * a);
        final double t2 = (-b + sqrtDisc) / (2 * a);
        if (t1 >= 0.001 && t1 <= 0.999) validTs.add(t1);
        if (t2 >= 0.001 && t2 <= 0.999) validTs.add(t2);
      }

      if (!prevInside && !ptInside) {
        if (validTs.length == 2) {
          // O segmento cruza o círculo entrando por t1 e saindo por t2
          final Offset iEnter = prevPt + V * validTs[0];
          final Offset iExit = prevPt + V * validTs[1];
          currentSegment.add(iEnter);
          if (currentSegment.length > 1) {
            newSegments.add(List<Offset>.from(currentSegment));
          }
          currentSegment = [iExit, pt];
        } else {
          currentSegment.add(pt);
        }
      } else if (!prevInside && ptInside) {
        // Entrando no círculo
        if (validTs.isNotEmpty) {
          final Offset iEnter = prevPt + V * validTs.first;
          currentSegment.add(iEnter);
        }
        if (currentSegment.length > 1) {
          newSegments.add(List<Offset>.from(currentSegment));
        }
        currentSegment = [];
      } else if (prevInside && !ptInside) {
        // Saindo do círculo
        if (validTs.isNotEmpty) {
          final Offset iExit = prevPt + V * validTs.last;
          currentSegment = [iExit, pt];
        } else {
          currentSegment = [pt];
        }
      } else {
        // Ambos dentro do círculo
        currentSegment = [];
      }
    }

    if (currentSegment.length > 1) {
      newSegments.add(currentSegment);
    }

    if (newSegments.isEmpty) return [];

    // Se o resultado for 1 único segmento idêntico ao original, mantemos o traço intacto
    if (newSegments.length == 1 && listEquals(newSegments.first, stroke.points)) {
      return [stroke];
    }

    return newSegments.map((pts) => Stroke(
      id: const Uuid().v4(),
      color: stroke.color,
      thickness: stroke.thickness,
      points: pts,
      isHighlighter: stroke.isHighlighter,
      brushType: stroke.brushType,
      zIndex: stroke.zIndex,
      layerId: stroke.layerId,
      creatorId: stroke.creatorId,
      pageNumber: stroke.pageNumber,
      updatedAt: TimeService().nowMs(),
    )).toList();
  }
}
