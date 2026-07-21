import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/core/theme/app_theme.dart'; // 🚀 Importa o tema unificado
import 'package:caderno_digital_app/features/auth/views/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 O SEGUIDOR: Escuta o provedor híbrido.
    // Se mudar o perfil OU a cor da disciplina, a app re-pinta-se na hora!
    final dynamicTheme = ref.watch(appThemeProvider);

    return MaterialApp(
      title: 'Caderno Digital',
      debugShowCheckedModeBanner: false,
      theme: dynamicTheme, // Injeta o motor dinâmico
      home: const SplashScreen(),
    );
  }
}