import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/local_page_model.dart';
import '../../notebooks/controllers/notebooks_controller.dart';

class StartCollaborationSheet extends ConsumerStatefulWidget {
  final int notebookServerId;
  final List<LocalPage> pages;
  final String currentTitle;
  final String role;
  final Function(List<int> pageIds, String alternativeTitle, String sharingType) onStart;

  const StartCollaborationSheet({
    super.key, 
    required this.notebookServerId,
    required this.pages, 
    required this.currentTitle,
    required this.role,
    required this.onStart,
  });

  @override
  ConsumerState<StartCollaborationSheet> createState() => _StartCollaborationSheetState();
}

class _StartCollaborationSheetState extends ConsumerState<StartCollaborationSheet> {
  late TextEditingController _titleController;
  final Set<int> _selectedPageIds = {};
  String _sharingType = 'full'; 
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.currentTitle);
    _loadInitialSettings();
  }

  Future<void> _loadInitialSettings() async {
    final sessionStatus = await ref.read(notebooksProvider.notifier).getSessionStatus(widget.notebookServerId);
    debugPrint('📡 [StartCollaboration] Configurações recuperadas: $sessionStatus');
    
    if (mounted) {
      setState(() {
        if (sessionStatus != null && sessionStatus['sharing_type'] != null) {
          final String serverType = sessionStatus['sharing_type'].toString().toLowerCase();
          _sharingType = (serverType == 'full' || serverType == 'scoped') ? serverType : 'full';
          _titleController.text = sessionStatus['alternative_title'] ?? widget.currentTitle;
          
          if (sessionStatus['authorized_page_ids'] != null) {
            _selectedPageIds.clear();
            _selectedPageIds.addAll(List<int>.from(sessionStatus['authorized_page_ids']));
          }
        }

        if (_selectedPageIds.isEmpty) {
          for (var p in widget.pages) {
            if (p.serverId != null) _selectedPageIds.add(p.serverId!);
          }
        }
        _isLoading = false;
      });
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
    final bool isOwner = widget.role == 'owner';

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20, 
        top: 24, left: 24, right: 24
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBF7), 
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))
      ),
      child: _isLoading 
        ? const SizedBox(height: 300, child: Center(child: CircularProgressIndicator()))
        : SingleChildScrollView(
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
                      Text(isOwner ? 'Abrir Sala de Colaboração' : 'Entrar na Sala', 
                        style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold)
                      ),
                      Text(isOwner ? 'Escolha o que os outros podem ver.' : 'Ligar ao professor ou colega.', 
                        style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)
                      ),
                    ],
                  ),
                ),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
            const SizedBox(height: 24),

            if (isOwner) ...[
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
            ] else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: themeColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: themeColor.withOpacity(0.2)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.info_outline_rounded, color: themeColor, size: 32),
                    const SizedBox(height: 12),
                    Text(
                      'Sessão: ${_titleController.text}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _sharingType == 'full' ? 'Modo de acesso completo ao caderno.' : 'Acesso limitado às folhas selecionadas pelo dono.',
                      style: const TextStyle(color: Colors.black54, fontSize: 13),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
            ],

            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: themeColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                    onPressed: (isOwner && _sharingType == 'scoped' && _selectedPageIds.isEmpty) ? null : () {
                      widget.onStart(
                        _sharingType == 'full' ? [] : _selectedPageIds.toList(), 
                        _titleController.text.trim(),
                        _sharingType
                      );
                      Navigator.pop(context);
                    },
                    child: Text(isOwner ? 'Iniciar Modo ${_sharingType == 'full' ? "Completo" : "Privado"}' : 'Entrar na Sala Agora', 
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                    ),
                  ),
                ),
                if (isOwner) ...[
                  const SizedBox(width: 8),
                  ValueListenableBuilder<bool>(
                    valueListenable: ValueNotifier(_isLoading),
                    builder: (context, loading, _) => IconButton.filled(
                      onPressed: loading ? null : () async {
                        setState(() => _isLoading = true);
                        final messenger = ScaffoldMessenger.of(context);
                        final success = await ref.read(notebooksProvider.notifier).updateSessionSettings(
                          notebookId: widget.notebookServerId,
                          sharingType: _sharingType,
                          alternativeTitle: _titleController.text.trim(),
                          pageIds: _sharingType == 'scoped' ? _selectedPageIds.toList() : null,
                        );
                        if (mounted) setState(() => _isLoading = false);
                        if (success && mounted) {
                          messenger.showSnackBar(const SnackBar(content: Text('Configurações guardadas! 💾'), backgroundColor: Colors.green));
                        }
                      },
                      style: IconButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: themeColor,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: themeColor)),
                        padding: const EdgeInsets.all(16),
                      ),
                      icon: const Icon(Icons.save_outlined),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeCard({required String label, required IconData icon, required String type, required Color color}) {
    final bool isSelected = _sharingType == type;
    debugPrint('🎴 [Card] $label selected: $isSelected (current: $_sharingType)');
    
    return GestureDetector(
      key: ValueKey('type_$type\_$isSelected'),
      onTap: () {
        setState(() => _sharingType = type);
        debugPrint('👆 Clique no modo: $type');
      },
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
