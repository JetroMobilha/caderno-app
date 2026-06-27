import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  // 🚀 FORÇA TÁTICA: Mudámos para v4. O Android vai recriar o ficheiro do zero hoje!
  static const _databaseName = "caderno_digital_offline_v4.db";
  static const _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    if (kIsWeb) {
      throw Exception("O SQLite local não é suportado diretamente na Web.");
    }

    if (Platform.isWindows || Platform.isLinux) {
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
    }

    String path = join(await getDatabasesPath(), _databaseName);
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }

  Future _onCreate(Database db, int version) async {
    // 1. Tabela de Utilizadores (users)
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        plan_type TEXT DEFAULT 'free',
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0
      )
    ''');

    // 2. Tabela de Disciplinas (subjects)
    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NULL,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT,
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 3. Tabela de Cadernos (notebooks)
    await db.execute('''
      CREATE TABLE notebooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NULL,
        subject_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        cover_type TEXT NOT NULL,
        color TEXT,
        cover_image TEXT,
        line_type TEXT,
        paper_size TEXT,
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    // 4. Tabela de Páginas (pages)
    await db.execute('''
      CREATE TABLE pages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NULL,
        notebook_id INTEGER NOT NULL,
        page_number INTEGER NOT NULL,
        is_landscape INTEGER DEFAULT 0, 
        header_data TEXT, 
        footer_data TEXT,
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        FOREIGN KEY (notebook_id) REFERENCES notebooks (id) ON DELETE CASCADE
      )
    ''');

    // 5. Motor de Desenho Vetorial (canvas_strokes)
    await db.execute('''
      CREATE TABLE canvas_strokes (
        client_stroke_id TEXT PRIMARY KEY,
        server_id INTEGER NULL,
        page_id INTEGER NOT NULL,
        stroke_data TEXT NOT NULL, 
        is_deleted INTEGER DEFAULT 0,
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        FOREIGN KEY (page_id) REFERENCES pages (id) ON DELETE CASCADE
      )
    ''');

    // 5.1 Motor de Tipografia (canvas_text_blocks)
    await db.execute('''
      CREATE TABLE canvas_text_blocks (
        client_text_id TEXT PRIMARY KEY,
        server_id INTEGER NULL,
        page_id INTEGER NOT NULL,
        text_data TEXT NOT NULL, 
        is_deleted INTEGER DEFAULT 0,
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        FOREIGN KEY (page_id) REFERENCES pages (id) ON DELETE CASCADE
      )
    ''');

    // 6. Tabela Pivô de Partilha (notebook_user)
    await db.execute('''
      CREATE TABLE notebook_user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NULL,
        notebook_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        role TEXT NOT NULL, 
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        FOREIGN KEY (notebook_id) REFERENCES notebooks (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // 7. Tabela de Pagamentos Multicaixa (payments)
    await db.execute('''
      CREATE TABLE payments (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NULL,
        user_id INTEGER NOT NULL,
        amount REAL NOT NULL,
        payment_method TEXT DEFAULT 'multicaixa',
        entity TEXT NOT NULL,
        reference TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    // =========================================================================
    // 🚀 8. MOTOR DE MULTIMÉDIA (canvas_image_blocks) - PURIFICADO E ALINHADO
    // =========================================================================
    await db.execute('''
      CREATE TABLE canvas_image_blocks (
        client_image_id TEXT PRIMARY KEY,
        server_id INTEGER NULL,
        page_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        pos_x REAL NOT NULL,
        pos_y REAL NOT NULL,
        scale REAL NOT NULL,
        rotation REAL NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        FOREIGN KEY (page_id) REFERENCES pages (id) ON DELETE CASCADE
      )
    ''');
  }
}