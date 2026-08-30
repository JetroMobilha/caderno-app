import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:caderno_digital_app/core/network/sync_provider.dart';
import 'package:caderno_digital_app/features/shared/widgets/app_drawer.dart';
import 'package:caderno_digital_app/features/auth/controllers/auth_controller.dart';
import '../controllers/subjects_controller.dart';
import '../widgets/subject_list_item.dart';
import '../widgets/subject_dialogs.dart';

class SubjectsListScreen extends ConsumerStatefulWidget {
  final bool initialShowArchived;
  const SubjectsListScreen({super.key, this.initialShowArchived = false});

  @override
  ConsumerState<SubjectsListScreen> createState() => _SubjectsListScreenState();
}

class _SubjectsListScreenState extends ConsumerState<SubjectsListScreen> {
  @override
  void initState() {
    super.initState();
    if (widget.initialShowArchived) {
      Future.microtask(() => ref.read(subjectsUiProvider.notifier).toggleListArchive(forceValue: true));
    }
  }

  @override
  Widget build(BuildContext context) {
    final uiSettings = ref.watch(subjectsUiProvider);
    final showArchived = uiSettings.showArchivedInList;
    final themeColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text(showArchived ? 'Pastas Arquivadas' : 'Os meus Cadernos', 
          style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 22)),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(showArchived ? Icons.inventory_2_rounded : Icons.archive_outlined),
            onPressed: () => ref.read(subjectsUiProvider.notifier).toggleListArchive(),
            tooltip: showArchived ? 'Ver Ativas' : 'Ver Arquivadas',
          ),
          if (ref.watch(syncProvider) == SyncState.syncing)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: SubjectsListBody(showArchived: showArchived),
      floatingActionButton: showArchived ? null : FloatingActionButton(
        backgroundColor: themeColor,
        foregroundColor: Colors.white,
        elevation: 4,
        onPressed: () {
          final user = ref.read(authProvider).currentUser;
          if (user != null) {
            SubjectDialogs.showSubjectModal(context, ref, user, isEditing: false, themeColor: themeColor);
          }
        },
        child: const Icon(Icons.add, size: 28),
      ),
    );
  }
}

class SubjectsListBody extends ConsumerWidget {
  final bool showArchived;
  const SubjectsListBody({super.key, required this.showArchived});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allSubjects = ref.watch(subjectsProvider);
    
    // 🚀 Filtrar e ordenar
    final activeSubjects = allSubjects.where((s) => s.isArchived == showArchived).toList();
    activeSubjects.sort((a, b) => a.name.compareTo(b.name));

    if (activeSubjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(showArchived ? Icons.archive_outlined : Icons.menu_book_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(showArchived ? 'Nenhuma pasta arquivada.' : 'Nenhuma pasta ativa.', 
              style: GoogleFonts.inter(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: activeSubjects.length,
      itemBuilder: (context, index) {
        return SubjectListItem(subject: activeSubjects[index]);
      },
    );
  }
}
