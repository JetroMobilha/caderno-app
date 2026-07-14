class Notebook {
    int? id; // ID local do SQLite (Mobile)
    int? serverId; // ID oficial do Laravel (Nuvem)
  final int subjectId; // ID da disciplina a que pertence
  final String title;
  final String coverType; // 'color' ou 'image'
  final String? color; // Código Hex da capa
  final String? coverImage; // Path ou URL da imagem de capa
  final String lineType; // 'ruled', 'grid', 'blank'
  final String paperSize; // 'A4', 'A5', 'A3', etc.
  final int syncedWithCloud;

  Notebook({
    this.id,
    this.serverId,
    required this.subjectId,
    required this.title,
    this.coverType = 'color',
    this.color = '#0F4C5C',
    this.coverImage,
    this.lineType = 'ruled',
    this.paperSize = 'A4',
    this.syncedWithCloud = 0,
  });

  // Converte a linha do SQLite num Objeto Dart
  factory Notebook.fromMap(Map<String, dynamic> map) {
    return Notebook(
      id: map['id'],
      serverId: map['server_id'],
      subjectId: map['subject_id'] as int,
      title: map['title'] ?? 'Sem Título',
      coverType: map['cover_type'] ?? 'color',
      color: map['color'],
      coverImage: map['cover_image'],
      lineType: map['line_type'] ?? 'ruled',
      paperSize: map['paper_size'] ?? 'A4',
      syncedWithCloud: map['synced_with_cloud'] ?? 0,
    );
  }

  // Prepara o Objeto Caderno para ser escrito no SQLite
  Map<String, dynamic> toMap() {
    final map = {
      'subject_id': subjectId,
      'title': title,
      'cover_type': coverType,
      'color': color,
      'cover_image': coverImage,
      'line_type': lineType,
      'paper_size': paperSize,
      'synced_with_cloud': syncedWithCloud,
    };
    if (id != null) map['id'] = id;
    if (serverId != null) map['server_id'] = serverId;
    return map;
  }
}