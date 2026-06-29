import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/drawing_point_model.dart';
import '../repositories/notebook_repository.dart';

class CanvasScreen extends StatefulWidget {
  final int notebookId;
  final String notebookTitle;
  final String lineType;
  final String paperSize;

  const CanvasScreen({
    super.key,
    required this.notebookId,
    required this.notebookTitle,
    this.lineType = 'ruled',
    required this.paperSize,
  });

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

enum ToolMode { draw, pan, select, text, eraser, insertImage, imageEdit }
enum InlineTarget { none, block, title, footer }

class _CanvasScreenState extends State<CanvasScreen> {
  final NotebookRepository _repository = NotebookRepository();
  bool _isLoading = true;

  List<LocalPage> _pages = [];
  int _currentPageIndex = 0;

  final ValueNotifier<List<Offset>> _activePointsNotifier = ValueNotifier([]);

  ToolMode _currentTool = ToolMode.draw;
  InlineTarget _activeInlineTarget = InlineTarget.none;
  TextBlock? _activeTextBlock;
  late String _liveLineType; // <--- NOVA VARIÁVEL MUTÁVEL

  final FocusNode _textFocusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();

  final Set<String> _selectedStrokeIds = {};
  Offset? _selectionRectStart;
  Offset? _selectionRectEnd;
  bool _isMovingStrokes = false;
  Offset? _lastPanOffset;

  String _selectedColorHex = '#2C3E50';
  double _selectedThickness = 3.0;

  final PageController _pageController = PageController(initialPage: 0);

  final Map<String, Size> _paperSizes = {
    'A5': const Size(420, 595),
    'A4': const Size(595, 842),
    'A3': const Size(842, 1191),
    'A2': const Size(1191, 1684),
    'A1': const Size(1684, 2384),
    'A0': const Size(2384, 3370),
  };

  final Map<String, Color> _colorPalette = {
    'Preto': const Color(0xFF1A1A24),
    'Cinzento Escuro': const Color(0xFF455A64),
    'Cinzento Claro': const Color(0xFF90A4AE),
    'Azul Marinho': const Color(0xFF2C3E50),
    'Azul Clássico': const Color(0xFF1976D2),
    'Ciano': const Color(0xFF00BCD4),
    'Verde Floresta': const Color(0xFF27AE60),
    'Verde Alface': const Color(0xFF8BC34A),
    'Amarelo': const Color(0xFFFBC02D),
    'Laranja': const Color(0xFFE67E22),
    'Vermelho': const Color(0xFFE74C3C),
    'Bordô': const Color(0xFFB71C1C),
    'Rosa': const Color(0xFFE91E63),
    'Roxo': const Color(0xFF9B59B6),
    'Castanho': const Color(0xFF795548),
  };

  final List<double> _thicknessOptions = [1.0, 2.0, 3.0, 5.0, 10.0, 20.0];

  @override
  void initState() {
    super.initState();
    _liveLineType = widget.lineType;
    _loadSavedPages();
  }

