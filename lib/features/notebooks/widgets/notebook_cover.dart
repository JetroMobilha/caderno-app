import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/notebook_model.dart';

class NotebookCover extends StatelessWidget {
  final Notebook notebook;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const NotebookCover({
    super.key,
    required this.notebook,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    // Tenta interpretar a cor gravada, senão usa a cor primária
    Color coverColor = AppColors.primary;
    try {
      if (notebook.color != null) {
        coverColor = Color(int.parse(notebook.color!.replaceFirst('#', '0xFF')));
      }
    } catch (_) {}

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Container(
        decoration: BoxDecoration(
          color: coverColor,
          borderRadius: const BorderRadius.only(
            topRight: Radius.circular(12),
            bottomRight: Radius.circular(12),
            topLeft: Radius.circular(4),
            bottomLeft: Radius.circular(4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 8,
              offset: const Offset(4, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            // =========================================================
            // 1. A LOMBADA DO CADERNO (O efeito de encadernação)
            // =========================================================
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              child: Container(
                width: 12,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.2),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(4),
                    bottomLeft: Radius.circular(4),
                  ),
                  border: Border(
                    right: BorderSide(color: Colors.black.withOpacity(0.3), width: 1),
                  ),
                ),
              ),
            ),

            // =========================================================
            // 2. DETALHES DA CAPA (Pauta e Título)
            // =========================================================
            Positioned(
              left: 24,
              top: 16,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.9),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      notebook.title,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.lora(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: AppColors.textDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Etiqueta do tipo de pauta
                  Row(
                    children: [
                      Icon(
                        notebook.lineType == 'grid'
                            ? Icons.grid_4x4
                            : notebook.lineType == 'blank'
                            ? Icons.check_box_outline_blank
                            : Icons.view_headline,
                        size: 14,
                        color: Colors.white70,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        notebook.paperSize,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.white70,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}