class Notebook {
  int? id;
  int? serverId;
  int? subjectId; // 🛡️ Nullable para isolamento de chaves locais
  String title;
  String coverType;
  String? color;
  String? coverImage;
  String lineType;
  String paperSize;

  // 🌟 Novas propriedades EdTech/Marketplace
  final int isPublished;
  final double price;
  final String? description;
  final String? authorName;

  final int syncedWithCloud;
  final int isDeleted;
  final int updatedAt;
  final String role; // 🚀 'owner', 'editor', 'viewer' ou 'student'

  Notebook({
    this.id,
    this.serverId,
    this.subjectId,
    required this.title,
    required this.coverType,
    this.color,
    this.coverImage,
    required this.lineType,
    required this.paperSize,
    this.isPublished = 0,
    this.price = 0.00,
    this.description,
    this.authorName,
    this.syncedWithCloud = 0,
    this.isDeleted = 0,
    int? updatedAt,
    this.role = 'owner',
  }) : updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  // 🔄 O Método copyWith para mutações limpas de estado na RAM
  Notebook copyWith({
    int? id,
    int? serverId,
    int? subjectId,
    String? title,
    String? coverType,
    String? color,
    String? coverImage,
    String? lineType,
    String? paperSize,
    int? isPublished,
    double? price,
    String? description,
    String? authorName,
    int? syncedWithCloud,
    int? isDeleted,
    int? updatedAt,
    String? role,
  }) {
    return Notebook(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      coverType: coverType ?? this.coverType,
      color: color ?? this.color,
      coverImage: coverImage ?? this.coverImage,
      lineType: lineType ?? this.lineType,
      paperSize: paperSize ?? this.paperSize,
      isPublished: isPublished ?? this.isPublished,
      price: price ?? this.price,
      description: description ?? this.description,
      authorName: authorName ?? this.authorName,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      role: role ?? this.role,
    );
  }

  // =========================================================================
  // 🌐 PARA A NUVEM / API (Manda tudo, incluindo a role)
  // =========================================================================
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'server_id': serverId,
      'subject_id': subjectId,
      'title': title,
      'cover_type': coverType,
      'color': color,
      'cover_image': coverImage,
      'line_type': lineType,
      'paper_size': paperSize,
      'is_published': isPublished,
      'price': price,
      'description': description,
      'author_name': authorName,
      'synced_with_cloud': syncedWithCloud,
      'is_deleted': isDeleted,
      'updated_at': updatedAt,
      'role': role,
    };
  }

  // Receber do Laravel (JSON)
  factory Notebook.fromJson(Map<String, dynamic> json) {
    return Notebook(
      serverId: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      subjectId: json['subject_id'] is int ? json['subject_id'] : int.tryParse(json['subject_id']?.toString() ?? ''),
      title: json['title'] ?? '',
      coverType: json['cover_type'] ?? 'color',
      color: json['color'],
      coverImage: json['cover_image'],
      lineType: json['line_type'] ?? 'ruled',
      paperSize: json['paper_size'] ?? 'A4',
      isPublished: int.tryParse(json['is_published']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      description: json['description'],
      authorName: json['author_name'],
      syncedWithCloud: 1,
      isDeleted: json['deleted_at'] != null ? 1 : 0,
      role: json['role'] ?? 'owner',
    );
  }
}
