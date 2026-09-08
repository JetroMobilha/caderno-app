import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/canvas/models/animation_object_model.dart';
import 'package:caderno_digital_app/features/canvas/models/audio_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/canvas_enums.dart';
import 'package:caderno_digital_app/features/canvas/models/image_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/shape_model.dart';
import 'package:caderno_digital_app/features/canvas/models/stroke_model.dart';
import 'package:caderno_digital_app/features/canvas/models/text_block_model.dart';
import 'package:caderno_digital_app/features/canvas/models/local_page_model.dart';
import 'package:caderno_digital_app/features/canvas/models/table_model.dart';
import 'package:caderno_digital_app/features/canvas/models/link_model.dart';
import 'package:caderno_digital_app/features/canvas/models/attachment_model.dart';
import 'package:caderno_digital_app/features/canvas/models/table_cell_model.dart';
import 'package:caderno_digital_app/features/canvas/models/page_object.dart';

enum HandleType { none, topLeft, topCenter, topRight, middleRight, bottomRight, bottomCenter, bottomLeft, middleLeft, rotate }

class CanvasToolState {
  final ToolMode currentTool;
  final String selectedColorHex;
  final double selectedThickness;
  final InlineTarget activeInlineTarget;
  final TextBlock? activeTextBlock;
  final String? activeTableId; // 🚀 v3.2
  final String? activeTableCell; // 🚀 v3.2 (format: "row,col")
  final String? tableSelectionStart; // 🚀 v4.7
  final String? tableSelectionEnd;   // 🚀 v4.7
  final Set<String> selectedStrokeIds;
  final Set<String> selectedTextIds;
  final Set<String> selectedImageIds;
  final Set<String> selectedShapeIds; 
  final Set<String> selectedAudioIds; 
  final Set<String> selectedAnimationIds; 
  final Set<String> selectedTableIds; 
  final Set<String> selectedTableCells; // 🚀 v4.2 (format: "row,col")
  final Set<String> selectedLinkIds; 
  final Set<String> selectedAttachmentIds; 
  final Offset? selectionRectStart;
  final Offset? selectionRectEnd;
  final List<Offset>? lassoPath; 
  final bool isTransformMode;
  final bool isHighlighter;
  final BrushType selectedBrushType; // 🚀 v1.2
  final bool isSmoothingEnabled;    // 🚀 v1.2
  final Offset totalSelectionDelta;
  final Size liveScale; 
  final double liveRotation; 
  final bool isMovingSelection; 
  final String? selectedEditingImageId;
  final HandleType activeHandle; 
  final Offset initialPosition; 
  final Size initialSize; 
  final double initialRotation;

  CanvasToolState({
    this.currentTool = ToolMode.draw,
    this.selectedColorHex = '#2C3E50',
    this.selectedThickness = 3.0,
    this.activeInlineTarget = InlineTarget.none,
    this.activeTextBlock,
    this.activeTableId,
    this.activeTableCell,
    this.tableSelectionStart,
    this.tableSelectionEnd,
    this.selectedStrokeIds = const {},
    this.selectedTextIds = const {},
    this.selectedImageIds = const {},
    this.selectedShapeIds = const {},
    this.selectedAudioIds = const {},
    this.selectedAnimationIds = const {},
    this.selectedTableIds = const {},
    this.selectedTableCells = const {},
    this.selectedLinkIds = const {},
    this.selectedAttachmentIds = const {},
    this.selectionRectStart,
    this.selectionRectEnd,
    this.lassoPath, 
    this.isTransformMode = false,
    this.isHighlighter = false,
    this.selectedBrushType = BrushType.gel,
    this.isSmoothingEnabled = false,
    this.totalSelectionDelta = Offset.zero,
    this.liveScale = const Size(1, 1),
    this.liveRotation = 0.0,
    this.isMovingSelection = false,
    this.selectedEditingImageId,
    this.activeHandle = HandleType.none,
    this.initialPosition = Offset.zero,
    this.initialSize = Size.zero,
    this.initialRotation = 0.0,
  });

