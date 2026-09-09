import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../notebooks/models/notebook_configuration.dart';
import '../models/canvas_enums.dart';
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
  for (int i = 1; i < points.length; i++) {
    path.lineTo(points[i].dx, points[i].dy);
  }
  return path;
}

/// 🚀 v10.21: Suavização Bézier Opcional com Nível e Performance Otimizada
Path buildSmoothPath(List<Offset> points, [double level = 0.5]) {
  final path = Path();
  if (points.length < 3 || level <= 0.05) return buildPath(points);
  
  path.moveTo(points.first.dx, points.first.dy);
  
  for (int i = 1; i < points.length - 2; i++) {
    final xc = (points[i].dx + points[i + 1].dx) / 2;
    final yc = (points[i].dy + points[i + 1].dy) / 2;
    path.quadraticBezierTo(points[i].dx, points[i].dy, xc, yc);
  }
  
  path.quadraticBezierTo(
    points[points.length - 2].dx, 
    points[points.length - 2].dy, 
    points.last.dx, 
    points.last.dy
  );
  
  return path;
}

class BackgroundPainter extends CustomPainter {
  final NotebookConfiguration? notebookConfig;
  final BackgroundConfig? bgConfig;
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
      oldDelegate.bgConfig != bgConfig ||
      oldDelegate.notebookConfig != notebookConfig;
}

class StrokesPainter extends CustomPainter {
  final List<Stroke> strokes;
  final Set<String> selectedStrokeIds;
  final Rect? selectionRect;
  final List<Offset>? lassoPath;
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
    this.lassoPath,
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
      if (visibleAuthorIds != null && stroke.creatorId != null && !visibleAuthorIds!.contains(stroke.creatorId)) continue;

      final bool isSelected = selectedStrokeIds.contains(stroke.id);
      Color strokeColor = Color(int.parse(stroke.color.replaceFirst('#', '0xFF')));
      if (isAuthorColorEnabled && stroke.creatorId != null && userColors.containsKey(stroke.creatorId)) {
        strokeColor = userColors[stroke.creatorId]!;
      }

      canvas.save();
      if (isSelected && selectionDelta != Offset.zero) {
        canvas.translate(selectionDelta.dx, selectionDelta.dy);
      }

      final path = stroke.smoothingLevel > 0 
          ? buildSmoothPath(stroke.points, stroke.smoothingLevel) 
          : buildPath(stroke.points);
          
      _renderArtisticStroke(
        canvas: canvas, 
        path: path, 
        brushType: stroke.brushType, 
        color: strokeColor, 
        thickness: stroke.thickness, 
        opacity: stroke.opacity,
        isHighlighter: stroke.isHighlighter, 
        points: stroke.points,
      );

      canvas.restore();
    }

    if (selectionRect != null) {
      canvas.drawRect(selectionRect!, Paint()..color = const Color(0x190F4C5C)..style = PaintingStyle.fill);
      canvas.drawRect(selectionRect!, Paint()..color = const Color(0xFF0F4C5C)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }

    if (lassoPath != null && lassoPath!.isNotEmpty) {
      final Path path = Path()..moveTo(lassoPath!.first.dx, lassoPath!.first.dy);
      for (var i = 1; i < lassoPath!.length; i++) path.lineTo(lassoPath![i].dx, lassoPath![i].dy);
      path.close();
      canvas.drawPath(path, Paint()..color = const Color(0x190F4C5C)..style = PaintingStyle.fill);
      canvas.drawPath(path, Paint()..color = const Color(0xFF0F4C5C)..style = PaintingStyle.stroke..strokeWidth = 1.5..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round);
    }
  }

  @override
  bool shouldRepaint(StrokesPainter oldDelegate) {
    return oldDelegate.pageVersion != pageVersion ||
        oldDelegate.selectionRect != selectionRect ||
        oldDelegate.lassoPath != lassoPath ||
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
  final double opacity; 
  final bool isHighlighter;
  final BrushType brushType;
  final double smoothingLevel;

  ActiveStrokePainter({
    required this.currentPoints, 
    required this.visualColor, 
    required this.currentThickness, 
    this.opacity = 1.0,
    this.isHighlighter = false,
    this.brushType = BrushType.gel,
    this.smoothingLevel = 0.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentPoints.isEmpty) return;
    final path = smoothingLevel > 0 
        ? buildSmoothPath(currentPoints, smoothingLevel) 
        : buildPath(currentPoints);
        
    _renderArtisticStroke(
      canvas: canvas, 
      path: path, 
      brushType: brushType, 
      color: visualColor, 
      thickness: currentThickness, 
      opacity: opacity,
      isHighlighter: isHighlighter, 
      points: currentPoints,
    );
  }

  @override
  bool shouldRepaint(ActiveStrokePainter oldDelegate) {
    return oldDelegate.visualColor != visualColor ||
           oldDelegate.currentThickness != currentThickness ||
           oldDelegate.brushType != brushType ||
           oldDelegate.smoothingLevel != smoothingLevel ||
           oldDelegate.opacity != opacity ||
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

      canvas.save();
      if (stroke.liveOffset != Offset.zero) canvas.translate(stroke.liveOffset.dx, stroke.liveOffset.dy);
      
      final path = stroke.smoothingLevel > 0 
          ? buildSmoothPath(stroke.points, stroke.smoothingLevel) 
          : buildPath(stroke.points);
          
      _renderArtisticStroke(
        canvas: canvas, 
        path: path, 
        brushType: stroke.brushType, 
        color: strokeColor, 
        thickness: stroke.thickness, 
        opacity: stroke.opacity,
        isHighlighter: stroke.isHighlighter, 
        points: stroke.points,
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(RemoteLiveStrokesPainter oldDelegate) {
    return oldDelegate.targetPageNumber != targetPageNumber || !mapEquals(oldDelegate.liveStrokes, liveStrokes);
  }
}

void _renderArtisticStroke({
  required Canvas canvas, 
  required Path path, 
  required BrushType brushType, 
  required Color color, 
  required double thickness, 
  double opacity = 1.0,
  bool isHighlighter = false, 
  required List<Offset> points,
}) {
  final paintColor = color.withOpacity(opacity * (isHighlighter ? 0.4 : 1.0));
  
  if (brushType == BrushType.neon) {
    canvas.drawPath(path, _getPaintForBrush(BrushType.neon, paintColor, thickness * 2.5, false)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8.0));
    canvas.drawPath(path, _getPaintForBrush(BrushType.neon, paintColor, thickness, false)..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.0));
    canvas.drawPath(path, _getPaintForBrush(BrushType.gel, Colors.white.withOpacity(opacity), thickness * 0.4, false));
  } else if (brushType == BrushType.fountain) {
    _drawFountainPath(canvas, points, paintColor, thickness);
  } else {
    canvas.drawPath(path, _getPaintForBrush(brushType, paintColor, thickness, isHighlighter));
  }
}

