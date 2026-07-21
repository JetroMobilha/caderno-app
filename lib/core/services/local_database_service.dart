import 'dart:convert';
import 'dart:io';
import 'dart:ui';
import 'package:drift/drift.dart';
import '../../features/canvas/models/image_block_model.dart';
import '../../features/canvas/models/local_page_model.dart';
import '../../features/canvas/models/stroke_model.dart';
import '../../features/canvas/models/text_block_model.dart';
import '../database/app_database.dart';

class LocalDatabaseService {
  final AppDatabase _db = AppDatabase.instance;

  // 📥 SALVA A ESTRUTURA DE METADADOS DA PÁGINA (COM ESCUDO ANTI-AMNÉSIA)
  Future<int> savePageMetadata(LocalPage page) async {
    if (page.id != null) {
      // =======================================================================
      // 🛡️ O ESCUDO ANTI-AMNÉSIA: Espreitar o banco antes de gravar
      // =======================================================================
      final existing = await (_db.select(_db.pages)..where((t) => t.id.equals(page.id!))).getSingleOrNull();

      int? officialServerId = page.serverId;

      // Se o Canvas acha que o server_id é nulo, MAS o banco já recebeu o ID da Nuvem...
      if (officialServerId == null && existing != null) {
        officialServerId = existing.serverId;
      }

      await (_db.update(_db.pages)..where((t) => t.id.equals(page.id!))).write(
        PagesCompanion(
          serverId: Value(officialServerId),
          syncedWithCloud: const Value(0),
          updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
          headerData: Value(page.title),
          footerData: Value(page.footer),
          // Outros campos se necessário
        ),
      );
      return page.id!;
    } else {
      // Se a folha é 100% nova, insere normalmente
      final newId = await _db.into(_db.pages).insert(
        PagesCompanion.insert(
          notebookId: page.notebookId,
          pageNumber: page.pageNumber,
          isLandscape: Value(page.isLandscape ? 1 : 0),
          headerData: Value(page.title),
          footerData: Value(page.footer),
        ),
      );
      return newId;
    }
  }

  // 📥 SALVA UM TRAÇO VETORIAL ISOLADO
  Future<void> saveStrokeLocally(int pageId, Stroke stroke) async {
    await _db.into(_db.canvasStrokes).insertOnConflictUpdate(
      CanvasStrokesCompanion.insert(
        clientStrokeId: stroke.id,
        pageId: pageId,
        strokeData: jsonEncode(stroke.toJson()),
        isDeleted: const Value(0),
        syncedWithCloud: const Value(0),
      ),
    );
  }

  // 📥 SALVA UM BLOCO DE TEXTO ISOLADO
  Future<void> saveTextBlockLocally(int pageId, TextBlock block) async {
    await _db.into(_db.canvasTextBlocks).insertOnConflictUpdate(
      CanvasTextBlocksCompanion.insert(
        clientTextId: block.id,
        pageId: pageId,
        textData: jsonEncode(block.toJson()),
        isDeleted: const Value(0),
        syncedWithCloud: const Value(0),
      ),
    );
  }

  // =========================================================================
  // 🚀 NOVO: SALVA UM BLOCO DE IMAGEM ISOLADO
  // =========================================================================
  Future<void> saveImageBlockLocally(int pageId, ImageBlock img) async {
    await _db.into(_db.canvasImageBlocks).insertOnConflictUpdate(
      CanvasImageBlocksCompanion.insert(
        clientImageId: img.id,
        pageId: pageId,
        imagePath: img.imagePath,
        posX: img.position.dx,
        posY: img.position.dy,
        width: img.width,
        height: img.height,
        rotation: img.rotation,
        isDeleted: const Value(0),
        syncedWithCloud: const Value(0),
        updatedAt: Value(DateTime.now().millisecondsSinceEpoch),
      ),
    );
  }

  // 📤 CARREGA UMA PÁGINA COMPLETA COM TUDO O QUE LHE PERTENCE
  Future<List<LocalPage>> getFullPagesForNotebook(int notebookId) async {
    final pageRows = await (_db.select(_db.pages)
          ..where((t) => t.notebookId.equals(notebookId))
          ..orderBy([(t) => OrderingTerm(expression: t.pageNumber)]))
        .get();

    List<LocalPage> fullPages = [];

    for (var pRow in pageRows) {
      final pId = pRow.id;

      // 1. Busca Traços
      final strokeRows = await (_db.select(_db.canvasStrokes)
            ..where((t) => t.pageId.equals(pId) & t.isDeleted.equals(0)))
          .get();
      final strokes = strokeRows.map((s) {
        final data = jsonDecode(s.strokeData);
        return Stroke.fromJson(data);
      }).toList();

      // 2. Busca Textos
      final textRows = await (_db.select(_db.canvasTextBlocks)
            ..where((t) => t.pageId.equals(pId) & t.isDeleted.equals(0)))
          .get();
      final textBlocks = textRows.map((t) {
        final data = jsonDecode(t.textData);
        return TextBlock.fromJson(data);
      }).toList();

      // 3. Busca Imagens
      final imgRows = await (_db.select(_db.canvasImageBlocks)
            ..where((t) => t.pageId.equals(pId) & t.isDeleted.equals(0)))
          .get();

      final List<ImageBlock> safeImages = [];

      for (var m in imgRows) {
        final String path = m.imagePath;

        // 🛡️ O NOVO ESCUDO: É válido se for um link da internet OU um ficheiro físico no disco!
        final bool isValidImage = path.startsWith('http') || File(path).existsSync();

        if (isValidImage) {
          safeImages.add(
            ImageBlock(
              id: m.clientImageId,
              imagePath: path,
              position: Offset(m.posX, m.posY),
              width: m.width,
              height: m.height,
              rotation: m.rotation,
            ),
          );
        }
      }

      fullPages.add(LocalPage(
        id: pRow.id,
        serverId: pRow.serverId,
        notebookId: pRow.notebookId,
        pageNumber: pRow.pageNumber,
        isLandscape: pRow.isLandscape == 1,
        title: pRow.headerData ?? '',
        footer: pRow.footerData ?? '',
        syncedWithCloud: pRow.syncedWithCloud,
        strokes: strokes,
        textBlocks: textBlocks,
        imageBlocks: safeImages,
      ));
    }

    return fullPages;
  }
}
