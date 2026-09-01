import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../canvas/widgets/background_engine.dart';
import '../models/notebook_configuration.dart';

class PagePreview extends StatelessWidget {
  final NotebookConfiguration config;
  final bool isVibrant; // 🚀 NOVO: Ativa cores mais fortes para miniaturas

  const PagePreview({
    super.key, 
    required this.config,
    this.isVibrant = false,
  });

  @override
  Widget build(BuildContext context) {
    final double pageWidth = config.page.width;
    final double pageHeight = config.page.height;

    return AspectRatio(
      aspectRatio: pageWidth / pageHeight,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(2), // 🚀 Mais fino para escala real
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10, offset: const Offset(0, 4)),
          ],
        ),
        child: FittedBox(
          fit: BoxFit.contain,
          child: SizedBox(
            width: pageWidth,
            height: pageHeight,
            child: ClipRect( // 🚀 Proteção extra para o desenho
              child: Stack(
                children: [
                  // 1. Background (Lines, Grid, etc.) - Passa a usar mm diretamente
                  _buildBackground(),

                  // 2. Margins (Visual guide)
                  _buildMarginsOverlay(),

                  // 3. Header
                  if (config.header.enabled)
                    Positioned(
                      top: config.margins.top > 0 ? config.margins.top - 12 : 5,
                      left: config.margins.left > 0 ? config.margins.left : 10,
                      right: config.margins.right > 0 ? config.margins.right : 10,
                      child: _buildHeaderFooter(config.header, isHeader: true),
                    ),

                  // 4. Footer
                  if (config.footer.enabled)
                    Positioned(
                      bottom: config.margins.bottom > 0 ? config.margins.bottom - 12 : 5,
                      left: config.margins.left > 0 ? config.margins.left : 10,
                      right: config.margins.right > 0 ? config.margins.right : 10,
                      child: _buildHeaderFooter(config.footer, isHeader: false),
                    ),

                  // 5. Page Numbering
                  if (config.numbering.enabled)
                    _buildNumbering(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBackground() {
    return CustomPaint(
      size: Size.infinite,
      painter: _PageBackgroundPainter(config: config, isVibrant: isVibrant),
    );
  }

  Widget _buildMarginsOverlay() {
    return Container(
      margin: EdgeInsets.only(
        top: config.margins.top,
        left: config.margins.left,
        right: config.margins.right,
        bottom: config.margins.bottom,
      ),
      decoration: BoxDecoration(
        // 🚀 Margens azuladas subtis em mm
        border: Border.all(color: Colors.blue.withOpacity(0.08), width: 0.2),
      ),
    );
  }

  Widget _buildHeaderFooter(HeaderFooterConfig hf, {required bool isHeader}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (hf.fields.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 6), // 🚀 Mais espaço lateral em mm
            child: Wrap(
              spacing: 16, // 🚀 Mais espaço entre campos em mm
              runSpacing: 4, // mm
              children: hf.fields.map((f) => Text(
                '$f: ________',
                style: GoogleFonts.inter(
                  fontSize: 3.5, 
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                  height: 1.2,
                ),
              )).toList(),
            ),
          ),
        if (isHeader)
          Divider(height: 6, thickness: 0.2, color: Colors.black12), // mm
      ],
    );
  }

  Widget _buildNumbering() {
    Alignment alignment = Alignment.bottomRight;
    if (config.numbering.position == 'bottom-center') alignment = Alignment.bottomCenter;
    if (config.numbering.position == 'top-right') alignment = Alignment.topRight;

    String label = '1';
    switch (config.numbering.format) {
      case 'counter': label = '1 / 10'; break;
      case 'labeled': label = 'Pág. 1'; break;
      case 'roman': label = 'I'; break;
      default: label = '1'; break;
    }

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(8.0), // mm
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 3.0, // mm
            fontWeight: FontWeight.bold, 
            color: Colors.black26
          ),
        ),
      ),
    );
  }
}

class _PageBackgroundPainter extends CustomPainter {
  final NotebookConfiguration config;
  final bool isVibrant;

  _PageBackgroundPainter({required this.config, required this.isVibrant});

  @override
  void paint(Canvas canvas, Size size) {
    // 🚀 Aplicar vibrância se necessário
    var bg = config.background;
    if (isVibrant && bg.lineColor == null) {
      bg = BackgroundConfig(
        type: bg.type,
        subType: bg.subType,
        spacing: bg.spacing,
        color: bg.color,
        lineColor: '#5C5C5C', // 🚀 Cor mais escura para miniaturas
        showRedMargin: bg.showRedMargin,
        opacity: 1.0,
      );
    }

    BackgroundEngine.draw(canvas, size, config, bg);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
