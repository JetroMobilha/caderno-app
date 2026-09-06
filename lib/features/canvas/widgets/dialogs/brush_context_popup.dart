import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../shared/widgets/color_engine_widget.dart';
import '../../providers/canvas_tool_provider.dart';
import 'brush_style_sheet.dart';
import '../../models/canvas_enums.dart';

class BrushContextPopup extends ConsumerWidget {
  final Offset position;

  const BrushContextPopup({super.key, required this.position});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolState = ref.watch(canvasToolProvider);
    final toolNotifier = ref.read(canvasToolProvider.notifier);

    final List<String> quickColors = [
      '#1A1A24', '#E53935', '#1976D2', '#27AE60', '#F39C12', '#6A1B9A', '#D81B60', '#0F4C5C'
    ];

    return Material(
      color: Colors.transparent,
      child: Stack(
        children: [
          // Overlay para fechar ao clicar fora
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(color: Colors.transparent, width: double.infinity, height: double.infinity),
          ),
          Positioned(
            left: (position.dx - 140).clamp(10, MediaQuery.of(context).size.width - 290),
            // 🚀 v1.10: Posicionado exatamente ACIMA do dedo com margem de segurança
            top: (position.dy - 260).clamp(10, MediaQuery.of(context).size.height - 300),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 280,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 20, offset: const Offset(0, 8))
                    ],
                    border: Border.all(color: Colors.black.withOpacity(0.05)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // 🚀 v1.12: Topo limpo com botão de estilos intuitivo
                      Row(
                        children: [
                          const Icon(Icons.line_weight_rounded, size: 18, color: Color(0xFF0F4C5C)),
                          const SizedBox(width: 10),
                          const Text('ESPESSURA', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 11, color: Color(0xFF0F4C5C))),
                          const Spacer(),
                          // 🚀 Ícone mais intuitivo (Várias canetas)
                          IconButton(
                            onPressed: () {
                              Navigator.pop(context);
                              showModalBottomSheet(
                                context: context,
                                backgroundColor: Colors.transparent,
                                isScrollControlled: true,
                                builder: (_) => const BrushStyleSheet(),
                              );
                            },
                            icon: const Icon(Icons.auto_awesome_motion_rounded, size: 22, color: Color(0xFF0F4C5C)),
                            tooltip: 'Trocar Estilo da Caneta',
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),

                      // 🚀 v1.13: Preview Dinâmico de Espessura
                      Center(
                        child: Container(
                          width: 50, height: 50,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.03),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Container(
                              width: toolState.selectedThickness.clamp(1.0, 45.0),
                              height: toolState.selectedThickness.clamp(1.0, 45.0),
                              decoration: BoxDecoration(
                                color: Color(int.parse(toolState.selectedColorHex.replaceFirst('#', '0xFF'))),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Slider de Espessura
                      SliderTheme(
                        data: SliderThemeData(
                          activeTrackColor: const Color(0xFF0F4C5C),
                          thumbColor: const Color(0xFF0F4C5C),
                          overlayColor: const Color(0xFF0F4C5C).withOpacity(0.12),
                          trackHeight: 4,
                        ),
                        child: Slider(
                          value: toolState.selectedThickness,
                          min: 1, max: 60,
                          onChanged: (v) => toolNotifier.setThickness(v),
                        ),
                      ),
                      
                      const Divider(height: 32),

                      // Paleta de Cores Rápidas
                      _buildQuickColors(context, toolState, toolNotifier, quickColors),

                      const SizedBox(height: 20),

                      // 🚀 v1.12: 7 Seletores Rápidos e Sem Botão redundante em baixo
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [1, 2, 3, 5, 8, 14, 30].map((size) => GestureDetector(
                          onTap: () {
                            toolNotifier.setThickness(size.toDouble());
                            Navigator.pop(context);
                          },
                          child: Container(
                            width: 32, height: 32,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: toolState.selectedThickness.toInt() == size ? const Color(0xFF0F4C5C) : Colors.black.withOpacity(0.04),
                              shape: BoxShape.circle,
                            ),
                            child: Text(size.toString(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: toolState.selectedThickness.toInt() == size ? Colors.white : Colors.black54)),
                          ),
                        )).toList(),
                      ),
                    ],
                  ),
                ),
                // 🚀 Seta indicadora (Aponte para o dedo)
                CustomPaint(
                  size: const Size(20, 10),
                  painter: _ArrowPainter(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
  Widget _buildQuickColors(BuildContext context, CanvasToolState toolState, CanvasToolNotifier toolNotifier, List<String> colors) {
    return Row(
      children: [
        Expanded(
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: colors.map((hex) {
                final bool isSelected = toolState.selectedColorHex.toUpperCase() == hex.toUpperCase();
                return GestureDetector(
                  onTap: () => toolNotifier.setColor(hex),
                  child: Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: Color(int.parse(hex.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: isSelected ? Border.all(color: Colors.white, width: 2) : null,
                        boxShadow: isSelected ? [BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
                      ),
                      child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        // Botão Estúdio HSV
        GestureDetector(
          onTap: () async {
            final newColor = await ColorEngine.show(context, initialColor: toolState.selectedColorHex, title: 'Estúdio de Cor');
            if (newColor != null) {
              toolNotifier.setColor(newColor);
              if (context.mounted) Navigator.pop(context);
            }
          },
          child: Container(
            width: 32, height: 32,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(colors: [Colors.red, Colors.yellow, Colors.green, Colors.cyan, Colors.blue, Colors.black54, Colors.red]),
            ),
            child: const Icon(Icons.palette_rounded, size: 16, color: Colors.white),
          ),
        ),
      ],
    );
  }


class _ArrowPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white..style = PaintingStyle.fill;
    final path = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width / 2, size.height)
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
