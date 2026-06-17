import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // Importante para o estado!
import 'features/subjects/screens/subjects_screen.dart';

void main() {
  // O ProviderScope é a "capa" obrigatória que faz a nossa base de dados
  // e os ecrãs comunicarem em tempo real.
  runApp(const ProviderScope(child: CadernoDigitalApp()));
}

class CadernoDigitalApp extends StatelessWidget {
  const CadernoDigitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caderno Digital',
      debugShowCheckedModeBanner: false, // Esconde a fita vermelha de "DEBUG"
      theme: ThemeData(
        // A nossa paleta de cores base (Azul Tinta)
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2C3E50)),
        useMaterial3: true,
      ),
      // Apontamos o ecrã inicial para a nossa obra de arte!
      home: const SubjectsScreen(),
    );
  }
}