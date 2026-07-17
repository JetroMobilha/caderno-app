import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../canvas/widgets/share_notebook_sheet.dart';
import '../../marketplace/widgets/publish_notebook_sheet.dart';
import '../../shared/widgets/app_drawer.dart';
import '../../subjects/controllers/subjects_controller.dart';
import '../../canvas/views/canvas_screen.dart';
import '../models/notebook_model.dart';
import '../controllers/notebooks_controller.dart';
import '../widgets/notebook_cover.dart'; // 🚀 Importa o teu componente visual fixo!

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
      // 🚀 INTELIGÊNCIA DE ARRANQUE: Verifica em que aba estamos ao arrancar!
      if (activeSub.id == -1) {
        await ref.read(notebooksProvider.notifier).loadSharedNotebooks();
      } else {
        await ref.read(notebooksProvider.notifier).loadNotebooks(
          activeSub.id ?? 0,
          subjectServerId: activeSub.serverId,
        );
      }
    }

    if (mounted) {
      setState(() => _isLoading = false);
    }
  }
  @override
  Widget build(BuildContext context) {
    final activeSubject = ref.watch(activeSubjectProvider);
    final notebooks = ref.watch(notebooksProvider);
    final dynamicColor = Theme.of(context).colorScheme.primary;

    // 📱 CALCULA COLUNAS CONFORME O ESPAÇO DISPONÍVEL (Responsividade Pura)
    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 1200
        ? 6 // Ecrãs Ultra-Largas (PCs Grandes)
        : screenWidth > 800
        ? 4 // Notebooks / Tablets em Paisagem
        : screenWidth > 600
        ? 3 // Tablets em Retrato
        : 2; // Telemóveis

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          activeSubject?.name ?? 'Meus Cadernos',
          style: GoogleFonts.lora(fontWeight: FontWeight.bold),
        ),
      ),
      body: _isLoading
          ? Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(color: dynamicColor, strokeWidth: 3),
            const SizedBox(height: 16),
            Text('A abrir a secretária...', style: GoogleFonts.inter(color: Colors.black54, fontSize: 14)),
          ],
        ),
      )
          : activeSubject == null
          ? _buildNoSubjectState(dynamicColor)
          : notebooks.isEmpty
          ? _buildEmptyState(dynamicColor, activeSubject.name)
          : Padding(
        padding: const EdgeInsets.all(16.0),
        child: GridView.builder(
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount, // 🚀 Colunas adaptáveis!
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
            childAspectRatio: 0.75, // Garante que o caderno mantém a proporção 3:4
          ),
          itemCount: notebooks.length,
          itemBuilder: (context, index) {
            final notebook = notebooks[index];
            return Stack(
              children: [
                // 🚀 1. O Teu Componente Visual de Capa Premium
                Positioned.fill(
                  child: NotebookCover(
                    notebook: notebook,
                    onTap: () async {
                      await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => CanvasScreen(
                            notebook: notebook
                          ),
                        ),
                      );
                      if (mounted) {
                        ref.read(notebooksProvider.notifier).refreshCurrent();
                      }
                    },
                  ),
                ),

                // 🚀 2. O Menu Flutuante de Três Pontos (Editar / Apagar)
                Positioned(
                  top: 8,
                  right: 4,
                  child: // 1️⃣ DENTRO DO TEU BUILD, SUBSTITUI O POPUPMENUBUTTON POR ESTE:
                  PopupMenuButton<String>(
                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white70, size: 20),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    onSelected: (value) async { // 🚀 Atenção: Coloca o async aqui!
                      if (value == 'edit') {
                        _showNotebookModal(context, ref, activeSubject, dynamicColor, isEditing: true, notebookToEdit: notebook);
                      } else if (value == 'delete') {
                        _confirmDelete(context, notebook);
                      } else if (value == 'share') {

                        // 🧠 LÓGICA INTELIGENTE DE PARTILHA: Se não tem ID no servidor, forçamos o push invisível!
                        Notebook currentNotebook = notebook;

                        if (currentNotebook.serverId == null) {
                          // 1. Avisa o utilizador que estamos a preparar o caderno (Loading visual rápido)
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('A ligar caderno à nuvem... ☁️'), duration: Duration(seconds: 1)),
                          );

                          // 2. Dispara o Sync apenas para enviar o que falta
                          await ref.read(subjectsProvider.notifier).syncManuallyWithCloud();

                          // 3. Atualiza o objeto do caderno com o novo Server ID que acabou de chegar
                          final updatedNotebooks = ref.read(notebooksProvider);
                          currentNotebook = updatedNotebooks.firstWhere((n) => n.id == notebook.id, orElse: () => notebook);
                        }

                        // Se a internet falhou e mesmo assim não obteve serverId, aborta com graciosidade
                        if (currentNotebook.serverId == null) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Sem internet. Não é possível partilhar agora.'), backgroundColor: Colors.redAccent),
                          );
                          return;
                        }

                        // 4. Agora sim, com o caderno seguro na nuvem, abrimos o Modal de luxo!
                        if (context.mounted) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => ShareNotebookBottomSheet(notebook: currentNotebook),
                          );
                        }
                      } else if (value == 'publish') {
                        // 🚀 Abre o Bottom Sheet de Publicação do Marketplace
                        if (context.mounted) {
                          showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => PublishNotebookSheet(notebook: notebook),
                          );
                        }
                      } else if (value == 'view_store') {
                        // Copia o ID ou link para a área de transferência e avisa o utilizador
                        Clipboard.setData(ClipboardData(text: 'https://app.cadernodigital.ao/loja/caderno/${notebook.serverId}'));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Link de partilha copiado! 🔗 Envia aos teus alunos ou colegas.'),
                            backgroundColor: Color(0xFF27AE60),
                          ),
                        );
                      }
                    },
                    itemBuilder: (context) => [
                      if (notebook.role == 'owner' || notebook.role == 'editor')
                        PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: dynamicColor), const SizedBox(width: 8), Text('Editar', style: GoogleFonts.inter(fontSize: 13))])),

                      // 🌟 A MAGIA DA PARTILHA AQUI (Só o Dono pode partilhar)
                      if (notebook.role == 'owner')
                        PopupMenuItem(value: 'share', child: Row(children: [const Icon(Icons.share_rounded, size: 18, color: Colors.blueAccent), const SizedBox(width: 8), Text('Partilhar', style: GoogleFonts.inter(fontSize: 13, color: Colors.blueAccent))])),


                      // 🚀 NOVA OPÇÃO: PUBLICAR NO MARKETPLACE (Só o dono pode publicar)
                      if (notebook.role == 'owner')
                        PopupMenuItem(
                          value: 'publish',
                          child: Row(
                            children: [
                              Icon(Icons.storefront_rounded, size: 18, color: notebook.isPublished == 1 ? AppColors.accent : AppColors.primary),
                              const SizedBox(width: 8),
                              Text(
                                notebook.isPublished == 1 ? 'Loja (Publicado) 🟢' : 'Publicar na Loja 🛒',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: notebook.isPublished == 1 ? FontWeight.bold : FontWeight.normal, color: notebook.isPublished == 1 ? AppColors.accent : AppColors.textDark),
                              )
                            ],
                          ),
                        ),

                      // 🌐 OPÇÃO EXCLUSIVA PARA CADERNOS PUBLICADOS: Ver na Loja / Copiar Link
                      if (notebook.isPublished == 1)
                        PopupMenuItem(
                          value: 'view_store',
                          child: Row(
                            children: [
                              const Icon(Icons.share_arrival_time_rounded, size: 18, color: Color(0xFF27AE60)),
                              const SizedBox(width: 8),
                              Text('Link da Loja 🔗', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: const Color(0xFF27AE60))),
                            ],
                          ),
                        ),

                      if (notebook.role == 'owner')
                        PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), const SizedBox(width: 8), Text('Apagar', style: GoogleFonts.inter(fontSize: 13, color: Colors.redAccent))])),
                    ],
                  )
                ),
              ],
            );
          },
        ),
      ),
      floatingActionButton: activeSubject == null ? null : FloatingActionButton(
        onPressed: () => _showNotebookModal(context, ref, activeSubject, dynamicColor, isEditing: false),
        child: const Icon(Icons.add),
      ),
    );
  }

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

  Widget _buildEmptyState(Color themeColor, String subjectName) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.book_outlined, size: 52, color: themeColor.withOpacity(0.3)),
          const SizedBox(height: 16),
          Text(
            'Estante Vazia em "$subjectName"',
            style: GoogleFonts.lora(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black),
          ),
          const SizedBox(height: 6),
          Text(
            'Clica no (+) em baixo para criares o teu primeiro caderno.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.black45, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // =========================================================================
  // 📓 MODAL HÍBRIDO (CAMALEÓNICO): ALTERNA ENTRE CRIAR OU EDITAR CADERNOS
  // =========================================================================
  void _showNotebookModal(BuildContext context, WidgetRef ref, activeSubject, Color themeColor, {required bool isEditing, Notebook? notebookToEdit}) {
    final titleController = TextEditingController(text: isEditing ? notebookToEdit!.title : '');
    final formKey = GlobalKey<FormState>();

    String selectedLineType = isEditing ? (notebookToEdit!.lineType ?? 'ruled') : 'ruled';
    String selectedPaperSize = isEditing ? (notebookToEdit!.paperSize ?? 'A4') : 'A4';

    // 🎨 As 16 cores premium unificadas da app
    final List<String> availableColors = [
      '#8B0000', '#0F4C5C', '#1F4E79', '#3F51B5',
      '#6C3483', '#9B59B6', '#D81B60', '#E91E63',
      '#E67E22', '#D35400', '#F1C40F', '#1E8449',
      '#27AE60', '#16A085', '#4E342E', '#607D8B',
    ];
    String pickedColorHex = isEditing ? (notebookToEdit!.color ?? '#8B0000') : '#8B0000';

    final Map<String, String> lineTypes = {'ruled': 'Pautado', 'grid': 'Quadriculado', 'blank': 'Liso / Em Branco'};

    showDialog(
      context: context,
      builder: (contextDialog) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Icon(isEditing ? Icons.edit_note_rounded : Icons.library_add_rounded, color: themeColor),
              const SizedBox(width: 10),
              Text(isEditing ? 'Editar Caderno' : 'Novo Caderno', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: themeColor)),
            ],
          ),
          content: SingleChildScrollView(
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: titleController,
                    textCapitalization: TextCapitalization.sentences,
                    decoration: InputDecoration(
                      labelText: 'Título do Caderno',
                      border: const OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: themeColor, width: 1.5)),
                    ),
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
                  Text('Cor da Capa (16 Tons):', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.black54)),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 10, runSpacing: 10,
                    children: availableColors.map((hex) {
                      final isSelected = pickedColorHex == hex;
                      final colorValue = Color(int.parse(hex.replaceFirst('#', '0xFF')));
                      return GestureDetector(
                        onTap: () => setModalState(() => pickedColorHex = hex),
                        child: CircleAvatar(
                          backgroundColor: colorValue,
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
          actionsPadding: const EdgeInsets.only(right: 20, bottom: 20),
          actions: [
            TextButton(onPressed: () => Navigator.pop(contextDialog), child: const Text('Cancelar', style: TextStyle(color: Colors.black45))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: themeColor),
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final notifier = ref.read(notebooksProvider.notifier);

                  if (isEditing) {
                    final cadernoEditado = notebookToEdit!.copyWith(
                      title: titleController.text.trim(),
                      color: pickedColorHex,
                      lineType: selectedLineType,
                      paperSize: selectedPaperSize,
                    );
                    await notifier.updateNotebook(cadernoEditado);
                    if (contextDialog.mounted) Navigator.pop(contextDialog);
                  } else {
                    final newNotebook = Notebook(
                      subjectId: activeSubject.id ?? 0,
                      title: titleController.text.trim(),
                      coverType: 'color',
                      color: pickedColorHex,
                      lineType: selectedLineType,
                      paperSize: selectedPaperSize,
                    );

                     newNotebook.id= await notifier.addNotebook(newNotebook, activeSubject.serverId);
                    if (contextDialog.mounted) {
                      Navigator.pop(contextDialog);
                      if (context.mounted) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CanvasScreen(
                              notebook:newNotebook
                            ),
                          ),
                        );
                      }
                    }
                  }
                }
              },
              child: Text(isEditing ? 'Atualizar' : 'Criar', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Apagar Caderno?', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: Colors.redAccent)),
        content: Text('O caderno "${notebook.title}" e todas as suas folhas serão arquivados.', style: GoogleFonts.inter()),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              ref.read(notebooksProvider.notifier).deleteNotebook(notebook);
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Caderno movido para a lixeira! 🗑️'), backgroundColor: Colors.green, duration: Duration(seconds: 2)),
              );
            },
            child: const Text('Apagar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}