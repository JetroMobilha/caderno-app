import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart' hide ChangeNotifierProvider;

import 'core/theme/app_colors.dart';
import 'features/auth/views/splash_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // 🚀 PROVIDERSCOPE: A redoma mágica que guarda o estado de toda a aplicação!
  runApp(
    const ProviderScope(
      child: CadernoDigitalApp(),
    ),
  );
}

class CadernoDigitalApp extends StatelessWidget {
  const CadernoDigitalApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Caderno Digital',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          elevation: 0,
        ),
      ),
      // O ecrã de Splash vai decidir se vai para o Login ou para as Disciplinas
      home: const SplashScreen(),
    );
  }
}