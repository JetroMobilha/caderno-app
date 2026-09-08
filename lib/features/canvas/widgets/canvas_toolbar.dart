import 'package:caderno_digital_app/features/shared/widgets/color_engine_widget.dart';
import 'package:flutter/material.dart';
import 'package:caderno_digital_app/features/canvas/widgets/dialogs/table_creation_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import 'package:caderno_digital_app/features/canvas/models/animation_object_model.dart';
import 'package:caderno_digital_app/features/canvas/models/attachment_model.dart';
import 'package:caderno_digital_app/features/canvas/models/link_model.dart';
import 'package:caderno_digital_app/features/canvas/models/shape_model.dart';
import 'package:caderno_digital_app/features/canvas/models/table_model.dart';
import 'package:caderno_digital_app/features/canvas/providers/canvas_tool_provider.dart';
import 'package:caderno_digital_app/features/canvas/providers/canvas_document_provider.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/models/canvas_enums.dart';
import 'package:caderno_digital_app/features/canvas/providers/canvas_ui_provider.dart';
import 'package:caderno_digital_app/features/canvas/widgets/canvas_zoom_control.dart';
import 'package:caderno_digital_app/features/canvas/widgets/dialogs/layer_manager_sheet.dart'; 
import 'package:caderno_digital_app/features/canvas/widgets/dialogs/page_action_helper.dart'; 
import 'package:caderno_digital_app/features/canvas/widgets/dialogs/brush_style_sheet.dart';
import 'package:caderno_digital_app/features/canvas/widgets/dialogs/object_explorer_sheet.dart';
import 'package:caderno_digital_app/features/canvas/models/table_cell_model.dart';
import 'package:caderno_digital_app/features/canvas/widgets/toolbars/text_edit_toolbar.dart';
import 'package:caderno_digital_app/features/canvas/widgets/toolbars/table_edit_toolbar.dart';

