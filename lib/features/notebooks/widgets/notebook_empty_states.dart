import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class NoSubjectState extends StatelessWidget {
  final Color themeColor;

  const NoSubjectState({super.key, required this.themeColor});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_back_rounded, size: 48, color: themeColor.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Bem-vindo à tua Secretária!',
            style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold, color: themeColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Abre o menu superior esquerdo (☰)\npara selecionares ou criares a tua primeira pasta.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class EmptyNotebooksState extends StatelessWidget {
  final Color themeColor;
  final String subjectName;
  final bool isSharedTab;

  const EmptyNotebooksState({
    super.key, 
    required this.themeColor, 
    required this.subjectName,
    this.isSharedTab = false,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSharedTab ? Icons.share_outlined : Icons.book_outlined,
            size: 52,
            color: themeColor.withOpacity(0.3),
          ),
          const SizedBox(height: 16),
          Text(
            isSharedTab
                ? 'Sem Cadernos Compartilhados'
                : 'Estante Vazia em "$subjectName"',
            style: GoogleFonts.lora(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            isSharedTab
                ? 'Ainda não tens nenhum caderno compartilhado contigo.'
                : 'Clica no (+) em baixo para criares o teu primeiro caderno.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.black45, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
