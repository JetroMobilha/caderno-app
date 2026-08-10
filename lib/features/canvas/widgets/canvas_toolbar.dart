import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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

    // 🚀 LÓGICA DE VISIBILIDADE ADAPTATIVA (Sessões Live)
    // Se a sessão estiver bloqueada pelo Dono, outros não podem desenhar.
    final bool isProfessor = controller.currentUserRole == 'owner';
    final bool hideDrawingTools = (controller.isSessionLocked && !isProfessor) || controller.currentUserRole == 'viewer';

    final bool hasImages = currentPage.imageBlocks.isNotEmpty;

    if (hideDrawingTools) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(30),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 15, offset: const Offset(0, 8)),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              controller.currentUserRole == 'viewer' ? Icons.visibility_outlined : Icons.lock_person_rounded, 
              color: controller.currentUserRole == 'viewer' ? Colors.blueGrey : const Color(0xFF27AE60), 
              size: 20
            ),
            const SizedBox(width: 12),
            Text(
              controller.currentUserRole == 'viewer' ? 'Modo Leitura' : 'Sessão Bloqueada pelo Professor',
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87),
            ),
            const SizedBox(width: 16),
            _buildCompactIconButton(Icons.chat_bubble_outline_rounded, () {
               controller.isChatOpen = true;
            }, 'Fazer Pergunta', const Color(0xFF0F4C5C)),
            if (controller.currentUserRole != 'viewer')
              _buildCompactIconButton(
                controller.isMyHandRaised ? Icons.pan_tool : Icons.pan_tool_outlined, 
                () => controller.toggleHandRaise(), 
                'Levantar Mão', 
                controller.isMyHandRaised ? Colors.orange : Colors.grey
              ),
          ],
        ),
      );
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Wrap(
        spacing: 6, runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center, alignment: WrapAlignment.center,
        children: [
          _buildToolButton(Icons.brush, ToolMode.draw, 'Caneta'),
          _buildToolButton(Icons.auto_fix_high, ToolMode.eraser, 'Borracha'),
          _buildToolButton(Icons.text_fields, ToolMode.text, 'Texto'),
          _buildToolButton(Icons.highlight_alt, ToolMode.select, 'Selecionar Tinta'),
          if (!isSmallScreen) _buildToolButton(Icons.pan_tool, ToolMode.pan, 'Mover Folha'),
          
          if (!isSmallScreen)
            _buildCompactIconButton(Icons.psychology_outlined, onAiAssistantTap, 'Assistente IA', const Color(0xFF0F4C5C)),

          if (!isSmallScreen)
            _buildCompactIconButton(Icons.add_photo_alternate_outlined, () => controller.pickAndInsertImage(currentPage), 'Adicionar Imagem', const Color(0xFF1A1A24)),
          
          // 🚀 RECURSOS ADAPTATIVOS POR TEMPLATE
          if (controller.currentTemplateType == 'study') ...[
            _buildCompactIconButton(
              controller.isLessonRecording ? Icons.stop_circle_rounded : Icons.mic_rounded, 
              () {
                if (controller.isLessonRecording) {
                  _showRecordingTitleDialog(context, controller);
                } else {
                  controller.startLessonRecording();
                }
              }, 
              controller.isLessonRecording ? 'Parar Gravação' : 'Gravar Aula', 
              controller.isLessonRecording ? Colors.redAccent : const Color(0xFF0F4C5C)
            ),
            _buildCompactIconButton(
              Icons.auto_awesome_rounded, 
              controller.isAiSummarizing ? null : () => controller.generateAiSummary(currentPage), 
              'Resumo IA', 
              controller.isAiSummarizing ? Colors.grey : Colors.amber.shade700
            ),
          ],

          if (controller.currentTemplateType == 'technical')
            _buildCompactIconButton(
              controller.visibleAuthorIds == null ? Icons.layers_outlined : Icons.layers_clear_outlined, 
              () => controller.visibleAuthorIds == null ? controller.toggleAuthorVisibility(controller.myUserId) : controller.resetAuthorVisibility(), 
              'Filtro de Camadas', 
              Colors.blueGrey
            ),

          if (controller.currentTemplateType == 'formal' && controller.currentUserRole == 'owner')
            _buildCompactIconButton(
              currentPage.isFrozen ? Icons.lock_rounded : Icons.lock_open_rounded, 
              () => controller.togglePageFreeze(currentPage), 
              currentPage.isFrozen ? 'Descongelar Página' : 'Congelar Página', 
              currentPage.isFrozen ? Colors.redAccent : Colors.green
            ),

          if (hasImages)
            _buildToolButton(Icons.transform, ToolMode.imageEdit, 'Editar Imagem'),

          if (isSmallScreen) ...[
            _buildCompactIconButton(Icons.undo, controller.canUndo ? () => controller.undo(currentPage) : null, 'Desfazer', controller.canUndo ? const Color(0xFF1A1A24) : Colors.grey.withValues(alpha: 0.3)),
            _buildCompactIconButton(Icons.redo, controller.canRedo ? () => controller.redo(currentPage) : null, 'Avançar', controller.canRedo ? const Color(0xFF1A1A24) : Colors.grey.withValues(alpha: 0.3)),
          ],

          if (isSmallScreen)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A24)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFFFDFBF7),
              onSelected: (val) {
                if (val == 'insert_image') controller.pickAndInsertImage(currentPage);
                if (val == 'select') controller.switchTool(ToolMode.select);
                if (val == 'ai_assistant') onAiAssistantTap();
                if (val == 'zoom_in') controller.zoom(1.2, MediaQuery.of(context).size);
                if (val == 'zoom_out') controller.zoom(0.8, MediaQuery.of(context).size);
                if (val == 'delete_page') onDeletePageTap();
                if (val == 'change_paper') onChangePaperTap();
                if (val == 'export_text') controller.exportPageText(currentPage, context);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'insert_image', child: Row(children: [Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF0F4C5C)), SizedBox(width: 12), Text('Inserir Imagem')])),
                const PopupMenuItem(value: 'ai_assistant', child: Row(children: [Icon(Icons.psychology_outlined, color: Color(0xFF0F4C5C)), SizedBox(width: 12), Text('Assistente IA')])),
                const PopupMenuItem(value: 'export_text', child: Row(children: [Icon(Icons.copy_all_outlined, color: Color(0xFF0F4C5C)), SizedBox(width: 12), Text('Exportar Todo o Texto')])),
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
            _buildCompactIconButton(
              Icons.copy_all_outlined, 
              (controller.currentTemplateType == 'creative' && controller.currentUserRole == 'viewer') 
                ? () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('A exportação está protegida pelo autor neste modo.')))
                : () => controller.exportPageText(currentPage, context), 
              'Exportar Texto', 
              (controller.currentTemplateType == 'creative' && controller.currentUserRole == 'viewer') ? Colors.grey : const Color(0xFF0F4C5C)
            ),
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildCompactIconButton(Icons.grid_on, onChangePaperTap, 'Mudar Pauta', const Color(0xFF0F4C5C)),
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildCompactIconButton(Icons.zoom_out, () => controller.zoom(0.8, MediaQuery.of(context).size), 'Afastar', const Color(0xFF1A1A24)),
            _buildCompactIconButton(Icons.zoom_in, () => controller.zoom(1.2, MediaQuery.of(context).size), 'Aproximar', const Color(0xFF1A1A24)),
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildCompactIconButton(Icons.undo, controller.canUndo ? () => controller.undo(currentPage) : null, 'Desfazer', controller.canUndo ? const Color(0xFF1A1A24) : Colors.grey.withValues(alpha: 0.5)),
            _buildCompactIconButton(Icons.redo, controller.canRedo ? () => controller.redo(currentPage) : null, 'Avançar', controller.canRedo ? const Color(0xFF1A1A24) : Colors.grey.withValues(alpha: 0.5)),
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
      decoration: BoxDecoration(color: isActive ? const Color(0xFF0F4C5C).withValues(alpha: 0.15) : Colors.transparent, shape: BoxShape.circle),
      child: IconButton(iconSize: 20, constraints: const BoxConstraints(minWidth: 36, minHeight: 36), padding: EdgeInsets.zero, icon: Icon(icon, color: isActive ? const Color(0xFF0F4C5C) : const Color(0xFF1A1A24)), onPressed: () => controller.switchTool(mode), tooltip: tooltip),
    );
  }

  Widget _buildCompactIconButton(IconData icon, VoidCallback? onPressed, String tooltip, Color color) {
    return IconButton(iconSize: 20, constraints: const BoxConstraints(minWidth: 36, minHeight: 36), padding: EdgeInsets.zero, icon: Icon(icon, color: color), onPressed: onPressed, tooltip: tooltip);
  }

  void _showRecordingTitleDialog(BuildContext context, CanvasController controller) {
    final now = DateTime.now();
    final defaultTitle = 'Aula de ${now.day.toString().padLeft(2, '0')}-${now.month.toString().padLeft(2, '0')}-${now.year}';
    final titleController = TextEditingController(text: defaultTitle);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Título da Gravação'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(hintText: 'Ex: Introdução à Anatomia'),
          autofocus: true,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () {
              controller.stopLessonRecording(titleController.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('Guardar'),
          ),
        ],
      ),
    );
  }
}
