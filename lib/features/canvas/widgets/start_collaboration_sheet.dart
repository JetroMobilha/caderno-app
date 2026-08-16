import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/canvas_controller.dart';
import '../models/local_page_model.dart';

class StartCollaborationSheet extends StatefulWidget {
  final List<LocalPage> pages;
  final String currentTitle;
  final Function(List<int> pageIds, String alternativeTitle) onStart;

  const StartCollaborationSheet({
    super.key, 
    required this.pages, 
    required this.currentTitle,
    required this.onStart,
  });

  @override
  State<StartCollaborationSheet> createState() => _StartCollaborationSheetState();
}

class _StartCollaborationSheetState extends State<StartCollaborationSheet> {
  late TextEditingController _titleController;
  final Set<int> _selectedPageIds = {};

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
    // Por padrão, selecionar apenas a página atual ou todas? 
    // Vamos selecionar todas inicialmente para facilitar.
    for (var p in widget.pages) {
      if (p.id != null) _selectedPageIds.add(p.id!);
    }
  }

  void _togglePage(int? id) {
    if (id == null) return;
    setState(() {
      if (_selectedPageIds.contains(id)) {
        _selectedPageIds.remove(id);
      } else {
        _selectedPageIds.add(id);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = const Color(0xFF0F4C5C);

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
        top: 24, left: 24, right: 24
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBF7), 
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min, 
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.security_rounded, color: Color(0xFF0F4C5C)),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Abrir Sala de Colaboração', 
                      style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold)
                    ),
                    Text('Escolha o que os outros podem ver.', 
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)
                    ),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 24),

          Text('Nome Público da Sala (Opcional):', 
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _titleController,
            decoration: InputDecoration(
              hintText: 'Ex: Ata de Reunião, Aula de História...',
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 24),

          Text('Selecionar Folhas para Partilhar:', 
            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)
          ),
          const SizedBox(height: 12),
          
          SizedBox(
            height: 120,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: widget.pages.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                final page = widget.pages[index];
                final isSelected = page.id != null && _selectedPageIds.contains(page.id!);
                
                return GestureDetector(
                  onTap: () => _togglePage(page.id),
                  child: Container(
                    width: 90,
                    decoration: BoxDecoration(
                      color: isSelected ? themeColor.withOpacity(0.1) : Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected ? themeColor : Colors.black12,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Stack(
                      children: [
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.description_outlined, 
                                color: isSelected ? themeColor : Colors.black38
                              ),
                              const SizedBox(height: 4),
                              Text('Folha ${page.pageNumber}', 
                                style: TextStyle(
                                  fontSize: 12, 
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? themeColor : Colors.black54
                                )
                              ),
                            ],
                          ),
                        ),
                        if (isSelected)
                          const Positioned(
                            top: 4, right: 4,
                            child: Icon(Icons.check_circle, color: Color(0xFF0F4C5C), size: 18),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
          
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: themeColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              onPressed: _selectedPageIds.isEmpty ? null : () {
                widget.onStart(_selectedPageIds.toList(), _titleController.text.trim());
                Navigator.pop(context);
              },
              child: const Text('Iniciar Colaboração Segura', 
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ),
    );
  }
}
