import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_tool_provider.dart';

class ColorStudioDialog extends ConsumerWidget {
  final bool isForText;
  final Function(String)? onColorSelected; // 🚀 Novo callback

  static const Map<String, Color> colorPalette = {
    'Black': Color(0xFF1A1A24),
    'Dark Gray': Color(0xFF455A64),
    'Light Gray': Color(0xFF90A4AE),
    'Off White': Color(0xFFECEFF1),
    'Dark Blue': Color(0xFF0F4C5C),
    'Royal Blue': Color(0xFF1976D2),
    'Sky Blue': Color(0xFF4FC3F7),
    'Purple': Color(0xFF6A1B9A),
    'Lavender': Color(0xFFB39DDB),
    'Deep Red': Color(0xFF9B2226),
    'Bright Red': Color(0xFFE53935),
    'Pink': Color(0xFFD81B60),
    'Pastel Pink': Color(0xFFF48FB1),
    'Orange': Color(0xFFE67E22),
    'Amber': Color(0xFFFFB300),
    'Forest Green': Color(0xFF1B4332),
    'Vibrant Green': Color(0xFF27AE60),
    'Mint': Color(0xFFA5D6A7),
    'Teal': Color(0xFF00897B),
    'Brown': Color(0xFF6D4C41),
  };

  const ColorStudioDialog({
    super.key,
    this.isForText = false,
    this.onColorSelected, // 🚀
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolNotifier = ref.read(canvasToolProvider.notifier);

    return AlertDialog(
      backgroundColor: const Color(0xFFFDFBF7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      title: Text(onColorSelected != null ? 'Mudar Cor da Seleção' : (isForText ? 'Cor do Texto' : 'Cor da Caneta')),
      content: SizedBox(
        width: 300,
        child: Wrap(
          spacing: 12,
          runSpacing: 12,
          children: colorPalette.entries.map((e) => GestureDetector(
            onTap: () {
              final hex = '#${e.value.toARGB32().toRadixString(16).substring(2).toUpperCase()}';
              
              if (onColorSelected != null) {
                onColorSelected!(hex);
              } else if (isForText) {
                // To be implemented: setTextColor in Document or Tool
              } else {
                toolNotifier.setColor(hex);
              }
              Navigator.pop(context);
            },
            child: CircleAvatar(backgroundColor: e.value),
          )).toList(),
        ),
      ),
    );
  }
}
