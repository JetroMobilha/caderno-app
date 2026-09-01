import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'dart:convert';
import 'notebook_configuration.dart';

class ParticipantPreview {
  final int id;
  final String name;
  final String? avatar;
  final String role;

  ParticipantPreview({
    required this.id,
    required this.name,
    this.avatar,
    required this.role,
  });

  String? get fullAvatarUrl {
    if (avatar == null || avatar!.isEmpty) return null;
    if (avatar!.startsWith('http')) return avatar;
    // 🚀 Fallback para o domínio de dev se for relativo
    return 'https://appcaderno.duckdns.org:9000/storage/$avatar';
  }

  factory ParticipantPreview.fromJson(Map<String, dynamic> json) {
    return ParticipantPreview(
      id: json['id'] as int,
      name: json['name'] as String,
      avatar: json['avatar'] as String?,
      role: json['role'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'avatar': avatar,
    'role': role,
  };
}

class Notebook {
  int? id;
  int? serverId;
  String clientId; // 🆔 Identidade única global
  int? subjectId; // 🛡️ Nullable para isolamento de chaves locais
  String title;
  String coverType;
  String? color;
  String? coverImage;
  String templateType; // 🚀 'study', 'technical', 'formal'
  String collaborationMode; // 🚀 'study_group', 'lecture', 'tutoring'
  int version; // 🔄 Versão lógica para UI/Compatibilidade

  // 🌟 Novas propriedades EdTech/Marketplace
  final int isPublished;
  final double price;
  final String? description;
  String? authorName;

  final int syncedWithCloud;
  final int isDeleted;
  final int updatedAt;
  final String role; // 🚀 'owner', 'editor', 'viewer' ou 'student'
  final String? alternativeTitle; // 🚀
  final String sharingType; // 🚀 'full' ou 'scoped'

  // 🚀 v20: Maturação de Estrutura
  final List<String> tags;
  final bool isArchived;
  final bool isFavorite;

  // 🚀 v24: Metadados Detalhados
  final String? origin;
  final List<ParticipantPreview> participants;
  final int participantsTotal;
  final int onlineCount; // 🚀
  final String? lastUpdatedByName;
  final bool notificationsEnabled;
  final int pageCount; // Mantido para UI (computado ou sync)
  final NotebookConfiguration? configuration; // 🚀 v25

  Notebook({
    this.id,
    this.serverId,
    String? clientId,
    this.subjectId,
    required this.title,
    required this.coverType,
    this.color,
    this.coverImage,
    this.templateType = 'blank',
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
    this.alternativeTitle,
    this.sharingType = 'full',
    this.tags = const [],
    this.isArchived = false,
    this.isFavorite = false,
    this.origin,
    this.participants = const [],
    this.participantsTotal = 0,
    this.onlineCount = 0,
    this.lastUpdatedByName,
    this.notificationsEnabled = true,
    this.pageCount = 0,
    this.configuration,
  }) : clientId = clientId ?? const Uuid().v4(),
       updatedAt = updatedAt ?? TimeService().nowMs();

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
    String? alternativeTitle,
    String? sharingType,
    List<String>? tags,
    bool? isArchived,
    bool? isFavorite,
    String? origin,
    int? pageCount,
    List<ParticipantPreview>? participants,
    int? participantsTotal,
    int? onlineCount,
    String? lastUpdatedByName,
    bool? notificationsEnabled,
    NotebookConfiguration? configuration,
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
      alternativeTitle: alternativeTitle ?? this.alternativeTitle,
      sharingType: sharingType ?? this.sharingType,
      tags: tags ?? this.tags,
      isArchived: isArchived ?? this.isArchived,
      isFavorite: isFavorite ?? this.isFavorite,
      origin: origin ?? this.origin,
      pageCount: pageCount ?? this.pageCount,
      participants: participants ?? this.participants,
      participantsTotal: participantsTotal ?? this.participantsTotal,
      onlineCount: onlineCount ?? this.onlineCount,
      lastUpdatedByName: lastUpdatedByName ?? this.lastUpdatedByName,
      notificationsEnabled: notificationsEnabled ?? this.notificationsEnabled,
      configuration: configuration ?? this.configuration,
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
      'template_type': templateType,
      'collaboration_mode': collaborationMode,
      'is_published': isPublished,
      'price': price,
      'description': description,
      'author_name': authorName,
      'synced_with_cloud': syncedWithCloud,
      'is_deleted': isDeleted,
      'updated_at': updatedAt,
      'version': version,
      'role': role,
      'alternative_title': alternativeTitle,
      'sharing_type': sharingType,
      'tags': tags, // 🚀 v20: Enviado como List (JSON Array no HTTP)
      'is_archived': isArchived ? 1 : 0, // 🚀 v20
      'is_favorite': isFavorite ? 1 : 0, // 🚀 v20
      'origin': origin,
      'participants_preview': {
        'total': participantsTotal,
        'list': participants.map((e) => e.toJson()).toList(),
        'online_count': onlineCount,
      },
      'last_updated_by_name': lastUpdatedByName,
      'notifications_enabled': notificationsEnabled ? 1 : 0,
      'configuration': configuration?.toJson(),
    };
  }

