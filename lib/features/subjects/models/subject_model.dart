class Subject {
  final int? id;
  final int? serverId;
  final int? userId;
  final String name;
  final String color;
  final String? icon;
  final int syncedWithCloud;
  final int isDeleted; // 🚀 A NOSSA VARIÁVEL DE CONTROLO FANTASMA!
  final int updatedAt;

  Subject({
    this.id,
    this.serverId,
    this.userId,
    required this.name,
    required this.color,
    this.icon,
    this.syncedWithCloud = 0,
    this.isDeleted = 0,
    this.updatedAt = 0,
  });

  // =========================================================================
  // 🚀 MÉTODO CLONAR PARA EDIÇÃO (Resolve o erro do Editor!)
  // =========================================================================
  Subject copyWith({
    int? id,
    int? serverId,
    int? userId,
    String? name,
    String? color,
    String? icon,
    int? syncedWithCloud,
    int? isDeleted,
    int? updatedAt,
  }) {
    return Subject(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      userId: userId ?? this.userId,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // =========================================================================
  // 💾 CONVERSÃO PARA A BASE DE DADOS LOCAL
  // =========================================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'user_id': userId,
      'name': name,
      'color': color,
      'icon': icon,
      'synced_with_cloud': syncedWithCloud,
      'is_deleted': isDeleted,
      'updated_at': updatedAt,
    };
  }

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      serverId: map['server_id'],
      userId: map['user_id'],
      name: map['name'] ?? '',
      color: map['color'] ?? '#1976D2',
      icon: map['icon'],
      syncedWithCloud: map['synced_with_cloud'] ?? 0,
      isDeleted: map['is_deleted'] ?? 0,
      updatedAt: map['updated_at'] ?? 0,
    );
  }
}