import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart' as pdf_pkg;
import 'package:pdf/widgets.dart' as pw;
import 'package:open_filex/open_filex.dart';
import 'package:http/http.dart' as http;

import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_configuration.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/models/page_object.dart';
import 'package:caderno_digital_app/features/canvas/models/stroke_model.dart';
import 'package:caderno_digital_app/features/canvas/models/text_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/image_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/shape_model.dart';
import 'package:caderno_digital_app/features/canvas/models/audio_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/animation_object_model.dart';
import 'package:caderno_digital_app/features/canvas/models/table_model.dart';
import 'package:caderno_digital_app/features/canvas/models/table_cell_model.dart';
import 'package:caderno_digital_app/features/canvas/models/table_types.dart';
import 'package:caderno_digital_app/features/canvas/models/link_model.dart';
import 'package:caderno_digital_app/features/canvas/models/attachment_model.dart';
import 'package:caderno_digital_app/features/canvas/models/canvas_enums.dart';
import 'package:caderno_digital_app/features/canvas/repositories/canvas_repository.dart';
import 'package:caderno_digital_app/features/canvas/widgets/canvas_painter.dart';
import 'package:caderno_digital_app/features/canvas/widgets/background_engine.dart';
import 'package:caderno_digital_app/features/explanations/models/explanation_model.dart';
import 'package:caderno_digital_app/features/explanations/widgets/animators/math_animator.dart';
import 'package:caderno_digital_app/features/explanations/widgets/animators/physics_animator.dart';
import 'package:caderno_digital_app/features/explanations/widgets/animators/engineering_animator.dart';

class PdfExportResult {
  final String? filePath;
  final String? error;

  PdfExportResult({this.filePath, this.error});

  bool get isSuccess => error == null && filePath != null;
}

class PdfExportService {
  /// Exporta um caderno completo para PDF
  static Future<PdfExportResult> exportNotebookToPdf({
    required Notebook notebook,
    required List<LocalPage> pages,
    CanvasRepository? canvasRepository,
    bool openAfterExport = true,
  }) async {
    if (pages.isEmpty) {
      return PdfExportResult(error: 'O caderno não possui páginas para exportar.');
    }

    try {
      final pdfDoc = pw.Document();

      for (var page in pages) {
        // 🚀 Assegurar que a página possui todo o seu conteúdo carregado antes de rasterizar
        LocalPage pageToRasterize = page;
        if ((!pageToRasterize.isContentLoaded || pageToRasterize.objects.isEmpty) && canvasRepository != null) {
          final loadedPage = await canvasRepository.getPageByClientId(page.clientId);
          if (loadedPage != null) {
            pageToRasterize = loadedPage;
          }
        }

        final Uint8List? pagePngBytes = await _rasterizePageToPng(pageToRasterize);
        if (pagePngBytes != null && pagePngBytes.isNotEmpty) {
          final pdfImage = pw.MemoryImage(pagePngBytes);
          
          final pageFormat = pageToRasterize.isLandscape 
              ? pdf_pkg.PdfPageFormat.a4.landscape 
              : pdf_pkg.PdfPageFormat.a4;

          pdfDoc.addPage(
            pw.Page(
              pageFormat: pageFormat,
              margin: pw.EdgeInsets.zero,
              build: (pw.Context context) {
                return pw.FullPage(
                  ignoreMargins: true,
                  child: pw.Image(pdfImage, fit: pw.BoxFit.contain),
                );
              },
            ),
          );
        }
      }

      final appDir = await getApplicationDocumentsDirectory();
      final exportsDir = Directory('${appDir.path}/exports');
      if (!await exportsDir.exists()) {
        await exportsDir.create(recursive: true);
      }

      final sanitizedTitle = notebook.title.replaceAll(RegExp(r'[^\w\s\-]'), '_').trim();
      final String exportPath = '${exportsDir.path}/${sanitizedTitle}_${DateTime.now().millisecondsSinceEpoch}.pdf';

      final file = File(exportPath);
      await file.writeAsBytes(await pdfDoc.save());

      if (openAfterExport) {
        await OpenFilex.open(exportPath);
      }

      return PdfExportResult(filePath: exportPath);
    } catch (e, stack) {
      debugPrint('🚨 [PdfExportService] Erro ao exportar PDF: $e\n$stack');
      return PdfExportResult(error: 'Erro ao exportar PDF: $e');
    }
  }

