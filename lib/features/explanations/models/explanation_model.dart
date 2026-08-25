import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

enum ExplanationType {
  mathFunction,
  physicsBody,
  engineeringMechanism
}

abstract class ExplanationModel {
  final String id;
  final ExplanationType type;
  final Offset position;
  final double scale;
  final bool isVisible;
  final bool isPlaying;

  ExplanationModel({
    String? id,
    required this.type,
    required this.position,
    this.scale = 1.0,
    this.isVisible = true,
    this.isPlaying = true,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toJson();
}

class MathExplanation extends ExplanationModel {
  final String expression; // ex: "sin(x)"
  final Color color;
  final double rangeMin;
  final double rangeMax;
  final double animationProgress; // 0.0 a 1.0

  MathExplanation({
    super.id,
    super.position = Offset.zero,
    super.scale = 1.0,
    super.isVisible = true,
    super.isPlaying = true,
    required this.expression,
    this.color = Colors.blue,
    this.rangeMin = -10.0,
    this.rangeMax = 10.0,
    this.animationProgress = 0.0,
  }) : super(type: ExplanationType.mathFunction);

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'mathFunction',
    'x': position.dx,
    'y': position.dy,
    'scale': scale,
    'expression': expression,
    'color': color.value,
    'range_min': rangeMin,
    'range_max': rangeMax,
    'progress': animationProgress,
  };

  MathExplanation copyWith({
    Offset? position,
    double? scale,
    bool? isVisible,
    bool? isPlaying,
    String? expression,
    Color? color,
    double? rangeMin,
    double? rangeMax,
    double? animationProgress,
  }) {
    return MathExplanation(
      id: id,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      isVisible: isVisible ?? this.isVisible,
      isPlaying: isPlaying ?? this.isPlaying,
      expression: expression ?? this.expression,
      color: color ?? this.color,
      rangeMin: rangeMin ?? this.rangeMin,
      rangeMax: rangeMax ?? this.rangeMax,
      animationProgress: animationProgress ?? this.animationProgress,
    );
  }
}

class PhysicsExplanation extends ExplanationModel {
  final double mass;
  final Offset velocity;
  final List<Offset> forces; // Lista de vetores de força

  PhysicsExplanation({
    super.id,
    super.position = Offset.zero,
    super.scale = 1.0,
    super.isVisible = true,
    super.isPlaying = true,
    this.mass = 1.0,
    this.velocity = Offset.zero,
    this.forces = const [],
  }) : super(type: ExplanationType.physicsBody);

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'physicsBody',
    'x': position.dx,
    'y': position.dy,
    'scale': scale,
    'mass': mass,
    'vx': velocity.dx,
    'vy': velocity.dy,
    'forces': forces.map((f) => {'dx': f.dx, 'dy': f.dy}).toList(),
  };

  PhysicsExplanation copyWith({
    Offset? position,
    double? scale,
    bool? isVisible,
    bool? isPlaying,
    double? mass,
    Offset? velocity,
    List<Offset>? forces,
  }) {
    return PhysicsExplanation(
      id: id,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      isVisible: isVisible ?? this.isVisible,
      isPlaying: isPlaying ?? this.isPlaying,
      mass: mass ?? this.mass,
      velocity: velocity ?? this.velocity,
      forces: forces ?? this.forces,
    );
  }
}

class EngineeringExplanation extends ExplanationModel {
  final double radius;
  final double angularVelocity; // rad/s
  final int toothCount; // Para engrenagens
  final bool isGear; // se false, é uma polia simples

  EngineeringExplanation({
    super.id,
    super.position = Offset.zero,
    super.scale = 1.0,
    super.isVisible = true,
    super.isPlaying = true,
    this.radius = 40.0,
    this.angularVelocity = 1.0,
    this.toothCount = 12,
    this.isGear = true,
  }) : super(type: ExplanationType.engineeringMechanism);

  @override
  Map<String, dynamic> toJson() => {
    'id': id,
    'type': 'engineeringMechanism',
    'x': position.dx,
    'y': position.dy,
    'scale': scale,
    'radius': radius,
    'angular_velocity': angularVelocity,
    'tooth_count': toothCount,
    'is_gear': isGear,
  };

  EngineeringExplanation copyWith({
    Offset? position,
    double? scale,
    bool? isVisible,
    bool? isPlaying,
    double? radius,
    double? angularVelocity,
    int? toothCount,
    bool? isGear,
  }) {
    return EngineeringExplanation(
      id: id,
      position: position ?? this.position,
      scale: scale ?? this.scale,
      isVisible: isVisible ?? this.isVisible,
      isPlaying: isPlaying ?? this.isPlaying,
      radius: radius ?? this.radius,
      angularVelocity: angularVelocity ?? this.angularVelocity,
      toothCount: toothCount ?? this.toothCount,
      isGear: isGear ?? this.isGear,
    );
  }
}