  CanvasToolState copyWith({
    ToolMode? currentTool,
    String? selectedColorHex,
    double? selectedThickness,
    InlineTarget? activeInlineTarget,
    TextBlock? Function()? activeTextBlock, // 🚀 v5.7: Permite definir como null
    String? Function()? activeTableId,      // 🚀 v5.7
    String? Function()? activeTableCell,   // 🚀 v5.7
    String? Function()? tableSelectionStart,
    String? Function()? tableSelectionEnd,
    Set<String>? selectedStrokeIds,
    Set<String>? selectedTextIds,
    Set<String>? selectedImageIds,
    Set<String>? selectedShapeIds, 
    Set<String>? selectedAudioIds, 
    Set<String>? selectedAnimationIds, 
    Set<String>? selectedTableIds, 
    Set<String>? selectedTableCells, 
    Set<String>? selectedLinkIds, 
    Set<String>? selectedAttachmentIds, 
    Offset? Function()? selectionRectStart,
    Offset? Function()? selectionRectEnd,
    List<Offset>? Function()? lassoPath, 
    bool? isTransformMode,
    bool? isHighlighter,
    BrushType? selectedBrushType,
    bool? isSmoothingEnabled,
    bool? isMovingSelection,
    Offset? totalSelectionDelta,
    Size? liveScale,
    double? liveRotation,
    String? selectedEditingImageId,
    HandleType? activeHandle,
    Offset? initialPosition,
    Size? initialSize,
    double? initialRotation,
  }) {
    return CanvasToolState(
      currentTool: currentTool ?? this.currentTool,
      selectedColorHex: selectedColorHex ?? this.selectedColorHex,
      selectedThickness: selectedThickness ?? this.selectedThickness,
      activeInlineTarget: activeInlineTarget ?? this.activeInlineTarget,
      activeTextBlock: activeTextBlock != null ? activeTextBlock() : this.activeTextBlock,
      activeTableId: activeTableId != null ? activeTableId() : this.activeTableId,
      activeTableCell: activeTableCell != null ? activeTableCell() : this.activeTableCell,
      tableSelectionStart: tableSelectionStart != null ? tableSelectionStart() : this.tableSelectionStart,
      tableSelectionEnd: tableSelectionEnd != null ? tableSelectionEnd() : this.tableSelectionEnd,
      selectedStrokeIds: selectedStrokeIds ?? this.selectedStrokeIds,
      selectedTextIds: selectedTextIds ?? this.selectedTextIds,
      selectedImageIds: selectedImageIds ?? this.selectedImageIds,
      selectedShapeIds: selectedShapeIds ?? this.selectedShapeIds,
      selectedAudioIds: selectedAudioIds ?? this.selectedAudioIds,
      selectedAnimationIds: selectedAnimationIds ?? this.selectedAnimationIds,
      selectedTableIds: selectedTableIds ?? this.selectedTableIds,
      selectedTableCells: selectedTableCells ?? this.selectedTableCells,
      selectedLinkIds: selectedLinkIds ?? this.selectedLinkIds,
      selectedAttachmentIds: selectedAttachmentIds ?? this.selectedAttachmentIds,
      selectionRectStart: selectionRectStart != null ? selectionRectStart() : this.selectionRectStart,
      selectionRectEnd: selectionRectEnd != null ? selectionRectEnd() : this.selectionRectEnd,
      lassoPath: lassoPath != null ? lassoPath() : this.lassoPath, 
      isTransformMode: isTransformMode ?? this.isTransformMode,
      isHighlighter: isHighlighter ?? this.isHighlighter,
      selectedBrushType: selectedBrushType ?? this.selectedBrushType,
      isSmoothingEnabled: isSmoothingEnabled ?? this.isSmoothingEnabled,
      isMovingSelection: isMovingSelection ?? this.isMovingSelection,
      totalSelectionDelta: totalSelectionDelta ?? this.totalSelectionDelta,
      liveScale: liveScale ?? this.liveScale,
      liveRotation: liveRotation ?? this.liveRotation,
      selectedEditingImageId: selectedEditingImageId ?? this.selectedEditingImageId,
      activeHandle: activeHandle ?? this.activeHandle,
      initialPosition: initialPosition ?? this.initialPosition,
      initialSize: initialSize ?? this.initialSize,
      initialRotation: initialRotation ?? this.initialRotation,
    );
  }
}