  /// Converte uma LocalPage inteira (Fundo PDF + Padrão + Traços + Todos os Objetos) em PNG
  static Future<Uint8List?> _rasterizePageToPng(LocalPage page) async {
    final double width = page.pageWidthPx;
    final double height = page.pageHeightPx;

    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // 1. Fundo Branco Base
    canvas.drawRect(Rect.fromLTWH(0, 0, width, height), Paint()..color = Colors.white);

    // 2. Fundo PDF se existir (Local ou Remoto)
    bool hasPdfBg = false;
    if (page.backgroundPdfPath != null && page.backgroundPdfPath!.isNotEmpty) {
      final bgPath = page.backgroundPdfPath!;
      try {
        ui.Image? bgImg;
        if (bgPath.startsWith('http')) {
          final response = await http.get(Uri.parse(bgPath));
          if (response.statusCode == 200) {
            final codec = await ui.instantiateImageCodec(response.bodyBytes);
            final frame = await codec.getNextFrame();
            bgImg = frame.image;
          }
        } else if (File(bgPath).existsSync()) {
          final bytes = await File(bgPath).readAsBytes();
          final codec = await ui.instantiateImageCodec(bytes);
          final frame = await codec.getNextFrame();
          bgImg = frame.image;
        }

        if (bgImg != null) {
          canvas.drawImageRect(
            bgImg,
            Rect.fromLTWH(0, 0, bgImg.width.toDouble(), bgImg.height.toDouble()),
            Rect.fromLTWH(0, 0, width, height),
            Paint(),
          );
          hasPdfBg = true;
        }
      } catch (e) {
        debugPrint('🚨 Erro ao carregar imagem de fundo PDF para rasterização: $e');
      }
    }

    // 3. Fundo Padrão (linhas/quadriculado, pautado, pontilhado, etc.)
    if (!hasPdfBg) {
      BackgroundConfig? effectiveBgConfig = page.backgroundConfig;
      if (effectiveBgConfig == null && page.lineType != null && page.lineType != 'blank') {
        effectiveBgConfig = BackgroundConfig(
          type: page.lineType!,
          spacing: page.lineSpacing ?? 8.0,
        );
      }
      effectiveBgConfig ??= page.toConfig.background;

      if (effectiveBgConfig.type != 'blank' || effectiveBgConfig.color != null) {
        BackgroundEngine.draw(canvas, Size(width, height), page.toConfig, effectiveBgConfig);
      }
    }

    // 4. Mapear visibilidade de camadas
    final Map<String, bool> layerVisibility = {
      for (var l in page.layers) l.id: l.isVisible
    };

    // 5. Filtrar e Ordenar Todos os Objetos por zIndex
    final List<PageObject> sortedObjects = page.objects.where((o) {
      if (o.isDeleted || !o.isVisible) return false;
      final bool layerVisible = layerVisibility[o.layerId ?? 'default'] ?? true;
      return layerVisible;
    }).toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));

    // 6. Desenhar Todos os Objetos na ordem correta de zIndex
    for (var object in sortedObjects) {
      if (object is Stroke) {
        _renderStroke(canvas, object);
      } else if (object is TextBlock) {
        _renderTextBlock(canvas, object, width);
      } else if (object is ImageBlock) {
        await _renderImageBlock(canvas, object);
      } else if (object is ShapeObject) {
        _renderShapeObject(canvas, object);
      } else if (object is TableObject) {
        _renderTableObject(canvas, object);
      } else if (object is LinkObject) {
        _renderLinkObject(canvas, object);
      } else if (object is AttachmentObject) {
        _renderAttachmentObject(canvas, object);
      } else if (object is AudioBlock) {
        _renderAudioBlock(canvas, object);
      } else if (object is AnimationObject) {
        _renderAnimationObject(canvas, object);
      } else if (object is ExplanationModel) {
        _renderExplanationModel(canvas, object);
      }
    }

    // Finalizar a gravação
    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    return byteData?.buffer.asUint8List();
  }

  /// Renderiza Traço Artístico
  static void _renderStroke(Canvas canvas, Stroke stroke) {
    final path = buildPath(stroke.points);
    final strokeColor = Color(int.parse(stroke.color.replaceFirst('#', '0xFF')));
    renderArtisticStroke(
      canvas: canvas,
      path: path,
      brushType: stroke.brushType,
      color: strokeColor,
      thickness: stroke.thickness,
      opacity: stroke.opacity,
      isHighlighter: stroke.isHighlighter,
      points: stroke.points,
    );
  }

  /// Renderiza Bloco de Texto
  static void _renderTextBlock(Canvas canvas, TextBlock tb, double pageMaxWidth) {
    canvas.save();
    canvas.translate(tb.position.dx, tb.position.dy);
    if (tb.rotation != 0) {
      canvas.rotate(tb.rotation);
    }

    // Fundo do bloco de texto
    if (tb.backgroundColorHex != null) {
      final bgPaint = Paint()..color = Color(int.parse(tb.backgroundColorHex!.replaceFirst('#', '0xFF')));
      canvas.drawRRect(
        RRect.fromRectAndRadius(Offset.zero & tb.size, const Radius.circular(4)),
        bgPaint,
      );
    }

    final List<String> lines = tb.text.split('\n');
    final Color textColor = Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF')));
    final Map<int, int> levelCounters = {};
    double currentY = 0;

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      int spaces = 0;
      for (int c = 0; c < line.length; c++) {
        if (line[c] == ' ') {
          spaces++;
        } else {
          break;
        }
      }
      int level = spaces ~/ 2;

      String prefix = '';
      if (tb.listType == ListType.bullet) {
        prefix = level == 0 ? '• ' : (level == 1 ? '◦ ' : '▪ ');
      } else if (tb.listType == ListType.numbered) {
        levelCounters.removeWhere((k, v) => k > level);
        levelCounters[level] = (levelCounters[level] ?? 0) + 1;
        if (level == 1) {
          prefix = '${String.fromCharCode(96 + (levelCounters[level]! % 26))}. ';
        } else if (level >= 2) {
          prefix = '- ';
        } else {
          prefix = '${levelCounters[level]}. ';
        }
      } else if (tb.listType == ListType.checklist) {
        final bool isChecked = tb.checkedLineIndices.contains(i);
        prefix = isChecked ? '☑ ' : '☐ ';
      }

      final String displayLine = prefix + (tb.listType == ListType.none ? line : line.trimLeft());

      final textStyle = TextStyle(
        fontSize: tb.fontSize,
        color: textColor,
        fontWeight: tb.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: tb.isItalic ? FontStyle.italic : FontStyle.normal,
        decoration: TextDecoration.combine([
          if (tb.isUnderline) TextDecoration.underline,
          if (tb.isStrikethrough) TextDecoration.lineThrough,
        ]),
      );

      final span = TextSpan(text: displayLine, style: textStyle);
      final tp = TextPainter(
        text: span,
        textAlign: tb.textAlign,
        textDirection: TextDirection.ltr,
      );

      final double tbWidth = tb.size.width > 0 ? tb.size.width : pageMaxWidth;
      tp.layout(maxWidth: tbWidth);
      tp.paint(canvas, Offset(0, currentY));
      currentY += tp.height;
    }

    canvas.restore();
  }

  /// Renderiza Bloco de Imagem com Rotação, Escala e Recorte
  static Future<void> _renderImageBlock(Canvas canvas, ImageBlock img) async {
    if (!File(img.imagePath).existsSync()) return;
    try {
      final bytes = await File(img.imagePath).readAsBytes();
      final codec = await ui.instantiateImageCodec(bytes);
      final frame = await codec.getNextFrame();
      final uiImg = frame.image;

      canvas.save();
      canvas.translate(img.position.dx + img.width / 2, img.position.dy + img.height / 2);
      if (img.rotation != 0) canvas.rotate(img.rotation);
      canvas.translate(-img.width / 2, -img.height / 2);

      final paint = Paint();
      if (img.opacity < 1.0) {
        paint.color = Colors.white.withValues(alpha: img.opacity);
      }

      if (img.cropRect != null) {
        final crop = img.cropRect!;
        final srcRect = Rect.fromLTWH(
          crop.left * uiImg.width,
          crop.top * uiImg.height,
          crop.width * uiImg.width,
          crop.height * uiImg.height,
        );
        final dstRect = Rect.fromLTWH(0, 0, img.width, img.height);
        canvas.drawImageRect(uiImg, srcRect, dstRect, paint);
      } else {
        canvas.drawImageRect(
          uiImg,
          Rect.fromLTWH(0, 0, uiImg.width.toDouble(), uiImg.height.toDouble()),
          Rect.fromLTWH(0, 0, img.width, img.height),
          paint,
        );
      }
      canvas.restore();
    } catch (e) {
      debugPrint('🚨 Erro ao rasterizar ImageBlock: $e');
    }
  }

  /// Renderiza Forma Geométrica
  static void _renderShapeObject(Canvas canvas, ShapeObject shape) {
    canvas.save();
    canvas.translate(shape.position.dx + shape.size.width / 2, shape.position.dy + shape.size.height / 2);
    if (shape.rotation != 0) canvas.rotate(shape.rotation);
    canvas.translate(-shape.size.width / 2, -shape.size.height / 2);

    final size = shape.size;
    final strokeColor = Color(int.parse(shape.strokeColor.replaceFirst('#', '0xFF')));

    if (shape.fillColor != null && shape.isClosed) {
      final fillPaint = Paint()
        ..color = Color(int.parse(shape.fillColor!.replaceFirst('#', '0xFF')))
        ..style = PaintingStyle.fill;
      _drawShapePath(canvas, size, shape.shapeType, fillPaint);
    }

    final strokePaint = Paint()
      ..color = strokeColor
      ..strokeWidth = shape.strokeWidth
      ..style = PaintingStyle.stroke;
    _drawShapePath(canvas, size, shape.shapeType, strokePaint);

    canvas.restore();
  }

  static void _drawShapePath(Canvas canvas, Size size, ShapeType type, Paint paint) {
    switch (type) {
      case ShapeType.rectangle:
        canvas.drawRect(Offset.zero & size, paint);
        break;
      case ShapeType.circle:
        canvas.drawOval(Offset.zero & size, paint);
        break;
      case ShapeType.line:
        canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint);
        break;
      case ShapeType.triangle:
        final path = Path()
          ..moveTo(size.width / 2, 0)
          ..lineTo(size.width, size.height)
          ..lineTo(0, size.height)
          ..close();
        canvas.drawPath(path, paint);
        break;
      case ShapeType.arrow:
        final start = Offset.zero;
        final end = Offset(size.width, size.height);
        canvas.drawLine(start, end, paint);
        final double angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
        const double arrowSize = 15.0;
        const double arrowAngle = math.pi / 6;
        final path = Path()
          ..moveTo(end.dx, end.dy)
          ..lineTo(end.dx - arrowSize * math.cos(angle - arrowAngle), end.dy - arrowSize * math.sin(angle - arrowAngle))
          ..moveTo(end.dx, end.dy)
          ..lineTo(end.dx - arrowSize * math.cos(angle + arrowAngle), end.dy - arrowSize * math.sin(angle + arrowAngle));
        canvas.drawPath(path, paint);
        break;
    }
  }

  /// Renderiza Tabela Completa (Fundo de Células, Conteúdo e Grades)
  static void _renderTableObject(Canvas canvas, TableObject table) {
    canvas.save();
    canvas.translate(table.position.dx, table.position.dy);

    final Color borderColor = Color(int.parse(table.borderColor.replaceFirst('#', '0xFF')));

    // Fundo da Tabela
    final tableBgColor = table.tableBackgroundColorHex != null
        ? Color(int.parse(table.tableBackgroundColorHex!.replaceFirst('#', '0xFF')))
        : Colors.white;
    canvas.drawRect(Offset.zero & table.size, Paint()..color = tableBgColor);

    // Renderizar Células
    final Set<CellCoordinate> occupied = {};
    for (int r = 0; r < table.rows; r++) {
      for (int c = 0; c < table.cols; c++) {
        final coord = CellCoordinate(r, c);
        if (occupied.contains(coord)) continue;

        int rs = 1, cs = 1;
        if (table.cellSpans.containsKey(coord)) {
          final span = table.cellSpans[coord]!;
          rs = span.row;
          cs = span.col;
        }
        for (int ir = 0; ir < rs; ir++) {
          for (int ic = 0; ic < cs; ic++) {
            occupied.add(CellCoordinate(r + ir, c + ic));
          }
        }

        final cell = table.cells[coord] ?? TableCellModel();
        final Offset offset = table.getCellOffset(coord);
        final Size size = table.getCellSize(coord);

        // Fundo da célula
        if (cell.style.backgroundColorHex != null) {
          final cellBg = Color(int.parse(cell.style.backgroundColorHex!.replaceFirst('#', '0xFF')));
          canvas.drawRect(Rect.fromLTWH(offset.dx, offset.dy, size.width, size.height), Paint()..color = cellBg);
        }

        // Conteúdo da célula
        if (cell.type == TableCellType.checkbox) {
          final bool checked = cell.value == 'true';
          final checkPaint = Paint()
            ..color = const Color(0xFF0F4C5C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 2.0;
          final rect = Rect.fromCenter(
            center: Offset(offset.dx + size.width / 2, offset.dy + size.height / 2),
            width: 16,
            height: 16,
          );
          canvas.drawRect(rect, checkPaint);
          if (checked) {
            canvas.drawLine(rect.topLeft + const Offset(3, 8), rect.bottomLeft + const Offset(7, -3), checkPaint);
            canvas.drawLine(rect.bottomLeft + const Offset(7, -3), rect.topRight + const Offset(-3, 4), checkPaint);
          }
        } else if (cell.value.isNotEmpty) {
          final cellTextColor = Color(int.parse(cell.style.textColorHex.replaceFirst('#', '0xFF')));
          final textStyle = TextStyle(
            fontSize: cell.style.fontSize,
            color: cellTextColor,
            fontWeight: cell.style.bold ? FontWeight.bold : FontWeight.normal,
            fontStyle: cell.style.italic ? FontStyle.italic : FontStyle.normal,
            decoration: TextDecoration.combine([
              if (cell.style.underline) TextDecoration.underline,
              if (cell.style.strikethrough) TextDecoration.lineThrough,
            ]),
          );

          final span = TextSpan(text: cell.value, style: textStyle);
          final tp = TextPainter(
            text: span,
            textAlign: cell.style.textAlign,
            textDirection: TextDirection.ltr,
          );
          tp.layout(maxWidth: math.max(10, size.width - 8));

          double textY = offset.dy + 4;
          if (cell.style.verticalAlign == 1) { // centro
            textY = offset.dy + (size.height - tp.height) / 2;
          } else if (cell.style.verticalAlign == 2) { // baixo
            textY = offset.dy + size.height - tp.height - 4;
          }

          tp.paint(canvas, Offset(offset.dx + 4, textY));
        }
      }
    }

    // Desenhar Borda Externa
    final borderPaint = Paint()
      ..color = borderColor
      ..strokeWidth = table.borderWidth
      ..style = PaintingStyle.stroke;
    _drawStyledRect(canvas, Offset.zero & table.size, borderPaint, table.lineStyle);

    // Desenhar Linhas da Grade Interna
    final gridPaint = Paint()
      ..color = borderColor
      ..strokeWidth = table.internalBorderWidth
      ..style = PaintingStyle.stroke;

    double currentX = 0;
    for (int c = 0; c < table.cols - 1; c++) {
      currentX += table.columnWidths[c];
      _drawStyledLine(canvas, Offset(currentX, 0), Offset(currentX, table.size.height), gridPaint, table.internalLineStyle);
    }

    double currentY = 0;
    for (int r = 0; r < table.rows - 1; r++) {
      currentY += table.rowHeights[r];
      _drawStyledLine(canvas, Offset(0, currentY), Offset(table.size.width, currentY), gridPaint, table.internalLineStyle);
    }

    canvas.restore();
  }

  /// Renderiza Card de Link
  static void _renderLinkObject(Canvas canvas, LinkObject link) {
    canvas.save();
    canvas.translate(link.position.dx, link.position.dy);

    final bgPaint = Paint()..color = Color(int.parse(link.backgroundColor.replaceFirst('#', '0xFF')));
    canvas.drawRRect(RRect.fromRectAndRadius(Offset.zero & link.size, const Radius.circular(8)), bgPaint);

    final textStyle = TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.bold,
      color: Color(int.parse(link.textColor.replaceFirst('#', '0xFF'))),
    );
    final span = TextSpan(text: '🔗 ${link.label}', style: textStyle);
    final tp = TextPainter(text: span, textDirection: TextDirection.ltr);
    tp.layout(maxWidth: link.size.width - 12);
    tp.paint(canvas, Offset(8, (link.size.height - tp.height) / 2));

    canvas.restore();
  }

  /// Renderiza Card de Anexo
  static void _renderAttachmentObject(Canvas canvas, AttachmentObject attach) {
    canvas.save();
    canvas.translate(attach.position.dx, attach.position.dy);

    final bgPaint = Paint()..color = Colors.white;
    final borderPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.15)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & attach.size;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(10)), borderPaint);

    final titleStyle = const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black);
    final titleTp = TextPainter(text: TextSpan(text: '📎 ${attach.fileName}', style: titleStyle), textDirection: TextDirection.ltr);
    titleTp.layout(maxWidth: attach.size.width - 16);
    titleTp.paint(canvas, const Offset(8, 8));

    final sizeStyle = TextStyle(fontSize: 9, color: Colors.black.withValues(alpha: 0.5));
    final sizeTp = TextPainter(
      text: TextSpan(text: '${(attach.fileSize / 1024).toStringAsFixed(1)} KB', style: sizeStyle),
      textDirection: TextDirection.ltr,
    );
    sizeTp.layout(maxWidth: attach.size.width - 16);
    sizeTp.paint(canvas, const Offset(8, 24));

    canvas.restore();
  }

  /// Renderiza Card de Áudio
  static void _renderAudioBlock(Canvas canvas, AudioBlock audio) {
    canvas.save();
    canvas.translate(audio.position.dx, audio.position.dy);

    final bgPaint = Paint()..color = const Color(0xFF0F4C5C).withValues(alpha: 0.1);
    final borderPaint = Paint()
      ..color = const Color(0xFF0F4C5C).withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & audio.size;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(12)), borderPaint);

    final titleStyle = const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F4C5C));
    final titleTp = TextPainter(text: TextSpan(text: '▶ ${audio.title}', style: titleStyle), textDirection: TextDirection.ltr);
    titleTp.layout(maxWidth: audio.size.width - 16);
    titleTp.paint(canvas, const Offset(8, 8));

    final durStr = '${(audio.durationSeconds / 60).floor()}:${(audio.durationSeconds % 60).toString().padLeft(2, '0')}';
    final durStyle = TextStyle(fontSize: 9, color: Colors.black.withValues(alpha: 0.5));
    final durTp = TextPainter(text: TextSpan(text: durStr, style: durStyle), textDirection: TextDirection.ltr);
    durTp.layout(maxWidth: audio.size.width - 16);
    durTp.paint(canvas, const Offset(8, 24));

    canvas.restore();
  }

  /// Renderiza Indicador de Animação
  static void _renderAnimationObject(Canvas canvas, AnimationObject anim) {
    canvas.save();
    canvas.translate(anim.position.dx, anim.position.dy);

    final bgPaint = Paint()..color = const Color(0xFFE36414).withValues(alpha: 0.1);
    final borderPaint = Paint()
      ..color = const Color(0xFFE36414).withValues(alpha: 0.3)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    final rect = Offset.zero & anim.size;
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(8)), borderPaint);

    final style = const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFFE36414));
    final tp = TextPainter(text: TextSpan(text: '🎬 ${anim.assetPath ?? 'Animação'}', style: style), textDirection: TextDirection.ltr);
    tp.layout(maxWidth: anim.size.width - 12);
    tp.paint(canvas, Offset(6, (anim.size.height - tp.height) / 2));

    canvas.restore();
  }

  /// Renderiza Modelo de Explicação
  static void _renderExplanationModel(Canvas canvas, ExplanationModel model) {
    canvas.save();
    canvas.translate(model.position.dx + model.size.width / 2, model.position.dy + model.size.height / 2);
    canvas.scale(model.scale);

    if (model is MathExplanation) {
      MathAnimator().paint(canvas, model.size, model, 0.5);
    } else if (model is PhysicsExplanation) {
      PhysicsAnimator().paint(canvas, model.size, model, 0.5);
    } else if (model is EngineeringExplanation) {
      EngineeringAnimator().paint(canvas, model.size, model, 0.5);
    }

    canvas.restore();
  }

  /// Desenha retângulo com estilo de linha (contínuo, tracejado ou pontilhado)
  static void _drawStyledRect(Canvas canvas, Rect rect, Paint paint, LineStyle style) {
    if (style == LineStyle.continuous) {
      canvas.drawRect(rect, paint);
      return;
    }
    _drawStyledLine(canvas, rect.topLeft, rect.topRight, paint, style);
    _drawStyledLine(canvas, rect.topRight, rect.bottomRight, paint, style);
    _drawStyledLine(canvas, rect.bottomRight, rect.bottomLeft, paint, style);
    _drawStyledLine(canvas, rect.bottomLeft, rect.topLeft, paint, style);
  }

  /// Desenha linha com estilo (contínuo, tracejado ou pontilhado)
  static void _drawStyledLine(Canvas canvas, Offset start, Offset end, Paint paint, LineStyle style) {
    if (style == LineStyle.continuous) {
      canvas.drawLine(start, end, paint);
      return;
    }

    final double thickness = paint.strokeWidth;
    final double distance = (end - start).distance;
    if (distance <= 0) return;

    final Offset direction = (end - start) / distance;

    if (style == LineStyle.dotted) {
      final double dotRadius = math.max(1.0, thickness / 2);
      final double spacing = (thickness * 2.5).clamp(3.0, 30.0);
      double currentPos = 0;
      final Paint dotPaint = Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill;

      while (currentPos <= distance) {
        canvas.drawCircle(start + direction * currentPos, dotRadius, dotPaint);
        currentPos += spacing;
      }
    } else if (style == LineStyle.dashed) {
      final double dashLen = (thickness * 5.0).clamp(5.0, 20.0);
      final double dashSpace = (thickness * 3.0).clamp(3.0, 12.0);
      double currentPos = 0;
      while (currentPos < distance) {
        final double segmentEnd = math.min(currentPos + dashLen, distance);
        canvas.drawLine(start + direction * currentPos, start + direction * segmentEnd, paint);
        currentPos += dashLen + dashSpace;
      }
    }
  }
}
