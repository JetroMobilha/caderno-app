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

    // 🚀 UNIFICAÇÃO DE UNIDADES: 
    // mmToPixel deve basear-se na dimensão real em mm (PageConfig) vs tamanho do widget (Size)
    final double mmToPixel = size.width / notebookConfig.page.width;
    final double spacing = bgConfig.spacing * mmToPixel;
    final margins = notebookConfig.margins;

    final paint = Paint()
      ..color = bgConfig.lineColor != null 
          ? Color(int.parse(bgConfig.lineColor!.replaceFirst('#', '0xFF')))
          : Colors.black.withValues(alpha: 0.1 * bgConfig.opacity)
      ..strokeWidth = bgConfig.lineWidth * mmToPixel; 

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
      case 'planning':
        _drawPlanning(canvas, size, spacing, margins, paint, bgConfig.subType, mmToPixel);
        break;
      case 'study':
        _drawStudy(canvas, size, spacing, margins, paint, bgConfig.subType, mmToPixel);
        break;
      case 'business':
        _drawBusiness(canvas, size, spacing, margins, paint, bgConfig.subType, mmToPixel);
        break;
      case 'accounting':
        _drawAccounting(canvas, size, spacing, margins, paint, bgConfig.subType, mmToPixel);
        break;
      case 'special':
        if (bgConfig.subType == 'checklist') {
          _drawChecklist(canvas, size, spacing, margins, paint, mmToPixel);
        }
        break;
      default:
        break;
    }
  }

  static void _drawLines(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, bool showRedMargin, double mmToPixel) {
    if (showRedMargin) {
      final marginPaint = Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.25)
        ..strokeWidth = 0.3 * mmToPixel;
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
        canvas.drawCircle(Offset(x, y), 0.3 * mmToPixel, paint..style = PaintingStyle.fill);
      }
    }
  }

  static void _drawMath(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, String? subType, double mmToPixel) {
    if (subType == 'cartesian') {
      final centerX = size.width / 2;
      final centerY = size.height / 2;
      _drawGrid(canvas, size, spacing, margins, paint, mmToPixel);
      final axisPaint = Paint()..color = Colors.black38..strokeWidth = 0.5 * mmToPixel;
      canvas.drawLine(Offset(0, centerY), Offset(size.width, centerY), axisPaint);
      canvas.drawLine(Offset(centerX, 0), Offset(centerX, size.height), axisPaint);
    } else if (subType == 'polar') {
      final center = Offset(size.width / 2, size.height / 2);
      for (double r = spacing; r < size.width; r += spacing) {
        canvas.drawCircle(center, r, paint..style = PaintingStyle.stroke);
      }
      for (double angle = 0; angle < 360; angle += 15) {
        final rad = angle * math.pi / 180;
        canvas.drawLine(center, center + Offset(math.cos(rad) * size.width, math.sin(rad) * size.width), paint);
      }
    } else if (subType == 'log') {
       _drawGrid(canvas, size, spacing, margins, paint, mmToPixel);
       final logPaint = Paint()..color = paint.color.withValues(alpha: 0.3)..strokeWidth = paint.strokeWidth * 1.5;
       for (int i = 1; i <= 10; i++) {
         double x = margins.left * mmToPixel + (math.log(i) / math.log(10)) * 100 * mmToPixel;
         canvas.drawLine(Offset(x, 0), Offset(x, size.height), logPaint);
       }
    }
  }

  static void _drawMusic(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, String? subType, double mmToPixel) {
    double y = margins.top * mmToPixel + 20 * mmToPixel;
    int staves = subType == 'piano' ? 2 : 1;
    while (y < size.height - 40 * mmToPixel) {
      for (int s = 0; s < staves; s++) {
        for (int i = 0; i < 5; i++) {
          canvas.drawLine(Offset(20 * mmToPixel, y), Offset(size.width - 20 * mmToPixel, y), paint);
          y += (subType == 'guitar' ? spacing * 0.8 : spacing);
        }
        if (s < staves - 1) y += spacing * 3;
      }
      y += spacing * 6;
    }
  }

  static void _drawEngineering(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, String? subType, double mmToPixel) {
    if (subType == 'millimeter') {
      for (double x = 0; x < size.width; x += spacing) {
        int i = (x / spacing).round();
        paint.color = (i % 10 == 0) ? Colors.redAccent.withValues(alpha: 0.15) : (i % 5 == 0 ? paint.color.withValues(alpha: 0.15) : paint.color.withValues(alpha: 0.05));
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += spacing) {
        int i = (y / spacing).round();
        paint.color = (i % 10 == 0) ? Colors.redAccent.withValues(alpha: 0.15) : (i % 5 == 0 ? paint.color.withValues(alpha: 0.15) : paint.color.withValues(alpha: 0.05));
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    } else if (subType == 'isometric') {
       final angle = 30 * math.pi / 180;
       for (double x = -size.height; x < size.width + size.height; x += spacing * 2) {
         canvas.drawLine(Offset(x, 0), Offset(x + size.height * math.tan(angle), size.height), paint);
         canvas.drawLine(Offset(x, 0), Offset(x - size.height * math.tan(angle), size.height), paint);
       }
       for (double y = 0; y < size.height; y += spacing * math.sin(angle) * 2) {
         canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
       }
    }
  }

  static void _drawCalligraphy(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, double mmToPixel) {
    double y = margins.top * mmToPixel + 10 * mmToPixel;
    while (y < size.height) {
      canvas.drawLine(Offset(10 * mmToPixel, y), Offset(size.width - 10 * mmToPixel, y), paint..strokeWidth = 0.1 * mmToPixel);
      canvas.drawLine(Offset(10 * mmToPixel, y + spacing), Offset(size.width - 10 * mmToPixel, y + spacing), paint..strokeWidth = 0.4 * mmToPixel);
      canvas.drawLine(Offset(10 * mmToPixel, y + spacing * 2), Offset(size.width - 10 * mmToPixel, y + spacing * 2), paint..strokeWidth = 0.4 * mmToPixel);
      canvas.drawLine(Offset(10 * mmToPixel, y + spacing * 3), Offset(size.width - 10 * mmToPixel, y + spacing * 3), paint..strokeWidth = 0.1 * mmToPixel);
      y += spacing * 6;
    }
  }

  static void _drawPlanning(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, String? subType, double mmToPixel) {
    if (subType == 'daily') {
      final double hourWidth = 40 * mmToPixel;
      canvas.drawLine(Offset(hourWidth, 0), Offset(hourWidth, size.height), paint..strokeWidth = 0.5 * mmToPixel);
      for (double y = 50 * mmToPixel; y < size.height; y += 25 * mmToPixel) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint..strokeWidth = 0.2 * mmToPixel);
      }
    } else if (subType == 'weekly') {
      double colWidth = size.width / 7;
      for (int i = 1; i < 7; i++) canvas.drawLine(Offset(i * colWidth, 0), Offset(i * colWidth, size.height), paint);
      for (double y = 40 * mmToPixel; y < size.height; y += 30 * mmToPixel) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    } else if (subType == 'todo') {
      for (double y = 40 * mmToPixel; y < size.height; y += 15 * mmToPixel) {
        canvas.drawRect(Rect.fromLTWH(15 * mmToPixel, y - 10 * mmToPixel, 8 * mmToPixel, 8 * mmToPixel), paint..style = PaintingStyle.stroke);
        canvas.drawLine(Offset(30 * mmToPixel, y), Offset(size.width - 15 * mmToPixel, y), paint);
      }
    } else if (subType == 'kanban') {
      double w3 = size.width / 3;
      canvas.drawLine(Offset(w3, 0), Offset(w3, size.height), paint..strokeWidth = 0.8 * mmToPixel);
      canvas.drawLine(Offset(w3 * 2, 0), Offset(w3 * 2, size.height), paint..strokeWidth = 0.8 * mmToPixel);
    }
  }

  static void _drawStudy(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, String? subType, double mmToPixel) {
    if (subType == 'cornell') {
      final cueW = size.width * 0.25;
      final sumH = size.height * 0.2;
      canvas.drawLine(Offset(cueW, 0), Offset(cueW, size.height - sumH), paint..strokeWidth = 0.5 * mmToPixel);
      canvas.drawLine(Offset(0, size.height - sumH), Offset(size.width, size.height - sumH), paint..strokeWidth = 0.5 * mmToPixel);
      for (double y = 40 * mmToPixel; y < size.height - sumH; y += 8 * mmToPixel) canvas.drawLine(Offset(cueW, y), Offset(size.width, y), paint..strokeWidth = 0.1 * mmToPixel);
    } else if (subType == 'summary') {
       canvas.drawLine(Offset(size.width / 2, 0), Offset(size.width / 2, size.height), paint);
       _drawLines(canvas, size, 8 * mmToPixel, margins, paint, false, mmToPixel);
    } else if (subType == 'mindmap') {
       canvas.drawCircle(Offset(size.width / 2, size.height / 2), 40 * mmToPixel, paint..style = PaintingStyle.stroke);
       canvas.drawCircle(Offset(size.width / 2, size.height / 2), 2 * mmToPixel, paint..style = PaintingStyle.fill);
    }
  }

  static void _drawBusiness(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, String? subType, double mmToPixel) {
     canvas.drawRect(Rect.fromLTWH(10 * mmToPixel, 10 * mmToPixel, size.width - 20 * mmToPixel, 30 * mmToPixel), paint..style = PaintingStyle.stroke);
     _drawLines(canvas, size, 12 * mmToPixel, margins, paint, true, mmToPixel);
  }

  static void _drawAccounting(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, String? subType, double mmToPixel) {
    final double col = size.width / 10;
    for (int i = 1; i < 10; i++) {
      paint.strokeWidth = (i == 7 || i == 9) ? 0.6 * mmToPixel : 0.15 * mmToPixel;
      canvas.drawLine(Offset(i * col, 0), Offset(i * col, size.height), paint);
    }
    for (double y = 0; y < size.height; y += 8 * mmToPixel) canvas.drawLine(Offset(0, y), Offset(size.width, y), paint..strokeWidth = 0.1 * mmToPixel);
  }

  static void _drawChecklist(Canvas canvas, Size size, double spacing, MarginsConfig margins, Paint paint, double mmToPixel) {
    for (double y = 30 * mmToPixel; y < size.height; y += 12 * mmToPixel) {
      canvas.drawCircle(Offset(20 * mmToPixel, y), 3 * mmToPixel, paint..style = PaintingStyle.stroke);
      canvas.drawLine(Offset(35 * mmToPixel, y), Offset(size.width - 15 * mmToPixel, y), paint);
    }
  }
}
