import 'package:flutter/material.dart';
import '../controllers/canvas_controller.dart';
import '../models/local_page_model.dart';

class CanvasToolbar extends StatelessWidget {
  final CanvasController controller;
  final LocalPage currentPage;
  final VoidCallback onColorTap;
  final VoidCallback onThicknessTap;
  final VoidCallback onChangePaperTap;
  final VoidCallback onDeletePageTap;
  final VoidCallback onAiAssistantTap;

  const CanvasToolbar({
    super.key,
    required this.controller,
    required this.currentPage,
    required this.onColorTap,
    required this.onThicknessTap,
    required this.onChangePaperTap,
    required this.onDeletePageTap,
    required this.onAiAssistantTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    final bool hasImages = currentPage.imageBlocks.isNotEmpty;
    final bool isEraserActive = controller.currentTool == ToolMode.eraser;
    final bool isSelectActive = controller.currentTool == ToolMode.select;

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
        spacing: 6, runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center, alignment: WrapAlignment.center,
        children: [
          _buildToolButton(Icons.brush, ToolMode.draw, 'Caneta'),
          if (!isSmallScreen || isEraserActive) _buildToolButton(Icons.backspace_outlined, ToolMode.eraser, 'Borracha'),
          _buildToolButton(Icons.pan_tool, ToolMode.pan, 'Mover Folha'),
          _buildToolButton(Icons.text_fields, ToolMode.text, 'Texto'),
          if (!isSmallScreen || isSelectActive) _buildToolButton(Icons.highlight_alt, ToolMode.select, 'Selecionar Tinta'),
          
          _buildCompactIconButton(Icons.psychology_outlined, onAiAssistantTap, 'Assistente IA', const Color(0xFF0F4C5C)),

          if (!isSmallScreen)
            _buildCompactIconButton(Icons.add_photo_alternate_outlined, () => controller.pickAndInsertImage(currentPage), 'Adicionar Imagem', const Color(0xFF1A1A24)),
          if (hasImages)
            _buildToolButton(Icons.transform, ToolMode.imageEdit, 'Editar Imagem'),

          if (isSmallScreen) ...[
            _buildCompactIconButton(Icons.undo, currentPage.strokes.isNotEmpty ? () => controller.undo(currentPage) : null, 'Desfazer', currentPage.strokes.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.3)),
            _buildCompactIconButton(Icons.redo, currentPage.redoHistory.isNotEmpty ? () => controller.redo(currentPage) : null, 'Avançar', currentPage.redoHistory.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.3)),
          ],

          if (isSmallScreen)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A24)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFFFDFBF7),
              onSelected: (val) {
                if (val == 'insert_image') controller.pickAndInsertImage(currentPage);
                if (val == 'eraser') controller.switchTool(ToolMode.eraser);
                if (val == 'select') controller.switchTool(ToolMode.select);
                if (val == 'ai_assistant') onAiAssistantTap();
                if (val == 'zoom_in') controller.zoom(1.2, MediaQuery.of(context).size);
                if (val == 'zoom_out') controller.zoom(0.8, MediaQuery.of(context).size);
                if (val == 'delete_page') onDeletePageTap();
                if (val == 'change_paper') onChangePaperTap();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'insert_image', child: Row(children: [Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF0F4C5C)), SizedBox(width: 12), Text('Inserir Imagem')])),
                const PopupMenuItem(value: 'ai_assistant', child: Row(children: [Icon(Icons.psychology_outlined, color: Color(0xFF0F4C5C)), SizedBox(width: 12), Text('Assistente IA')])),
                const PopupMenuItem(value: 'eraser', child: Row(children: [Icon(Icons.backspace_outlined, color: Color(0xFF1A1A24)), SizedBox(width: 12), Text('Borracha')])),
                const PopupMenuItem(value: 'select', child: Row(children: [Icon(Icons.highlight_alt, color: Color(0xFF1A1A24)), SizedBox(width: 12), Text('Selecionar Tinta')])),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'zoom_in', child: Row(children: [Icon(Icons.zoom_in, color: Color(0xFF1A1A24)), SizedBox(width: 12), Text('Aproximar (+)')])),
                const PopupMenuItem(value: 'zoom_out', child: Row(children: [Icon(Icons.zoom_out, color: Color(0xFF1A1A24)), SizedBox(width: 12), Text('Afastar (-)')])),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'change_paper', child: Row(children: [Icon(Icons.grid_on, color: Color(0xFF0F4C5C)), SizedBox(width: 12), Text('Mudar Pauta')])),
                const PopupMenuItem(value: 'delete_page', child: Row(children: [Icon(Icons.delete_forever, color: Colors.redAccent), SizedBox(width: 12), Text('Rasgar Folha', style: TextStyle(color: Colors.redAccent))])),
              ],
            )
          else ...[
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildCompactIconButton(Icons.grid_on, onChangePaperTap, 'Mudar Pauta', const Color(0xFF0F4C5C)),
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildCompactIconButton(Icons.zoom_out, () => controller.zoom(0.8, MediaQuery.of(context).size), 'Afastar', const Color(0xFF1A1A24)),
            _buildCompactIconButton(Icons.zoom_in, () => controller.zoom(1.2, MediaQuery.of(context).size), 'Aproximar', const Color(0xFF1A1A24)),
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildCompactIconButton(Icons.undo, currentPage.strokes.isNotEmpty ? () => controller.undo(currentPage) : null, 'Desfazer', currentPage.strokes.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.5)),
            _buildCompactIconButton(Icons.redo, currentPage.redoHistory.isNotEmpty ? () => controller.redo(currentPage) : null, 'Avançar', currentPage.redoHistory.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.5)),
            _buildCompactIconButton(Icons.delete_forever, onDeletePageTap, 'Rasgar Folha', Colors.redAccent),
          ],

          if (controller.currentTool == ToolMode.draw) ...[
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            InkWell(onTap: onColorTap, customBorder: const CircleBorder(), child: Container(width: 36, height: 36, alignment: Alignment.center, child: CircleAvatar(radius: 11, backgroundColor: Color(int.parse(controller.selectedColorHex.replaceFirst('#', '0xFF')))))),
            InkWell(onTap: onThicknessTap, customBorder: const CircleBorder(), child: Container(width: 36, height: 36, alignment: Alignment.center, child: CircleAvatar(radius: 11, backgroundColor: Colors.black12, child: CircleAvatar(radius: (controller.selectedThickness / 1.5).clamp(2.0, 9.0), backgroundColor: const Color(0xFF1A1A24))))),
          ],
        ],
      ),
    );
  }

  // 🚀 ESTE É O MÉTODO QUE O TEU EDITOR ESTAVA A RECLAMAR! (Tem exatamente 3 parâmetros)
  Widget _buildToolButton(IconData icon, ToolMode mode, String tooltip) {
    final bool isActive = controller.currentTool == mode;
    return Container(
      decoration: BoxDecoration(color: isActive ? const Color(0xFF0F4C5C).withOpacity(0.15) : Colors.transparent, shape: BoxShape.circle),
      child: IconButton(iconSize: 20, constraints: const BoxConstraints(minWidth: 36, minHeight: 36), padding: EdgeInsets.zero, icon: Icon(icon, color: isActive ? const Color(0xFF0F4C5C) : const Color(0xFF1A1A24)), onPressed: () => controller.switchTool(mode), tooltip: tooltip),
    );
  }

  Widget _buildCompactIconButton(IconData icon, VoidCallback? onPressed, String tooltip, Color color) {
    return IconButton(iconSize: 20, constraints: const BoxConstraints(minWidth: 36, minHeight: 36), padding: EdgeInsets.zero, icon: Icon(icon, color: color), onPressed: onPressed, tooltip: tooltip);
  }
}