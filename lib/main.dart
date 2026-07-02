import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'core/network/api_service.dart';
import 'features/auth/models/user_model.dart';
import 'features/auth/screens/login_screen.dart';
import 'features/auth/screens/splash_screen.dart';
import 'features/subjects/screens/subjects_screen.dart';

// 🚀 IMPORTS NOVOS OBRIGATÓRIOS PARA A INJEÇÃO DE IDENTIDADE
import 'features/auth/providers/user_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ProviderScope(child: CadernoDigitalApp()));
}

class CadernoDigitalApp extends StatelessWidget {
  const CadernoDigitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caderno Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: const Color(0xFFFDFBF7),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF0F4C5C),
          primary: const Color(0xFF0F4C5C),
        ),
        textTheme: GoogleFonts.interTextTheme(Theme.of(context).textTheme),
      ),
      home: const AuthGuard(),
    );
  }
}

// 🚀 PROMOVIDO A CONSUMER WIDGET PARA FALAR COM O RIVERPOD
class AuthGuard extends ConsumerWidget {
  const AuthGuard({super.key});

  // 🕵️‍♂️ FUNÇÃO TÁTICA: Lê o token e a identidade ao mesmo tempo!
  Future<bool> _initializeCoreSystems(WidgetRef ref) async {
    final api = ApiService();
    final token = await api.getToken();

    if (token != null && token.isNotEmpty) {
      // O Passaporte é válido! Vamos ler a Ficha do Soldado no Cofre.
      final userMap = await api.getUserData();

      if (userMap != null) {
        final user = User.fromJson(userMap);
        // 🚀 INJEÇÃO IMEDIATA NA RAM (Riverpod) ANTES DA TELA ABRIR!
        ref.read(userProvider.notifier).setUser(user);
        return true; // Autorizado a entrar
      }
    }
    return false; // Barrado (vai para Login)
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<bool>(
      future: _initializeCoreSystems(ref), // 🚀 Usamos a nossa nova função!
      builder: (context, snapshot) {

        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        // 🔐 DECISÃO DE FLUXO BLINDADA
        final isAuthorized = snapshot.data ?? false;

        if (isAuthorized) {
          // A identidade já está na RAM! A gaveta vai desenhar a foto instantaneamente.
          return const SubjectsScreen();
        }

        // Se o cofre estiver vazio, obriga a fazer autenticação
        return const LoginScreen();
      },
    );
  }
}