  Future<void> _loadSavedPages() async {
    try {
      final pages = await _repository.getFullPagesForNotebook(widget.notebookId);
      setState(() {
        _pages = pages;
        _isLoading = false;
      });
    } catch (e) {
      print("Erro tático ao carregar caderno: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _activePointsNotifier.dispose();
    _pageController.dispose();
    _textFocusNode.dispose();
    _textController.dispose();
    for (var page in _pages) {
      page.dispose();
    }
    super.dispose();
  }

  // =========================================================================
  // 🚀 O PORTEIRO DE ESTADO (Garante limpeza visual imediata na troca de ferramenta)
  // =========================================================================
  void _switchTool(ToolMode newMode) {
    setState(() {
      _currentTool = newMode;

      // 🧹 A FAXINA MÁGICA: Se saíste da ferramenta Selecionar, apaga o rastro azul!
      if (newMode != ToolMode.select) {
        _selectedStrokeIds.clear();
        _selectionRectStart = null;
        _selectionRectEnd = null;
        _isMovingStrokes = false;
      }
    });
  }

  void _finishEditingInline(LocalPage page) {
    if (_activeInlineTarget == InlineTarget.none) return;

    setState(() {
      final String cleanText = _textController.text.trim();

      if (_activeInlineTarget == InlineTarget.block && _activeTextBlock != null) {
        _activeTextBlock!.text = cleanText;
        if (cleanText.isEmpty) {
          page.textBlocks.remove(_activeTextBlock);
        } else if (page.id != null) {
          _repository.saveSingleTextBlock(page.id!, _activeTextBlock!);
        }
      } else if (_activeInlineTarget == InlineTarget.title) {
        page.title = cleanText;
        if (page.id != null) {
          _repository.updatePageMetadata(page.id!, page.title, page.footer);
        }
      } else if (_activeInlineTarget == InlineTarget.footer) {
        page.footer = cleanText;
        if (page.id != null) {
          _repository.updatePageMetadata(page.id!, page.title, page.footer);
        }
      }

      _activeInlineTarget = InlineTarget.none;
      _activeTextBlock = null;
    });

    _textFocusNode.unfocus();
  }

  void _resetZoomForPage(LocalPage page, String paperSize) {
    final double initialScale = paperSize == 'A0' || paperSize == 'A1' ? 0.25 : 1.4;
    page.transformationController.value = Matrix4.identity()..scale(initialScale);
  }

  void _zoom(double factor) {
    if (_pages.isEmpty) return;
    final currentPage = _pages[_currentPageIndex];

    setState(() {
      final Matrix4 matrix = currentPage.transformationController.value;
      final double currentScale = matrix.getMaxScaleOnAxis();

      if (currentScale * factor < 0.1 || currentScale * factor > 6.0) return;

      final Size screenSize = MediaQuery.of(context).size;
      final double centerX = screenSize.width / 2;
      final double centerY = screenSize.height / 2;

      matrix.translate(centerX, centerY);
      matrix.scale(factor);
      matrix.translate(-centerX, -centerY);

      currentPage.transformationController.value = matrix;
    });
  }

  void _showAddPageDialog() {
    bool selectedIsLandscape = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFFFDFBF7),
          title: Text('Nova Folha', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Escolha a orientação desta folha:', style: GoogleFonts.inter(fontSize: 14)),
              const SizedBox(height: 16),
              RadioListTile<bool>(
                title: const Text('Retrato (Vertical)'),
                value: false,
                groupValue: selectedIsLandscape,
                onChanged: (val) => setModalState(() => selectedIsLandscape = val!),
              ),
              RadioListTile<bool>(
                title: const Text('Paisagem (Horizontal)'),
                value: true,
                groupValue: selectedIsLandscape,
                onChanged: (val) => setModalState(() => selectedIsLandscape = val!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C)),
              onPressed: () async {
                final newPage = LocalPage(
                  notebookId: widget.notebookId,
                  pageNumber: _pages.length + 1,
                  isLandscape: selectedIsLandscape,
                );

                _resetZoomForPage(newPage, widget.paperSize);

                setState(() => _pages.add(newPage));
                Navigator.pop(context);

                await _repository.saveFullNotebook(widget.notebookId, _pages);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_pageController.hasClients) {
                    _pageController.animateToPage(
                      _pages.length - 1,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  }
                });
              },
              child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDeletePage(LocalPage page, int index) {
    if (_pages.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por segurança, não é possível rasgar a única folha do caderno!'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.delete_forever, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text(
              'Rasgar Folha ${index + 1}',
              style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 18),
            ),
          ],
        ),
        content: Text(
          'Aviso irreversível:\nEsta ação destruirá todos os desenhos, textos e fotografias contidos nesta folha.',
          style: GoogleFonts.inter(fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(context);
              setState(() {
                _pages.removeAt(index);
                if (_currentPageIndex >= _pages.length) {
                  _currentPageIndex = _pages.length - 1;
                }
              });
              await _repository.saveFullNotebook(widget.notebookId, _pages);
            },
            child: const Text('Destruir Folha', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _deleteImageBlock(LocalPage page, ImageBlock img) {
    final int backupIndex = page.imageBlocks.indexOf(img);
    setState(() => page.imageBlocks.remove(img));

    _repository.saveFullNotebook(widget.notebookId, _pages);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Fotografia removida da folha.'),
        backgroundColor: const Color(0xFF1A1A24),
        action: SnackBarAction(
          label: 'ANULAR',
          textColor: const Color(0xFF00BCD4),
          onPressed: () {
            setState(() => page.imageBlocks.insert(backupIndex, img));
            _repository.saveFullNotebook(widget.notebookId, _pages);
          },
        ),
      ),
    );
  }

  void _eraseAtPosition(Offset pos, LocalPage page) {
    const double eraserRadius = 20.0;
    final List<Stroke> strokesToRemove = [];

    for (var stroke in page.strokes) {
      for (var point in stroke.points) {
        if ((point - pos).distance < eraserRadius) {
          strokesToRemove.add(stroke);
          break;
        }
      }
    }

    if (strokesToRemove.isNotEmpty) {
      setState(() {
        for (var stroke in strokesToRemove) {
          page.strokes.remove(stroke);
          if (page.id != null) {
            _repository.deleteSingleStroke(page.id!, stroke.id);
          }
        }
      });
    }
  }

  Future<void> _pickAndInsertImage(LocalPage page) async {
    final ImagePicker picker = ImagePicker();
    final XFile? pickedFile = await picker.pickImage(source: ImageSource.gallery, imageQuality: 85);

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);
      final newImageBlock = ImageBlock(
        id: const Uuid().v4(),
        imageFile: imageFile,
        position: const Offset(100, 150),
        width: 300.0,
        height: 200.0,
      );

      setState(() {
        page.imageBlocks.add(newImageBlock);
        _currentTool = ToolMode.imageEdit;
        _selectedStrokeIds.clear(); // Limpa seleções antigas ao focar na foto nova
      });

