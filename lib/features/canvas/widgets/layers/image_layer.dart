import 'dart:io' as io;
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/local_page_model.dart';
import '../../models/canvas_enums.dart';

class ImageLayer extends ConsumerStatefulWidget {
  final LocalPage page;

  const ImageLayer({
    super.key,
    required this.page,
  });

  @override
  ConsumerState<ImageLayer> createState() => _ImageLayerState();
}

class _ImageLayerState extends ConsumerState<ImageLayer> {
  @override
  Widget build(BuildContext context) {
    final toolState = ref.watch(canvasToolProvider);
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final docState = ref.watch(canvasDocumentProvider);

    return Stack(
      clipBehavior: Clip.none,
      children: widget.page.imageBlocks.where((img) => !img.isDeleted).map((img) {
        final bool isEditing = img.id == toolState.selectedEditingImageId;
        final bool isSelected = isEditing || toolState.selectedImageIds.contains(img.id);
        const double padding = 60.0;

        return AnimatedPositioned(
          duration: const Duration(milliseconds: 60),
          key: ValueKey('img_${img.id}'),
          left: img.position.dx - padding,
          top: img.position.dy - padding,
          child: Transform.rotate(
            angle: img.rotation,
            child: SizedBox(
              width: img.width + (padding * 2),
              height: img.height + (padding * 2),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: padding,
                    top: padding,
                    width: img.width,
                    height: img.height,
                    child: GestureDetector(
                      onTapDown: toolState.currentTool == ToolMode.imageEdit
                          ? (_) {
                              toolNotifier.selectIds(imageIds: {img.id});
                              // Logic to bring image to front and notify document
                            }
                          : null,
                      onPanUpdate: (isEditing || isSelected) && docState.currentUserRole != 'viewer'
                          ? (d) {
                              final double cosA = math.cos(img.rotation);
                              final double sinA = math.sin(img.rotation);
                              final Offset rotatedDelta = Offset(
                                d.delta.dx * cosA - d.delta.dy * sinA,
                                d.delta.dx * sinA + d.delta.dy * cosA,
                              );
                              setState(() {
                                img.position += rotatedDelta;
                              });
                              // Broadcast throttled update
                            }
                          : null,
                      child: Container(
                        decoration: BoxDecoration(
                          border: isSelected ? Border.all(color: const Color(0xFF0F4C5C), width: 3.0) : null,
                        ),
                        child: img.imagePath.startsWith('http')
                            ? Image.network(img.imagePath, fit: BoxFit.fill)
                            : Image.file(io.File(img.imagePath), fit: BoxFit.fill),
                      ),
                    ),
                  ),
                  if (isEditing && docState.currentUserRole != 'viewer') ...[
                    Positioned(
                      right: padding - 18,
                      bottom: padding - 18,
                      width: 36,
                      height: 36,
                      child: GestureDetector(
                        onPanUpdate: (d) {
                          setState(() {
                            img.width = (img.width + d.delta.dx).clamp(60.0, 1000.0);
                            img.height = (img.height + d.delta.dy).clamp(60.0, 1000.0);
                          });
                        },
                        onPanEnd: (_) {},
                        child: const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.open_in_full, size: 16),
                        ),
                      ),
                    ),
                    Positioned(
                      top: padding - 45,
                      left: padding + (img.width / 2) - 18,
                      child: GestureDetector(
                        onPanUpdate: (d) {
                          final center = Offset(padding + img.width / 2, padding + img.height / 2);
                          final currentPos = d.localPosition + Offset(padding + img.width / 2 - 18, padding - 45);
                          setState(() {
                            img.rotation = math.atan2(currentPos.dy - center.dy, currentPos.dx - center.dx) + (math.pi / 2);
                          });
                        },
                        onPanEnd: (_) {},
                        child: const CircleAvatar(
                          backgroundColor: Colors.white,
                          child: Icon(Icons.rotate_right),
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
