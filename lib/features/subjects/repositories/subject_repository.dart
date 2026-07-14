import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/network/api_service.dart';
import '../models/subject_model.dart';

class SubjectRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService();

  // =========================================================================
  // 📚 LER DISCIPLINAS
  // =========================================================================
  Future<List<Subject>> getAllSubjects() async {
    if (kIsWeb) {
      final response = await _apiService.get('/subjects');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((s) => Subject(
          id: s['id'],
          serverId: s['id'],
          userId: s['user_id'] ?? 0,
          name: s['name'],
          color: s['color'],
          icon: s['icon'],
          syncedWithCloud: 1,
        )).toList();
      }
      return [];
    } else {
      final db = await _dbHelper.database;
      final List<Map<String, dynamic>> maps = await db.query(
        'subjects',
        where: 'is_deleted = ?',
        whereArgs: [0],
        orderBy: 'name ASC', // Ordena alfabeticamente
      );

      return maps.map((map) => Subject.fromMap(map)).toList();
    }
  }

  // =========================================================================
  // ➕ CRIAR DISCIPLINA
  // =========================================================================
  Future<Subject?> addSubject(Subject subject) async {
    if (kIsWeb) {
      final payload = {
        'name': subject.name,
        'color': subject.color,
        'icon': subject.icon,
      };
      final response = await _apiService.post('/subjects', payload);

      if (response.statusCode == 201 || response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return Subject(
          id: data['id'],
          serverId: data['id'],
          userId: data['user_id'] ?? subject.userId,
          name: data['name'],
          color: data['color'],
          icon: data['icon'],
          syncedWithCloud: 1,
        );
      }
      return null;
    } else {
      final db = await _dbHelper.database;
      final map = {
        'user_id': subject.userId,
        'server_id': null,
        'name': subject.name,
        'color': subject.color,
        'icon': subject.icon,
        'synced_with_cloud': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      };
      final int insertedId = await db.insert('subjects', map);

      return Subject(
        id: insertedId,
        userId: subject.userId,
        serverId: null,
        name: subject.name,
        color: subject.color,
        icon: subject.icon,
        syncedWithCloud: 0,
      );
    }
  }

  // =========================================================================
  // ✏️ ATUALIZAR DISCIPLINA
  // =========================================================================
  Future<void> updateSubject(Subject subject) async {
    if (kIsWeb) {
      final payload = {
        'name': subject.name,
        'color': subject.color,
        'icon': subject.icon,
      };
      await _apiService.put('/subjects/${subject.serverId ?? subject.id}', payload);
    } else {
      if (subject.id == null) return;
      final db = await _dbHelper.database;
      await db.update(
        'subjects',
        {
          'name': subject.name,
          'color': subject.color,
          'icon': subject.icon,
          'synced_with_cloud': 0,
          'updated_at': DateTime.now().millisecondsSinceEpoch,
        },
        where: 'id = ?',
        whereArgs: [subject.id],
      );
    }
  }

  // =========================================================================
  // 🗑️ APAGAR DISCIPLINA
  // =========================================================================
  Future<void> deleteSubject(Subject subject) async {
    if (kIsWeb) {
      await _apiService.delete('/subjects/${subject.serverId ?? subject.id}');
    } else {
      if (subject.id == null) return;
      final db = await _dbHelper.database;
      await db.update(
        'subjects',
        {
        'is_deleted': 1,
        'synced_with_cloud': 0 // O SyncService vai ver isto e avisar o Laravel!
        },
        where: 'id = ?',
        whereArgs: [subject.id],
      );
    }
  }
}