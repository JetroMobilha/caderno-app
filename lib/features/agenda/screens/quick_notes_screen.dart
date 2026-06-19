import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class QuickNotesScreen extends StatefulWidget {

  final List<Map<String, dynamic>>? initialNotes;

  const QuickNotesScreen({super.key, this.initialNotes});

  @override
  State<QuickNotesScreen> createState() => _QuickNotesScreenState();
}

class _QuickNotesScreenState extends State<QuickNotesScreen> {
  late List<Map<String, dynamic>> _notes;

  @override
  void initState() {
    super.initState();
    // Se passarmos notas no construtor (ex: lista vazia no teste), usa essas.
    // Caso contrário, usa os dados mockados por defeito na app.
    _notes = widget.initialNotes ?? [
      {
        'title': 'Reunião com Orientador',
        'content': 'Discutir a modelação das tabelas JSON e sincronismo WebRTC.',
        'date': '14:30',
        'color': 0xFFFFF9C4
      },
      {
        'title': 'Lista de Compras',
        'content': 'Café, canetas para o tablet, pilhas para o rato.',
        'date': 'Ontem',
        'color': 0xFFE1BEE7
      }
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text('Agenda & Notas Rápidas', style: GoogleFonts.ubuntu(fontWeight: FontWeight.w500)),
        backgroundColor: const Color(0xFF0F4C5C), // Cor do Perfil Agenda
        foregroundColor: Colors.white,
      ),
      body: _notes.isEmpty
          ? Center(
        child: Text(
          'Nenhuma nota para hoje. Clique no + para começar!',
          style: GoogleFonts.inter(color: Colors.black45),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: 200,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.9,
          ),
          itemCount: _notes.length,
          itemBuilder: (context, index) {
            final note = _notes[index];
            return Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Color(note['color']),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    note['title'],
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: Text(
                      note['content'],
                      style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, height: 1.3),
                      maxLines: 5,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Align(
                    alignment: Alignment.bottomRight,
                    child: Text(
                      note['date'],
                      style: GoogleFonts.inter(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F4C5C),
        foregroundColor: Colors.white,
        onPressed: () {
          // Lógica futura para abrir modal de texto simples
        },
        child: const Icon(Icons.post_add),
      ),
    );
  }
}