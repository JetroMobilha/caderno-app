import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'package:caderno_digital_app/features/canvas/models/page_object.dart';

enum ExplanationType {
  mathFunction,
  physicsBody,
  engineeringMechanism
}

enum MathKind {
  sineWave,
  polynomial,
  trigCircle
}

enum PhysicsKind {
  inclinedPlane,
  simplePendulum,
  massSpring
}

enum EngineeringKind {
  gears,
  dcCircuit,
  trussBeam
}

/// 🚀 v10.0: Modelo Abstrato Integrado com PageObject para Explicações e Simulações.
abstract class ExplanationModel implements PageObject {
  @override
  final String id;
  @override
  final String type; // ex: 'explanation_math', 'explanation_physics', 'explanation_engineering'
  @override
  final String? parentId;

  final ExplanationType explanationType;

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
  final double opacity;

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

  final double scale;
  final bool isPlaying;

  ExplanationModel({
    String? id,
    required this.type,
    this.parentId,
    required this.explanationType,
    required this.position,
    this.size = const Size(280, 200),
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
    this.scale = 1.0,
    this.isPlaying = true,
  }) : id = id ?? const Uuid().v4(),
       updatedAt = updatedAt ?? TimeService().nowMs();

  @override
  Map<String, dynamic> toJson();

  @override
  ExplanationModel clone({String? newId, int? newPageNumber});

  @override
  ExplanationModel copyWith({
    String? id,
    String? Function()? parentId,
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
    double? scale,
    bool? isPlaying,
  });

  factory ExplanationModel.fromJson(Map<String, dynamic> json) {
    final String type = json['type']?.toString() ?? '';
    if (type == 'explanation_math' || json['explanation_type'] == 'mathFunction' || type == 'mathFunction') {
      return MathExplanation.fromJson(json);
    } else if (type == 'explanation_physics' || json['explanation_type'] == 'physicsBody' || type == 'physicsBody') {
      return PhysicsExplanation.fromJson(json);
    } else {
      return EngineeringExplanation.fromJson(json);
    }
  }
}

class MathExplanation extends ExplanationModel {
  final MathKind kind;
  final String expression;
  final Color color;
  final double frequency;
  final double amplitude;
  final bool showAxes;
  final double rangeMin;
  final double rangeMax;
  final double animationProgress;

  MathExplanation({
    super.id,
    super.parentId,
    super.position = Offset.zero,
    super.size = const Size(280, 200),
    super.rotation = 0.0,
    super.zIndex = 0,
    super.isLocked = false,
    super.isVisible = true,
    super.opacity = 1.0,
    super.updatedAt,
    super.version = 1,
    super.isDeleted = false,
    super.syncedWithCloud = false,
    super.deletedInSession = false,
    super.pageNumber,
    super.creatorId,
    super.layerId,
    super.scale = 1.0,
    super.isPlaying = true,
    this.kind = MathKind.sineWave,
    this.expression = 'f(x) = sin(x)',
    this.color = Colors.blue,
    this.frequency = 1.0,
    this.amplitude = 50.0,
    this.showAxes = true,
    this.rangeMin = -10.0,
    this.rangeMax = 10.0,
    this.animationProgress = 0.0,
  }) : super(type: 'explanation_math', explanationType: ExplanationType.mathFunction);

