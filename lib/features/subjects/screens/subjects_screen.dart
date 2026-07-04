import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/foundation.dart'; // Para o kIsWeb
import '../../../core/database/database_helper.dart'; // Ajusta o caminho se necessário

import '../../../core/network/api_service.dart';
import '../../../core/network/sync_service.dart';
import '../../auth/providers/user_provider.dart';
import '../../auth/screens/login_screen.dart';
import '../../auth/screens/profile_screen.dart';
import '../../notebooks/screens/notebooks_screen.dart';
import '../../notebooks/providers/notebook_provider.dart';
import '../models/subject_model.dart';
import '../providers/subject_provider.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  // 🚀 TÁTICA: Definimos a cor principal da aplicação diretamente aqui
  static const Color primaryColor = Color(0xFF0F4C5C);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuta o utilizador atual para manter a gaveta atualizada
    final currentUser = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text('Os meus Cadernos', style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: const Color(0xFFFDFBF7),
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            // 🚀 CABEÇALHO CLICÁVEL (Botão gigante para o Perfil)
            InkWell(
              onTap: () {
                Navigator.pop(context); // Fecha a gaveta
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfileScreen()));
              },
              child: UserAccountsDrawerHeader(
                decoration: const BoxDecoration(color: primaryColor),
                margin: EdgeInsets.zero,
                currentAccountPicture: CircleAvatar(
                  backgroundColor: Colors.white,
                  backgroundImage: (currentUser != null && currentUser.avatar != null)
                      ? NetworkImage(
                      currentUser.avatar!.startsWith('http')
                          ? currentUser.avatar!
                          : "${ApiService.baseUrlImagem}${currentUser.avatar!}"
                  )
                      : null,
                  child: (currentUser == null || currentUser.avatar == null)
                      ? const Icon(Icons.person, size: 40, color: primaryColor)
                      : null,
                ),
                accountName: Text(
                  currentUser?.name ?? 'A carregar...',
                  style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
                ),
                accountEmail: Row(
                  children: [
                    Text(
                      currentUser?.email ?? '',
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(width: 8),
                    const Icon(Icons.edit_rounded, size: 14, color: Colors.white54),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // 🚀 MENU INFERIOR LIMPO E DIRETO
            Padding(
              padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text('DEFINIÇÕES', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey)),
              ),
            ),

            ListTile(
              leading: const Icon(Icons.cloud_sync_outlined, color: Colors.black87),
              title: Text('Sincronização', style: GoogleFonts.inter(color: Colors.black87, fontWeight: FontWeight.w500)),
              onTap: () async {
                // 1. Fecha a gaveta imediatamente
                Navigator.pop(context);

                // 2. Avisa o soldado que a operação começou
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('A comunicar com o Quartel-General... ☁️'), duration: Duration(seconds: 2)),
                );

                // 3. INICIA A BATERIA DE SINCRONIZAÇÃO
                await SyncService().syncAll();

                // 4. ATUALIZA A TELA (Diz ao Riverpod para ler o SQLite de novo)
                // Isto faz com que as disciplinas que acabaram de chegar da nuvem apareçam na hora!
                ref.invalidate(subjectProvider);

                // 5. Sucesso!
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Tudo sincronizado!'), backgroundColor: Colors.green),
                  );
                }
              },
            ),

            const Divider(height: 32),

            // ZONA DE PERIGO (LOGOUT)
            ListTile(
              leading: const Icon(Icons.exit_to_app_rounded, color: Colors.redAccent),
              title: Text('Terminar Sessão', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.redAccent)),
              onTap: () => _handleLogout(context, ref),
            ),

            const Padding(
              padding: EdgeInsets.only(bottom: 24.0, top: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.cloud_off, size: 16, color: Colors.green),
                  SizedBox(width: 6),
                  Text('Motor Local Ativo (100% Offline)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            )
          ],
        ),
      ),
      body: const SubjectsListBody(),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () => _showAddSubjectDialog(context, ref),
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    String pickedColorHex = '#8B0000';
    String selectedIcon = 'book';

    final List<String> availableColors = ['#8B0000', '#2C3E50', '#1E8449', '#D35400', '#6C3483'];
    final Map<String, IconData> availableIcons = {
      'book': Icons.book,
      'computer': Icons.computer,
      'calculate': Icons.calculate,
      'biotech': Icons.biotech,
      'gavel': Icons.gavel,
      'calendar_month': Icons.calendar_month, // 🚀 Ícone novo para usares na "Agenda" se quiseres
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFFFDFBF7),
          title: Text('Nova Disciplina', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Nome da Disciplina', border: OutlineInputBorder()),
                  validator: (value) => value == null || value.trim().isEmpty ? 'Introduza o nome' : null,
                ),
                const SizedBox(height: 15),
                Text('Ícone Representativo:', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 12,
                  runSpacing: 12,
                  children: availableIcons.entries.map((entry) {
                    final isSelected = selectedIcon == entry.key;
                    return Container(
                      decoration: isSelected
                          ? BoxDecoration(color: primaryColor.withOpacity(0.1), borderRadius: BorderRadius.circular(8))
                          : null,
                      child: IconButton(
                        icon: Icon(entry.value, color: isSelected ? primaryColor : Colors.black54),
                        onPressed: () => setModalState(() => selectedIcon = entry.key),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 15),
                Text('Cor do Marcador:', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  children: availableColors.map((hex) {
                    final isSelected = pickedColorHex == hex;
                    return GestureDetector(
                      onTap: () => setModalState(() => pickedColorHex = hex),
                      child: CircleAvatar(
                        backgroundColor: Color(int.parse(hex.replaceFirst('#', '0xFF'))),
                        radius: 14,
                        child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                      ),
                    );
                  }).toList(),
                )
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.black54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  final currentUser = ref.read(userProvider);

                  if (currentUser == null) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Erro: Identidade do soldado não encontrada.')),
                    );
                    return;
                  }

                  // 🚀 INSTANCIAÇÃO PURIFICADA:
                  ref.read(subjectProvider.notifier).addSubject(
                    Subject(
                      userId: currentUser.id ?? 0,
                      serverId: null,
                      name: nameController.text.trim(),
                      color: pickedColorHex,
                      icon: selectedIcon,
                      // 3. Nasce com 0 para o nosso Radar de Fundo saber que tem de a enviar na próxima ofensiva
                      syncedWithCloud: 0,
                    ),
                  );

                  Navigator.pop(context); // Fecha o modal após recrutar
                }
              },
              child: const Text('Criar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleLogout(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('A terminar sessão e encriptar dados...'), duration: Duration(seconds: 2)),
    );

    if (!kIsWeb) {
      await DatabaseHelper.instance.clearAllData();
    }

    ref.invalidate(subjectProvider);
    ref.invalidate(notebookProvider);
    ref.read(userProvider.notifier).clearUser();

    final api = ApiService();
    await api.logout();



    if (context.mounted) {
      Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
    }
  }
}

