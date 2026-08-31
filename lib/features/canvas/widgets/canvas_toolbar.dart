import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_viewport_provider.dart';
import '../models/local_page_model.dart';
import '../models/canvas_enums.dart';
import '../../explanations/controllers/explanation_controller.dart'; // 🚀 Novo
import '../../explanations/models/explanation_model.dart'; // 🚀 Novo

class CanvasToolbar extends ConsumerWidget {
  final LocalPage currentPage;
  final VoidCallback onColorTap;
  final VoidCallback onThicknessTap;
  final VoidCallback onChangePaperTap;
  final VoidCallback onDeletePageTap;
  final VoidCallback onAiAssistantTap;
  final VoidCallback? onAddImageTap; 
  final VoidCallback? onRecordingsTap;

  const CanvasToolbar({
    super.key,
    required this.currentPage,
    required this.onColorTap,
    required this.onThicknessTap,
    required this.onChangePaperTap,
    required this.onDeletePageTap,
    required this.onAiAssistantTap,
    this.onAddImageTap,
    this.onRecordingsTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolState = ref.watch(canvasToolProvider);
    final toolNotifier = ref.read(canvasToolProvider.notifier);
    final docState = ref.watch(canvasDocumentProvider);
    final docNotifier = ref.read(canvasDocumentProvider.notifier);
    final viewportNotifier = ref.read(canvasViewportProvider.notifier);

    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    final bool isProfessor = docState.currentUserRole == 'owner';
    final bool isEditor = docState.currentUserRole == 'editor';
    final bool hideDrawingTools = !(isProfessor || isEditor) || docState.currentUserRole == 'viewer';

    if (hideDrawingTools) {
      return _buildCompactToolbar(context, docState);
    }

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
          _buildToolButton(toolNotifier, Icons.brush, ToolMode.draw, 'Caneta', toolState.currentTool),
          _buildToolButton(toolNotifier, Icons.auto_fix_high, ToolMode.eraser, 'Apagar Objeto', toolState.currentTool),
          _buildToolButton(toolNotifier, Icons.cleaning_services_rounded, ToolMode.pixelEraser, 'Borracha de Precisão', toolState.currentTool), // 🚀
          _buildToolButton(toolNotifier, Icons.text_fields, ToolMode.text, 'Texto', toolState.currentTool),
          _buildToolButton(toolNotifier, Icons.highlight_alt, ToolMode.select, 'Selecionar (Rect)', toolState.currentTool),
          _buildToolButton(toolNotifier, Icons.gesture_rounded, ToolMode.lasso, 'Laço de Seleção', toolState.currentTool), // 🚀

          _buildCompactIconButton(Icons.style_rounded, () => Scaffold.of(context).openEndDrawer(), 'Ver Páginas', const Color(0xFF0F4C5C)),

          if (toolState.selectedStrokeIds.isNotEmpty || toolState.selectedTextIds.isNotEmpty || toolState.selectedImageIds.isNotEmpty) ...[
            _buildCompactIconButton(
              toolState.isTransformMode ? Icons.check_circle_rounded : Icons.open_with_rounded, 
              () => toolNotifier.toggleTransformMode(), 
              toolState.isTransformMode ? 'Concluir' : 'Redimensionar Seleção', 
              toolState.isTransformMode ? Colors.green : const Color(0xFFE67E22)
            ),
            // 🚀 Botão para mudar cor da seleção em lote
            InkWell(
              onTap: onColorTap,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(border: Border.all(color: Colors.black12), borderRadius: BorderRadius.circular(8)),
                child: const Icon(Icons.palette_outlined, size: 18, color: Colors.blueAccent),
              ),
            ),
          ],

          if (!isSmallScreen) _buildToolButton(toolNotifier, Icons.pan_tool, ToolMode.pan, 'Mover Folha', toolState.currentTool),
          
          if (!isSmallScreen)
            _buildCompactIconButton(Icons.psychology_outlined, onAiAssistantTap, 'Assistente IA', const Color(0xFF0F4C5C)),

          if (!isSmallScreen)
            _buildCompactIconButton(
              Icons.settings_suggest_rounded, 
              () {
                // Adicionar uma Engrenagem de exemplo
                ref.read(explanationProvider.notifier).addExplanation(
                  EngineeringExplanation(
                    position: const Offset(450, 200),
                    radius: 50.0,
                    toothCount: 18,
                    angularVelocity: 0.5,
                  ),
                );
              }, 
              'Adicionar Engrenagem', 
              Colors.blueGrey
            ),

          if (!isSmallScreen)
            _buildCompactIconButton(Icons.add_photo_alternate_outlined, onAddImageTap, 'Adicionar Imagem', const Color(0xFF1A1A24)),
          
          if (isSmallScreen) ...[
            _buildCompactIconButton(Icons.undo, docState.undoStack.isNotEmpty ? () => docNotifier.undo(currentPage) : null, 'Desfazer', docState.undoStack.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.3)),
            _buildCompactIconButton(Icons.redo, docState.redoStack.isNotEmpty ? () => docNotifier.redo(currentPage) : null, 'Avançar', docState.redoStack.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.3)),
          ],

          if (isSmallScreen)
            _buildMoreMenu(context, ref, toolNotifier, viewportNotifier, onAddImageTap)
          else ...[
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildCompactIconButton(Icons.grid_on, onChangePaperTap, 'Mudar Pauta', const Color(0xFF0F4C5C)),
            _buildCompactIconButton(Icons.zoom_out, () => viewportNotifier.zoom(0.8), 'Afastar', const Color(0xFF1A1A24)),
            _buildCompactIconButton(Icons.zoom_in, () => viewportNotifier.zoom(1.2), 'Aproximar', const Color(0xFF1A1A24)),
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildCompactIconButton(Icons.undo, docState.undoStack.isNotEmpty ? () => docNotifier.undo(currentPage) : null, 'Desfazer', docState.undoStack.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.5)),
            _buildCompactIconButton(Icons.redo, docState.redoStack.isNotEmpty ? () => docNotifier.redo(currentPage) : null, 'Avançar', docState.redoStack.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.5)),
            _buildCompactIconButton(Icons.delete_forever, onDeletePageTap, 'Rasgar Folha', Colors.redAccent),
          ],

          if (toolState.currentTool == ToolMode.draw) ...[
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            InkWell(
              onTap: onColorTap, 
              customBorder: const CircleBorder(), 
              child: Container(
                width: 36, height: 36, 
                alignment: Alignment.center, 
                child: CircleAvatar(
                  radius: 11, 
                  backgroundColor: Color(int.parse(toolState.selectedColorHex.replaceFirst('#', '0xFF'))).withOpacity(toolState.isHighlighter ? 0.4 : 1.0)
                )
              )
            ),
            InkWell(
              onTap: onThicknessTap, 
              customBorder: const CircleBorder(), 
              child: Container(
                width: 36, height: 36, 
                alignment: Alignment.center, 
                child: CircleAvatar(
                  radius: 11, 
                  backgroundColor: Colors.black12, 
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(radius: (toolState.selectedThickness / 1.5).clamp(2.0, 9.0), backgroundColor: const Color(0xFF1A1A24).withOpacity(toolState.isHighlighter ? 0.4 : 1.0)),
                      if (toolState.isHighlighter) Icon(Icons.highlight, size: 10, color: Colors.white.withOpacity(0.8)),
                    ],
                  )
                )
              )
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactToolbar(BuildContext context, CanvasDocumentState docState) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8))],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(docState.currentUserRole == 'viewer' ? Icons.visibility_outlined : Icons.lock_person_rounded, color: Colors.blueGrey, size: 20),
          const SizedBox(width: 12),
          Text(docState.currentUserRole == 'viewer' ? 'Modo Leitura' : 'Sessão Bloqueada', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87)),
        ],
      ),
    );
  }

  Widget _buildToolButton(CanvasToolNotifier notifier, IconData icon, ToolMode mode, String tooltip, ToolMode currentTool) {
    final bool isActive = currentTool == mode;
    return Container(
      decoration: BoxDecoration(color: isActive ? const Color(0xFF0F4C5C).withOpacity(0.15) : Colors.transparent, shape: BoxShape.circle),
      child: IconButton(iconSize: 20, constraints: const BoxConstraints(minWidth: 36, minHeight: 36), padding: EdgeInsets.zero, icon: Icon(icon, color: isActive ? const Color(0xFF0F4C5C) : const Color(0xFF1A1A24)), onPressed: () => notifier.switchTool(mode), tooltip: tooltip),
    );
  }

  Widget _buildCompactIconButton(IconData icon, VoidCallback? onPressed, String tooltip, Color color) {
    return IconButton(iconSize: 20, constraints: const BoxConstraints(minWidth: 36, minHeight: 36), padding: EdgeInsets.zero, icon: Icon(icon, color: color), onPressed: onPressed, tooltip: tooltip);
  }

  Widget _buildMoreMenu(BuildContext context, WidgetRef ref, CanvasToolNotifier toolNotifier, CanvasViewportNotifier viewportNotifier, VoidCallback? onAddImage) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A24)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) {
        if (val == 'zoom_in') viewportNotifier.zoom(1.2);
        if (val == 'zoom_out') viewportNotifier.zoom(0.8);
        if (val == 'add_image') onAddImage?.call();
        if (val == 'clear_explanations') ref.read(explanationProvider.notifier).clearPage();
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'zoom_in', child: Text('Aproximar (+)')),
        const PopupMenuItem(value: 'zoom_out', child: Text('Afastar (-)')),
        const PopupMenuItem(value: 'add_image', child: Text('Adicionar Imagem')),
        const PopupMenuItem(value: 'clear_explanations', child: Text('Limpar Animações')),
      ],
    );
  }
}
