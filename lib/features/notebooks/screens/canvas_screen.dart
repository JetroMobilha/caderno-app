import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/drawing_point_model.dart';

class CanvasScreen extends StatefulWidget {
  final String notebookTitle;

  const CanvasScreen({super.key, required this.notebookTitle});

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

class _CanvasScreenState extends State<CanvasScreen> {
  List<Stroke> _strokes = [];
  List<Offset> _currentPoints = [];

  String _selectedColorHex = '#2C3E50';
  double _selectedThickness = 3.0;

  final Map<String, Color> _colorPalette = {
    'Azul': const Color(0xFF2C3E50),
    'Preto': const Color(0xFF1A1A24),
    'Vermelho': const Color(0xFFE74C3C),
    'Verde': const Color(0xFF27AE60),
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A24)),
        title: Text(
          widget.notebookTitle,
          style: GoogleFonts.lora(color: const Color(0xFF1A1A24), fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
            onPressed: () => setState(() => _strokes = []),
            tooltip: 'Limpar Página',
          ),
        ],
      ),
      body: Stack(
        children: [
          GestureDetector(
            onPanStart: (details) {
              setState(() {
                _currentPoints = [details.localPosition];
              });
            },
            onPanUpdate: (details) {
              setState(() {
                _currentPoints.add(details.localPosition);
              });
            },
            onPanEnd: (details) {
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
            },
            child: RepaintBoundary(
              child: CustomPaint(
                size: Size.infinite,
                painter: NotebookPainter(
                  strokes: _strokes,
                  currentPoints: _currentPoints,
                  currentColor: _selectedColorHex,
                  currentThickness: _selectedThickness,
                ),
              ),
            ),
          ),

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
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
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
                              border: Border.all(
                                color: isSelected ? Colors.blue : Colors.transparent,
                                width: 2,
                              ),
                            ),
                            padding: const EdgeInsets.all(2),
                            child: CircleAvatar(
                              radius: 12,
                              backgroundColor: entry.value,
                            ),
                          ),
                        ),
                      );
                    }),
                    // 🚀 CORREÇÃO: Envolvemos o VerticalDivider num SizedBox com altura fixa!
                    const SizedBox(
                      height: 24,
                      child: VerticalDivider(thickness: 1, color: Colors.black12),
                    ),
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
}

// 🚀 CORREÇÃO: NotebookPainter reintroduzido no escopo global do ficheiro
class NotebookPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset> currentPoints;
  final String currentColor;
  final double currentThickness;

  NotebookPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentThickness,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = Colors.blue.withOpacity(0.08)
      ..strokeWidth = 1.0;

    for (double y = 40; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
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