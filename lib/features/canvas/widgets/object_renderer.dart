import 'package:flutter/material.dart';
import 'dart:io' as io;
import 'dart:math' as math;
import 'package:flutter/foundation.dart'; 
import '../models/table_cell_model.dart';
import '../models/table_types.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/page_object.dart';
import '../models/text_block_model.dart';
import '../models/image_block_model.dart';
import '../models/shape_model.dart';
import '../models/audio_block_model.dart';
import '../models/animation_object_model.dart';
import '../models/table_model.dart';
import '../models/link_model.dart';
import '../models/stroke_model.dart'; // 🚀 v10.97
import '../models/canvas_enums.dart'; 
import '../models/attachment_model.dart';
import '../../explanations/models/explanation_model.dart';
import '../../explanations/widgets/animators/math_animator.dart';
import '../../explanations/widgets/animators/physics_animator.dart';
import '../../explanations/widgets/animators/engineering_animator.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_tool_provider.dart';
import '../providers/canvas_viewport_provider.dart';

/// 🚀 v10.4: Renderizador de Objetos Limpo.
/// Responsável APENAS por desenhar o conteúdo do objeto.
/// A lógica de Seleção e Transformação foi movida para [SelectionOverlay].
class ObjectRenderer extends ConsumerStatefulWidget {
  final PageObject object;
  final bool isReadOnly;
  final Offset? movementDelta; 
  final Size? liveScale; 
  final double? liveRotation; 
  final Offset? livePositionDelta; // 🚀 v10.96

  const ObjectRenderer({
    super.key,
    required this.object,
    this.isReadOnly = false,
    this.movementDelta,
    this.liveScale,
    this.liveRotation,
    this.livePositionDelta,
  });

  @override
  ConsumerState<ObjectRenderer> createState() => _ObjectRendererState();
}

class _ObjectRendererState extends ConsumerState<ObjectRenderer> with SingleTickerProviderStateMixin {
  AnimationController? _animationController;