/// Notifier responsável pela gestão do estado das ferramentas do canvas.
/// Controla qual a ferramenta ativa, as seleções atuais, e o estado de edição inline (texto/tabelas).
/// 🚀 v5.6: Utiliza AutoDispose para garantir que o estado seja limpo ao fechar o caderno.
class CanvasToolNotifier extends AutoDisposeNotifier<CanvasToolState> {
  @override
  CanvasToolState build() => CanvasToolState();

  /// Altera a ferramenta atual e limpa estados temporários de seleção/edição.
  void switchTool(ToolMode mode) {
    // 🚀 v6.6: Se for a mesma ferramenta e houver edição ativa, NÃO fechar.
    // Isso evita que cliques acidentais nos ícones da toolbar fechem o editor.
    if (state.currentTool == mode && (state.activeTextBlock != null || state.activeTableCell != null)) {
      return;
    }

    // 🚀 v5.6: Se houver edição ativa e estivermos REALMENTE trocando de ferramenta, fechamos.
    if (state.activeTextBlock != null || state.activeTableCell != null) {
      debugPrint('📝 [CanvasTool] Finalizando edição ativa para trocar ferramenta...');
      exitWritingMode();
    }

    // 🚀 v7.0: Decidir se mantemos o modo de transformação baseado na compatibilidade da ferramenta
    final bool canKeepTransform = mode == ToolMode.text || 
                                  mode == ToolMode.table || 
                                  mode == ToolMode.select || 
                                  mode == ToolMode.lasso ||
                                  mode == ToolMode.organizer;

    state = state.copyWith(
      currentTool: mode,
      isTransformMode: canKeepTransform ? state.isTransformMode : false,
      selectionRectStart: () => null,
      selectionRectEnd: () => null,
      lassoPath: () => null,
      activeInlineTarget: InlineTarget.none,
      activeTextBlock: () => null,
      activeTableId: () => null,
      activeTableCell: () => null,
      selectedTableCells: {},
    );
  }

  /// Define a cor selecionada para ferramentas de desenho e texto.
  void setColor(String hex) {
    state = state.copyWith(selectedColorHex: hex);
  }

  /// Define a espessura da linha para canetas e formas.
  void setThickness(double thickness) {
    state = state.copyWith(selectedThickness: thickness);
  }

  /// Ativa/Desativa o modo marca-texto (transparência).
  void toggleHighlighterMode(bool value) {
    state = state.copyWith(isHighlighter: value);
  }

  /// Altera o tipo de pincel (gel, caneta, marcador, etc).
  void setBrushType(BrushType type) {
    state = state.copyWith(selectedBrushType: type);
  }

  /// Ativa/Desativa a suavização de traço (Bezier).
  void setSmoothing(bool value) {
    state = state.copyWith(isSmoothingEnabled: value);
  }

  /// Inicia a edição inline de um bloco de texto.
  /// Limpa seleções de outros objetos para focar na escrita.
  void setTextEditing(InlineTarget target, [TextBlock? block]) {
    final bool isProxy = block?.id.startsWith('proxy_') ?? false;

    state = state.copyWith(
      activeInlineTarget: target,
      activeTextBlock: () => block,
      selectedStrokeIds: {},
      selectedTextIds: {},
      selectedImageIds: {},
      selectedShapeIds: {},
      selectedAudioIds: {},
      selectedAnimationIds: {},
      selectedTableIds: isProxy ? state.selectedTableIds : {},
      selectedLinkIds: {},
      selectedAttachmentIds: {},
      // 🚀 v5.5: Preservar contexto de tabela se for um proxy
      activeTableId: () => isProxy ? state.activeTableId : null,
      activeTableCell: () => isProxy ? state.activeTableCell : null,
    );
  }

