import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/local_page_model.dart';
import '../../../notebooks/widgets/page_configuration_form.dart';
import '../../../notebooks/models/notebook_configuration.dart';
import '../../../../core/utils/geometry_utils.dart'; // 🚀 NOVO

class PageSettingsDialog extends ConsumerStatefulWidget {
  final LocalPage page;

  const PageSettingsDialog({
    super.key,
    required this.page,
  });

  @override
  ConsumerState<PageSettingsDialog> createState() => _PageSettingsDialogState();
}

class _PageSettingsDialogState extends ConsumerState<PageSettingsDialog> {
  late NotebookConfiguration _currentConfig;
  bool _isUploadingBg = false;

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.page.toConfig;
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(canvasDocumentProvider);
    final targetPage = docState.pages.cast<LocalPage?>().firstWhere(
          (p) =>
              p?.clientId == widget.page.clientId ||
              (p != null && p.id == widget.page.id),
          orElse: () => widget.page,
        ) ??
        widget.page;

    // 🚀 Calcular Nível Superior do Caderno
    int minLevel = 6;
    for (var p in docState.pages) {
      final int level = GeometryUtils.getPaperLevel(p.paperSize, isInfinite: p.isInfinite);
      if (level < minLevel) minLevel = level;
    }

    return AlertDialog(
      backgroundColor: const Color(0xFFFDFBF7),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), // 🚀 MAIS ESPAÇO
      title: Text(
        'Configurar Folha',
        style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C)),
      ),
      content: SizedBox(
        width: MediaQuery.of(context).size.width > 600 ? 500 : MediaQuery.of(context).size.width * 0.95,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageConfigurationForm(
                config: _currentConfig,
                page: targetPage, // 🚀 Passar página para aviso de orientação
                minPaperLevel: minLevel, // 🚀 Passar nível para bloqueio de tamanho
                onChanged: (newConfig) {
                  setState(() {
                    _currentConfig = newConfig;
                  });
                  // 🚀 FEEDBACK EM TEMPO REAL
                  ref.read(canvasDocumentProvider.notifier).updatePageSettings(targetPage, newConfig);
                },
              ),
              const SizedBox(height: 8),
              _buildBackgroundImageSection(targetPage),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('FECHAR', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F4C5C))),
        ),
      ],
    );
  }

  Widget _buildBackgroundImageSection(LocalPage targetPage) {
    final bool hasImage = targetPage.backgroundPdfPath != null && targetPage.backgroundPdfPath!.isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 8.0, bottom: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: Text(
              'Imagem de Fundo',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (_isUploadingBg)
            const Center(child: Padding(
              padding: EdgeInsets.all(16.0),
              child: CircularProgressIndicator(color: Color(0xFF0F4C5C)),
            ))
          else
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickBackgroundImage(targetPage),
                    icon: const Icon(Icons.image_search_rounded, size: 18),
                    label: Text(hasImage ? 'Trocar Imagem de Fundo' : 'Adicionar Fundo'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF0F4C5C),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                if (hasImage) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => _clearBackgroundImage(targetPage),
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    tooltip: 'Remover Fundo',
                  ),
                ],
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _pickBackgroundImage(LocalPage targetPage) async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;

    final applyToAll = await _askApplyToAllDialog();
    if (applyToAll == null) return; // cancelado

    setState(() => _isUploadingBg = true);
    try {
      await ref.read(canvasDocumentProvider.notifier).setPageBackgroundImage(targetPage, file.path, applyToAll: applyToAll);
    } finally {
      if (mounted) setState(() => _isUploadingBg = false);
    }
  }

  Future<void> _clearBackgroundImage(LocalPage targetPage) async {
    final applyToAll = await _askApplyToAllDialog(isClear: true);
    if (applyToAll == null) return; // cancelado

    setState(() => _isUploadingBg = true);
    try {
      await ref.read(canvasDocumentProvider.notifier).setPageBackgroundImage(targetPage, null, applyToAll: applyToAll);
    } finally {
      if (mounted) setState(() => _isUploadingBg = false);
    }
  }

  Future<bool?> _askApplyToAllDialog({bool isClear = false}) async {
    return showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(isClear ? 'Remover Fundo' : 'Aplicar Fundo', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
        content: Text(
          isClear 
              ? 'Deseja remover o fundo apenas desta página ou de todas as páginas do caderno?'
              : 'Deseja aplicar esta imagem apenas nesta página ou em todas as páginas do caderno?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, null),
            child: const Text('CANCELAR', style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('SÓ NESTA', style: TextStyle(color: Color(0xFF0F4C5C), fontWeight: FontWeight.bold)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('EM TODAS', style: TextStyle(color: Color(0xFF0F4C5C), fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
