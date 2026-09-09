import 'package:caderno_digital_app/core/network/time_service.dart';

/// 🚀 v9.4: Modelo de Utilizador Imutável.
class User {
  final int? id;
  final int? serverId;
  final String name;
  final String email;
  final String? avatar;
  final String planType;
  final String? bio;
  final String? institution;
  final String? preferredColor;
  final String? preferredFont;
  final String? specialties;
  final int syncedWithCloud;
  final int updatedAt;

  User({
    this.id,
    this.serverId,
    required this.name,
    required this.email,
    this.avatar,
    this.planType = 'free',
    this.bio,
    this.institution,
    this.preferredColor,
    this.preferredFont,
    this.specialties,
    this.syncedWithCloud = 0,
    this.updatedAt = 0,
  });

  User copyWith({
    int? id,
    int? serverId,
    String? name,
    String? email,
    String? avatar,
    String? planType,
    String? bio,
    String? institution,
    String? preferredColor,
    String? preferredFont,
    String? specialties,
    int? syncedWithCloud,
    int? updatedAt,
  }) {
    return User(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      name: name ?? this.name,
      email: email ?? this.email,
      avatar: avatar ?? this.avatar,
      planType: planType ?? this.planType,
      bio: bio ?? this.bio,
      institution: institution ?? this.institution,
      preferredColor: preferredColor ?? this.preferredColor,
      preferredFont: preferredFont ?? this.preferredFont,
      specialties: specialties ?? this.specialties,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  User clone() {
    return copyWith(
      id: null,
      serverId: null,
      syncedWithCloud: 0,
      updatedAt: TimeService().nowMs(),
    );
  }

  factory User.fromJson(Map<String, dynamic> json) {
    int? upAt;
    if (json['updated_at_ms'] != null) {
      upAt = (json['updated_at_ms'] as num).toInt();
    } else if (json['updated_at'] != null) {
      final val = json['updated_at'];
      if (val is num) upAt = val.toInt();
      else if (val is String) upAt = DateTime.tryParse(val)?.millisecondsSinceEpoch;
    }

    return User(
      id: json['id'] is int ? json['id'] : null,
      serverId: json['server_id'] != null 
          ? (json['server_id'] is int ? json['server_id'] : int.tryParse(json['server_id'].toString()))
          : (json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? '')),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      planType: json['plan_type'] ?? 'free',
      bio: json['bio'],
      institution: json['institution'],
      preferredColor: json['preferred_color'] ?? json['preferredColor'],
      preferredFont: json['preferred_font'] ?? json['preferredFont'],
      specialties: json['specialties'],
      syncedWithCloud: json['synced_with_cloud'] ?? (json['server_id'] != null ? 1 : 0),
      updatedAt: upAt ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id, 'server_id': serverId, 'name': name, 'email': email, 'avatar': avatar,
      'plan_type': planType, 'bio': bio, 'institution': institution,
      'preferred_color': preferredColor, 'preferred_font': preferredFont,
      'specialties': specialties, 'synced_with_cloud': syncedWithCloud,
      'updated_at': updatedAt,
    };
  }
}
