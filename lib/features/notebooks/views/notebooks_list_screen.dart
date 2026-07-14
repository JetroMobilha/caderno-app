import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../shared/widgets/app_drawer.dart';
import '../../subjects/controllers/subjects_controller.dart';
import '../../canvas/views/canvas_screen.dart';
import '../models/notebook_model.dart';
import '../controllers/notebooks_controller.dart';

class NotebooksListScreen extends ConsumerStatefulWidget {
  const NotebooksListScreen({super.key});

  @override
  ConsumerState<NotebooksListScreen> createState() => _NotebooksListScreenState();
}

class _NotebooksListScreenState extends ConsumerState<NotebooksListScreen> {
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchInitialData();
  }

  Future<void> _fetchInitialData() async {
    await Future.delayed(const Duration(milliseconds: 100));

    final activeSub = ref.read(activeSubjectProvider);
    if (activeSub != null) {
      await ref.read(notebooksProvider.notifier).loadNotebooks(
        activeSub.id ?? 0,
        subjectServerId: activeSub.serverId,
      );
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeSubject = ref.watch(activeSubjectProvider);
    final allNotebooks = ref.watch(notebooksProvider);

    // 🎨 Captura a cor dinâmica ativa da disciplina naquele milissegundo!
    final dynamicColor = Theme.of(context).colorScheme.primary;

    final notebooks = activeSubject == null ? [] : allNotebooks.where((n) =>
    n.subjectId == activeSubject.id ||
        (activeSubject.serverId != null && n.subjectId == activeSubject.serverId)
    ).toList();

    return Scaffold(
      // Mantém o fundo papel padrão vindo do ColorScheme automático
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          activeSubject?.name ?? 'Meus Cadernos',
          style: GoogleFonts.lora(fontWeight: FontWeight.bold),
        ),
        // 🚀 LIMPEZA TÁTICA: Removidas as cores fixas daqui! O AppBar agora
        // herda automaticamente a cor da disciplina ativa configurada no app_theme.
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // 🎨 Usa a cor dinâmica no indicador de carregamento
            CircularProgressIndicator(color: dynamicColor, strokeWidth: 3),
            const SizedBox(height: 16),
            Text('A abrir a secretária...', style: GoogleFonts.inter(color: Colors.black54, fontSize: 14)),
          ],
        ),
      )
          : activeSubject == null
          ? _buildNoSubjectState(dynamicColor) // 🚀 Passa a cor dinâmica para o ecrã vazio
          : notebooks.isEmpty
          ? Center(
        child: Text(
          'Nenhum caderno na disciplina "${activeSubject.name}".\nClica no + para começares!',
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
            return _buildNotebookCard(context, notebooks[index], activeSubject);
          },
        ),
      ),
      // 🚀 LIMPEZA TÁTICA: O FloatingActionButton herda a cor automaticamente do theme global!
      floatingActionButton: activeSubject == null ? null : FloatingActionButton(
        onPressed: () => _showAddNotebookDialog(context, ref, activeSubject, dynamicColor),
        child: const Icon(Icons.add),
      ),
    );
  }

  // Ecrã amigável adaptado para receber a cor viva ativa
  Widget _buildNoSubjectState(Color themeColor) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.arrow_back_rounded, size: 48, color: themeColor.withOpacity(0.4)),
          const SizedBox(height: 16),
          Text(
            'Bem-vindo à tua Secretária!',
            style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold, color: themeColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Abre o menu superior esquerdo (☰)\npara selecionares ou criares a tua primeira disciplina.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.black54, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildNotebookCard(BuildContext context, Notebook notebook, activeSubject) {
    final cardColor = notebook.color != null
        ? Color(int.parse(notebook.color!.replaceFirst('#', '0xFF')))
        : const Color(0xFF8B0000);

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CanvasScreen(
              notebookId: notebook.id ?? 0,
              notebookSid: notebook.serverId ?? 0,
              notebookTitle: notebook.title,
              lineType: notebook.lineType,
              paperSize: notebook.paperSize,
            ),
          ),
        );

        if (mounted) {
          ref.read(notebooksProvider.notifier).loadNotebooks(
            activeSubject.id ?? 0,
            subjectServerId: activeSubject.serverId,
          );
        }
      },
      onLongPress: () => _confirmDelete(context, notebook),
      child: Container(
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 6, offset: const Offset(0, 4))],
        ),
        child: Stack(
          children: [
            Positioned(
              left: 0, top: 0, bottom: 0, width: 15,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.15),
                  borderRadius: const BorderRadius.only(topLeft: Radius.circular(12), bottomLeft: Radius.circular(12)),
                ),
              ),
            ),
            Positioned(
              right: 12, left: 27, top: 40,
              child: Container(
                padding: const EdgeInsets.all(8),
                color: Colors.white.withOpacity(0.9),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notebook.title,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.black87, fontSize: 13),
                      maxLines: 2, overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text('Formato: ${notebook.paperSize}', style: GoogleFonts.inter(color: Colors.black54, fontSize: 10, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNotebookDialog(BuildContext context, WidgetRef ref, activeSubject, Color themeColor) {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String selectedLineType = 'ruled';
    String selectedPaperSize = 'A4';
    String pickedColorHex = '#8B0000';

    final List<String> availableColors = ['#8B0000', '#2C3E50', '#1E8449', '#D35400', '#6C3483'];
    final Map<String, String> lineTypes = {'ruled': 'Pautado', 'grid': 'Quadriculado', 'blank': 'Liso / Em Branco'};

    showDialog(
      context: context,
      builder: (contextDialog) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
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
                    validator: (value) => value == null || value.trim().isEmpty ? 'Introduz o título' : null,
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedPaperSize,
                    decoration: const InputDecoration(labelText: 'Tamanho da Folha', border: OutlineInputBorder()),
                    items: ['A0', 'A1', 'A2', 'A3', 'A4', 'A5'].map((size) => DropdownMenuItem(value: size, child: Text(size))).toList(),
                    onChanged: (value) { if (value != null) setModalState(() => selectedPaperSize = value); },
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    value: selectedLineType,
                    decoration: const InputDecoration(labelText: 'Estilo da Pauta', border: OutlineInputBorder()),
                    items: lineTypes.entries.map((entry) => DropdownMenuItem(value: entry.key, child: Text(entry.value))).toList(),
                    onChanged: (value) { if (value != null) setModalState(() => selectedLineType = value); },
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
            TextButton(onPressed: () => Navigator.pop(contextDialog), child: const Text('Cancelar')),
            ElevatedButton(
              // 🚀 O botão agora herda as configurações universais automáticas do tema!
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final newNotebook = Notebook(
                    subjectId: activeSubject.id ?? 0,
                    title: titleController.text.trim(),
                    coverType: 'color',
                    color: pickedColorHex,
                    lineType: selectedLineType,
                    paperSize: selectedPaperSize,
                  );

                  final realId = await ref.read(notebooksProvider.notifier).addNotebook(newNotebook, activeSubject.serverId);

                  if (contextDialog.mounted) {
                    Navigator.pop(contextDialog);
                    if (context.mounted) {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CanvasScreen(
                            notebookId: realId,
                            notebookSid: null,
                            notebookTitle: newNotebook.title,
                            lineType: newNotebook.lineType,
                            paperSize: newNotebook.paperSize,
                          ),
                        ),
                      );
                    }
                  }
                }
              },
              child: const Text('Criar'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmDelete(BuildContext context, Notebook notebook) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Destruir Caderno?'),
        content: Text('O caderno "${notebook.title}" e todas as suas folhas serão apagados permanentemente.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(notebooksProvider.notifier).deleteNotebook(notebook);
              Navigator.pop(ctx);
            },
            child: const Text('Apagar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}