  @override
  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'parent_id': parentId, 'explanation_type': explanationType.name,
    'kind': kind.name, 'x': position.dx, 'y': position.dy, 'width': size.width, 'height': size.height,
    'rotation': rotation, 'z_index': zIndex, 'is_locked': isLocked ? 1 : 0,
    'is_visible': isVisible ? 1 : 0, 'opacity': opacity, 'updated_at': updatedAt, 'version': version,
    'is_deleted': isDeleted ? 1 : 0, 'synced_with_cloud': syncedWithCloud ? 1 : 0,
    'deleted_in_session': deletedInSession ? 1 : 0, 'page_number': pageNumber,
    'creator_id': creatorId, 'layer_id': layerId, 'scale': scale, 'is_playing': isPlaying ? 1 : 0,
    'expression': expression, 'color': color.toARGB32(), 'frequency': frequency,
    'amplitude': amplitude, 'show_axes': showAxes ? 1 : 0,
    'range_min': rangeMin, 'range_max': rangeMax, 'progress': animationProgress,
  };

  factory MathExplanation.fromJson(Map<String, dynamic> json) {
    return MathExplanation(
      id: json['id'],
      parentId: json['parent_id'],
      position: Offset(json['x']?.toDouble() ?? 0.0, json['y']?.toDouble() ?? 0.0),
      size: Size(json['width']?.toDouble() ?? 280.0, json['height']?.toDouble() ?? 200.0),
      rotation: json['rotation']?.toDouble() ?? 0.0,
      zIndex: json['z_index'] ?? 0,
      isLocked: json['is_locked'] == 1 || json['is_locked'] == true,
      isVisible: json['is_visible'] == null ? true : (json['is_visible'] == 1 || json['is_visible'] == true),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      updatedAt: json['updated_at'],
      version: json['version'] ?? 1,
      isDeleted: json['is_deleted'] == 1 || json['is_deleted'] == true,
      syncedWithCloud: json['synced_with_cloud'] == 1 || json['synced_with_cloud'] == true,
      deletedInSession: json['deleted_in_session'] == 1 || json['deleted_in_session'] == true,
      pageNumber: json['page_number'],
      creatorId: json['creator_id'],
      layerId: json['layer_id'],
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      isPlaying: json['is_playing'] == null ? true : (json['is_playing'] == 1 || json['is_playing'] == true),
      kind: MathKind.values.firstWhere((e) => e.name == json['kind'], orElse: () => MathKind.sineWave),
      expression: json['expression'] ?? 'f(x) = sin(x)',
      color: Color(json['color'] ?? Colors.blue.toARGB32()),
      frequency: (json['frequency'] as num?)?.toDouble() ?? 1.0,
      amplitude: (json['amplitude'] as num?)?.toDouble() ?? 50.0,
      showAxes: json['show_axes'] == 1 || json['show_axes'] == true,
      rangeMin: (json['range_min'] as num?)?.toDouble() ?? -10.0,
      rangeMax: (json['range_max'] as num?)?.toDouble() ?? 10.0,
      animationProgress: (json['progress'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  MathExplanation copyWith({
    String? id,
    String? Function()? parentId,
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
    double? scale,
    bool? isPlaying,
    MathKind? kind,
    String? expression,
    Color? color,
    double? frequency,
    double? amplitude,
    bool? showAxes,
    double? rangeMin,
    double? rangeMax,
    double? animationProgress,
  }) {
    return MathExplanation(
      id: id ?? this.id,
      parentId: parentId != null ? parentId() : this.parentId,
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
      scale: scale ?? this.scale,
      isPlaying: isPlaying ?? this.isPlaying,
      kind: kind ?? this.kind,
      expression: expression ?? this.expression,
      color: color ?? this.color,
      frequency: frequency ?? this.frequency,
      amplitude: amplitude ?? this.amplitude,
      showAxes: showAxes ?? this.showAxes,
      rangeMin: rangeMin ?? this.rangeMin,
      rangeMax: rangeMax ?? this.rangeMax,
      animationProgress: animationProgress ?? this.animationProgress,
    );
  }

  @override
  MathExplanation clone({String? newId, int? newPageNumber}) {
    return copyWith(
      id: newId ?? const Uuid().v4(),
      pageNumber: newPageNumber ?? pageNumber,
      updatedAt: TimeService().nowMs(),
      version: 1,
      syncedWithCloud: false,
    );
  }
}

class PhysicsExplanation extends ExplanationModel {
  final PhysicsKind kind;
  final double mass;
  final double angleDegrees;
  final double frictionCoeff;
  final double length;
  final double springK;
  final Offset velocity;
  final List<Offset> forces;

  PhysicsExplanation({
    super.id,
    super.parentId,
    super.position = Offset.zero,
    super.size = const Size(280, 200),
    super.rotation = 0.0,
    super.zIndex = 0,
    super.isLocked = false,
    super.isVisible = true,
    super.opacity = 1.0,
    super.updatedAt,
    super.version = 1,
    super.isDeleted = false,
    super.syncedWithCloud = false,
    super.deletedInSession = false,
    super.pageNumber,
    super.creatorId,
    super.layerId,
    super.scale = 1.0,
    super.isPlaying = true,
    this.kind = PhysicsKind.inclinedPlane,
    this.mass = 2.0,
    this.angleDegrees = 30.0,
    this.frictionCoeff = 0.1,
    this.length = 120.0,
    this.springK = 10.0,
    this.velocity = Offset.zero,
    this.forces = const [],
  }) : super(type: 'explanation_physics', explanationType: ExplanationType.physicsBody);

  @override
  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'parent_id': parentId, 'explanation_type': explanationType.name,
    'kind': kind.name, 'x': position.dx, 'y': position.dy, 'width': size.width, 'height': size.height,
    'rotation': rotation, 'z_index': zIndex, 'is_locked': isLocked ? 1 : 0,
    'is_visible': isVisible ? 1 : 0, 'opacity': opacity, 'updated_at': updatedAt, 'version': version,
    'is_deleted': isDeleted ? 1 : 0, 'synced_with_cloud': syncedWithCloud ? 1 : 0,
    'deleted_in_session': deletedInSession ? 1 : 0, 'page_number': pageNumber,
    'creator_id': creatorId, 'layer_id': layerId, 'scale': scale, 'is_playing': isPlaying ? 1 : 0,
    'mass': mass, 'angle_degrees': angleDegrees, 'friction_coeff': frictionCoeff,
    'length': length, 'spring_k': springK, 'vx': velocity.dx, 'vy': velocity.dy,
    'forces': forces.map((f) => {'dx': f.dx, 'dy': f.dy}).toList(),
  };

  factory PhysicsExplanation.fromJson(Map<String, dynamic> json) {
    return PhysicsExplanation(
      id: json['id'],
      parentId: json['parent_id'],
      position: Offset(json['x']?.toDouble() ?? 0.0, json['y']?.toDouble() ?? 0.0),
      size: Size(json['width']?.toDouble() ?? 280.0, json['height']?.toDouble() ?? 200.0),
      rotation: json['rotation']?.toDouble() ?? 0.0,
      zIndex: json['z_index'] ?? 0,
      isLocked: json['is_locked'] == 1 || json['is_locked'] == true,
      isVisible: json['is_visible'] == null ? true : (json['is_visible'] == 1 || json['is_visible'] == true),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      updatedAt: json['updated_at'],
      version: json['version'] ?? 1,
      isDeleted: json['is_deleted'] == 1 || json['is_deleted'] == true,
      syncedWithCloud: json['synced_with_cloud'] == 1 || json['synced_with_cloud'] == true,
      deletedInSession: json['deleted_in_session'] == 1 || json['deleted_in_session'] == true,
      pageNumber: json['page_number'],
      creatorId: json['creator_id'],
      layerId: json['layer_id'],
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      isPlaying: json['is_playing'] == null ? true : (json['is_playing'] == 1 || json['is_playing'] == true),
      kind: PhysicsKind.values.firstWhere((e) => e.name == json['kind'], orElse: () => PhysicsKind.inclinedPlane),
      mass: (json['mass'] as num?)?.toDouble() ?? 2.0,
      angleDegrees: (json['angle_degrees'] as num?)?.toDouble() ?? 30.0,
      frictionCoeff: (json['friction_coeff'] as num?)?.toDouble() ?? 0.1,
      length: (json['length'] as num?)?.toDouble() ?? 120.0,
      springK: (json['spring_k'] as num?)?.toDouble() ?? 10.0,
      velocity: Offset(json['vx']?.toDouble() ?? 0.0, json['vy']?.toDouble() ?? 0.0),
      forces: (json['forces'] as List?)?.map((f) => Offset(f['dx']?.toDouble() ?? 0.0, f['dy']?.toDouble() ?? 0.0)).toList() ?? const [],
    );
  }

  @override
  PhysicsExplanation copyWith({
    String? id,
    String? Function()? parentId,
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
    double? scale,
    bool? isPlaying,
    PhysicsKind? kind,
    double? mass,
    double? angleDegrees,
    double? frictionCoeff,
    double? length,
    double? springK,
    Offset? velocity,
    List<Offset>? forces,
  }) {
    return PhysicsExplanation(
      id: id ?? this.id,
      parentId: parentId != null ? parentId() : this.parentId,
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
      scale: scale ?? this.scale,
      isPlaying: isPlaying ?? this.isPlaying,
      kind: kind ?? this.kind,
      mass: mass ?? this.mass,
      angleDegrees: angleDegrees ?? this.angleDegrees,
      frictionCoeff: frictionCoeff ?? this.frictionCoeff,
      length: length ?? this.length,
      springK: springK ?? this.springK,
      velocity: velocity ?? this.velocity,
      forces: forces ?? this.forces,
    );
  }

  @override
  PhysicsExplanation clone({String? newId, int? newPageNumber}) {
    return copyWith(
      id: newId ?? const Uuid().v4(),
      pageNumber: newPageNumber ?? pageNumber,
      updatedAt: TimeService().nowMs(),
      version: 1,
      syncedWithCloud: false,
    );
  }
}

class EngineeringExplanation extends ExplanationModel {
  final EngineeringKind kind;
  final double radius;
  final double angularVelocity;
  final int toothCount;
  final double gearRatio;
  final double voltage;
  final double resistance;
  final double beamLength;
  final double loadForce;

  EngineeringExplanation({
    super.id,
    super.parentId,
    super.position = Offset.zero,
    super.size = const Size(280, 200),
    super.rotation = 0.0,
    super.zIndex = 0,
    super.isLocked = false,
    super.isVisible = true,
    super.opacity = 1.0,
    super.updatedAt,
    super.version = 1,
    super.isDeleted = false,
    super.syncedWithCloud = false,
    super.deletedInSession = false,
    super.pageNumber,
    super.creatorId,
    super.layerId,
    super.scale = 1.0,
    super.isPlaying = true,
    this.kind = EngineeringKind.gears,
    this.radius = 40.0,
    this.angularVelocity = 1.0,
    this.toothCount = 12,
    this.gearRatio = 2.0,
    this.voltage = 12.0,
    this.resistance = 10.0,
    this.beamLength = 200.0,
    this.loadForce = 50.0,
  }) : super(type: 'explanation_engineering', explanationType: ExplanationType.engineeringMechanism);

  @override
  Map<String, dynamic> toJson() => {
    'id': id, 'type': type, 'parent_id': parentId, 'explanation_type': explanationType.name,
    'kind': kind.name, 'x': position.dx, 'y': position.dy, 'width': size.width, 'height': size.height,
    'rotation': rotation, 'z_index': zIndex, 'is_locked': isLocked ? 1 : 0,
    'is_visible': isVisible ? 1 : 0, 'opacity': opacity, 'updated_at': updatedAt, 'version': version,
    'is_deleted': isDeleted ? 1 : 0, 'synced_with_cloud': syncedWithCloud ? 1 : 0,
    'deleted_in_session': deletedInSession ? 1 : 0, 'page_number': pageNumber,
    'creator_id': creatorId, 'layer_id': layerId, 'scale': scale, 'is_playing': isPlaying ? 1 : 0,
    'radius': radius, 'angular_velocity': angularVelocity, 'tooth_count': toothCount,
    'gear_ratio': gearRatio, 'voltage': voltage, 'resistance': resistance,
    'beam_length': beamLength, 'load_force': loadForce,
  };

  factory EngineeringExplanation.fromJson(Map<String, dynamic> json) {
    return EngineeringExplanation(
      id: json['id'],
      parentId: json['parent_id'],
      position: Offset(json['x']?.toDouble() ?? 0.0, json['y']?.toDouble() ?? 0.0),
      size: Size(json['width']?.toDouble() ?? 280.0, json['height']?.toDouble() ?? 200.0),
      rotation: json['rotation']?.toDouble() ?? 0.0,
      zIndex: json['z_index'] ?? 0,
      isLocked: json['is_locked'] == 1 || json['is_locked'] == true,
      isVisible: json['is_visible'] == null ? true : (json['is_visible'] == 1 || json['is_visible'] == true),
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
      updatedAt: json['updated_at'],
      version: json['version'] ?? 1,
      isDeleted: json['is_deleted'] == 1 || json['is_deleted'] == true,
      syncedWithCloud: json['synced_with_cloud'] == 1 || json['synced_with_cloud'] == true,
      deletedInSession: json['deleted_in_session'] == 1 || json['deleted_in_session'] == true,
      pageNumber: json['page_number'],
      creatorId: json['creator_id'],
      layerId: json['layer_id'],
      scale: (json['scale'] as num?)?.toDouble() ?? 1.0,
      isPlaying: json['is_playing'] == null ? true : (json['is_playing'] == 1 || json['is_playing'] == true),
      kind: EngineeringKind.values.firstWhere((e) => e.name == json['kind'], orElse: () => EngineeringKind.gears),
      radius: (json['radius'] as num?)?.toDouble() ?? 40.0,
      angularVelocity: (json['angular_velocity'] as num?)?.toDouble() ?? 1.0,
      toothCount: json['tooth_count'] ?? 12,
      gearRatio: (json['gear_ratio'] as num?)?.toDouble() ?? 2.0,
      voltage: (json['voltage'] as num?)?.toDouble() ?? 12.0,
      resistance: (json['resistance'] as num?)?.toDouble() ?? 10.0,
      beamLength: (json['beam_length'] as num?)?.toDouble() ?? 200.0,
      loadForce: (json['load_force'] as num?)?.toDouble() ?? 50.0,
    );
  }

  @override
  EngineeringExplanation copyWith({
    String? id,
    String? Function()? parentId,
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
    double? scale,
    bool? isPlaying,
    EngineeringKind? kind,
    double? radius,
    double? angularVelocity,
    int? toothCount,
    double? gearRatio,
    double? voltage,
    double? resistance,
    double? beamLength,
    double? loadForce,
  }) {
    return EngineeringExplanation(
      id: id ?? this.id,
      parentId: parentId != null ? parentId() : this.parentId,
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
      scale: scale ?? this.scale,
      isPlaying: isPlaying ?? this.isPlaying,
      kind: kind ?? this.kind,
      radius: radius ?? this.radius,
      angularVelocity: angularVelocity ?? this.angularVelocity,
      toothCount: toothCount ?? this.toothCount,
      gearRatio: gearRatio ?? this.gearRatio,
      voltage: voltage ?? this.voltage,
      resistance: resistance ?? this.resistance,
      beamLength: beamLength ?? this.beamLength,
      loadForce: loadForce ?? this.loadForce,
    );
  }

  @override
  EngineeringExplanation clone({String? newId, int? newPageNumber}) {
    return copyWith(
      id: newId ?? const Uuid().v4(),
      pageNumber: newPageNumber ?? pageNumber,
      updatedAt: TimeService().nowMs(),
      version: 1,
      syncedWithCloud: false,
    );
  }
}
