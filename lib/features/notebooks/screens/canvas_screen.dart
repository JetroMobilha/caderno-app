import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/drawing_point_model.dart';
import '../repositories/notebook_repository.dart';


class CanvasScreen extends StatefulWidget {
  final int notebookId; // 🚀 ADICIONADO
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

// 🚀 NOVO: Máquina de Estados clara para as ferramentas principais
enum ToolMode { draw, pan, select }

class _CanvasScreenState extends State<CanvasScreen> {
  List<LocalPage> _pages = [];
  int _currentPageIndex = 0;
  List<Offset> _currentPoints = [];

  // 🚀 ATUALIZADO: A variável que controla a ferramenta ativa
  ToolMode _currentTool = ToolMode.draw;

  final Set<String> _selectedStrokeIds = {};
  Offset? _selectionRectStart;
  Offset? _selectionRectEnd;
  bool _isMovingStrokes = false;
  Offset? _lastPanOffset;

  String _selectedColorHex = '#2C3E50';
  double _selectedThickness = 3.0;


  bool _isToolbarVisible = true;
  bool _isToolbarPinned = true;

  // Controlador do motor de animação e deslize horizontal das folhas
  final PageController _pageController = PageController(initialPage: 0);

  // 📐 DIMENSÕES ISO PURAS PARA EXPORTAÇÃO MILIMÉTRICA EM PDF
  final Map<String, Size> _paperSizes = {
    'A5': const Size(420, 595),
    'A4': const Size(595, 842),
    'A3': const Size(842, 1191),
    'A2': const Size(1191, 1684),
    'A1': const Size(1684, 2384),
    'A0': const Size(2384, 3370),
  };

  // 🚀 EXPANDIDO: Palete de Cores Alargada (9 Cores Premium)
  final Map<String, Color> _colorPalette = {
    'Azul': const Color(0xFF2C3E50),
    'Preto': const Color(0xFF1A1A24),
    'Vermelho': const Color(0xFFE74C3C),
    'Verde': const Color(0xFF27AE60),
    'Laranja': const Color(0xFFE67E22),
    'Roxo': const Color(0xFF9B59B6),
    'Rosa': const Color(0xFFE91E63),
    'Amarelo': const Color(0xFFF1C40F),
    'Ciano': const Color(0xFF1ABC9C),
  };

  // 🚀 EXPANDIDO: Lista de Traços Suportados de 1px até 30px
  final List<double> _thicknessOptions = [1.0, 2.0, 3.5, 5.0, 7.5, 10.0, 15.0, 20.0, 30.0];

  @override
  void dispose() {
    _pageController.dispose();
    // Limpa os controladores de zoom de todas as páginas para evitar vazamentos de memória
    for (var page in _pages) {
      page.dispose();
    }
    super.dispose();
  }

  // Define a escala inicial ideal sem quebrar as proporções do papel
  void _resetZoomForPage(LocalPage page, String paperSize) {
    final double initialScale = paperSize == 'A0' || paperSize == 'A1' ? 0.25 : 1.4;
    page.transformationController.value = Matrix4.identity()..scale(initialScale);
  }

  // Controla o Zoom via Botão focado na página que está atualmente visível
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

