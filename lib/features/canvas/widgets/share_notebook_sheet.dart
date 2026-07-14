import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../notebooks/repositories/notebook_repository.dart';

class ShareNotebookBottomSheet extends StatefulWidget {
  final int notebookId;
  final String notebookTitle;

  const ShareNotebookBottomSheet({
    super.key,
    required this.notebookId,
    required this.notebookTitle,
  });

  @override
  State<ShareNotebookBottomSheet> createState() => _ShareNotebookBottomSheetState();
}

class _ShareNotebookBottomSheetState extends State<ShareNotebookBottomSheet> {
  final TextEditingController _emailController = TextEditingController();
  final NotebookRepository _notebookRepository = NotebookRepository();

  String _selectedRole = 'editor';
  bool _isLoading = false;

  final List<Map<String, String>> _collaborators = [
    {'name': 'Tu (Proprietário)', 'email': 'comandante@caderno.app', 'role': 'owner'},
  ];

  void _sendInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;

    setState(() => _isLoading = true);
    final bool success = await _notebookRepository.shareNotebookWithFriend(
      notebookId: widget.notebookId,
      email: email,
      role: _selectedRole,
    );
    setState(() => _isLoading = false);

    if (success) {
      setState(() {
        _collaborators.add({'name': email.split('@')[0], 'email': email, 'role': _selectedRole});
        _emailController.clear();
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Caderno partilhado com sucesso com $email! 🎓'), backgroundColor: const Color(0xFF0F4C5C)));
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Erro ao enviar convite. Verifica o e-mail! ⚠️'), backgroundColor: Colors.redAccent));
      }
    }
  }

  void _removeUser(int index) {
    setState(() => _collaborators.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) Navigator.pop(context, _collaborators.length - 1);
      },
      child: Container(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom + 20, top: 24, left: 24, right: 24),
        decoration: const BoxDecoration(color: Color(0xFFFDFBF7), borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
        child: Column(
          mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF0F4C5C).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.people_alt_outlined, color: Color(0xFF0F4C5C))),
              const SizedBox(width: 12),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Partilhar Caderno', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold)), Text(widget.notebookTitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54))])),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context, _collaborators.length - 1)),
            ]),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(4), decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), border: Border.all(color: Colors.black12)),
              child: Row(children: [
                Expanded(child: TextField(controller: _emailController, keyboardType: TextInputType.emailAddress, decoration: const InputDecoration(hintText: 'E-mail do estudante...', border: InputBorder.none, contentPadding: EdgeInsets.symmetric(horizontal: 12)))),
                DropdownButtonHideUnderline(child: DropdownButton<String>(value: _selectedRole, items: const [DropdownMenuItem(value: 'editor', child: Text('Pode Editar')), DropdownMenuItem(value: 'viewer', child: Text('Só Leitura'))], onChanged: (v) => setState(() => _selectedRole = v!))),
                const SizedBox(width: 8),
                ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C)), onPressed: _isLoading ? null : _sendInvite, child: _isLoading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Convidar', style: TextStyle(color: Colors.white))),
              ]),
            ),
            const SizedBox(height: 20), Text('Quem tem acesso', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black54)), const SizedBox(height: 10),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              child: ListView.separated(
                shrinkWrap: true, itemCount: _collaborators.length, separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (context, index) {
                  final user = _collaborators[index];
                  final isOwner = user['role'] == 'owner';
                  return ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: CircleAvatar(backgroundColor: isOwner ? const Color(0xFFE67E22) : const Color(0xFF2C3E50), child: Text(user['name']![0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                    title: Text(user['name']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                    subtitle: Text(user['email']!, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                    trailing: Row(mainAxisSize: MainAxisSize.min, children: [Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4), decoration: BoxDecoration(color: isOwner ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1), borderRadius: BorderRadius.circular(6)), child: Text(isOwner ? 'Dono' : (user['role'] == 'editor' ? 'Editor' : 'Leitor'), style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: isOwner ? Colors.orange[800] : Colors.blue[800]))), if (!isOwner) IconButton(icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20), onPressed: () => _removeUser(index))]),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}