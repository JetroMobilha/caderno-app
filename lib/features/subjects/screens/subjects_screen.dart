import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/subject_provider.dart';
import '../models/subject_model.dart';

// Usamos ConsumerWidget para escutar as mudanças no Riverpod
class SubjectsScreen extends ConsumerWidget {
  const SubjectsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuta a lista de disciplinas da base de dados
    final subjects = ref.watch(subjectProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Cor de folha de papel macia
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Os Meus Cadernos',
          style: GoogleFonts.lora( // Fonte elegante e clássica
            color: const Color(0xFF1A1A24),
            fontSize: 26,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: subjects.isEmpty
          ? Center(
        child: Text(
          'A tua estante está vazia.\nCria a tua primeira disciplina!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: Colors.grey.shade500,
            fontSize: 16,
          ),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, // Dois cadernos por linha
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.8, // Formato vertical de caderno
        ),
        itemCount: subjects.length,
        itemBuilder: (context, index) {
          final subject = subjects[index];
          return _buildBinderCard(subject);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddSubjectDialog(context, ref),
        backgroundColor: const Color(0xFF2C3E50), // Azul Tinta
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text(
          'Nova Disciplina',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // O Design do Caderno (Lombada colorida à esquerda)
  Widget _buildBinderCard(Subject subject) {
    // Converte a string hexadecimal '#FF0000' para cor do Flutter
    final color = Color(int.parse(subject.color.replaceFirst('#', '0xFF')));

    return Container(
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
          // A lombada do caderno (A parte colorida com textura)
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
                    'Cadernos: 0', // Placeholder para o futuro
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Janela para adicionar a disciplina
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
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50)),
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                // Chama o nosso Cérebro para gravar na BD!
                ref.read(subjectProvider.notifier).addSubject(
                  Subject(
                    userId: 1, // Temporário (até termos o Login feito)
                    name: nameController.text,
                    color: '#8B0000', // Vermelho Escuro (Bordô) por defeito
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