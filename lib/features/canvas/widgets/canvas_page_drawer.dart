import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import '../models/local_page_model.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_viewport_provider.dart';
import '../providers/canvas_ui_provider.dart'; // 🚀 NOVO
import '../views/page_overview_screen.dart';
import 'dialogs/add_page_dialog.dart';
import 'dialogs/select_notebook_dialog.dart';

class CanvasPageDrawer extends ConsumerWidget {
  final Notebook notebook;
  final VoidCallback onAddPage;

  const CanvasPageDrawer({
    super.key,
    required this.notebook,
    required this.onAddPage,
  });

  void _toggleSection(WidgetRef ref, String section) {
    ref.read(canvasUiProvider.notifier).toggleSection(section);
  }

  Color _getSectionColor(String title, {String? customColor}) {
    if (customColor != null) {
      try {
        return Color(int.parse(customColor.replaceFirst('#', '0xFF')));
      } catch (_) {}
    }
    // 🚀 ALGORITMO DJB2: Excelente dispersão para evitar colisões de cores
    // ⚓ NORMALIZAÇÃO: trim e lowercase para consistência entre dispositivos
    final String key = title.trim().toLowerCase();
    int hash = 5381;
    for (int i = 0; i < key.length; i++) {
      hash = ((hash << 5) + hash) + key.codeUnitAt(i);
    }
    
    final List<Color> palette = [
      const Color(0xFF0F4C5C), // Azul petróleo
      const Color(0xFFE36414), // Laranja
      const Color(0xFF5F0F40), // Roxo escuro
      const Color(0xFF9A031E), // Carmim
      const Color(0xFF2D6A4F), // Verde floresta
      const Color(0xFF3C096C), // Violeta
      const Color(0xFF264653), // Charcoal
      const Color(0xFF2A9D8F), // Persa Green
      const Color(0xFFE76F51), // Terra Cotta
      const Color(0xFFF4A261), // Sandy Brown
      const Color(0xFFE9C46A), // Maize
      const Color(0xFF6D597A), // Muted Purple
      const Color(0xFF355070), // Indigo
      const Color(0xFFB56576), // Rose
      const Color(0xFF6D6875), // Old Lavender
    ];
    return palette[hash.abs() % palette.length];
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const themeColor = Color(0xFF0F4C5C);
    final docState = ref.watch(canvasDocumentProvider);
    final viewportState = ref.watch(canvasViewportProvider);
    final viewportNotifier = ref.read(canvasViewportProvider.notifier);
    final uiState = ref.watch(canvasUiProvider); // 🚀 ESTADO PERSISTENTE

    // 🚀 Lógica de Agrupamento
    final List<LocalPage> favoritePages = docState.pages.where((p) => p.isFavorite).toList();
    final Map<String, List<LocalPage>> sectionedPages = {};
    final List<LocalPage> unsectionedPages = [];

    for (var p in docState.pages) {
      if (p.sectionTitle != null && p.sectionTitle!.isNotEmpty) {
        sectionedPages.putIfAbsent(p.sectionTitle!, () => []).add(p);
      } else {
        unsectionedPages.add(p);
      }
    }

    return Drawer(
      backgroundColor: const Color(0xFFFDFBF7),
      width: 320.0,
      child: Column(
        children: [
          _buildHeader(context, docState, themeColor),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
              children: [
                _buildIntegratedToolbar(context, ref, themeColor),
                const SizedBox(height: 12),
                if (favoritePages.isNotEmpty) ...[
                  _buildSectionHeader(
                    'FAVORITOS', 
                    Icons.star_rounded, 
                    Colors.orange,
                    isCollapsed: uiState.collapsedSections.contains('FAVORITOS'),
                    onTap: () => _toggleSection(ref, 'FAVORITOS'),
                  ),
                  if (!uiState.collapsedSections.contains('FAVORITOS'))
                    _buildPageGroup(context, ref, favoritePages, docState, viewportState, viewportNotifier, themeColor, prefix: 'fav_'),
                  const Divider(indent: 20, endIndent: 20, height: 32),
                ],

                // Secções Dinâmicas
                ...sectionedPages.entries.map((entry) {
                  final sectionColor = _getSectionColor(entry.key, customColor: entry.value.first.sectionColor);
                  final isCollapsed = uiState.collapsedSections.contains(entry.key);
                  
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionHeader(
                        entry.key.toUpperCase(), 
                        Icons.folder_open_rounded, 
                        sectionColor,
                        isCollapsed: isCollapsed,
                        onTap: () => _toggleSection(ref, entry.key),
                      ),
                      if (!isCollapsed)
                        _buildPageGroup(context, ref, entry.value, docState, viewportState, viewportNotifier, sectionColor),
                      const SizedBox(height: 16),
                    ],
                  );
                }),

                if (unsectionedPages.isNotEmpty) ...[
                  if (sectionedPages.isNotEmpty) 
                    _buildSectionHeader(
                      'OUTRAS PÁGINAS', 
                      Icons.insert_drive_file_outlined, 
                      Colors.black38,
                      isCollapsed: uiState.collapsedSections.contains('OUTRAS PÁGINAS'),
                      onTap: () => _toggleSection(ref, 'OUTRAS PÁGINAS'),
                    ),
                  if (!uiState.collapsedSections.contains('OUTRAS PÁGINAS'))
                    _buildPageGroup(context, ref, unsectionedPages, docState, viewportState, viewportNotifier, themeColor),
                ],
              ],
            ),
          ),
          if (docState.currentUserRole != 'viewer')
            _buildBottomButtons(context, ref, themeColor),
        ],
      ),
    );
  }

  Widget _buildIntegratedToolbar(BuildContext context, WidgetRef ref, Color themeColor) {
    final uiState = ref.watch(canvasUiProvider);

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.04),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.pop(context);
                Navigator.push(context, MaterialPageRoute(builder: (_) => const PageOverviewScreen()));
              },
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: 40,
                decoration: BoxDecoration(
                  color: themeColor,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [BoxShadow(color: themeColor.withOpacity(0.2), blurRadius: 4, offset: const Offset(0, 2))],
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.grid_view_rounded, size: 16, color: Colors.white),
                    const SizedBox(width: 8),
                    Text(
                      'VISTA GERAL',
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white, letterSpacing: 0.5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          _buildIntegratedActionButton(Icons.delete_sweep_outlined, () => _showDeletedPagesDialog(context, ref)),
          const SizedBox(width: 4),
          _buildViewToggleButton(Icons.view_list_rounded, !uiState.isGridView, () => ref.read(canvasUiProvider.notifier).toggleGridView(false)),
          _buildViewToggleButton(Icons.grid_view_rounded, uiState.isGridView, () => ref.read(canvasUiProvider.notifier).toggleGridView(true)),
        ],
      ),
    );
  }

  Widget _buildIntegratedActionButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 18, color: Colors.black45),
      ),
    );
  }

  Widget _buildViewToggleButton(IconData icon, bool isActive, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 40,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isActive ? Colors.white : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive ? [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, 2))] : null,
        ),
        child: Icon(icon, size: 18, color: isActive ? const Color(0xFF0F4C5C) : Colors.black26),
      ),
    );
  }

  Widget _buildPageGroup(
    BuildContext context,
    WidgetRef ref,
    List<LocalPage> pages, 
    CanvasDocumentState docState, 
    CanvasViewportState viewportState,
    CanvasViewportNotifier viewportNotifier,
    Color themeColor,
    {String prefix = ''}
  ) {
    final uiState = ref.watch(canvasUiProvider);

    if (uiState.isGridView) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.8,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: pages.length,
          itemBuilder: (context, i) {
            final p = pages[i];
            return _PageGridTile(
              key: ValueKey('${prefix}grid_${p.clientId}'),
              page: p,
              index: docState.pages.indexOf(p),
              isCurrent: viewportState.currentPageIndex == docState.pages.indexOf(p),
              themeColor: themeColor,
              onTap: () {
                viewportNotifier.jumpToPage(docState.pages.indexOf(p), clientId: p.clientId);
                Navigator.pop(context);
              },
              onAction: (val) => _handleAction(context, ref, p, val),
            );
          },
        ),
      );
    }

    return Column(
      children: pages.map((p) => _PageListTile(
        key: ValueKey('${prefix}${p.clientId}'),
        page: p,
        index: docState.pages.indexOf(p),
        isCurrent: viewportState.currentPageIndex == docState.pages.indexOf(p),
        themeColor: themeColor,
        onTap: () {
          viewportNotifier.jumpToPage(docState.pages.indexOf(p));
          Navigator.pop(context);
        },
        onAction: (val) => _handleAction(context, ref, p, val),
      )).toList(),
    );
  }

  Widget _buildHeader(BuildContext context, CanvasDocumentState state, Color themeColor) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [themeColor, themeColor.withOpacity(0.85)],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 24),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          '${state.pages.length} Folhas',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text(
                notebook.title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.lora(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                'Última edição: ${DateFormat('dd/MM HH:mm').format(DateTime.fromMillisecondsSinceEpoch(notebook.updatedAt))}',
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10),
              ),
            ],
          ),
        ),
      ),
    );
  }


  Widget _buildSectionHeader(String title, IconData icon, Color color, {required bool isCollapsed, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
        child: Row(
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: color,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            Icon(
              isCollapsed ? Icons.keyboard_arrow_right_rounded : Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: color.withOpacity(0.5),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButtons(BuildContext context, WidgetRef ref, Color themeColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton.icon(
        onPressed: () {
          Navigator.pop(context);
          WidgetsBinding.instance.addPostFrameCallback((_) {
            onAddPage();
          });
        },
        icon: const Icon(Icons.add_rounded),
        label: const Text('ADICIONAR NOVA FOLHA'),
        style: ElevatedButton.styleFrom(
          backgroundColor: themeColor,
          foregroundColor: Colors.white,
          elevation: 0,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
      ),
    );
  }

  void _handleAction(BuildContext context, WidgetRef ref, LocalPage page, String action) {
    final int index = ref.read(canvasDocumentProvider).pages.indexOf(page);
    
    switch (action) {
      case 'rename': _showRenameDialog(context, ref, page); break;
      case 'section': _showSectionDialog(context, ref, page); break;
      case 'remove_section': ref.read(canvasDocumentProvider.notifier).updatePageSection(page, null); break;
      case 'add_before': _showAddPageDialog(context, ref, insertIndex: index); break;
      case 'add_after': _showAddPageDialog(context, ref, insertIndex: index + 1); break;
      case 'duplicate': ref.read(canvasDocumentProvider.notifier).duplicatePage(page); break;
      case 'move_to': _handleMovePage(context, ref, page); break;
      case 'copy_to': _handleCopyPage(context, ref, page); break;
      case 'favorite': ref.read(canvasDocumentProvider.notifier).toggleFavorite(page); break;
      case 'delete': _confirmDelete(context, ref, page); break;
    }
  }

  Future<void> _handleMovePage(BuildContext context, WidgetRef ref, LocalPage page) async {
    final Notebook? target = await showDialog<Notebook>(
      context: context,
      builder: (_) => const SelectNotebookDialog(title: 'Mover Folha para...'),
    );
    if (target != null && target.id != null) {
      await ref.read(canvasDocumentProvider.notifier).movePageToOtherNotebook(page, target.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Folha movida para "${target.title}"')),
        );
      }
    }
  }

  Future<void> _handleCopyPage(BuildContext context, WidgetRef ref, LocalPage page) async {
    final Notebook? target = await showDialog<Notebook>(
      context: context,
      builder: (_) => const SelectNotebookDialog(title: 'Copiar Folha para...'),
    );
    if (target != null && target.id != null) {
      await ref.read(canvasDocumentProvider.notifier).copyPageToOtherNotebook(page, target.id!);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cópia criada em "${target.title}"')),
        );
      }
    }
  }

  void _showAddPageDialog(BuildContext context, WidgetRef ref, {int? insertIndex}) {
    showDialog(
      context: context, 
      builder: (_) => AddPageDialog(
        defaultLineType:'ruled',
        defaultLineSpacing: 28.0,
        insertIndex: insertIndex,
      )
    );
  }

  void _showRenameDialog(BuildContext context, WidgetRef ref, LocalPage page) {
    final controller = TextEditingController(text: page.title);
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Renomear Folha'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'Ex: Resumo Aula 1'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              ref.read(canvasDocumentProvider.notifier).renamePage(page, controller.text.trim());
              Navigator.pop(ctx);
            },
            child: const Text('GUARDAR'),
          ),
        ],
      ),
    );
  }

  void _showSectionDialog(BuildContext context, WidgetRef ref, LocalPage page) {
    final docState = ref.read(canvasDocumentProvider);
    final List<String> existingSections = docState.pages
        .map((p) => p.sectionTitle)
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    final controller = TextEditingController(text: page.sectionTitle);
    String? selectedColor = page.sectionColor;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Mover para Secção'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Autocomplete<String>(
                initialValue: TextEditingValue(text: page.sectionTitle ?? ''),
                optionsBuilder: (TextEditingValue textEditingValue) {
                  if (textEditingValue.text.isEmpty) return existingSections;
                  return existingSections.where((s) => s.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (selection) => controller.text = selection,
                fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
                  fieldController.addListener(() => controller.text = fieldController.text);
                  return TextField(
                    controller: fieldController,
                    focusNode: focusNode,
                    autofocus: true,
                    decoration: const InputDecoration(
                      hintText: 'Nome da Secção',
                      helperText: 'Deixe vazio para remover da secção',
                    ),
                  );
                },
              ),
              const SizedBox(height: 20),
              const Text('Cor da Secção (Opcional)', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black38)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  '#0F4C5C', '#E36414', '#5F0F40', '#9A031E', '#2D6A4F', '#3C096C', '#264653'
                ].map((colorHex) {
                  final bool isSel = selectedColor == colorHex;
                  return InkWell(
                    onTap: () => setDialogState(() => selectedColor = colorHex),
                    child: Container(
                      width: 28, height: 28,
                      decoration: BoxDecoration(
                        color: Color(int.parse(colorHex.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: Border.all(color: isSel ? Colors.black : Colors.transparent, width: 2),
                      ),
                      child: isSel ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                ref.read(canvasDocumentProvider.notifier).updatePageSection(
                  page, 
                  controller.text.trim(),
                  sectionColor: selectedColor,
                );
                Navigator.pop(ctx);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C5C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('MOVER'),
            ),
          ],
        ),
      ),
    );
  }

  void _showDeletedPagesDialog(BuildContext context, WidgetRef ref) async {
    final deletedPages = await ref.read(canvasDocumentProvider.notifier).getDeletedPages();

    if (!context.mounted) return;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Folhas Eliminadas'),
            const SizedBox(height: 4),
            Text(
              'Os itens na lixeira são eliminados permanentemente após 30 dias.',
              style: GoogleFonts.inter(fontSize: 10, color: Colors.redAccent.withOpacity(0.7), fontWeight: FontWeight.w500),
            ),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: deletedPages.isEmpty
              ? const Center(child: Text('Nenhuma folha na lixeira.'))
              : ListView.builder(
                  itemCount: deletedPages.length,
                  itemBuilder: (context, index) {
                    final page = deletedPages[index];
                    return ListTile(
                      title: Text(page.title.isEmpty ? 'Página ${page.pageNumber}' : page.title),
                      subtitle: Text('Eliminada em ${DateFormat('dd/MM HH:mm').format(DateTime.fromMillisecondsSinceEpoch(page.updatedAt))}'),
                      trailing: IconButton(
                        icon: const Icon(Icons.restore_page_rounded, color: Color(0xFF0F4C5C)),
                        onPressed: () {
                          ref.read(canvasDocumentProvider.notifier).restorePage(page);
                          Navigator.pop(ctx);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Folha restaurada!')),
                          );
                        },
                      ),
                    );
                  },
                ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('FECHAR')),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, LocalPage page) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Apagar Folha?'),
        content: const Text('Esta ação não pode ser desfeita.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              ref.read(canvasDocumentProvider.notifier).deletePage(page);
              Navigator.pop(ctx);
            },
            child: const Text('APAGAR', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _PageGridTile extends StatelessWidget {
  final LocalPage page;
  final int index;
  final bool isCurrent;
  final Color themeColor;
  final VoidCallback onTap;
  final Function(String) onAction;

  const _PageGridTile({
    super.key,
    required this.page,
    required this.index,
    required this.isCurrent,
    required this.themeColor,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: isCurrent ? themeColor.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isCurrent ? themeColor : Colors.black.withOpacity(0.05)),
          boxShadow: isCurrent ? [BoxShadow(color: themeColor.withOpacity(0.1), blurRadius: 4)] : null,
        ),
        child: Stack(
          children: [
            Column(
              children: [
                Expanded(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: _PageThumbnail(
                        lineType: page.lineType ?? 'ruled',
                        index: index + 1,
                        isSelected: isCurrent,
                        themeColor: themeColor,
                      ),
                    ),
                  ),
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 8),
                  decoration: BoxDecoration(
                    color: isCurrent ? themeColor.withOpacity(0.1) : Colors.black.withOpacity(0.02),
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  ),
                  child: Text(
                    page.title.isEmpty ? 'Pág. ${index + 1}' : page.title,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isCurrent ? FontWeight.bold : FontWeight.w500,
                      color: isCurrent ? themeColor : Colors.black87,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
            Positioned(
              top: 0, right: 0,
              child: PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 16, color: Colors.black26),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onSelected: onAction,
                itemBuilder: (context) => [
                  _menuItem('rename', Icons.edit_outlined, 'Renomear'),
                  _menuItem('section', Icons.folder_outlined, 'Mudar Secção'),
                  if (page.sectionTitle != null)
                    _menuItem('remove_section', Icons.folder_off_outlined, 'Remover da Secção'),
                  const PopupMenuDivider(),
                  _menuItem('add_before', Icons.vertical_align_top_rounded, 'Inserir antes'),
                  _menuItem('add_after', Icons.vertical_align_bottom_rounded, 'Inserir depois'),
                  const PopupMenuDivider(),
                  _menuItem('favorite', page.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded, page.isFavorite ? 'Remover Favorito' : 'Marcar Favorito'),
                  _menuItem('duplicate', Icons.copy_rounded, 'Duplicar'),
                  _menuItem('move_to', Icons.drive_file_move_outlined, 'Mover para caderno'),
                  _menuItem('copy_to', Icons.content_copy_rounded, 'Copiar para caderno'),
                  const PopupMenuDivider(),
                  _menuItem('delete', Icons.delete_outline_rounded, 'Apagar', isDestructive: true),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      height: 36,
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDestructive ? Colors.redAccent : Colors.black54),
          const SizedBox(width: 8),
          Text(label, style: TextStyle(fontSize: 12, color: isDestructive ? Colors.redAccent : Colors.black87)),
        ],
      ),
    );
  }
}