  @override
  void initState() {
    super.initState();
    if (widget.object is AnimationObject) {
      final anim = widget.object as AnimationObject;
      // 🚀 v11.0: Inicializar sempre se for do tipo 'physics' para evitar crash na renderização
      if (anim.autoPlay || anim.animationType == AnimationObjectType.physics) {
        _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 1));
        if (anim.autoPlay) {
          if (anim.isLooping) {
            _animationController!.repeat();
          } else {
            _animationController!.forward();
          }
        }
      }
    } else if (widget.object is ExplanationModel) {
      final exp = widget.object as ExplanationModel;
      _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
      if (exp.isPlaying) {
        _animationController!.repeat();
      }
    }
  }

  @override
  void dispose() {
    _animationController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final toolState = ref.watch(canvasToolProvider);
    final bool isEditingThis = (widget.object is TextBlock && toolState.activeTextBlock?.id == widget.object.id);
    if (!widget.object.isVisible || isEditingThis) return const SizedBox.shrink();

    Widget content;
    if (widget.object is TextBlock) {
      final tb = widget.object as TextBlock;
      // Aplicar liveScale proporcional ao tamanho da fonte durante o redimensionamento live
      final effectiveTb = (widget.liveScale != null)
          ? tb.copyWith(fontSize: tb.fontSize * widget.liveScale!.height)
          : tb;
      content = _buildText(effectiveTb);
    }
    else if (widget.object is ImageBlock) content = _buildImage(widget.object as ImageBlock);
    else if (widget.object is ShapeObject) content = _buildShape(widget.object as ShapeObject);
    else if (widget.object is AudioBlock) content = _buildAudio(widget.object as AudioBlock);
    else if (widget.object is AnimationObject) content = _buildAnimation(widget.object as AnimationObject);
    else if (widget.object is TableObject) content = _buildTable(widget.object as TableObject);
    else if (widget.object is LinkObject) content = _buildLink(widget.object as LinkObject);
    else if (widget.object is AttachmentObject) {
      content = _buildAttachment(widget.object as AttachmentObject);
    }
    else if (widget.object is ExplanationModel) {
      content = _buildExplanation(widget.object as ExplanationModel);
    }
    else {
      content = const SizedBox.shrink();
    }

    final position = widget.object.position + (widget.movementDelta ?? Offset.zero) + (widget.livePositionDelta ?? Offset.zero);
    final rotation = widget.object.rotation + (widget.liveRotation ?? 0.0);
    
    // 🚀 v10.97: Tamanho real escalonado durante a prévia live
    final size = Size(
      widget.object.size.width * (widget.liveScale?.width ?? 1.0), 
      widget.object.size.height * (widget.liveScale?.height ?? 1.0)
    );

    return Positioned(
      left: position.dx, top: position.dy,
      child: Opacity(
        opacity: (widget.movementDelta != null || widget.liveScale != null || widget.liveRotation != null || widget.livePositionDelta != null) ? 0.6 : widget.object.opacity,
        child: Transform.rotate(
          angle: rotation, alignment: Alignment.center,
          child: ConstrainedBox( // 🚀 v10.27: Flexibilidade para evitar overflow visual
            constraints: BoxConstraints(
              minWidth: size.width, 
              minHeight: size.height,
              maxWidth: widget.object is TextBlock ? double.infinity : size.width,
            ),
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                _buildDynamicContent(content, size),
                if (widget.object.isLocked) Positioned(right: 4, top: 4, child: Container(padding: const EdgeInsets.all(2), decoration: BoxDecoration(color: Colors.orange.withValues(alpha: 0.8), shape: BoxShape.circle), child: const Icon(Icons.lock_rounded, size: 10, color: Colors.white))),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// 🚀 v10.97: Envolve o conteúdo num SizedBox para forçar a escala live
  Widget _buildDynamicContent(Widget content, Size size) {
    if (widget.object is Stroke) return content; // Strokes já usam sua própria lógica interna
    return SizedBox(
      width: size.width,
      height: widget.object is TextBlock ? null : size.height, // 🚀 Permitir altura flexível para o Bloco de Texto evitar overflows
      child: content,
    );
  }

  Widget _buildText(TextBlock tb) {
    final List<String> lines = tb.text.split('\n');
    final Color textColor = Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF')));
    
    // 🚀 v10.60: Gestão de contadores por nível para listas numeradas
    final Map<int, int> levelCounters = {};

    return Container(
      width: tb.size.width, 
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: tb.backgroundColorHex != null ? Color(int.parse(tb.backgroundColorHex!.replaceFirst('#', '0xFF'))) : null, 
        borderRadius: BorderRadius.circular(4)
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: _getCrossAxisAlignment(tb.textAlign),
        children: lines.asMap().entries.map((entry) {
          final line = entry.value;
          int spaces = 0;
          for (int i = 0; i < line.length; i++) {
            if (line[i] == ' ') spaces++;
            else break;
          }
          int level = spaces ~/ 2;

          Widget prefix = const SizedBox.shrink();
          if (tb.listType == ListType.bullet) {
            IconData icon = Icons.circle;
            if (level == 1) icon = Icons.circle_outlined;
            else if (level >= 2) icon = Icons.square_rounded;
            prefix = Icon(icon, size: tb.fontSize * (level == 0 ? 0.4 : 0.35), color: textColor);
          } else if (tb.listType == ListType.numbered) {
            // Resetar contadores de níveis mais profundos
            levelCounters.removeWhere((k, v) => k > level);
            levelCounters[level] = (levelCounters[level] ?? 0) + 1;
            
            String label = '${levelCounters[level]}.';
            if (level == 1) {
              label = '${String.fromCharCode(96 + (levelCounters[level]! % 26))}.';
            } else if (level >= 2) {
              label = '-';
            }
            prefix = Text(label, style: GoogleFonts.inter(fontSize: tb.fontSize * 0.8, color: textColor, fontWeight: FontWeight.bold));
          } else if (tb.listType == ListType.checklist) {
            final bool isChecked = tb.checkedLineIndices.contains(entry.key);
            prefix = GestureDetector(
              onTap: widget.isReadOnly ? null : () {
                final List<int> newIndices = List<int>.from(tb.checkedLineIndices);
                if (isChecked) newIndices.remove(entry.key); else newIndices.add(entry.key);
                final pageClientId = ref.read(canvasViewportProvider).currentPageClientId;
                if (pageClientId != null) {
                  final page = ref.read(canvasDocumentProvider).pages.firstWhere((p) => p.clientId == pageClientId);
                  ref.read(canvasDocumentProvider.notifier).updateObject(page, tb.copyWith(checkedLineIndices: newIndices));
                }
              }, 
              child: Icon(isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: tb.fontSize, color: isChecked ? Colors.green : textColor)
            );
          }
          return Row(
            mainAxisSize: MainAxisSize.min, 
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (tb.listType != ListType.none)
                SizedBox(
                  width: 24, 
                  child: Padding(
                    padding: EdgeInsets.only(left: 1.0 + (level * 10.0), top: tb.fontSize * 0.22), // 🚀 v10.63: Sincronizado
                    child: prefix,
                  ),
                ),
              Expanded(
                child: Text(
                  tb.listType == ListType.none ? entry.value : entry.value.trimLeft(), 
                  textAlign: tb.textAlign, 
                  softWrap: true,
                  style: GoogleFonts.getFont(
                    tb.fontFamily ?? 'Inter', 
                    fontSize: tb.fontSize, 
                    height: tb.lineHeight, 
                    fontWeight: tb.isBold ? FontWeight.bold : FontWeight.normal, 
                    fontStyle: tb.isItalic ? FontStyle.italic : FontStyle.normal, 
                    decoration: TextDecoration.combine([
                      if (tb.isUnderline) TextDecoration.underline, 
                      if (tb.isStrikethrough) TextDecoration.lineThrough
                    ]), 
                    color: textColor
                  )
                )
              )
            ]
          );
        }).toList(),
      ),
    );
  }

  CrossAxisAlignment _getCrossAxisAlignment(TextAlign align) {
    switch (align) { case TextAlign.center: return CrossAxisAlignment.center; case TextAlign.right: return CrossAxisAlignment.end; default: return CrossAxisAlignment.start; }
  }

  Widget _buildImage(ImageBlock img) {
    final toolState = ref.watch(canvasToolProvider);
    final bool isCropping = toolState.isImageCropping && toolState.selectedObjectIds.contains(img.id);
    final bool hasCrop = img.cropRect != null;
    
    Widget baseImage(BoxFit fit, [Alignment alignment = Alignment.center]) {
      final ImageProvider provider = img.imagePath.startsWith('http') 
          ? NetworkImage(img.imagePath) 
          : FileImage(io.File(img.imagePath)) as ImageProvider;

      return Image(
        image: provider,
        fit: fit,
        alignment: alignment,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey.withValues(alpha: 0.1),
          child: const Center(child: Icon(Icons.broken_image_rounded, color: Colors.grey, size: 20)),
        ),
      );
    }

    if (!hasCrop && !isCropping) return SizedBox(width: img.width, height: img.height, child: baseImage(BoxFit.fill));

    // 🚀 v10.34: Renderização Imersiva de Recorte
    final crop = img.cropRect ?? const Rect.fromLTWH(0, 0, 1, 1);
    
    return SizedBox(
      width: img.width,
      height: img.height,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Fundo esmaecido (Imagem Inteira) - Apenas se estiver em modo de edição de corte
          if (isCropping)
            Positioned.fill(
              child: OverflowBox(
                alignment: Alignment(
                  (crop.center.dx * 2) - 1,
                  (crop.center.dy * 2) - 1,
                ),
                minWidth: 0, minHeight: 0,
                maxWidth: img.width / crop.width.clamp(0.01, 1.0),
                maxHeight: img.height / crop.height.clamp(0.01, 1.0),
                child: Opacity(opacity: 0.3, child: baseImage(BoxFit.fill)),
              ),
            ),
            
          // Imagem Recortada (Destaque)
          Positioned.fill(
            child: ClipRect(
              child: FractionallySizedBox(
                widthFactor: 1 / crop.width.clamp(0.01, 1.0),
                heightFactor: 1 / crop.height.clamp(0.01, 1.0),
                alignment: Alignment(
                  (crop.center.dx * 2) - 1,
                  (crop.center.dy * 2) - 1,
                ),
                child: baseImage(BoxFit.fill),
              ),
            ),
          ),
        ],
      ),
    );
  }
  Widget _buildShape(ShapeObject shape) => CustomPaint(size: shape.size, painter: _ShapePainter(shape: shape));
  Widget _buildAudio(AudioBlock audio) => Container(width: audio.size.width, height: audio.size.height, decoration: BoxDecoration(color: const Color(0xFF0F4C5C).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF0F4C5C).withValues(alpha: 0.3))), padding: const EdgeInsets.symmetric(horizontal: 12), child: Row(children: [const Icon(Icons.play_circle_fill_rounded, color: Color(0xFF0F4C5C), size: 28), const SizedBox(width: 10), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(audio.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Color(0xFF0F4C5C))), Text('${(audio.durationSeconds / 60).floor()}:${(audio.durationSeconds % 60).toString().padLeft(2, '0')}', style: TextStyle(fontSize: 9, color: Colors.black.withValues(alpha: 0.5)))]))]));

  Widget _buildAnimation(AnimationObject anim) {
    if (anim.animationType == AnimationObjectType.physics && anim.configData != null && _animationController != null) {
      return AnimatedBuilder(
        animation: _animationController!, 
        builder: (context, child) => CustomPaint(size: anim.size, painter: _PhysicsAnimationPainter(anim: anim, time: _animationController!.value))
      );
    }
    return SizedBox(width: anim.size.width, height: anim.size.height, child: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [const Icon(Icons.animation_rounded, color: Color(0xFFE36414), size: 32), Text(anim.assetPath ?? 'Animação', style: const TextStyle(fontSize: 8))])));
  }

  Widget _buildTable(TableObject table) {
    final toolState = ref.watch(canvasToolProvider);
    final isSelected = toolState.selectedObjectIds.contains(table.id);
    
    final Color borderColor = Color(int.parse(table.borderColor.replaceFirst('#', '0xFF')));

    return Container(
      width: table.size.width, height: table.size.height,
      decoration: BoxDecoration(
        color: table.tableBackgroundColorHex != null ? Color(int.parse(table.tableBackgroundColorHex!.replaceFirst('#', '0xFF'))) : Colors.white.withValues(alpha: 0.9), 
        // A borda externa agora é desenhada pelo Painter se for tracejada/pontilhada
        border: table.lineStyle == LineStyle.continuous 
            ? Border.all(color: borderColor, width: table.borderWidth)
            : null,
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Camada de Fundo/Conteúdo das Células
          ..._buildTableGrid(table, isSelected),
          
          // 2. Camada de Estrutura (Grid/Bordas)
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: TableGridPainter(
                  rows: table.rows,
                  cols: table.cols,
                  rowHeights: table.rowHeights,
                  columnWidths: table.columnWidths,
                  borderColor: borderColor,
                  borderWidth: table.borderWidth,
                  lineStyle: table.lineStyle,
                  internalBorderWidth: table.internalBorderWidth,
                  internalLineStyle: table.internalLineStyle,
                ),
              ),
            ),
          ),

          // 3. Camada de Seleção (Sempre por cima de tudo)
          if (isSelected && !toolState.isTransformMode) ...[
            if (toolState.selectedTableCells.length == 1)
               _buildSingleCellSelectionOverlay(table, toolState.selectedTableCells.first),
            if (toolState.selectedTableCells.length > 1) 
              _buildRangeSelectionOverlay(table, toolState.selectedTableCells),
          ],
        ],
      ),
    );
  }

  Widget _buildSingleCellSelectionOverlay(TableObject table, TableCellKey key) {
    final coords = key.coordinate;
    final Offset offset = table.getCellOffset(coords);
    final Size size = table.getCellSize(coords);
    
    // 🚀 v10.92: Geometria Relativa
    // Ajustamos a moldura para "sangrar" metade da espessura da borda, garantindo alinhamento central
    final double topBorder = coords.row == 0 ? table.borderWidth : table.internalBorderWidth;
    final double leftBorder = coords.col == 0 ? table.borderWidth : table.internalBorderWidth;

    return Positioned(
      left: offset.dx - (leftBorder / 2), 
      top: offset.dy - (topBorder / 2), 
      width: size.width + leftBorder, 
      height: size.height + topBorder, 
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF1976D2).withValues(alpha: 0.08),
            border: Border.all(color: const Color(0xFF1976D2), width: 2.0),
          ),
        ),
      ),
    );
  }

  Widget _buildRangeSelectionOverlay(TableObject table, Set<TableCellKey> selection) {
    int minR = 999, maxR = -1, minC = 999, maxC = -1;
    final tableSelection = selection.where((key) => key.tableId == table.id).toList();
    if (tableSelection.isEmpty) return const SizedBox.shrink();
    for (var key in tableSelection) {
      final c = key.coordinate;
      if (c.row < minR) minR = c.row; if (c.row > maxR) maxR = c.row;
      if (c.col < minC) minC = c.col; if (c.col > maxC) maxC = c.col;
    }
    
    final Offset startOffset = table.getCellOffset(CellCoordinate(minR, minC));
    double width = 0;
    for (int c = minC; c <= maxC; c++) {
      width += table.columnWidths[c];
    }
    double height = 0;
    for (int r = minR; r <= maxR; r++) {
      height += table.rowHeights[r];
    }

    // 🚀 v10.92: Compensação proporcional de bordas para seleção múltipla
    final double topBorder = minR == 0 ? table.borderWidth : table.internalBorderWidth;
    final double leftBorder = minC == 0 ? table.borderWidth : table.internalBorderWidth;

    return Positioned(
      left: startOffset.dx - (leftBorder / 2), 
      top: startOffset.dy - (topBorder / 2), 
      width: width + leftBorder, 
      height: height + topBorder, 
      child: IgnorePointer(
        child: Container(
          decoration: BoxDecoration(
            color: Colors.blueAccent.withValues(alpha: 0.1), 
            border: Border.all(color: Colors.blueAccent, width: 2)
          )
        )
      )
    );
  }

  List<Widget> _buildTableGrid(TableObject table, bool isSelected) {
    final List<Widget> widgets = []; final Set<CellCoordinate> occupied = {};
    for (int r = 0; r < table.rows; r++) {
      for (int c = 0; c < table.cols; c++) {
        final coord = CellCoordinate(r, c); if (occupied.contains(coord)) continue;
        int rs = 1, cs = 1;
        if (table.cellSpans.containsKey(coord)) { final span = table.cellSpans[coord]!; rs = span.row; cs = span.col; }
        for (int ir = 0; ir < rs; ir++) { for (int ic = 0; ic < cs; ic++) { occupied.add(CellCoordinate(r + ir, c + ic)); } }
        widgets.add(_buildStackCell(table, coord, isSelected));
      }
    }
    return widgets;
  }

  Widget _buildStackCell(TableObject table, CellCoordinate coords, bool isTableSelected) {
    final TableCellKey cellKey = TableCellKey(table.id, coords);
    final toolState = ref.watch(canvasToolProvider);
    final isCellSelected = toolState.selectedTableCells.contains(cellKey);
    final cell = table.cells[coords] ?? TableCellModel();
    
    // 🚀 v10.60: Centralização da lógica de geometria
    final Offset offset = table.getCellOffset(coords);
    final Size size = table.getCellSize(coords);
    
    final Color gridColor = Color(int.parse(table.borderColor.replaceFirst('#', '0xFF'))).withValues(alpha: 0.15); 
    final Color selectionColor = const Color(0xFF1976D2);

    return Positioned(
      left: offset.dx, top: offset.dy, width: size.width, height: size.height,
      child: GestureDetector(
        onTap: toolState.isTransformMode ? null : () { 
          if (!isTableSelected) ref.read(canvasToolProvider.notifier).selectIds(objectIds: {table.id});
          ref.read(canvasToolProvider.notifier).selectIds(tableCells: {cellKey});
        },
        onDoubleTap: toolState.isTransformMode ? null : () {
          if (!isTableSelected) ref.read(canvasToolProvider.notifier).selectIds(objectIds: {table.id});
          ref.read(canvasToolProvider.notifier).setTableCellEditing(table, coords);
        },
        onLongPress: toolState.isTransformMode ? null : () { 
          if (!isTableSelected) ref.read(canvasToolProvider.notifier).selectIds(objectIds: {table.id});
          ref.read(canvasToolProvider.notifier).toggleTableCellSelection(cellKey);
        },
        child: Container(
          decoration: BoxDecoration(
            color: cell.style.backgroundColorHex != null ? Color(int.parse(cell.style.backgroundColorHex!.replaceFirst('#', '0xFF'))) : null, 
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(4),
                child: Align(
                  alignment: _getVerticalAlignment(cell.style.verticalAlign),
                  child: _buildCellContent(table, coords, cell, size.height),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Alignment _getVerticalAlignment(int align) { switch (align) { case 0: return Alignment.topCenter; case 2: return Alignment.bottomCenter; default: return Alignment.center; } }

  Widget _buildCellContent(TableObject table, CellCoordinate coords, TableCellModel cell, double rowHeight) {
    if (cell.type == TableCellType.checkbox) {
      return Center(child: Icon(cell.value == 'true' ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: rowHeight * 0.6, color: const Color(0xFF0F4C5C)));
    }

    final Color textColor = Color(int.parse(cell.style.textColorHex.replaceFirst('#', '0xFF')));
    
    // 🚀 v10.60: Suporte a listas dentro de células
    if (cell.style.listType != ListType.none) {
      final List<String> lines = cell.value.split('\n');
      final Map<int, int> levelCounters = {};

      return SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: _getCrossAxisAlignment(cell.style.textAlign),
          children: lines.asMap().entries.map((entry) {
            final line = entry.value;
            int spaces = 0;
            for (int i = 0; i < line.length; i++) {
              if (line[i] == ' ') spaces++;
              else break;
            }
            int level = spaces ~/ 2;
  
            Widget prefix = const SizedBox.shrink();
            if (cell.style.listType == ListType.bullet) {
              IconData icon = Icons.circle;
              if (level == 1) icon = Icons.circle_outlined;
              else if (level >= 2) icon = Icons.square_rounded;
              prefix = Icon(icon, size: cell.style.fontSize * (level == 0 ? 0.4 : 0.35), color: textColor);
            } else if (cell.style.listType == ListType.numbered) {
              levelCounters.removeWhere((k, v) => k > level);
              levelCounters[level] = (levelCounters[level] ?? 0) + 1;
              String label = '${levelCounters[level]}.';
              if (level == 1) label = '${String.fromCharCode(96 + (levelCounters[level]! % 26))}.';
              else if (level >= 2) label = '-';
              prefix = Text(label, style: GoogleFonts.inter(fontSize: cell.style.fontSize * 0.8, color: textColor, fontWeight: FontWeight.bold));
            } else if (cell.style.listType == ListType.checklist) {
              final bool isChecked = cell.style.checkedLineIndices.contains(entry.key);
              prefix = GestureDetector(
                onTap: widget.isReadOnly ? null : () {
                  final List<int> newIndices = List<int>.from(cell.style.checkedLineIndices);
                  if (isChecked) newIndices.remove(entry.key); else newIndices.add(entry.key);
                  
                  final pageClientId = ref.read(canvasViewportProvider).currentPageClientId;
                  if (pageClientId != null) {
                    final page = ref.read(canvasDocumentProvider).pages.firstWhere((p) => p.clientId == pageClientId);
                    final Map<CellCoordinate, TableCellModel> newCells = Map.from(table.cells);
                    newCells[coords] = cell.copyWith(style: cell.style.copyWith(checkedLineIndices: newIndices));
                    ref.read(canvasDocumentProvider.notifier).updateObject(page, table.copyWith(cells: newCells));
                  }
                },
                child: Icon(isChecked ? Icons.check_box_rounded : Icons.check_box_outline_blank_rounded, size: cell.style.fontSize, color: isChecked ? Colors.green : textColor)
              );
            }
  
            return Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 24, 
                  child: Padding(
                    padding: EdgeInsets.only(left: 1.0 + (level * 10.0), top: cell.style.fontSize * 0.22), // 🚀 v10.63: Sincronizado
                    child: prefix,
                  ),
                ),
                Expanded(
                  child: Text(
                    line.trimLeft(),
                    textAlign: cell.style.textAlign,
                    softWrap: true,
                    style: GoogleFonts.getFont(
                      cell.style.fontFamily ?? 'Inter',
                      fontSize: cell.style.fontSize,
                      height: 1.6,
                      fontWeight: cell.style.bold ? FontWeight.bold : FontWeight.normal,
                      fontStyle: cell.style.italic ? FontStyle.italic : FontStyle.normal,
                      decoration: TextDecoration.combine([
                        if (cell.style.underline) TextDecoration.underline,
                        if (cell.style.strikethrough) TextDecoration.lineThrough
                      ]),
                      color: textColor
                    )
                  )
                )
              ]
            );
          }).toList(),
        ),
      );
    }

    return Text(
      cell.value, 
      softWrap: true, 
      textAlign: cell.style.textAlign, 
      style: GoogleFonts.getFont(
        cell.style.fontFamily ?? 'Inter', 
        fontSize: cell.style.fontSize, 
        height: 1.6, // 🚀 v10.60: Paridade total com o modo de edição
        fontWeight: cell.style.bold ? FontWeight.bold : FontWeight.normal, 
        fontStyle: cell.style.italic ? FontStyle.italic : FontStyle.normal, 
        decoration: TextDecoration.combine([
          if (cell.style.underline) TextDecoration.underline, 
          if (cell.style.strikethrough) TextDecoration.lineThrough
        ]), 
        color: textColor
      )
    );
  }

  Widget _buildLink(LinkObject link) => Container(width: link.size.width, height: link.size.height, decoration: BoxDecoration(color: Color(int.parse(link.backgroundColor.replaceFirst('#', '0xFF'))), borderRadius: BorderRadius.circular(8)), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(link.linkType == LinkType.internalPage ? Icons.description_outlined : Icons.link_rounded, color: Color(int.parse(link.textColor.replaceFirst('#', '0xFF'))), size: 16), const SizedBox(width: 8), Flexible(child: Text(link.label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(color: Color(int.parse(link.textColor.replaceFirst('#', '0xFF'))), fontSize: 12, fontWeight: FontWeight.bold)))]));
  Widget _buildAttachment(AttachmentObject attach) => Container(width: attach.size.width, height: attach.size.height, decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10), border: Border.all(color: Colors.black.withValues(alpha: 0.1)), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4, offset: const Offset(0, 2))]), padding: const EdgeInsets.symmetric(horizontal: 10), child: Row(children: [Icon(attach.fileExtension.toLowerCase() == 'pdf' ? Icons.picture_as_pdf_rounded : Icons.insert_drive_file_rounded, color: const Color(0xFF0F4C5C), size: 24), const SizedBox(width: 10), Expanded(child: Column(mainAxisAlignment: MainAxisAlignment.center, crossAxisAlignment: CrossAxisAlignment.start, children: [Text(attach.fileName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)), Text('${(attach.fileSize / 1024).toStringAsFixed(1)} KB', style: TextStyle(fontSize: 9, color: Colors.black.withValues(alpha: 0.4)))]))]));

  Widget _buildExplanation(ExplanationModel model) {
    if (_animationController == null) {
      _animationController = AnimationController(vsync: this, duration: const Duration(seconds: 2));
      if (model.isPlaying) _animationController!.repeat();
    }

    return SizedBox(
      width: model.size.width,
      height: model.size.height,
      child: AnimatedBuilder(
        animation: _animationController!,
        builder: (context, _) {
          return CustomPaint(
            size: model.size,
            painter: _ExplanationObjectPainter(
              model: model,
              time: _animationController!.value,
            ),
          );
        },
      ),
    );
  }
}

