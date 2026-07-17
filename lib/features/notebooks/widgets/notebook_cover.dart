import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../models/notebook_model.dart';

class NotebookCover extends StatefulWidget {
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
  State<NotebookCover> createState() => _NotebookCoverState();
}

class _NotebookCoverState extends State<NotebookCover> with SingleTickerProviderStateMixin {
  late double _scale;
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 150),
      lowerBound: 0.0,
      upperBound: 0.05, // Encolhe até 5% na pressão
    )..addListener(() {
      setState(() => _scale = 1 - _controller.value);
    });
    _scale = 1.0;
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) => _controller.forward();
  void _onTapUp(TapUpDetails details) {
    _controller.reverse();
    widget.onTap();
  }
  void _onTapCancel() => _controller.reverse();

  @override
  Widget build(BuildContext context) {
    // 🎨 Interpretação de Cor Robusta
    Color coverColor = AppColors.primary;
    try {
      if (widget.notebook.color != null && widget.notebook.color!.isNotEmpty) {
        coverColor = Color(int.parse(widget.notebook.color!.replaceFirst('#', '0xFF')));
      }
    } catch (_) {}

    final bool isUnsynced = widget.notebook.syncedWithCloud == 0 && widget.notebook.serverId == null;
    final bool isShared = widget.notebook.role != 'owner';
    final bool isPublished = widget.notebook.isPublished == 1;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onLongPress: widget.onLongPress,
      child: Transform.scale(
        scale: _scale,
        child: Container(
          decoration: BoxDecoration(
            color: coverColor,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(14),
              bottomRight: Radius.circular(14),
              topLeft: Radius.circular(6),
              bottomLeft: Radius.circular(6),
            ),
            boxShadow: [
              // Sombra Dupla para Efeito de Volume Real (Capa de Livro 3D)
              BoxShadow(
                color: coverColor.withOpacity(0.4),
                blurRadius: 10,
                offset: const Offset(3, 5),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 4,
                offset: const Offset(1, 2),
              ),
            ],
          ),
          child: Stack(
            children: [
              // =========================================================
              // 1. A LOMBADA COM TEXTURA REALISTA
              // =========================================================
              Positioned(
                left: 0,
                top: 0,
                bottom: 0,
                child: Container(
                  width: 14,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.black.withOpacity(0.35),
                        Colors.black.withOpacity(0.1),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(6),
                      bottomLeft: Radius.circular(6), // 👈 Faltava o "(" aqui antes do 6!
                    ),
                  ),
                  child: const Center(
                    child: VerticalDivider(
                      color: Colors.white12,
                      thickness: 1,
                      width: 1,
                      indent: 12,
                      endIndent: 12,
                    ),
                  ),
                ),
              ),

              // =========================================================
              // 2. CONTEÚDO E ETIQUETAS DA CAPA
              // =========================================================
              Positioned(
                left: 26,
                top: 18,
                right: 12,
                bottom: 14,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // --- TOPO: TÍTULO DO CADERNO ---
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.92),
                            borderRadius: BorderRadius.circular(6),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 4, offset: const Offset(0, 2))
                            ],
                          ),
                          child: Text(
                            widget.notebook.title,
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.lora(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: AppColors.textDark,
                              height: 1.2,
                            ),
                          ),
                        ),
                        if (widget.notebook.author_name != null && widget.notebook.author_name!.isNotEmpty) ...[
                          const SizedBox(height: 6),
                          Text(
                            'Por: ${widget.notebook.author_name}',
                            style: GoogleFonts.inter(fontSize: 11, color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w500),
                          ),
                        ]
                      ],
                    ),

                    // --- RODAPÉ: METADADOS ESPECIFICAÇÕES ---
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        // Estilo e Tamanho (Ex: A4 • Pautado)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                widget.notebook.lineType == 'grid'
                                    ? Icons.grid_4x4_rounded
                                    : widget.notebook.lineType == 'blank'
                                    ? Icons.check_box_outline_blank_rounded
                                    : Icons.view_headline_rounded,
                                size: 12,
                                color: Colors.white,
                              ),
                              const SizedBox(width: 4),
                              Text(
                                '${widget.notebook.paperSize}',
                                style: GoogleFonts.inter(fontSize: 10.5, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // =========================================================
              // 3. 🛡️ BADGES DE ESTADO (NUVEM, PARTILHA E LOJA)
              // =========================================================

              // A) Selo de "Não Sincronizado" ou "Partilhado" (Canto Superior Direito)
              Positioned(
                top: 8,
                right: 32, // Afastado para não colidir com o botão de 3 pontos da UI
                child: Row(
                  children: [
                    if (isUnsynced)
                      _buildBadge(
                        icon: Icons.cloud_upload_rounded,
                        color: Colors.amber.shade700,
                        tooltip: 'Aguardando Sincronização',
                      ),
                    if (isShared) ...[
                      const SizedBox(width: 4),
                      _buildBadge(
                        icon: Icons.folder_shared_rounded,
                        color: Colors.blueAccent,
                        tooltip: 'Caderno Partilhado (${widget.notebook.role.toUpperCase()})',
                      ),
                    ],
                  ],
                ),
              ),

              // B) Selo de MARKETPLACE / PRO (Canto Inferior Direito)
              if (isPublished)
                Positioned(
                  bottom: 12,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFFFD700), Color(0xFFFFA500)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      boxShadow: [
                        BoxShadow(color: Colors.black.withOpacity(0.3), blurRadius: 4, offset: const Offset(0, 2))
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.stars_rounded, size: 12, color: Colors.black87),
                        const SizedBox(width: 3),
                        Text(
                          widget.notebook.price > 0 ? '${widget.notebook.price.toStringAsFixed(2)} Kz' : 'GRÁTIS',
                          style: GoogleFonts.inter(fontSize: 9.5, fontWeight: FontWeight.w900, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Helper para criar badges circulares elegantes
  Widget _buildBadge({required IconData icon, required Color color, required String tooltip}) {
    return Tooltip(
      message: tooltip,
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 3)],
        ),
        child: Icon(icon, size: 12, color: Colors.white),
      ),
    );
  }
}