import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notebooks/models/notebook_model.dart';
import '../../notebooks/controllers/notebooks_controller.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../canvas/models/local_page_model.dart';
import '../../canvas/repositories/canvas_repository.dart';

class ShareNotebookBottomSheet extends ConsumerStatefulWidget {
  final Notebook notebook;

  const ShareNotebookBottomSheet({super.key, required this.notebook});

  @override
  ConsumerState<ShareNotebookBottomSheet> createState() => _ShareNotebookBottomSheetState();
}

class _ShareNotebookBottomSheetState extends ConsumerState<ShareNotebookBottomSheet> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _titleController = TextEditingController();

  String _selectedRole = 'viewer';
  bool _isLoading = false;
  bool _isFetchingList = true;
  
  String _sharingType = 'full'; // 'full' ou 'scoped'
  final Set<int> _selectedPageIds = {};
  List<LocalPage> _allPages = [];

  final List<Map<String, String>> _collaborators = [];

  @override
  void initState() {
    super.initState();
    _titleController.text = widget.notebook.title;
    _loadInitialData();
  }

  // 👥 Descarrega a lista real de acessos da Nuvem
  Future<void> _loadInitialData() async {
    final currentUser = ref.read(authProvider).currentUser;
    if (currentUser != null) {
      _collaborators.add({
        'name': '${currentUser.name} (Tu)',
        'email': currentUser.email,
        'role': 'owner'
      });
    }

    if (widget.notebook.serverId != null) {
      final notifier = ref.read(notebooksProvider.notifier);
      
      // 🚀 1. Carregar STATUS DA SESSÃO (Para lembrar escolhas)
      final sessionStatus = await notifier.getSessionStatus(widget.notebook.serverId!);
      if (sessionStatus != null && sessionStatus['active'] == true) {
        setState(() {
          _sharingType = sessionStatus['sharing_type'] ?? 'full';
          _titleController.text = sessionStatus['alternative_title'] ?? widget.notebook.title;
          if (sessionStatus['authorized_page_ids'] != null) {
            _selectedPageIds.clear();
            _selectedPageIds.addAll(List<int>.from(sessionStatus['authorized_page_ids']));
          }
        });
      }

      // 🚀 2. Carregar Lista de Colaboradores
      final serverList = await notifier.loadCollaborators(widget.notebook.serverId!);
      
      // 🚀 3. Carregar folhas para o modo Scoped
      final repo = ref.read(canvasRepositoryProvider);
      final pages = await repo.getPagesByNotebook(widget.notebook.id!, widget.notebook.serverId);

      setState(() {
        _collaborators.addAll(serverList);
        _allPages = pages;
        // Se não houver nada selecionado ainda, seleciona todas
        if (_selectedPageIds.isEmpty) {
          for (var p in pages) if (p.serverId != null) _selectedPageIds.add(p.serverId!);
        }
        _isFetchingList = false;
      });
    } else {
      setState(() => _isFetchingList = false);
    }
  }

  // 🤝 Envia o convite com Escopo e Título
  void _sendInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;

    setState(() => _isLoading = true);
    
    // 🚀 ENVIAR PARÂMETROS DE SESSÃO JUNTO COM O CONVITE
    final bool success = await ref.read(notebooksProvider.notifier).shareNotebook(
      widget.notebook.serverId!,
      email,
      _selectedRole,
      alternativeTitle: _titleController.text.trim(),
      sharingType: _sharingType,
      pageIds: _sharingType == 'scoped' ? _selectedPageIds.toList() : null,
    );
    
    if (mounted) setState(() => _isLoading = false);

    if (success) {
      setState(() {
        _collaborators.add({'name': email.split('@')[0], 'email': email, 'role': _selectedRole});
        _emailController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Partilhado com $email! 🎓'), backgroundColor: const Color(0xFF0F4C5C)));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Falha ao convidar. E-mail registado? ⚠️'), backgroundColor: Colors.redAccent));
      }
    }
  }

  // 🧨 REVOCOAR PERMISSÃO EM TEMPO REAL
  void _removeUser(int index, String email) async {
    final bool success = await ref.read(notebooksProvider.notifier).revokeAccess(widget.notebook.serverId!, email);

    if (success) {
      setState(() => _collaborators.removeAt(index));
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Acesso revogado com sucesso! 🗑️'), backgroundColor: Colors.green));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao revogar acesso na nuvem.'), backgroundColor: Colors.redAccent));
      }
    }
  }

  void _togglePageSelection(int? serverId) {
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
    final bool isUserOwner = widget.notebook.role == 'owner';

    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 24, left: 24, right: 24),
      decoration: const BoxDecoration(color: Color(0xFFFDFBF7), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: SingleChildScrollView( 
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Cabeçalho Visual
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF0F4C5C).withValues(alpha: 0.1), shape: BoxShape.circle), child: const Icon(Icons.people_alt_outlined, color: Color(0xFF0F4C5C))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Partilhar Caderno', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold)), Text(widget.notebook.title, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54))])),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ]),
            const SizedBox(height: 24),

            // 🚀 SEÇÃO 1: PRIVACIDADE (Apenas para o Dono)
            if (isUserOwner) ...[
              Text('Nível de Privacidade:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildPrivacyCard('Completo', Icons.book_rounded, 'full', const Color(0xFF0F4C5C))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildPrivacyCard('Seleção', Icons.auto_awesome_motion_rounded, 'scoped', Colors.orange.shade800)),
                ],
              ),
              const SizedBox(height: 20),

              if (_sharingType == 'scoped') ...[
                Text('Folhas Autorizadas:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                if (_allPages.where((p) => p.serverId != null).isEmpty)
                  const Padding(
                    padding: EdgeInsets.symmetric(vertical: 8.0),
                    child: Text('Nenhuma folha sincronizada disponível.', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                  )
                else
                  SizedBox(
                    height: 80,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      itemCount: _allPages.length,
                      separatorBuilder: (_, __) => const SizedBox(width: 8),
                      itemBuilder: (context, index) {
                        final p = _allPages[index];
                        final bool isSynced = p.serverId != null;
                        final isSel = isSynced && _selectedPageIds.contains(p.serverId);

                        return GestureDetector(
                          onTap: isSynced ? () => _togglePageSelection(p.serverId) : null,
                          child: Container(
                            width: 70,
                            decoration: BoxDecoration(
                              color: isSel ? const Color(0xFF0F4C5C).withOpacity(0.1) : (isSynced ? Colors.white : Colors.grey.shade100),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: isSel ? const Color(0xFF0F4C5C) : Colors.black12),
                            ),
                            child: Opacity(
                              opacity: isSynced ? 1.0 : 0.4,
                              child: Center(child: Text('F${p.pageNumber}', style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal))),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                const SizedBox(height: 20),
              ],

              Text('Nome Público (para convidados):', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                decoration: InputDecoration(
                  hintText: 'Como os outros verão este caderno...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 24),
            ],

            Text('Convidar por E-mail:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 10),

            Container(
              padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
              child: Row(children: [
                Expanded(
                  child: Autocomplete<String>(
                    optionsBuilder: (TextEditingValue textEditingValue) async {
                      if (textEditingValue.text.length < 3) return const Iterable<String>.empty();
                      return await ref.read(notebooksProvider.notifier).getEmailSuggestions(textEditingValue.text);
                    },
                    onSelected: (String selection) { _emailController.text = selection; },
                    fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                      if (_emailController.text != controller.text && _emailController.text.isEmpty) { controller.text = _emailController.text; }
                      _emailController.addListener(() { if (_emailController.text != controller.text) { controller.text = _emailController.text; } });
                      return TextField(
                        controller: controller, focusNode: focusNode,
                        keyboardType: TextInputType.emailAddress,
                        decoration: const InputDecoration(hintText: 'Digita e-mail...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                      );
                    },
                  ),
                ),
                DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                        value: _selectedRole,
                        items: const [
                          DropdownMenuItem(value: 'editor', child: Text('Edit', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'viewer', child: Text('Read', style: TextStyle(fontSize: 12))),
                          DropdownMenuItem(value: 'student', child: Text('Est.', style: TextStyle(fontSize: 12))),
                        ],
                        onChanged: (v) => setState(() => _selectedRole = v!)
                    )
                ),
                IconButton(
                  onPressed: _isLoading ? null : _sendInvite,
                  icon: _isLoading 
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) 
                    : const Icon(Icons.send_rounded, color: Color(0xFF0F4C5C)),
                ),
              ]),
            ),
            const SizedBox(height: 24),

            Text('Quem tem acesso', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
            const SizedBox(height: 10),

            _isFetchingList
                ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
                : Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true, itemCount: _collaborators.length, separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = _collaborators[index];
                  final isOwner = user['role'] == 'owner';

                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: isOwner ? const Color(0xFFE67E22) : const Color(0xFF2C3E50), child: Text(user['name']![0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    title: Text(user['name']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(user['email']!, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                    trailing: isOwner ? null : IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20), onPressed: () => _removeUser(index, user['email']!)),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrivacyCard(String label, IconData icon, String type, Color color) {
    final isSel = _sharingType == type;
    return GestureDetector(
      onTap: () => setState(() => _sharingType = type),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSel ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSel ? color : Colors.black12, width: isSel ? 2 : 1),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSel ? color : Colors.black38, size: 20),
            const SizedBox(height: 4),
            Text(label, style: TextStyle(fontSize: 11, fontWeight: isSel ? FontWeight.bold : FontWeight.normal, color: isSel ? color : Colors.black54)),
          ],
        ),
      ),
    );
  }
}
