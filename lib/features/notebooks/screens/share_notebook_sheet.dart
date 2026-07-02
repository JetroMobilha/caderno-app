import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
  String _selectedRole = 'editor'; // 'editor' ou 'viewer'
  bool _isLoading = false;

  // 🚀 LISTA MOCK DE TESTE (Na Fase 2 virá do SQLite / Laravel via Repository)
  final List<Map<String, String>> _collaborators = [
    {'name': 'Tu (Proprietário)', 'email': 'comandante@caderno.app', 'role': 'owner'},
    {'name': 'Engenheiro Adjunto', 'email': 'amigo@gmail.com', 'role': 'editor'},
  ];

  void _sendInvite() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) return;

    setState(() => _isLoading = true);

    // Simulação de tempo de requisição POST /api/notebooks/{id}/invite
    await Future.delayed(const Duration(milliseconds: 600));

    setState(() {
      _collaborators.add({
        'name': email.split('@')[0], // Gera nome provisório
        'email': email,
        'role': _selectedRole,
      });
      _emailController.clear();
      _isLoading = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Convite enviado para $email!'),
          backgroundColor: const Color(0xFF0F4C5C),
        ),
      );
    }
  }

  void _removeUser(int index) {
    setState(() => _collaborators.removeAt(index));
    // Futuro: disparar DELETE /api/notebooks/{id}/collaborators/{userId}
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
        top: 24, left: 24, right: 24,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBF7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // CABEÇALHO DO MODAL
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF0F4C5C).withOpacity(0.1), shape: BoxShape.circle),
                child: const Icon(Icons.people_alt_outlined, color: Color(0xFF0F4C5C)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Partilhar Caderno', style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24))),
                    Text(widget.notebookTitle, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54, fontWeight: FontWeight.w500)),
                  ],
                ),
              ),
              IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
            ],
          ),

          const SizedBox(height: 20),

          // BARRA DE CONVITE RÁPIDO
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.black12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: const InputDecoration(
                      hintText: 'E-mail do utilizador...',
                      border: InputBorder.none,
                      contentPadding: EdgeInsets.symmetric(horizontal: 12),
                    ),
                  ),
                ),

                // Seletor de Permissão Compacto
                DropdownButtonHideUnderline(
                  child: DropdownButton<String>(
                    value: _selectedRole,
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C)),
                    items: const [
                      DropdownMenuItem(value: 'editor', child: Text('Pode Editar')),
                      DropdownMenuItem(value: 'viewer', child: Text('Só Leitura')),
                    ],
                    onChanged: (val) => setState(() => _selectedRole = val!),
                  ),
                ),

                const SizedBox(width: 8),

                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C5C),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  ),
                  onPressed: _isLoading ? null : _sendInvite,
                  child: _isLoading
                      ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('Convidar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),
          Text('Quem tem acesso', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.black45)),
          const SizedBox(height: 8),

          // LISTA DE COLABORADORES ATIVOS
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 220),
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: _collaborators.length,
              separatorBuilder: (_, __) => const Divider(height: 1, color: Colors.black12),
              itemBuilder: (context, index) {
                final user = _collaborators[index];
                final bool isOwner = user['role'] == 'owner';

                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: isOwner ? const Color(0xFFE67E22) : const Color(0xFF2C3E50),
                    child: Text(user['name']![0].toUpperCase(), style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                  ),
                  title: Text(user['name']!, style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 14)),
                  subtitle: Text(user['email']!, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: isOwner ? Colors.orange.withOpacity(0.1) : Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          isOwner ? 'Dono' : (user['role'] == 'editor' ? 'Editor' : 'Leitor'),
                          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: isOwner ? Colors.orange[800] : Colors.blue[800]),
                        ),
                      ),
                      if (!isOwner) ...[
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent, size: 20),
                          onPressed: () => _removeUser(index),
                          tooltip: 'Revogar acesso',
                        ),
                      ]
                    ],
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