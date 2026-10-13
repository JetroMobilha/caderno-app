import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:uuid/uuid.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../providers/canvas_document_provider.dart';
import '../../providers/canvas_viewport_provider.dart';
import '../../models/canvas_enums.dart';
import '../../models/local_page_model.dart';
import '../../models/shape_model.dart';
import '../../models/table_model.dart';
import '../../models/link_model.dart';
import '../../models/attachment_model.dart';
import 'package:caderno_digital_app/features/canvas/widgets/dialogs/table_creation_dialog.dart';
import 'package:caderno_digital_app/features/explanations/widgets/simulation_studio_sheet.dart';
import 'package:flutter/foundation.dart';
import '../dialogs/brush_style_sheet.dart';
import '../dialogs/link_creation_dialog.dart'; // 🚀 Links
import 'package:file_picker/file_picker.dart'; // 🚀 Attachments
import 'package:path_provider/path_provider.dart';
import 'dart:io' as io;
import 'dart:convert';

/// 🚀 v10.14: Barra de ferramentas superior ultra-fina e inteligente.
class TopActionToolbar extends ConsumerWidget {
  final LocalPage currentPage;
  final VoidCallback? onAddImageTap;

  const TopActionToolbar({
    super.key,
    required this.currentPage,
    this.onAddImageTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactionState = ref.watch(canvasInteractionProvider);
    final interactionNotifier = ref.read(canvasInteractionProvider.notifier);
    
    if (!interactionState.isTopToolbarVisible) {
      return _buildShowButton(interactionNotifier);
    }

    final screenWidth = MediaQuery.of(context).size.width;
    
    // 🚀 v10.85: Garantir que ferramentas críticas nunca sumam
    final List<ToolMode> permanentTools = [
      ToolMode.draw, 
      ToolMode.eraser, 
      ToolMode.pan
    ];
    
    // Filtrar a lista para evitar duplicados nas ferramentas flexíveis
    final List<ToolMode> flexibleTools = interactionState.toolOrder
        .where((t) => !permanentTools.contains(t))
        .toList();

    final bool isWide = screenWidth > 540;
    // Ajustar contagem para acomodar as permanentes + flexíveis
    final int flexibleVisibleCount = isWide 
        ? flexibleTools.length 
        : (screenWidth < 380 ? 2 : 3);
    
    final visibleFlexible = flexibleTools.take(flexibleVisibleCount).toList();
    final overflowTools = flexibleTools.skip(flexibleVisibleCount).toList();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 2), 
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.98),
        borderRadius: BorderRadius.circular(32),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          )
        ],
        border: Border.all(color: Colors.black.withOpacity(0.05)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Botão de Esconder
          _buildIconButton(
            icon: Icons.keyboard_arrow_up_rounded, 
            onTap: () => interactionNotifier.toggleTopToolbar(false),
            tooltip: 'Esconder Barra',
            color: Colors.black26,
          ),
          const VerticalDivider(width: 12, thickness: 0.5, indent: 8, endIndent: 8),

          // 1. FERRAMENTAS PERMANENTES (Pincel, Borracha, Mão)
          ...permanentTools.map((mode) => _buildToolButton(
            interactionNotifier, 
            _getIconForTool(mode), 
            mode, 
            _getLabelForTool(mode), 
            interactionState.activeTool,
            context
          )),

          const VerticalDivider(width: 8, thickness: 0.3, indent: 10, endIndent: 10),

          // 2. FERRAMENTAS FLEXÍVEIS (Texto, Tabela, etc.)
          ...visibleFlexible.map((mode) => _buildToolButton(
            interactionNotifier, 
            _getIconForTool(mode), 
            mode, 
            _getLabelForTool(mode), 
            interactionState.activeTool,
            context
          )),

          if (overflowTools.isNotEmpty) ...[
            _buildMoreMenu(context, ref, interactionNotifier, overflowTools, interactionState.activeTool),
          ],

          _buildInsertionMenu(context, ref),
        ],
      ),
    );
  }

  Widget _buildShowButton(CanvasInteractionNotifier notifier) {
    return GestureDetector(
      onTap: () => notifier.toggleTopToolbar(true),
      child: Container(
        width: 40, height: 24,
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.9),
          borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
          boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
        ),
        child: const Icon(Icons.keyboard_arrow_down_rounded, size: 18, color: Color(0xFF0F4C5C)),
      ),
    );
  }

  Widget _buildToolButton(CanvasInteractionNotifier notifier, IconData icon, ToolMode mode, String tooltip, ToolMode activeTool, BuildContext context) {
    final bool isActive = activeTool == mode;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 1),
      child: InkWell(
        onTap: () => notifier.switchTool(mode),
        onLongPress: mode == ToolMode.draw ? () => _showBrushSelector(context) : null,
        borderRadius: BorderRadius.circular(10),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          width: 34, // Ícone ligeiramente menor
          height: 34,
          decoration: BoxDecoration(
            color: isActive ? const Color(0xFF0F4C5C).withOpacity(0.08) : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: isActive ? const Color(0xFF0F4C5C) : const Color(0xFF5F6368)),
        ),
      ),
    );
  }

  Widget _buildIconButton({required IconData icon, required VoidCallback onTap, required String tooltip, Color? color}) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: SizedBox(
          width: 28, height: 28,
          child: Icon(icon, size: 16, color: color ?? const Color(0xFF5F6368)),
        ),
      ),
    );
  }

  Widget _buildMoreMenu(BuildContext context, WidgetRef ref, CanvasInteractionNotifier notifier, List<ToolMode> overflow, ToolMode activeTool) {
    return PopupMenuButton<ToolMode>(
      icon: const Icon(Icons.more_horiz_rounded, color: Color(0xFF5F6368), size: 20),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (mode) => notifier.switchTool(mode),
      itemBuilder: (context) => overflow.map((mode) => PopupMenuItem<ToolMode>(
        value: mode,
        height: 38,
        child: Row(
          children: [
            Icon(_getIconForTool(mode), size: 18, color: Colors.black54),
            const SizedBox(width: 12),
            Text(_getLabelForTool(mode), style: const TextStyle(fontSize: 12)),
          ],
        ),
      )).toList(),
    );
  }

  Widget _buildInsertionMenu(BuildContext context, WidgetRef ref) {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.add_circle_outline_rounded, color: Color(0xFF0F4C5C), size: 22),
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (val) {
        if (val == 'simulation') {
          SimulationStudioSheet.show(context, canvasSize: Size(currentPage.pageWidthPx, currentPage.pageHeightPx));
        } else if (val == 'image') {
          onAddImageTap?.call();
        } else if (val.startsWith('shape_')) {
          _handleInsertShape(ref, val.replaceFirst('shape_', ''));
        } else if (val == 'table') {
          _handleInsertTable(context, ref);
        } else if (val == 'link') {
          _handleInsertLink(context, ref);
        } else if (val == 'attach') {
          _handleInsertAttachment(context, ref);
        }
      },
      itemBuilder: (context) => [
        _buildPopupItem('simulation', Icons.auto_awesome_motion, 'Ilustração Animada'),
        const PopupMenuDivider(),
        _buildPopupItem('image', Icons.image_outlined, 'Imagem'),
        const PopupMenuDivider(),
        _buildPopupItem('shape_rectangle', Icons.rectangle_outlined, 'Retângulo'),
        _buildPopupItem('shape_circle', Icons.circle_outlined, 'Círculo'),
        _buildPopupItem('table', Icons.table_chart_outlined, 'Tabela'),
        _buildPopupItem('link', Icons.link_rounded, 'Link'),
        _buildPopupItem('attach', Icons.attach_file_rounded, 'Anexo'),
      ],
    );
  }

  PopupMenuItem<String> _buildPopupItem(String value, IconData icon, String label) => PopupMenuItem<String>(value: value, height: 38, child: Row(children: [Icon(icon, size: 18, color: Colors.black54), const SizedBox(width: 12), Text(label, style: const TextStyle(fontSize: 12))]));

  IconData _getIconForTool(ToolMode mode) {
    switch (mode) {
      case ToolMode.select: return Icons.near_me_outlined;
      case ToolMode.draw: return Icons.brush_outlined;
      case ToolMode.text: return Icons.text_fields_rounded;
      case ToolMode.table: return Icons.grid_on_rounded;
      case ToolMode.eraser: return Icons.auto_fix_high_rounded;
      case ToolMode.pixelEraser: return Icons.auto_fix_normal_rounded;
      case ToolMode.pan: return Icons.pan_tool_outlined;
      case ToolMode.video: return Icons.animation_rounded;
      default: return Icons.near_me_outlined;
    }
  }

  String _getLabelForTool(ToolMode mode) {
    switch (mode) {
      case ToolMode.select: return 'Seleção';
      case ToolMode.draw: return 'Desenhar';
      case ToolMode.text: return 'Texto';
      case ToolMode.table: return 'Tabela';
      case ToolMode.eraser: return 'Borracha';
      case ToolMode.pixelEraser: return 'Borracha Pixel';
      case ToolMode.pan: return 'Mover';
      case ToolMode.video: return 'Animação';
      default: return 'Ferramenta';
    }
  }

  Offset _getInsertPosition(WidgetRef ref, {double width = 220, double height = 60}) {
    final center = ref.read(canvasViewportProvider).currentViewportCenter;
    if (center != null) {
      return Offset(
        (center.dx - width / 2).clamp(0.0, 10000.0),
        (center.dy - height / 2).clamp(0.0, 10000.0),
      );
    }
    return const Offset(100, 300);
  }

  void _handleInsertShape(WidgetRef ref, String typeName) {
    final type = ShapeType.values.firstWhere((e) => e.name == typeName);
    final pos = _getInsertPosition(ref, width: 150, height: 100);
    final shape = ShapeObject(id: const Uuid().v4(), shapeType: type, position: pos, size: const Size(150, 100), strokeColor: '#0F4C5C', zIndex: currentPage.objects.length);
    ref.read(canvasDocumentProvider.notifier).addShape(currentPage, shape);
  }

  void _handleInsertTable(BuildContext context, WidgetRef ref) async {
    final result = await TableCreationDialog.show(context);
    if (result != null) {
      final pos = _getInsertPosition(ref, width: 200, height: 150);
      final table = TableObject(id: const Uuid().v4(), rows: result['rows']!, cols: result['cols']!, position: pos, zIndex: currentPage.objects.length);
      ref.read(canvasDocumentProvider.notifier).addTable(currentPage, table);
    }
  }

  void _handleInsertLink(BuildContext context, WidgetRef ref) async {
    final result = await LinkCreationDialog.show(context);
    if (result != null) {
      final pos = _getInsertPosition(ref, width: 200, height: 50);
      final link = LinkObject(
        id: const Uuid().v4(), 
        linkType: LinkType.externalUrl, 
        url: result['url']!, 
        label: result['label']!, 
        position: pos, 
        zIndex: currentPage.objects.length
      );
      ref.read(canvasDocumentProvider.notifier).addLink(currentPage, link);
    }
  }

  void _handleInsertAttachment(BuildContext context, WidgetRef ref) async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'doc', 'docx', 'xls', 'xlsx', 'txt', 'zip', 'jpg', 'png'],
      withData: true,
    );

    if (result != null && result.files.isNotEmpty) {
      final file = result.files.first;
      final pos = _getInsertPosition(ref, width: 220, height: 60);
      await ref
          .read(canvasDocumentProvider.notifier)
          .pickAndInsertAttachment(
            currentPage,
            file: file,
            position: pos,
            context: context,
          );
    }
  }

  void _showBrushSelector(BuildContext context) => showModalBottomSheet(context: context, backgroundColor: Colors.transparent, isScrollControlled: true, builder: (_) => const BrushStyleSheet());
}