      if (page.id != null) {
        await _repository.saveSingleImageBlock(page.id!, newImageBlock);
      }
    }
  }

  void _undo() {
    if (_pages.isEmpty) return;
    final currentPage = _pages[_currentPageIndex];
    if (currentPage.strokes.isNotEmpty) {
      setState(() {
        currentPage.redoHistory.add(currentPage.strokes.removeLast());
      });
    }
  }

  void _redo() {
    if (_pages.isEmpty) return;
    final currentPage = _pages[_currentPageIndex];
    if (currentPage.redoHistory.isNotEmpty) {
      final strokeToRestore = currentPage.redoHistory.removeLast();
      setState(() {
        currentPage.strokes.add(strokeToRestore);
      });
      if (currentPage.id != null) {
        _repository.saveSingleStroke(currentPage.id!, strokeToRestore);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFD6D6D6),
        appBar: _buildAppBar(false),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const CircularProgressIndicator(color: Color(0xFF0F4C5C)),
              const SizedBox(height: 16),
              Text('A carregar folhas...', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      );
    }

    final bool hasPages = _pages.isNotEmpty;
    final LocalPage? currentPage = hasPages ? _pages[_currentPageIndex] : null;
    final Size baseSize = _paperSizes[widget.paperSize] ?? const Size(595, 842);

    return Scaffold(
      backgroundColor: const Color(0xFFD6D6D6),
      appBar: _buildAppBar(hasPages),
      body: !hasPages
          ? _buildEmptyState()
          : Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPageIndex = index),
            itemBuilder: (context, index) {
              final page = _pages[index];
              final Size currentPageSize = page.isLandscape ? Size(baseSize.height, baseSize.width) : baseSize;

              final bool isDrawingBlocked = _currentTool == ToolMode.pan ||
                  _currentTool == ToolMode.text ||
                  _currentTool == ToolMode.imageEdit;

              final bool canTapCanvas = _currentTool == ToolMode.text || _currentTool == ToolMode.eraser;

              return InteractiveViewer.builder(
                scaleEnabled: _currentTool == ToolMode.pan,
                panEnabled: _currentTool == ToolMode.pan,
                maxScale: 6.0,
                minScale: 0.1,
                transformationController: page.transformationController,
                boundaryMargin: const EdgeInsets.all(3000),
                builder: (context, viewport) {
                  return Center(
                    child: Container(
                      width: currentPageSize.width,
                      height: currentPageSize.height,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFBF7),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: ClipRect(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [

                            RepaintBoundary(
                              child: CustomPaint(
                                size: currentPageSize,
                                willChange: false,
                                painter: StaticNotebookPainter(
                                  strokes: const [],
                                  lineType: _liveLineType,
                                  selectedStrokeIds: const {},
                                  selectionRect: null,
                                ),
                              ),
                            ),

                            ...(page.imageBlocks ?? []).map((img) {
                              final bool isImageMode = _currentTool == ToolMode.imageEdit;

                              return Positioned(
                                key: ValueKey('img_${img.id}'),
                                left: img.position.dx,
                                top: img.position.dy,
                                child: SizedBox(
                                  width: img.width + 24,
                                  height: img.height + 24,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [
                                      Positioned(
                                        left: 0,
                                        top: 0,
                                        width: img.width,
                                        height: img.height,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: isImageMode ? Border.all(color: const Color(0xFF0F4C5C), width: 2.0) : null,
                                          ),
                                          child: Image.file(img.imageFile, fit: BoxFit.fill),
                                        ),
                                      ),

                                      if (isImageMode) ...[
                                        Positioned(
                                          left: (img.width / 2) - 22,
                                          top: (img.height / 2) - 22,
                                          width: 44,
                                          height: 44,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onPanUpdate: (d) => setState(() => img.position += d.delta),
                                            onPanEnd: (d) {
                                              if (page.id != null) _repository.saveSingleImageBlock(page.id!, img);
                                            },
                                            child: const CircleAvatar(
                                              backgroundColor: Color(0xFF0F4C5C),
                                              child: Icon(Icons.open_with, size: 20, color: Colors.white),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: img.width - 22,
                                          top: img.height - 22,
                                          width: 44,
                                          height: 44,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onPanUpdate: (d) => setState(() {
                                              img.width = (img.width + d.delta.dx).clamp(80.0, 900.0);
                                              img.height = (img.height + d.delta.dy).clamp(80.0, 900.0);
                                            }),
                                            onPanEnd: (d) {
                                              if (page.id != null) _repository.saveSingleImageBlock(page.id!, img);
                                            },
                                            child: Center(
                                              child: Container(
                                                width: 30,
                                                height: 30,
                                                decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                                                child: const Icon(Icons.open_in_full, size: 14, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                        Positioned(
                                          left: img.width - 22,
                                          top: -22,
                                          width: 44,
                                          height: 44,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onTap: () => _deleteImageBlock(page, img),
                                            child: Center(
                                              child: Container(
                                                width: 30,
                                                height: 30,
                                                decoration: const BoxDecoration(color: Colors.redAccent, shape: BoxShape.circle),
                                                child: const Icon(Icons.close, size: 16, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }),

                            Positioned.fill(
                              child: IgnorePointer(
                                ignoring: _currentTool == ToolMode.imageEdit || _currentTool == ToolMode.pan,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapUp: canTapCanvas ? (details) {
                                    if (_activeInlineTarget != InlineTarget.none) _finishEditingInline(page);

                                    if (_currentTool == ToolMode.text) {
                                      final newBlock = TextBlock(
                                        text: '',
                                        position: details.localPosition,
                                        isBold: false,
                                        isItalic: false,
                                        isUnderline: false,
                                        textColorHex: _selectedColorHex,
                                        fontSize: 18.0,
                                      );
                                      setState(() {
                                        page.textBlocks.add(newBlock);
                                        _activeInlineTarget = InlineTarget.block;
                                        _activeTextBlock = newBlock;
                                        _textController.text = '';
                                      });
                                      _textFocusNode.requestFocus();
                                    } else if (_currentTool == ToolMode.eraser) {
                                      _eraseAtPosition(details.localPosition, page);
                                    }
                                  } : null,
                                  onPanStart: !isDrawingBlocked ? (details) {
                                    final localPos = details.localPosition;
                                    if (_currentTool == ToolMode.draw) {
                                      _activePointsNotifier.value = [localPos];
                                      page.undoHistory.clear();
                                      page.redoHistory.clear();
                                    } else if (_currentTool == ToolMode.select) {
                                      bool clickedOnSelected = false;
                                      for (var id in _selectedStrokeIds) {
                                        final matches = page.strokes.where((s) => s.id == id);
                                        if (matches.isNotEmpty) {
                                          final stroke = matches.first;
                                          for (var pt in stroke.points) {
                                            if ((pt - localPos).distance < 25.0) {
                                              clickedOnSelected = true;
                                              break;
                                            }
                                          }
                                        }
                                        if (clickedOnSelected) break;
                                      }

                                      if (clickedOnSelected) {
                                        _isMovingStrokes = true;
                                        _lastPanOffset = localPos;
                                      } else {
                                        _isMovingStrokes = false;
                                        _selectionRectStart = localPos;
                                        _selectionRectEnd = localPos;
                                        setState(() => _selectedStrokeIds.clear());
                                      }
                                    } else if (_currentTool == ToolMode.eraser) {
                                      _eraseAtPosition(localPos, page);
                                    }
                                  } : null,
                                  onPanUpdate: !isDrawingBlocked ? (details) {
                                    final localPos = details.localPosition;
                                    if (_currentTool == ToolMode.draw) {
                                      final currentList = _activePointsNotifier.value;
                                      if (currentList.isEmpty || (localPos - currentList.last).distance > 1.5) {
                                        _activePointsNotifier.value = List.from(currentList)..add(localPos);
                                      }
                                    } else if (_currentTool == ToolMode.select) {
                                      if (_isMovingStrokes && _lastPanOffset != null) {
                                        final delta = localPos - _lastPanOffset!;
                                        setState(() {
                                          for (var id in _selectedStrokeIds) {
                                            final matches = page.strokes.where((s) => s.id == id);
                                            if (matches.isNotEmpty) {
                                              final stroke = matches.first;
                                              for (int i = 0; i < stroke.points.length; i++) {
                                                stroke.points[i] = stroke.points[i] + delta;
                                              }
                                            }
                                          }
                                        });
                                        _lastPanOffset = localPos;
                                      } else if (_selectionRectStart != null) {
                                        setState(() {
                                          _selectionRectEnd = localPos;
                                          final rect = Rect.fromPoints(_selectionRectStart!, _selectionRectEnd!);
                                          _selectedStrokeIds.clear();
                                          for (var stroke in page.strokes) {
                                            for (var pt in stroke.points) {
                                              if (rect.contains(pt)) {
                                                _selectedStrokeIds.add(stroke.id);
                                                break;
                                              }
                                            }
                                          }
                                        });
                                      }
                                    } else if (_currentTool == ToolMode.eraser) {
                                      _eraseAtPosition(localPos, page);
                                    }
                                  } : null,
                                  onPanEnd: !isDrawingBlocked ? (details) {
                                    if (_currentTool == ToolMode.draw) {
                                      final newStroke = Stroke(
                                        color: _selectedColorHex,
                                        thickness: _selectedThickness,
                                        points: List.from(_activePointsNotifier.value),
                                      );
                                      setState(() => page.strokes.add(newStroke));
                                      _activePointsNotifier.value = [];
                                      if (page.id != null) {
                                        _repository.saveSingleStroke(page.id!, newStroke);
                                      }
                                    } else if (_currentTool == ToolMode.select) {
                                      setState(() {
                                        _isMovingStrokes = false;
                                        _selectionRectStart = null;
                                        _selectionRectEnd = null;
                                        _lastPanOffset = null;
                                      });
                                    }
                                  } : null,
                                  child: RepaintBoundary(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CustomPaint(
                                          size: currentPageSize,
                                          isComplex: true,
                                          willChange: false,
                                          painter: StaticNotebookPainter(
                                            strokes: page.strokes,
                                            lineType: 'none',
                                            selectedStrokeIds: _selectedStrokeIds,
                                            selectionRect: _selectionRectStart != null && _selectionRectEnd != null
                                                ? Rect.fromPoints(_selectionRectStart!, _selectionRectEnd!)
                                                : null,
                                          ),
                                        ),
                                        ValueListenableBuilder<List<Offset>>(
                                          valueListenable: _activePointsNotifier,
                                          builder: (context, activePoints, child) => CustomPaint(
                                            size: currentPageSize,
                                            painter: ActiveStrokePainter(
                                              currentPoints: activePoints,
                                              currentColor: _selectedColorHex,
                                              currentThickness: _selectedThickness,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // =======================================================
                            // 📝 CAMADA 4: BLOCOS DE TEXTO LIVRE (Calibrado ISO Moleskine)
                            // =======================================================
                            ...page.textBlocks.map((tb) {
                              final bool isEditing = tb == _activeTextBlock && _activeInlineTarget == InlineTarget.block;

                              // 🚀 CÁLCULO 1: O passo matemático exato da pauta física
                              final double physicalLineStep = _liveLineType == 'grid' ? 25.0 : 28.0;
                              final double exactLineMulti = physicalLineStep / tb.fontSize;

                              // 🚀 CÁLCULO 2: Estica a caixa até à margem direita (com trava mínima de segurança de 60px)
                              final double paperRightEnd = (currentPageSize.width - tb.position.dx - 20.0).clamp(60.0, currentPageSize.width);

                              return Positioned(
                                left: tb.position.dx,
                                top: tb.position.dy,
                                width: paperRightEnd, // <--- O SEGREDO DA LINHA INTEIRA
                                child: GestureDetector(
                                  onPanUpdate: _currentTool == ToolMode.text && !isEditing
                                      ? (details) => setState(() => tb.position += details.delta)
                                      : null,
                                  onTap: _currentTool == ToolMode.text && !isEditing ? () {
                                    if (_activeInlineTarget != InlineTarget.none) _finishEditingInline(page);
                                    setState(() {
                                      _activeInlineTarget = InlineTarget.block;
                                      _activeTextBlock = tb;
                                      _textController.text = tb.text;
                                    });
                                    _textFocusNode.requestFocus();
                                  } : null,
                                  child: isEditing
                                      ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: const Color(0xFF0F4C5C).withOpacity(0.5)),
                                    ),
                                    child: TextField(
                                      controller: _textController,
                                      focusNode: _textFocusNode,
                                      maxLines: null,
                                      autofocus: true,
                                      style: GoogleFonts.inter(
                                        fontSize: tb.fontSize,
                                        height: exactLineMulti, // <--- O ÍMAN MÁGICO DE PAUTA
                                        fontWeight: tb.isBold ? FontWeight.bold : FontWeight.normal,
                                        fontStyle: tb.isItalic ? FontStyle.italic : FontStyle.normal,
                                        decoration: tb.isUnderline ? TextDecoration.underline : TextDecoration.none,
                                        color: Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF'))),
                                      ),
                                      decoration: const InputDecoration(
                                        isDense: true,
                                        contentPadding: EdgeInsets.zero,
                                        border: InputBorder.none,
                                        hintText: 'Escreva aqui na linha...',
                                      ),
                                      onChanged: (val) => tb.text = val,
                                    ),
                                  )
                                      : Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 2),
                                    decoration: BoxDecoration(
                                      border: _currentTool == ToolMode.text
                                          ? Border.all(color: Colors.blueAccent.withOpacity(0.2))
                                          : null,
                                    ),
                                    child: Text(
                                      tb.text,
                                      style: GoogleFonts.inter(
                                        fontSize: tb.fontSize,
                                        height: exactLineMulti, // <--- O ÍMAN MÁGICO DE PAUTA
                                        fontWeight: tb.isBold ? FontWeight.bold : FontWeight.normal,
                                        fontStyle: tb.isItalic ? FontStyle.italic : FontStyle.normal,
                                        decoration: tb.isUnderline ? TextDecoration.underline : TextDecoration.none,
                                        color: Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF'))),
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),

                            Positioned(
                              top: 30,
                              left: 40,
                              right: 40,
                              child: Center(
                                child: _activeInlineTarget == InlineTarget.title
                                    ? TextField(
                                  controller: _textController,
                                  focusNode: _textFocusNode,
                                  autofocus: true,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24)),
                                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Título da Folha...', isDense: true),
                                  onSubmitted: (_) => _finishEditingInline(page),
                                )
                                    : GestureDetector(
                                  onTap: _currentTool == ToolMode.text ? () {
                                    if (_activeInlineTarget != InlineTarget.none) _finishEditingInline(page);
                                    setState(() {
                                      _activeInlineTarget = InlineTarget.title;
                                      _textController.text = page.title;
                                    });
                                    _textFocusNode.requestFocus();
                                  } : null,
                                  child: Text(
                                    page.title.isEmpty ? (_currentTool == ToolMode.text ? '[ Escrever Título ]' : '') : page.title,
                                    style: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.bold, color: page.title.isEmpty ? Colors.black26 : const Color(0xFF1A1A24)),
                                  ),
                                ),
                              ),
                            ),
                            Positioned(
                              bottom: 30,
                              left: 40,
                              right: 40,
                              child: Center(
                                child: _activeInlineTarget == InlineTarget.footer
                                    ? TextField(
                                  controller: _textController,
                                  focusNode: _textFocusNode,
                                  autofocus: true,
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.inter(fontSize: 12, color: Colors.black87),
                                  decoration: const InputDecoration(border: InputBorder.none, hintText: 'Rodapé...', isDense: true),
                                  onSubmitted: (_) => _finishEditingInline(page),
                                )
                                    : GestureDetector(
                                  onTap: _currentTool == ToolMode.text ? () {
                                    if (_activeInlineTarget != InlineTarget.none) _finishEditingInline(page);
                                    setState(() {
                                      _activeInlineTarget = InlineTarget.footer;
                                      _textController.text = page.footer;
                                    });
                                    _textFocusNode.requestFocus();
                                  } : null,
                                  child: Text(
                                    page.footer.isEmpty ? (_currentTool == ToolMode.text ? '[ Escrever Rodapé ]' : '') : page.footer,
                                    style: GoogleFonts.inter(fontSize: 12, color: page.footer.isEmpty ? Colors.black26 : Colors.black54),
                                  ),
                                ),
                              ),
                            ),

                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(child: _buildFloatingToolbar(currentPage!)),
          ),
        ],
      ),
      floatingActionButton: hasPages
          ? null
          : FloatingActionButton(
        backgroundColor: const Color(0xFF0F4C5C),
        foregroundColor: Colors.white,
        onPressed: _showAddPageDialog,
        child: const Icon(Icons.note_add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool hasPages) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: const IconThemeData(color: Color(0xFF1A1A24)),
      title: hasPages
          ? _buildAppBarDropdown()
          : Text(
        widget.notebookTitle,
        style: GoogleFonts.lora(color: const Color(0xFF1A1A24), fontWeight: FontWeight.bold, fontSize: 16),
      ),
      actions: [
        if (hasPages)
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFF27AE60)),
            tooltip: 'Guardar Caderno',
            onPressed: () async {
              await _repository.saveFullNotebook(widget.notebookId, _pages);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Caderno guardado!'), backgroundColor: Color(0xFF27AE60)),
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildAppBarDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: _currentPageIndex,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1A1A24)),
        selectedItemBuilder: (BuildContext context) {
          final List<Widget> selectedItems = _pages.asMap().entries.map<Widget>((entry) {
            return Container(
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.notebookTitle} - Folha ${entry.key + 1}/${_pages.length}',
                style: GoogleFonts.lora(color: const Color(0xFF1A1A24), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            );
          }).toList();

          selectedItems.add(const SizedBox.shrink());
          return selectedItems;
        },
        items: [
          ..._pages.asMap().entries.map((entry) => DropdownMenuItem<int>(
            value: entry.key,
            child: Text('Ir para Folha ${entry.key + 1}'),
          )),
          DropdownMenuItem<int>(
            value: _pages.length,
            child: const Row(
              children: [
                Icon(Icons.add, color: Color(0xFF0F4C5C)),
                SizedBox(width: 8),
                Text('Nova Folha'),
              ],
            ),
          ),
        ],
        onChanged: (int? newIndex) {
          if (newIndex != null) {
            if (newIndex == _pages.length) {
              _showAddPageDialog();
            } else {
              _pageController.animateToPage(
                newIndex,
                duration: const Duration(milliseconds: 350),
                curve: Curves.easeInOut,
              );
            }
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_page_break_outlined, size: 80, color: Colors.black.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            'Este caderno está vazio.\nClique no + para criar a primeira folha.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.black45, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, ToolMode mode, String tooltip) {
    final bool isActive = _currentTool == mode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0F4C5C).withOpacity(0.15) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        iconSize: 20,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: isActive ? const Color(0xFF0F4C5C) : const Color(0xFF1A1A24)),
        onPressed: () => _switchTool(mode), // 🚀 MÁGICA CHAMADA AQUI
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildCompactIconButton(IconData icon, VoidCallback? onPressed, String tooltip, Color color) {
    return IconButton(
      iconSize: 20,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
      icon: Icon(icon, color: color),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  Widget _buildFloatingToolbar(LocalPage currentPage) {
    if (_activeInlineTarget != InlineTarget.none) {
      return _buildInlineEditingToolbar(currentPage);
    }

    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;
    final bool hasImages = currentPage.imageBlocks.isNotEmpty;
    final bool isEraserActive = _currentTool == ToolMode.eraser;
    final bool isSelectActive = _currentTool == ToolMode.select;

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

          if (!isSmallScreen || isEraserActive)
            _buildToolButton(Icons.backspace_outlined, ToolMode.eraser, 'Borracha'),

          _buildToolButton(Icons.pan_tool, ToolMode.pan, 'Mover Folha'),
          _buildToolButton(Icons.text_fields, ToolMode.text, 'Texto'),

          if (!isSmallScreen || isSelectActive)
            _buildToolButton(Icons.highlight_alt, ToolMode.select, 'Selecionar Tinta'),

          if (!isSmallScreen)
            _buildCompactIconButton(Icons.add_photo_alternate_outlined, () => _pickAndInsertImage(currentPage), 'Adicionar Imagem', const Color(0xFF1A1A24)),

          if (hasImages)
            _buildToolButton(Icons.transform, ToolMode.imageEdit, 'Editar Imagem'),

          if (isSmallScreen)
            _buildCompactIconButton(Icons.undo, currentPage.strokes.isNotEmpty ? _undo : null, 'Desfazer', currentPage.strokes.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.3)),

          if (isSmallScreen)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A24)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFFFDFBF7),
              onSelected: (val) {
                if (val == 'insert_image') _pickAndInsertImage(currentPage);
                if (val == 'eraser') _switchTool(ToolMode.eraser); // 🚀 MÁGICA CHAMADA AQUI
                if (val == 'select') _switchTool(ToolMode.select); // 🚀 MÁGICA CHAMADA AQUI
                if (val == 'zoom_in') _zoom(1.2);
                if (val == 'zoom_out') _zoom(0.8);
                if (val == 'redo' && currentPage.redoHistory.isNotEmpty) _redo();
                if (val == 'delete_page') _confirmDeletePage(currentPage, _currentPageIndex);
                if (val == 'change_paper') _showPaperStyleStudioDialog();
              },
              itemBuilder: (context) => [
                const PopupMenuItem(value: 'insert_image', child: Row(children: [Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF0F4C5C)), SizedBox(width: 12), Text('Inserir Imagem')])),
                const PopupMenuItem(value: 'eraser', child: Row(children: [Icon(Icons.backspace_outlined, color: Color(0xFF1A1A24)), SizedBox(width: 12), Text('Borracha')])),
                const PopupMenuItem(value: 'select', child: Row(children: [Icon(Icons.highlight_alt, color: Color(0xFF1A1A24)), SizedBox(width: 12), Text('Selecionar Tinta')])),
                const PopupMenuDivider(),
                const PopupMenuItem(value: 'zoom_in', child: Row(children: [Icon(Icons.zoom_in, color: Color(0xFF1A1A24)), SizedBox(width: 12), Text('Aproximar (+)')])),
                const PopupMenuItem(value: 'zoom_out', child: Row(children: [Icon(Icons.zoom_out, color: Color(0xFF1A1A24)), SizedBox(width: 12), Text('Afastar (-)')])),
                const PopupMenuDivider(),
                const PopupMenuItem( value: 'change_paper',  child: Row(children: [Icon(Icons.grid_on, color: Color(0xFF0F4C5C)), SizedBox(width: 12), Text('Mudar Pauta do Papel')]),),
                PopupMenuItem(value: 'redo', enabled: currentPage.redoHistory.isNotEmpty, child: Row(children: [Icon(Icons.redo, color: currentPage.redoHistory.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey), const SizedBox(width: 12), const Text('Avançar')])),
                const PopupMenuItem(value: 'delete_page', child: Row(children: [Icon(Icons.delete_forever, color: Colors.redAccent), SizedBox(width: 12), Text('Rasgar Folha', style: TextStyle(color: Colors.redAccent))])),
              ],
            )
          else ...[
            // 🖥️ COMPORTAMENTO PC / TABLET (Ecrãs largos > 600px)
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),

            // 🚀 O BOTÃO QUE FALTAVA NO COMPUTADOR:
            _buildCompactIconButton(
              Icons.grid_on,
              _showPaperStyleStudioDialog,
              'Mudar Pauta do Papel',
              const Color(0xFF0F4C5C),
            ),
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildCompactIconButton(Icons.zoom_out, () => _zoom(0.8), 'Afastar', const Color(0xFF1A1A24)),
            _buildCompactIconButton(Icons.zoom_in, () => _zoom(1.2), 'Aproximar', const Color(0xFF1A1A24)),
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildCompactIconButton(Icons.undo, currentPage.strokes.isNotEmpty ? _undo : null, 'Desfazer', currentPage.strokes.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.5)),
            _buildCompactIconButton(Icons.redo, currentPage.redoHistory.isNotEmpty ? _redo : null, 'Avançar', currentPage.redoHistory.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.5)),
            _buildCompactIconButton(Icons.delete_forever, () => _confirmDeletePage(currentPage, _currentPageIndex), 'Rasgar Folha', Colors.redAccent),
          ],

          if (_currentTool == ToolMode.draw) ...[
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildColorButton(),
            _buildThicknessButton(),
          ],
        ],
      ),
    );
  }

  Widget _buildInlineEditingToolbar(LocalPage currentPage) {
    if (_activeInlineTarget == InlineTarget.title || _activeInlineTarget == InlineTarget.footer) {
      return Container(
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        decoration: BoxDecoration(color: const Color(0xFFFDFBF7), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFF0F4C5C).withOpacity(0.3))),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _activeInlineTarget == InlineTarget.title ? 'A editar Título da Página...' : 'A editar Rodapé...',
              style: GoogleFonts.inter(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.black54),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C), shape: const StadiumBorder(), minimumSize: const Size(60, 32)),
              onPressed: () => _finishEditingInline(currentPage),
              child: const Text('Concluir', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    }

    final tb = _activeTextBlock!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: const Color(0xFFFDFBF7), borderRadius: BorderRadius.circular(30), border: Border.all(color: const Color(0xFF0F4C5C).withOpacity(0.3))),
      child: Wrap(
        spacing: 4, crossAxisAlignment: WrapCrossAlignment.center, alignment: WrapAlignment.center,
        children: [
          _buildCompactIconButton(Icons.format_bold, () => setState(() => tb.isBold = !tb.isBold), 'Negrito', tb.isBold ? const Color(0xFF0F4C5C) : Colors.black45),
          _buildCompactIconButton(Icons.format_italic, () => setState(() => tb.isItalic = !tb.isItalic), 'Itálico', tb.isItalic ? const Color(0xFF0F4C5C) : Colors.black45),
          _buildCompactIconButton(Icons.format_underlined, () => setState(() => tb.isUnderline = !tb.isUnderline), 'Sublinhado', tb.isUnderline ? const Color(0xFF0F4C5C) : Colors.black45),
          Container(width: 1, height: 20, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),

          _buildCompactIconButton(Icons.text_decrease, () => setState(() => tb.fontSize = (tb.fontSize - 2).clamp(10.0, 64.0)), 'Diminuir', Colors.black87),
          Text('${tb.fontSize.toInt()}', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold)),
          _buildCompactIconButton(Icons.text_increase, () => setState(() => tb.fontSize = (tb.fontSize + 2).clamp(10.0, 64.0)), 'Aumentar', Colors.black87),
          Container(width: 1, height: 20, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),

          ...['#1A1A24', '#E74C3C', '#27AE60', '#1976D2'].map((hex) {
            final bool isSelected = tb.textColorHex == hex;
            return GestureDetector(
              onTap: () => setState(() => tb.textColorHex = hex),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3), padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? const Color(0xFF0F4C5C) : Colors.transparent, width: 2)),
                child: CircleAvatar(radius: 7, backgroundColor: Color(int.parse(hex.replaceFirst('#', '0xFF')))),
              ),
            );
          }),

          IconButton(
            iconSize: 18, constraints: const BoxConstraints(minWidth: 32, minHeight: 32), padding: EdgeInsets.zero,
            icon: const Icon(Icons.palette_outlined, color: Color(0xFF0F4C5C)),
            tooltip: 'Roda de Cores para Texto',
            onPressed: _showTextColorStudioDialog,
          ),

          const SizedBox(width: 4),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C), shape: const StadiumBorder(), minimumSize: const Size(50, 30)),
            onPressed: () => _finishEditingInline(currentPage),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }

  void _showTextColorStudioDialog() {
    if (_activeTextBlock == null) return;
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cor do Texto', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 16, runSpacing: 16, alignment: WrapAlignment.center,
            children: _colorPalette.entries.map((entry) {
              final hex = '#${entry.value.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
              final isSelected = _activeTextBlock!.textColorHex == hex;
              return GestureDetector(
                onTap: () {
                  setState(() => _activeTextBlock!.textColorHex = hex);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? const Color(0xFF0F4C5C) : Colors.transparent, width: 2)),
                  child: CircleAvatar(radius: 16, backgroundColor: entry.value),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showColorStudioDialog() { /* ... */ }
  void _showThicknessStudioDialog() { /* ... */ }
  Widget _buildColorButton() => InkWell(onTap: _showColorStudioDialog, customBorder: const CircleBorder(), child: Container(width: 36, height: 36, alignment: Alignment.center, child: CircleAvatar(radius: 11, backgroundColor: Color(int.parse(_selectedColorHex.replaceFirst('#', '0xFF'))))));
  Widget _buildThicknessButton() => InkWell(onTap: _showThicknessStudioDialog, customBorder: const CircleBorder(), child: Container(width: 36, height: 36, alignment: Alignment.center, child: CircleAvatar(radius: 11, backgroundColor: Colors.black12, child: CircleAvatar(radius: (_selectedThickness / 1.5).clamp(2.0, 9.0), backgroundColor: const Color(0xFF1A1A24)))));
  // =========================================================================
  // 📐 ESTÚDIO DE PAUTA EM TEMPO REAL
  // =========================================================================
  void _showPaperStyleStudioDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Pauta do Papel', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildPaperOption('ruled', 'Pautado (28px)', Icons.view_headline),
            const SizedBox(height: 8),
            _buildPaperOption('grid', 'Quadriculado (25px)', Icons.grid_4x4),
            const SizedBox(height: 8),
            _buildPaperOption('blank', 'Liso / Em Branco', Icons.check_box_outline_blank),
          ],
        ),
      ),
    );
  }

  Widget _buildPaperOption(String type, String label, IconData icon) {
    final bool isSelected = _liveLineType == type;
    return InkWell(
      onTap: () {
        setState(() => _liveLineType = type);
        Navigator.pop(context);
        _repository.updateLineType(widget.notebookId, type); // Cimenta na Base de Dados!
      },
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFF0F4C5C).withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? const Color(0xFF0F4C5C) : Colors.black12, width: 1.5),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF0F4C5C) : Colors.black54),
            const SizedBox(width: 12),
            Text(label, style: GoogleFonts.inter(fontWeight: isSelected ? FontWeight.bold : FontWeight.w500, color: const Color(0xFF1A1A24))),
            const Spacer(),
            if (isSelected) const Icon(Icons.check_circle, color: Color(0xFF0F4C5C), size: 18),
          ],
        ),
      ),
    );
  }
}

