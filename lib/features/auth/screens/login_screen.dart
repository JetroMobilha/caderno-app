import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;

import '../../../core/network/api_service.dart';
import '../../../core/network/sync_service.dart';
import '../../subjects/providers/subject_provider.dart';
import '../../subjects/screens/subjects_screen.dart';
import '../models/user_model.dart';
import 'forgot_password_screen.dart';
import 'register_screen.dart'; // Requer o pacote 'http' no pubspec.yaml

import 'package:flutter_riverpod/flutter_riverpod.dart'; // 🚀 O Rádio
import '../providers/user_provider.dart';                 // 🚀 O Transmissor

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _serverErrorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // =========================================================================
  // 🔐 DISPARADOR DE AUTENTICAÇÃO LARAVEL SANCTUM / JWT
  // =========================================================================
  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _serverErrorMessage = null;
    });

    try {
      final api = ApiService();

      // 🚀 CUMPRINDO O CONTRATO LARAVEL: Chave 'login_id' e requireAuth: false
      final response = await api.post('/login', {
        'login_id': _emailController.text.trim(),
        'password': _passwordController.text,
      }, requireAuth: false);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {

        final String token = responseData['access_token'];
        final Map<String, dynamic> userMap = responseData['user'];

        // 💾 GRAVA NO COFRE CRIPTOGRAFADO DO SISTEMA OPERACIONAL
        await api.saveToken(token);
        await api.saveUserData(userMap);

        final user = User.fromJson(userMap);
        ref.read(userProvider.notifier).setUser(user);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Sessão iniciada como ${userMap['name']}!'), backgroundColor: const Color(0xFF27AE60)),
          );
          try {
            final syncService = SyncService();
            await syncService.pullSubjects(); // Puxa do servidor para o SQLite local

            // 4. Obriga o Riverpod a ler o SQLite atualizado
            ref.invalidate(subjectProvider);
          } catch (e) {
            print('⚠️ Pull inicial falhou (sem internet?), a prosseguir offline: $e');
          }
          // 🚀 REDIRECIONAMENTO REAL: Destrói o ecrã de login e abre as disciplinas
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SubjectsScreen()),
                (route) => false,
          );
        }
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> errors = responseData['errors'];
        setState(() => _serverErrorMessage = errors.values.first[0]);
      } else if (response.statusCode == 429) {
        setState(() => _serverErrorMessage = 'Muitas tentativas! Bloqueado por segurança durante 1 minuto.');
      } else {
        setState(() => _serverErrorMessage = responseData['message'] ?? 'Credenciais inválidas.');
      }
    } catch (e) {
      // 🕵️‍♂️ NOVO RADAR: Imprime o erro real do Dart na consola preta para nunca mais seres enganado!
      print('🚨 ERRO INTERNO DO FLUTTER: $e');
      setState(() => _serverErrorMessage = 'Erro de sistema: Servidor ou leitura de dados falhou.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // O fundo creme clássico do nosso papel
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 40.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420), // Trava tática para ficar elegante no Windows/PC
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [

                // 1. LOGOTIPO EDITORIAL
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F4C5C).withOpacity(0.08),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.menu_book_rounded, size: 56, color: Color(0xFF0F4C5C)),
                ),
                const SizedBox(height: 20),

                Text(
                  'Caderno Digital',
                  style: GoogleFonts.lora(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24)),
                ),
                const SizedBox(height: 6),
                Text(
                  'A sua secretária de estudo comunitária.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500),
                ),

                const SizedBox(height: 40),

                // 2. CARTÃO DE FORMULÁRIO
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                    boxShadow: [
                      BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10)),
                    ],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [

                        Text('E-mail institucional', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: 'exemplo@estudante.ao',
                            hintStyle: const TextStyle(color: Colors.black26),
                            prefixIcon: const Icon(Icons.alternate_email_rounded, size: 18, color: Colors.black45),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
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

                        const SizedBox(height: 20),

                        Text('Palavra-passe', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: '••••••••••••',
                            hintStyle: const TextStyle(color: Colors.black26),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.black45),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: Colors.black45),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            filled: true,
                            fillColor: const Color(0xFFF8F9FA),
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F4C5C), width: 1.5)),
                          ),
                          validator: (val) {
                            if (val == null || val.isEmpty) return 'Introduza a palavra-passe';
                            if (val.length < 6) return 'Mínimo de 8 caracteres';
                            return null;
                          },
                        ),

                        // BANNER DE ERRO DO SERVIDOR
                        if (_serverErrorMessage != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline_rounded, size: 16, color: Colors.redAccent),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_serverErrorMessage!, style: GoogleFonts.inter(fontSize: 12, color: Colors.red[800], fontWeight: FontWeight.w600))),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 28),

                        // BOTÃO PRINCIPAL DE ACESSO
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0F4C5C),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            onPressed: _isLoading ? null : _handleLogin,
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text('Abrir Caderno', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // RODAPÉ DE REGISTO
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('É um novo estudante?', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                    TextButton(
                      onPressed: () {
                        // 🚀 LIGAÇÃO FÍSICA AO NOVO ECRÃ
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const RegisterScreen()),
                        );
                      },
                      child: Text('Criar conta', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Esqueceu a senha?', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                    TextButton(
                      onPressed: () {
                        // 🚀 LIGAÇÃO FÍSICA AO NOVO ECRÃ
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const ForgotPasswordScreen()),
                        );
                      },
                      child: Text('Recuper conta', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
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