  /// Ativa a edição de uma célula específica de uma tabela.
  /// Implementa um mecanismo de 'Proxy' para reutilizar a barra de texto original.
  void setTableCellEditing(TableObject table, String cellCoords) {
    // 🚀 v5.4: Evitar re-ativação se já estivermos na mesma célula (Preserva cursor)
    final newCellKey = '${table.id}:$cellCoords';
    if (state.activeTableCell == newCellKey) return;

    final cell = table.cells[cellCoords] ?? TableCellModel();
    
    // 🚀 v7.3: Cálculo de Posição com Suporte a Rotação (Alignment.center)
    final parts = cellCoords.split(',');
    final r = int.parse(parts[0]);
    final c = int.parse(parts[1]);
    
    double localLeft = 0;
    for (int i = 0; i < c; i++) localLeft += table.columnWidths[i];
    double localTop = 0;
    for (int i = 0; i < r; i++) localTop += table.rowHeights[i];

    // Calcular dimensões considerando spans
    double cellW = table.columnWidths[c];
    double cellH = table.rowHeights[r];
    if (table.cellSpans.containsKey(cellCoords)) {
      final spanParts = table.cellSpans[cellCoords]!.split(',');
      int rs = int.parse(spanParts[0]);
      int cs = int.parse(spanParts[1]);
      cellW = 0;
      for (int i = 0; i < cs; i++) cellW += table.columnWidths[c + i];
      cellH = 0;
      for (int i = 0; i < rs; i++) cellH += table.rowHeights[r + i];
    }

    // 1. Centro da Tabela (Ponto de rotação no ObjectRenderer)
    final tableCenter = (table.position & table.size).center;

    // 2. Centro da Célula (Não rotacionado)
    final cellUnrotatedTopLeft = table.position + Offset(localLeft, localTop);
    final cellUnrotatedCenter = cellUnrotatedTopLeft + Offset(cellW / 2, cellH / 2);

    // 3. Centro da Célula (Rotacionado)
    final rotatedCellCenter = _rotatePoint(cellUnrotatedCenter, tableCenter, table.rotation);

    // 4. Posição Final do Proxy (Para que o seu centro bata com o centro rotacionado da célula)
    final proxyPos = rotatedCellCenter - Offset(cellW / 2, cellH / 2);

    final proxy = TextBlock(
      id: 'proxy_${table.id}_$cellCoords',
      text: cell.value,
      position: proxyPos,
      fontSize: cell.style.fontSize,
      isBold: cell.style.bold,
      isItalic: cell.style.italic,
      isUnderline: cell.style.underline,
      isStrikethrough: cell.style.strikethrough,
      textAlign: cell.style.textAlign,
      fontFamily: cell.style.fontFamily,
      textColorHex: cell.style.textColorHex,
      backgroundColorHex: cell.style.backgroundColorHex,
      rotation: table.rotation,
    );

    state = state.copyWith(
      activeInlineTarget: InlineTarget.block, 
      activeTextBlock: () => proxy,
      activeTableId: () => table.id,
      activeTableCell: () => newCellKey, // Formato id:r,c
      selectedTableCells: {newCellKey},
      tableSelectionStart: () => null,
      tableSelectionEnd: () => null,
      // 🚀 v5.5: Limpar outras seleções para evitar conflitos visuais
      selectedStrokeIds: {},
      selectedTextIds: {},
      selectedImageIds: {},
      selectedShapeIds: {},
      selectedAudioIds: {},
      selectedAnimationIds: {},
      selectedTableIds: {table.id},
    );
  }

