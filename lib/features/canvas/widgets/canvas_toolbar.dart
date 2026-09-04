import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../models/animation_object_model.dart';
import '../models/attachment_model.dart';
import '../models/link_model.dart';
import '../models/shape_model.dart';
import '../models/table_model.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_viewport_provider.dart';
import '../models/local_page_model.dart';
import '../models/canvas_enums.dart';
import 'canvas_zoom_control.dart';
import 'dialogs/layer_manager_sheet.dart'; 
import 'dialogs/page_action_helper.dart'; 
import '../../explanations/controllers/explanation_controller.dart'; 
import '../../explanations/models/explanation_model.dart';

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
          BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Wrap(
        spacing: 6, runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center, alignment: WrapAlignment.center,
        children: [
          _buildToolButton(toolNotifier, Icons.brush, ToolMode.draw, 'Caneta', toolState.currentTool),
          _buildToolButton(toolNotifier, Icons.auto_fix_high, ToolMode.eraser, 'Apagar Objeto', toolState.currentTool),
          _buildToolButton(toolNotifier, Icons.cleaning_services_rounded, ToolMode.pixelEraser, 'Borracha de Precisão', toolState.currentTool),
          _buildToolButton(toolNotifier, Icons.text_fields, ToolMode.text, 'Texto', toolState.currentTool),
          _buildToolButton(toolNotifier, Icons.highlight_alt, ToolMode.select, 'Selecionar (Rect)', toolState.currentTool),
          _buildToolButton(toolNotifier, Icons.gesture_rounded, ToolMode.lasso, 'Laço de Seleção', toolState.currentTool),

          if (toolState.selectedStrokeIds.isNotEmpty || toolState.selectedTextIds.isNotEmpty || toolState.selectedImageIds.isNotEmpty) ...[
            _buildCompactIconButton(
              toolState.isTransformMode ? Icons.check_circle_rounded : Icons.open_with_rounded, 
              () => toolNotifier.toggleTransformMode(), 
              toolState.isTransformMode ? 'Concluir' : 'Redimensionar Seleção', 
              toolState.isTransformMode ? Colors.green : const Color(0xFFE67E22)
            ),
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

          _buildCompactIconButton(Icons.layers_outlined, () => _showLayerManager(context, currentPage), 'Camadas', const Color(0xFF0F4C5C)),

          _buildShapeMenu(context, ref, currentPage),
          _buildAnimationMenu(context, ref, currentPage),
          _buildInsertionMenu(context, ref, currentPage), // 🚀 NOVO

          if (!isSmallScreen) _buildToolButton(toolNotifier, Icons.pan_tool, ToolMode.pan, 'Mover Folha', toolState.currentTool),
          
          if (!isSmallScreen)
            _buildCompactIconButton(Icons.psychology_outlined, onAiAssistantTap, 'Assistente IA', const Color(0xFF0F4C5C)),

          if (!isSmallScreen)
            _buildCompactIconButton(
              Icons.settings_suggest_rounded, 
              () {
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
            _buildCompactIconButton(Icons.undo, docState.undoStack.isNotEmpty ? () => docNotifier.undo(currentPage) : null, 'Desfazer', docState.undoStack.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withValues(alpha: 0.3)),
            _buildCompactIconButton(Icons.redo, docState.redoStack.isNotEmpty ? () => docNotifier.redo(currentPage) : null, 'Avançar', docState.redoStack.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withValues(alpha: 0.3)),
          ],

          if (isSmallScreen)
            _buildMoreMenu(context, ref, toolNotifier, viewportNotifier, onAddImageTap, currentPage)
          else ...[
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildCompactIconButton(Icons.grid_on, onChangePaperTap, 'Mudar Pauta', const Color(0xFF0F4C5C)),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: CanvasZoomControl(currentPage: currentPage),
            ),

            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildCompactIconButton(Icons.undo, docState.undoStack.isNotEmpty ? () => docNotifier.undo(currentPage) : null, 'Desfazer', docState.undoStack.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withValues(alpha: 0.5)),
            _buildCompactIconButton(Icons.redo, docState.redoStack.isNotEmpty ? () => docNotifier.redo(currentPage) : null, 'Avançar', docState.redoStack.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withValues(alpha: 0.5)),
            
            _buildPagePopupMenu(context, ref, currentPage),
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
                  backgroundColor: Color(int.parse(toolState.selectedColorHex.replaceFirst('#', '0xFF'))).withValues(alpha: toolState.isHighlighter ? 0.4 : 1.0)
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
                  backgroundColor: Colors.black.withValues(alpha: 0.12), 
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircleAvatar(radius: (toolState.selectedThickness / 1.5).clamp(2.0, 9.0), backgroundColor: const Color(0xFF1A1A24).withValues(alpha: toolState.isHighlighter ? 0.4 : 1.0)),
                      if (toolState.isHighlighter) Icon(Icons.highlight, size: 10, color: Colors.white.withValues(alpha: 0.8)),
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



  Widget _buildShapeMenu(BuildContext context, WidgetRef ref, LocalPage page) {
    return PopupMenuButton<ShapeType>(
      icon: const Icon(Icons.category_outlined, color: Color(0xFF0F4C5C)),
      tooltip: 'Inserir Forma',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (type) {
        final shape = ShapeObject(
          id: const Uuid().v4(),
          shapeType: type,
          position: const Offset(100, 100),
          size: const Size(150, 100),
          strokeColor: '#0F4C5C',
          zIndex: page.objects.length,
        );
        ref.read(canvasDocumentProvider.notifier).addShape(page, shape);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: ShapeType.rectangle, child: Row(children: [Icon(Icons.rectangle_outlined), SizedBox(width: 8), Text('Retângulo')])),
        const PopupMenuItem(value: ShapeType.circle, child: Row(children: [Icon(Icons.circle_outlined), SizedBox(width: 8), Text('Círculo')])),
        const PopupMenuItem(value: ShapeType.triangle, child: Row(children: [Icon(Icons.change_history_rounded), SizedBox(width: 8), Text('Triângulo')])),
        const PopupMenuItem(value: ShapeType.line, child: Row(children: [Icon(Icons.horizontal_rule_rounded), SizedBox(width: 8), Text('Linha')])),
        const PopupMenuItem(value: ShapeType.arrow, child: Row(children: [Icon(Icons.arrow_right_alt_rounded), SizedBox(width: 8), Text('Seta')])),
      ],
    );
  }

  Widget _buildAnimationMenu(BuildContext context, WidgetRef ref, LocalPage page) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.animation_rounded, color: Color(0xFFE36414)),
      tooltip: 'Inserir Animação',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (type) {
        final anim = AnimationObject(
          id: const Uuid().v4(),
          animationType: AnimationObjectType.physics,
          position: const Offset(200, 200),
          size: const Size(120, 120),
          configData: type == 'gear' 
              ? {'type': 'engineeringMechanism', 'is_gear': true, 'tooth_count': 18, 'radius': 50.0}
              : {'type': 'physicsBody', 'mass': 1.0},
          zIndex: page.objects.length,
        );
        ref.read(canvasDocumentProvider.notifier).addAnimation(page, anim);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'gear', child: Row(children: [Icon(Icons.settings_suggest_outlined), SizedBox(width: 8), Text('Engrenagem')])),
        const PopupMenuItem(value: 'physics', child: Row(children: [Icon(Icons.waves_rounded), SizedBox(width: 8), Text('Corpo de Física')])),
      ],
    );
  }

  Widget _buildInsertionMenu(BuildContext context, WidgetRef ref, LocalPage page) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0F4C5C)),
      tooltip: 'Mais Opções',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) {
        if (val == 'table') _handleInsertTable(context, ref, page);
        else if (val == 'link') _handleInsertLink(context, ref, page);
        else if (val == 'attach') _handleInsertAttachment(context, ref, page);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'table', child: Row(children: [Icon(Icons.table_chart_outlined), SizedBox(width: 8), Text('Tabela')])),
        const PopupMenuItem(value: 'link', child: Row(children: [Icon(Icons.link_rounded), SizedBox(width: 8), Text('Link Interativo')])),
        const PopupMenuItem(value: 'attach', child: Row(children: [Icon(Icons.attach_file_rounded), SizedBox(width: 8), Text('Anexar Ficheiro')])),
      ],
    );
  }

  void _handleInsertTable(BuildContext context, WidgetRef ref, LocalPage page) {
    final table = TableObject(
      id: const Uuid().v4(),
      position: const Offset(150, 150),
      rows: 3, cols: 3,
      zIndex: page.objects.length,
    );
    ref.read(canvasDocumentProvider.notifier).addTable(page, table);
  }

  void _handleInsertLink(BuildContext context, WidgetRef ref, LocalPage page) {
    final link = LinkObject(
      id: const Uuid().v4(),
      linkType: LinkType.externalUrl,
      url: 'https://google.com',
      label: 'Google',
      position: const Offset(200, 200),
      zIndex: page.objects.length,
    );
    ref.read(canvasDocumentProvider.notifier).addLink(page, link);
  }

  void _handleInsertAttachment(BuildContext context, WidgetRef ref, LocalPage page) {
    final attach = AttachmentObject(
      id: const Uuid().v4(),
      fileName: 'documento_exemplo.pdf',
      fileExtension: 'pdf',
      localPath: '/tmp/test.pdf',
      position: const Offset(100, 300),
      zIndex: page.objects.length,
    );
    ref.read(canvasDocumentProvider.notifier).addAttachment(page, attach);
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
      decoration: BoxDecoration(color: isActive ? const Color(0xFF0F4C5C).withValues(alpha: 0.15) : Colors.transparent, shape: BoxShape.circle),
      child: IconButton(iconSize: 20, constraints: const BoxConstraints(minWidth: 36, minHeight: 36), padding: EdgeInsets.zero, icon: Icon(icon, color: isActive ? const Color(0xFF0F4C5C) : const Color(0xFF1A1A24)), onPressed: () => notifier.switchTool(mode), tooltip: tooltip),
    );
  }

  Widget _buildCompactIconButton(IconData icon, VoidCallback? onPressed, String tooltip, Color color) {
    return IconButton(iconSize: 20, constraints: const BoxConstraints(minWidth: 36, minHeight: 36), padding: EdgeInsets.zero, icon: Icon(icon, color: color), onPressed: onPressed, tooltip: tooltip);
  }

  void _showLayerManager(BuildContext context, LocalPage page) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => LayerManagerSheet(page: page),
    );
  }

  Widget _buildPagePopupMenu(BuildContext context, WidgetRef ref, LocalPage page) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.description_outlined, color: Color(0xFF0F4C5C)),
      tooltip: 'Ações da Página',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) => _handlePageAction(context, ref, page, val),
      itemBuilder: (context) => [
        _buildPopupItem('rename', Icons.edit_outlined, 'Renomear'),
        _buildPopupItem('settings', Icons.settings_outlined, 'Configurar'),
        _buildPopupItem('section', Icons.folder_outlined, 'Mover para Secção'),
        if (page.sectionTitle != null)
          _buildPopupItem('remove_section', Icons.folder_off_outlined, 'Remover Secção'),
        const PopupMenuDivider(),
        _buildPopupItem('favorite', page.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded, page.isFavorite ? 'Remover Favorito' : 'Marcar Favorito'),
        _buildPopupItem('duplicate', Icons.copy_rounded, 'Duplicar Página'),
        const PopupMenuDivider(),
        _buildPopupItem('move_to', Icons.drive_file_move_outlined, 'Mover para caderno'),
        _buildPopupItem('copy_to', Icons.content_copy_rounded, 'Copiar para caderno'),
        const PopupMenuDivider(),
        _buildPopupItem('delete', Icons.delete_outline_rounded, 'Rasgar Folha (Apagar)', isDestructive: true),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String label, {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      height: 38,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDestructive ? Colors.redAccent : Colors.black54),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, color: isDestructive ? Colors.redAccent : Colors.black87)),
        ],
      ),
    );
  }

  void _handlePageAction(BuildContext context, WidgetRef ref, LocalPage page, String action) {
    switch (action) {
      case 'rename': PageActionHelper.showRenameDialog(context, ref, page); break;
      case 'settings': PageActionHelper.showSettingsDialog(context, ref, page); break;
      case 'section': PageActionHelper.showSectionDialog(context, ref, page); break;
      case 'remove_section': ref.read(canvasDocumentProvider.notifier).updatePageSection(page, null); break;
      case 'favorite': ref.read(canvasDocumentProvider.notifier).toggleFavorite(page); break;
      case 'duplicate': ref.read(canvasDocumentProvider.notifier).duplicatePage(page); break;
      case 'move_to': PageActionHelper.handleMovePage(context, ref, page); break;
      case 'copy_to': PageActionHelper.handleCopyPage(context, ref, page); break;
      case 'delete': PageActionHelper.showConfirmDelete(context, ref, page); break;
    }
  }

  Widget _buildMoreMenu(BuildContext context, WidgetRef ref, CanvasToolNotifier toolNotifier, CanvasViewportNotifier viewportNotifier, VoidCallback? onAddImage, LocalPage page) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A24)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) {
        if (val == 'add_image') onAddImage?.call();
        else if (val == 'clear_explanations') ref.read(explanationProvider.notifier).clearPage();
        else _handlePageAction(context, ref, page, val);
      },
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: CanvasZoomControl(currentPage: page, isCompact: true),
        ),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'add_image', child: Row(children: [Icon(Icons.add_photo_alternate_outlined, size: 18), SizedBox(width: 8), Text('Adicionar Imagem')])),
        const PopupMenuDivider(),
        const PopupMenuItem(value: 'settings', child: Row(children: [Icon(Icons.settings_outlined, size: 18), SizedBox(width: 8), Text('Configurar Página')])),
        const PopupMenuItem(value: 'rename', child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Renomear')])),
        const PopupMenuItem(value: 'delete', child: Row(children: [Icon(Icons.delete_outline_rounded, size: 18, color: Colors.redAccent), SizedBox(width: 8), Text('Rasgar Folha', style: TextStyle(color: Colors.redAccent))])),
      ],
    );
  }
}
