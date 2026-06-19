import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_profile_provider.dart';
import '../../agenda/screens/quick_notes_screen.dart';
import '../../notebooks/screens/notebooks_screen.dart';
import '../../notebooks/providers/notebook_provider.dart';
import '../models/subject_model.dart';
import '../providers/subject_provider.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentProfile = ref.watch(appProfileProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text('Os meus Cadernos', style: currentProfile.titleStyle),
        backgroundColor: currentProfile.primaryColor,
        foregroundColor: Colors.white,
      ),
      drawer: Drawer(
        child: Container(
          color: const Color(0xFFFDFBF7),
          child: Column(
            children: [
              UserAccountsDrawerHeader(
                decoration: BoxDecoration(color: currentProfile.primaryColor),
                currentAccountPicture: const CircleAvatar(
                  backgroundColor: Colors.white,
                  child: Icon(Icons.person, size: 40, color: Color(0xFF2C3E50)),
                ),
                accountName: const Text('Comandante Jetro', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                accountEmail: const Text('modo.offline@cadernodigital.local', style: TextStyle(color: Colors.white70)),
              ),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'MODO DE TRABALHO',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                ),
              ),
              ...AppProfile.values.map((profile) {
                final isSelected = currentProfile == profile;
                return ListTile(
                  leading: Icon(profile.icon, color: isSelected ? profile.primaryColor : Colors.black54),
                  title: Text(
                    profile.name,
                    style: GoogleFonts.inter(
                      fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                      color: isSelected ? profile.primaryColor : Colors.black87,
                    ),
                  ),
                  trailing: isSelected ? Icon(Icons.check_circle, color: profile.primaryColor) : null,
                  selected: isSelected,
                  onTap: () {
                    ref.read(appProfileProvider.notifier).changeProfile(profile);
                    Navigator.pop(context); // Fecha a gaveta

                    // 🚀 REDIRECIONAMENTO DINÂMICO DE LAYOUT:
                    if (profile == AppProfile.agenda) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const QuickNotesScreen()),
                      );
                    }
                  },
                );
              }).toList(),
              const Spacer(),
              const Padding(
                padding: EdgeInsets.all(16.0),
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
      ),
      body: const SubjectsListBody(),
      // 🚀 ADICIONADO: O Botão Flutuante que estava em falta para os testes e UI!
      floatingActionButton: FloatingActionButton(
        backgroundColor: currentProfile.primaryColor,
        foregroundColor: Colors.white,
        onPressed: () => _showAddSubjectDialog(context, ref),
        child: const Icon(Icons.add),
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
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: availableIcons.entries.map((entry) {
                    final isSelected = selectedIcon == entry.key;
                    return IconButton(
                      icon: Icon(entry.value, color: isSelected ? Colors.blue : Colors.black54),
                      onPressed: () => setModalState(() => selectedIcon = entry.key),
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
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50)),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  ref.read(subjectProvider.notifier).addSubject(
                    Subject(
                      userId: 1,
                      name: nameController.text.trim(),
                      color: pickedColorHex,
                      icon: selectedIcon,
                    ),
                  );
                  Navigator.pop(context);
                }
              },
              child: const Text('Criar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}

class SubjectsListBody extends ConsumerWidget {
  const SubjectsListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectProvider);

    if (subjects.isEmpty) {
      return const Center(child: Text('Nenhuma disciplina criada.'));
    }

    return ListView.builder(
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
        case 'book':
        default: return Icons.book;
      }
    }

    final Color subjectColor = Color(int.parse((subject.color).replaceFirst('#', '0xFF')));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
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
          height: 40,
          decoration: BoxDecoration(
            color: subjectColor,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        title: Row(
          children: [
            Icon(getIconData(subject.icon), color: Colors.black54, size: 20),
            const SizedBox(width: 10),
            Text(
              subject.name,
              style: GoogleFonts.lora(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: Colors.grey.shade200,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$notebookCount ${notebookCount == 1 ? 'caderno' : 'cadernos'}',
            style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black87),
          ),
        ),
      ),
    );
  }
}