import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class LinkCreationDialog extends StatefulWidget {
  final String? initialLabel;
  final String? initialUrl;

  const LinkCreationDialog({super.key, this.initialLabel, this.initialUrl});

  static Future<Map<String, String>?> show(BuildContext context, {String? label, String? url}) {
    return showDialog<Map<String, String>>(
      context: context,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => LinkCreationDialog(initialLabel: label, initialUrl: url),
    );
  }

  @override
  State<LinkCreationDialog> createState() => _LinkCreationDialogState();
}

class _LinkCreationDialogState extends State<LinkCreationDialog> {
  late TextEditingController _labelCtrl;
  late TextEditingController _urlCtrl;

  @override
  void initState() {
    super.initState();
    _labelCtrl = TextEditingController(text: widget.initialLabel ?? '');
    _urlCtrl = TextEditingController(text: widget.initialUrl ?? 'https://');
  }

  @override
  void dispose() {
    _labelCtrl.dispose();
    _urlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 0,
      backgroundColor: Colors.white,
      child: Container(
        width: 380,
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.link_rounded, color: Color(0xFF0F4C5C), size: 28),
                const SizedBox(width: 12),
                Text('Inserir Link', style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
              ],
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _labelCtrl,
              decoration: const InputDecoration(
                labelText: 'Título do Link (Ex: Wikipédia)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title_rounded, color: Colors.black38),
              ),
              autofocus: true,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _urlCtrl,
              decoration: const InputDecoration(
                labelText: 'URL (Endereço Web)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.language_rounded, color: Colors.black38),
              ),
              keyboardType: TextInputType.url,
            ),
            const SizedBox(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
                ),
                const SizedBox(width: 12),
                ElevatedButton(
                  onPressed: () {
                    final label = _labelCtrl.text.trim();
                    final url = _urlCtrl.text.trim();
                    if (url.isEmpty || url == 'https://') return;
                    Navigator.of(context).pop({
                      'label': label.isEmpty ? url : label,
                      'url': url,
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C5C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Confirmar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
