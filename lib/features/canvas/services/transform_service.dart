import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/page_object.dart';
import '../models/stroke_model.dart'; // 🚀 v10.97
import '../models/shape_model.dart'; // 🚀 v10.97
import '../providers/canvas_tool_provider.dart';

/// 🚀 v10.4: Motor de Transformação Centralizado.
/// Fornece lógica matemática para Mover, Redimensionar e Rotacionar qualquer objeto do canvas.
class TransformService {
  
  /// Calcula os limites combinados de um conjunto de objetos.
  /// 🚀 v10.6: Refinado para maior precisão em coordenadas de documento.
  static Rect getCombinedBounds(List<PageObject> objects) {
    if (objects.isEmpty) return Rect.zero;
    
    double minX = 9999999.0;
    double minY = 9999999.0;
    double maxX = -9999999.0;
    double maxY = -9999999.0;

    for (final obj in objects) {
      Rect bounds = obj.position & obj.size;
      
      // 🚀 v10.97: Inflar limites com base na mancha de tinta real do objeto
      if (obj is Stroke) {
        bounds = bounds.inflate(obj.thickness / 2);
      } else if (obj is ShapeObject) {
        bounds = bounds.inflate(obj.strokeWidth / 2);
      } else {
        // 🚀 v11.0: Margem de segurança unificada para todos os objetos (incluindo animações)
        // para evitar desalinhamentos visuais e inconsistência no hit-test.
        bounds = bounds.inflate(2.0);
      }

      if (bounds.left < minX) minX = bounds.left;
      if (bounds.top < minY) minY = bounds.top;
      if (bounds.right > maxX) maxX = bounds.right;
      if (bounds.bottom > maxY) maxY = bounds.bottom;
    }

    return Rect.fromLTRB(minX, minY, maxX, maxY);
  }

  /// Calcula o novo estado de um objeto após um arraste de redimensionamento.
  static PageObject? calculateResize({
    required PageObject object,
    required HandleType handle,
    required Offset delta,
    bool keepAspectRatio = false,
  }) {
    if (object.isLocked) return null;

    double newX = object.position.dx;
    double newY = object.position.dy;
    double newW = object.size.width;
    double newH = object.size.height;

    final double aspectRatio = object.size.width / object.size.height;

    switch (handle) {
      case HandleType.bottomRight:
        newW += delta.dx;
        newH += delta.dy;
        if (keepAspectRatio) {
          if (newW / newH > aspectRatio) newH = newW / aspectRatio;
          else newW = newH * aspectRatio;
        }
        break;
      case HandleType.bottomLeft:
        newX += delta.dx;
        newW -= delta.dx;
        newH += delta.dy;
        if (keepAspectRatio) {
          if (newW / newH > aspectRatio) newH = newW / aspectRatio;
          else {
            final oldW = newW;
            newW = newH * aspectRatio;
            newX -= (newW - oldW);
          }
        }
        break;
      case HandleType.topLeft:
        newX += delta.dx;
        newY += delta.dy;
        newW -= delta.dx;
        newH -= delta.dy;
        if (keepAspectRatio) {
          if (newW / newH > aspectRatio) {
            final oldH = newH;
            newH = newW / aspectRatio;
            newY -= (newH - oldH);
          } else {
            final oldW = newW;
            newW = newH * aspectRatio;
            newX -= (newW - oldW);
          }
        }
        break;
      case HandleType.topRight:
        newY += delta.dy;
        newW += delta.dx;
        newH -= delta.dy;
        if (keepAspectRatio) {
          if (newW / newH > aspectRatio) {
            final oldH = newH;
            newH = newW / aspectRatio;
            newY -= (newH - oldH);
          } else newW = newH * aspectRatio;
        }
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

  /// 🚀 v10.96: Calcula transformação imersiva (escala e posição) consciente de rotação.
  /// Retorna um Map com 'scale' (Size) e 'positionDelta' (Offset).
  static Map<String, dynamic> calculateImmersiveTransform({
    required PageObject object,
    required HandleType handle,
    required Offset delta,
    bool keepAspectRatio = false,
  }) {
    // 1. Projetar o delta global para o eixo local do objeto rotacionado
    final double cosA = math.cos(-object.rotation);
    final double sinA = math.sin(-object.rotation);
    final double localDX = delta.dx * cosA - delta.dy * sinA;
    final double localDY = delta.dx * sinA + delta.dy * cosA;

    double scaleX = 1.0;
    double scaleY = 1.0;
    double localMoveX = 0.0;
    double localMoveY = 0.0;

    final double oldW = object.size.width;
    final double oldH = object.size.height;

    switch (handle) {
      case HandleType.bottomRight:
        scaleX = (oldW + localDX) / oldW;
        scaleY = (oldH + localDY) / oldH;
        break;
      case HandleType.bottomLeft:
        scaleX = (oldW - localDX) / oldW;
        scaleY = (oldH + localDY) / oldH;
        localMoveX = oldW * (1.0 - scaleX);
        break;
      case HandleType.topLeft:
        scaleX = (oldW - localDX) / oldW;
        scaleY = (oldH - localDY) / oldH;
        localMoveX = oldW * (1.0 - scaleX);
        localMoveY = oldH * (1.0 - scaleY);
        break;
      case HandleType.topRight:
        scaleX = (oldW + localDX) / oldW;
        scaleY = (oldH - localDY) / oldH;
        localMoveY = oldH * (1.0 - scaleY);
        break;
      case HandleType.topCenter:
        scaleY = (oldH - localDY) / oldH;
        localMoveY = oldH * (1.0 - scaleY);
        break;
      case HandleType.bottomCenter:
        scaleY = (oldH + localDY) / oldH;
        break;
      case HandleType.middleLeft:
        scaleX = (oldW - localDX) / oldW;
        localMoveX = oldW * (1.0 - scaleX);
        break;
      case HandleType.middleRight:
        scaleX = (oldW + localDX) / oldW;
        break;
      default:
        break;
    }

    // Aplicar restrições mínimas de escala
    scaleX = scaleX.clamp(20.0 / oldW, 10.0);
    scaleY = scaleY.clamp(20.0 / oldH, 10.0);

    if (keepAspectRatio) {
      final double uniformScale = math.max(scaleX, scaleY);
      scaleX = uniformScale;
      scaleY = uniformScale;
      // Recalcular localMove se necessário para manter a âncora fixa
      if (handle == HandleType.topLeft || handle == HandleType.bottomLeft || handle == HandleType.middleLeft) {
        localMoveX = oldW * (1.0 - scaleX);
      }
      if (handle == HandleType.topLeft || handle == HandleType.topRight || handle == HandleType.topCenter) {
        localMoveY = oldH * (1.0 - scaleY);
      }
    }

    // Converter deslocamento local de volta para global usando a rotação do objeto
    final double gDX = localMoveX * math.cos(object.rotation) - localMoveY * math.sin(object.rotation);
    final double gDY = localMoveX * math.sin(object.rotation) + localMoveY * math.cos(object.rotation);

    return {
      'scale': Size(scaleX, scaleY),
      'positionDelta': Offset(gDX, gDY),
    };
  }

  /// Calcula a nova rotação baseada no movimento do cursor em relação ao centro do objeto.
  static double calculateRotation({
    required PageObject object,
    required Offset currentLocalPos,
  }) {
    final center = (object.position & object.size).center;
    final double angle = math.atan2(currentLocalPos.dy - center.dy, currentLocalPos.dx - center.dx);
    
    // Compensar o offset de 90 graus (topo)
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