class _ExplanationObjectPainter extends CustomPainter {
  final ExplanationModel model;
  final double time;

  final MathAnimator _mathAnimator = MathAnimator();
  final PhysicsAnimator _physicsAnimator = PhysicsAnimator();
  final EngineeringAnimator _engAnimator = EngineeringAnimator();

  _ExplanationObjectPainter({required this.model, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);
    canvas.scale(model.scale);

    if (model is MathExplanation) {
      _mathAnimator.paint(canvas, size, model, time);
    } else if (model is PhysicsExplanation) {
      _physicsAnimator.paint(canvas, size, model, time);
    } else if (model is EngineeringExplanation) {
      _engAnimator.paint(canvas, size, model, time);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _ExplanationObjectPainter oldDelegate) => true;
}

class _ShapePainter extends CustomPainter {
  final ShapeObject shape; _ShapePainter({required this.shape});
  @override void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Color(int.parse(shape.strokeColor.replaceFirst('#', '0xFF')))..strokeWidth = shape.strokeWidth..style = PaintingStyle.stroke;
    if (shape.fillColor != null && shape.isClosed) { final fillPaint = Paint()..color = Color(int.parse(shape.fillColor!.replaceFirst('#', '0xFF')))..style = PaintingStyle.fill; _drawPath(canvas, size, fillPaint); }
    _drawPath(canvas, size, paint);
  }
  void _drawPath(Canvas canvas, Size size, Paint paint) {
    switch (shape.shapeType) {
      case ShapeType.rectangle: canvas.drawRect(Offset.zero & size, paint); break;
      case ShapeType.circle: canvas.drawOval(Offset.zero & size, paint); break;
      case ShapeType.line: canvas.drawLine(Offset.zero, Offset(size.width, size.height), paint); break;
      case ShapeType.triangle: final path = Path()..moveTo(size.width / 2, 0)..lineTo(size.width, size.height)..lineTo(0, size.height)..close(); canvas.drawPath(path, paint); break;
      case ShapeType.arrow:
        final start = Offset.zero; final end = Offset(size.width, size.height); canvas.drawLine(start, end, paint);
        final double angle = math.atan2(end.dy - start.dy, end.dx - start.dx);
        const double arrowSize = 15.0; const double arrowAngle = math.pi / 6;
        final path = Path()..moveTo(end.dx, end.dy)..lineTo(end.dx - arrowSize * math.cos(angle - arrowAngle), end.dy - arrowSize * math.sin(angle - arrowAngle))..moveTo(end.dx, end.dy)..lineTo(end.dx - arrowSize * math.cos(angle + arrowAngle), end.dy - arrowSize * math.sin(angle + arrowAngle));
        canvas.drawPath(path, paint); break;
    }
  }
  @override bool shouldRepaint(covariant _ShapePainter oldDelegate) => oldDelegate.shape.version != shape.version || oldDelegate.shape.updatedAt != shape.updatedAt;
}

