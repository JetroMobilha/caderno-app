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

    // 🚀 UNIFICAÇÃO DE ESCALA: Baseada rigorosamente na largura lógica em mm vs largura física em pixels
    final double mmToPixel = size.width / notebookConfig.page.width;
    final double spacing = bgConfig.spacing * mmToPixel;
    final margins = notebookConfig.margins;

    final paint = Paint()
      ..color = bgConfig.lineColor != null 
          ? Color(int.parse(bgConfig.lineColor!.replaceFirst('#', '0xFF')))
          : Colors.black.withValues(alpha: 0.1 * bgConfig.opacity)
      ..strokeWidth = bgConfig.lineWidth * mmToPixel; 

    // 🚀 GARANTIR QUE O TAMANHO TOTAL É USADO
    final double W = size.width;
    final double H = size.height;

    switch (bgConfig.type) {
      case 'lines':
        _drawLines(canvas, W, H, spacing, margins, paint, bgConfig.showRedMargin, mmToPixel);
        break;
      case 'grid':
        _drawGrid(canvas, W, H, spacing, paint);
        break;
      case 'dots':
        _drawDots(canvas, W, H, spacing, paint, mmToPixel);
        break;
      case 'math':
        _drawMath(canvas, W, H, spacing, paint, bgConfig.subType, mmToPixel);
        break;
      case 'music':
        _drawMusic(canvas, W, H, spacing, paint, bgConfig.subType, mmToPixel);
        break;
      case 'engineering':
        _drawEngineering(canvas, W, H, spacing, paint, bgConfig.subType, mmToPixel);
        break;
      case 'calligraphy':
        _drawCalligraphy(canvas, W, H, spacing, paint, mmToPixel);
        break;
      case 'planning':
        _drawPlanning(canvas, W, H, spacing, paint, bgConfig.subType, mmToPixel);
        break;
      case 'study':
        _drawStudy(canvas, W, H, spacing, paint, bgConfig.subType, mmToPixel);
        break;
      case 'business':
        _drawBusiness(canvas, W, H, spacing, paint, mmToPixel);
        break;
      case 'accounting':
        _drawAccounting(canvas, W, H, spacing, paint, mmToPixel);
        break;
      case 'special':
        if (bgConfig.subType == 'checklist') {
          _drawChecklist(canvas, W, H, spacing, paint, mmToPixel);
        }
        break;
      default:
        break;
    }
  }

  static void _drawLines(Canvas canvas, double W, double H, double spacing, MarginsConfig margins, Paint paint, bool showRedMargin, double mmToPixel) {
    if (showRedMargin) {
      final marginPaint = Paint()
        ..color = Colors.redAccent.withValues(alpha: 0.25)
        ..strokeWidth = 0.5 * mmToPixel;
      final marginX = (margins.left + 25) * mmToPixel;
      canvas.drawLine(Offset(marginX, 0), Offset(marginX, H), marginPaint);
    }
    for (double y = spacing; y < H; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(W, y), paint);
    }
  }

  static void _drawGrid(Canvas canvas, double W, double H, double spacing, Paint paint) {
    // 🚀 GARANTIR PREENCHIMENTO TOTAL: De 0 até W/H com margem extra
    for (double x = 0; x <= W + spacing; x += spacing) {
      canvas.drawLine(Offset(x, 0), Offset(x, H), paint);
    }
    for (double y = 0; y <= H + spacing; y += spacing) {
      canvas.drawLine(Offset(0, y), Offset(W, y), paint);
    }
  }

  static void _drawDots(Canvas canvas, double W, double H, double spacing, Paint paint, double mmToPixel) {
    for (double x = spacing; x < W; x += spacing) {
      for (double y = spacing; y < H; y += spacing) {
        canvas.drawCircle(Offset(x, y), 0.4 * mmToPixel, paint..style = PaintingStyle.fill);
      }
    }
  }

  static void _drawMath(Canvas canvas, double W, double H, double spacing, Paint paint, String? subType, double mmToPixel) {
    if (subType == 'cartesian') {
      _drawGrid(canvas, W, H, spacing, paint);
      final axisPaint = Paint()..color = Colors.black38..strokeWidth = 1.0 * mmToPixel;
      canvas.drawLine(Offset(0, H / 2), Offset(W, H / 2), axisPaint);
      canvas.drawLine(Offset(W / 2, 0), Offset(W / 2, H), axisPaint);
    } else if (subType == 'polar') {
      final center = Offset(W / 2, H / 2);
      for (double r = spacing; r < W; r += spacing) {
        canvas.drawCircle(center, r, paint..style = PaintingStyle.stroke);
      }
      for (double angle = 0; angle < 360; angle += 15) {
        final rad = angle * math.pi / 180;
        canvas.drawLine(center, center + Offset(math.cos(rad) * W, math.sin(rad) * W), paint);
      }
    } else {
       _drawGrid(canvas, W, H, spacing, paint);
    }
  }

  static void _drawMusic(Canvas canvas, double W, double H, double spacing, Paint paint, String? subType, double mmToPixel) {
    double y = 40 * mmToPixel;
    int staves = subType == 'piano' ? 2 : 1;
    while (y < H - 40 * mmToPixel) {
      for (int s = 0; s < staves; s++) {
        for (int i = 0; i < 5; i++) {
          canvas.drawLine(Offset(15 * mmToPixel, y), Offset(W - 15 * mmToPixel, y), paint);
          y += spacing;
        }
        if (s < staves - 1) y += spacing * 3;
      }
      y += spacing * 6;
    }
  }

  static void _drawEngineering(Canvas canvas, double W, double H, double spacing, Paint paint, String? subType, double mmToPixel) {
    if (subType == 'millimeter') {
      for (double x = 0; x < W; x += spacing) {
        int i = (x / spacing).round();
        paint.color = (i % 10 == 0) ? Colors.redAccent.withValues(alpha: 0.15) : (i % 5 == 0 ? paint.color.withValues(alpha: 0.15) : paint.color.withValues(alpha: 0.05));
        canvas.drawLine(Offset(x, 0), Offset(x, H), paint);
      }
      for (double y = 0; y < H; y += spacing) {
        int i = (y / spacing).round();
        paint.color = (i % 10 == 0) ? Colors.redAccent.withValues(alpha: 0.15) : (i % 5 == 0 ? paint.color.withValues(alpha: 0.15) : paint.color.withValues(alpha: 0.05));
        canvas.drawLine(Offset(0, y), Offset(W, y), paint);
      }
    } else if (subType == 'isometric') {
       final angle = 30 * math.pi / 180;
       for (double x = -H; x < W + H; x += spacing * 2) {
         canvas.drawLine(Offset(x, 0), Offset(x + H * math.tan(angle), H), paint);
         canvas.drawLine(Offset(x, 0), Offset(x - H * math.tan(angle), H), paint);
       }
       for (double y = 0; y < H; y += spacing * math.sin(angle) * 2) {
         canvas.drawLine(Offset(0, y), Offset(W, y), paint);
       }
    } else {
       _drawGrid(canvas, W, H, spacing, paint);
    }
  }

  static void _drawCalligraphy(Canvas canvas, double W, double H, double spacing, Paint paint, double mmToPixel) {
    double y = 20 * mmToPixel;
    while (y < H) {
      canvas.drawLine(Offset(10 * mmToPixel, y), Offset(W - 10 * mmToPixel, y), paint..strokeWidth = 0.2 * mmToPixel);
      canvas.drawLine(Offset(10 * mmToPixel, y + spacing), Offset(W - 10 * mmToPixel, y + spacing), paint..strokeWidth = 0.5 * mmToPixel);
      canvas.drawLine(Offset(10 * mmToPixel, y + spacing * 2), Offset(W - 10 * mmToPixel, y + spacing * 2), paint..strokeWidth = 0.5 * mmToPixel);
      canvas.drawLine(Offset(10 * mmToPixel, y + spacing * 3), Offset(W - 10 * mmToPixel, y + spacing * 3), paint..strokeWidth = 0.2 * mmToPixel);
      y += spacing * 7;
    }
  }

  static void _drawPlanning(Canvas canvas, double W, double H, double spacing, Paint paint, String? subType, double mmToPixel) {
    if (subType == 'daily') {
      canvas.drawLine(Offset(40 * mmToPixel, 0), Offset(40 * mmToPixel, H), paint..strokeWidth = 0.6 * mmToPixel);
      for (double y = 30 * mmToPixel; y < H; y += 15 * mmToPixel) {
        canvas.drawLine(Offset(0, y), Offset(W, y), paint..strokeWidth = 0.2 * mmToPixel);
      }
    } else if (subType == 'weekly') {
      double colWidth = W / 7;
      for (int i = 1; i < 7; i++) canvas.drawLine(Offset(i * colWidth, 0), Offset(i * colWidth, H), paint);
      for (double y = 40 * mmToPixel; y < H; y += 30 * mmToPixel) canvas.drawLine(Offset(0, y), Offset(W, y), paint);
    } else if (subType == 'todo') {
      for (double y = 40 * mmToPixel; y < H; y += 18 * mmToPixel) {
        canvas.drawRect(Rect.fromLTWH(20 * mmToPixel, y - 12 * mmToPixel, 10 * mmToPixel, 10 * mmToPixel), paint..style = PaintingStyle.stroke);
        canvas.drawLine(Offset(40 * mmToPixel, y), Offset(W - 20 * mmToPixel, y), paint);
      }
    } else if (subType == 'kanban') {
      canvas.drawLine(Offset(W / 3, 0), Offset(W / 3, H), paint..strokeWidth = 1.0 * mmToPixel);
      canvas.drawLine(Offset(W * 2 / 3, 0), Offset(W * 2 / 3, H), paint..strokeWidth = 1.0 * mmToPixel);
    }
  }

  static void _drawStudy(Canvas canvas, double W, double H, double spacing, Paint paint, String? subType, double mmToPixel) {
    if (subType == 'cornell') {
      final cueW = W * 0.25;
      final sumH = H * 0.15;
      canvas.drawLine(Offset(cueW, 0), Offset(cueW, H - sumH), paint..strokeWidth = 0.8 * mmToPixel);
      canvas.drawLine(Offset(0, H - sumH), Offset(W, H - sumH), paint..strokeWidth = 0.8 * mmToPixel);
      for (double y = 30 * mmToPixel; y < H - sumH; y += spacing) canvas.drawLine(Offset(cueW, y), Offset(W, y), paint..strokeWidth = 0.2 * mmToPixel);
    } else if (subType == 'summary') {
       canvas.drawLine(Offset(W / 2, 0), Offset(W / 2, H), paint);
       for (double y = spacing; y < H; y += spacing) canvas.drawLine(Offset(0, y), Offset(W, y), paint..strokeWidth = 0.1 * mmToPixel);
    } else {
       canvas.drawCircle(Offset(W / 2, H / 2), 40 * mmToPixel, paint..style = PaintingStyle.stroke);
    }
  }

  static void _drawBusiness(Canvas canvas, double W, double H, double spacing, Paint paint, double mmToPixel) {
     canvas.drawRect(Rect.fromLTWH(15 * mmToPixel, 15 * mmToPixel, W - 30 * mmToPixel, 25 * mmToPixel), paint..style = PaintingStyle.stroke);
     for (double y = 50 * mmToPixel; y < H; y += spacing * 1.2) canvas.drawLine(Offset(0, y), Offset(W, y), paint);
  }

  static void _drawAccounting(Canvas canvas, double W, double H, double spacing, Paint paint, double mmToPixel) {
    final double col = W / 10;
    for (int i = 1; i < 10; i++) {
      paint.strokeWidth = (i == 7 || i == 9) ? 0.8 * mmToPixel : 0.2 * mmToPixel;
      canvas.drawLine(Offset(i * col, 0), Offset(i * col, H), paint);
    }
    for (double y = 0; y < H; y += spacing) canvas.drawLine(Offset(0, y), Offset(W, y), paint..strokeWidth = 0.2 * mmToPixel);
  }

  static void _drawChecklist(Canvas canvas, double W, double H, double spacing, Paint paint, double mmToPixel) {
    for (double y = 30 * mmToPixel; y < H; y += spacing * 1.5) {
      canvas.drawCircle(Offset(25 * mmToPixel, y), 3.5 * mmToPixel, paint..style = PaintingStyle.stroke);
      canvas.drawLine(Offset(45 * mmToPixel, y), Offset(W - 20 * mmToPixel, y), paint);
    }
  }
}
