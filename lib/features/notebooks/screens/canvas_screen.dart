import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/drawing_point_model.dart';

class LocalPage {
  final bool isLandscape;
  List<Stroke> strokes = [];
  List<Stroke> undoHistory = [];

  LocalPage({required this.isLandscape});
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

  late TransformationController _transformationController;

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
  void initState() {
    super.initState();
    _transformationController = TransformationController();
    _resetZoom();
  }

  void _resetZoom() {
    final double initialScale = widget.paperSize == 'A0' || widget.paperSize == 'A1' ? 0.25 : 1.4;
    _transformationController.value = Matrix4.identity()..scale(initialScale);
  }

  @override
  void dispose() {
    _transformationController.dispose();
    super.dispose();
  }

  void _zoom(double factor) {
    setState(() {
      final Matrix4 matrix = _transformationController.value;
      final double currentScale = matrix.getMaxScaleOnAxis();
      if (currentScale * factor < 0.1 || currentScale * factor > 6.0) return;

      final Size screenSize = MediaQuery.of(context).size;
      final double centerX = screenSize.width / 2;
      final double centerY = screenSize.height / 2;

      matrix.translate(centerX, centerY);
      matrix.scale(factor);
      matrix.translate(-centerX, -centerY);

      _transformationController.value = matrix;
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
                setState(() {
                  _pages.add(LocalPage(isLandscape: selectedIsLandscape));
                  _currentPageIndex = _pages.length - 1;
                  _resetZoom();
                });
                Navigator.pop(context);
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
        title: Text(
          hasPages ? '${widget.notebookTitle} - Folha ${_currentPageIndex + 1}/${_pages.length}' : widget.notebookTitle,
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
          InteractiveViewer.builder(
            scaleEnabled: !_isDrawingMode,
            panEnabled: !_isDrawingMode,
            maxScale: 6.0,
            minScale: 0.1,
            transformationController: _transformationController,
            boundaryMargin: const EdgeInsets.all(3000),
            builder: (context, viewport) {
              return Center(
                child: Container(
                  width: pageSize.width,
                  height: pageSize.height,
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
                        currentPage!.undoHistory.clear();
                      });
                    } : null,
                    onPanUpdate: _isDrawingMode ? (details) {
                      setState(() => _currentPoints.add(details.localPosition));
                    } : null,
                    onPanEnd: _isDrawingMode ? (details) {
                      setState(() {
                        currentPage!.strokes.add(
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
                        size: pageSize,
                        painter: NotebookPainter(
                          strokes: currentPage!.strokes,
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
          ),

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

          // ZOOM FLUTUANTE
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

          // 🚀 PAINEL DE NAVEGAÇÃO E CRIAÇÃO DE MÚLTIPLAS FOLHAS (Canto Inferior Esquerdo)
          if (hasPages)
            Positioned(
              bottom: 20,
              left: 20,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  FloatingActionButton.small(
                    heroTag: 'prev_page_btn',
                    backgroundColor: _currentPageIndex > 0 ? Colors.white : Colors.grey[300],
                    foregroundColor: const Color(0xFF0F4C5C),
                    onPressed: _currentPageIndex > 0 ? () => setState(() => _currentPageIndex--) : null,
                    child: const Icon(Icons.arrow_back_ios_new, size: 16),
                  ),
                  const SizedBox(width: 8),
                  FloatingActionButton.small(
                    heroTag: 'next_page_btn',
                    backgroundColor: _currentPageIndex < _pages.length - 1 ? Colors.white : Colors.grey[300],
                    foregroundColor: const Color(0xFF0F4C5C),
                    onPressed: _currentPageIndex < _pages.length - 1 ? () => setState(() => _currentPageIndex++) : null,
                    child: const Icon(Icons.arrow_forward_ios, size: 16),
                  ),
                  const SizedBox(width: 16),
                  // 🚀 NOVO: Botão para adicionar mais folhas a qualquer momento!
                  FloatingActionButton.extended(
                    heroTag: 'add_more_pages_btn',
                    backgroundColor: const Color(0xFF0F4C5C),
                    foregroundColor: Colors.white,
                    onPressed: _showAddPageDialog,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text('Nova Folha', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
        ],
      ),
      // Mostra o botão grande central APENAS se o caderno estiver totalmente vazio
      floatingActionButton: hasPages ? null : FloatingActionButton(
        backgroundColor: const Color(0xFF0F4C5C),
        foregroundColor: Colors.white,
        onPressed: _showAddPageDialog,
        child: const Icon(Icons.note_add),
      ),
    );
  }
}

// O NotebookPainter mantém-se perfeitamente igual
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