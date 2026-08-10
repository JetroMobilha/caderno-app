import 'package:uuid/uuid.dart';

class Notebook {
  int? id;
  int? serverId;
  String clientId; // 🆔 Identidade única global
  int? subjectId; // 🛡️ Nullable para isolamento de chaves locais
  String title;
  String coverType;
  String? color;
  String? coverImage;
  String lineType;
  String paperSize;
  double? lineSpacing; // 📏 Espaçamento dinâmico entre linhas/grelha
  String templateType; // 🚀 'study', 'technical', 'formal'
  String collaborationMode; // 🚀 'study_group', 'lecture', 'tutoring'
  int version; // 🔄 Versão lógica para UI/Compatibilidade

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
    String? clientId,
    this.subjectId,
    required this.title,
    required this.coverType,
    this.color,
    this.coverImage,
    required this.lineType,
    required this.paperSize,
    this.lineSpacing,
    this.templateType = 'study',
    this.collaborationMode = 'study_group',
    this.isPublished = 0,
    this.price = 0.00,
    this.description,
    this.authorName,
    this.syncedWithCloud = 0,
    this.isDeleted = 0,
    int? updatedAt,
    this.version = 1,
    this.role = 'owner',
  }) : clientId = clientId ?? const Uuid().v4(),
       updatedAt = updatedAt ?? DateTime.now().millisecondsSinceEpoch;

  Notebook copyWith({
    int? id,
    int? serverId,
    String? clientId,
    int? subjectId,
    String? title,
    String? coverType,
    String? color,
    String? coverImage,
    String? lineType,
    String? paperSize,
    double? lineSpacing,
    String? templateType,
    String? collaborationMode,
    int? isPublished,
    double? price,
    String? description,
    String? authorName,
    int? syncedWithCloud,
    int? isDeleted,
    int? updatedAt,
    int? version,
    String? role,
  }) {
    return Notebook(
      id: id ?? this.id,
      serverId: serverId ?? this.serverId,
      clientId: clientId ?? this.clientId,
      subjectId: subjectId ?? this.subjectId,
      title: title ?? this.title,
      coverType: coverType ?? this.coverType,
      color: color ?? this.color,
      coverImage: coverImage ?? this.coverImage,
      lineType: lineType ?? this.lineType,
      paperSize: paperSize ?? this.paperSize,
      lineSpacing: lineSpacing ?? this.lineSpacing,
      templateType: templateType ?? this.templateType,
      collaborationMode: collaborationMode ?? this.collaborationMode,
      isPublished: isPublished ?? this.isPublished,
      price: price ?? this.price,
      description: description ?? this.description,
      authorName: authorName ?? this.authorName,
      syncedWithCloud: syncedWithCloud ?? this.syncedWithCloud,
      isDeleted: isDeleted ?? this.isDeleted,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
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
      'client_id': clientId,
      'subject_id': subjectId,
      'title': title,
      'cover_type': coverType,
      'color': color,
      'cover_image': coverImage,
      'line_type': lineType,
      'paper_size': paperSize,
      'line_spacing': lineSpacing,
      'template_type': templateType,
      'collaboration_mode': collaborationMode,
      'is_published': isPublished,
      'price': price,
      'description': description,
      'author_name': authorName,
      'synced_with_cloud': syncedWithCloud,
      'is_deleted': isDeleted,
      'updated_at': updatedAt,
      'version': 1,
      'role': role,
    };
  }

  // Receber do Laravel (JSON)
  factory Notebook.fromJson(Map<String, dynamic> json) {
    // 🛡️ CORREÇÃO DE COMPATIBILIDADE: 'lines' vindo do servidor -> 'ruled' no Flutter
    String lineType = json['line_type'] ?? 'ruled';
    if (lineType == 'lines') lineType = 'ruled';

    return Notebook(
      serverId: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      clientId: json['client_id'] ?? const Uuid().v4(),
      subjectId: json['subject_id'] is int ? json['subject_id'] : int.tryParse(json['subject_id']?.toString() ?? ''),
      title: json['title'] ?? '',
      coverType: json['cover_type'] ?? 'color',
      color: json['color'],
      coverImage: json['cover_image'],
      lineType: lineType,
      paperSize: json['paper_size'] ?? 'A4',
      lineSpacing: json['line_spacing'] != null ? double.tryParse(json['line_spacing'].toString()) : null,
      templateType: json['template_type'] ?? 'study',
      collaborationMode: json['collaboration_mode'] ?? 'study_group',
      isPublished: int.tryParse(json['is_published']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      description: json['description'],
      authorName: json['author_name'],
      syncedWithCloud: 1,
      isDeleted: json['deleted_at'] != null ? 1 : 0,
      updatedAt: (json['updated_at'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch,
      role: json['role'] ?? 'owner',
    );
  }
}