  /// Alterna a seleção de uma célula individual (usado em multi-seleção/Shift).
  void toggleTableCellSelection(String cell) {
    final newSelection = Set<String>.from(state.selectedTableCells);
    if (newSelection.contains(cell)) {
      newSelection.remove(cell);
    } else {
      newSelection.add(cell);
    }
    state = state.copyWith(selectedTableCells: newSelection);
  }

  /// Limpa todas as seleções de células de tabela.
  void clearTableCellSelection() {
    state = state.copyWith(
      selectedTableCells: {},
      tableSelectionStart: () => null,
      tableSelectionEnd: () => null,
    );
  }

  /// Atualiza o intervalo de seleção de células (arraste no modo Tabela).
  void updateTableSelectionRange(String cellCoords, TableObject table) {
    final cellKey = '${table.id}:$cellCoords';
    String start = state.tableSelectionStart ?? cellKey;
    state = state.copyWith(
      tableSelectionStart: () => start,
      tableSelectionEnd: () => cellKey,
      selectedTableCells: table.getKeysInRange(start, cellKey),
    );
  }

  /// Limpa apenas o cursor/bloco ativo, mas mantém a ferramenta de texto/tabela ativa.
  /// 🚀 v5.8: Essencial para preenchimento contínuo.
  void stopEditing() {
    debugPrint('📝 [CanvasTool] Parando edição (Mantendo ferramenta)...');
    state = state.copyWith(
      activeInlineTarget: InlineTarget.none,
      activeTextBlock: () => null,
      activeTableCell: () => null,
      tableSelectionStart: () => null,
      tableSelectionEnd: () => null,
      selectedTableCells: {},
    );
  }

  /// Finaliza qualquer modo de escrita ativo e retorna ao estado neutro.
  void exitWritingMode() {
    debugPrint('🛡️ [CanvasTool] Finalizando modo de escrita...');
    
    // 🚀 v5.9: Se estávamos editando uma tabela, voltamos para o modo Tabela
    final bool wasInTable = state.activeTableId != null || state.currentTool == ToolMode.table;

    state = state.copyWith(
      currentTool: wasInTable ? ToolMode.table : ToolMode.draw,
      activeInlineTarget: InlineTarget.none,
      activeTextBlock: () => null,
      activeTableCell: () => null,
      activeTableId: () => wasInTable ? state.activeTableId : null, 
      tableSelectionStart: () => null,
      tableSelectionEnd: () => null,
      selectedTableCells: {},
      selectedTableIds: wasInTable ? state.selectedTableIds : {}, 
      isTransformMode: false,
    );
  }

  /// Encerra forçadamente o modo de design de tabela.
  void forceExitTableMode() {
     debugPrint('🛑 [CanvasTool] Saindo explicitamente do Modo de Tabela.');
     state = CanvasToolState(
      currentTool: ToolMode.draw,
      selectedColorHex: state.selectedColorHex,
      selectedThickness: state.selectedThickness,
      isHighlighter: state.isHighlighter,
      selectedBrushType: state.selectedBrushType,
      isSmoothingEnabled: state.isSmoothingEnabled,
    );
  }

  /// Atalho para limpar edição de texto.
  void clearTextEditing() {
    exitWritingMode();
  }

  /// Ativa/Desativa o modo de transformação (redimensionamento/rotação).
  /// 🚀 v6.8: Agora limpa edições ativas para focar no layout.
  void toggleTransformMode() {
    final bool turningOn = !state.isTransformMode;
    
    if (turningOn) {
      debugPrint('📐 [CanvasTool] Ativando modo de transformação. Limpando editores...');
      
      // Se houver um bloco de texto sendo editado que não seja proxy, garantimos que ele está selecionado
      final activeBlock = state.activeTextBlock;
      final Set<String> newTextIds = Set.from(state.selectedTextIds);
      if (activeBlock != null && !activeBlock.id.startsWith('proxy_')) {
        newTextIds.add(activeBlock.id);
      }

      // Parar edições de texto/células e limpar seleções internas
      stopEditing();

      state = state.copyWith(
        isTransformMode: true,
        selectedTextIds: newTextIds,
        selectedTableCells: {}, // 🚀 v6.9: Limpar seleção interna ao entrar em modo layout
      );
    } else {
      state = state.copyWith(isTransformMode: false);
    }
  }

