class User {
  final int? id; // ID local (SQLite)
  final int? serverId; // ID na Nuvem (Laravel)
  final String name;
  final String email;
  final String? avatar; // 🚀 O caminho ou Link da foto!
  final String planType;

  User({
    this.id,
    this.serverId,
    required this.name,
    required this.email,
    this.avatar,
    this.planType = 'free',
  });

  // 1. Receber do Laravel (JSON)
  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      serverId: json['id'],
      name: json['name'],
      email: json['email'],
      avatar:json['avatar'],
      planType: json['plan_type'] ?? 'free',
    );
  }

  // 2. Receber do SQLite Local
  factory User.fromDatabaseMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      serverId: map['server_id'],
      name: map['name'],
      email: map['email'],
      avatar: map['avatar'],
      planType: map['plan_type'],
    );
  }

  // 3. Enviar para o SQLite Local
  Map<String, dynamic> toDatabaseMap() {
    return {
      'id': id,
      'server_id': serverId,
      'name': name,
      'email': email,
      'avatar': avatar,
      'plan_type': planType,
      'updated_at': DateTime.now().millisecondsSinceEpoch,
    };
  }
}