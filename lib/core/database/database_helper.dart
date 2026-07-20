import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static const _databaseName = "caderno_digital_offline_v9.db";
  static const _databaseVersion = 1;

  DatabaseHelper._privateConstructor();
  static final DatabaseHelper instance = DatabaseHelper._privateConstructor();

  static Database? _database;
  static bool _isInitializing = false;

  Future<Database> get database async {
    if (_database != null) return _database!;
    
    // 🛡️ Proteção contra chamadas simultâneas
    while (_isInitializing) {
      await Future.delayed(const Duration(milliseconds: 100));
      if (_database != null) return _database!;
    }

    _isInitializing = true;
    try {
      _database = await _initDatabase();
    } finally {
      _isInitializing = false;
    }
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path;

    if (kIsWeb) {
      // 🚀 NA WEB: Ativa o motor WebAssembly / IndexedDB
      databaseFactory = databaseFactoryFfiWeb;
      path = _databaseName; // Na Web, o motor gere o sistema de ficheiros virtual no IndexedDB
    } else if (Platform.isWindows || Platform.isLinux || Platform.isMacOS) {
      // 🖥️ NO DESKTOP: Windows / Linux / macOS
      sqfliteFfiInit();
      databaseFactory = databaseFactoryFfi;
      path = join(await getDatabasesPath(), _databaseName);
    } else {
      // 📱 NO MOBILE: Android / iOS
      path = join(await getDatabasesPath(), _databaseName);
    }

    // Chamada única e universal para todas as plataformas!
    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
    );
  }
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NULL,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        avatar TEXT,
        plan_type TEXT DEFAULT 'free',
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE subjects (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NULL,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        color TEXT NOT NULL,
        icon TEXT,
        is_deleted INTEGER DEFAULT 0,
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE notebooks (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NULL,
        subject_id INTEGER NULL,
        title TEXT NOT NULL,
        cover_type TEXT NOT NULL,
        color TEXT,
        cover_image TEXT,
        line_type TEXT,
        paper_size TEXT,
        is_published INTEGER DEFAULT 0,
        price REAL DEFAULT 0.00,
        description TEXT,
        author_name TEXT,
        is_deleted INTEGER DEFAULT 0,
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        FOREIGN KEY (subject_id) REFERENCES subjects (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE pages (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NULL,
        notebook_id INTEGER NOT NULL,
        page_number INTEGER NOT NULL,
        is_landscape INTEGER DEFAULT 0, 
        header_data TEXT, 
        footer_data TEXT,
        is_deleted INTEGER DEFAULT 0,
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        FOREIGN KEY (notebook_id) REFERENCES notebooks (id) ON DELETE CASCADE
      )
    ''');

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

    await db.execute('''
      CREATE TABLE notebook_user (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        server_id INTEGER NULL,
        notebook_id INTEGER NOT NULL,
        user_id INTEGER NOT NULL,
        role TEXT NOT NULL DEFAULT 'viewer',
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        FOREIGN KEY (notebook_id) REFERENCES notebooks (id) ON DELETE CASCADE,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

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
        item_type TEXT DEFAULT 'subscription',
        item_id INTEGER NULL,
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        FOREIGN KEY (user_id) REFERENCES users (id) ON DELETE CASCADE
      )
    ''');

    await db.execute('''
      CREATE TABLE canvas_image_blocks (
        client_image_id TEXT PRIMARY KEY,
        server_id INTEGER NULL,
        page_id INTEGER NOT NULL,
        image_path TEXT NOT NULL,
        pos_x REAL NOT NULL,
        pos_y REAL NOT NULL,
        width REAL NOT NULL,
        height REAL NOT NULL,
        rotation REAL NOT NULL,
        is_deleted INTEGER DEFAULT 0,
        synced_with_cloud INTEGER DEFAULT 0,
        updated_at INTEGER DEFAULT 0,
        FOREIGN KEY (page_id) REFERENCES pages (id) ON DELETE CASCADE
      )
    ''');
  }

  Future<void> clearAllData() async {
    final db = await database;
    final List<String> alvos = [
      'canvas_image_blocks',
      'canvas_text_blocks',
      'canvas_strokes',
      'pages',
      'notebook_user',
      'notebooks',
      'subjects',
      'payments',
      'users'
    ];

    for (String tabela in alvos) {
      try {
        await db.delete(tabela);
      } catch (_) {}
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('last_subjects_sync');
    await prefs.remove('last_notebooks_sync');
    await prefs.remove('last_pages_sync');
  }
}