  // Diálogo para escolher a orientação da nova folha
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
                onChanged: (value) => setModalState(() => selectedIsLandscape = value!),
              ),
              RadioListTile<bool>(
                title: const Text('Paisagem (Horizontal)'),
                value: true,
                groupValue: selectedIsLandscape,
                onChanged: (value) => setModalState(() => selectedIsLandscape = value!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C)),
              onPressed: () {
                final newPage = LocalPage(isLandscape: selectedIsLandscape);
                _resetZoomForPage(newPage, widget.paperSize);

                setState(() {
                  _pages.add(newPage);
                });
                Navigator.pop(context);

                // Desliza com animação realista até à folha recém-criada
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

  void _undo() {
    if (_pages.isEmpty) return;
    final currentPage = _pages[_currentPageIndex];
    if (currentPage.strokes.isNotEmpty) {
      setState(() {
        // Remove do ecrã e atira para o "futuro" (redo)
        currentPage.redoHistory.add(currentPage.strokes.removeLast());
      });
    }
  }

  // 🚀 NOVA: Função para Avançar linhas
  void _redo() {
    if (_pages.isEmpty) return;
    final currentPage = _pages[_currentPageIndex];
    if (currentPage.redoHistory.isNotEmpty) {
      setState(() {
        // Puxa do "futuro" de volta para o ecrã
        currentPage.strokes.add(currentPage.redoHistory.removeLast());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPages = _pages.isNotEmpty;
    final LocalPage? currentPage = hasPages ? _pages[_currentPageIndex] : null;

    final Size baseSize = _paperSizes[widget.paperSize] ?? const Size(595, 842);
    final Size pageSize = (currentPage?.isLandscape ?? false)
        ? Size(baseSize.height, baseSize.width)
        : baseSize;

    return Scaffold(
      backgroundColor: const Color(0xFFD6D6D6),
      appBar: _buildAppBar(hasPages),
      body: !hasPages
          ? _buildEmptyState()
          : Stack(
        children: [
          // 🚀 MOTOR DE RENDERIZAÇÃO DE FOLHAS ANIMADAS
          PageView.builder(
            controller: _pageController,
            // 🚀 Bloqueia o deslize de página a menos que estejamos no modo de mover a folha
            physics: _currentTool == ToolMode.pan ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPageIndex = index),
            itemBuilder: (context, index) {
              final page = _pages[index];
              final Size currentPageSize = page.isLandscape ? Size(baseSize.height, baseSize.width) : baseSize;

              return InteractiveViewer.builder(
                // 🚀 A folha só é movível se a ferramenta Mão estiver ativa!
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
                      child: GestureDetector(
                        // 🚀 Se a ferramenta Mão estiver ativa, o GestureDetector é desativado (retorna null)
                        onPanStart: _currentTool != ToolMode.pan ? (details) {
                          final localPos = details.localPosition;
                          if (_currentTool == ToolMode.draw) {
                            setState(() {
                              _currentPoints = [localPos];
                              page.undoHistory.clear();
                              page.redoHistory.clear();
                            });
                          } else if (_currentTool == ToolMode.select) {
                            bool clickedOnSelected = false;
                            for (var id in _selectedStrokeIds) {
                              final stroke = page.strokes.firstWhere((s) => s.id == id);
                              for (var pt in stroke.points) {
                                if ((pt - localPos).distance < 25.0) {
                                  clickedOnSelected = true;
                                  break;
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
                          }
                        } : null,
                        onPanUpdate: _currentTool != ToolMode.pan ? (details) {
                          final localPos = details.localPosition;
                          if (_currentTool == ToolMode.draw) {
                            setState(() => _currentPoints.add(localPos));
                          } else if (_currentTool == ToolMode.select) {
                            if (_isMovingStrokes && _lastPanOffset != null) {
                              final delta = localPos - _lastPanOffset!;
                              setState(() {
                                for (var id in _selectedStrokeIds) {
                                  final stroke = page.strokes.firstWhere((s) => s.id == id);
                                  for (int i = 0; i < stroke.points.length; i++) {
                                    stroke.points[i] = stroke.points[i] + delta;
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
                          }
                        } : null,
                        onPanEnd: _currentTool != ToolMode.pan ? (details) {
                          if (_currentTool == ToolMode.draw) {
                            setState(() {
                              page.strokes.add(
                                Stroke(color: _selectedColorHex, thickness: _selectedThickness, points: List.from(_currentPoints)),
                              );
                              _currentPoints.clear();
                            });
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
                          child: CustomPaint(
                            key: const Key('canvas_custom_paint'),
                            size: currentPageSize,
                            painter: NotebookPainter(
                              strokes: page.strokes,
                              currentPoints: _currentPoints,
                              currentColor: _selectedColorHex,
                              currentThickness: _selectedThickness,
                              lineType: widget.lineType,
                              selectedStrokeIds: _selectedStrokeIds,
                              selectionRect: _selectionRectStart != null && _selectionRectEnd != null
                                  ? Rect.fromPoints(_selectionRectStart!, _selectionRectEnd!)
                                  : null,
                            ),
                          ),
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
            child: Center(
              child: _buildFloatingToolbar(currentPage!),
            ),
          ),
        ],
      ),
      floatingActionButton: hasPages ? null : FloatingActionButton(
        backgroundColor: const Color(0xFF0F4C5C),
        foregroundColor: Colors.white,
        onPressed: _showAddPageDialog,
        child: const Icon(Icons.note_add),
      ),
    );
  }

  // 🛠️ MÉTODOS DE EXTRAÇÃO DE LAYOUT (Estilo de Código Flutter Limpo e Declarativo)

  PreferredSizeWidget _buildAppBar(bool hasPages) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: const IconThemeData(color: Color(0xFF1A1A24)),
      title: hasPages ? _buildAppBarDropdown() : Text(widget.notebookTitle, style: GoogleFonts.lora(color: const Color(0xFF1A1A24), fontWeight: FontWeight.bold, fontSize: 16)),
      actions: [
        if (hasPages)
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFF27AE60)),
            tooltip: 'Guardar Caderno',
            onPressed: () async {
              final repo = NotebookRepository();
              await repo.saveFullNotebook(widget.notebookId, _pages);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Caderno guardado localmente!'), backgroundColor: Color(0xFF27AE60)),
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
          List<Widget> selectedItems = _pages.asMap().entries.map<Widget>((entry) {
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
          ..._pages.asMap().entries.map((entry) {
            return DropdownMenuItem<int>(
              value: entry.key,
              child: Text('Ir para Folha ${entry.key + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            );
          }),
          DropdownMenuItem<int>(
            value: _pages.length,
            child: Row(
              children: [
                const Icon(Icons.add, size: 18, color: Color(0xFF0F4C5C)),
                const SizedBox(width: 8),
                Text('Nova Folha', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
              ],
            ),
          ),
        ],
        onChanged: (int? newIndex) {
          if (newIndex != null) {
            if (newIndex == _pages.length) {
              _showAddPageDialog();
            } else {
              _pageController.animateToPage(newIndex, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
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
            'Este caderno está vazio.\nClique no + para adicionar a primeira folha.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.black45, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // 🚀 CONSTRUTOR DE BOTÃO DE FERRAMENTA (Mostra claramente qual está ativa)
  Widget _buildToolButton(IconData icon, ToolMode mode, String tooltip) {
    final isActive = _currentTool == mode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0F4C5C).withOpacity(0.15) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: Icon(icon, color: isActive ? const Color(0xFF0F4C5C) : const Color(0xFF1A1A24)),
        onPressed: () => setState(() {
          _currentTool = mode;
          if (mode != ToolMode.select) _selectedStrokeIds.clear();
        }),
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildFloatingToolbar(LocalPage currentPage) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 🚀 AS 3 FERRAMENTAS PRINCIPAIS LADO A LADO
          _buildToolButton(Icons.brush, ToolMode.draw, 'Caneta'),
          _buildToolButton(Icons.highlight_alt, ToolMode.select, 'Selecionar e Mover'),
          _buildToolButton(Icons.pan_tool, ToolMode.pan, 'Mover Folha / Zoom'),

          const SizedBox(height: 24, child: VerticalDivider(thickness: 1, color: Colors.black12)),
          IconButton(
            icon: const Icon(Icons.zoom_out, color: Color(0xFF1A1A24)),
            onPressed: () => _zoom(0.8),
            tooltip: 'Afastar',
          ),
          IconButton(
            icon: const Icon(Icons.zoom_in, color: Color(0xFF1A1A24)),
            onPressed: () => _zoom(1.2),
            tooltip: 'Aproximar',
          ),
          IconButton(
            icon: Icon(
                Icons.undo,
                color: currentPage.strokes.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.5)
            ),
            onPressed: currentPage.strokes.isNotEmpty ? _undo : null,
            tooltip: 'Desfazer Traço',
          ),
          IconButton(
            icon: Icon(
                Icons.redo,
                color: currentPage.redoHistory.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.5)
            ),
            onPressed: currentPage.redoHistory.isNotEmpty ? _redo : null,
            tooltip: 'Avançar Traço',
          ),
          // Botão: Apagar Tudo (Agora com proteção e desativado se já estiver vazio)
          IconButton(
            icon: Icon(Icons.delete_sweep, color: currentPage.strokes.isNotEmpty ? Colors.redAccent : Colors.grey),
            onPressed: currentPage.strokes.isNotEmpty ? () => _confirmClearPage(currentPage) : null,
            tooltip: 'Apagar Toda a Folha',
          ),
          const SizedBox(height: 24, child: VerticalDivider(thickness: 1, color: Colors.black12)),
          _buildMoreToolsDropdown(),
        ],
      ),
    );
  }

  Widget _buildMoreToolsDropdown() {
    return PopupMenuButton<String>(
      icon: const Icon(Icons.more_vert, color: Color(0xFF0F4C5C)),
      tooltip: 'Mais Ferramentas',
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      offset: const Offset(0, -180),
      // Modifica o itemBuilder do PopupMenuButton para atualizar as espessuras e a ação de seleção:
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Text('Cores da Caneta', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
        ),
        PopupMenuItem(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _colorPalette.entries.map((entry) {
              final hex = '#${entry.value.value.toRadixString(16).substring(2).toUpperCase()}';
              final isSelected = _selectedColorHex == hex;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedColorHex = hex);
                  Navigator.pop(context);
                },
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: isSelected ? Colors.black45 : Colors.transparent, width: 2),
                  ),
                  child: CircleAvatar(radius: 12, backgroundColor: entry.value),
                ),
              );
            }).toList(),
          ),
        ),
        const PopupMenuDivider(),
        PopupMenuItem(
          enabled: false,
          child: Text('Espessura', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
        ),
        PopupMenuItem(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              // Usando a nova lista estendida de espessuras
              children: _thicknessOptions.map((t) {
                final isSelected = _selectedThickness == t;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedThickness = t);
                    Navigator.pop(context);
                  },
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
                    ),
                    child: CircleAvatar(radius: 10, backgroundColor: Colors.white, child: Container(width: t/2 + 2, height: t/2 + 2, decoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle))),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const PopupMenuDivider(),

      ],

    );
  }

  // 🚀 REDE DE SEGURANÇA: Diálogo para confirmar a limpeza da folha
  void _confirmClearPage(LocalPage page) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Apagar Folha', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 18)),
          ],
        ),
        content: Text(
            'Tem a certeza que deseja apagar todos os traços desta folha?\n(Poderá anular esta ação depois usando o botão Voltar).',
            style: GoogleFonts.inter(fontSize: 14)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                // Guarda o estado atual no histórico antes de apagar, permitindo o "Desfazer"
                page.undoHistory.addAll(page.strokes);
                page.strokes.clear();
                page.redoHistory.clear();
              });
              Navigator.pop(context); // Fecha o diálogo
            },
            child: const Text('Apagar Tudo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class NotebookPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset> currentPoints;
  final String currentColor;
  final double currentThickness;
  final String lineType;
  final Set<String> selectedStrokeIds; // 🚀 NOVO
  final Rect? selectionRect; // 🚀 NOVO

  NotebookPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentThickness,
    required this.lineType,
    required this.selectedStrokeIds,
    required this.selectionRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = const Color(0xFF1B365D).withOpacity(0.18)
      ..strokeWidth = 1.0;

    if (lineType == 'ruled') {
      for (double y = 40; y < size.height; y += 28) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), backgroundPaint);
      }
    } else if (lineType == 'grid') {
      const double gridSize = 25.0;
      for (double y = gridSize; y < size.height; y += gridSize) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), backgroundPaint);
      }
      for (double x = gridSize; x < size.width; x += gridSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), backgroundPaint);
      }
    }

    // Desenha todos os traços salvos
    for (final stroke in strokes) {
      final isSelected = selectedStrokeIds.contains(stroke.id);

      final paint = Paint()
        ..color = Color(int.parse(stroke.color.replaceFirst('#', '0xFF')))
        ..strokeWidth = stroke.thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Se o traço estiver selecionado, desenha primeiro uma caixa azul de destaque por baixo
      if (isSelected && stroke.points.isNotEmpty) {
        double minX = stroke.points.first.dx, maxX = stroke.points.first.dx;
        double minY = stroke.points.first.dy, maxY = stroke.points.first.dy;
        for (var pt in stroke.points) {
          if (pt.dx < minX) minX = pt.dx; if (pt.dx > maxX) maxX = pt.dx;
          if (pt.dy < minY) minY = pt.dy; if (pt.dy > maxY) maxY = pt.dy;
        }
        final bounds = Rect.fromLTRB(minX - 6, minY - 6, maxX + 6, maxY + 6);
        canvas.drawRect(bounds, Paint()..color = const Color(0x220000FF)..style = PaintingStyle.fill);
        canvas.drawRect(bounds, Paint()..color = const Color(0xFF0000FF)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      }

      for (int i = 0; i < stroke.points.length - 1; i++) {
         canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    // Linha atual que está a ser desenhada
    if (currentPoints.length > 1) {
      final activePaint = Paint()
        ..color = Color(int.parse(currentColor.replaceFirst('#', '0xFF')))
        ..strokeWidth = currentThickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (int i = 0; i < currentPoints.length - 1; i++) {
        canvas.drawLine(currentPoints[i], currentPoints[i + 1], activePaint);
      }
    }

    // 🚀 Desenha o retângulo semi-transparente do arrasto do Lasso de Caixa
    if (selectionRect != null) {
      canvas.drawRect(selectionRect!, Paint()..color = const Color(0x190F4C5C)..style = PaintingStyle.fill);
      canvas.drawRect(selectionRect!, Paint()..color = const Color(0xFF0F4C5C)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant NotebookPainter oldDelegate) => true;
}