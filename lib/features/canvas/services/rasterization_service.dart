import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';
import '../models/stroke_model.dart';
import '../models/image_block_model.dart';
import '../widgets/canvas_painter.dart';

class RasterizationService {
  /// Converte uma lista de Strokes numa imagem PNG transparente e retorna um ImageBlock
  static Future<ImageBlock?> rasterizeStrokes(List<Stroke> strokes, String creatorId) async {
    if (strokes.isEmpty) return null;

    // Calcular o Bounding Box de todos os pontos
    double minX = double.infinity, minY = double.infinity, maxX = double.negativeInfinity, maxY = double.negativeInfinity;
    for (var s in strokes) {
      for (var p in s.points) {
        if (p.dx < minX) minX = p.dx;
        if (p.dx > maxX) maxX = p.dx;
        if (p.dy < minY) minY = p.dy;
        if (p.dy > maxY) maxY = p.dy;
      }
    }

    // Margem de segurança para espessura do pincel
    const padding = 20.0;
    minX -= padding;
    minY -= padding;
    maxX += padding;
    maxY += padding;

    final width = maxX - minX;
    final height = maxY - minY;
    
    if (width <= 0 || height <= 0) return null;

    // Criar o gravador de imagem do Flutter
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder, Rect.fromLTWH(0, 0, width, height));

    // Mover a origem para o canto superior esquerdo do bounding box para pintar os strokes na posição (0, 0)
    canvas.translate(-minX, -minY);

    for (var stroke in strokes) {
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

    final picture = recorder.endRecording();
    final img = await picture.toImage(width.toInt(), height.toInt());
    final byteData = await img.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return null;

    final buffer = byteData.buffer.asUint8List();

    // Guardar a imagem gerada localmente
    final appDir = await getApplicationDocumentsDirectory();
    final String newPath = '${appDir.path}/raster_${DateTime.now().millisecondsSinceEpoch}.png';
    final file = File(newPath);
    await file.writeAsBytes(buffer);

    return ImageBlock(
      id: const Uuid().v4(),
      imagePath: newPath,
      position: Offset(minX, minY),
      width: width,
      height: height,
      creatorId: creatorId,
    );
  }
}
