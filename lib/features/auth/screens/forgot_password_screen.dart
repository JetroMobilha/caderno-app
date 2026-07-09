import 'package:flutter/foundation.dart'; // 🚀 O ESCUDO WEB
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/api_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  bool _isLoading = false;
  String? _serverMessage;
  bool _isError = false;

  Future<void> _handleSendCode() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _serverMessage = null;
    });

    try {
      final api = ApiService();
      final response = await api.forgotPassword(_emailController.text.trim());

      if (response.statusCode == 200) {
        if (mounted) {
          // 🚀 SALTO TÁTICO: Vai para o Ecrã 2 e leva o e-mail na mochila!
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => ResetPasswordScreen(email: _emailController.text.trim()),
            ),
          );
        }
      } else {
        setState(() {
          _isError = true;
          _serverMessage = 'Não encontrámos nenhuma conta com este e-mail.';
        });
      }
    } catch (e) {
      debugPrint('🚨 ERRO INTERNO (Forgot Password): $e');
      setState(() {
        _isError = true;
        _serverMessage = 'Falha ao contactar o quartel-general (Servidor).';
      });
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
        iconTheme: const IconThemeData(color: Color(0xFF0F4C5C)),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.lock_reset_rounded, size: 56, color: Color(0xFF0F4C5C)),
                  const SizedBox(height: 20),
                  Text(
                    'Recuperar Acesso',
                    style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24)),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Introduza o seu e-mail institucional. Vamos enviar-lhe um código de 6 dígitos para redefinir a palavra-passe.',
                    style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
                  ),
                  const SizedBox(height: 30),
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: GoogleFonts.inter(fontSize: 14),
                    decoration: InputDecoration(
                      hintText: 'exemplo@estudante.ao',
                      prefixIcon: const Icon(Icons.alternate_email, size: 18),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    validator: (val) => val == null || !val.contains('@') ? 'E-mail inválido' : null,
                  ),

                  if (_serverMessage != null) ...[
                    const SizedBox(height: 16),
                    Text(
                      _serverMessage!,
                      style: GoogleFonts.inter(fontSize: 13, color: _isError ? Colors.red[800] : Colors.green[800]),
                    ),
                  ],

                  const SizedBox(height: 28),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF0F4C5C),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      onPressed: _isLoading ? null : _handleSendCode,
                      child: _isLoading
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : Text('Enviar Código', style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: Colors.white)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}