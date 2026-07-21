import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../auth/controllers/auth_controller.dart';
import '../../notebooks/models/notebook_model.dart';
import '../../notebooks/controllers/notebooks_controller.dart';
import '../../subjects/controllers/subjects_controller.dart';

class PublishNotebookSheet extends ConsumerStatefulWidget {
  final Notebook notebook;

  const PublishNotebookSheet({super.key, required this.notebook});

  @override
  ConsumerState<PublishNotebookSheet> createState() => _PublishNotebookSheetState();
}

class _PublishNotebookSheetState extends ConsumerState<PublishNotebookSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _authorController;
  late TextEditingController _descController;
  late TextEditingController _priceController;

  bool _isPublished = false;
  bool _isFree = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final user = ref.read(authProvider).currentUser;

    _isPublished = widget.notebook.isPublished == 1;
    _isFree = widget.notebook.price == 0;

    _authorController = TextEditingController(
      text: widget.notebook.authorName ?? user?.name ?? 'Autor Académico',
    );
    _descController = TextEditingController(
      text: widget.notebook.description ?? '',
    );
    _priceController = TextEditingController(
      text: widget.notebook.price > 0 ? widget.notebook.price.toStringAsFixed(0) : '',
    );
  }

  @override
  void dispose() {
    _authorController.dispose();
    _descController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final themeColor = AppColors.primary; // #0F4C5C
    final accentColor = AppColors.accent; // #27AE60

    return Container(
      padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
      decoration: const BoxDecoration(
        color: AppColors.paper, // #FDFBF7
        borderRadius: BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- CABEÇALHO DO MODAL (🚀 CORRIGIDO: Totalmente flexível sem cortar texto) ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(color: themeColor.withOpacity(0.1), shape: BoxShape.circle),
                          child: Icon(Icons.storefront_rounded, color: themeColor, size: 24),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 2), // Ligeiro alinhamento visual com o ícone
                              Text('Publicar na Loja', style: GoogleFonts.inter(fontSize: 17, fontWeight: FontWeight.bold, color: AppColors.textDark)),
                              const SizedBox(height: 2),
                              Text(
                                'Disponibiliza o teu conteúdo na comunidade',
                                style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textMuted, height: 1.2),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 16),

              // --- TOGGLE DE ATIVAÇÃO NA LOJA (🚀 CORRIGIDO: Apenas com Material, sem blocos duplicados!) ---
              Material(
                color: _isPublished ? accentColor.withOpacity(0.1) : Colors.grey.withOpacity(0.08),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: _isPublished ? accentColor : Colors.transparent, width: 1.5),
                ),
                clipBehavior: Clip.antiAlias,
                child: Padding(
                  padding: const EdgeInsets.all(4), // Respiro para o efeito de onda não bater no canto
                  child: SwitchListTile(
                    activeColor: accentColor,
                    title: Text(
                      _isPublished ? 'Visível no Marketplace 🟢' : 'Privado (Fora da Loja) ⚪',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5, color: AppColors.textDark),
                    ),
                    subtitle: Text(
                      _isPublished ? 'Qualquer estudante poderá encontrar este caderno.' : 'O caderno está visível apenas na tua secretária.',
                      style: GoogleFonts.inter(fontSize: 11.5, color: AppColors.textMuted),
                    ),
                    value: _isPublished,
                    onChanged: (val) => setState(() => _isPublished = val),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Se estiver ativado para publicar, mostra os campos de edição da loja
              if (_isPublished) ...[
                Text('Nome do Autor / Professor', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _authorController,
                  decoration: InputDecoration(
                    hintText: 'Ex: Prof. Jetro Domingos',
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: 20),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'O nome do autor é obrigatório' : null,
                ),
                const SizedBox(height: 16),

                Text('Sinopse / Descrição do Caderno', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descController,
                  maxLines: 3,
                  decoration: InputDecoration(
                    hintText: 'Explica o que os alunos vão encontrar neste caderno (resumos, exercícios, fórmulas)...',
                    filled: true, fillColor: Colors.white,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                  ),
                  validator: (val) => val == null || val.trim().isEmpty ? 'Escreve uma pequena descrição' : null,
                ),
                const SizedBox(height: 16),

                Text('Modelo de Distribuição', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _buildChoiceChip(
                        label: 'GRÁTIS 🎁',
                        isSelected: _isFree,
                        color: accentColor,
                        onTap: () => setState(() {
                          _isFree = true;
                          _priceController.clear();
                        }),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildChoiceChip(
                        label: 'PREMIUM / PAGO 💎',
                        isSelected: !_isFree,
                        color: themeColor,
                        onTap: () => setState(() => _isFree = false),
                      ),
                    ),
                  ],
                ),

                if (!_isFree) ...[
                  const SizedBox(height: 16),
                  Text('Preço de Venda (em Kwanzas - Kz)', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.textMuted)),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _priceController,
                    keyboardType: TextInputType.number,
                    decoration: InputDecoration(
                      hintText: 'Ex: 1500',
                      suffixText: 'Kz',
                      suffixStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, color: themeColor),
                      filled: true, fillColor: Colors.white,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      prefixIcon: const Icon(Icons.sell_outlined, size: 20),
                    ),
                    validator: (val) {
                      if (_isFree) return null;
                      if (val == null || val.isEmpty) return 'Define um preço';
                      if ((double.tryParse(val) ?? 0) <= 0) return 'Preço inválido';
                      return null;
                    },
                  ),
                ],
              ],

              const SizedBox(height: 24),

              // --- BOTÃO DE CONFIRMAÇÃO ---
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _isPublished ? (_isFree ? accentColor : themeColor) : Colors.redAccent,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    elevation: 2,
                  ),
                  onPressed: _isLoading ? null : _handlePublish,
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Text(
                    _isPublished ? 'PUBLICAR NA LOJA 🚀' : 'RETIRAR DA LOJA 🗑️',
                    style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14, letterSpacing: 0.5),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChoiceChip({required String label, required bool isSelected, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: 12),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 1.5),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 8, offset: const Offset(0, 3))] : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            fontSize: 12.5,
            color: isSelected ? Colors.white : AppColors.textDark,
          ),
        ),
      ),
    );
  }

  Future<void> _handlePublish() async {
    if (_isPublished && !_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final notebooksNotifier = ref.read(notebooksProvider.notifier);
    final subjectsNotifier = ref.read(subjectsProvider.notifier);

    try {
      final double price = _isPublished && !_isFree ? (double.tryParse(_priceController.text.trim()) ?? 0.0) : 0.0;

      // 1. Atualizamos o objeto do caderno com as novas propriedades da Loja
      final cadernoAtualizado = widget.notebook.copyWith(
        isPublished: _isPublished ? 1 : 0,
        authorName: _isPublished ? _authorController.text.trim() : widget.notebook.authorName,
        description: _isPublished ? _descController.text.trim() : widget.notebook.description,
        price: price,
      );

      // 2. Gravamos no SQLite local e marcamos para sincronizar
      await notebooksNotifier.updateNotebook(cadernoAtualizado);

      // 3. Disparamos a sincronização para enviar a novidade logo para o servidor do Laravel!
      await subjectsNotifier.syncManuallyWithCloud();

      if (mounted) {
        Navigator.pop(context);
        scaffoldMessenger.showSnackBar(
          SnackBar(
            content: Text(_isPublished ? 'Caderno publicado no Marketplace com sucesso! 🛒✨' : 'Caderno removido da loja.'),
            backgroundColor: _isPublished ? AppColors.accent : Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        scaffoldMessenger.showSnackBar(SnackBar(content: Text('Erro ao publicar: $e'), backgroundColor: AppColors.error));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}