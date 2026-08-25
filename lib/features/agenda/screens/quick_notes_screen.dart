import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/quick_notes_controller.dart';
import '../../canvas/models/local_page_model.dart';

class QuickNotesScreen extends ConsumerWidget {
  const QuickNotesScreen({super.key});

  String _formatDate(int timestamp) {
    final date = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return '${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
    } else if (diff.inDays == 1) {
      return 'Ontem';
    } else {
      return '${date.day}/${date.month}';
    }
  }

  void _showNoteModal(BuildContext context, WidgetRef ref, {LocalPage? noteToEdit}) {
    final titleController = TextEditingController(text: noteToEdit?.title ?? '');
    final contentController = TextEditingController(text: noteToEdit?.extractedText ?? '');
    String selectedColorHex = noteToEdit?.footer ?? '0xFFFFF9C4';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFFFDFBF7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(
            noteToEdit == null ? 'Nova Nota' : 'Editar Nota',
            style: GoogleFonts.ubuntu(fontWeight: FontWeight.bold),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Título', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: contentController,
                  maxLines: 5,
                  decoration: const InputDecoration(labelText: 'Conteúdo', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _colorOption(0xFFFFF9C4, selectedColorHex, (hex) => setModalState(() => selectedColorHex = hex)),
                    _colorOption(0xFFE1BEE7, selectedColorHex, (hex) => setModalState(() => selectedColorHex = hex)),
                    _colorOption(0xFFFFCCBC, selectedColorHex, (hex) => setModalState(() => selectedColorHex = hex)),
                    _colorOption(0xFFC8E6C9, selectedColorHex, (hex) => setModalState(() => selectedColorHex = hex)),
                    _colorOption(0xFFB3E5FC, selectedColorHex, (hex) => setModalState(() => selectedColorHex = hex)),
                  ],
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C), foregroundColor: Colors.white),
              onPressed: () {
                if (noteToEdit == null) {
                  ref.read(quickNotesProvider.notifier).addNote(
                    title: titleController.text,
                    content: contentController.text,
                    colorHex: selectedColorHex,
                  );
                } else {
                  ref.read(quickNotesProvider.notifier).updateNote(
                    noteToEdit,
                    title: titleController.text,
                    content: contentController.text,
                    colorHex: selectedColorHex,
                  );
                }
                Navigator.pop(context);
              },
              child: Text(noteToEdit == null ? 'Adicionar' : 'Guardar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorOption(int colorValue, String currentHex, Function(String) onSelect) {
    final String hex = '0x${colorValue.toRadixString(16).toUpperCase()}';
    final bool isSelected = currentHex == hex;
    return GestureDetector(
      onTap: () => onSelect(hex),
      child: Container(
        width: 30, height: 30,
        decoration: BoxDecoration(
          color: Color(colorValue),
          shape: BoxShape.circle,
          border: isSelected ? Border.all(color: Colors.black, width: 2) : null,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(quickNotesProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text('Agenda & Notas Rápidas', style: GoogleFonts.ubuntu(fontWeight: FontWeight.w500)),
        backgroundColor: const Color(0xFF0F4C5C),
        foregroundColor: Colors.white,
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF0F4C5C)))
          : state.notes.isEmpty
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
                    itemCount: state.notes.length,
                    itemBuilder: (context, index) {
                      final note = state.notes[index];
                      final Color noteColor = Color(int.tryParse(note.footer) ?? 0xFFFFF9C4);

                      return GestureDetector(
                        onTap: () => _showNoteModal(context, ref, noteToEdit: note),
                        onLongPress: () {
                          showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Apagar Nota?'),
                              content: const Text('Esta nota será removida permanentemente.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
                                TextButton(
                                  onPressed: () {
                                    ref.read(quickNotesProvider.notifier).deleteNote(note);
                                    Navigator.pop(context);
                                  },
                                  child: const Text('Apagar', style: TextStyle(color: Colors.redAccent)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: noteColor,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 3))
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                note.title.isEmpty ? 'Sem título' : note.title,
                                style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.black87),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Expanded(
                                child: Text(
                                  note.extractedText ?? '',
                                  style: GoogleFonts.inter(fontSize: 13, color: Colors.black87, height: 1.3),
                                  maxLines: 5,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Align(
                                alignment: Alignment.bottomRight,
                                child: Text(
                                  _formatDate(note.updatedAt),
                                  style: GoogleFonts.inter(fontSize: 10, color: Colors.black45, fontWeight: FontWeight.bold),
                                ),
                              )
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF0F4C5C),
        foregroundColor: Colors.white,
        onPressed: () => _showNoteModal(context, ref),
        child: const Icon(Icons.post_add),
      ),
    );
  }
}