class _PhysicsAnimationPainter extends CustomPainter {
  final AnimationObject anim; final double time; static final MathAnimator _mathAnimator = MathAnimator(); static final PhysicsAnimator _physicsAnimator = PhysicsAnimator(); static final EngineeringAnimator _engAnimator = EngineeringAnimator();
  _PhysicsAnimationPainter({required this.anim, required this.time});
  @override void paint(Canvas canvas, Size size) {
    final config = anim.configData; if (config == null) return;
    final type = config['type'];

    // 🚀 v11.0: Centralizar o canvas para que as animações físicas (que desenham em torno de Offset.zero) 
    // fiquem perfeitamente alinhadas com o quadro de seleção do objeto.
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    if (type == 'engineeringMechanism') {
      _engAnimator.paint(canvas, size, EngineeringExplanation(id: anim.id, position: Offset.zero, radius: (config['radius'] as num?)?.toDouble() ?? 40.0, angularVelocity: (config['angular_velocity'] as num?)?.toDouble() ?? 1.0, toothCount: config['tooth_count'] ?? 12, kind: (config['is_gear'] == false) ? EngineeringKind.dcCircuit : EngineeringKind.gears), time);
    } else if (type == 'physicsBody') {
      _physicsAnimator.paint(canvas, size, PhysicsExplanation(id: anim.id, position: Offset.zero, mass: (config['mass'] as num?)?.toDouble() ?? 1.0), time);
    } else if (type == 'mathFunction') {
      _mathAnimator.paint(canvas, size, MathExplanation(id: anim.id, position: Offset.zero, expression: config['expression'] ?? 'sin(x)'), time);
    }

    canvas.restore();
  }
  @override bool shouldRepaint(covariant _PhysicsAnimationPainter oldDelegate) => true;
}