/// Barra de ferramentas principal do canvas.
/// Gere a alternância entre ferramentas (Caneta, Texto, Tabela) e 
/// exibe barras contextuais ricas dependendo do que está selecionado.
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
    final uiState = ref.watch(canvasUiProvider);

    final bool isWritingTextBlock = toolState.activeTextBlock != null;
    final bool isEditingCell = toolState.activeTableCell != null;
    final bool isTextToolActive = toolState.currentTool == ToolMode.text; 
    final bool hasMultipleCellsSelected = toolState.selectedTableCells.length > 1; // 🚀 v6.4

    // 🚀 v5.6: Só mostrar barra de design se houver uma tabela selecionada/ativa
    final bool hasTableSelected = toolState.selectedTableIds.isNotEmpty || toolState.activeTableId != null;
    // 🚀 v6.2: Persistência no modo Seleção para redimensionamento
    final bool isTableDesignMode = (toolState.currentTool == ToolMode.table || toolState.currentTool == ToolMode.select) && hasTableSelected;

    // Prioridade 1: Múltiplas Células Selecionadas -> Barra de Tabela (Estrutura/Estilos em Massa)
    if (hasMultipleCellsSelected && hasTableSelected) {
      return TableEditToolbar(currentPage: currentPage, isCellEditing: false);
    }

    // Prioridade 2: Edição de Texto (Blocos ou Célula Única) ou Ferramenta de Texto Ativa
    if (isTextToolActive || isWritingTextBlock || isEditingCell) {
       return TextEditToolbar(
         block: toolState.activeTextBlock, 
         currentPage: currentPage
       );
    }

    if (isTableDesignMode) {
      return TableEditToolbar(currentPage: currentPage, isCellEditing: false);
    }

    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    final bool isProfessor = docState.currentUserRole == 'owner';
    final bool isEditor = docState.currentUserRole == 'editor';
    final bool hideDrawingTools = !(isProfessor || isEditor) || docState.currentUserRole == 'viewer';

    if (hideDrawingTools) {
      return _buildCompactToolbar(context, docState);
    }

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: uiState.isHudMode ? 0.15 : 1.0,
      child: IgnorePointer(
        ignoring: uiState.isHudMode,
        child: Container(
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
              _buildToolButton(
                toolNotifier, 
                Icons.brush, 
                ToolMode.draw, 
                'Caneta', 
                toolState.currentTool,
                onLongPress: () => _showBrushSelector(context),
              ),
              _buildToolButton(
                toolNotifier, 
                toolState.currentTool == ToolMode.pixelEraser ? Icons.cleaning_services_rounded : Icons.auto_fix_high, 
                toolState.currentTool == ToolMode.pixelEraser ? ToolMode.pixelEraser : ToolMode.eraser, 
                toolState.currentTool == ToolMode.pixelEraser ? 'Borracha de Precisão' : 'Apagar Objeto', 
                toolState.currentTool,
                onLongPress: () {
                  if (toolState.currentTool == ToolMode.eraser) {
                    toolNotifier.switchTool(ToolMode.pixelEraser);
                  } else {
                    toolNotifier.switchTool(ToolMode.eraser);
                  }
                },
              ),
              _buildToolButton(
                toolNotifier, 
                Icons.text_fields, 
                ToolMode.text, 
                'Texto', 
                toolState.currentTool,
              ),
              _buildToolButton(
                toolNotifier, 
                Icons.table_chart_rounded, 
                ToolMode.table, 
                'Trabalhar com Tabelas', 
                toolState.currentTool,
              ),
              _buildToolButton(toolNotifier, Icons.highlight_alt, ToolMode.select, 'Selecionar (Rect)', toolState.currentTool),
              _buildToolButton(toolNotifier, Icons.gesture_rounded, ToolMode.lasso, 'Laço de Seleção', toolState.currentTool),
              _buildToolButton(toolNotifier, Icons.account_tree_outlined, ToolMode.organizer, 'Explorador de Objetos', toolState.currentTool, onLongPress: () => _showObjectExplorer(context)),

              if (toolState.selectedStrokeIds.isNotEmpty || 
                  toolState.selectedTextIds.isNotEmpty || 
                  toolState.selectedImageIds.isNotEmpty ||
                  toolState.selectedShapeIds.isNotEmpty || 
                  toolState.selectedAudioIds.isNotEmpty || 
                  toolState.selectedAnimationIds.isNotEmpty ||
                  toolState.selectedTableIds.isNotEmpty || 
                  toolState.selectedLinkIds.isNotEmpty || 
                  toolState.selectedAttachmentIds.isNotEmpty) ...[
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
              
              _buildInsertionMenu(context, ref, currentPage), 

              if (!isSmallScreen) _buildToolButton(toolNotifier, Icons.pan_tool, ToolMode.pan, 'Mover Folha', toolState.currentTool),
              
              if (!isSmallScreen)
                _buildCompactIconButton(Icons.psychology_outlined, onAiAssistantTap, 'Assistente IA', const Color(0xFF0F4C5C)),

              if (isSmallScreen) ...[
                _buildCompactIconButton(Icons.undo, docState.undoStack.isNotEmpty ? () => docNotifier.undo(currentPage) : null, 'Desfazer', docState.undoStack.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.3)),
                _buildCompactIconButton(Icons.redo, docState.redoStack.isNotEmpty ? () => docNotifier.redo(currentPage) : null, 'Avançar', docState.redoStack.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.3)),
              ],

              if (isSmallScreen)
                _buildMoreMenu(context, ref, onAddImageTap, currentPage)
              else ...[
                Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: CanvasZoomControl(currentPage: currentPage),
                ),
                Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
                _buildCompactIconButton(Icons.undo, docState.undoStack.isNotEmpty ? () => docNotifier.undo(currentPage) : null, 'Desfazer', docState.undoStack.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.5)),
                _buildCompactIconButton(Icons.redo, docState.redoStack.isNotEmpty ? () => docNotifier.redo(currentPage) : null, 'Avançar', docState.redoStack.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.5)),
                _buildPagePopupMenu(context, ref, currentPage),
              ],

              if (toolState.currentTool == ToolMode.draw) ...[
                Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
                InkWell(
                  onTap: () async {
                    final hex = await ColorEngine.show(context, initialColor: toolState.selectedColorHex, title: 'Cor da Caneta');
                    if (hex != null) toolNotifier.setColor(hex);
                  }, 
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
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildToolButton(CanvasToolNotifier notifier, IconData icon, ToolMode mode, String tooltip, ToolMode currentTool, {VoidCallback? onLongPress}) {
    final bool isActive = currentTool == mode;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => notifier.switchTool(mode),
        onLongPress: onLongPress,
        customBorder: const CircleBorder(),
        child: Container(
          width: 36, height: 36,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0F4C5C).withOpacity(0.15) : Colors.transparent, 
            shape: BoxShape.circle
          ),
          child: Icon(icon, size: 20, color: isActive ? const Color(0xFF0F4C5C) : const Color(0xFF1A1A24)),
        ),
      ),
    );
  }

  Widget _buildCompactIconButton(IconData icon, VoidCallback? onPressed, String tooltip, Color color) {
    return IconButton(iconSize: 20, constraints: const BoxConstraints(minWidth: 36, minHeight: 36), padding: EdgeInsets.zero, icon: Icon(icon, color: color), onPressed: onPressed, tooltip: tooltip);
  }

  void _showBrushSelector(BuildContext context) {
    showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => const BrushStyleSheet());
  }

  void _showLayerManager(BuildContext context, LocalPage page) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => LayerManagerSheet(page: page));
  }

  void _showObjectExplorer(BuildContext context) {
    showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => ObjectExplorerSheet(pageClientId: currentPage.clientId));
  }

  Widget _buildInsertionMenu(BuildContext context, WidgetRef ref, LocalPage page) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0F4C5C)),
      tooltip: 'Inserir Objetos',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) {
        if (val == 'image') onAddImageTap?.call();
        else if (val.startsWith('shape_')) _handleInsertShape(ref, page, val.replaceFirst('shape_', ''));
        else if (val.startsWith('anim_')) _handleInsertAnimation(ref, page, val.replaceFirst('anim_', ''));
        else if (val == 'table') _handleInsertTable(context, ref, page);
        else if (val == 'link') _handleInsertLink(ref, page);
        else if (val == 'attach') _handleInsertAttachment(ref, page);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(value: 'image', child: Row(children: [Icon(Icons.add_photo_alternate_outlined), SizedBox(width: 8), Text('Imagem (Galeria)')])),
        const PopupMenuDivider(),
        _buildHeaderItem('FORMAS GEOMÉTRICAS'),
        _buildPopupItem('shape_rectangle', Icons.rectangle_outlined, 'Retângulo'),
        _buildPopupItem('shape_circle', Icons.circle_outlined, 'Círculo'),
        _buildPopupItem('shape_triangle', Icons.change_history_rounded, 'Triângulo'),
        _buildPopupItem('shape_line', Icons.horizontal_rule_rounded, 'Linha'),
        _buildPopupItem('shape_arrow', Icons.arrow_right_alt_rounded, 'Seta'),
        const PopupMenuDivider(),
        _buildHeaderItem('ILUSTRAÇÕES TÉCNICAS'),
        _buildPopupItem('anim_gear', Icons.settings_suggest_outlined, 'Engrenagem'),
        _buildPopupItem('anim_physics', Icons.waves_rounded, 'Corpo de Física'),
        const PopupMenuDivider(),
        _buildHeaderItem('ESTRUTURAS'),
        _buildPopupItem('table', Icons.table_chart_outlined, 'Tabela'),
        _buildPopupItem('link', Icons.link_rounded, 'Link Interativo'),
        _buildPopupItem('attach', Icons.attach_file_rounded, 'Anexar Ficheiro'),
      ],
    );
  }

  PopupMenuItem<String> _buildHeaderItem(String title) {
    return PopupMenuItem<String>(enabled: false, child: Text(title, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey)));
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String label, {bool isDestructive = false}) {
    return PopupMenuItem<String>(value: value, child: Row(children: [Icon(icon, size: 18, color: isDestructive ? Colors.redAccent : Colors.black54), const SizedBox(width: 12), Text(label, style: TextStyle(fontSize: 13, color: isDestructive ? Colors.redAccent : Colors.black87))]));
  }

  void _handleInsertShape(WidgetRef ref, LocalPage page, String typeName) {
    final type = ShapeType.values.firstWhere((e) => e.name == typeName);
    final shape = ShapeObject(id: const Uuid().v4(), shapeType: type, position: const Offset(150, 150), size: const Size(150, 100), strokeColor: '#0F4C5C', zIndex: page.objects.length);
    ref.read(canvasDocumentProvider.notifier).addShape(page, shape);
  }

  void _handleInsertAnimation(WidgetRef ref, LocalPage page, String type) {
    final anim = AnimationObject(id: const Uuid().v4(), animationType: AnimationObjectType.physics, position: const Offset(200, 200), size: const Size(120, 120), configData: type == 'gear' ? {'type': 'engineeringMechanism', 'is_gear': true, 'tooth_count': 18, 'radius': 50.0} : {'type': 'physicsBody', 'mass': 1.0}, zIndex: page.objects.length);
    ref.read(canvasDocumentProvider.notifier).addAnimation(page, anim);
  }

  void _handleInsertTable(BuildContext context, WidgetRef ref, LocalPage page) async {
    final result = await TableCreationDialog.show(context);
    if (result != null) {
      final table = TableObject(id: const Uuid().v4(), rows: result['rows']!, cols: result['cols']!, position: const Offset(150, 150), zIndex: page.objects.length);
      ref.read(canvasDocumentProvider.notifier).addTable(page, table);
    }
  }

  void _handleInsertLink(WidgetRef ref, LocalPage page) {
    final link = LinkObject(id: const Uuid().v4(), linkType: LinkType.externalUrl, url: 'https://google.com', label: 'Google', position: const Offset(200, 200), zIndex: page.objects.length);
    ref.read(canvasDocumentProvider.notifier).addLink(page, link);
  }

  void _handleInsertAttachment(WidgetRef ref, LocalPage page) {
    final attach = AttachmentObject(id: const Uuid().v4(), fileName: 'documento.pdf', fileExtension: 'pdf', localPath: '', position: const Offset(100, 300), zIndex: page.objects.length);
    ref.read(canvasDocumentProvider.notifier).addAttachment(page, attach);
  }

  Widget _buildCompactToolbar(BuildContext context, CanvasDocumentState docState) {
    return Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8))]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(docState.currentUserRole == 'viewer' ? Icons.visibility_outlined : Icons.lock_person_rounded, color: Colors.blueGrey, size: 20), const SizedBox(width: 12), Text(docState.currentUserRole == 'viewer' ? 'Modo Leitura' : 'Sessão Bloqueada', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87))]));
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
        _buildPopupItem('paper', Icons.grid_on_rounded, 'Mudar Pauta / Papel'), 
        _buildPopupItem('section', Icons.folder_outlined, 'Mover para Secção'),
        if (page.sectionTitle != null) _buildPopupItem('remove_section', Icons.folder_off_outlined, 'Remover Secção'),
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

  void _handlePageAction(BuildContext context, WidgetRef ref, LocalPage page, String action) {
    switch (action) {
      case 'rename': PageActionHelper.showRenameDialog(context, ref, page); break;
      case 'settings': PageActionHelper.showSettingsDialog(context, ref, page); break;
      case 'paper': onChangePaperTap(); break; 
      case 'section': PageActionHelper.showSectionDialog(context, ref, page); break;
      case 'remove_section': ref.read(canvasDocumentProvider.notifier).updatePageSection(page, null); break;
      case 'favorite': ref.read(canvasDocumentProvider.notifier).toggleFavorite(page); break;
      case 'duplicate': ref.read(canvasDocumentProvider.notifier).duplicatePage(page); break;
      case 'move_to': PageActionHelper.handleMovePage(context, ref, page); break;
      case 'copy_to': PageActionHelper.handleCopyPage(context, ref, page); break;
      case 'delete': PageActionHelper.showConfirmDelete(context, ref, page); break;
    }
  }

  Widget _buildMoreMenu(BuildContext context, WidgetRef ref, VoidCallback? onAddImage, LocalPage page) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A24)),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) {
        if (val == 'add_image') onAddImage?.call();
        else _handlePageAction(context, ref, page, val);
      },
      itemBuilder: (context) => [
        PopupMenuItem(enabled: false, padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), child: CanvasZoomControl(currentPage: page, isCompact: true)),
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
