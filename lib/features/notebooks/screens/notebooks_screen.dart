import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notebook_model.dart';
import '../providers/notebook_provider.dart';
import 'canvas_screen.dart';

class NotebooksScreen extends ConsumerStatefulWidget {
  final int subjectId;
  final String subjectName;

  const NotebooksScreen({
    super.key,
    required this.subjectId,
    required this.subjectName,
  });

  @override
  ConsumerState<NotebooksScreen> createState() => _NotebooksScreenState();
}

class _NotebooksScreenState extends ConsumerState<NotebooksScreen> {

  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchData();
  }

  Future<void> _fetchData() async {
    // 🚀 Pede ao Provider para ir buscar os dados reais ao SQLite
    await ref.read(notebookProvider.notifier).loadNotebooks(widget.subjectId);

    // Adicionamos um micro-delay intencional apenas para a animação respirar e ser suave
    await Future.delayed(const Duration(milliseconds: 300));

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final allNotebooks = ref.watch(notebookProvider);
    final notebooks = allNotebooks.where((n) => n.subject_id == widget.subjectId).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text(widget.subjectName, style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: Color(0xFF2C3E50), strokeWidth: 3),
            const SizedBox(height: 16),
            Text(
              'A organizar a estante...',
              style: GoogleFonts.inter(color: Colors.black54, fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ],
        ),
      )
          : notebooks.isEmpty
          ? Center(
        child: Text(
          'Nenhum caderno nesta disciplina.\nClique no + para começar!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.black45, fontSize: 14),
        ),
      )
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75,
          ),
          itemCount: notebooks.length,
          itemBuilder: (context, index) {
            return _buildNotebookCard(context, notebooks[index]);
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF2C3E50),
        foregroundColor: Colors.white,
        onPressed: () => _showAddNotebookDialog(context, ref),
        child: const Icon(Icons.add),
      ),
    );
  }

  // =========================================================================
  // 📚 RENDERIZADOR DE CAPA DE CADERNO (Com Sincronização Ativa pós-Canvas)
  // =========================================================================
  Widget _buildNotebookCard(BuildContext context, Notebook notebook) {
    final cardColor = notebook.color != null
        ? Color(int.parse(notebook.color!.replaceFirst('#', '0xFF')))
        : const Color(0xFF8B0000);

    return GestureDetector(
      // 🚀 SEGREDO TÁTICO: Transformado em ASYNC para escutar o retorno
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CanvasScreen(
              notebookId: notebook.id ?? 0,
              notebookTitle: notebook.title,
              lineType: notebook.line_type ?? 'ruled',
              paperSize: notebook.paper_size ?? 'A4',
            ),
          ),
        );

        // 🚀 O REFORÇO: No exato segundo em que o utilizador faz "Voltar" e sai
        // do caderno, a estante acorda e obriga o Riverpod a ler o SQLite de novo!
        if (mounted) {
          ref.read(notebookProvider.notifier).loadNotebooks(widget.subjectId);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0,
              top: 0,
              bottom: 0,
              width: 15,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(12),
                    bottomLeft: Radius.circular(12),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 12,
              left: 27,
              top: 40,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white.withOpacity(0.9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notebook.title,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Formato: ${notebook.paper_size}',
                      style: GoogleFonts.inter(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNotebookDialog(BuildContext context, WidgetRef ref) {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String selectedLineType = 'ruled';
    String selectedPaperSize = 'A4';
    String pickedColorHex = '#8B0000';

    final List<String> availableColors = ['#8B0000', '#2C3E50', '#1E8449', '#D35400', '#6C3483'];
    final Map<String, String> lineTypes = {
      'ruled': 'Pautado',
      'grid': 'Quadriculado',
      'blank': 'Liso / Em Branco',
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFFFDFBF7),
          title: Text('Novo Caderno', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(labelText: 'Título do Caderno', border: OutlineInputBorder()),
                    validator: (value) => value == null || value.trim().isEmpty ? 'Introduza o título' : null,
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedPaperSize,
                    decoration: const InputDecoration(labelText: 'Tamanho da Folha (Real para PDF)', border: OutlineInputBorder()),
                    items: ['A0', 'A1', 'A2', 'A3', 'A4', 'A5'].map((size) {
                      return DropdownMenuItem(value: size, child: Text(size));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setModalState(() => selectedPaperSize = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  DropdownButtonFormField<String>(
                    value: selectedLineType,
                    decoration: const InputDecoration(labelText: 'Estilo da Pauta', border: OutlineInputBorder()),
                    items: lineTypes.entries.map((entry) {
                      return DropdownMenuItem(value: entry.key, child: Text(entry.value));
                    }).toList(),
                    onChanged: (value) {
                      if (value != null) setModalState(() => selectedLineType = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  Text('Cor da Capa:', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: availableColors.map((hex) {
                      final isSelected = pickedColorHex == hex;
                      return GestureDetector(
                        onTap: () => setModalState(() => pickedColorHex = hex),
                        child: CircleAvatar(
                          backgroundColor: Color(int.parse(hex.replaceFirst('#', '0xFF'))),
                          radius: 14,
                          child: isSelected ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                        ),
                      );
                    }).toList(),
                  )
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50)),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  // 🚀 ALINHADO COM O TEU MODELO: Usando os sublinhados corretos (snake_case)
                  final newNotebook = Notebook(
                    subject_id: widget.subjectId,
                    title: titleController.text.trim(),
                    cover_type: 'color',        // Corrigido
                    color: pickedColorHex,
                    line_type: selectedLineType,  // Corrigido
                    paper_size: selectedPaperSize, // Corrigido
                  );

                  // 1. Espera que o Provider grave no SQLite e devolva o ID real!
                  final realId = await ref.read(notebookProvider.notifier).addNotebook(newNotebook);

                  if (context.mounted) {
                    Navigator.pop(context); // Fecha o Diálogo

                    // 2. Mergulha imediatamente no Canvas com a ligação de dados perfeita
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CanvasScreen(
                          notebookId: realId,
                          notebookTitle: newNotebook.title,
                          // 🚀 Acedendo às propriedades também com sublinhado
                          lineType: newNotebook.line_type ?? 'ruled',
                          paperSize: newNotebook.paper_size ?? 'A4',
                        ),
                      ),
                    );
                  }
                }
              },
              child: const Text('Criar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}