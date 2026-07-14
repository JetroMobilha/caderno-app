import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:sqflite/sqflite.dart';
import '../../features/canvas/models/image_block_model.dart';
import '../../features/canvas/models/local_page_model.dart';
import '../../features/canvas/models/stroke_model.dart';
import '../../features/canvas/models/text_block_model.dart';
import '../database/database_helper.dart';

class LocalDatabaseService {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;

  // 📥 SALVA A ESTRUTURA DE METADADOS DA PÁGINA (COM ESCUDO ANTI-AMNÉSIA)
  Future<int> savePageMetadata(LocalPage page) async {
    final db = await _dbHelper.database;

    if (page.id != null) {
      // =======================================================================
      // 🛡️ O ESCUDO ANTI-AMNÉSIA: Espreitar o SQLite antes de gravar
      // =======================================================================
      final existing = await db.query(
        'pages',
        columns: ['server_id'],
        where: 'id = ?',
        whereArgs: [page.id],
      );

      int? officialServerId = page.serverId;

      // Se o Canvas acha que o server_id é nulo, MAS o SQLite já recebeu o ID da Nuvem...
      if (officialServerId == null && existing.isNotEmpty) {
        officialServerId = existing.first['server_id'] as int?;
      }

      // Criamos o mapa original da página
      final Map<String, dynamic> map = page.toDatabaseMap();

      // 🎯 REFORÇO CRÍTICO: Injetamos o ID oficial para nunca mais o perdermos!
      map['server_id'] = officialServerId;

      // Como a folha sofreu alterações (novos desenhos), marcamos para o Radar atuar!
      map['synced_with_cloud'] = 0;
      map['updated_at'] = DateTime.now().millisecondsSinceEpoch;

      await db.update(
        'pages',
        map,
        where: 'id = ?',
        whereArgs: [page.id],
      );
      return page.id!;
    } else {
      // Se a folha é 100% nova, insere normalmente
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
        'image_path': img.imagePath,
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

          // 🛡️ O NOVO ESCUDO: É válido se for um link da internet OU um ficheiro físico no disco!
          final bool isValidImage = path.startsWith('http') || File(path).existsSync();

          if (isValidImage) {
            safeImages.add(
                ImageBlock(
                  id: m['client_image_id'].toString(),
                  imagePath: path, // 🚀 MUDANÇA
                  position: Offset(
                    (m['pos_x'] as num).toDouble(),
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