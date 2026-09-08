import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class TableCreationDialog extends StatefulWidget {
  const TableCreationDialog({super.key});

  static Future<Map<String, int>?> show(BuildContext context) {
    return showDialog<Map<String, int>>(
      context: context,
      builder: (context) => const TableCreationDialog(),
    );
  }

  @override
  State<TableCreationDialog> createState() => _TableCreationDialogState();
}

class _TableCreationDialogState extends State<TableCreationDialog> {
  int rows = 3;
  int cols = 3;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Text('Nova Tabela', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildCounter('Linhas', rows, (val) => setState(() => rows = val)),
          const SizedBox(height: 16),
          _buildCounter('Colunas', cols, (val) => setState(() => cols = val)),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text('Cancelar', style: TextStyle(color: Colors.grey[600])),
        ),
        ElevatedButton(
          onPressed: () => Navigator.pop(context, {'rows': rows, 'cols': cols}),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F4C5C),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          ),
          child: const Text('Criar'),
        ),
      ],
    );
  }

  Widget _buildCounter(String label, int value, Function(int) onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 14)),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
            ),
            SizedBox(
              width: 30,
              child: Text(value.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
            ),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: value < 20 ? () => onChanged(value + 1) : null,
            ),
          ],
        ),
      ],
    );
  }
}
