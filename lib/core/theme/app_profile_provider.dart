import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// 🔥 ADICIONADO: 'agenda' incluído no enumerador global
enum AppProfile { corporativo, academico, desenho, notas, agenda }

class AppProfileNotifier extends StateNotifier<AppProfile> {
  AppProfileNotifier() : super(AppProfile.academico);

  void changeProfile(AppProfile newProfile) => state = newProfile;
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
      case AppProfile.agenda: return 'Agenda Pessoal'; // 🔥 Novo nome
    }
  }

  IconData get icon {
    switch (this) {
      case AppProfile.corporativo: return Icons.business_center;
      case AppProfile.academico: return Icons.school;
      case AppProfile.desenho: return Icons.brush;
      case AppProfile.notas: return Icons.sticky_note_2;
      case AppProfile.agenda: return Icons.calendar_month; // 🔥 Novo Ícone
    }
  }

  Color get primaryColor {
    switch (this) {
      case AppProfile.corporativo: return const Color(0xFF1B365D);
      case AppProfile.academico: return const Color(0xFF2C3E50);
      case AppProfile.desenho: return const Color(0xFFD35400);
      case AppProfile.notas: return const Color(0xFF16A085);
      case AppProfile.agenda: return const Color(0xFF0F4C5C); // 🔥 Azul Petróleo de Organização
    }
  }

  TextStyle get titleStyle {
    switch (this) {
      case AppProfile.corporativo: return GoogleFonts.inter(fontWeight: FontWeight.bold);
      case AppProfile.academico: return GoogleFonts.lora(fontWeight: FontWeight.bold);
      case AppProfile.desenho: return GoogleFonts.poppins(fontWeight: FontWeight.w600);
      case AppProfile.notas: return GoogleFonts.caveat(fontWeight: FontWeight.bold, fontSize: 24);
      case AppProfile.agenda: return GoogleFonts.ubuntu(fontWeight: FontWeight.w500, letterSpacing: 0.5); // 🔥 Nova Fonte Clean
    }
  }
}