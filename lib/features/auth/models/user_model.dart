class User {
  final int? id; // ID local (SQLite)
  final int? serverId; // ID na Nuvem (Laravel)
  final String name;
  final String email;
  final String? avatar;
  final String planType;
  final int syncedWithCloud;
  final int updatedAt;

  User({
    this.id,
    this.serverId,
    required this.name,
    required this.email,
    this.avatar,
    this.planType = 'free',
    this.syncedWithCloud = 0,
    this.updatedAt = 0,
  });

  // 1. Receber do Laravel (JSON) ou do Cache Local
  factory User.fromJson(Map<String, dynamic> json) {
    int? upAt;
    if (json['updated_at_ms'] != null) {
      upAt = (json['updated_at_ms'] as num).toInt();
    } else if (json['updated_at'] != null) {
      final val = json['updated_at'];
      if (val is num) {
        upAt = val.toInt();
      } else if (val is String) {
        upAt = DateTime.tryParse(val)?.millisecondsSinceEpoch;
      }
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
      syncedWithCloud: json['synced_with_cloud'] ?? (json['server_id'] != null ? 1 : 0),
      updatedAt: upAt ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'server_id': serverId,
      'name': name,
      'email': email,
      'avatar': avatar,
      'plan_type': planType,
      'synced_with_cloud': syncedWithCloud,
      'updated_at': updatedAt,
    };
  }
}
