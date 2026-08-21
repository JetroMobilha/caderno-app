import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/core/theme/app_theme.dart'; // 🚀 Importa o tema unificado
import 'package:caderno_digital_app/features/auth/views/splash_screen.dart';
import 'package:caderno_digital_app/features/shared/widgets/notification_overlay.dart';
import 'package:flutter/foundation.dart'; // 🚀 Para kIsWeb
import 'package:caderno_digital_app/core/network/time_service.dart';
import 'package:caderno_digital_app/core/network/http_overrides.dart' 
    if (dart.library.html) 'package:caderno_digital_app/core/network/http_overrides_web.dart';

void main() async { // 🚀 Adicionado async
  WidgetsFlutterBinding.ensureInitialized();
  
  // 🛡️ Aplicar overrides de rede apenas em plataformas nativas
  applyHttpOverrides();

  // 🕒 OFFLINE-FIRST: Carregar relógio calibrado do disco
  await TimeService().init();

  // 🛡️ OFFLINE-FIRST: Por padrão, o google_fonts tenta baixar fontes.
  // No Mobile, desativamos para evitar erros sem internet. 
  // Na Web, permitimos pois o carregamento inicial sempre requer rede.
  GoogleFonts.config.allowRuntimeFetching = true; // 🚀 Restaurado para evitar erros sem assets
  
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
      builder: (context, child) => NotificationOverlay(child: child!),
      home: const SplashScreen(),
    );
  }
}
