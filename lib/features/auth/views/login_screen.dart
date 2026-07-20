import 'dart:convert';
import 'package:flutter/foundation.dart'; // 🚀 IMPORTAÇÃO VITAL PARA O ESCUDO WEB
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/sync_service.dart';
import '../../notebooks/views/notebooks_list_screen.dart';
import '../../subjects/controllers/subjects_controller.dart';
import '../../subjects/views/subjects_list_screen.dart';
import '../controllers/auth_controller.dart'; // 🚀 O nosso cérebro centralizado

import 'forgot_password_screen.dart';
import 'register_screen.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  // 🚀 UX INTERAÇÃO: Variável visual de olho mantida na View
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =========================================================================
  // ⚙️ GATILHO DO CONTROLADOR (Views limpas de requisições HTTP!)
  // =========================================================================
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    // 🎯 Delegamos o disparo para o método centralizado do AuthController
    final bool success = await ref.read(authProvider).login(
      _emailController.text.trim(),
      _passwordController.text,
    );

    if (success && mounted) {
      final user = ref.read(authProvider).currentUser;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Sessão iniciada como ${user?.name ?? "Estudante"}! 🎉'),
          backgroundColor: const Color(0xFF27AE60),
        ),
      );

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const NotebooksListScreen()), // ✅ Novo e Elevado!
            (route) => false,
      );
    }
  }

  // =========================================================================
  // 🎨 INTERFACE VISUAL PREMIUM (Consome o estado global do AuthController)
  // =========================================================================
  @override
  Widget build(BuildContext context) {
    // 📢 Assistimos ao controlador para reagir a loadings e erros de forma síncrona
    final authController = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 40.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // 🌟 HEADER DO LOGOTIPO CHIC
                Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(color: const Color(0xFF0F4C5C).withOpacity(0.1), blurRadius: 24, offset: const Offset(0, 8)),
                    ],
                  ),
                  child: const Icon(Icons.menu_book_rounded, size: 48, color: Color(0xFF0F4C5C)),
                ),
                const SizedBox(height: 24),

                Text(
                  'Caderno Digital',
                  style: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24)),
                ),
                const SizedBox(height: 8),
                Text(
                  'A sua secretária de estudo comunitária.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 15, color: Colors.black54, fontWeight: FontWeight.w400),
                ),

                const SizedBox(height: 40),

                // 💳 CARTÃO DO FORMULÁRIO BLINDADO
                Container(
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.black.withOpacity(0.04)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 30, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('E-mail Institucional', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          style: GoogleFonts.inter(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: 'exemplo@estudante.ao',
                            hintStyle: const TextStyle(color: Colors.black26),
                            prefixIcon: const Icon(Icons.alternate_email_rounded, size: 20, color: Colors.black45),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F4C5C), width: 1.5)),
                          ),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Introduza o seu e-mail';
                            if (!val.contains('@')) return 'E-mail com formato inválido';
                            return null;
                          },
                        ),

                        const SizedBox(height: 24),

                        Text('Palavra-passe', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.inter(fontSize: 15),
                          decoration: InputDecoration(
                            hintText: '••••••••••••',
                            hintStyle: const TextStyle(color: Colors.black26),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20, color: Colors.black45),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 20, color: Colors.black45),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F4C5C), width: 1.5)),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Introduza a palavra-passe';
                            if (val.length < 6) return 'Mínimo de 6 caracteres';
                            return null;
                          },
                        ),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            style: TextButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()));
                            },
                            child: Text('Esqueceu a palavra-passe?', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: const Color(0xFF0F4C5C))),
                          ),
                        ),

                        // 🪄 ANIMAÇÃO FLUIDA DE ERRO (Lê a mensagem centralizada no Controller)
                        AnimatedSize(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                          child: authController.authErrorMessage == null
                              ? const SizedBox.shrink()
                              : Padding(
                            padding: const EdgeInsets.only(top: 16.0),
                            child: Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.redAccent.withOpacity(0.08),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.redAccent.withOpacity(0.3)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.error_outline_rounded, size: 18, color: Colors.redAccent),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      authController.authErrorMessage!,
                                      style: GoogleFonts.inter(fontSize: 13, color: Colors.red[700], fontWeight: FontWeight.w600),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),

                        const SizedBox(height: 32),

                        // 🔘 BOTÃO DE LOGIN REATIVO
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F4C5C),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: authController.isLoading ? null : _handleLogin,
                            child: authController.isLoading
                                ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text('Abrir Caderno', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // 🦶 RODAPÉ
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('É um novo estudante?', style: GoogleFonts.inter(fontSize: 14, color: Colors.black54)),
                    const SizedBox(width: 4),
                    InkWell(
                      borderRadius: BorderRadius.circular(4),
                      onTap: () {
                        Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 2.0),
                        child: Text(
                          'Criar conta',
                          style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C)),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}