class _PageListTile extends StatelessWidget {
  final LocalPage page;
  final int index;
  final bool isCurrent;
  final Color themeColor;
  final VoidCallback onTap;
  final Function(String) onAction;

  const _PageListTile({
    super.key,
    required this.page,
    required this.index,
    required this.isCurrent,
    required this.themeColor,
    required this.onTap,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isCurrent 
                ? themeColor.withOpacity(0.05) 
                : (page.isFavorite ? Colors.orange.withOpacity(0.03) : Colors.transparent),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isCurrent 
                  ? themeColor.withOpacity(0.1) 
                  : (page.isFavorite ? Colors.orange.withOpacity(0.1) : Colors.transparent)
            ),
          ),
          child: Row(
            children: [
              _PageThumbnail(
                lineType: page.lineType ?? 'ruled',
                index: index + 1,
                isSelected: isCurrent,
                themeColor: page.isFavorite ? Colors.orange : themeColor,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        if (page.isFavorite)
                          const Padding(
                            padding: EdgeInsets.only(right: 6),
                            child: Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                          ),
                        Expanded(
                          child: Text(
                            page.title.isEmpty ? 'Página ${index + 1}' : page.title,
                            style: TextStyle(
                              fontWeight: (isCurrent || page.isFavorite) ? FontWeight.bold : FontWeight.w500,
                              fontSize: 13,
                              color: isCurrent 
                                  ? themeColor 
                                  : (page.isFavorite 
                                      ? Colors.orange.shade800 
                                      : (page.sectionTitle != null ? themeColor.withOpacity(0.8) : Colors.black87)),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getPageSubtitle(page.lineType),
                      style: const TextStyle(fontSize: 10, color: Colors.black38),
                    ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, size: 18, color: Colors.black26),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                onSelected: onAction,
                itemBuilder: (context) => [
                  _menuItem('rename', Icons.edit_outlined, 'Renomear'),
                  _menuItem('section', Icons.folder_outlined, 'Mudar Secção'),
                  if (page.sectionTitle != null)
                    _menuItem('remove_section', Icons.folder_off_outlined, 'Remover da Secção'),
                  const PopupMenuDivider(),
                  _menuItem('add_before', Icons.vertical_align_top_rounded, 'Inserir antes'),
                  _menuItem('add_after', Icons.vertical_align_bottom_rounded, 'Inserir depois'),
                  const PopupMenuDivider(),
                  _menuItem('favorite', page.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded, page.isFavorite ? 'Remover Favorito' : 'Marcar Favorito'),
                  _menuItem('duplicate', Icons.copy_rounded, 'Duplicar'),
                  _menuItem('move_to', Icons.drive_file_move_outlined, 'Mover para caderno'),
                  _menuItem('copy_to', Icons.content_copy_rounded, 'Copiar para caderno'),
                  const PopupMenuDivider(),
                  _menuItem('delete', Icons.delete_outline_rounded, 'Apagar', isDestructive: true),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  PopupMenuItem<String> _menuItem(String value, IconData icon, String label, {bool isDestructive = false}) {
    return PopupMenuItem(
      value: value,
      child: Row(
        children: [
          Icon(icon, size: 18, color: isDestructive ? Colors.redAccent : Colors.black54),
          const SizedBox(width: 12),
          Text(label, style: TextStyle(fontSize: 13, color: isDestructive ? Colors.redAccent : Colors.black87)),
        ],
      ),
    );
  }

  String _getPageSubtitle(String? type) {
    switch (type) {
      case 'ruled': return 'Pautado';
      case 'grid': return 'Quadriculado';
      case 'blank': return 'Liso';
      case 'cornell': return 'Cornell Notes';
      case 'engineering': return 'Engenharia';
      default: return 'Folha Normal';
    }
  }
}


class _PageThumbnail extends StatelessWidget {
  final String lineType;
  final int index;
  final bool isSelected;
  final Color themeColor;

  const _PageThumbnail({
    required this.lineType,
    required this.index,
    required this.isSelected,
    required this.themeColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 38,
      height: 50,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: isSelected ? themeColor : Colors.black12,
          width: isSelected ? 1.5 : 0.8,
        ),
        boxShadow: isSelected ? [
          BoxShadow(color: themeColor.withOpacity(0.15), blurRadius: 4, spreadRadius: 1)
        ] : null,
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: CustomPaint(
              painter: _ThumbnailPainter(lineType: lineType),
            ),
          ),
          Center(
            child: Text(
              '$index',
              style: TextStyle(
                color: isSelected ? themeColor : Colors.black26,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ThumbnailPainter extends CustomPainter {
  final String lineType;
  _ThumbnailPainter({required this.lineType});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.05)
      ..strokeWidth = 0.5;

    if (lineType == 'ruled') {
      for (double y = 8; y < size.height; y += 5) {
        canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), paint);
      }
    } else if (lineType == 'grid') {
      for (double x = 4; x < size.width; x += 5) {
        canvas.drawLine(Offset(x, 4), Offset(x, size.height - 4), paint);
      }
      for (double y = 4; y < size.height; y += 5) {
        canvas.drawLine(Offset(4, y), Offset(size.width - 4, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
