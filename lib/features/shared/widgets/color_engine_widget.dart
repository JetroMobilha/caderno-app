import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ColorEngineWidget extends StatefulWidget {
  final String selectedColorHex;
  final Function(String) onColorSelected;

  const ColorEngineWidget({
    super.key,
    required this.selectedColorHex,
    required this.onColorSelected,
  });

  @override
  State<ColorEngineWidget> createState() => _ColorEngineWidgetState();
}

class _ColorEngineWidgetState extends State<ColorEngineWidget> {
  final List<String> _presets = [
    '#0F4C5C', '#1F4E79', '#3F51B5', '#6C3483',
    '#9B59B6', '#D81B60', '#E91E63', '#B03A2E',
    '#E67E22', '#D35400', '#F1C40F', '#1E8449',
    '#27AE60', '#16A085', '#4E342E', '#607D8B',
    '#8B0000', '#2C3E50', '#7F8C8D', '#000000',
  ];

  late TextEditingController _hexController;

  @override
  void initState() {
    super.initState();
    _hexController = TextEditingController(text: widget.selectedColorHex.replaceFirst('#', ''));
  }

  @override
  void dispose() {
    _hexController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            ..._presets.map((hex) {
              final isSelected = widget.selectedColorHex.toUpperCase() == hex.toUpperCase();
              final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
              return GestureDetector(
                onTap: () {
                  widget.onColorSelected(hex);
                  _hexController.text = hex.replaceFirst('#', '');
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isSelected ? Colors.black.withOpacity(0.3) : Colors.transparent,
                      width: 2,
                    ),
                    boxShadow: [
                      if (isSelected)
                        BoxShadow(color: color.withOpacity(0.4), blurRadius: 6, offset: const Offset(0, 2))
                    ],
                  ),
                  child: isSelected ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                ),
              );
            }),
            // Custom Color Trigger
            GestureDetector(
              onTap: _showCustomColorPicker,
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: const Icon(Icons.colorize_rounded, size: 16, color: Colors.black54),
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _showCustomColorPicker() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Cor Personalizada', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              height: 60,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Color(int.parse('0xFF${_hexController.text.isEmpty ? "000000" : _hexController.text}')),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.black12),
              ),
              alignment: Alignment.center,
              child: Text(
                'PREVISUALIZAÇÃO',
                style: TextStyle(
                  color: ThemeData.estimateBrightnessForColor(
                              Color(int.parse('0xFF${_hexController.text.isEmpty ? "000000" : _hexController.text}'))) ==
                          Brightness.dark
                      ? Colors.white
                      : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: _hexController,
              decoration: const InputDecoration(
                prefixText: '#',
                labelText: 'Código Hexadecimal',
                hintText: 'FF5733',
                border: OutlineInputBorder(),
              ),
              maxLength: 6,
              onChanged: (val) {
                if (val.length == 6) {
                  (ctx as Element).markNeedsBuild();
                }
              },
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          ElevatedButton(
            onPressed: () {
              if (_hexController.text.length == 6) {
                widget.onColorSelected('#${_hexController.text.toUpperCase()}');
                Navigator.pop(ctx);
              }
            },
            child: const Text('CONFIRMAR'),
          ),
        ],
      ),
    );
  }
}
