import 'dart:io' as io;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';

import '../../handwriting/views/handwriting_training_screen.dart';
import '../../../core/network/api_service.dart';
import '../controllers/auth_controller.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  final _nameController = TextEditingController();
  final _bioController = TextEditingController();
  final _institutionController = TextEditingController();
  final _specialtiesController = TextEditingController();
  String? _selectedColorHex;
  XFile? _selectedImage;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final currentUser = ref.read(authProvider).currentUser;
      if (currentUser != null) {
        _nameController.text = currentUser.name;
        _bioController.text = currentUser.bio ?? '';
        _institutionController.text = currentUser.institution ?? '';
        _specialtiesController.text = currentUser.specialties ?? '';
        _selectedColorHex = currentUser.preferredColor;
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _bioController.dispose();
    _institutionController.dispose();
    _specialtiesController.dispose();
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

    FocusScope.of(context).unfocus();

    final bool success = await ref.read(authProvider.notifier).updateProfile(
      name: _nameController.text.trim(),
      imageFile: _selectedImage,
      bio: _bioController.text.trim(),
      institution: _institutionController.text.trim(),
      preferredColor: _selectedColorHex,
      specialties: _specialtiesController.text.trim(),
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
    final themeColor = _selectedColorHex != null 
        ? Color(int.parse(_selectedColorHex!.replaceFirst('#', '0xFF')))
        : Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text('Meu Perfil', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20)),
        backgroundColor: themeColor,
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
                  decoration: BoxDecoration(
                    color: themeColor,
                    borderRadius: const BorderRadius.only(
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
                                ? (kIsWeb ? NetworkImage(_selectedImage!.path) : FileImage(io.File(_selectedImage!.path))) as ImageProvider
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
                        style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.bold, color: const Color(0xFF2C3E50)),
                      ),
                    ),
                    const SizedBox(height: 32),

                    _buildSectionTitle('Credencial de Acesso'),
                    const SizedBox(height: 8),
                    _buildDisabledField(
                      icon: Icons.email_outlined,
                      label: 'E-mail Institucional',
                      value: currentUser?.email ?? 'A carregar...',
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Informações do Perfil'),
                    const SizedBox(height: 8),
                    _buildTextField(
                      controller: _nameController,
                      label: 'Nome Completo',
                      icon: Icons.person_outline_rounded,
                      themeColor: themeColor,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _bioController,
                      label: 'Bio / Frase de Status',
                      icon: Icons.chat_bubble_outline_rounded,
                      themeColor: themeColor,
                      maxLines: 2,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _institutionController,
                      label: 'Instituição / Universidade',
                      icon: Icons.account_balance_rounded,
                      themeColor: themeColor,
                    ),
                    const SizedBox(height: 12),
                    _buildTextField(
                      controller: _specialtiesController,
                      label: 'Especialidades (ex: Cálculo, Direito)',
                      icon: Icons.star_outline_rounded,
                      themeColor: themeColor,
                    ),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Preferências Visuais'),
                    const SizedBox(height: 8),
                    Text('Cor Favorita da Aplicação', style: GoogleFonts.inter(fontSize: 13, color: Colors.black54)),
                    const SizedBox(height: 12),
                    _buildColorSelector(),

                    const SizedBox(height: 24),

                    _buildSectionTitle('Personalização Académica'),
                    const SizedBox(height: 8),
                    _buildTrainingCard(themeColor),

                    const SizedBox(height: 40),

                    _buildSaveButton(authController.isLoading, themeColor),
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

  Widget _buildSectionTitle(String title) {
    return Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black45));
  }

  Widget _buildDisabledField({required IconData icon, required String label, required String value}) {
    return Container(
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
            child: Icon(icon, size: 20, color: Colors.black54),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
                const SizedBox(height: 2),
                Text(value, style: GoogleFonts.inter(fontSize: 14, color: Colors.black87, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, size: 16, color: Colors.black26),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required Color themeColor,
    int maxLines = 1,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w500, color: const Color(0xFF2C3E50)),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: Colors.black45),
        prefixIcon: Icon(icon, color: Colors.black45),
        filled: true,
        fillColor: Colors.white,
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.black.withOpacity(0.08)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: themeColor, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildColorSelector() {
    final colors = [
      '#0F4C5C', '#2C3E50', '#1B365D', '#D35400', '#16A085', '#8E44AD', '#C0392B'
    ];

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: colors.map((hex) {
        final color = Color(int.parse(hex.replaceFirst('#', '0xFF')));
        final isSelected = _selectedColorHex == hex;
        return GestureDetector(
          onTap: () => setState(() => _selectedColorHex = hex),
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
              border: Border.all(
                color: isSelected ? Colors.black : Colors.transparent,
                width: 2,
              ),
              boxShadow: [
                if (isSelected) BoxShadow(color: color.withOpacity(0.4), blurRadius: 8, spreadRadius: 2)
              ],
            ),
            child: isSelected ? const Icon(Icons.check, color: Colors.white, size: 20) : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildTrainingCard(Color themeColor) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.08)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Material(
        color: Colors.transparent,
        child: ListTile(
          onTap: () {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const HandwritingTrainingScreen()));
          },
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
            child: Icon(Icons.gesture_rounded, color: themeColor, size: 20),
          ),
          title: Text('Treinar Caligrafia Pessoal', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF2C3E50))),
          subtitle: Text('Digitaliza a tua letra para síntese de texto', style: GoogleFonts.inter(fontSize: 11, color: Colors.black45)),
          trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 14, color: Colors.black26),
        ),
      ),
    );
  }

  Widget _buildSaveButton(bool isLoading, Color themeColor) {
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          elevation: 4,
          shadowColor: themeColor.withOpacity(0.4),
        ),
        onPressed: isLoading ? null : _saveProfile,
        child: isLoading
            ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
            : Text('Guardar Alterações', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold)),
      ),
    );
  }
}
