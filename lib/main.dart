import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/core/theme/app_theme.dart'; // 🚀 Importa o tema unificado
import 'package:caderno_digital_app/features/auth/views/splash_screen.dart';
import 'dart:io';

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  // 🛡️ OFFLINE-FIRST: Por padrão, o google_fonts tenta baixar fontes.
  // Se quiser suporte offline total, baixe os .ttf, coloque em assets/ e registre no pubspec.yaml.
  // Por agora, desativamos o fetching para evitar erros de rede em loop.
  GoogleFonts.config.allowRuntimeFetching = false;
  
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