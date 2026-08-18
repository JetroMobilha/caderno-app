import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:caderno_digital_app/core/theme/app_colors.dart';
import 'package:caderno_digital_app/core/network/sync_provider.dart';
import 'package:caderno_digital_app/features/canvas/widgets/share_notebook_sheet.dart';
import 'package:caderno_digital_app/features/marketplace/widgets/publish_notebook_sheet.dart';
import 'package:caderno_digital_app/features/shared/widgets/app_drawer.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import 'package:caderno_digital_app/features/subjects/models/subject_model.dart';
import 'package:caderno_digital_app/features/canvas/views/canvas_screen.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import 'package:caderno_digital_app/features/notebooks/controllers/notebooks_controller.dart';
import 'package:caderno_digital_app/features/notebooks/widgets/notebook_cover.dart';
import 'package:caderno_digital_app/core/theme/app_profile.dart';

class NotebooksListScreen extends ConsumerStatefulWidget {
  const NotebooksListScreen({super.key});

  @override
  ConsumerState<NotebooksListScreen> createState() => _NotebooksListScreenState();
}

class _NotebooksListScreenState extends ConsumerState<NotebooksListScreen> {
  @override
  void initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    final activeSubject = ref.watch(activeSubjectProvider);
    final notebooksState = ref.watch(notebooksProvider);
    final activeProfile = ref.watch(appProfileProvider); 
    final notebooks = notebooksState.notebooks;
    final dynamicColor = Theme.of(context).colorScheme.primary;

