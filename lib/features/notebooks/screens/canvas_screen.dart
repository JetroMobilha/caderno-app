import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/drawing_point_model.dart';

// 🚀 MODELO DE ESTADO INDEPENDENTE PARA CADA FOLHA
class LocalPage {
  final bool isLandscape;
  List<Stroke> strokes = [];
  List<Stroke> undoHistory = [];

  // Cada folha agora é dona absoluta da sua própria câmara e nível de zoom
  late TransformationController transformationController;

  LocalPage({required this.isLandscape}) {
    transformationController = TransformationController();
  }

  void dispose() {
    transformationController.dispose();
  }
}

class CanvasScreen extends StatefulWidget {
  final String notebookTitle;
  final String lineType;
  final String paperSize;

  const CanvasScreen({
    super.key,
    required this.notebookTitle,
    this.lineType = 'ruled',
    required this.paperSize,
  });

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  List<LocalPage> _pages = [];
  int _currentPageIndex = 0;
  List<Offset> _currentPoints = [];

  String _selectedColorHex = '#2C3E50';
  double _selectedThickness = 3.0;

  bool _isDrawingMode = true;
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

  final Map<String, Color> _colorPalette = {
    'Azul': const Color(0xFF2C3E50),
    'Preto': const Color(0xFF1A1A24),
    'Vermelho': const Color(0xFFE74C3C),
    'Verde': const Color(0xFF27AE60),
  };

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
      setState(() => currentPage.undoHistory.add(currentPage.strokes.removeLast()));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool hasPages = _pages.isNotEmpty;
    final LocalPage? currentPage = hasPages ? _pages[_currentPageIndex] : null;

    Size baseSize = _paperSizes[widget.paperSize] ?? const Size(595, 842);
    final Size pageSize = (currentPage?.isLandscape ?? false) ? Size(baseSize.height, baseSize.width) : baseSize;

    return Scaffold(
      backgroundColor: const Color(0xFFD6D6D6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A24)),
        title: hasPages
            ? DropdownButtonHideUnderline(
          child: DropdownButton<int>(
            value: _currentPageIndex,
            icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1A1A24)),
            // 🚀 ALINHAMENTO DE TIPAGEM COESO: Evita o erro de subtipo do SizedBox/Container
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

