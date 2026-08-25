import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:caderno_digital_app/core/network/sync_provider.dart';
import 'package:caderno_digital_app/features/shared/widgets/app_drawer.dart';
import 'package:caderno_digital_app/features/subjects/controllers/subjects_controller.dart';
import 'package:caderno_digital_app/features/notebooks/controllers/notebooks_controller.dart';
import 'package:caderno_digital_app/core/theme/app_profile.dart';
import '../widgets/notebook_grid_item.dart';
import '../widgets/notebook_dialogs.dart';
import '../widgets/notebook_empty_states.dart';

class NotebooksListScreen extends ConsumerWidget {
  const NotebooksListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeSubject = ref.watch(activeSubjectProvider);
    final notebooksState = ref.watch(notebooksProvider);
    final activeProfile = ref.watch(appProfileProvider);
    final notebooks = notebooksState.notebooks;
    final dynamicColor = Theme.of(context).colorScheme.primary;

    final double screenWidth = MediaQuery.of(context).size.width;
    final int crossAxisCount = screenWidth > 1200 ? 6 : screenWidth > 800 ? 4 : screenWidth > 600 ? 3 : 2;

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
      body: notebooksState.isLoading
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
              ? NoSubjectState(themeColor: dynamicColor)
              : notebooks.isEmpty
                  ? EmptyNotebooksState(themeColor: dynamicColor, subjectName: activeSubject.name)
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
                          return NotebookGridItem(
                            notebook: notebooks[index],
                            dynamicColor: dynamicColor,
                          );
                        },
                      ),
                    ),
      floatingActionButton: activeSubject == null
          ? null
          : FloatingActionButton(
              onPressed: () => NotebookDialogs.showNotebookModal(context, ref, activeSubject, dynamicColor, isEditing: false),
              child: const Icon(Icons.add),
            ),
    );
  }
}
