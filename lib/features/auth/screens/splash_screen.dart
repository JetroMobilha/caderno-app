import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';


class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // O nosso creme clássico
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 1. LOGOTIPO PULSANTE (Igual ao do Login, mas ligeiramente maior)
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: const Color(0xFF0F4C5C).withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.menu_book_rounded,
                size: 72,
                color: Color(0xFF0F4C5C),
              ),
            ),
            const SizedBox(height: 24),

            // 2. NOME DA PLATAFORMA
            Text(
              'Caderno Digital',
              style: GoogleFonts.lora(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: const Color(0xFF1A1A24),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'A carregar o seu espaço de estudo...',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: Colors.black54,
                fontWeight: FontWeight.w500,
              ),
            ),

            const SizedBox(height: 48),

            // 3. INDICADOR DE PROGRESSO ELEGANTE
            const SizedBox(
              width: 32,
              height: 32,
              child: CircularProgressIndicator(
                color: Color(0xFF0F4C5C),
                strokeWidth: 3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}