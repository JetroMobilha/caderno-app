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
import '../models/table_model.dart';
import '../models/link_model.dart';
import '../models/attachment_model.dart';
import '../../explanations/models/explanation_model.dart';
import '../../explanations/widgets/animators/math_animator.dart';
import '../../explanations/widgets/animators/physics_animator.dart';
import '../../explanations/widgets/animators/engineering_animator.dart';
import '../models/canvas_enums.dart'; 
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_viewport_provider.dart';

class ObjectRenderer extends ConsumerStatefulWidget {
  final PageObject object;
  final bool isReadOnly;
  final Offset? movementDelta; 
  final Size? liveScale; 
  final double? liveRotation; 

  const ObjectRenderer({
    super.key,
    required this.object,
    this.isReadOnly = false,
    this.movementDelta,
    this.liveScale,
    this.liveRotation,
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
    final toolState = ref.watch(canvasToolProvider);
    
    // 🚀 v3.5: Ocultar objeto se estiver em edição inline (Ghost Mode Real)
    final bool isEditingThis = (widget.object is TextBlock && toolState.activeTextBlock?.id == widget.object.id) ||
                               (widget.object is TableObject && toolState.activeTableId == widget.object.id);

    if (!widget.object.isVisible || isEditingThis) return const SizedBox.shrink();

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
    } else if (widget.object is TableObject) {
      content = _buildTable(widget.object as TableObject);
    } else if (widget.object is LinkObject) {
      content = _buildLink(widget.object as LinkObject);
    } else if (widget.object is AttachmentObject) {
      content = _buildAttachment(widget.object as AttachmentObject);
    } else {
      content = const SizedBox.shrink();
    }

    final position = widget.object.position + (widget.movementDelta ?? Offset.zero);
    final rotation = widget.object.rotation + (widget.liveRotation ?? 0.0);
    final size = Size(
      widget.object.size.width * (widget.liveScale?.width ?? 1.0),
      widget.object.size.height * (widget.liveScale?.height ?? 1.0),
    );

    return Positioned(
      left: position.dx,
      top: position.dy,
      child: Opacity(
        opacity: (widget.movementDelta != null || widget.liveScale != null || widget.liveRotation != null) ? 0.6 : 1.0,
        child: Transform.rotate(
          angle: rotation,
          alignment: Alignment.center,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                content,
                if (widget.object.isLocked)
                  Positioned(
                    right: 4, top: 4,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(color: Colors.orange.withOpacity(0.8), shape: BoxShape.circle),
                      child: const Icon(Icons.lock_rounded, size: 10, color: Colors.white),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildText(TextBlock tb) {
    final List<String> lines = tb.text.split('\n');
    final Color textColor = Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF')));
    final double effectiveLineHeight = tb.lineHeight;

    return Container(
      width: tb.size.width,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: tb.backgroundColorHex != null ? Color(int.parse(tb.backgroundColorHex!.replaceFirst('#', '0xFF'))) : null,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: _getCrossAxisAlignment(tb.textAlign),
        children: lines.asMap().entries.map((entry) {
          final int idx = entry.key;
          final String lineText = entry.value;
          
          Widget prefix = const SizedBox.shrink();
          if (tb.listType == ListType.bullet) {
            prefix = Padding(padding: const EdgeInsets.only(right: 8), child: Icon(Icons.circle, size: tb.fontSize * 0.4, color: textColor));
          } else if (tb.listType == ListType.numbered) {
            prefix = Padding(padding: const EdgeInsets.only(right: 8), child: Text('${idx + 1}.', style: GoogleFonts.inter(fontSize: tb.fontSize * 0.8, color: textColor, fontWeight: FontWeight.bold)));
          } else if (tb.listType == ListType.checklist) {
            final bool isChecked = tb.checkedLineIndices.contains(idx);
            prefix = GestureDetector(
              onTap: widget.isReadOnly ? null : () {
                final List<int> newIndices = List.from(tb.checkedLineIndices);
                if (isChecked) newIndices.remove(idx); else newIndices.add(idx);
                tb.checkedLineIndices = newIndices;
                
                final pageClientId = ref.read(canvasViewportProvider).currentPageClientId;
                if (pageClientId != null) {
                  final page = ref.read(canvasDocumentProvider).pages.firstWhere((p) => p.clientId == pageClientId);
                  ref.read(canvasDocumentProvider.notifier).updateObject(page, tb);
                }
              },
              child: Padding(
                padding: const EdgeInsets.only(right: 6), 
                child: Icon(isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, 
                  size: tb.fontSize, 
                  color: isChecked ? Colors.green : textColor
                )
              ),
            );
          }

          return Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              prefix,
              Expanded(
                child: Text(
                  lineText,
                  textAlign: tb.textAlign,
                  style: GoogleFonts.getFont(
                    tb.fontFamily ?? 'Inter',
                    fontSize: tb.fontSize,
                    height: effectiveLineHeight,
                    fontWeight: tb.isBold ? FontWeight.bold : FontWeight.normal,
                    fontStyle: tb.isItalic ? FontStyle.italic : FontStyle.normal,
                    decoration: TextDecoration.combine([
                      if (tb.isUnderline) TextDecoration.underline,
                      if (tb.isStrikethrough) TextDecoration.lineThrough,
                    ]),
                    color: textColor,
                  ),
                ),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }

  CrossAxisAlignment _getCrossAxisAlignment(TextAlign align) {
    switch (align) {
      case TextAlign.center: return CrossAxisAlignment.center;
      case TextAlign.right: return CrossAxisAlignment.end;
      default: return CrossAxisAlignment.start;
    }
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
    final toolState = ref.watch(canvasToolProvider);
    final isSelected = toolState.selectedTableIds.contains(table.id);
    
    return Container(
      width: table.size.width,
      height: table.size.height,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.9),
        border: Border.all(color: Color(int.parse(table.borderColor.replaceFirst('#', '0xFF'))), width: table.borderWidth),
        boxShadow: isSelected ? [BoxShadow(color: Colors.blueAccent.withOpacity(0.2), blurRadius: 10)] : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Table(
            border: TableBorder.all(color: Color(int.parse(table.borderColor.replaceFirst('#', '0xFF'))), width: table.borderWidth),
            children: List.generate(table.rows, (r) {
              return TableRow(
                children: List.generate(table.cols, (c) {
                  final text = table.cellData['$r,$c'] ?? '';
                  return GestureDetector(
                    onTap: () {
                      if (!isSelected) {
                        ref.read(canvasToolProvider.notifier).selectIds(tableIds: {table.id});
                      }
                    },
                    onDoubleTap: () => _editTableCell(table, r, c),
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      height: table.size.height / table.rows,
                      alignment: Alignment.center,
                      child: Text(text, 
                        maxLines: 2, 
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.inter(fontSize: (table.size.height / table.rows) * 0.4)
                      ),
                    ),
                  );
                }),
              );
            }),
          ),
        ],
      ),
    );
  }

  void _editTableCell(TableObject table, int row, int col) {
    ref.read(canvasToolProvider.notifier).setTableCellEditing(table.id, '$row,$col');
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
