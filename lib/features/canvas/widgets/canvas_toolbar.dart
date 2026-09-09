import 'package:caderno_digital_app/features/shared/widgets/color_engine_widget.dart';
import 'package:flutter/material.dart';
import 'package:caderno_digital_app/features/canvas/widgets/dialogs/table_creation_dialog.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_document_provider.dart';
import '../models/local_page_model.dart';
import '../models/canvas_enums.dart' hide CanvasInteractionStateMode; // 🚀 v10
import '../providers/canvas_ui_provider.dart';
import '../widgets/canvas_zoom_control.dart';
import '../widgets/dialogs/layer_manager_sheet.dart'; 
import '../widgets/dialogs/page_action_helper.dart'; 
import '../widgets/dialogs/brush_style_sheet.dart';
import '../models/stroke_model.dart';
import '../models/text_block_model.dart';
import '../models/table_model.dart';
import '../models/shape_model.dart';
import '../models/page_object.dart';

/// 🚀 v10.1: Barra de ferramentas profissional tri-zonal com suporte a Grupos.
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
    final interactionState = ref.watch(canvasInteractionProvider);
    final interactionNotifier = ref.read(canvasInteractionProvider.notifier);
    final docState = ref.watch(canvasDocumentProvider);
    final docNotifier = ref.read(canvasDocumentProvider.notifier);
    final uiState = ref.watch(canvasUiProvider);

    final bool hideDrawingTools = docState.currentUserRole == 'viewer';
    if (hideDrawingTools) return _buildCompactToolbar(context, docState);

    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    return AnimatedOpacity(
      duration: const Duration(milliseconds: 200),
      opacity: uiState.isHudMode ? 0.15 : 1.0,
      child: IgnorePointer(
        ignoring: uiState.isHudMode,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(32),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 20, offset: const Offset(0, 8))],
            border: Border.all(color: Colors.black.withValues(alpha: 0.05)),
          ),
          child: IntrinsicHeight(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildGlobalZone(interactionNotifier, interactionState, context, ref),
                const VerticalDivider(width: 24, thickness: 1, indent: 8, endIndent: 8),
                Flexible(child: _buildContextualZone(context, ref, interactionState, interactionNotifier, docNotifier)),
                const VerticalDivider(width: 24, thickness: 1, indent: 8, endIndent: 8),
                _buildSystemZone(context, ref, docState, docNotifier, isSmallScreen),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGlobalZone(CanvasInteractionNotifier notifier, CanvasInteractionState state, BuildContext context, WidgetRef ref) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _buildToolButton(notifier, Icons.near_me_outlined, ToolMode.select, 'Selecionar', state.activeTool),
        _buildToolButton(notifier, Icons.brush_outlined, ToolMode.draw, 'Desenhar', state.activeTool, onLongPress: () => _showBrushSelector(context)),
        _buildToolButton(notifier, state.activeTool == ToolMode.pixelEraser ? Icons.cleaning_services_rounded : Icons.auto_fix_normal_outlined, ToolMode.eraser, 'Apagar', state.activeTool, onLongPress: () {
          notifier.switchTool(state.activeTool == ToolMode.eraser ? ToolMode.pixelEraser : ToolMode.eraser);
        }),
        _buildToolButton(notifier, Icons.text_fields_rounded, ToolMode.text, 'Texto', state.activeTool),
        _buildToolButton(notifier, Icons.grid_on_rounded, ToolMode.table, 'Tabela', state.activeTool),
        _buildInsertionMenu(context, ref, currentPage),
      ],
    );
  }

  Widget _buildContextualZone(BuildContext context, WidgetRef ref, CanvasInteractionState state, CanvasInteractionNotifier notifier, CanvasDocumentNotifier docNotifier) {
    if (state.selectedObjectIds.isNotEmpty) {
      final bool singleSelection = state.selectedObjectIds.length == 1;
      final String? firstId = singleSelection ? state.selectedObjectIds.first : null;
      final obj = singleSelection ? currentPage.objects.where((o) => o.id == firstId).firstOrNull : null;
      final bool canGroup = state.selectedObjectIds.length > 1;
      final bool isPartOfGroup = singleSelection && obj?.parentId != null;

      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildContextIconButton(state.isTransformMode ? Icons.check_circle_rounded : Icons.transform_rounded, () => notifier.toggleTransformMode(), state.isTransformMode ? Colors.green : Colors.orangeAccent),
          
          // 🚀 BOTÕES DE GRUPO (v10.1)
          if (canGroup) _buildContextIconButton(Icons.group_work_rounded, () => notifier.groupSelectedObjects(currentPage), Colors.indigoAccent),
          if (isPartOfGroup) _buildContextIconButton(Icons.group_off_rounded, () => notifier.ungroupSelectedObjects(currentPage), Colors.blueGrey),

          if (obj is Stroke || obj is TextBlock || obj is ShapeObject) _buildContextIconButton(Icons.palette_outlined, onColorTap, Colors.blueAccent),
          if (singleSelection && obj != null) _buildContextIconButton(obj.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, () { docNotifier.updateObject(currentPage, obj.copyWith(isLocked: !obj.isLocked)); }, obj.isLocked ? Colors.orange : Colors.black45),
          _buildContextIconButton(Icons.delete_outline_rounded, () { docNotifier.deleteObjects(currentPage, state.selectedObjectIds.toList()); notifier.clearSelection(); }, Colors.redAccent),
        ],
      );
    }
    if (state.activeTool == ToolMode.draw) {
      return Row(mainAxisSize: MainAxisSize.min, children: [_buildColorCircle(context, state.selectedColorHex, notifier), const SizedBox(width: 12), _buildContextIconButton(Icons.line_weight_rounded, onThicknessTap, const Color(0xFF1A1A24))]);
    }
    return const SizedBox(width: 20); 
  }

  Widget _buildSystemZone(BuildContext context, WidgetRef ref, CanvasDocumentState docState, CanvasDocumentNotifier docNotifier, bool isSmallScreen) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (!isSmallScreen) ...[CanvasZoomControl(currentPage: currentPage), const SizedBox(width: 8)],
        _buildContextIconButton(Icons.undo_rounded, docState.canUndo ? () => docNotifier.undo(currentPage) : null, docState.canUndo ? const Color(0xFF1A1A24) : Colors.black12),
        _buildContextIconButton(Icons.redo_rounded, docState.canRedo ? () => docNotifier.redo(currentPage) : null, docState.canRedo ? const Color(0xFF1A1A24) : Colors.black12),
        _buildContextIconButton(Icons.layers_outlined, () => _showLayerManager(context, currentPage), const Color(0xFF0F4C5C)),
        _buildPagePopupMenu(context, ref, currentPage),
      ],
    );
  }

  Widget _buildToolButton(CanvasInteractionNotifier notifier, IconData icon, ToolMode mode, String tooltip, ToolMode activeTool, {VoidCallback? onLongPress}) {
    final bool isActive = activeTool == mode;
    return Tooltip(message: tooltip, child: InkWell(onTap: () => notifier.switchTool(mode), onLongPress: onLongPress, borderRadius: BorderRadius.circular(12), child: AnimatedContainer(duration: const Duration(milliseconds: 200), width: 38, height: 38, margin: const EdgeInsets.symmetric(horizontal: 2), decoration: BoxDecoration(color: isActive ? const Color(0xFF0F4C5C).withValues(alpha: 0.12) : Colors.transparent, borderRadius: BorderRadius.circular(12)), child: Icon(icon, size: 20, color: isActive ? const Color(0xFF0F4C5C) : const Color(0xFF5F6368)))));
  }

  Widget _buildContextIconButton(IconData icon, VoidCallback? onPressed, Color color) => IconButton(iconSize: 20, constraints: const BoxConstraints(minWidth: 38, minHeight: 38), padding: EdgeInsets.zero, icon: Icon(icon, color: color), onPressed: onPressed);

  Widget _buildColorCircle(BuildContext context, String hex, CanvasInteractionNotifier notifier) => InkWell(onTap: () async { final newHex = await ColorEngine.show(context, initialColor: hex, title: 'Cor da Caneta'); if (newHex != null) notifier.setColor(newHex); }, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.black12)), child: CircleAvatar(radius: 11, backgroundColor: Color(int.parse(hex.replaceFirst('#', '0xFF'))))));

  void _showBrushSelector(BuildContext context) => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => const BrushStyleSheet());
  void _showLayerManager(BuildContext context, LocalPage page) => showModalBottomSheet(context: context, isScrollControlled: true, backgroundColor: Colors.transparent, builder: (_) => LayerManagerSheet(page: page));

  Widget _buildInsertionMenu(BuildContext context, WidgetRef ref, LocalPage page) => PopupMenuButton<String>(icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0F4C5C), size: 22), offset: const Offset(0, -200), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)), onSelected: (val) { if (val == 'image') onAddImageTap?.call(); else if (val.startsWith('shape_')) _handleInsertShape(ref, page, val.replaceFirst('shape_', '')); else if (val == 'table') _handleInsertTable(context, ref, page); else if (val == 'link') _handleInsertLink(ref, page); else if (val == 'attach') _handleInsertAttachment(ref, page); }, itemBuilder: (context) => [_buildPopupItem('image', Icons.image_outlined, 'Imagem'), const PopupMenuDivider(), PopupMenuItem(enabled: false, child: Text('FORMAS', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.bold, color: Colors.black38))), _buildPopupItem('shape_rectangle', Icons.rectangle_outlined, 'Retângulo'), _buildPopupItem('shape_circle', Icons.circle_outlined, 'Círculo'), const PopupMenuDivider(), _buildPopupItem('table', Icons.table_chart_outlined, 'Tabela'), _buildPopupItem('link', Icons.link_rounded, 'Link'), _buildPopupItem('attach', Icons.attach_file_rounded, 'Anexo')]);

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String label) => PopupMenuItem<String>(value: value, child: Row(children: [Icon(icon, size: 18, color: Colors.black54), const SizedBox(width: 12), Text(label, style: const TextStyle(fontSize: 13))]));

  void _handleInsertShape(WidgetRef ref, LocalPage page, String typeName) { final type = ShapeType.values.firstWhere((e) => e.name == typeName); final shape = ShapeObject(id: const Uuid().v4(), shapeType: type, position: const Offset(150, 150), size: const Size(150, 100), strokeColor: '#0F4C5C', zIndex: page.objects.length); ref.read(canvasDocumentProvider.notifier).addShape(page, shape); }
  void _handleInsertTable(BuildContext context, WidgetRef ref, LocalPage page) async { final result = await TableCreationDialog.show(context); if (result != null) { final table = TableObject(id: const Uuid().v4(), rows: result['rows']!, cols: result['cols']!, position: const Offset(150, 150), zIndex: page.objects.length); ref.read(canvasDocumentProvider.notifier).addTable(page, table); } }
  void _handleInsertLink(WidgetRef ref, LocalPage page) { final link = LinkObject(id: const Uuid().v4(), linkType: LinkType.externalUrl, url: 'https://google.com', label: 'Google', position: const Offset(200, 200), zIndex: page.objects.length); ref.read(canvasDocumentProvider.notifier).addLink(page, link); }
  void _handleInsertAttachment(WidgetRef ref, LocalPage page) { final attach = AttachmentObject(id: const Uuid().v4(), fileName: 'documento.pdf', fileExtension: 'pdf', localPath: '', position: const Offset(100, 300), zIndex: page.objects.length); ref.read(canvasDocumentProvider.notifier).addAttachment(page, attach); }

  Widget _buildCompactToolbar(BuildContext context, CanvasDocumentState docState) => Container(margin: const EdgeInsets.symmetric(horizontal: 16), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(30), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 15, offset: const Offset(0, 8))]), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(docState.currentUserRole == 'viewer' ? Icons.visibility_outlined : Icons.lock_person_rounded, color: Colors.blueGrey, size: 20), const SizedBox(width: 12), Text(docState.currentUserRole == 'viewer' ? 'Modo Leitura' : 'Sessão Bloqueada', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black87))]));

  Widget _buildPagePopupMenu(BuildContext context, WidgetRef ref, LocalPage page) => PopupMenuButton<String>(icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF5F6368)), offset: const Offset(0, -280), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)), onSelected: (val) => _handlePageAction(context, ref, page, val), itemBuilder: (context) => [_buildPopupItem('rename', Icons.edit_outlined, 'Renomear Folha'), _buildPopupItem('settings', Icons.settings_outlined, 'Configurações'), _buildPopupItem('paper', Icons.grid_on_rounded, 'Mudar Pauta'), const PopupMenuDivider(), _buildPopupItem('favorite', page.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded, 'Favorito'), _buildPopupItem('duplicate', Icons.copy_rounded, 'Duplicar Página'), _buildPopupItem('delete', Icons.delete_outline_rounded, 'Rasgar Folha')]);

  void _handlePageAction(BuildContext context, WidgetRef ref, LocalPage page, String action) { switch (action) { case 'rename': PageActionHelper.showRenameDialog(context, ref, page); break; case 'settings': PageActionHelper.showSettingsDialog(context, ref, page); break; case 'paper': onChangePaperTap(); break; case 'favorite': ref.read(canvasDocumentProvider.notifier).toggleFavorite(page); break; case 'duplicate': ref.read(canvasDocumentProvider.notifier).duplicatePage(page); break; case 'delete': PageActionHelper.showConfirmDelete(context, ref, page); break; } }
}
