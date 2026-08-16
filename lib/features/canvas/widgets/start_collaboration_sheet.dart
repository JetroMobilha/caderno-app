import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/local_page_model.dart';

class StartCollaborationSheet extends StatefulWidget {
  final List<LocalPage> pages;
  final String currentTitle;
  final Function(List<int> pageIds, String alternativeTitle, String sharingType) onStart;

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
  String _sharingType = 'full'; // 'full' ou 'scoped'

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
    // 🚀 USAR SERVER_ID: Apenas páginas sincronizadas podem ser partilhadas
    for (var p in widget.pages) {
      if (p.serverId != null) _selectedPageIds.add(p.serverId!);
    }
  }

  void _togglePage(int? serverId) {
    if (serverId == null) return;
    setState(() {
      if (_selectedPageIds.contains(serverId)) {
        _selectedPageIds.remove(serverId);
      } else {
        _selectedPageIds.add(serverId);
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
      child: SingleChildScrollView(
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

            Text('Modo de Partilha:', 
              style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black87)
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _buildTypeCard(
                    label: 'Caderno Inteiro', 
                    icon: Icons.book_rounded, 
                    type: 'full', 
                    color: themeColor
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildTypeCard(
                    label: 'Páginas Selecionadas', 
                    icon: Icons.auto_awesome_motion_rounded, 
                    type: 'scoped', 
                    color: Colors.orange.shade800
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            if (_sharingType == 'scoped') ...[
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
                    final bool isSynced = page.serverId != null;
                    final isSelected = isSynced && _selectedPageIds.contains(page.serverId!);
                    
                    return GestureDetector(
                      onTap: isSynced ? () => _togglePage(page.serverId) : null,
                      child: Container(
                        width: 90,
                        decoration: BoxDecoration(
                          color: isSelected ? themeColor.withOpacity(0.1) : (isSynced ? Colors.white : Colors.grey.shade100),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: isSelected ? themeColor : Colors.black12,
                            width: isSelected ? 2 : 1,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Center(
                              child: Opacity(
                                opacity: isSynced ? 1.0 : 0.4,
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
                            ),
                            if (isSelected)
                              const Positioned(
                                top: 4, right: 4,
                                child: Icon(Icons.check_circle, color: Color(0xFF0F4C5C), size: 18),
                              ),
                            if (!isSynced)
                              const Positioned(
                                bottom: 4, right: 4,
                                child: Icon(Icons.cloud_off_rounded, color: Colors.black26, size: 14),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),
            ],

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: (_sharingType == 'scoped' && _selectedPageIds.isEmpty) ? null : () {
                  widget.onStart(
                    _sharingType == 'full' ? [] : _selectedPageIds.toList(), 
                    _titleController.text.trim(),
                    _sharingType
                  );
                  Navigator.pop(context);
                },
                child: Text('Iniciar em Modo ${_sharingType == 'full' ? "Completo" : "Privado"}', 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)
                ),
              ),
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({required String label, required IconData icon, required String type, required Color color}) {
    final isSelected = _sharingType == type;
    return GestureDetector(
      onTap: () => setState(() => _sharingType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.black12,
            width: isSelected ? 2 : 1
          )
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? color : Colors.black38, size: 28),
            const SizedBox(height: 8),
            Text(label, style: TextStyle(
              fontSize: 12, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              color: isSelected ? color : Colors.black54
            )),
          ],
        ),
      ),
    );
  }
}