              selectedItems.add(const SizedBox.shrink()); // Elemento fantasma para balancear a lista
              return selectedItems;
            },
            items: [
              ..._pages.asMap().entries.map((entry) {
                return DropdownMenuItem<int>(
                  value: entry.key,
                  child: Text('Ir para Folha ${entry.key + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
                );
              }),
              // 🚀 COMPACTAÇÃO DE INTERFACE: Adicionar folha embutida como último item da lista
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
                  _pageController.animateToPage(
                      newIndex,
                      duration: const Duration(milliseconds: 350),
                      curve: Curves.easeInOut
                  );
                }
              }
            },
          ),
        )
            : Text(
          widget.notebookTitle,
          style: GoogleFonts.lora(color: const Color(0xFF1A1A24), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          if (hasPages && !_isToolbarVisible)
            IconButton(
              icon: const Icon(Icons.build_circle, color: Color(0xFF0F4C5C)),
              onPressed: () => setState(() => _isToolbarVisible = true),
              tooltip: 'Mostrar Ferramentas',
            ),
          if (hasPages) ...[
            IconButton(
              icon: Icon(_isDrawingMode ? Icons.brush : Icons.pan_tool, color: const Color(0xFF0F4C5C)),
              onPressed: () => setState(() => _isDrawingMode = !_isDrawingMode),
              tooltip: _isDrawingMode ? 'Modo Caneta' : 'Modo Mover / Zoom',
            ),
            IconButton(
              icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
              onPressed: () => setState(() => currentPage!.strokes.clear()),
              tooltip: 'Limpar Folha',
            ),
            IconButton(
              icon: const Icon(Icons.undo, size: 20, color: Color(0xFF2C3E50)),
              onPressed: currentPage!.strokes.isNotEmpty ? _undo : null,
              tooltip: 'Desfazer',
            ),
          ]
        ],
      ),
      body: !hasPages
          ? Center(
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
      )
          : Stack(
        children: [
          // 🚀 MOTOR DE ANIMAÇÃO ENTRE FOLHAS PRESERVANDO O ZOOM INDIVIDUAL
          PageView.builder(
            controller: _pageController,
            physics: _isDrawingMode ? const NeverScrollableScrollPhysics() : const BouncingScrollPhysics(),
            itemCount: _pages.length,
            onPageChanged: (index) {
              setState(() {
                _currentPageIndex = index;
              });
            },
            itemBuilder: (context, index) {
              final page = _pages[index];
              final Size currentPageSize = page.isLandscape ? Size(baseSize.height, baseSize.width) : baseSize;

              return InteractiveViewer.builder(
                scaleEnabled: !_isDrawingMode,
                panEnabled: !_isDrawingMode,
                maxScale: 6.0,
                minScale: 0.1,
                transformationController: page.transformationController, // Atua na folha isolada
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
                        onPanStart: _isDrawingMode ? (details) {
                          setState(() {
                            _currentPoints = [details.localPosition];
                            page.undoHistory.clear();
                          });
                        } : null,
                        onPanUpdate: _isDrawingMode ? (details) {
                          setState(() => _currentPoints.add(details.localPosition));
                        } : null,
                        onPanEnd: _isDrawingMode ? (details) {
                          setState(() {
                            page.strokes.add(
                              Stroke(
                                color: _selectedColorHex,
                                thickness: _selectedThickness,
                                points: List.from(_currentPoints),
                              ),
                            );
                            _currentPoints.clear();
                          });
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

          // TOOLBAR POPUP COMPACTA SUPERIOR (MANTÉM-SE ESTÁTICA ENQUANTO AS FOLHAS DESLIZAM)
          if (_isToolbarVisible)
            Positioned(
              top: 10,
              left: 16,
              right: 16,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
                    ],
                  ),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            _isToolbarPinned ? Icons.push_pin : Icons.push_pin_outlined,
                            size: 18,
                            color: _isToolbarPinned ? const Color(0xFF0F4C5C) : Colors.black45,
                          ),
                          onPressed: () => setState(() => _isToolbarPinned = !_isToolbarPinned),
                          tooltip: _isToolbarPinned ? 'Desfixar Barra' : 'Fixar Barra',
                        ),
                        const SizedBox(height: 24, child: VerticalDivider(thickness: 1, color: Colors.black12)),
                        PopupMenuButton<String>(
                          icon: CircleAvatar(
                            radius: 10,
                            backgroundColor: Color(int.parse(_selectedColorHex.replaceFirst('#', '0xFF'))),
                          ),
                          tooltip: 'Selecionar Cor',
                          onSelected: (hex) => setState(() => _selectedColorHex = hex),
                          itemBuilder: (context) => _colorPalette.entries.map((entry) {
                            final hex = '#${entry.value.value.toRadixString(16).substring(2).toUpperCase()}';
                            return PopupMenuItem<String>(
                              value: hex,
                              child: Row(
                                children: [
                                  CircleAvatar(radius: 8, backgroundColor: entry.value),
                                  const SizedBox(width: 12),
                                  Text(entry.key, style: GoogleFonts.inter(fontSize: 13)),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 24, child: VerticalDivider(thickness: 1, color: Colors.black12)),
                        PopupMenuButton<double>(
                          icon: const Icon(Icons.line_weight, size: 18, color: Color(0xFF2C3E50)),
                          tooltip: 'Espessura da Caneta',
                          onSelected: (thickness) => setState(() => _selectedThickness = thickness),
                          itemBuilder: (context) => [1.5, 3.0, 5.0, 8.0].map((value) {
                            return PopupMenuItem<double>(
                              value: value,
                              child: Text('${value.toInt()} px', style: GoogleFonts.inter(fontSize: 13)),
                            );
                          }).toList(),
                        ),
                        if (!_isToolbarPinned) ...[
                          const SizedBox(height: 24, child: VerticalDivider(thickness: 1, color: Colors.black12)),
                          IconButton(
                            icon: const Icon(Icons.close, size: 18, color: Colors.redAccent),
                            onPressed: () => setState(() => _isToolbarVisible = false),
                            tooltip: 'Esconder Barra',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),

          // BOTÕES FLUTUANTES DE ZOOM (CANTO INFERIOR DIREITO)
          Positioned(
            bottom: 20,
            right: 20,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                FloatingActionButton.small(
                  heroTag: 'zoom_in_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F4C5C),
                  onPressed: () => _zoom(1.2),
                  child: const Icon(Icons.zoom_in),
                ),
                const SizedBox(height: 8),
                FloatingActionButton.small(
                  heroTag: 'zoom_out_btn',
                  backgroundColor: Colors.white,
                  foregroundColor: const Color(0xFF0F4C5C),
                  onPressed: () => _zoom(0.8),
                  child: const Icon(Icons.zoom_out),
                ),
              ],
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
}

class NotebookPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset> currentPoints;
  final String currentColor;
  final double currentThickness;
  final String lineType;

  NotebookPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentThickness,
    required this.lineType,
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

    for (final stroke in strokes) {
      final paint = Paint()
        ..color = Color(int.parse(stroke.color.replaceFirst('#', '0xFF')))
        ..strokeWidth = stroke.thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

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
  }

  @override
  bool shouldRepaint(covariant NotebookPainter oldDelegate) => true;
}