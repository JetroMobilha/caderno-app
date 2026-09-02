import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../notebooks/models/notebook_configuration.dart';
import '../models/stroke_model.dart';
import 'background_engine.dart';

Path buildPath(List<Offset> points) {
  final path = Path();
  if (points.isEmpty) return path;
  
  path.moveTo(points.first.dx, points.first.dy);
  
  if (points.length == 1) {
    path.addOval(Rect.fromCircle(center: points.first, radius: 0.1));
    return path;
  }

  // 🚀 ALTA FIDELIDADE: Usar lineTo para preservar a escrita original do autor.
  // Isto também é muito mais performático para traços com muitos pontos.
  for (int i = 1; i < points.length; i++) {
    path.lineTo(points[i].dx, points[i].dy);
  }

  return path;
}

class BackgroundPainter extends CustomPainter {
  final NotebookConfiguration? notebookConfig;
  final BackgroundConfig? bgConfig;
  
  // 🚀 FALLBACK para compatibilidade com código antigo
  final String? lineType;
  final double? lineSpacing;

  BackgroundPainter({
    this.notebookConfig, 
    this.bgConfig,
    this.lineType,
    this.lineSpacing,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (notebookConfig != null && bgConfig != null) {
      BackgroundEngine.draw(canvas, size, notebookConfig!, bgConfig!);
      return;
    }

    // 🚀 LÓGICA DE LEGACY (Se não houver config rica)
    final type = bgConfig?.type ?? lineType ?? 'ruled';
    final spacing = bgConfig?.spacing ?? lineSpacing ?? 28.0;

    final bgPaint = Paint()
      ..color = const Color(0xFF1B365D).withOpacity(0.18)
      ..strokeWidth = 1.0;

    if (type == 'ruled') {
      canvas.drawLine(
          const Offset(60, 0),
          Offset(60, size.height),
          Paint()
            ..color = Colors.redAccent.withOpacity(0.4)
            ..strokeWidth = 1.5);
      for (double y = 90; y < size.height - 60; y += spacing) {
        canvas.drawLine(Offset(60, y), Offset(size.width - 20, y), bgPaint);
      }
    } else if (type == 'grid') {
      for (double y = 90; y < size.height - 60; y += spacing) {
        canvas.drawLine(Offset(20, y), Offset(size.width - 20, y), bgPaint);
      }
      for (double x = 20; x < size.width - 20; x += spacing) {
        canvas.drawLine(Offset(x, 90), Offset(x, size.height - 60), bgPaint);
      }
    } else if (type == 'dots') {
      for (double y = 90; y < size.height - 60; y += spacing) {
        for (double x = 20; x < size.width - 20; x += spacing) {
          canvas.drawCircle(Offset(x, y), 1.2, bgPaint);
        }
      }
    } else if (type == 'engineering') {
      final minorPaint = Paint()..color = const Color(0xFF1B365D).withOpacity(0.08)..strokeWidth = 0.5;
      final majorPaint = Paint()..color = const Color(0xFF1B365D).withOpacity(0.2)..strokeWidth = 1.0;

      for (double y = 0; y < size.height; y += 10) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), (y % 50 == 0) ? majorPaint : minorPaint);
      }
      for (double x = 0; x < size.width; x += 10) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), (x % 50 == 0) ? majorPaint : minorPaint);
      }
    }
  }

  @override
  bool shouldRepaint(BackgroundPainter oldDelegate) =>
      oldDelegate.lineType != lineType || 
      oldDelegate.lineSpacing != lineSpacing ||
      oldDelegate.bgConfig != bgConfig;
}

class StrokesPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Set<String> selectedStrokeIds;
  final Rect? selectionRect;
  final List<Offset>? lassoPath; // 🚀 Novo
  final int pageVersion;
  final Set<String> remoteMovingStrokeIds;
  final Set<String>? visibleAuthorIds;
  final bool isAuthorColorEnabled;
  final Map<String, Color> userColors;
  final Offset selectionDelta;

  StrokesPainter({
    required this.strokes,
    required this.selectedStrokeIds,
    required this.selectionRect,
    this.lassoPath, // 🚀
    required this.pageVersion,
    this.remoteMovingStrokeIds = const {},
    this.visibleAuthorIds,
    this.isAuthorColorEnabled = false,
    this.userColors = const {},
    this.selectionDelta = Offset.zero,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      if (stroke.isDeleted || remoteMovingStrokeIds.contains(stroke.id)) continue;

      if (visibleAuthorIds != null && stroke.creatorId != null) {
        if (!visibleAuthorIds!.contains(stroke.creatorId)) continue;
      }

      final bool isSelected = selectedStrokeIds.contains(stroke.id);

      Color strokeColor = Color(int.parse(stroke.color.replaceFirst('#', '0xFF')));
      if (isAuthorColorEnabled && stroke.creatorId != null && userColors.containsKey(stroke.creatorId)) {
        strokeColor = userColors[stroke.creatorId]!;
      }

      final paint = Paint()
        ..color = stroke.isHighlighter ? strokeColor.withOpacity(0.4) : strokeColor
        ..strokeWidth = stroke.thickness
        ..style = PaintingStyle.stroke
        ..strokeCap = stroke.isHighlighter ? StrokeCap.square : StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode = stroke.isHighlighter ? BlendMode.multiply : BlendMode.srcOver;

      canvas.save();
      if (isSelected && selectionDelta != Offset.zero) {
        canvas.translate(selectionDelta.dx, selectionDelta.dy);
      }

      canvas.drawPath(buildPath(stroke.points), paint);
      canvas.restore();
    }

    if (selectionRect != null) {
      canvas.drawRect(selectionRect!, Paint()..color = const Color(0x190F4C5C)..style = PaintingStyle.fill);
      canvas.drawRect(
          selectionRect!,
          Paint()
            ..color = const Color(0xFF0F4C5C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5);
    }

    if (lassoPath != null && lassoPath!.isNotEmpty) {
      final Path path = Path()..moveTo(lassoPath!.first.dx, lassoPath!.first.dy);
      for (var i = 1; i < lassoPath!.length; i++) {
        path.lineTo(lassoPath![i].dx, lassoPath![i].dy);
      }
      // Não fechar o path se for desenho live, ou fechar? Geralmente se fecha para seleção.
      path.close();

      canvas.drawPath(path, Paint()..color = const Color(0x190F4C5C)..style = PaintingStyle.fill);
      canvas.drawPath(
          path,
          Paint()
            ..color = const Color(0xFF0F4C5C)
            ..style = PaintingStyle.stroke
            ..strokeWidth = 1.5
            ..strokeCap = StrokeCap.round
            ..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(StrokesPainter oldDelegate) {
    return oldDelegate.pageVersion != pageVersion ||
        oldDelegate.selectionRect != selectionRect ||
        oldDelegate.lassoPath != lassoPath || // 🚀
        oldDelegate.selectionDelta != selectionDelta ||
        !setEquals(oldDelegate.visibleAuthorIds, visibleAuthorIds) ||
        !setEquals(oldDelegate.remoteMovingStrokeIds, remoteMovingStrokeIds) ||
        !setEquals(oldDelegate.selectedStrokeIds, selectedStrokeIds) ||
        !listEquals(oldDelegate.strokes, strokes);
  }
}

class ActiveStrokePainter extends CustomPainter {
  final List<Offset> currentPoints;
  final Color visualColor; 
  final double currentThickness;
  final bool isHighlighter; // 🚀

  ActiveStrokePainter({required this.currentPoints, required this.visualColor, required this.currentThickness, this.isHighlighter = false});

  @override
  void paint(Canvas canvas, Size size) {
    if (currentPoints.isEmpty) return;
    final paint = Paint()
      ..color = isHighlighter ? visualColor.withOpacity(0.4) : visualColor
      ..strokeWidth = currentThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = isHighlighter ? StrokeCap.square : StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..blendMode = isHighlighter ? BlendMode.multiply : BlendMode.srcOver;
    canvas.drawPath(buildPath(currentPoints), paint);
  }

  @override
  bool shouldRepaint(ActiveStrokePainter oldDelegate) {
    return oldDelegate.visualColor != visualColor ||
           oldDelegate.currentThickness != currentThickness ||
           !listEquals(oldDelegate.currentPoints, currentPoints);
  }
}

class RemoteLiveStrokesPainter extends CustomPainter {
  final Map<String, Stroke> liveStrokes;
  final int targetPageNumber; 
  final bool isAuthorColorEnabled; 
  final Map<String, Color> userColors; 

  RemoteLiveStrokesPainter({
    required this.liveStrokes, 
    required this.targetPageNumber,
    this.isAuthorColorEnabled = false,
    this.userColors = const {},
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (liveStrokes.isEmpty) return;
    for (final stroke in liveStrokes.values) {
      if (stroke.isDeleted || (stroke.points.isEmpty && stroke.liveOffset == Offset.zero)) continue;
      if (stroke.pageNumber != null && stroke.pageNumber != targetPageNumber) continue;

      Color strokeColor = Color(int.parse(stroke.color.replaceFirst('#', '0xFF')));
      if (isAuthorColorEnabled && stroke.creatorId != null && userColors.containsKey(stroke.creatorId)) {
        strokeColor = userColors[stroke.creatorId]!;
      }

      final paint = Paint()
        ..color = stroke.isHighlighter ? strokeColor.withOpacity(0.32) : strokeColor.withOpacity(0.8)
        ..strokeWidth = stroke.thickness
        ..style = PaintingStyle.stroke
        ..strokeCap = stroke.isHighlighter ? StrokeCap.square : StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..blendMode = stroke.isHighlighter ? BlendMode.multiply : BlendMode.srcOver;

      canvas.save();
      if (stroke.liveOffset != Offset.zero) {
        canvas.translate(stroke.liveOffset.dx, stroke.liveOffset.dy);
      }
      canvas.drawPath(buildPath(stroke.points), paint);
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(RemoteLiveStrokesPainter oldDelegate) {
    return oldDelegate.targetPageNumber != targetPageNumber ||
           !mapEquals(oldDelegate.liveStrokes, liveStrokes);
  }
}

class RemotePointersPainter extends CustomPainter {
  final Map<String, dynamic> pointers;
  final List<Map<String, dynamic>> onlineUsers;
  final int targetPageNumber; 

  RemotePointersPainter({required this.pointers, required this.onlineUsers, required this.targetPageNumber});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..style = PaintingStyle.fill;

    pointers.forEach((uid, data) {
      final int? pageNum = data['page_number'];
      if (pageNum != null && pageNum != targetPageNumber) return;

      final Offset pos = data['pos'];
      final user = onlineUsers.firstWhere((u) => u['id'].toString() == uid, orElse: () => <String, dynamic>{});
      if (user.isEmpty) return;
      
      final Color color = (user['color'] as Color?) ?? Colors.grey;

      paint.color = color;
      final Path path = Path()
        ..moveTo(pos.dx, pos.dy)
        ..lineTo(pos.dx + 12, pos.dy + 12)
        ..lineTo(pos.dx + 5, pos.dy + 12)
        ..lineTo(pos.dx, pos.dy + 18)
        ..close();
      canvas.drawPath(path, paint);

      final String label = user['name'] ?? 'Colega';
      final String? tool = data['tool'];

      final textPainter = TextPainter(
        text: TextSpan(
          text: label,
          style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      IconData? toolIcon;
      if (tool != null) toolIcon = _getToolIcon(tool);

      final iconPainter = toolIcon != null ? TextPainter(
        text: TextSpan(
          text: String.fromCharCode(toolIcon.codePoint),
          style: TextStyle(
            color: Colors.white.withOpacity(0.9),
            fontSize: 10,
            fontFamily: toolIcon.fontFamily,
            package: toolIcon.fontPackage,
          ),
        ),
        textDirection: TextDirection.ltr,
      ) : null;
      iconPainter?.layout();

      final double iconWidth = iconPainter != null ? iconPainter.width + 4 : 0;
      final double totalWidth = textPainter.width + iconWidth + 12;
      final double totalHeight = textPainter.height + 6;

      final rect = Rect.fromLTWH(pos.dx + 14, pos.dy + 14, totalWidth, totalHeight);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), paint);

      if (iconPainter != null) iconPainter.paint(canvas, pos + const Offset(18, 16));
      textPainter.paint(canvas, pos + Offset(18 + iconWidth, 17));
    });
  }

  IconData _getToolIcon(String toolName) {
    switch (toolName) {
      case 'draw': return Icons.edit_rounded;
      case 'text': return Icons.text_fields_rounded;
      case 'eraser': return Icons.auto_fix_normal_rounded;
      case 'select': return Icons.ads_click_rounded;
      case 'insertImage':
      case 'imageEdit': return Icons.image_rounded;
      default: return Icons.pan_tool_alt_rounded;
    }
  }

  @override
  bool shouldRepaint(RemotePointersPainter oldDelegate) {
    return oldDelegate.targetPageNumber != targetPageNumber ||
           !mapEquals(oldDelegate.pointers, pointers) ||
           !listEquals(oldDelegate.onlineUsers, onlineUsers);
  }
}
