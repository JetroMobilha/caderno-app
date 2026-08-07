import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/handwriting_controller.dart';

class HandwritingTrainingScreen extends ConsumerStatefulWidget {
  const HandwritingTrainingScreen({super.key});

  @override
  ConsumerState<HandwritingTrainingScreen> createState() => _HandwritingTrainingScreenState();
}

class _HandwritingTrainingScreenState extends ConsumerState<HandwritingTrainingScreen> {
  final ValueNotifier<List<Offset>> _activePointsNotifier = ValueNotifier([]);

  @override
  void dispose() {
    _activePointsNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(handwritingProvider);
    final notifier = ref.read(handwritingProvider.notifier);
    
    // Lista de caracteres para treinar (A-Z, a-z, 0-9)
    final List<String> alphabet = [
      ...'ABCDEFGHIJKLMNOPQRSTUVWXYZ'.split(''),
      ...'abcdefghijklmnopqrstuvwxyz'.split(''),
      ...'0123456789'.split(''),
      '?', '!', '.', ',', ';', ':', '-', '+', '=', '@', '#', '%', '&', '*', '(', ')', '/', '\\'
    ];

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Minha Caligrafia ✍️', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Recarregar Progresso',
            onPressed: () => notifier.loadProgress(),
          ),
        ],
      ),
      body: Column(
        children: [
          // 📋 SELETOR DE CARACTERES (Horizontal)
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 12),
            color: AppColors.primary.withOpacity(0.05),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: alphabet.length,
              itemBuilder: (context, index) {
                final char = alphabet[index];
                final isSelected = state.currentCharacter == char;
                final isTrained = state.trainedCharacters.contains(char);
                
                return GestureDetector(
                  onTap: () => notifier.setCharacter(char),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 50,
                    margin: const EdgeInsets.only(right: 10),
                    decoration: BoxDecoration(
                      color: isSelected ? AppColors.primary : (isTrained ? AppColors.accent.withOpacity(0.2) : Colors.white),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? AppColors.primary : (isTrained ? AppColors.accent : Colors.grey.shade300),
                        width: 1.5,
                      ),
                      boxShadow: isSelected ? [BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
                    ),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        Text(
                          char,
                          style: GoogleFonts.inter(
                            fontSize: 22,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            color: isSelected ? Colors.white : (isTrained ? AppColors.accent : AppColors.textDark),
                          ),
                        ),
                        if (isTrained && !isSelected)
                          Positioned(
                            top: 4,
                            right: 4,
                            child: Icon(Icons.check_circle, size: 12, color: AppColors.accent),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          if (state.isLoading)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 8),
              child: LinearProgressIndicator(minHeight: 2),
            ),

          // ✍️ ÁREA DE DESENHO (Canvas)
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                children: [
                  Text(
                    'Desenha o caractere "${state.currentCharacter}" abaixo:',
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textDark),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: AppColors.paper,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.grey.shade300, width: 2),
                        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 15, offset: const Offset(0, 8))],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(24),
                        child: Stack(
                          children: [
                            // 1. Marca d'água do caractere (Fundo de tudo)
                            Center(
                              child: IgnorePointer(
                                child: Text(
                                  state.currentCharacter,
                                  style: TextStyle(
                                    fontSize: 260,
                                    fontWeight: FontWeight.w100,
                                    color: Colors.grey.withOpacity(0.04),
                                  ),
                                ),
                              ),
                            ),

                            // 2. Linhas de Guia (Pautas) - IgnorePointer para não bloquear desenhos
                            const Positioned.fill(
                              child: IgnorePointer(
                                child: CustomPaint(painter: _HandwritingGuideLines()),
                              ),
                            ),
                            
                            // 3. Canvas de Desenho Interativo (No topo para capturar 100% dos gestos)
                            Positioned.fill(
                              child: GestureDetector(
                                behavior: HitTestBehavior.opaque,
                                onPanStart: (details) {
                                  _activePointsNotifier.value = [details.localPosition];
                                },
                                onPanUpdate: (details) {
                                  final localPos = details.localPosition;
                                  final list = _activePointsNotifier.value;
                                  if (list.isEmpty || (localPos - list.last).distance > 1.2) {
                                    _activePointsNotifier.value = List<Offset>.from(list)..add(localPos);
                                  }
                                },
                                onPanEnd: (_) {
                                  if (_activePointsNotifier.value.isNotEmpty) {
                                    notifier.addFullStroke(List.from(_activePointsNotifier.value));
                                    _activePointsNotifier.value = [];
                                  }
                                },
                                child: Stack(
                                  children: [
                                    // Traços já finalizados
                                    CustomPaint(
                                      painter: _HandwritingPainter(strokes: state.currentStrokes),
                                      size: Size.infinite,
                                    ),
                                    // Traço ativo (em curso) - 🚀 Renderização ultra-fluida
                                    ValueListenableBuilder<List<Offset>>(
                                      valueListenable: _activePointsNotifier,
                                      builder: (context, points, _) => CustomPaint(
                                        painter: _HandwritingPainter(strokes: [points]),
                                        size: Size.infinite,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // 🎮 BOTÕES DE CONTROLO
                  Row(
                    children: [
                      _ActionButton(
                        icon: Icons.undo_rounded,
                        label: 'Desfazer',
                        color: Colors.orange.shade700,
                        onTap: state.currentStrokes.isEmpty ? null : () => notifier.undoLastStroke(),
                      ),
                      const SizedBox(width: 12),
                      _ActionButton(
                        icon: Icons.delete_outline_rounded,
                        label: 'Limpar',
                        color: Colors.redAccent,
                        onTap: state.currentStrokes.isEmpty ? null : () => notifier.clearCanvas(),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 54,
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.accent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                              elevation: 4,
                            ),
                            onPressed: (state.currentStrokes.isEmpty || state.isSaving) 
                                ? null 
                                : () async {
                                    final success = await notifier.saveCurrentCharacter();
                                    if (context.mounted && success) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Letra "${state.currentCharacter}" guardada! 🚀'),
                                          backgroundColor: AppColors.accent,
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    }
                                  },
                            icon: state.isSaving 
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                                : const Icon(Icons.cloud_upload_rounded),
                            label: Text(
                              state.isSaving ? 'A GUARDAR...' : 'GUARDAR CALIGRAFIA',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _ActionButton({required this.icon, required this.label, required this.color, this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: onTap == null ? Colors.grey.shade200 : color.withOpacity(0.1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(color: onTap == null ? Colors.grey.shade300 : color.withOpacity(0.3)),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: onTap == null ? Colors.grey : color, size: 24),
              const SizedBox(height: 4),
              Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: onTap == null ? Colors.grey : color)),
            ],
          ),
        ),
      ),
    );
  }
}

class _HandwritingPainter extends CustomPainter {
  final List<List<Offset>> strokes;

  _HandwritingPainter({required this.strokes});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.textDark
      ..strokeWidth = 4.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    for (final stroke in strokes) {
      if (stroke.isEmpty) continue;
      canvas.drawPath(_buildHandwritingPath(stroke), paint);
    }
  }

  Path _buildHandwritingPath(List<Offset> points) {
    final path = Path();
    if (points.isEmpty) return path;

    if (points.length < 3) {
      path.moveTo(points.first.dx, points.first.dy);
      for (var i = 1; i < points.length; i++) {
        path.lineTo(points[i].dx, points[i].dy);
      }
      if (points.length == 1) {
        path.addOval(Rect.fromCircle(center: points.first, radius: 0.1));
      }
      return path;
    }

    path.moveTo(points[0].dx, points[0].dy);

    // 🚀 INTERPOLAÇÃO POR CURVAS QUADRÁTICAS (Bézier) - Mesma lógica do Canvas principal
    for (int i = 1; i < points.length - 2; i++) {
      final xc = (points[i].dx + points[i + 1].dx) / 2;
      final yc = (points[i].dy + points[i + 1].dy) / 2;
      path.quadraticBezierTo(points[i].dx, points[i].dy, xc, yc);
    }

    path.quadraticBezierTo(
      points[points.length - 2].dx,
      points[points.length - 2].dy,
      points[points.length - 1].dx,
      points[points.length - 1].dy,
    );

    return path;
  }

  @override
  bool shouldRepaint(_HandwritingPainter oldDelegate) => true;
}

class _HandwritingGuideLines extends CustomPainter {
  const _HandwritingGuideLines();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withOpacity(0.2)
      ..strokeWidth = 1.0;

    final dashPaint = Paint()
      ..color = Colors.blue.withOpacity(0.1)
      ..strokeWidth = 1.0;

    // Linha de Topo (Ascendentes)
    canvas.drawLine(Offset(0, size.height * 0.2), Offset(size.width, size.height * 0.2), paint);
    
    // Linha Média (X-Height) - Mais visível para letras minúsculas
    _drawDashedLine(canvas, Offset(0, size.height * 0.45), Offset(size.width, size.height * 0.45), dashPaint);
    
    // Linha de Base (Baseline) - 🟥 VERMELHA E FORTE (Onde a letra senta)
    canvas.drawLine(
      Offset(0, size.height * 0.75), 
      Offset(size.width, size.height * 0.75), 
      Paint()..color = Colors.red.withOpacity(0.4)..strokeWidth = 2.0
    );
    
    // Linha de Descida (Descendentes: p, g, q, j)
    canvas.drawLine(Offset(0, size.height * 0.9), Offset(size.width, size.height * 0.9), paint);
  }

  void _drawDashedLine(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double dashWidth = 5, dashSpace = 5;
    double distance = (end - start).distance;
    double currentDist = 0;
    while (currentDist < distance) {
      canvas.drawLine(
        start + Offset(currentDist, 0),
        start + Offset(currentDist + dashWidth, 0),
        paint,
      );
      currentDist += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(_HandwritingGuideLines oldDelegate) => false;
}