    final bool isLoading = notebooksState.isLoading;

    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 1200
        ? 6 
        : screenWidth > 800
        ? 4 
        : screenWidth > 600
        ? 3 
        : 2; 

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          activeSubject?.name ?? (activeProfile == AppProfile.academico ? 'Meus Cadernos' : 'Minhas Agendas'),
          style: GoogleFonts.lora(fontWeight: FontWeight.bold),
        ),
        actions: [
          if (ref.watch(syncProvider) == SyncState.syncing)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ),
        ],
      ),
      body: isLoading
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
                          crossAxisCount: crossAxisCount,
                          crossAxisSpacing: 16,
                          mainAxisSpacing: 16,
                          childAspectRatio: 0.75,
                        ),
                        itemCount: notebooks.length,
                        itemBuilder: (context, index) {
                          final notebook = notebooks[index];
                          return Stack(
                            children: [
                              Positioned.fill(
                                child: NotebookCover(
                                  notebook: notebook,
                                  onTap: () async {
                                    await Navigator.push(
                                      context,
                                      MaterialPageRoute(
                                        builder: (context) => CanvasScreen(notebook: notebook),
                                      ),
                                    );
                                  },
                                ),
                              ),
                              Positioned(
                                top: 6,
                                right: 4,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black.withOpacity(0.2),
                                    shape: BoxShape.circle,
                                  ),
                                  child: PopupMenuButton<String>(
                                    icon: const Icon(Icons.more_vert_rounded, color: Colors.white, size: 20),
                                    padding: EdgeInsets.zero,
                                    constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    onSelected: (value) async {
                                      if (value == 'edit') {
                                        _showNotebookModal(context, ref, activeSubject, dynamicColor, isEditing: true, notebookToEdit: notebook);
                                      } else if (value == 'delete') {
                                        _confirmDelete(context, notebook);
                                      } else if (value == 'share') {
                                        Notebook currentNotebook = notebook;
                                        if (currentNotebook.serverId == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('A ligar caderno à nuvem... ☁️'), duration: Duration(seconds: 1)),
                                          );
                                          await ref.read(subjectsProvider.notifier).syncManuallyWithCloud();
                                          final notebooksState = ref.read(notebooksProvider);
                                          currentNotebook = notebooksState.notebooks.firstWhere((n) => n.id == notebook.id, orElse: () => notebook);
                                        }

                                        if (currentNotebook.serverId == null) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Sem internet. Não é possível partilhar agora.'), backgroundColor: Colors.redAccent),
                                          );
                                          return;
                                        }

                                        if (context.mounted) {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => ShareNotebookBottomSheet(notebook: currentNotebook),
                                          );
                                        }
                                      } else if (value == 'publish') {
                                        if (context.mounted) {
                                          showModalBottomSheet(
                                            context: context,
                                            isScrollControlled: true,
                                            backgroundColor: Colors.transparent,
                                            builder: (context) => PublishNotebookSheet(notebook: notebook),
                                          );
                                        }
                                      } else if (value == 'view_store') {
                                        Clipboard.setData(ClipboardData(text: 'https://app.cadernodigital.ao/loja/caderno/${notebook.serverId}'));
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          const SnackBar(
                                            content: Text('Link de partilha copiado! 🔗 Envia aos teus alunos ou colegas.'),
                                            backgroundColor: Color(0xFF27AE60),
                                          ),
                                        );
                                      } else if (value == 'duplicate') {
                                        _confirmDuplicate(context, ref, notebook, activeSubject);
                                      } else if (value == 'move') {
                                        _showMoveNotebookDialog(context, ref, notebook);
                                      } else if (value == 'leave') {
                                        _confirmLeave(context, ref, notebook);
                                      }
                                    },
                                    itemBuilder: (context) {
                                      // 🚀 VERIFICAÇÃO DE SEGURANÇA REFORÇADA
                                      // Um caderno é considerado partilhado se estivermos na aba de partilhados (subjectId == -1)
                                      // ou se a sua role local não for 'owner'.
                                      final bool isSharedTab = activeSubject?.id == -1;
                                      final String currentRole = (notebook.role).toLowerCase().trim();
                                      
                                      final bool isOwner = !isSharedTab && currentRole == 'owner';
                                      final bool isEditor = currentRole == 'editor';
                                      
                                      debugPrint('🔍 [Menu] Caderno: ${notebook.title} | TabShared: $isSharedTab | Role: $currentRole | ResultOwner: $isOwner');

                                      return [
                                        // 📝 Editar: Proprietário ou Editor
                                        if (isOwner || isEditor)
                                          PopupMenuItem(value: 'edit', child: Row(children: [Icon(Icons.edit, size: 18, color: dynamicColor), const SizedBox(width: 8), Text('Editar', style: GoogleFonts.inter(fontSize: 13))])),
                                        
                                        // 🚚 Mover: APENAS Proprietário Real
                                        if (isOwner)
                                          PopupMenuItem(value: 'move', child: Row(children: [const Icon(Icons.drive_file_move_outlined, size: 18, color: Colors.blueGrey), const SizedBox(width: 8), Text('Mover', style: GoogleFonts.inter(fontSize: 13))])),
                                        
                                        // 🤝 Partilhar: Proprietário ou Editor
                                        if (isOwner || isEditor)
                                          PopupMenuItem(value: 'share', child: Row(children: [const Icon(Icons.share_rounded, size: 18, color: Colors.blueAccent), const SizedBox(width: 8), Text('Partilhar', style: GoogleFonts.inter(fontSize: 13, color: Colors.blueAccent))])),
                                        
                                        // 👯 Duplicar: TODOS podem criar a sua cópia
                                        PopupMenuItem(
                                          value: 'duplicate',
                                          child: Row(
                                            children: [
                                              const Icon(Icons.copy_rounded, size: 18, color: Colors.teal),
                                              const SizedBox(width: 8),
                                              Text(isOwner ? 'Duplicar Caderno' : 'Criar Minha Cópia', style: GoogleFonts.inter(fontSize: 13, color: Colors.teal)),
                                            ],
                                          ),
                                        ),
                                        
                                        // 🛒 Publicar: APENAS Proprietário Real
                                        if (isOwner)
                                          PopupMenuItem(
                                            value: 'publish',
                                            child: Row(
                                              children: [
                                                Icon(Icons.storefront_rounded, size: 18, color: notebook.isPublished == 1 ? AppColors.accent : AppColors.primary),
                                                const SizedBox(width: 8),
                                                Text(
                                                  notebook.isPublished == 1 ? 'Loja (Publicado) 🟢' : 'Publicar na Loja 🛒',
                                                  style: GoogleFonts.inter(fontSize: 13, fontWeight: notebook.isPublished == 1 ? FontWeight.bold : FontWeight.normal, color: notebook.isPublished == 1 ? AppColors.accent : AppColors.textDark),
                                                ),
                                              ],
                                            ),
                                          ),
                                        
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
                                        
                                        // 👋 Sair: Disponível para qualquer um que não seja o Owner (na aba partilhados ou role convidada)
                                        if (!isOwner)
                                          PopupMenuItem(value: 'leave', child: Row(children: [const Icon(Icons.logout_rounded, size: 18, color: Colors.orangeAccent), const SizedBox(width: 8), Text('Sair do Caderno', style: GoogleFonts.inter(fontSize: 13, color: Colors.orangeAccent))])),
                                        
                                        // 🧨 Apagar: APENAS Proprietário Real
                                        if (isOwner)
                                          PopupMenuItem(value: 'delete', child: Row(children: [const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent), const SizedBox(width: 8), Text('Apagar', style: GoogleFonts.inter(fontSize: 13, color: Colors.redAccent))])),
                                      ];
                                    },
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
      floatingActionButton: activeSubject == null
          ? null
          : FloatingActionButton(
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

  void _showNotebookModal(BuildContext context, WidgetRef ref, Subject? activeSubject, Color themeColor, {required bool isEditing, Notebook? notebookToEdit}) {
    final titleController = TextEditingController(text: isEditing ? notebookToEdit!.title : '');
    final formKey = GlobalKey<FormState>();
    String selectedLineType = isEditing ? (notebookToEdit!.lineType) : 'ruled';
    String selectedTemplate = isEditing ? (notebookToEdit!.templateType) : 'study';
    final List<String> availableColors = [
      '#8B0000', '#0F4C5C', '#1F4E79', '#3F51B5',
      '#6C3483', '#9B59B6', '#D81B60', '#E91E63',
      '#E67E22', '#D35400', '#F1C40F', '#1E8449',
      '#27AE60', '#16A085', '#4E342E', '#607D8B',
    ];
    String pickedColorHex = isEditing ? (notebookToEdit!.color ?? '#8B0000') : '#8B0000';

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
              Flexible(
                child: Text(isEditing ? 'Editar Caderno' : 'Novo Caderno', 
                  style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: themeColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
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
                  const SizedBox(height: 20),
                  Text('Propósito do Caderno:', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: themeColor)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _buildTemplateCard(
                        context, 'Pessoal / Estudo', Icons.school_rounded, 'study', selectedTemplate, themeColor,
                        onTap: () {
                          setModalState(() {
                            selectedTemplate = 'study';
                            selectedLineType = 'ruled';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildTemplateCard(
                        context, 'Técnico', Icons.engineering_rounded, 'technical', selectedTemplate, Colors.blueGrey,
                        onTap: () {
                          setModalState(() {
                            selectedTemplate = 'technical';
                            selectedLineType = 'grid';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildTemplateCard(
                        context, 'Formal', Icons.business_center_rounded, 'formal', selectedTemplate, const Color(0xFF2C3E50),
                        onTap: () {
                          setModalState(() {
                            selectedTemplate = 'formal';
                            selectedLineType = 'blank';
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      _buildTemplateCard(
                        context, 'Criativo', Icons.palette_rounded, 'creative', selectedTemplate, const Color(0xFFD81B60),
                        onTap: () {
                          setModalState(() {
                            selectedTemplate = 'creative';
                            selectedLineType = 'blank';
                          });
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
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
                      templateType: selectedTemplate,
                    );
                    await notifier.updateNotebook(cadernoEditado);
                    if (contextDialog.mounted) Navigator.pop(contextDialog);
                  } else {
                    final newNotebook = Notebook(
                      subjectId: activeSubject?.id ?? 0,
                      title: titleController.text.trim(),
                      coverType: 'color',
                      color: pickedColorHex,
                      lineType: selectedLineType,
                      paperSize: 'A4',
                      templateType: selectedTemplate,
                    );

                    newNotebook.id = await notifier.addNotebook(newNotebook, activeSubject?.serverId);
                    if (contextDialog.mounted) {
                      Navigator.pop(contextDialog);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Caderno "${newNotebook.title}" criado com sucesso! 📓'),
                          backgroundColor: themeColor,
                          duration: const Duration(seconds: 2),
                        ),
                      );
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

  Widget _buildTemplateCard(BuildContext context, String label, IconData icon, String type, String selected, Color color, {required VoidCallback onTap}) {
    final isSelected = selected == type;
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: isSelected ? 2 : 1),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey, size: 24),
              const SizedBox(height: 6),
              Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? color : Colors.grey)),
            ],
          ),
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

  void _confirmDuplicate(BuildContext context, WidgetRef ref, Notebook notebook, Subject? activeSubject) {
    int? selectedSubId;
    final subjects = ref.read(subjectsProvider).where((s) => s.id != -1).toList();

    if (subjects.isNotEmpty) {
      // Pré-selecionar a disciplina atual se não for a aba de partilhados
      selectedSubId = (activeSubject != null && activeSubject.id != -1) 
          ? activeSubject.id 
          : subjects.first.id;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.copy_rounded, color: Colors.teal),
              const SizedBox(width: 10),
              Text(notebook.role == 'owner' ? 'Duplicar Caderno' : 'Criar Minha Cópia', 
                style: GoogleFonts.lora(fontWeight: FontWeight.bold)
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Onde desejas guardar a cópia de "${notebook.title}"?', style: GoogleFonts.inter(fontSize: 14)),
              const SizedBox(height: 20),
              Text('Disciplina de Destino:', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black54)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedSubId,
                    isExpanded: true,
                    items: subjects.map((s) => DropdownMenuItem(
                      value: s.id, 
                      child: Text(s.name, style: GoogleFonts.inter(fontSize: 14))
                    )).toList(),
                    onChanged: (val) => setStateModal(() => selectedSubId = val),
                  ),
                ),
              ),
              if (notebook.role != 'owner') ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Row(
                    children: [
                      const Icon(Icons.privacy_tip_outlined, size: 16, color: Colors.amber),
                      const SizedBox(width: 8),
                      Expanded(child: Text('Apenas as folhas autorizadas pelo dono serão copiadas.', style: GoogleFonts.inter(fontSize: 11, color: Colors.amber.shade900))),
                    ],
                  ),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: selectedSubId == null ? null : () async {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('A criar a tua cópia... ⏳'), duration: Duration(seconds: 2)),
                );
                
                await ref.read(notebooksProvider.notifier).duplicateNotebook(notebook, selectedSubId!);
                
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Cópia criada com sucesso! 📓'), backgroundColor: Colors.green),
                  );
                }
              },
              child: const Text('Confirmar Cópia', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _showMoveNotebookDialog(BuildContext context, WidgetRef ref, Notebook notebook) {
    int? selectedSubId;
    final subjects = ref.read(subjectsProvider);

    if (subjects.isNotEmpty) {
      selectedSubId = subjects.firstWhere((s) => s.id != notebook.subjectId, orElse: () => subjects.first).id;
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setStateModal) => AlertDialog(
          backgroundColor: Theme.of(context).colorScheme.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              const Icon(Icons.drive_file_move_outlined, color: Colors.blueGrey),
              const SizedBox(width: 10),
              Text('Mover Caderno', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Para qual disciplina desejas mover "${notebook.title}"?', style: GoogleFonts.inter(fontSize: 14)),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.black12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton<int>(
                    value: selectedSubId,
                    isExpanded: true,
                    items: subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))).toList(),
                    onChanged: (val) => setStateModal(() => selectedSubId = val),
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Theme.of(context).colorScheme.primary),
              onPressed: () async {
                if (selectedSubId != null) {
                  await ref.read(notebooksProvider.notifier).moveNotebook(notebook, selectedSubId!);
                  if (ctx.mounted) {
                    Navigator.pop(ctx);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Caderno movido com sucesso! 🚀'), backgroundColor: Colors.green),
                    );
                  }
                }
              },
              child: const Text('Mover Agora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmLeave(BuildContext context, WidgetRef ref, Notebook notebook) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Sair do Caderno?', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: Colors.orangeAccent)),
        content: Text('Deixarás de ter acesso a "${notebook.title}". Terás de pedir um novo convite ao dono para voltar.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orangeAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              final success = await ref.read(notebooksProvider.notifier).leaveNotebook(notebook);
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Removeste o teu acesso com sucesso. 👋'), backgroundColor: Colors.blueGrey),
                );
              }
            },
            child: const Text('Sair Agora', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
