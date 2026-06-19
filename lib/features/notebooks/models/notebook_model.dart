class Notebook {
  final int? id;
  final int subject_id;
  final String title;
  final String coverType;
  final String? color;
  final String? coverImage;
  final String? lineType;

  Notebook({
    this.id,
    required this.subject_id,
    required this.title,
    required this.coverType,
    this.color,
    this.coverImage,
    this.lineType,
  });

  factory Notebook.fromMap(Map<String, dynamic> map) {
    return Notebook(
      id: map['id'],
      subject_id: map['subject_id'],
      title: map['title'],
      coverType: map['cover_type'],
      color: map['color'],
      coverImage: map['cover_image'],
      lineType: map['line_type'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'subject_id': subject_id,
      'title': title,
      'cover_type': coverType,
      'color': color,
      'cover_image': coverImage,
      'line_type': lineType,
    };
  }
}