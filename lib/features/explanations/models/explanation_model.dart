import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';

enum ExplanationType {
  mathFunction,
  physicsBody,
  engineeringMechanism
}

/// 🚀 v9.4: Modelo Abstrato Imutável para Explicações Dinâmicas.
abstract class ExplanationModel {
  final String id;
  final ExplanationType type;
  final Offset position;
  final double scale;
  final bool isVisible;
  final bool isPlaying;
  final int updatedAt;

  ExplanationModel({
    String? id,
    required this.type,
    required this.position,
    this.scale = 1.0,
    this.isVisible = true,
    this.isPlaying = true,
    int? updatedAt,
  }) : id = id ?? const Uuid().v4(),
       updatedAt = updatedAt ?? TimeService().nowMs();

  Map<String, dynamic> toJson();
  
  ExplanationModel clone({String? newId});
  
  ExplanationModel copyWith({
    String? id,
    Offset? position,
    double? scale,
    bool? isVisible,
    bool? isPlaying,
    int? updatedAt,
  });
}

class MathExplanation extends ExplanationModel {
  final String expression;
  final Color color;
  final double rangeMin;
  final double rangeMax;
  final double animationProgress;

  MathExplanation({
    super.id,
    super.position = Offset.zero,
    super.scale = 1.0,
    super.isVisible = true,
    super.isPlaying = true,
    super.updatedAt,
    required this.expression,
    this.color = Colors.blue,
    this.rangeMin = -10.0,
    this.rangeMax = 10.0,
    this.animationProgress = 0.0,
  }) : super(type: ExplanationType.mathFunction);

  @override
  Map<String, dynamic> toJson() => {
    'id': id, 'type': 'mathFunction', 'x': position.dx, 'y': position.dy,
    'scale': scale, 'expression': expression, 'color': color.toARGB32(),
    'range_min': rangeMin, 'range_max': rangeMax, 'progress': animationProgress,
    'updated_at': updatedAt,
  };

  @override
  MathExplanation copyWith({
    String? id,
    Offset? position,
    double? scale,
    bool? isVisible,
    bool? isPlaying,
    int? updatedAt,
    String? expression,
    Color? color,
    double? rangeMin,
    double? rangeMax,
    double? animationProgress,
  }) {
    return MathExplanation(
      id: id ?? this.id,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      isVisible: isVisible ?? this.isVisible,
      isPlaying: isPlaying ?? this.isPlaying,
      updatedAt: updatedAt ?? TimeService().nowMs(),
      expression: expression ?? this.expression,
      color: color ?? this.color,
      rangeMin: rangeMin ?? this.rangeMin,
      rangeMax: rangeMax ?? this.rangeMax,
      animationProgress: animationProgress ?? this.animationProgress,
    );
  }

  @override
  MathExplanation clone({String? newId}) {
    return copyWith(
      id: newId ?? const Uuid().v4(),
      updatedAt: TimeService().nowMs(),
    );
  }
}

class PhysicsExplanation extends ExplanationModel {
  final double mass;
  final Offset velocity;
  final List<Offset> forces;

  PhysicsExplanation({
    super.id,
    super.position = Offset.zero,
    super.scale = 1.0,
    super.isVisible = true,
    super.isPlaying = true,
    super.updatedAt,
    this.mass = 1.0,
    this.velocity = Offset.zero,
    this.forces = const [],
  }) : super(type: ExplanationType.physicsBody);

  @override
  Map<String, dynamic> toJson() => {
    'id': id, 'type': 'physicsBody', 'x': position.dx, 'y': position.dy,
    'scale': scale, 'mass': mass, 'vx': velocity.dx, 'vy': velocity.dy,
    'forces': forces.map((f) => {'dx': f.dx, 'dy': f.dy}).toList(),
    'updated_at': updatedAt,
  };

  @override
  PhysicsExplanation copyWith({
    String? id,
    Offset? position,
    double? scale,
    bool? isVisible,
    bool? isPlaying,
    int? updatedAt,
    double? mass,
    Offset? velocity,
    List<Offset>? forces,
  }) {
    return PhysicsExplanation(
      id: id ?? this.id,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      isVisible: isVisible ?? this.isVisible,
      isPlaying: isPlaying ?? this.isPlaying,
      updatedAt: updatedAt ?? TimeService().nowMs(),
      mass: mass ?? this.mass,
      velocity: velocity ?? this.velocity,
      forces: forces ?? this.forces,
    );
  }

  @override
  PhysicsExplanation clone({String? newId}) {
    return copyWith(
      id: newId ?? const Uuid().v4(),
      updatedAt: TimeService().nowMs(),
    );
  }
}

class EngineeringExplanation extends ExplanationModel {
  final double radius;
  final double angularVelocity;
  final int toothCount;
  final bool isGear;

  EngineeringExplanation({
    super.id,
    super.position = Offset.zero,
    super.scale = 1.0,
    super.isVisible = true,
    super.isPlaying = true,
    super.updatedAt,
    this.radius = 40.0,
    this.angularVelocity = 1.0,
    this.toothCount = 12,
    this.isGear = true,
  }) : super(type: ExplanationType.engineeringMechanism);

  @override
  Map<String, dynamic> toJson() => {
    'id': id, 'type': 'engineeringMechanism', 'x': position.dx, 'y': position.dy,
    'scale': scale, 'radius': radius, 'angular_velocity': angularVelocity,
    'tooth_count': toothCount, 'is_gear': isGear, 'updated_at': updatedAt,
  };

  @override
  EngineeringExplanation copyWith({
    String? id,
    Offset? position,
    double? scale,
    bool? isVisible,
    bool? isPlaying,
    int? updatedAt,
    double? radius,
    double? angularVelocity,
    int? toothCount,
    bool? isGear,
  }) {
    return EngineeringExplanation(
      id: id ?? this.id,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      isVisible: isVisible ?? this.isVisible,
      isPlaying: isPlaying ?? this.isPlaying,
      updatedAt: updatedAt ?? TimeService().nowMs(),
      radius: radius ?? this.radius,
      angularVelocity: angularVelocity ?? this.angularVelocity,
      toothCount: toothCount ?? this.toothCount,
      isGear: isGear ?? this.isGear,
    );
  }

  @override
  EngineeringExplanation clone({String? newId}) {
    return copyWith(
      id: newId ?? const Uuid().v4(),
      updatedAt: TimeService().nowMs(),
    );
  }
}
