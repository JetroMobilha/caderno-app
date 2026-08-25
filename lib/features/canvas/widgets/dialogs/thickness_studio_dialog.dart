import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_tool_provider.dart';

class ThicknessStudioDialog extends ConsumerStatefulWidget {
  const ThicknessStudioDialog({super.key});

  @override
  ConsumerState<ThicknessStudioDialog> createState() => _ThicknessStudioDialogState();
}

class _ThicknessStudioDialogState extends ConsumerState<ThicknessStudioDialog> {
  late double _tempThickness;
  late bool _isHighlighter;

  @override
  void initState() {
    super.initState();
    final toolState = ref.read(canvasToolProvider);
    _tempThickness = toolState.selectedThickness;
    _isHighlighter = toolState.isHighlighter;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Configurações do Lápis'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('Espessura'),
          Slider(
            value: _tempThickness,
            min: 1,
            max: 40,
            activeColor: const Color(0xFF0F4C5C),
            onChanged: (v) => setState(() => _tempThickness = v),
          ),
          const Divider(),
          SwitchListTile(
            title: const Text('Modo Marcador'),
            subtitle: const Text('Torna o traço semi-transparente'),
            value: _isHighlighter,
            activeColor: const Color(0xFF0F4C5C),
            onChanged: (v) => setState(() => _isHighlighter = v),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            ref.read(canvasToolProvider.notifier).setThickness(_tempThickness);
            ref.read(canvasToolProvider.notifier).toggleHighlighterMode(_isHighlighter);
            Navigator.pop(context);
          },
          child: const Text('Aplicar'),
        ),
      ],
    );
  }
}
