import 'dart:io';
import 'package:flutter/foundation.dart'; // 🚀 O ESCUDO WEB
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_service.dart';
import '../controllers/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(authProvider).currentUser;
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
      maxWidth: 800,
      maxHeight: 800,
    );

    if (pickedFile != null) {
      setState(() {
        _selectedImage = pickedFile;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (_nameController.text.trim().isEmpty) return;

    // Dispara a atualização centralizada no controlador
    final bool success = await ref.read(authProvider).updateProfile(
      name: _nameController.text.trim(),
      imageFile: _selectedImage,
    );

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil atualizado com sucesso! ✨'),
          backgroundColor: Color(0xFF27AE60),
          behavior: SnackBarBehavior.floating,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authController = ref.watch(authProvider);
    final currentUser = authController.currentUser;

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
            Stack(
              alignment: Alignment.topCenter,
              children: [
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
                const SizedBox(height: 190),

                Positioned(
                  top: 40,
                  child: GestureDetector(
                    onTap: authController.isLoading ? null : _pickImage,
                    child: Stack(
                      children: [
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
                                ? (kIsWeb ? NetworkImage(_selectedImage!.path) : FileImage(File(_selectedImage!.path))) as ImageProvider
                                : (currentUser?.avatar != null
                                ? NetworkImage("${ApiService.baseUrlImagem}${currentUser!.avatar!}")
                                : null) as ImageProvider?,
                            child: _selectedImage == null && currentUser?.avatar == null
                                ? const Icon(Icons.person, size: 64, color: Color(0xFFBDC3C7))
                                : null,
                          ),
                        ),
                        Positioned(
                          bottom: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: const Color(0xFFD35400),
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.white, width: 3),
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

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28.0),
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 420),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Text(
                        currentUser?.name ?? 'Estudante',
                        style: GoogleFonts.lora(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    Text('Credencial de Acesso', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade200.withOpacity(0.6),
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
                                  currentUser?.email ?? 'A carregar...',
                                  style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.lock_outline, size: 16, color: Colors.black26),
                        ],
                      ),
                    ),

                    const SizedBox(height: 24),

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

                    AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                      child: authController.authErrorMessage == null
                          ? const SizedBox.shrink()
                          : Padding(
                        padding: const EdgeInsets.only(top: 20.0),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(color: Colors.redAccent.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                          child: Row(
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 16, color: Colors.redAccent),
                              const SizedBox(width: 8),
                              Expanded(child: Text(authController.authErrorMessage!, style: GoogleFonts.inter(fontSize: 13, color: Colors.red[800], fontWeight: FontWeight.w600))),
                            ],
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 40),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF0F4C5C),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 4,
                          shadowColor: const Color(0xFF0F4C5C).withOpacity(0.4),
                        ),
                        onPressed: authController.isLoading ? null : _saveProfile,
                        child: authController.isLoading
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