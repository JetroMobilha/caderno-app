import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/drawing_point_model.dart';

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
  List<Stroke> _strokes = [];
  List<Stroke> _undoHistory = [];
  List<Offset> _currentPoints = [];

  String _selectedColorHex = '#2C3E50';
  double _selectedThickness = 3.0;

  bool _isLandscape = false;
  bool _isDrawingMode = true;

  // 🚀 NOVO: Controlador de transformação persistente na memória do State
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
    // 🚀 INICIALIZAÇÃO ÚNICA: Define o zoom inicial padrão sem resetar nos setStates futuros
    _transformationController = TransformationController();

    final double initialScale = widget.paperSize == 'A0' || widget.paperSize == 'A1' ? 0.25 : 1.4;
    _transformationController.value = Matrix4.identity()..scale(initialScale);
  }

  @override
  void dispose() {
    // Evita vazamentos de memória ao fechar o caderno
    _transformationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    Size baseSize = _paperSizes[widget.paperSize] ?? const Size(595, 842);
    final Size pageSize = _isLandscape ? Size(baseSize.height, baseSize.width) : baseSize;

    return Scaffold(
      backgroundColor: const Color(0xFFD6D6D6),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 1,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A24)),
        title: Text(
          '${widget.notebookTitle} (${widget.paperSize})',
          style: GoogleFonts.lora(color: const Color(0xFF1A1A24), fontWeight: FontWeight.bold, fontSize: 16),
        ),
        actions: [
          IconButton(
            icon: Icon(_isDrawingMode ? Icons.brush : Icons.pan_tool, color: const Color(0xFF0F4C5C)),
            onPressed: () => setState(() => _isDrawingMode = !_isDrawingMode),
            tooltip: _isDrawingMode ? 'Modo Caneta Ativo' : 'Modo Mover Ativo',
          ),
          IconButton(
            icon: const Icon(Icons.screen_rotation, color: Color(0xFF0F4C5C)),
            onPressed: () => setState(() => _isLandscape = !_isLandscape),
            tooltip: 'Rodar Folha',
          ),
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: () => setState(() => _strokes = []),
            tooltip: 'Limpar Página',
          ),
          IconButton(
            icon: const Icon(Icons.undo, size: 20, color: Color(0xFF2C3E50)),
            onPressed: _strokes.isNotEmpty ? _undo : null,
            tooltip: 'Desfazer',
          ),
        ],
      ),
      body: Stack(
        children: [
          InteractiveViewer.builder(
            scaleEnabled: !_isDrawingMode,
            panEnabled: !_isDrawingMode,
            maxScale: 6.0,
            minScale: 0.1,
            // 🚀 CORREÇÃO: Passa a referência da instância estável em vez de criar uma nova
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
                        _undoHistory.clear();
                      });
                    } : null,
                    onPanUpdate: _isDrawingMode ? (details) {
                      setState(() {
                        _currentPoints.add(details.localPosition);
                      });
                    } : null,
                    onPanEnd: _isDrawingMode ? (details) {
                      setState(() {
                        _strokes.add(
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
                          strokes: _strokes,
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

          // Toolbar Flutuante Superior (Igual)
          Positioned(
            top: 10,
            left: 20,
            right: 20,
            child: Center(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5)),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Formato: ${widget.paperSize}',
                      style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C)),
                    ),
                    const SizedBox(width: 8),
                    const SizedBox(height: 24, child: VerticalDivider(thickness: 1, color: Colors.black12)),
                    const SizedBox(width: 8),
                    ..._colorPalette.entries.map((entry) {
                      final hexString = '#${entry.value.value.toRadixString(16).substring(2).toUpperCase()}';
                      final isSelected = _selectedColorHex == hexString;
                      return GestureDetector(
                        onTap: () => setState(() => _selectedColorHex = hexString),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 6),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: isSelected ? Colors.blue : Colors.transparent, width: 2),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: CircleAvatar(radius: 12, backgroundColor: entry.value),
                          ),
                        ),
                      );
                    }),
                    const SizedBox(height: 24, child: VerticalDivider(thickness: 1, color: Colors.black12)),
                    const SizedBox(width: 8),
                    DropdownButton<double>(
                      value: _selectedThickness,
                      underline: const SizedBox(),
                      icon: const Icon(Icons.line_weight, size: 20, color: Color(0xFF2C3E50)),
                      items: [1.5, 3.0, 5.0, 8.0].map((double value) {
                        return DropdownMenuItem<double>(
                          value: value,
                          child: Text('${value.toInt()}px', style: GoogleFonts.inter(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (newValue) {
                        if (newValue != null) {
                          setState(() => _selectedThickness = newValue);
                        }
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _undo() {
    if (_strokes.isNotEmpty) {
      setState(() => _undoHistory.add(_strokes.removeLast()));
    }
  }
}

// O NotebookPainter mantém-se igual e intocado
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