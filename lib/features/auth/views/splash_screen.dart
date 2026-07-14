import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 👈 Riverpod
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../notebooks/views/notebooks_list_screen.dart';
import '../controllers/auth_controller.dart';
import 'login_screen.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthorization();
  }

  Future<void> _checkAuthorization() async {
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // 🚀 Lemos o estado silenciosamente (ref.read)
    final loggedIn = await ref.read(authProvider).checkAuthStatus();

    if (!mounted) return;

    if (loggedIn) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const NotebooksListScreen()),
      );
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.menu_book_rounded, size: 80, color: AppColors.textLight),
            const SizedBox(height: 16),
            Text('Caderno Digital', style: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.bold, color: AppColors.textLight)),
            const SizedBox(height: 8),
            Text('O teu conhecimento em tempo real', style: GoogleFonts.inter(fontSize: 14, color: Colors.white70)),
          ],
        ),
      ),
    );
  }
}