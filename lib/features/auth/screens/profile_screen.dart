import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';

import '../../../core/network/api_service.dart';
import '../models/user_model.dart';
import '../providers/user_provider.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  File? _selectedImage;
  bool _isUpdating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(userProvider);
      if (currentUser != null) {
        _nameController.text = currentUser.name;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 50,
      maxWidth: 800,     // 🚀 Limite de largura
      maxHeight: 800,    // 🚀 Limite de altura adicionado
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) return;

    setState(() {
      _isUpdating = true;
      _errorMessage = null;
    });

    try {
      final api = ApiService();
      final response = await api.updateProfile(
        name: _nameController.text.trim(),
        imageFile: _selectedImage,
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200) {
        final Map<String, dynamic> userMap = responseData['user'];
        final updatedUser = User.fromJson(userMap);

        await api.saveUserData(userMap);
        ref.read(userProvider.notifier).setUser(updatedUser);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Perfil atualizado com sucesso!'),
              backgroundColor: Color(0xFF27AE60),
              behavior: SnackBarBehavior.floating, // Estilo flutuante
            ),
          );
          Navigator.pop(context);
        }
      } else {
        setState(() {
          _errorMessage = responseData['message'] ?? 'Erro ao atualizar perfil.';
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Falha no motor interno ou perda de ligação à rede.';
      });
      print('🚨 ERRO NO PROFILE_SCREEN: $e');
    } finally {
      if (mounted) setState(() => _isUpdating = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(userProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text('Meu Perfil', style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 22)),
        backgroundColor: const Color(0xFF0F4C5C),
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // 🚀 CABEÇALHO CURVO COM FOTO SOBREPOSTA
            Stack(
              alignment: Alignment.topCenter,
              children: [
                // Fundo Azul Curvo
                Container(
                  height: 120,
                  decoration: const BoxDecoration(
                    color: Color(0xFF0F4C5C),
                    borderRadius: BorderRadius.only(
                      bottomLeft: Radius.circular(40),
                      bottomRight: Radius.circular(40),
                    ),
                  ),
                ),

                // Espaçador invisível para a Stack ter altura suficiente
                const SizedBox(height: 190),

                // Avatar
                Positioned(
                  top: 40,
                  child: GestureDetector(
                    onTap: _isUpdating ? null : _pickImage,
                    child: Stack(
                      children: [
                        // Borda branca grossa com sombra
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 4),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 15, offset: const Offset(0, 8)),
                            ],
                          ),
                          child: CircleAvatar(
                            radius: 64,
                            backgroundColor: const Color(0xFFFDFBF7),
                            backgroundImage: _selectedImage != null
                                ? FileImage(_selectedImage!)
                                : (currentUser?.avatar != null
                                ? NetworkImage(currentUser!.avatar!)
                                : null) as ImageProvider?,
                            child: _selectedImage == null && currentUser?.avatar == null
                                ? const Icon(Icons.person, size: 64, color: Color(0xFFBDC3C7))
                                : null,
                          ),
                        ),
                        // Botão flutuante de edição
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD35400), // Laranja tático de destaque
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
                              boxShadow: [
                                BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 4, offset: const Offset(0, 2)),
                              ],
                            ),
                            child: const Icon(Icons.edit_rounded, size: 16, color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            // 🚀 CORPO DO FORMULÁRIO
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 10),

                    // NOME DO ALUNO NO CENTRO (Opcional, dá um toque premium)
                    Center(
                      child: Text(
                        currentUser?.name ?? 'Estudante',
                        style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    // CARTÃO DE IDENTIFICAÇÃO (E-MAIL BLINDADO)
                    Text('Credencial de Acesso', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200.withOpacity(0.6), // Cinza bem suave
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.black.withOpacity(0.04)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.email_outlined, size: 20, color: Colors.black54),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('E-mail Institucional', style: GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
                                const SizedBox(height: 2),
                                Text(
                                  currentUser?.email ?? 'carregando...',
                                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.lock_outline, size: 16, color: Colors.black26), // Símbolo de inalterável
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

                    // CAMPO DE EDIÇÃO DO NOME
                    Text('Informações Pessoais', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45)),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _nameController,
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF2C3E50)),
                      decoration: InputDecoration(
                        labelText: 'Nome Completo',
                        labelStyle: const TextStyle(color: Colors.black45),
                        prefixIcon: const Icon(Icons.person_outline_rounded, color: Colors.black45),
                        filled: true,
                        fillColor: Colors.white,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: Color(0xFF0F4C5C), width: 1.5),
                        ),
                      ),
                    ),

                    // MENSAGEM DE ERRO
                    if (_errorMessage != null) ...[
                      const SizedBox(height: 20),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: Row(
                          children: [
                            const Icon(Icons.error_outline_rounded, size: 16, color: Colors.redAccent),
                            const SizedBox(width: 8),
                            Expanded(child: Text(_errorMessage!, style: GoogleFonts.inter(fontSize: 13, color: Colors.red[800], fontWeight: FontWeight.w600))),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 40),

                    // 🚀 BOTÃO DE AÇÃO
                    SizedBox(
                      width: double.infinity,
                      height: 54, // Botão um pouco mais alto e imponente
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4C5C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: const Color(0xFF0F4C5C).withOpacity(0.4),
                        ),
                        onPressed: _isUpdating ? null : _saveProfile,
                        child: _isUpdating
                            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : Text('Guardar Alterações', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}