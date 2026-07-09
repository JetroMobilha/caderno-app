import 'dart:convert';
import 'package:flutter/foundation.dart'; // 🚀 O ESCUDO WEB
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/network/api_service.dart';
import '../../subjects/screens/subjects_screen.dart';
import '../models/user_model.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/user_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  String? _serverErrorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  // =========================================================================
  // 🚀 DISPARADOR DE REGISTO LARAVEL SANCTUM
  // =========================================================================
  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _serverErrorMessage = null;
    });

    try {
      final api = ApiService();

      final response = await api.post('/register', {
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'password': _passwordController.text,
      }, requireAuth: false);

      final Map<String, dynamic> responseData = jsonDecode(response.body);

      if (response.statusCode == 200 || response.statusCode == 201) {

        final String token = responseData['token'] ?? responseData['access_token'];
        final Map<String, dynamic> userMap = responseData['user'];

        await api.saveToken(token);
        await api.saveUserData(userMap);

        final user = User.fromJson(userMap);
        ref.read(userProvider.notifier).setUser(user);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Conta criada com sucesso! Bem-vindo, ${userMap['name']}!'),
              backgroundColor: const Color(0xFF27AE60),
            ),
          );

          // 🚀 SALTO TÁTICO HÍBRIDO
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(builder: (_) => const SubjectsScreen()),
                (route) => false,
          );
        }
      } else if (response.statusCode == 422) {
        final Map<String, dynamic> errors = responseData['errors'];
        setState(() => _serverErrorMessage = errors.values.first[0]);
      } else {
        setState(() => _serverErrorMessage = responseData['message'] ?? 'Não foi possível concluir o registo.');
      }
    } catch (e) {
      debugPrint('🚨 ERRO INTERNO (Registo): $e');
      setState(() => _serverErrorMessage = 'Sem ligação ao Quartel-General. Verifique a internet.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A1A24), size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 10.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: const Color(0xFF0F4C5C).withOpacity(0.08), shape: BoxShape.circle),
                  child: const Icon(Icons.person_add_alt_1_rounded, size: 48, color: Color(0xFF0F4C5C)),
                ),
                const SizedBox(height: 16),
                Text('Criar Caderno', style: GoogleFonts.lora(fontSize: 30, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24))),
                const SizedBox(height: 6),
                Text('Preencha os seus dados institucionais.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: Colors.black54, fontWeight: FontWeight.w500)),
                const SizedBox(height: 32),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.black.withOpacity(0.06)),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, 10))],
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Nome Completo', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _nameController,
                          textCapitalization: TextCapitalization.words,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: _buildInputDecoration('Ex: Jetro Domingos', Icons.person_outline_rounded),
                          validator: (val) => val == null || val.trim().length < 3 ? 'Introduza o seu nome completo' : null,
                        ),
                        const SizedBox(height: 16),

                        Text('E-mail institucional', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          autocorrect: false,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: _buildInputDecoration('estudante@caderno.ao', Icons.alternate_email_rounded),
                          validator: (val) {
                            if (val == null || val.trim().isEmpty) return 'Introduza o e-mail';
                            if (!val.contains('@') || !val.contains('.')) return 'E-mail inválido';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        Text('Palavra-passe', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: _buildPasswordDecoration('Mínimo 8 caracteres', _obscurePassword, () => setState(() => _obscurePassword = !_obscurePassword)),
                          validator: (val) => val == null || val.length < 6 ? 'A senha deve ter pelo menos 8 caracteres' : null,
                        ),
                        const SizedBox(height: 16),

                        Text('Confirmar Palavra-passe', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50))),
                        const SizedBox(height: 8),
                        TextFormField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          style: GoogleFonts.inter(fontSize: 14),
                          decoration: _buildPasswordDecoration('Repita a senha', _obscureConfirmPassword, () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword)),
                          validator: (val) {
                            if (val != _passwordController.text) return 'As palavras-passe não coincidem';
                            return null;
                          },
                        ),

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
                            onPressed: _isLoading ? null : _handleRegister,
                            child: _isLoading
                                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                                : Text('Registar e Entrar', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text('Já possui uma conta?', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text('Iniciar sessão', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
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

  InputDecoration _buildInputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black26),
      prefixIcon: Icon(icon, size: 18, color: Colors.black45),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F4C5C), width: 1.5)),
    );
  }

  InputDecoration _buildPasswordDecoration(String hint, bool isObscured, VoidCallback onToggle) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: Colors.black26),
      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 18, color: Colors.black45),
      suffixIcon: IconButton(
        icon: Icon(isObscured ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 18, color: Colors.black45),
        onPressed: onToggle,
      ),
      filled: true,
      fillColor: const Color(0xFFF8F9FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF0F4C5C), width: 1.5)),
    );
  }
}