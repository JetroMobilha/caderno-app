import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/notebook_provider.dart';
import '../models/notebook_model.dart';
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
  @override
  void initState() {
    super.initState();
    // Dispara a leitura da Base de Dados assim que o ecrã é montado
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notebookProvider.notifier).loadNotebooks(widget.subjectId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final notebooks = ref.watch(notebookProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7), // Fundo folha de papel cremosa
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Color(0xFF1A1A24)),
        title: Text(
          widget.subjectName,
          style: GoogleFonts.lora(
            color: const Color(0xFF1A1A24),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: notebooks.isEmpty
          ? Center(
        child: Text(
          'Nenhum caderno nesta disciplina.\nCria o teu primeiro bloco de notas!',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 16),
        ),
      )
          : GridView.builder(
        padding: const EdgeInsets.all(20),
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
          maxCrossAxisExtent: 200, // Mantém o tamanho do caderno controlado em ecrãs grandes
          crossAxisSpacing: 20,
          mainAxisSpacing: 20,
          childAspectRatio: 0.75, // Proporção vertical de caderno real
        ),
        itemCount: notebooks.length,
        itemBuilder: (context, index) {
          final notebook = notebooks[index];
          return _buildNotebookCard(notebook);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddNotebookDialog(context),
        backgroundColor: const Color(0xFF2C3E50),
        icon: const Icon(Icons.menu_book, color: Colors.white),
        label: Text(
          'Novo Caderno',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }

  // Desenha o aspeto físico do caderno
  Widget _buildNotebookCard(Notebook notebook) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => CanvasScreen(notebookTitle: notebook.title),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF34495E), // Cor base escura (estilo capa dura)
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 8,
              offset: const Offset(3, 5),
            ),
          ],
        ),
        child: Stack(
          children: [
            // Linhas brancas na lateral esquerda imitando anéis/espiral de caderno
            Positioned(
              left: 5,
              top: 10,
              bottom: 10,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: List.generate(
                  6,
                      (index) => Container(
                    width: 4,
                    height: 12,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ),
            ),
            // Etiqueta branca centralizada para o título
            Center(
              child: Container(
                width: 120,
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDFBF7),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.black12, width: 2),
                ),
                child: Text(
                  notebook.title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A24),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddNotebookDialog(BuildContext context) {
    final titleController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    String selectedCoverType = 'classic';
    String selectedLineType = 'ruled';

    final Map<String, String> coverTypes = {
      'classic': 'Capa Clássica',
      'leather': 'Textura Couro',
      'geometric': 'Design Geométrico'
    };

    final Map<String, String> lineTypes = {
      'ruled': 'Pautado (Linhas)',
      'grid': 'Quadriculado',
      'blank': 'Liso (Desenho)'
    };

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFFFDFBF7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text('Configurar Novo Caderno', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'Título do Bloco',
                      hintText: 'Ex: Álgebra Linear - Vol I',
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Introduza o título do caderno';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),
                  Text('Estilo da Capa:', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  DropdownButtonFormField<String>(
                    value: selectedCoverType,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: coverTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (val) => setModalState(() => selectedCoverType = val!),
                  ),
                  const SizedBox(height: 20),
                  Text('Tipo de Folha Interna:', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
                  DropdownButtonFormField<String>(
                    value: selectedLineType,
                    decoration: const InputDecoration(border: OutlineInputBorder()),
                    items: lineTypes.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
                    onChanged: (val) => setModalState(() => selectedLineType = val!),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2C3E50)),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  ref.read(notebookProvider.notifier).addNotebook(
                    Notebook(
                      subject_id: widget.subjectId,
                      title: titleController.text.trim(),
                      coverType: selectedCoverType,
                      lineType: selectedLineType,
                    ),
                  );
                  Navigator.pop(context);
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