  // Receber do Laravel (JSON)
  factory Notebook.fromJson(Map<String, dynamic> json) {

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

    final preview = json['participants_preview'];
    List<ParticipantPreview> parts = [];
    int totalParts = 0;
    int oCount = 0;
    
    if (preview != null && preview is Map) {
       totalParts = int.tryParse(preview['total']?.toString() ?? '0') ?? 0;
       oCount = int.tryParse(preview['online_count']?.toString() ?? '0') ?? 0;
       if (preview['list'] is List) {
         parts = (preview['list'] as List).map((e) => ParticipantPreview.fromJson(e)).toList();
       }
    }

    return Notebook(
      serverId: json['id'] is int ? json['id'] : int.tryParse(json['id']?.toString() ?? ''),
      clientId: json['client_id'] ?? const Uuid().v4(),
      subjectId: json['subject_id'] is int ? json['subject_id'] : int.tryParse(json['subject_id']?.toString() ?? ''),
      title: json['title'] ?? '',
      coverType: json['cover_type'] ?? 'color',
      color: json['color'],
      coverImage: json['cover_image'],
      templateType: json['template_type'] ?? 'study',
      collaborationMode: json['collaboration_mode'] ?? 'study_group',
      isPublished: int.tryParse(json['is_published']?.toString() ?? '0') ?? 0,
      price: double.tryParse(json['price']?.toString() ?? '0.0') ?? 0.0,
      description: json['description'],
      authorName: json['author_name'],
      syncedWithCloud: json['synced_with_cloud'] ?? 1,
      isDeleted: json['deleted_at'] != null ? 1 : 0,
      updatedAt: upAt ?? TimeService().nowMs(),
      version: int.tryParse(json['version']?.toString() ?? '1') ?? 1,
      role: json['role'] ?? 'owner',
      alternativeTitle: json['alternative_title'],
      sharingType: json['sharing_type'] ?? 'full',
      tags: parseTags(json['tags']),
      isArchived: json['is_archived'] == 1 || json['is_archived'] == true,
      isFavorite: json['is_favorite'] == 1 || json['is_favorite'] == true,
      origin: json['origin'],
      participants: parts,
      participantsTotal: totalParts,
      onlineCount: oCount,
      lastUpdatedByName: json['last_updated_by_name'],
      notificationsEnabled: json['notifications_enabled'] == 1 || json['notifications_enabled'] == true || json['notifications_enabled'] == null,
      configuration: json['configuration'] != null ? NotebookConfiguration.fromJson(json['configuration'] is String ? jsonDecode(json['configuration']) : json['configuration']) : null,
    );
  }

  static List<String> parseTags(dynamic tagsJson) {
    if (tagsJson == null) return [];
    if (tagsJson is List) return tagsJson.map((e) => e.toString()).toList();
    if (tagsJson is String) {
      return tagsJson.split(',').where((t) => t.isNotEmpty).toList();
    }
    return [];
  }

  Notebook clone({String? newClientId, int? newSubjectId}) {
    return Notebook(
      id: null,
      serverId: null,
      clientId: newClientId ?? const Uuid().v4(),
      subjectId: newSubjectId ?? subjectId,
      title: '$title (Cópia)',
      coverType: coverType,
      color: color,
      coverImage: coverImage,
      templateType: templateType,
      collaborationMode: collaborationMode,
      isPublished: 0,
      price: 0.0,
      description: description,
      authorName: authorName,
      syncedWithCloud: 0,
      isDeleted: 0,
      updatedAt: TimeService().nowMs(),
      version: 1,
      role: 'owner',
      alternativeTitle: alternativeTitle,
      sharingType: sharingType,
      tags: List.from(tags),
      isArchived: false,
      isFavorite: false,
      origin: origin ?? 'Cópia Local',
      pageCount: pageCount,
      participants: const [],
      participantsTotal: 1, // Apenas eu
      lastUpdatedByName: null,
      notificationsEnabled: true,
      configuration: configuration != null ? NotebookConfiguration.fromJson(configuration!.toJson()) : null,
    );
  }
}
