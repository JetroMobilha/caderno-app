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
  // Lista que guarda todos os traços finalizados e o traço atual
  List<Stroke> _strokes = [];
  List<Offset> _currentPoints = [];

  // Configurações padrão da caneta digital (Azul Tinta)
  final String _selectedColorHex = '#2C3E50';
  final double _selectedThickness = 3.0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Folha de papel creme
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
      body: GestureDetector(
        // 1. O utilizador toca no ecrã: Iniciamos um novo traço
        onPanStart: (details) {
          setState(() {
            _currentPoints = [details.localPosition];
          });
        },
        // 2. O utilizador arrasta o dedo: Vamos empilhando as coordenadas cartesianas
        onPanUpdate: (details) {
          setState(() {
            _currentPoints.add(details.localPosition);
          });
        },
        // 3. O utilizador levanta o dedo: Fechamos o Traço e guardamos na lista estruturada
        onPanEnd: (details) {
          setState(() {
            _strokes.add(
              Stroke(
                color: _selectedColorHex,
                thickness: _selectedThickness,
                points: List.from(_currentPoints),
              ),
            );
            _currentPoints.clear(); // Limpa o rascunho para o próximo traço
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
    );
  }
}

/// O "Pincel" da nossa aplicação que desenha os píxeis no ecrã em tempo real
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
    // Desenhar primeiro as linhas pautadas (o fundo do caderno físico)
    final linePaint = Paint()
      ..color = Colors.blue.withOpacity(0.08)
      ..strokeWidth = 1.0;

    for (double y = 40; y < size.height; y += 28) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);
    }

    // Configuração para desenhar os traços guardados
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = Color(int.parse(stroke.color.replaceFirst('#', '0xFF')))
        ..strokeWidth = stroke.thickness
        ..strokeCap = StrokeCap.round // Ponta da caneta arredondada (suave)
        ..strokeJoin = StrokeJoin.round;

      for (int i = 0; i < stroke.points.length - 1; i++) {
        canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    // Desenhar o traço que está a acontecer em tempo real
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