  void setSelectionRect(Offset? start, Offset? end, [LocalPage? page]) {
    state = state.copyWith(
      selectionRectStart: () => start,
      selectionRectEnd: () => end,
      lassoPath: () => null,
    );

    if (start != null && end != null && page != null) {
      final rect = Rect.fromPoints(start, end);
      final newStrokeIds = <String>{};
      final newTextIds = <String>{};
      final newImageIds = <String>{};
      final newShapeIds = <String>{};
      final newAudioIds = <String>{};
      final newAnimationIds = <String>{};
      final newTableIds = <String>{};
      final newLinkIds = <String>{};
      final newAttachmentIds = <String>{};
      
      for (var obj in page.objects) {
        if (obj.isDeleted) continue;
        
        final layer = page.layers.cast<LayerDefinition?>().firstWhere((l) => l?.id == (obj.layerId ?? 'default'), orElse: () => null);
        if (layer?.isLocked ?? false) continue;

        bool intersects = false;
        if (obj is Stroke) {
          intersects = obj.points.any((pt) => rect.contains(pt));
          if (intersects) newStrokeIds.add(obj.id);
        } else {
          final objRect = obj.position & obj.size;
          intersects = rect.overlaps(objRect);
          if (intersects) {
            if (obj is TextBlock) newTextIds.add(obj.id);
            else if (obj is ImageBlock) newImageIds.add(obj.id);
            else if (obj is ShapeObject) newShapeIds.add(obj.id);
            else if (obj is AudioBlock) newAudioIds.add(obj.id);
            else if (obj is AnimationObject) newAnimationIds.add(obj.id);
            else if (obj is TableObject) newTableIds.add(obj.id);
            else if (obj is LinkObject) newLinkIds.add(obj.id);
            else if (obj is AttachmentObject) newAttachmentIds.add(obj.id);
          }
        }
      }

      state = state.copyWith(
        selectedStrokeIds: newStrokeIds,
        selectedTextIds: newTextIds,
        selectedImageIds: newImageIds,
        selectedShapeIds: newShapeIds,
        selectedAudioIds: newAudioIds,
        selectedAnimationIds: newAnimationIds,
        selectedTableIds: newTableIds,
        selectedLinkIds: newLinkIds,
        selectedAttachmentIds: newAttachmentIds,
      );
    }
  }

  void setLassoPath(List<Offset>? path, [LocalPage? page]) {
    state = state.copyWith(
      lassoPath: () => path,
      selectionRectStart: () => null,
      selectionRectEnd: () => null,
    );

    if (path != null && path.length > 3 && page != null) {
      final newStrokeIds = <String>{};
      final newTextIds = <String>{};
      final newImageIds = <String>{};
      final newShapeIds = <String>{};
      final newAudioIds = <String>{};
      final newAnimationIds = <String>{};
      final newTableIds = <String>{};
      final newLinkIds = <String>{};
      final newAttachmentIds = <String>{};

      for (var obj in page.objects) {
        if (obj.isDeleted) continue;

        final layer = page.layers.cast<LayerDefinition?>().firstWhere((l) => l?.id == (obj.layerId ?? 'default'), orElse: () => null);
        if (layer?.isLocked ?? false) continue;

        bool intersects = false;
        if (obj is Stroke) {
          intersects = obj.points.any((pt) => _isPointInPolygon(pt, path));
          if (intersects) newStrokeIds.add(obj.id);
        } else {
          final center = obj.position + Offset(obj.size.width / 2, obj.size.height / 2);
          intersects = _isPointInPolygon(obj.position, path) || _isPointInPolygon(center, path);
          
          if (intersects) {
            if (obj is TextBlock) newTextIds.add(obj.id);
            else if (obj is ImageBlock) newImageIds.add(obj.id);
            else if (obj is ShapeObject) newShapeIds.add(obj.id);
            else if (obj is AudioBlock) newAudioIds.add(obj.id);
            else if (obj is AnimationObject) newAnimationIds.add(obj.id);
            else if (obj is TableObject) newTableIds.add(obj.id);
            else if (obj is LinkObject) newLinkIds.add(obj.id);
            else if (obj is AttachmentObject) newAttachmentIds.add(obj.id);
          }
        }
      }

      state = state.copyWith(
        selectedStrokeIds: newStrokeIds,
        selectedTextIds: newTextIds,
        selectedImageIds: newImageIds,
        selectedShapeIds: newShapeIds,
        selectedAudioIds: newAudioIds,
        selectedAnimationIds: newAnimationIds,
        selectedTableIds: newTableIds,
        selectedLinkIds: newLinkIds,
        selectedAttachmentIds: newAttachmentIds,
      );
    }
  }

