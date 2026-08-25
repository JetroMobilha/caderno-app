import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:caderno_digital_app/core/theme/app_colors.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import 'package:caderno_digital_app/features/auth/controllers/auth_controller.dart';

final appThemeProvider = Provider<ThemeData>((ref) {
  // 🛡️ Garantia extra de modo offline (Permitido em Web)
  GoogleFonts.config.allowRuntimeFetching = true;

  final authState = ref.watch(authProvider);
  final activeSubject = ref.watch(activeSubjectProvider);

  // 1. Determinar Cor Primária
  // Prioridade: Disciplina Ativa > Preferência do Utilizador > Padrão (Azul Petróleo)
  Color primaryColor = const Color(0xFF0F4C5C);

  if (activeSubject != null) {
    try {
      primaryColor = Color(int.parse(activeSubject.color.replaceFirst('#', '0xFF')));
    } catch (_) {}
  } else if (authState.currentUser?.preferredColor != null) {
    try {
      primaryColor = Color(int.parse(authState.currentUser!.preferredColor!.replaceFirst('#', '0xFF')));
    } catch (_) {}
  }

  // 2. Determinar Fonte
  // Prioridade: Preferência do Utilizador > Padrão (Inter)
  String fontFamily = authState.currentUser?.preferredFont ?? 'Inter';

  // 🚀 Lógica de tipografia robusta (Offline-Safe)
  TextTheme baseTextTheme;
  try {
    baseTextTheme = GoogleFonts.getTextTheme(
      fontFamily,
      ThemeData.light().textTheme,
    );
  } catch (e) {
    debugPrint('⚠️ GoogleFonts falhou (provavelmente offline): $e');
    baseTextTheme = ThemeData.light().textTheme;
  }

  baseTextTheme = baseTextTheme.apply(
    bodyColor: AppColors.textDark,
    displayColor: AppColors.textDark,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,

    colorScheme: ColorScheme.fromSeed(
      seedColor: primaryColor,
      primary: primaryColor,
      background: AppColors.background,
      surface: AppColors.paper,
    ),

    // Injeta o tema de texto limpo em toda a app (Inputs, ListTiles, Textos normais)
    textTheme: baseTextTheme,

    appBarTheme: AppBarTheme(
      backgroundColor: primaryColor,
      foregroundColor: AppColors.textLight,
      elevation: 0,
      centerTitle: true,
      titleTextStyle: GoogleFonts.getFont(
        fontFamily,
        fontWeight: FontWeight.bold,
        fontSize: 20,
        color: AppColors.textLight,
      ),
    ),

    floatingActionButtonTheme: FloatingActionButtonThemeData(
      backgroundColor: primaryColor,
      foregroundColor: AppColors.textLight,
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),

    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryColor,
        foregroundColor: AppColors.textLight,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      ),
    ),

    dividerTheme: const DividerThemeData(color: Colors.black12, thickness: 1),
  );
});
