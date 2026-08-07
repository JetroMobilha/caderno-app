import 'package:uuid/uuid.dart';

class Subject {
  final int? id;
  final int? serverId;
  final String clientId; // 🆔 Identidade única global
  final int? userId;
  final String name;
  final String color;
  final String? icon;
  final int syncedWithCloud;
  final int isDeleted;
  final int updatedAt;
  int version; // 🔄 UI Only

  Subject({
    this.id,
    this.serverId,
    String? clientId,
    this.userId,
    required this.name,
    required this.color,
    this.icon,
    this.syncedWithCloud = 0,
    this.isDeleted = 0,
    this.updatedAt = 0,
    this.version = 1,
  }) : clientId = clientId ?? const Uuid().v4();

  Subject copyWith({
    int? id,
    int? serverId,
    String? clientId,
    int? userId,
    String? name,
    String? color,
    String? icon,
    int? syncedWithCloud,
    int? isDeleted,
    int? updatedAt,
    int? version,
  }) {
    return Subject(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      clientId: clientId ?? this.clientId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
    );
  }

  // Receber do Laravel (JSON)
  factory Subject.fromJson(Map<String, dynamic> json) {
    return Subject(
      serverId: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      clientId: json['client_id'] ?? const Uuid().v4(), // Prioridade ao ID do cliente
      userId: json['user_id'] is int ? json['user_id'] : int.tryParse(json['user_id']?.toString() ?? ''),
      name: json['name'] ?? '',
      color: json['color'] ?? '#0F4C5C',
      icon: json['icon'],
      isDeleted: json['deleted_at'] != null ? 1 : 0,
      syncedWithCloud: 1,
      updatedAt: (json['updated_at'] as num?)?.toInt() ?? 0,
      version: int.tryParse(json['version']?.toString() ?? '1') ?? 1,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'server_id': serverId,
      'client_id': clientId,
      'user_id': userId,
      'name': name,
      'color': color,
      'icon': icon,
      'synced_with_cloud': syncedWithCloud,
      'is_deleted': isDeleted,
      'updated_at': updatedAt,
      'version': 1,
    };
  }
}