  bool _isPointInPolygon(Offset point, List<Offset> polygon) {
    bool result = false;
    int j = polygon.length - 1;
    for (int i = 0; i < polygon.length; i++) {
      if ((polygon[i].dy > point.dy) != (polygon[j].dy > point.dy) &&
          (point.dx < (polygon[j].dx - polygon[i].dx) * (point.dy - polygon[i].dy) / (polygon[j].dy - polygon[i].dy) + polygon[i].dx)) {
        result = !result;
      }
      j = i;
    }
    return result;
  }

  void setMovingSelection(bool value) {
    state = state.copyWith(isMovingSelection: value);
  }

  void clearSelection() {
    state = state.copyWith(
      selectedStrokeIds: {},
      selectedTextIds: {},
      selectedImageIds: {},
      selectedShapeIds: {},
      selectedAudioIds: {},
      selectedAnimationIds: {},
      selectedTableIds: {}, 
      selectedLinkIds: {}, 
      selectedAttachmentIds: {}, 
      selectionRectStart: () => null,
      selectionRectEnd: () => null,
      lassoPath: () => null, 
      isTransformMode: state.isTransformMode, // 🚀 v7.0: Não resetar automaticamente
      isMovingSelection: false, 
      totalSelectionDelta: Offset.zero,
      liveScale: const Size(1, 1), 
      liveRotation: 0.0, 
    );
  }

  void updateSelectionDelta(Offset delta) {
    state = state.copyWith(totalSelectionDelta: state.totalSelectionDelta + delta);
  }

  void resetSelectionDelta() {
    state = state.copyWith(totalSelectionDelta: Offset.zero);
  }

  void selectIds({
    Set<String>? strokeIds,
    Set<String>? textIds,
    Set<String>? imageIds,
    Set<String>? shapeIds,
    Set<String>? audioIds,
    Set<String>? animationIds,
    Set<String>? tableIds,
    Set<String>? tableCells,
    Set<String>? linkIds,
    Set<String>? attachmentIds,
  }) {
    state = state.copyWith(
      selectedStrokeIds: strokeIds ?? state.selectedStrokeIds,
      selectedTextIds: textIds ?? state.selectedTextIds,
      selectedImageIds: imageIds ?? state.selectedImageIds,
      selectedShapeIds: shapeIds ?? state.selectedShapeIds,
      selectedAudioIds: audioIds ?? state.selectedAudioIds,
      selectedAnimationIds: animationIds ?? state.selectedAnimationIds,
      selectedTableIds: tableIds ?? state.selectedTableIds,
      selectedTableCells: tableCells ?? state.selectedTableCells,
      selectedLinkIds: linkIds ?? state.selectedLinkIds,
      selectedAttachmentIds: attachmentIds ?? state.selectedAttachmentIds,
    );
  }

