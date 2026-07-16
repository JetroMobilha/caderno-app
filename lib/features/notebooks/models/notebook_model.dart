class Notebook {
  final int? id;
  final int? serverId;
  final int? subjectId; // 🛡️ Nullable para isolamento de chaves locais
  final String title;
  final String coverType;
  final String? color;
  final String? coverImage;
  final String lineType;
  final String paperSize;

  // 🌟 Novas propriedades EdTech/Marketplace
  final int isPublished;
  final double price;
  final String? description;
  final String? author_name;

  final int syncedWithCloud;
  final int isDeleted;
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
    this.author_name,
    this.syncedWithCloud = 0,
    this.isDeleted = 0,
    this.role = 'owner',
  });

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
    String? author_name,
    int? syncedWithCloud,
    int? isDeleted,
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
      author_name: author_name ?? this.author_name,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      isDeleted: isDeleted ?? this.isDeleted,
      role: role ?? this.role,
    );
  }

  // =========================================================================
  // 🌐 PARA A NUVEM / API (Manda tudo, incluindo a role)
  // =========================================================================
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
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
      'author_name': author_name,
      'synced_with_cloud': syncedWithCloud,
      'is_deleted': isDeleted,
      'role': role, // A Nuvem recebe e processa isto na tabela pivô dela!
    };
  }

  // =========================================================================
  // 📱 PARA O SQLITE LOCAL (Gravação limpa na tabela 'notebooks')
  // =========================================================================
  Map<String, dynamic> toMapForSQLite() {
    return {
      if (id != null) 'id': id,
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
      'author_name': author_name,
      'synced_with_cloud': syncedWithCloud,
      'is_deleted': isDeleted,
      // 🚀 NOTA: O campo 'role' foi removido aqui!
      // Assim o SQLite grava o caderno tranquilamente sem dar erro de coluna inexistente.
    };
  }

  // =========================================================================
  // 🛡️ DESCODIFICADOR BLINDADO (SQLite -> RAM)
  // =========================================================================
  factory Notebook.fromMap(Map<String, dynamic> map) {
    return Notebook(
      id: map['id'] as int?,
      serverId: map['server_id'] as int?,
      subjectId: map['subject_id'] as int?,
      title: map['title'] as String,
      coverType: map['cover_type'] as String,
      color: map['color'] as String?,
      coverImage: map['cover_image'] as String?,
      lineType: map['line_type'] as String,
      paperSize: map['paper_size'] as String,

      // 🚀 CONVERSÃO SEGURA: Se o Laravel enviar "0", tentamos converter para int!
      isPublished: int.tryParse(map['is_published']?.toString() ?? '0') ?? 0,

      // 🚀 CONVERSÃO SEGURA: Se o Laravel enviar "0.00", convertemos para double!
      price: double.tryParse(map['price']?.toString() ?? '0.0') ?? 0.0,

      description: map['description'] as String?,
      author_name: map['author_name'] as String?,

      syncedWithCloud: int.tryParse(map['synced_with_cloud']?.toString() ?? '0') ?? 0,
      isDeleted: int.tryParse(map['is_deleted']?.toString() ?? '0') ?? 0,
      role: map['role'] ?? 'owner',
    );
  }
}