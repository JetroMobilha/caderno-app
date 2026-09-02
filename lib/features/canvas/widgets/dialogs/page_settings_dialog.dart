import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
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

  @override
  void initState() {
    super.initState();
    _currentConfig = widget.page.toConfig;
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(canvasDocumentProvider);
    
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
          child: PageConfigurationForm(
            config: _currentConfig,
            page: widget.page, // 🚀 Passar página para aviso de orientação
            minPaperLevel: minLevel, // 🚀 Passar nível para bloqueio de tamanho
            onChanged: (newConfig) {
              setState(() {
                _currentConfig = newConfig;
              });
              // 🚀 FEEDBACK EM TEMPO REAL
              ref.read(canvasDocumentProvider.notifier).updatePageSettings(widget.page, newConfig);
            },
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
}