  void selectAt(Offset localPos, LocalPage page, {bool includeLocked = false}) {
    // 🚀 v2: Prioridade total à seleção atual se o clique for dentro dela
    if (isPointInSelection(localPos, page)) return;

    final objects = page.objects.where((o) => !o.isDeleted).toList()
      ..sort((a, b) => b.zIndex.compareTo(a.zIndex));

    for (var obj in objects) {
      if (!includeLocked && obj.isLocked) continue;
      if (!obj.isVisible) continue;

      bool hit = checkHit(localPos, obj);

      if (hit) {
        clearSelection();
        _applySelection(obj);
        return;
      }
    }
    clearSelection();
  }

  bool isPointInSelection(Offset localPos, LocalPage page) {
    final selectedIds = {
      ...state.selectedStrokeIds, ...state.selectedTextIds, ...state.selectedImageIds,
      ...state.selectedShapeIds, ...state.selectedAudioIds, ...state.selectedAnimationIds,
      ...state.selectedTableIds, ...state.selectedLinkIds, ...state.selectedAttachmentIds,
    };
    if (selectedIds.isEmpty) return false;

    for (var id in selectedIds) {
      final obj = page.objects.cast<PageObject?>().firstWhere((o) => o?.id == id, orElse: () => null);
      if (obj != null && checkHit(localPos, obj)) return true;
    }
    return false;
  }

  bool checkHit(Offset localPos, PageObject obj) {
    if (obj is Stroke) {
      return obj.points.any((pt) => (pt - localPos).distance < (obj.thickness + 15));
    } else {
      final bounds = obj.position & obj.size;
      // Área de toque mínima padrão indústria (44px)
      final hitBounds = Rect.fromCenter(
        center: bounds.center, 
        width: bounds.width < 44 ? 44 : bounds.width, 
        height: bounds.height < 44 ? 44 : bounds.height
      );

      if (obj.rotation != 0) {
        final center = hitBounds.center;
        final rotatedPoint = _rotatePoint(localPos, center, -obj.rotation);
        return hitBounds.contains(rotatedPoint);
      } else {
        return hitBounds.contains(localPos);
      }
    }
  }

  void _applySelection(PageObject obj) {
    if (obj is Stroke) selectIds(strokeIds: {obj.id});
    else if (obj is TextBlock) selectIds(textIds: {obj.id});
    else if (obj is ImageBlock) selectIds(imageIds: {obj.id});
    else if (obj is ShapeObject) selectIds(shapeIds: {obj.id});
    else if (obj is AudioBlock) selectIds(audioIds: {obj.id});
    else if (obj is AnimationObject) selectIds(animationIds: {obj.id});
    else if (obj is TableObject) selectIds(tableIds: {obj.id});
    else if (obj is LinkObject) selectIds(linkIds: {obj.id});
    else if (obj is AttachmentObject) selectIds(attachmentIds: {obj.id});
  }

  Offset _rotatePoint(Offset point, Offset center, double angle) {
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);
    final dx = point.dx - center.dx;
    final dy = point.dy - center.dy;
    return Offset(
      center.dx + dx * cosA - dy * sinA,
      center.dy + dx * sinA + dy * cosA,
    );
  }

  void startHandleTransform(HandleType handle, Offset currentPos, Size currentSize, double currentRotation) {
    state = state.copyWith(
      activeHandle: handle,
      initialPosition: currentPos,
      initialSize: currentSize,
      initialRotation: currentRotation,
      liveScale: const Size(1, 1),
      liveRotation: 0,
    );
  }

  void updateLiveTransform({Size? scale, double? rotation}) {
    state = state.copyWith(
      liveScale: scale ?? state.liveScale,
      liveRotation: rotation ?? state.liveRotation,
    );
  }

  void endHandleTransform() {
    state = state.copyWith(
      activeHandle: HandleType.none,
      liveScale: const Size(1, 1),
      liveRotation: 0,
    );
  }

  /// Reinicia completamente o estado das ferramentas para o padrão.
  void reset() {
    state = CanvasToolState();
  }
}

final canvasToolProvider = NotifierProvider.autoDispose<CanvasToolNotifier, CanvasToolState>(() {
  return CanvasToolNotifier();
});
