import 'dart:io';
import 'dart:ui' as ui;
import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart' hide TableCell; // Esconder para evitar colisão
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
import 'package:caderno_digital_app/features/explanations/models/explanation_model.dart';

class PdfExportResult {
  final String? filePath;
  final String? error;

  PdfExportResult({this.filePath, this.error});

  bool get isSuccess => error == null && filePath != null;
}

class PdfExportService {
  /// Exporta um caderno completo para PDF estruturado e vetorial
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
        // 🚀 Assegurar que a página possui todo o seu conteúdo carregado antes de criar a UI do PDF
        LocalPage pageToRasterize = page;
        if ((!pageToRasterize.isContentLoaded || pageToRasterize.objects.isEmpty) && canvasRepository != null) {
          final loadedPage = await canvasRepository.getPageByClientId(page.clientId);
          if (loadedPage != null) {
            pageToRasterize = loadedPage;
          }
        }

        final pw.Widget? pageWidget = await _buildPdfPageWidget(pageToRasterize);
        if (pageWidget != null) {
          final pageFormat = pdf_pkg.PdfPageFormat(
            pageToRasterize.pageWidthPx,
            pageToRasterize.pageHeightPx,
          );

          pdfDoc.addPage(
            pw.Page(
              pageFormat: pageFormat,
              margin: pw.EdgeInsets.zero,
              build: (pw.Context context) {
                return pw.FullPage(
                  ignoreMargins: true,
                  child: pageWidget,
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

  /// Converte uma LocalPage inteira num Widget [pw.Stack] do PDF, iterando cada Object.
  static Future<pw.Widget?> _buildPdfPageWidget(LocalPage page) async {
    final double width = page.pageWidthPx;
    final double height = page.pageHeightPx;
    
    final List<pw.Widget> stackChildren = [];
    
    // 1. Fundo Branco Base
    stackChildren.add(
      pw.Positioned(
        left: 0, top: 0,
        child: pw.Container(
          width: width,
          height: height,
          color: pdf_pkg.PdfColors.white,
        ),
      )
    );
    
    // 2. Fundo PDF se existir (Tratado como MemoryImage para o fundo do Stack)
    bool hasPdfBg = false;
    if (page.backgroundPdfPath != null && page.backgroundPdfPath!.isNotEmpty) {
      final bgPath = page.backgroundPdfPath!;
      try {
        Uint8List? bgBytes;
        if (bgPath.startsWith('http')) {
          final response = await http.get(Uri.parse(bgPath));
          if (response.statusCode == 200) {
            bgBytes = response.bodyBytes;
          }
        } else if (File(bgPath).existsSync()) {
          bgBytes = await File(bgPath).readAsBytes();
        }
        
        if (bgBytes != null) {
          final pdfImage = pw.MemoryImage(bgBytes);
          stackChildren.add(
            pw.Positioned(
              left: 0, top: 0,
              child: pw.Image(pdfImage, width: width, height: height, fit: pw.BoxFit.fill),
            )
          );
          hasPdfBg = true;
        }
      } catch (e) {
        debugPrint('🚨 Erro ao carregar imagem de fundo PDF para estruturação: $e');
      }
    }
    
    // 3. Fundo Padrão Vetorial (linhas, quadriculado, pontilhado, etc.)
    if (!hasPdfBg) {
      stackChildren.add(
        pw.Positioned(
          left: 0, top: 0,
          child: _buildStandardBackground(page, width, height),
        )
      );
    }
    
    // 4. Mapear visibilidade de camadas
    final Map<String, bool> layerVisibility = {
      for (var l in page.layers) l.id: l.isVisible
    };

    // 5. Filtrar e Ordenar Todos os Objetos por zIndex
    final List<PageObject> sortedObjects = page.objects.where((o) {
      if (o.isDeleted || !o.isVisible) return false;
      
      // 🚀 Ignorar objetos multimédia/interativos que só fazem sentido no Canvas Digital
      if (o is AudioBlock || o is AttachmentObject || o is AnimationObject || o is ExplanationModel) {
        return false;
      }

      final bool layerVisible = layerVisibility[o.layerId ?? 'default'] ?? true;
      return layerVisible;
    }).toList()
      ..sort((a, b) => a.zIndex.compareTo(b.zIndex));
      
    // 6. Converter Objetos em Widgets
    for (var object in sortedObjects) {
      final widget = await _buildObjectWidget(object, width, height);
      if (widget != null) {
        stackChildren.add(widget);
      }
    }
    
    return pw.SizedBox(
      width: width,
      height: height,
      child: pw.Stack(
        children: stackChildren,
      ),
    );
  }

  /// Converte Cores HEX para o padrão do PDF
  static pdf_pkg.PdfColor _hexToPdfColor(String hex) {
    try {
      final cleanHex = hex.replaceFirst('#', '').padLeft(8, 'F');
      final val = int.parse(cleanHex, radix: 16);
      return pdf_pkg.PdfColor.fromInt(val);
    } catch (_) {
      return pdf_pkg.PdfColors.black;
    }
  }

  /// Renderiza o Background Standard nativamente em vetores PDF via [pw.CustomPaint]
  static pw.Widget _buildStandardBackground(LocalPage page, double width, double height) {
    return pw.CustomPaint(
      size: pdf_pkg.PdfPoint(width, height),
      painter: (pdf_pkg.PdfGraphics canvas, pdf_pkg.PdfPoint size) {
        final lineType = page.lineType;
        final double spacing = page.lineSpacing ?? 28.0;
        final bgConfig = page.backgroundConfig;
        
        final lineColorHex = bgConfig?.lineColor ?? '#E0E0E0';
        final pdf_pkg.PdfColor lineColor = _hexToPdfColor(lineColorHex);
        canvas.setStrokeColor(lineColor);
        canvas.setLineWidth(1.0);
        
        // Fundo com cor base
        final baseColorHex = bgConfig?.color ?? '#FFFFFF';
        final pdf_pkg.PdfColor baseColor = _hexToPdfColor(baseColorHex);
        canvas.setFillColor(baseColor);
        canvas.drawRect(0, 0, width, height);
        canvas.fillPath();
        
        if (lineType == 'ruled') {
          for (double y = spacing; y < height; y += spacing) {
            canvas.drawLine(0, height - y, width, height - y); // pdf origin é bottom-left!
          }
          canvas.strokePath();
          // Margem vermelha (se tiver configurada)
          if (bgConfig?.showRedMargin == true) {
            canvas.setStrokeColor(pdf_pkg.PdfColors.red300);
            canvas.drawLine(width * 0.1, 0, width * 0.1, height);
            canvas.strokePath();
          }
        } else if (lineType == 'grid') {
          for (double y = spacing; y < height; y += spacing) {
            canvas.drawLine(0, height - y, width, height - y);
          }
          for (double x = spacing; x < width; x += spacing) {
            canvas.drawLine(x, 0, x, height);
          }
          canvas.strokePath();
        } else if (lineType == 'dotted') {
           canvas.setFillColor(lineColor);
           for (double y = spacing; y < height; y += spacing) {
             for (double x = spacing; x < width; x += spacing) {
               canvas.drawEllipse(x, height - y, 1.0, 1.0);
             }
           }
           canvas.fillPath();
        }
      }
    );
  }

  /// Despachador do mapeamento `PageObject` -> `pw.Widget`
  static Future<pw.Widget?> _buildObjectWidget(PageObject object, double pageWidth, double pageHeight) async {
    if (object is Stroke) {
      return _buildStroke(object, pageWidth, pageHeight);
    } else if (object is TextBlock) {
      return _buildTextBlock(object, pageWidth);
    } else if (object is ImageBlock) {
      return await _buildImageBlock(object);
    } else if (object is ShapeObject) {
      return _buildShapeObject(object);
    } else if (object is TableObject) {
      return _buildTableObject(object);
    } else if (object is LinkObject) {
      return _buildLinkObject(object);
    }
    return null;
  }

  /// Cria traços livres via Béziers e `pw.CustomPaint`
  static pw.Widget _buildStroke(Stroke stroke, double pageWidth, double pageHeight) {
    return pw.Positioned(
      left: 0, top: 0,
      child: pw.CustomPaint(
        size: pdf_pkg.PdfPoint(pageWidth, pageHeight),
        painter: (pdf_pkg.PdfGraphics canvas, pdf_pkg.PdfPoint size) {
          if (stroke.points.isEmpty) return;
          
          final color = _hexToPdfColor(stroke.color);
          final finalColor = pdf_pkg.PdfColor(color.red, color.green, color.blue, stroke.opacity);
          
          canvas.setStrokeColor(finalColor);
          canvas.setLineWidth(stroke.thickness);
          canvas.setLineCap(pdf_pkg.PdfLineCap.round);
          canvas.setLineJoin(pdf_pkg.PdfLineJoin.round);
          
          final pts = stroke.points;
          canvas.moveTo(pts.first.dx, size.y - pts.first.dy);
          for (int i = 1; i < pts.length; i++) {
            canvas.lineTo(pts[i].dx, size.y - pts[i].dy);
          }
          canvas.strokePath();
        }
      )
    );
  }

  /// Converte TextBlocks para Textos Nativos e Selecionáveis `pw.Text`
  static pw.Widget _buildTextBlock(TextBlock tb, double pageMaxWidth) {
    final textColor = _hexToPdfColor(tb.textColorHex);
    
    final style = pw.TextStyle(
      fontSize: tb.fontSize,
      color: textColor,
      fontWeight: tb.isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
      fontStyle: tb.isItalic ? pw.FontStyle.italic : pw.FontStyle.normal,
      decoration: tb.isUnderline && tb.isStrikethrough
          ? pw.TextDecoration.combine([pw.TextDecoration.underline, pw.TextDecoration.lineThrough])
          : (tb.isUnderline ? pw.TextDecoration.underline : (tb.isStrikethrough ? pw.TextDecoration.lineThrough : pw.TextDecoration.none)),
    );
    
    final List<String> lines = tb.text.split('\n');
    final Map<int, int> levelCounters = {};
    final List<pw.Widget> textSpans = [];
    
    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];
      int spaces = 0;
      for (int c = 0; c < line.length; c++) {
        if (line[c] == ' ') spaces++;
        else break;
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
      
      textSpans.add(pw.Text(displayLine, style: style));
    }

    pw.Widget content = pw.Column(
      crossAxisAlignment: tb.textAlign == TextAlign.center
          ? pw.CrossAxisAlignment.center
          : tb.textAlign == TextAlign.right
              ? pw.CrossAxisAlignment.end
              : pw.CrossAxisAlignment.start,
      children: textSpans,
    );
    
    if (tb.backgroundColorHex != null) {
      content = pw.Container(
        color: _hexToPdfColor(tb.backgroundColorHex!),
        padding: const pw.EdgeInsets.all(4),
        child: content,
      );
    }
    
    pw.Widget positioned = pw.Positioned(
      left: tb.position.dx,
      top: tb.position.dy,
      child: tb.rotation != 0
          ? pw.Transform.rotateBox(angle: -tb.rotation, child: content)
          : content,
    );
    return positioned;
  }

  /// Converte Imagens para o Widget `pw.Image` com compressão JPEG se aplicável
  static Future<pw.Widget?> _buildImageBlock(ImageBlock img) async {
    if (!File(img.imagePath).existsSync()) return null;
    try {
      final bytes = await File(img.imagePath).readAsBytes();
      final pdfImage = pw.MemoryImage(bytes);
      
      pw.Widget content = pw.Image(pdfImage, width: img.width, height: img.height, fit: pw.BoxFit.fill);
      
      if (img.opacity < 1.0) {
        content = pw.Opacity(opacity: img.opacity, child: content);
      }
      
      return pw.Positioned(
        left: img.position.dx,
        top: img.position.dy,
        child: img.rotation != 0
          ? pw.Transform.rotateBox(angle: -img.rotation, child: content)
          : content,
      );
    } catch (e) {
      debugPrint('🚨 Erro ao rasterizar ImageBlock: $e');
      return null;
    }
  }

  /// Renderiza Formas Geométricas via Componentes `pdf`
  static pw.Widget _buildShapeObject(ShapeObject shape) {
    final strokeColor = _hexToPdfColor(shape.strokeColor);
    final fillColor = shape.fillColor != null && shape.isClosed
        ? _hexToPdfColor(shape.fillColor!)
        : null;
        
    pw.Widget content;
    
    if (shape.shapeType == ShapeType.rectangle) {
      content = pw.Container(
        width: shape.size.width,
        height: shape.size.height,
        decoration: pw.BoxDecoration(
          color: fillColor,
          border: pw.Border.all(color: strokeColor, width: shape.strokeWidth),
        ),
      );
    } else if (shape.shapeType == ShapeType.circle) {
      content = pw.Container(
        width: shape.size.width,
        height: shape.size.height,
        decoration: pw.BoxDecoration(
          color: fillColor,
          border: pw.Border.all(color: strokeColor, width: shape.strokeWidth),
          shape: pw.BoxShape.circle,
        ),
      );
    } else {
      content = pw.CustomPaint(
        size: pdf_pkg.PdfPoint(shape.size.width, shape.size.height),
        painter: (pdf_pkg.PdfGraphics canvas, pdf_pkg.PdfPoint size) {
          canvas.setStrokeColor(strokeColor);
          canvas.setLineWidth(shape.strokeWidth);
          if (fillColor != null) canvas.setFillColor(fillColor);
          
          if (shape.shapeType == ShapeType.line) {
            canvas.moveTo(0, size.y);
            canvas.lineTo(size.x, 0);
            canvas.strokePath();
          } else if (shape.shapeType == ShapeType.triangle) {
            canvas.moveTo(size.x / 2, size.y);
            canvas.lineTo(size.x, 0);
            canvas.lineTo(0, 0);
            canvas.closePath();
            if (fillColor != null) canvas.fillAndStrokePath();
            else canvas.strokePath();
          } else if (shape.shapeType == ShapeType.arrow) {
            canvas.moveTo(0, size.y);
            canvas.lineTo(size.x, 0);
            canvas.strokePath();
            
            final angle = math.atan2(-size.y, size.x);
            const double arrowSize = 15.0;
            const double arrowAngle = math.pi / 6;
            
            canvas.moveTo(size.x, 0);
            canvas.lineTo(size.x - arrowSize * math.cos(angle - arrowAngle), 0 - arrowSize * math.sin(angle - arrowAngle));
            canvas.moveTo(size.x, 0);
            canvas.lineTo(size.x - arrowSize * math.cos(angle + arrowAngle), 0 - arrowSize * math.sin(angle + arrowAngle));
            canvas.strokePath();
          }
        }
      );
    }
    
    return pw.Positioned(
      left: shape.position.dx,
      top: shape.position.dy,
      child: shape.rotation != 0
          ? pw.Transform.rotateBox(angle: -shape.rotation, child: content)
          : content,
    );
  }

  /// Mapeia Células da Tabela com `pw.Positioned` para manter fidelidade visual ao milímetro
  static pw.Widget _buildTableObject(TableObject table) {
    final borderColor = _hexToPdfColor(table.borderColor);
    final tableBgColor = table.tableBackgroundColorHex != null
        ? _hexToPdfColor(table.tableBackgroundColorHex!)
        : pdf_pkg.PdfColors.white;

    final List<pw.Widget> children = [];
    
    // Contentor mestre e fundo da tabela
    children.add(
      pw.Positioned(
        left: 0, top: 0,
        child: pw.Container(
          width: table.size.width,
          height: table.size.height,
          decoration: pw.BoxDecoration(
            color: tableBgColor,
            border: pw.Border.all(color: borderColor, width: table.borderWidth),
          ),
        ),
      ),
    );

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

        final cellBg = cell.style.backgroundColorHex != null
            ? _hexToPdfColor(cell.style.backgroundColorHex!)
            : null;
            
        final textColor = _hexToPdfColor(cell.style.textColorHex);
        
        pw.Widget cellContent;
        if (cell.type == TableCellType.checkbox) {
          final isChecked = cell.value == 'true';
          cellContent = pw.Center(
            child: pw.Container(
              width: 14, height: 14,
              decoration: pw.BoxDecoration(
                border: pw.Border.all(color: _hexToPdfColor('#0F4C5C'), width: 1.5),
              ),
              child: isChecked 
                  ? pw.Center(child: pw.Text('X', style: pw.TextStyle(color: _hexToPdfColor('#0F4C5C'), fontSize: 10, fontWeight: pw.FontWeight.bold)))
                  : null,
            ),
          );
        } else {
          cellContent = pw.Text(
            cell.value,
            style: pw.TextStyle(
              fontSize: cell.style.fontSize,
              color: textColor,
              fontWeight: cell.style.bold ? pw.FontWeight.bold : pw.FontWeight.normal,
              fontStyle: cell.style.italic ? pw.FontStyle.italic : pw.FontStyle.normal,
              decoration: cell.style.underline ? pw.TextDecoration.underline : pw.TextDecoration.none,
            ),
            textAlign: cell.style.textAlign == TextAlign.center
                ? pw.TextAlign.center
                : cell.style.textAlign == TextAlign.right ? pw.TextAlign.right : pw.TextAlign.left,
          );
        }
        
        // Cada célula posicionada e esticada com base no size e offset da matriz do Canvas
        children.add(
          pw.Positioned(
            left: offset.dx,
            top: offset.dy,
            child: pw.Container(
              width: size.width,
              height: size.height,
              padding: const pw.EdgeInsets.all(4),
              decoration: pw.BoxDecoration(
                color: cellBg,
                border: pw.Border.all(color: borderColor, width: table.internalBorderWidth / 2),
              ),
              alignment: cell.style.verticalAlign == 1 
                  ? pw.Alignment.centerLeft 
                  : cell.style.verticalAlign == 2 ? pw.Alignment.bottomLeft : pw.Alignment.topLeft,
              child: cellContent,
            ),
          ),
        );
      }
    }
    
    return pw.Positioned(
      left: table.position.dx,
      top: table.position.dy,
      child: pw.SizedBox(
        width: table.size.width,
        height: table.size.height,
        child: pw.Stack(children: children),
      ),
    );
  }

  /// Renderiza Links Externos compatíveis com visualizador de PDF
  static pw.Widget _buildLinkObject(LinkObject link) {
    final bgColor = _hexToPdfColor(link.backgroundColor);
    final textColor = _hexToPdfColor(link.textColor);
    
    return pw.Positioned(
      left: link.position.dx,
      top: link.position.dy,
      child: pw.UrlLink(
        destination: link.url ?? '',
        child: pw.Container(
          width: link.size.width,
          height: link.size.height,
          decoration: pw.BoxDecoration(
            color: bgColor,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          padding: const pw.EdgeInsets.symmetric(horizontal: 8),
          alignment: pw.Alignment.centerLeft,
          child: pw.Text('🔗 ${link.label}', style: pw.TextStyle(color: textColor, fontSize: 12, fontWeight: pw.FontWeight.bold)),
        ),
      ),
    );
  }
}