Path _buildSmoothPath(List<Offset> points) {
  final path = Path();
  if (points.isEmpty) return path;
  path.moveTo(points.first.dx, points.first.dy);
  if (points.length == 1) { path.addOval(Rect.fromCircle(center: points.first, radius: 0.5)); return path; }
  for (int i = 1; i < points.length; i++) { path.lineTo(points[i].dx, points[i].dy); }
  return path;
}

// =========================================================================
// 🎨 PAINTER ESTÁTICO (Completo: Pautado, Quadriculado, Traços e Laço!)
// =========================================================================
class StaticNotebookPainter extends CustomPainter {
  final List<Stroke> strokes;
  final String lineType;
  final Set<String> selectedStrokeIds;
  final Rect? selectionRect;

  StaticNotebookPainter({
    required this.strokes,
    required this.lineType,
    required this.selectedStrokeIds,
    required this.selectionRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final Paint bgPaint = Paint()
      ..color = const Color(0xFF1B365D).withOpacity(0.18)
      ..strokeWidth = 1.0;

    // 1. Pauta Pautada (Linhas horizontais clássicas)
    if (lineType == 'ruled') {
      canvas.drawLine(
        const Offset(60, 0),
        Offset(60, size.height),
        Paint()..color = Colors.redAccent.withOpacity(0.4)..strokeWidth = 1.5,
      );
      for (double y = 90; y < size.height - 60; y += 28) {
        canvas.drawLine(Offset(60, y), Offset(size.width - 20, y), bgPaint);
      }
    }
    // 🚀 2. Pauta Quadriculada (Grelha X/Y restaurada!)
    else if (lineType == 'grid') {
      const double margin = 20.0;
      const double topMargin = 90.0;
      const double bottomMargin = 60.0;
      const double gridSize = 25.0;

      // Linhas Horizontais
      for (double y = topMargin; y < size.height - bottomMargin; y += gridSize) {
        canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), bgPaint);
      }
      // Linhas Verticais
      for (double x = margin; x < size.width - margin; x += gridSize) {
        canvas.drawLine(Offset(x, topMargin), Offset(x, size.height - bottomMargin), bgPaint);
      }
    }

