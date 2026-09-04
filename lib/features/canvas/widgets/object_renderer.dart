import 'dart:io' as io;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/page_object.dart';
import '../models/text_block_model.dart';
import '../models/image_block_model.dart';
import '../models/shape_model.dart';
import '../models/audio_block_model.dart';
import '../models/animation_object_model.dart';
import '../models/table_model.dart'; // 🚀 v29
import '../models/link_model.dart'; // 🚀 v29
import '../models/attachment_model.dart'; // 🚀 v29
import '../../explanations/models/explanation_model.dart';
import '../../explanations/widgets/animators/math_animator.dart';
import '../../explanations/widgets/animators/physics_animator.dart';
import '../../explanations/widgets/animators/engineering_animator.dart';

class ObjectRenderer extends ConsumerStatefulWidget {
  final PageObject object;
  final bool isReadOnly;

  const ObjectRenderer({
    super.key,
    required this.object,
    this.isReadOnly = false,
  });

  @override
  ConsumerState<ObjectRenderer> createState() => _ObjectRendererState();
}

class _ObjectRendererState extends ConsumerState<ObjectRenderer> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    if (widget.object is AnimationObject) {
      final anim = widget.object as AnimationObject;
      if (anim.autoPlay) {
        _animationController = AnimationController(
          vsync: this,
          duration: const Duration(seconds: 1),
        );
        if (anim.isLooping) {
          _animationController!.repeat();
        } else {
          _animationController!.forward();
        }
      }
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.object.isVisible) return const SizedBox.shrink();

    Widget content;
    if (widget.object is TextBlock) {
      content = _buildText(widget.object as TextBlock);
    } else if (widget.object is ImageBlock) {
      content = _buildImage(widget.object as ImageBlock);
    } else if (widget.object is ShapeObject) {
      content = _buildShape(widget.object as ShapeObject);
    } else if (widget.object is AudioBlock) {
      content = _buildAudio(widget.object as AudioBlock);
    } else if (widget.object is AnimationObject) {
      content = _buildAnimation(widget.object as AnimationObject);
    } else if (widget.object is TableObject) { // 🚀 v29
      content = _buildTable(widget.object as TableObject);
    } else if (widget.object is LinkObject) { // 🚀 v29
      content = _buildLink(widget.object as LinkObject);
    } else if (widget.object is AttachmentObject) { // 🚀 v29
      content = _buildAttachment(widget.object as AttachmentObject);
    } else {
      content = const SizedBox.shrink();
    }

    return Positioned(
      left: widget.object.position.dx,
      top: widget.object.position.dy,
      child: Transform.rotate(
        angle: widget.object.rotation,
        child: content,
      ),
    );
  }

  Widget _buildText(TextBlock tb) {
    return Text(
      tb.text,
      style: GoogleFonts.inter(
        fontSize: tb.fontSize,
        fontWeight: tb.isBold ? FontWeight.bold : FontWeight.normal,
        fontStyle: tb.isItalic ? FontStyle.italic : FontStyle.normal,
        decoration: tb.isUnderline ? TextDecoration.underline : TextDecoration.none,
        color: Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF'))),
      ),
    );
  }

  Widget _buildImage(ImageBlock img) {
    return SizedBox(
      width: img.width,
      height: img.height,
      child: img.imagePath.startsWith('http')
          ? Image.network(img.imagePath, fit: BoxFit.fill)
          : Image.file(io.File(img.imagePath), fit: BoxFit.fill),
    );
  }

  Widget _buildShape(ShapeObject shape) {
    return CustomPaint(
      size: shape.size,
      painter: _ShapePainter(shape: shape),
    );
  }

  Widget _buildAudio(AudioBlock audio) {
    return Container(
      width: audio.size.width,
      height: audio.size.height,
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C5C).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFF0F4C5C).withValues(alpha: 0.3)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF0F4C5C), size: 28),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(audio.title, 
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F4C5C))
                ),
                Text('${(audio.durationSeconds / 60).floor()}:${(audio.durationSeconds % 60).toString().padLeft(2, '0')}', 
                  style: TextStyle(fontSize: 9, color: Colors.black.withValues(alpha: 0.5))
                ),
              ],
            ),
          ),
          const Icon(Icons.graphic_eq_rounded, color: Color(0xFF0F4C5C), size: 16),
        ],
      ),
    );
  }

  Widget _buildAnimation(AnimationObject anim) {
    if (anim.animationType == AnimationObjectType.physics && anim.configData != null) {
      return AnimatedBuilder(
        animation: _animationController!,
        builder: (context, child) {
          return CustomPaint(
            size: anim.size,
            painter: _PhysicsAnimationPainter(
              anim: anim,
              time: _animationController!.value,
            ),
          );
        },
      );
    }
    
    // Placeholder para Lottie ou outros
    return SizedBox(
      width: anim.size.width,
      height: anim.size.height,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.animation_rounded, color: Color(0xFFE36414), size: 32),
            Text(anim.assetPath ?? 'Animação', style: const TextStyle(fontSize: 8)),
          ],
        ),
      ),
    );
  }

  Widget _buildTable(TableObject table) {
    return Container(
      width: table.size.width,
      height: table.size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Color(int.parse(table.borderColor.replaceFirst('#', '0xFF'))), width: table.borderWidth),
      ),
      child: Table(
        border: TableBorder.all(color: Color(int.parse(table.borderColor.replaceFirst('#', '0xFF'))), width: table.borderWidth),
        children: List.generate(table.rows, (r) {
          return TableRow(
            children: List.generate(table.cols, (c) {
              final text = table.cellData['$r,$c'] ?? '';
              return Container(
                padding: const EdgeInsets.all(4),
                height: table.size.height / table.rows,
                alignment: Alignment.center,
                child: Text(text, style: const TextStyle(fontSize: 10)),
              );
            }),
          );
        }),
      ),
    );
  }

  Widget _buildLink(LinkObject link) {
    return Container(
      width: link.size.width,
      height: link.size.height,
      decoration: BoxDecoration(
        color: Color(int.parse(link.backgroundColor.replaceFirst('#', '0xFF'))),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(link.linkType == LinkType.internalPage ? Icons.description_outlined : Icons.link_rounded, 
            color: Color(int.parse(link.textColor.replaceFirst('#', '0xFF'))), size: 16
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(link.label, 
              maxLines: 1, overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Color(int.parse(link.textColor.replaceFirst('#', '0xFF'))), fontSize: 12, fontWeight: FontWeight.bold)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAttachment(AttachmentObject attach) {
    return Container(
      width: attach.size.width,
      height: attach.size.height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 10),
      child: Row(
        children: [
          Icon(_getAttachmentIcon(attach.fileExtension), color: const Color(0xFF0F4C5C), size: 24),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(attach.fileName, 
                  maxLines: 1, overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)
                ),
                Text('${(attach.fileSize / 1024).toStringAsFixed(1)} KB', 
                  style: TextStyle(fontSize: 9, color: Colors.black.withValues(alpha: 0.4))
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getAttachmentIcon(String ext) {
    final e = ext.toLowerCase();
    if (e == 'pdf') return Icons.picture_as_pdf_rounded;
    if (['doc', 'docx'].contains(e)) return Icons.description_rounded;
    if (['xls', 'xlsx'].contains(e)) return Icons.table_view_rounded;
    return Icons.insert_drive_file_rounded;
  }
}

class _ShapePainter extends CustomPainter {
  final ShapeObject shape;

  _ShapePainter({required this.shape});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Color(int.parse(shape.strokeColor.replaceFirst('#', '0xFF')))
      ..strokeWidth = shape.strokeWidth
      ..style = PaintingStyle.stroke;

    if (shape.fillColor != null && shape.isClosed) {
      final fillPaint = Paint()
        ..color = Color(int.parse(shape.fillColor!.replaceFirst('#', '0xFF')))
        ..style = PaintingStyle.fill;
      
      _drawPath(canvas, size, fillPaint);
    }

    _drawPath(canvas, size, paint);
  }

  void _drawPath(Canvas canvas, Size size, Paint paint) {
    switch (shape.shapeType) {
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
        _drawArrow(canvas, size, paint);
        break;
    }
  }

  void _drawArrow(Canvas canvas, Size size, Paint paint) {
    final start = Offset.zero;
    final end = Offset(size.width, size.height);
    canvas.drawLine(start, end, paint);
    
    final double angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
    const double arrowSize = 15.0;
    const double arrowAngle = math.pi / 6;

    final path = Path()
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle - arrowAngle),
        end.dy - arrowSize * math.sin(angle - arrowAngle),
      )
      ..moveTo(end.dx, end.dy)
      ..lineTo(
        end.dx - arrowSize * math.cos(angle + arrowAngle),
        end.dy - arrowSize * math.sin(angle + arrowAngle),
      );
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _ShapePainter oldDelegate) => 
      oldDelegate.shape.version != shape.version || oldDelegate.shape.updatedAt != shape.updatedAt;
}

class _PhysicsAnimationPainter extends CustomPainter {
  final AnimationObject anim;
  final double time;
  
  static final MathAnimator _mathAnimator = MathAnimator();
  static final PhysicsAnimator _physicsAnimator = PhysicsAnimator();
  static final EngineeringAnimator _engAnimator = EngineeringAnimator();

  _PhysicsAnimationPainter({required this.anim, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    final config = anim.configData;
    if (config == null) return;

    final type = config['type'];
    
    if (type == 'engineeringMechanism') {
      final exp = EngineeringExplanation(
        id: anim.id,
        position: Offset.zero,
        radius: (config['radius'] as num?)?.toDouble() ?? 40.0,
        angularVelocity: (config['angular_velocity'] as num?)?.toDouble() ?? 1.0,
        toothCount: config['tooth_count'] ?? 12,
        isGear: config['is_gear'] ?? true,
      );
      _engAnimator.paint(canvas, size, exp, time);
    } else if (type == 'physicsBody') {
      final exp = PhysicsExplanation(
        id: anim.id,
        position: Offset.zero,
        mass: (config['mass'] as num?)?.toDouble() ?? 1.0,
      );
      _physicsAnimator.paint(canvas, size, exp, time);
    } else if (type == 'mathFunction') {
      final exp = MathExplanation(
        id: anim.id,
        position: Offset.zero,
        expression: config['expression'] ?? 'sin(x)',
      );
      _mathAnimator.paint(canvas, size, exp, time);
    }
  }

  @override
  bool shouldRepaint(covariant _PhysicsAnimationPainter oldDelegate) => true;
}
