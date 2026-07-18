import '../../../core/database/database_helper.dart';
import '../models/subject_model.dart';

class SubjectRepository {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // =========================================================================
  // 📚 LER DISCIPLINAS
  // =========================================================================
  Future<List<Subject>> getAllSubjects() async {
    final db = await _dbHelper.database;
    final List<Map<String, dynamic>> maps = await db.query(
      'subjects',
      where: 'is_deleted = ?',
      whereArgs: [0],
      orderBy: 'name ASC', // Ordena alfabeticamente
    );

    return maps.map((map) => Subject.fromMap(map)).toList();
  }

  // =========================================================================
  // ➕ CRIAR DISCIPLINA
  // =========================================================================
  Future<Subject?> addSubject(Subject subject) async {
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

  // =========================================================================
  // ✏️ ATUALIZAR DISCIPLINA
  // =========================================================================
  Future<void> updateSubject(Subject subject) async {
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

  // =========================================================================
  // 🗑️ APAGAR DISCIPLINA
  // =========================================================================
  Future<void> deleteSubject(Subject subject) async {
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
