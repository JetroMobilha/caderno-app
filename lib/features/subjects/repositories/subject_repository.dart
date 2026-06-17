import 'package:flutter/foundation.dart'; // Contém o kIsWeb
import '../../../core/database/database_helper.dart';
import '../models/subject_model.dart';

class SubjectRepository {
  final _dbHelper = DatabaseHelper.instance;

  // Simulador de cache para a Web enquanto não ligamos o Laravel via API
  final List<Subject> _webCache = [];

  /// Procura todas as disciplinas dependendo da plataforma
  Future<List<Subject>> getSubjects() async {
    if (kIsWeb) {
      // NA WEB: No futuro, isto será um 'http.get' para o teu servidor Laravel
      return _webCache;
    } else {
      // NO MOBILE/DESKTOP: Usa o SQLite estável que já criámos
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query('subjects');
      return maps.map((map) => Subject.fromMap(map)).toList();
    }
  }

  /// Grava uma disciplina de forma adaptativa
  Future<void> insertSubject(Subject subject) async {
    if (kIsWeb) {
      // NA WEB: No futuro, envia um 'http.post' para o Laravel
      _webCache.add(subject);
    } else {
      // NO MOBILE/DESKTOP: Grava no SQL local
      final db = await _dbHelper.database;
      await db.insert('subjects', subject.toMap());
    }
  }
}