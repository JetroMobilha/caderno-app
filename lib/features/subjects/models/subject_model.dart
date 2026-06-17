/// Modelo que representa uma Disciplina (Subject) no Caderno Digital.
///
/// Faz a ponte entre os dados em memória e a tabela 'subjects' no SQLite.
class Subject {
  /// ID local gerado automaticamente pelo SQLite (usado em modo offline).
  final int? id;

  /// ID real gerado pelo servidor Laravel (nulo até à primeira sincronização).
  final int? serverId;

  /// ID do utilizador dono desta disciplina.
  final int userId;

  /// Nome da disciplina (ex: "Matemática").
  final String name;

  /// Cor da lombada/capa em formato Hexadecimal (ex: "#FF0000").
  final String color;

  /// Ícone representativo da disciplina (opcional).
  final String? icon;

  /// Flag de sincronização: 0 para "Apenas Local", 1 para "Sincronizado com a Cloud".
  final int syncedWithCloud;

  Subject({
    this.id,
    this.serverId,
    required this.userId,
    required this.name,
    required this.color,
    this.icon,
    this.syncedWithCloud = 0,
  });

  /// Constrói um objeto [Subject] a partir de um Map (normalmente vindo da query ao SQLite).
  factory Subject.fromMap(Map<String, dynamic> map) {
    return Subject(
      id: map['id'],
      serverId: map['server_id'],
      userId: map['user_id'],
      name: map['name'],
      color: map['color'],
      icon: map['icon'],
      syncedWithCloud: map['synced_with_cloud'] ?? 0,
    );
  }

  /// Converte o objeto [Subject] num Map para ser guardado nativamente no SQLite.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'server_id': serverId,
      'user_id': userId,
      'name': name,
      'color': color,
      'icon': icon,
      'synced_with_cloud': syncedWithCloud,
    };
  }
}