class SubjectsListBody extends ConsumerStatefulWidget {
  const SubjectsListBody({super.key});
  @override
  ConsumerState<SubjectsListBody> createState() => _SubjectsListBodyState();
}

class _SubjectsListBodyState extends ConsumerState<SubjectsListBody> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadSubjects();
  }

  Future<void> _loadSubjects() async {
    await Future.delayed(const Duration(milliseconds: 400));
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: SubjectsScreen.primaryColor, strokeWidth: 3),
            const SizedBox(height: 16),
            Text('A carregar disciplinas...', style: GoogleFonts.inter(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500)),
          ],
        ),
      );
    }

    final subjects = ref.watch(subjectProvider);

    if (subjects.isEmpty) {
      return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text('Nenhuma disciplina criada.', style: GoogleFonts.inter(color: Colors.grey, fontSize: 16)),
            ],
          )
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80), // Margem de fundo para não colar no botão flutuante
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        return _buildSubjectCard(context, ref, subjects[index]);
      },
    );
  }

  Widget _buildSubjectCard(BuildContext context, WidgetRef ref, Subject subject) {
    final allNotebooks = ref.watch(notebookProvider);
    final notebookCount = allNotebooks.where((n) => n.subject_id == subject.id).length;

    IconData getIconData(String? iconName) {
      switch (iconName) {
        case 'computer': return Icons.computer;
        case 'calculate': return Icons.calculate;
        case 'biotech': return Icons.biotech;
        case 'gavel': return Icons.gavel;
        case 'calendar_month': return Icons.calendar_month;
        case 'book':
        default: return Icons.book;
      }
    }

    final Color subjectColor = Color(int.parse((subject.color).replaceFirst('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 1, // Reduzi a elevação para parecer mais "plano" e moderno
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withOpacity(0.05)), // Borda muito subtil
      ),
      color: Colors.white,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => NotebooksScreen(
                subjectId: subject.id ?? 0,
                subjectName: subject.name,
              ),
            ),
          );
        },
        leading: Container(
          width: 6,
          height: double.infinity,
          decoration: BoxDecoration(color: subjectColor, borderRadius: BorderRadius.circular(4)),
        ),
        title: Row(
          children: [
            Icon(getIconData(subject.icon), color: Colors.black54, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                subject.name,
                style: GoogleFonts.lora(fontSize: 17, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
              ),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: const Color(0xFFF8F9FA), // Fundo mais leve no contador
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$notebookCount ${notebookCount == 1 ? 'caderno' : 'cadernos'}',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54),
          ),
        ),
      ),
    );
  }
}