import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:sqflite/sqflite.dart';
import '../database/database_helper.dart';
import '../../features/notebooks/models/drawing_point_model.dart';

class LocalDatabaseService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 📥 SALVA A ESTRUTURA DE METADADOS DA PÁGINA
  Future<int> savePageMetadata(LocalPage page) async {
    final db = await _dbHelper.database;
    if (page.id != null) {
      await db.update(
        'pages',
        page.toDatabaseMap(),
        where: 'id = ?',
        whereArgs: [page.id],
      );
      return page.id!;
    } else {
      return await db.insert('pages', page.toDatabaseMap());
    }
  }

  // 📥 SALVA UM TRAÇO VETORIAL ISOLADO
  Future<void> saveStrokeLocally(int pageId, Stroke stroke) async {
    final db = await _dbHelper.database;
    await db.insert(
      'canvas_strokes',
      {
        'client_stroke_id': stroke.id,
        'page_id': pageId,
        'stroke_data': jsonEncode(stroke.toMap()),
        'is_deleted': 0,
        'synced_with_cloud': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 📥 SALVA UM BLOCO DE TEXTO ISOLADO
  Future<void> saveTextBlockLocally(int pageId, TextBlock block) async {
    final db = await _dbHelper.database;
    await db.insert(
      'canvas_text_blocks',
      {
        'client_text_id': block.id,
        'page_id': pageId,
        'text_data': jsonEncode(block.toMap()),
        'is_deleted': 0,
        'synced_with_cloud': 0,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // =========================================================================
  // 🚀 NOVO: SALVA UM BLOCO DE IMAGEM ISOLADO (O que te faltava!)
  // =========================================================================
  Future<void> saveImageBlockLocally(int pageId, ImageBlock img) async {
    final db = await _dbHelper.database;
    await db.insert(
      'canvas_image_blocks',
      {
        'client_image_id': img.id,
        'page_id': pageId,
        'image_path': img.imageFile.path,
        'pos_x': img.position.dx,
        'pos_y': img.position.dy,
        'scale': img.width,       // Guardamos a largura no campo scale
        'rotation': img.height,   // Guardamos a altura no campo rotation
        'is_deleted': 0,
        'synced_with_cloud': 0,
        'updated_at': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // 📤 CARREGA UMA PÁGINA COMPLETA COM TUDO O QUE LHE PERTENCE
  Future<List<LocalPage>> getFullPagesForNotebook(int notebookId) async {
    final db = await _dbHelper.database;

    final pageMaps = await db.query(
        'pages',
        where: 'notebook_id = ?',
        whereArgs: [notebookId],
        orderBy: 'page_number ASC'
    );

    List<LocalPage> fullPages = [];

    for (var pMap in pageMaps) {
      final page = LocalPage.fromDatabaseMap(pMap);
      final pId = page.id;

      if (pId != null) {
        // 1. Busca Traços
        final strokeMaps = await db.query('canvas_strokes', where: 'page_id = ? AND is_deleted = 0', whereArgs: [pId]);
        page.strokes = strokeMaps.map((s) {
          final data = jsonDecode(s['stroke_data'] as String);
          return Stroke.fromMap(data);
        }).toList();

        // 2. Busca Textos
        final textMaps = await db.query('canvas_text_blocks', where: 'page_id = ? AND is_deleted = 0', whereArgs: [pId]);
        page.textBlocks = textMaps.map((t) {
          final data = jsonDecode(t['text_data'] as String);
          return TextBlock.fromMap(data);
        }).toList();

        // 3. 🚀 Busca Imagens (BLINDADO CONTRA CRASHES DE TIPO)
        final imgMaps = await db.query('canvas_image_blocks', where: 'page_id = ? AND is_deleted = 0', whereArgs: [pId]);

        final List<ImageBlock> safeImages = [];

        for (var m in imgMaps) {
          final String path = m['image_path'].toString();
          final File f = File(path);

          // Só desenha se a foto física ainda existir no disco do telemóvel!
          if (f.existsSync()) {
            safeImages.add(
                ImageBlock(
                  id: m['client_image_id'].toString(),
                  imageFile: f,
                  position: Offset(
                    (m['pos_x'] as num).toDouble(), // 🛡️ Imune ao corte de decimais do Android
                    (m['pos_y'] as num).toDouble(),
                  ),
                  width: (m['scale'] as num).toDouble(),
                  height: (m['rotation'] as num).toDouble(),
                  rotation: 0.0,
                )
            );
          }
        }

        page.imageBlocks = safeImages;
      }

      fullPages.add(page);
    }

    return fullPages;
  }
}