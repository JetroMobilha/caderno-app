import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../notebooks/models/notebook_configuration.dart';

class BackgroundEngine {
  static void draw(Canvas canvas, Size size, NotebookConfiguration notebookConfig, BackgroundConfig bgConfig) {
    // 1. Fill Background Color
    if (bgConfig.color != null) {
      final color = Color(int.parse(bgConfig.color!.replaceFirst('#', '0xFF')));
      canvas.drawRect(Offset.zero & size, Paint()..color = color);
    }

    final double mmToPixel = size.width / notebookConfig.page.width;
    final double spacing = bgConfig.spacing * mmToPixel;
    final margins = notebookConfig.margins;

    final paint = Paint()
      ..color = bgConfig.lineColor != null 
          ? Color(int.parse(bgConfig.lineColor!.replaceFirst('#', '0xFF')))
          : Colors.black.withOpacity(0.1 * bgConfig.opacity)
      ..strokeWidth = 0.15 * mmToPixel; // 🚀 Linhas ultra-finas e precisas

    switch (bgConfig.type) {
      case 'lines':
        _drawLines(canvas, size, spacing, margins, paint, bgConfig.showRedMargin, mmToPixel);
        break;
      case 'grid':
        _drawGrid(canvas, size, spacing, margins, paint, mmToPixel);
        break;
      case 'dots':
        _drawDots(canvas, size, spacing, margins, paint, mmToPixel);
        break;
      case 'math':
        _drawMath(canvas, size, spacing, margins, paint, bgConfig.subType, mmToPixel);
        break;
      case 'music':
        _drawMusic(canvas, size, spacing, margins, paint, bgConfig.subType, mmToPixel);
        break;
      case 'engineering':
        _drawEngineering(canvas, size, spacing, margins, paint, bgConfig.subType, mmToPixel);
        break;
      case 'calligraphy':
        _drawCalligraphy(canvas, size, spacing, margins, paint, mmToPixel);
        break;
      case 'study':
        if (bgConfig.subType == 'cornell') {
          _drawCornell(canvas, size, spacing, margins, paint, mmToPixel);
        }
        break;
      default:
        // 'blank' or unknown
        break;
    }
  }

  static void _drawLines(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, bool showRedMargin, double mmToPixel) {
    if (showRedMargin) {
      final marginPaint = Paint()
        ..color = Colors.redAccent.withOpacity(0.25)
        ..strokeWidth = 0.3 * mmToPixel;
      
      // Margem vermelha padrão a ~30mm da esquerda
      final marginX = (margins.left + 30) * mmToPixel;
      canvas.drawLine(Offset(marginX, 0), Offset(marginX, size.height), marginPaint);
    }

    final double marginLeft = margins.left * mmToPixel;
    final double marginRight = margins.right * mmToPixel;
    final double marginTop = margins.top * mmToPixel;
    final double marginBottom = margins.bottom * mmToPixel;

    for (double y = marginTop + spacing; y < size.height - marginBottom; y += spacing) {
      canvas.drawLine(Offset(marginLeft, y), Offset(size.width - marginRight, y), paint);
    }
  }

  static void _drawGrid(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, double mmToPixel) {
    final double marginLeft = margins.left * mmToPixel;
    final double marginRight = margins.right * mmToPixel;
    final double marginTop = margins.top * mmToPixel;
    final double marginBottom = margins.bottom * mmToPixel;

    for (double x = marginLeft; x <= size.width - marginRight; x += spacing) {
      canvas.drawLine(Offset(x, marginTop), Offset(x, size.height - marginBottom), paint);
    }
    for (double y = marginTop; y <= size.height - marginBottom; y += spacing) {
      canvas.drawLine(Offset(marginLeft, y), Offset(size.width - marginRight, y), paint);
    }
  }

