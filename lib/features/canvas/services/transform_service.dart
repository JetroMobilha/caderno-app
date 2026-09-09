import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/page_object.dart';
import '../providers/canvas_tool_provider.dart';

/// 🚀 v10.0: Motor de Transformação Centralizado.
/// Fornece lógica matemática para Mover, Redimensionar e Rotacionar qualquer objeto do canvas.
class TransformService {
  
  /// Calcula o novo estado de um objeto após um arraste de redimensionamento.
  static PageObject? calculateResize({
    required PageObject object,
    required HandleType handle,
    required Offset delta,
    required bool keepAspectRatio,
  }) {
    double newX = object.position.dx;
    double newY = object.position.dy;
    double newW = object.size.width;
    double newH = object.size.height;

    // Se o objeto estiver bloqueado, não permite redimensionar
    if (object.isLocked) return null;

    switch (handle) {
      case HandleType.bottomRight:
        newW += delta.dx;
        newH += delta.dy;
        break;
      case HandleType.bottomLeft:
        newX += delta.dx;
        newW -= delta.dx;
        newH += delta.dy;
        break;
      case HandleType.topLeft:
        newX += delta.dx;
        newY += delta.dy;
        newW -= delta.dx;
        newH -= delta.dy;
        break;
      case HandleType.topRight:
        newY += delta.dy;
        newW += delta.dx;
        newH -= delta.dy;
        break;
      case HandleType.middleRight:
        newW += delta.dx;
        break;
      case HandleType.middleLeft:
        newX += delta.dx;
        newW -= delta.dx;
        break;
      case HandleType.topCenter:
        newY += delta.dy;
        newH -= delta.dy;
        break;
      case HandleType.bottomCenter:
        newH += delta.dy;
        break;
      default:
        return null;
    }

    // Aplicar restrições mínimas
    newW = newW.clamp(20.0, 5000.0);
    newH = newH.clamp(20.0, 5000.0);

    return object.copyWith(
      position: Offset(newX, newY),
      size: Size(newW, newH),
    );
  }

  /// Calcula a nova rotação baseada no movimento do cursor em relação ao centro do objeto.
  static double calculateRotation({
    required PageObject object,
    required Offset currentLocalPos,
  }) {
    final center = (object.position & object.size).center;
    final double angle = math.atan2(currentLocalPos.dy - center.dy, currentLocalPos.dx - center.dx);
    
    // Compensar o offset de 90 graus (topo) e a rotação atual
    return angle + (math.pi / 2);
  }

  /// Utilitário para rotacionar um ponto em torno de um centro.
  static Offset rotatePoint(Offset point, Offset center, double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    return Offset(
      center.dx + dx * cosA - dy * sinA,
      center.dy + dx * sinA + dy * cosA,
    );
  }
}
