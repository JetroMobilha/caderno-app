import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:caderno_digital_app/core/theme/app_colors.dart';
import 'package:caderno_digital_app/core/theme/app_profile.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';

final appThemeProvider = Provider<ThemeData>((ref) {
  final activeProfile = ref.watch(appProfileProvider);
  final activeSubject = ref.watch(activeSubjectProvider);

  Color primaryColor = activeProfile.primaryColor;

  if (activeSubject != null) {
    try {
      primaryColor = Color(int.parse(activeSubject.color.replaceFirst('#', '0xFF')));
    } catch (_) {
      primaryColor = activeProfile.primaryColor;
    }
  }

  // 🚀 Força a tipografia Sans-Serif em toda a estrutura do Material Design
  final TextTheme baseTextTheme = GoogleFonts.getTextTheme(
    activeProfile.fontFamilyName,
    ThemeData.light().textTheme,
  ).apply(
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
      titleTextStyle: activeProfile.titleStyle.copyWith(
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