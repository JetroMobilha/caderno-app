import 'drawing_point_model.dart';

/// Representa a Página do Caderno mapeada com a tabela 'pages' do Laravel
class NotebookPage {
  final int? id;
  final int notebookId;
  final int pageNumber;
  final Map<String, dynamic>? headerData;
  final List<Stroke> strokeData; // 👈 O array de traços do Canvas
  final Map<String, dynamic>? footerData;

  NotebookPage({
    this.id,
    required this.notebookId,
    required this.pageNumber,
    this.headerData,
    required this.strokeData,
    this.footerData,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'notebook_id': notebookId,
      'page_number': pageNumber,
      'header_data': headerData,
      // Converte a lista de traços para o formato JSON esperado pelo servidor
      'stroke_data': strokeData.map((stroke) => stroke.toMap()).toList(),
      'footer_data': footerData,
    };
  }

  factory NotebookPage.fromMap(Map<String, dynamic> map) {
    final List<dynamic> strokesList = map['stroke_data'] ?? [];
    return NotebookPage(
      id: map['id'],
      notebookId: map['notebook_id'],
      pageNumber: map['page_number'],
      headerData: map['header_data'],
      strokeData: strokesList.map((s) => Stroke.fromMap(s)).toList(),
      footerData: map['footer_data'],
    );
  }
}