void _drawFountainPath(Canvas canvas, List<Offset> points, Color color, double baseThickness) {
  if (points.length < 2) return;
  for (int i = 0; i < points.length - 1; i++) {
    final dist = (points[i] - points[i + 1]).distance;
    final thickness = (baseThickness * (1.5 - (dist / 15).clamp(0.0, 1.2))).clamp(0.5, baseThickness * 2);
    final paint = Paint()..color = color..strokeWidth = thickness..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
    canvas.drawLine(points[i], points[i + 1], paint);
  }
}

Paint _getPaintForBrush(BrushType type, Color color, double thickness, bool isHighlighter) {
  final paint = Paint()
    ..color = color
    ..strokeWidth = thickness
    ..style = PaintingStyle.stroke
    ..strokeCap = StrokeCap.round
    ..strokeJoin = StrokeJoin.round;

  switch (type) {
    case BrushType.gel: 
      return isHighlighter 
          ? (paint..strokeCap = StrokeCap.square..blendMode = BlendMode.multiply) 
          : paint;
    case BrushType.fountain: return paint;
    case BrushType.pencil: 
      return paint..color = color.withOpacity(color.opacity * 0.8)..strokeCap = StrokeCap.butt..strokeJoin = StrokeJoin.bevel;
    case BrushType.marker: 
      return paint..strokeCap = StrokeCap.square..strokeJoin = StrokeJoin.miter;
    case BrushType.watercolor: 
      return paint..color = color.withOpacity(color.opacity * 0.6)..maskFilter = MaskFilter.blur(BlurStyle.normal, thickness * 0.4)..blendMode = BlendMode.multiply;
    case BrushType.crayon: 
      return paint..strokeWidth = thickness * 1.5..color = color.withOpacity(color.opacity * 0.9)..strokeCap = StrokeCap.square..maskFilter = const MaskFilter.blur(BlurStyle.solid, 1.2);
    case BrushType.airbrush: 
      return paint..color = color.withOpacity(color.opacity * 0.4)..maskFilter = MaskFilter.blur(BlurStyle.normal, thickness * 1.5);
    case BrushType.neon: 
      return paint..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4.0);
    case BrushType.calligraphy: return paint..strokeCap = StrokeCap.butt..strokeWidth = thickness * 2.5;
    case BrushType.ribbon: return paint..strokeWidth = thickness * 0.75;
    case BrushType.fineliner: return paint..strokeWidth = thickness * 0.5..strokeCap = StrokeCap.butt..strokeJoin = StrokeJoin.miter;
    case BrushType.monoline: return paint..strokeWidth = thickness..strokeCap = StrokeCap.round..strokeJoin = StrokeJoin.round;
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
      final Path path = Path()..moveTo(pos.dx, pos.dy)..lineTo(pos.dx + 12, pos.dy + 12)..lineTo(pos.dx + 5, pos.dy + 12)..lineTo(pos.dx, pos.dy + 18)..close();
      canvas.drawPath(path, paint);
      final String label = user['name'] ?? 'Colega';
      final textPainter = TextPainter(text: TextSpan(text: label, style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)), textDirection: TextDirection.ltr);
      textPainter.layout();
      final rect = Rect.fromLTWH(pos.dx + 14, pos.dy + 14, textPainter.width + 12, textPainter.height + 6);
      canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(6)), paint);
      textPainter.paint(canvas, pos + const Offset(20, 17));
    });
  }

  @override
  bool shouldRepaint(RemotePointersPainter oldDelegate) {
    return oldDelegate.targetPageNumber != targetPageNumber || !mapEquals(oldDelegate.pointers, pointers) || !listEquals(oldDelegate.onlineUsers, onlineUsers);
  }
}
