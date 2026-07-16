import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../notebooks/models/notebook_model.dart';
import '../../notebooks/controllers/notebooks_controller.dart';
import '../../auth/controllers/auth_controller.dart';

class ShareNotebookBottomSheet extends ConsumerStatefulWidget {
  final Notebook notebook;

  const ShareNotebookBottomSheet({super.key, required this.notebook});

  @override
  ConsumerState<ShareNotebookBottomSheet> createState() => _ShareNotebookBottomSheetState();
}

class _ShareNotebookBottomSheetState extends ConsumerState<ShareNotebookBottomSheet> {
  final TextEditingController _emailController = TextEditingController();

  String _selectedRole = 'viewer';
  bool _isLoading = false;
  bool _isFetchingList = true;

  final List<Map<String, String>> _collaborators = [];

  @override
  void initState() {
    super.initState();
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
      final serverList = await ref.read(notebooksProvider.notifier).loadCollaborators(widget.notebook.serverId!);
      setState(() {
        _collaborators.addAll(serverList);
        _isFetchingList = false;
      });
    } else {
      setState(() => _isFetchingList = false);
    }
  }

  // 🤝 Envia o convite
  void _sendInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;

    setState(() => _isLoading = true);
    final bool success = await ref.read(notebooksProvider.notifier).shareNotebook(
      widget.notebook.serverId!,
      email,
      _selectedRole,
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

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 24, left: 24, right: 24),
      decoration: const BoxDecoration(color: Color(0xFFFDFBF7), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(
        mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Cabeçalho Visual
          Row(children: [
            Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF0F4C5C).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.people_alt_outlined, color: Color(0xFF0F4C5C))),
            const SizedBox(width: 12),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Partilhar Caderno', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold)), Text(widget.notebook.title, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54))])),
            IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
          ]),
          const SizedBox(height: 20),

          // 🚀 O INPUT INTELIGENTE COM AUTOCOMPLETE DA NUVEM
          Container(
            padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
            child: Row(children: [
              Expanded(
                child: Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) async {
                    if (textEditingValue.text.length < 3) return const Iterable<String>.empty();
                    // Dispara a busca sementes na API do Laravel
                    return await ref.read(notebooksProvider.notifier).getEmailSuggestions(textEditingValue.text);
                  },
                  onSelected: (String selection) {
                    _emailController.text = selection;
                  },
                  fieldViewBuilder: (context, controller, focusNode, onFieldSubmitted) {
                    // Sincroniza o controller interno do Autocomplete com o nosso
                    if (_emailController.text != controller.text && _emailController.text.isEmpty) {
                      controller.text = _emailController.text;
                    }
                    _emailController.addListener(() {
                      if (_emailController.text != controller.text) {
                        controller.text = _emailController.text;
                      }
                    });
                    return TextField(
                      controller: controller,
                      focusNode: focusNode,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(hintText: 'Digita e-mail do aluno...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12)),
                    );
                  },
                ),
              ),
              DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                      value: _selectedRole,
                      items: const [
                        DropdownMenuItem(value: 'editor', child: Text('Editor', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'viewer', child: Text('Leitor', style: TextStyle(fontSize: 13))),
                        DropdownMenuItem(value: 'student', child: Text('Aluno', style: TextStyle(fontSize: 13))),
                      ],
                      onChanged: (v) => setState(() => _selectedRole = v!)
                  )
              ),
              const SizedBox(width: 8),
              ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C)), onPressed: _isLoading ? null : _sendInvite, child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Convidar', style: TextStyle(color: Colors.white))),
            ]),
          ),
          const SizedBox(height: 20),

          Text('Quem tem acesso', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)),
          const SizedBox(height: 10),

          // Lista de Colaboradores
          _isFetchingList
              ? const Center(child: Padding(padding: EdgeInsets.all(16.0), child: CircularProgressIndicator()))
              : Container(
            constraints: const BoxConstraints(maxHeight: 180),
            child: ListView.separated(
              shrinkWrap: true, itemCount: _collaborators.length, separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final user = _collaborators[index];
                final isOwner = user['role'] == 'owner';

                String roleDisplay = 'Leitor';
                if (isOwner) roleDisplay = 'Dono';
                else if (user['role'] == 'editor') roleDisplay = 'Editor';
                else if (user['role'] == 'student') roleDisplay = 'Aluno';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(backgroundColor: isOwner ? const Color(0xFFE67E22) : const Color(0xFF2C3E50), child: Text(user['name']![0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                  title: Text(user['name']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(user['email']!, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                  trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isOwner ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(roleDisplay, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOwner ? Colors.orange[800] : Colors.blue[800]))),
                        if (!isOwner) IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20), onPressed: () => _removeUser(index, user['email']!))
                      ]
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}