/// 🚀 v10.90: Painter especializado para o grid e bordas da tabela.
/// Suporta estilos Contínuo, Tracejado e Pontilhado.
class TableGridPainter extends CustomPainter {
  final int rows;
  final int cols;
  final List<double> rowHeights;
  final List<double> columnWidths;
  final Color borderColor;
  final double borderWidth;
  final LineStyle lineStyle;
  final double internalBorderWidth; // 🚀 v10.91
  final LineStyle internalLineStyle; // 🚀 v10.91

  TableGridPainter({
    required this.rows,
    required this.cols,
    required this.rowHeights,
    required this.columnWidths,
    required this.borderColor,
    required this.borderWidth,
    required this.lineStyle,
    required this.internalBorderWidth,
    required this.internalLineStyle,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = borderColor
      ..strokeWidth = borderWidth
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = borderColor.withValues(alpha: 1.0) // 🚀 v10.91: 100% opaca para refletir estilos fielmente
      ..strokeWidth = internalBorderWidth
      ..style = PaintingStyle.stroke;

    // 1. Desenhar Borda Externa
    _drawStyledRect(canvas, Offset.zero & size, paint, lineStyle);

    // 2. Desenhar Linhas de Grade Verticais
    double currentX = 0;
    for (int c = 0; c < cols - 1; c++) {
      currentX += columnWidths[c];
      _drawStyledLine(canvas, Offset(currentX, 0), Offset(currentX, size.height), gridPaint, internalLineStyle);
    }

    // 3. Desenhar Linhas de Grade Horizontais
    double currentY = 0;
    for (int r = 0; r < rows - 1; r++) {
      currentY += rowHeights[r];
      _drawStyledLine(canvas, Offset(0, currentY), Offset(size.width, currentY), gridPaint, internalLineStyle);
    }
  }

  void _drawStyledRect(Canvas canvas, Rect rect, Paint paint, LineStyle style) {
    if (style == LineStyle.continuous) {
      canvas.drawRect(rect, paint);
      return;
    }
    
    _drawStyledLine(canvas, rect.topLeft, rect.topRight, paint, style);
    _drawStyledLine(canvas, rect.topRight, rect.bottomRight, paint, style);
    _drawStyledLine(canvas, rect.bottomRight, rect.bottomLeft, paint, style);
    _drawStyledLine(canvas, rect.bottomLeft, rect.topLeft, paint, style);
  }

  void _drawStyledLine(Canvas canvas, Offset start, Offset end, Paint paint, LineStyle style) {
    if (style == LineStyle.continuous) {
      canvas.drawLine(start, end, paint);
      return;
    }

    final double thickness = paint.strokeWidth;
    final double distance = (end - start).distance;
    if (distance <= 0) return;

    final Offset direction = (end - start) / distance;

    if (style == LineStyle.dotted) {
      // 🚀 v10.91: Pontilhado circular perfeito e proporcional
      final double dotRadius = thickness / 2;
      final double spacing = (thickness * 2.5).clamp(3.0, 30.0); // Espaçamento entre centros
      
      double currentPos = 0;
      final Paint dotPaint = Paint()
        ..color = paint.color
        ..style = PaintingStyle.fill;

      while (currentPos <= distance) {
        canvas.drawCircle(start + direction * currentPos, dotRadius, dotPaint);
        currentPos += spacing;
      }
    } else if (style == LineStyle.dashed) {
      // 🚀 v10.91: Tracejado retangular proporcional
      final double dashLen = (thickness * 5.0).clamp(5.0, 20.0);
      final double dashSpace = (thickness * 3.0).clamp(3.0, 12.0);
      
      double currentPos = 0;
      while (currentPos < distance) {
        final double segmentEnd = math.min(currentPos + dashLen, distance);
        canvas.drawLine(start + direction * currentPos, start + direction * segmentEnd, paint);
        currentPos += dashLen + dashSpace;
      }
    }
  }

  @override
  bool shouldRepaint(covariant TableGridPainter oldDelegate) {
    // 🚀 v10.91: Comparação profunda para garantir repintura em qualquer mudança estética ou estrutural
    return oldDelegate.rows != rows ||
        oldDelegate.cols != cols ||
        oldDelegate.borderWidth != borderWidth ||
        oldDelegate.lineStyle != lineStyle ||
        oldDelegate.internalBorderWidth != internalBorderWidth ||
        oldDelegate.internalLineStyle != internalLineStyle ||
        oldDelegate.borderColor != borderColor ||
        !listEquals(oldDelegate.rowHeights, rowHeights) ||
        !listEquals(oldDelegate.columnWidths, columnWidths);
  }
}
