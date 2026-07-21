class User {
  final int? id; // ID local (SQLite)
  final int? serverId; // ID na Nuvem (Laravel)
  final String name;
  final String email;
  final String? avatar;
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
      serverId: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      avatar: json['avatar'],
      planType: json['plan_type'] ?? 'free',
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
    };
  }
}
