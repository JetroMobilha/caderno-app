class Subject {
  final int? id;
  final int userId;
  final String name;
  final String color;
  final String? icon;

  Subject({
    this.id,
    required this.userId,
    required this.name,
    required this.color,
    this.icon,
  });

  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      userId: map['user_id'] ?? 1,
      name: map['name'],
      color: map['color'],
      icon: map['icon'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'user_id': userId,
      'name': name,
      'color': color,
      'icon': icon,
    };
  }
}