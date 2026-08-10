import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppProfile { corporativo, academico, desenho, notas, agenda }

class AppProfileNotifier extends StateNotifier<AppProfile> {
  // O perfil padrão arranca no Académico
  AppProfileNotifier() : super(AppProfile.academico) {
    _restoreProfile();
  }

  Future<void> _restoreProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final index = prefs.getInt('active_app_profile');
    if (index != null && index < AppProfile.values.length) {
      state = AppProfile.values[index];
    }
  }

  Future<void> changeProfile(AppProfile newProfile) async {
    state = newProfile;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_app_profile', newProfile.index);
  }
}

final appProfileProvider = StateNotifierProvider<AppProfileNotifier, AppProfile>((ref) {
  return AppProfileNotifier();
});

/// Extensão utilitária para extrair configurações visuais com base no perfil ativo
extension AppProfileExtension on AppProfile {
  String get name {
    switch (this) {
      case AppProfile.corporativo: return 'Corporativo / Trabalho';
      case AppProfile.academico: return 'Académico / Estudos';
      case AppProfile.desenho: return 'Artes & Desenho';
      case AppProfile.notas: return 'Notas Rápidas';
      case AppProfile.agenda: return 'Agenda Pessoal';
    }
  }

  IconData get icon {
    switch (this) {
      case AppProfile.corporativo: return Icons.business_center;
      case AppProfile.academico: return Icons.school;
      case AppProfile.desenho: return Icons.brush;
      case AppProfile.notas: return Icons.sticky_note_2;
      case AppProfile.agenda: return Icons.calendar_month;
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppProfile.corporativo: return const Color(0xFF1B365D);
      case AppProfile.academico: return const Color(0xFF2C3E50);
      case AppProfile.desenho: return const Color(0xFFD35400);
      case AppProfile.notas: return const Color(0xFF16A085);
      case AppProfile.agenda: return const Color(0xFF0F4C5C);
    }
  }

  // 🚀 SUBSTITUÍMOS A FONTE SERIFADA (LORA) PELA SANS-SERIF (INTER)
  String get fontFamilyName {
    switch (this) {
      case AppProfile.corporativo: return 'Inter';
      case AppProfile.academico: return 'Inter'; // 🔥 Agora é Sans-Serif!
      case AppProfile.desenho: return 'Poppins';
      case AppProfile.notas: return 'Nunito'; // Substituído por Nunito (Sans-Serif arredondada)
      case AppProfile.agenda: return 'Ubuntu';
    }
  }

  TextStyle get titleStyle {
    // 🛡️ Fallback seguro para fontes em modo offline
    try {
      switch (this) {
        case AppProfile.corporativo: return GoogleFonts.inter(fontWeight: FontWeight.bold);
        case AppProfile.academico: return GoogleFonts.inter(fontWeight: FontWeight.bold);
        case AppProfile.desenho: return GoogleFonts.poppins(fontWeight: FontWeight.w600);
        case AppProfile.notas: return GoogleFonts.nunito(fontWeight: FontWeight.bold, fontSize: 24);
        case AppProfile.agenda: return GoogleFonts.ubuntu(fontWeight: FontWeight.w500, letterSpacing: 0.5);
      }
    } catch (_) {
      return const TextStyle(fontWeight: FontWeight.bold);
    }
  }
}