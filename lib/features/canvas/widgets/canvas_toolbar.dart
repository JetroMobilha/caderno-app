import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/canvas_controller.dart';

class CanvasToolbar extends StatelessWidget {
  final CanvasController controller;

  const CanvasToolbar({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          _buildToolButton(Icons.brush, ToolMode.draw, 'Caneta'),

          if (!isSmallScreen || controller.currentTool == ToolMode.eraser)
            _buildToolButton(Icons.backspace_outlined, ToolMode.eraser, 'Borracha'),

          _buildToolButton(Icons.pan_tool, ToolMode.pan, 'Mover Folha'),
          _buildToolButton(Icons.text_fields, ToolMode.text, 'Texto'),

          if (!isSmallScreen || controller.currentTool == ToolMode.select)
            _buildToolButton(Icons.highlight_alt, ToolMode.select, 'Selecionar Tinta'),

          if (controller.currentTool == ToolMode.draw) ...[
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            // O botão de cor usa a variável do controller
            InkWell(
              onTap: () {
                // Aqui chamarias a lógica de abrir o Modal de Cores (podes passar um callback)
              },
              customBorder: const CircleBorder(),
              child: Container(
                width: 36, height: 36, alignment: Alignment.center,
                child: CircleAvatar(
                    radius: 11,
                    backgroundColor: Color(int.parse(controller.selectedColorHex.replaceFirst('#', '0xFF')))
                ),
              ),
            ),
          ],

          if (isSmallScreen)
            IconButton(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A24)),
              onPressed: () {
                // Menu Mobile: Desfazer, Inserir Imagem, Mudar Pauta...
              },
            )
          else ...[
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            IconButton(
              icon: const Icon(Icons.undo),
              onPressed: () { /* Lógica de Undo no Controller */ },
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, ToolMode mode, String tooltip) {
    final bool isActive = controller.currentTool == mode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0F4C5C).withOpacity(0.15) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        iconSize: 20,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        icon: Icon(icon, color: isActive ? const Color(0xFF0F4C5C) : const Color(0xFF1A1A24)),
        onPressed: () => controller.switchTool(mode),
        tooltip: tooltip,
      ),
    );
  }
}