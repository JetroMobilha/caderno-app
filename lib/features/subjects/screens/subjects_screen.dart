import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/subject_provider.dart';
import '../models/subject_model.dart';
// 1. CORREÇÃO: Import em falta adicionado!
import '../../notebooks/screens/notebooks_screen.dart';

class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Os Meus Cadernos',
          style: GoogleFonts.lora(
            color: const Color(0xFF1A1A24),
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (subjects.isEmpty) {
            return Center(
              child: Text(
                'A tua estante está vazia.\nCria a tua primeira disciplina!',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 16),
              ),
            );
          }

          int crossAxisCount = 2;
          if (constraints.maxWidth >= 900) {
            crossAxisCount = 6;
          } else if (constraints.maxWidth >= 600) {
            crossAxisCount = 4;
          }

          return GridView.builder(
            padding: const EdgeInsets.all(20),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: 0.75,
            ),
            itemCount: subjects.length,
            itemBuilder: (context, index) {
              // 2. CORREÇÃO: Passamos o 'context' que o método agora exige!
              return _buildBinderCard(context, subjects[index]);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubjectDialog(context, ref),
        backgroundColor: const Color(0xFF2C3E50),
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Nova Disciplina', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // 3. CORREÇÃO: Método ajustado com Context e variável 'color' reposicionada
  Widget _buildBinderCard(BuildContext context, Subject subject) {
    final color = Color(int.parse(subject.color.replaceFirst('#', '0xFF')));

    return InkWell(
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
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 16,
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Spacer(),
                    Text(
                      subject.name,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1A1A24),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Cadernos: 0',
                      style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddSubjectDialog(BuildContext context, WidgetRef ref) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF7),
        title: Text('Nova Disciplina', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            hintText: 'Ex: Matemática Analítica',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50)),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                ref.read(subjectProvider.notifier).addSubject(
                  Subject(
                    userId: 1,
                    name: nameController.text,
                    color: '#8B0000',
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Criar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}