  static void _drawDots(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, double mmToPixel) {
    final double marginLeft = margins.left * mmToPixel;
    final double marginRight = margins.right * mmToPixel;
    final double marginTop = margins.top * mmToPixel;
    final double marginBottom = margins.bottom * mmToPixel;

    for (double x = marginLeft + spacing; x < size.width - marginRight; x += spacing) {
      for (double y = marginTop + spacing; y < size.height - marginBottom; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.2 * mmToPixel, paint);
      }
    }
  }

  static void _drawMath(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, String? subType, double mmToPixel) {
    if (subType == 'cartesian') {
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      
      // Secondary Grid
      final secondaryPaint = Paint()..color = paint.color.withOpacity(0.05)..strokeWidth = 0.1 * mmToPixel;
      for (double x = centerX; x < size.width; x += spacing / 2) canvas.drawLine(Offset(x, 0), Offset(x, size.height), secondaryPaint);
      for (double x = centerX; x > 0; x -= spacing / 2) canvas.drawLine(Offset(x, 0), Offset(x, size.height), secondaryPaint);
      
      // Draw Main Grid
      _drawGrid(canvas, size, spacing, margins, paint, mmToPixel);
      
      // Draw Axis
      final axisPaint = Paint()
        ..color = Colors.black38
        ..strokeWidth = 0.5 * mmToPixel;
      canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);
      canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), axisPaint);
    } else if (subType == 'polar') {
      final center = Offset(size.width / 2, size.height / 2);
      for (double r = spacing; r < size.width / 2; r += spacing) {
        canvas.drawCircle(center, r, paint..style = PaintingStyle.stroke);
      }
      for (double angle = 0; angle < 360; angle += 15) {
        final rad = angle * 3.14159 / 180;
        final endX = center.dx + 1000 * math.cos(rad);
        final endY = center.dy + 1000 * math.sin(rad);
        canvas.drawLine(center, Offset(endX, endY), paint);
      }
    }
  }

  static void _drawMusic(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, String? subType, double mmToPixel) {
    final double marginLeft = margins.left * mmToPixel;
    final double marginRight = margins.right * mmToPixel;
    final double marginTop = margins.top * mmToPixel;
    final double marginBottom = margins.bottom * mmToPixel;

    double y = marginTop + 20 * mmToPixel;
    paint.strokeWidth = 0.2 * mmToPixel;
    paint.color = Colors.black45;

    int staves = subType == 'piano' ? 2 : 1;
    
    while (y < size.height - marginBottom - 30 * mmToPixel) {
      for (int s = 0; s < staves; s++) {
        for (int i = 0; i < 5; i++) {
          canvas.drawLine(Offset(marginLeft + 15 * mmToPixel, y), Offset(size.width - marginRight - 15 * mmToPixel, y), paint);
          y += spacing;
        }
        if (s < staves - 1) y += spacing * 2; 
      }
      y += spacing * 5; 
    }
  }

  static void _drawEngineering(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, String? subType, double mmToPixel) {
    if (subType == 'millimeter') {
      final majorPaint = Paint()..color = Colors.redAccent.withOpacity(0.12)..strokeWidth = 0.2 * mmToPixel;
      final mediumPaint = Paint()..color = paint.color.withOpacity(0.1)..strokeWidth = 0.15 * mmToPixel;
      final minorPaint = Paint()..color = paint.color.withOpacity(0.05)..strokeWidth = 0.1 * mmToPixel;
      
      for (double x = 0; x < size.width; x += spacing) {
         int idx = (x / spacing).round();
         Paint p = minorPaint;
         if (idx % 10 == 0) p = majorPaint;
         else if (idx % 5 == 0) p = mediumPaint;
         canvas.drawLine(Offset(x, 0), Offset(x, size.height), p);
      }
      for (double y = 0; y < size.height; y += spacing) {
         int idx = (y / spacing).round();
         Paint p = minorPaint;
         if (idx % 10 == 0) p = majorPaint;
         else if (idx % 5 == 0) p = mediumPaint;
         canvas.drawLine(Offset(0, y), Offset(size.width, y), p);
      }
    } else if (subType == 'isometric') {
       final angle = 30 * 3.14159 / 180;
       final stepX = spacing * 2 * math.cos(angle);
       final stepY = spacing * math.sin(angle);

       for (double x = -size.height; x < size.width + size.height; x += stepX) {
         canvas.drawLine(Offset(x, 0), Offset(x + size.height * math.tan(angle), size.height), paint);
         canvas.drawLine(Offset(x, 0), Offset(x - size.height * math.tan(angle), size.height), paint);
       }
       for (double y = 0; y < size.height; y += stepY * 2) {
         canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
       }
    }
  }

  static void _drawCalligraphy(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, double mmToPixel) {
    final double marginLeft = margins.left * mmToPixel;
    final double marginRight = margins.right * mmToPixel;
    final double marginTop = margins.top * mmToPixel;
    final double marginBottom = margins.bottom * mmToPixel;

    double y = marginTop + 10 * mmToPixel;
    while (y < size.height - marginBottom) {
      canvas.drawLine(Offset(marginLeft, y), Offset(size.width - marginRight, y), paint);
      canvas.drawLine(Offset(marginLeft, y + spacing), Offset(size.width - marginRight, y + spacing), paint..strokeWidth = 0.3 * mmToPixel);
      canvas.drawLine(Offset(marginLeft, y + spacing * 2), Offset(size.width - marginRight, y + spacing * 2), paint..strokeWidth = 0.3 * mmToPixel);
      canvas.drawLine(Offset(marginLeft, y + spacing * 3), Offset(size.width - marginRight, y + spacing * 3), paint..strokeWidth = 0.15 * mmToPixel);
      y += spacing * 5;
    }
  }

  static void _drawCornell(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, double mmToPixel) {
    final double cueWidth = size.width * 0.3;
    final double summaryHeight = size.height * 0.2;

    final divPaint = Paint()..color = Colors.redAccent.withOpacity(0.25)..strokeWidth = 0.3 * mmToPixel;

    canvas.drawLine(Offset(cueWidth, 0), Offset(cueWidth, size.height - summaryHeight), divPaint);
    canvas.drawLine(Offset(0, size.height - summaryHeight), Offset(size.width, size.height - summaryHeight), divPaint);

    for (double y = spacing * 2; y < size.height - summaryHeight; y += spacing) {
      canvas.drawLine(Offset(cueWidth, y), Offset(size.width, y), paint);
    }
  }
}
