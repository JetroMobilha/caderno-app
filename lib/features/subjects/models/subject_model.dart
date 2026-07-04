class Subject {
  final int? id;
  final int userId;
  final int? serverId; // 🚀 1. AGORA TEM '?': Já aceita null perfeitamente!
  final String name;
  final String color;
  final String? icon;
  final int syncedWithCloud;

  Subject({
    this.id,
    required this.userId,
    this.serverId, // 🚀 2. Removemos o 'required' para poderes omitir ou passar null à vontade
    required this.name,
    required this.color,
    this.icon,
    required this.syncedWithCloud,
  });

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'] as int?,
      userId: map['user_id'] as int? ?? 0,
      // 🚀 3. SEM FALSOS IDs: Se vier null da BD local, fica null! Não metas '?? 1'.
      serverId: map['server_id'] as int?,
      name: map['name'] as String? ?? '',
      color: map['color'] as String? ?? '#000000',
      icon: map['icon'] as String?,
      syncedWithCloud: map['synced_with_cloud'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'server_id': serverId, // Se for null, o SQLite e o JSON enviam null com sucesso!
      'name': name,
      'color': color,
      'icon': icon,
      'synced_with_cloud': syncedWithCloud,
    };
  }
}