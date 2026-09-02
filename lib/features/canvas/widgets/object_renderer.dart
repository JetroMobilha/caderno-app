import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/page_object.dart';
import '../models/text_block_model.dart';
import '../models/image_block_model.dart';

class ObjectRenderer extends StatelessWidget {
  final PageObject object;
  final bool isReadOnly;

  const ObjectRenderer({
    super.key,
    required this.object,
    this.isReadOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    if (!object.isVisible) return const SizedBox.shrink();

    Widget content;
    if (object is TextBlock) {
      content = _buildText(object as TextBlock);
    } else if (object is ImageBlock) {
      content = _buildImage(object as ImageBlock);
    } else {
      content = const SizedBox.shrink();
    }

    return Positioned(
      left: object.position.dx,
      top: object.position.dy,
      child: Transform.rotate(
        angle: object.rotation,
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
}
