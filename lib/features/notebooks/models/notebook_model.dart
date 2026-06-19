/// Modelo que representa um Caderno individual (Notebook) na aplicação.
///
/// Possui uma relação de dependência direta com uma disciplina através da
/// chave estrangeira [subject_id]. Mapeia dados relacionais para o SQLite local
/// e prepara a estrutura para sincronização com o ecossistema Laravel.
class Notebook {
  /// ID sequencial local autogerado pelo SQLite.
  final int? id;

  /// ID correspondente na base de dados remota do Laravel.
  final int? serverId;
  final int subject_id; // Chave estrangeira que liga à nossa Disciplina
  final String title;
  final String coverType;
  final String? color;
  final String? coverImage;
  final String? lineType;
  final int syncedWithCloud;

  Notebook({
    this.id,
    this.serverId,
    required this.subject_id,
    required this.title,
    required this.coverType,
    this.color,
    this.coverImage,
    this.lineType,
    this.syncedWithCloud = 0,
  });

  factory Notebook.fromMap(Map<String, dynamic> map) {
    return Notebook(
      id: map['id'],
      serverId: map['server_id'],
      subject_id: map['subject_id'],
      title: map['title'],
      coverType: map['cover_type'],
      color: map['color'],
      coverImage: map['cover_image'],
      lineType: map['line_type'],
      syncedWithCloud: map['synced_with_cloud'] ?? 0,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'subject_id': subject_id,
      'title': title,
      'cover_type': coverType,
      'color': color,
      'cover_image': coverImage,
      'line_type': lineType,
      'synced_with_cloud': syncedWithCloud,
    };
  }
}