    // 3. Desenho dos Traços + Efeito Neon de Seleção
    for (final stroke in strokes) {
      final bool isSelected = selectedStrokeIds.contains(stroke.id);

      final paint = Paint()
        ..color = Color(int.parse(stroke.color.replaceFirst('#', '0xFF')))
        ..strokeWidth = stroke.thickness
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      if (isSelected && stroke.points.isNotEmpty) {
        double minX = stroke.points.first.dx, maxX = stroke.points.first.dx;
        double minY = stroke.points.first.dy, maxY = stroke.points.first.dy;

        for (var pt in stroke.points) {
          if (pt.dx < minX) minX = pt.dx;
          if (pt.dx > maxX) maxX = pt.dx;
          if (pt.dy < minY) minY = pt.dy;
          if (pt.dy > maxY) maxY = pt.dy;
        }

        final Rect bounds = Rect.fromLTRB(minX - 6, minY - 6, maxX + 6, maxY + 6);
        canvas.drawRect(bounds, Paint()..color = const Color(0x220000FF)..style = PaintingStyle.fill);
        canvas.drawRect(bounds, Paint()..color = const Color(0xFF0000FF)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      }

      canvas.drawPath(_buildSmoothPath(stroke.points), paint);
    }

    // 4. O Quadrado Azul do Laço de Seleção
    if (selectionRect != null) {
      canvas.drawRect(selectionRect!, Paint()..color = const Color(0x190F4C5C)..style = PaintingStyle.fill);
      canvas.drawRect(selectionRect!, Paint()..color = const Color(0xFF0F4C5C)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant StaticNotebookPainter oldDelegate) => true;
}

class ActiveStrokePainter extends CustomPainter {
  final List<Offset> currentPoints;
  final String currentColor;
  final double currentThickness;

  ActiveStrokePainter({
    required this.currentPoints,
    required this.currentColor,
    required this.currentThickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (currentPoints.isEmpty) return;

    final paint = Paint()
      ..color = Color(int.parse(currentColor.replaceFirst('#', '0xFF')))
      ..strokeWidth = currentThickness
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(_buildSmoothPath(currentPoints), paint);
  }

  @override
  bool shouldRepaint(covariant ActiveStrokePainter oldDelegate) => true;
}