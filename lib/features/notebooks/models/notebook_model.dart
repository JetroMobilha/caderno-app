class Notebook {
  int? id;
  int? server_id;
  final int subject_id;
  final String title;
  final String cover_type;
  final String? color;
  final String? cover_image;
  final String? line_type;
  final String? paper_size;
  int synced_with_cloud;

  Notebook({
    this.id,
    this.server_id,
    required this.subject_id,
    required this.title,
    required this.cover_type,
    this.color,
    this.cover_image,
    this.line_type,
    this.paper_size,
    this.synced_with_cloud = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id, // 🚀 SÓ ENVIA O ID SE ELE EXISTIR
      'server_id': server_id,
      'subject_id': subject_id,
      'title': title,
      'cover_type': cover_type,
      'color': color,
      'cover_image': cover_image,
      'line_type': line_type,
      'paper_size': paper_size,
      'synced_with_cloud': synced_with_cloud,
    };
  }

  factory Notebook.fromMap(Map<String, dynamic> map) {
    return Notebook(
      id: map['id'] as int?,
      server_id: map['server_id'] as int?,
      subject_id: map['subject_id'] as int,
      title: map['title'] as String,
      cover_type: map['cover_type'] as String,
      color: map['color'] as String?,
      cover_image: map['cover_image'] as String?,
      line_type: map['line_type'] as String?,
      paper_size: map['paper_size'] as String?,
      synced_with_cloud: map['synced_with_cloud'] as int? ?? 0,
    );
  }
}