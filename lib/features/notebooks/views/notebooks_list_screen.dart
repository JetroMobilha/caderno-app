import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:caderno_digital_app/core/network/sync_provider.dart';
import 'package:caderno_digital_app/features/shared/widgets/app_drawer.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import 'package:caderno_digital_app/features/notebooks/controllers/notebooks_controller.dart';
import 'package:caderno_digital_app/features/trash/views/trash_screen.dart';
import '../widgets/notebook_grid_item.dart';
import '../widgets/notebook_dialogs.dart';
import '../widgets/notebook_empty_states.dart';

class NotebooksListScreen extends ConsumerStatefulWidget {
  const NotebooksListScreen({super.key});

  @override
  ConsumerState<NotebooksListScreen> createState() => _NotebooksListScreenState();
}

class _NotebooksListScreenState extends ConsumerState<NotebooksListScreen> {
  @override
  Widget build(BuildContext context) {
    final uiSettings = ref.watch(subjectsUiProvider);
    final showArchived = uiSettings.showArchivedInNotebooks;
    final activeSubject = ref.watch(activeSubjectProvider);
    final notebooksState = ref.watch(notebooksProvider);
    final dynamicColor = Theme.of(context).colorScheme.primary;

    // 🚀 FILTRAGEM
    final allNotebooks = notebooksState.notebooks;
    final displayNotebooks = allNotebooks.where((n) => n.isArchived == showArchived).toList();
    
    // Agrupamento
    final favorites = displayNotebooks.where((n) => n.isFavorite).toList();
    final remaining = displayNotebooks.where((n) => !n.isFavorite).toList();

    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 1200 ? 6 : screenWidth > 800 ? 4 : screenWidth > 600 ? 3 : 2;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      drawer: const AppDrawer(),
      appBar: AppBar(
        title: Text(
          showArchived ? 'Arquivados' : (activeSubject?.name ?? 'Meus Cadernos'),
          style: GoogleFonts.lora(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => TrashScreen(initialTabIndex: 1))),
            tooltip: 'Ver Lixeira',
          ),
          IconButton(
            icon: Icon(showArchived ? Icons.inventory_2_rounded : Icons.archive_outlined),
            onPressed: () => ref.read(subjectsUiProvider.notifier).toggleNotebooksArchive(),
            tooltip: showArchived ? 'Ver Ativos' : 'Ver Arquivados',
          ),
          if (ref.watch(syncProvider) == SyncState.syncing)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black26))),
            ),
        ],
      ),
      body: notebooksState.isLoading
          ? Center(child: CircularProgressIndicator(color: dynamicColor))
          : activeSubject == null
              ? NoSubjectState(themeColor: dynamicColor)
              : displayNotebooks.isEmpty
                  ? EmptyNotebooksState(themeColor: dynamicColor, subjectName: showArchived ? 'arquivados' : activeSubject.name)
                  : CustomScrollView(
                      slivers: [
                        if (favorites.isNotEmpty && !showArchived) ...[
                          _buildSectionTitle('FAVORITOS', Icons.star_rounded, Colors.orange),
                          _buildGrid(favorites, crossAxisCount, dynamicColor),
                        ],
                        if (remaining.isNotEmpty) ...[
                          if (favorites.isNotEmpty && !showArchived)
                            _buildSectionTitle('RESTANTES', Icons.book_rounded, dynamicColor),
                          _buildGrid(remaining, crossAxisCount, dynamicColor),
                        ],
                      ],
                    ),
      floatingActionButton: activeSubject == null || showArchived
          ? null
          : FloatingActionButton(
              onPressed: () => NotebookDialogs.showNotebookModal(context, ref, activeSubject, dynamicColor, isEditing: false),
              child: const Icon(Icons.add),
            ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon, Color color) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
        child: Row(
          children: [
            Icon(icon, size: 16, color: color),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: color, letterSpacing: 1.2),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid(List<dynamic> items, int crossAxisCount, Color dynamicColor) {
    return SliverPadding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 0.75,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) => NotebookGridItem(notebook: items[index], dynamicColor: dynamicColor),
          childCount: items.length,
        ),
      ),
    );
  }
}
