import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../models/canvas_enums.dart';

/// 🚀 v10.19: Estúdio Profissional de Pincel (3 Níveis de Propriedades).
class ThicknessStudioDialog extends ConsumerStatefulWidget {
  const ThicknessStudioDialog({super.key});

  @override
  ConsumerState<ThicknessStudioDialog> createState() => _ThicknessStudioDialogState();
}

class _ThicknessStudioDialogState extends ConsumerState<ThicknessStudioDialog> {
  late double _thickness;
  late double _opacity;
  late double _smoothing;
  late PalmRejectionMode _palmMode;

  @override
  void initState() {
    super.initState();
    final state = ref.read(canvasInteractionProvider);
    _thickness = state.selectedThickness;
    _opacity = state.brushOpacity;
    _smoothing = state.smoothingLevel;
    _palmMode = state.palmRejectionMode;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text('ESTÚDIO DE TRAÇO', style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 18)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 2. Espessura
            _buildLabel('Espessura', '${_thickness.toStringAsFixed(1)} px'),
            Slider(
              value: _thickness, min: 1, max: 30,
              activeColor: const Color(0xFF0F4C5C),
              onChanged: (v) => setState(() => _thickness = v),
            ),

            // 3. Opacidade
            _buildLabel('Opacidade', '${(_opacity * 100).toInt()}%'),
            Slider(
              value: _opacity, min: 0.1, max: 1.0,
              activeColor: const Color(0xFF0F4C5C),
              onChanged: (v) => setState(() => _opacity = v),
            ),

            // Suavização
            _buildLabel('Suavização do Traço', '${(_smoothing * 100).toInt()}%'),
            Slider(
              value: _smoothing, min: 0.0, max: 1.0,
              activeColor: Colors.blueAccent,
              onChanged: (v) => setState(() => _smoothing = v),
            ),

            const Divider(height: 32),

            // Palm Rejection
            const Text('✋ Palm Rejection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
            const SizedBox(height: 8),
            SegmentedButton<PalmRejectionMode>(
              segments: const [
                ButtonSegment(value: PalmRejectionMode.auto, label: Text('Auto'), icon: Icon(Icons.brightness_auto)),
                ButtonSegment(value: PalmRejectionMode.enabled, label: Text('On'), icon: Icon(Icons.check_circle_outline)),
                ButtonSegment(value: PalmRejectionMode.disabled, label: Text('Off'), icon: Icon(Icons.cancel_outlined)),
              ],
              selected: {_palmMode},
              onSelectionChanged: (set) => setState(() => _palmMode = set.first),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCELAR')),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C), foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
          onPressed: () {
            final notifier = ref.read(canvasInteractionProvider.notifier);
            notifier.setThickness(_thickness);
            notifier.setBrushOpacity(_opacity);
            notifier.setSmoothingLevel(_smoothing);
            notifier.setPalmRejectionMode(_palmMode);
            Navigator.pop(context);
          },
          child: const Text('APLICAR'),
        ),
      ],
    );
  }

  Widget _buildLabel(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, left: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.black54)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F4C5C))),
        ],
      ),
    );
  }
}
