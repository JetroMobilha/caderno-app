import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:caderno_digital_app/core/network/sync_provider.dart';
import 'package:caderno_digital_app/features/shared/widgets/app_drawer.dart';
import 'package:caderno_digital_app/features/auth/controllers/auth_controller.dart';
import '../controllers/subjects_controller.dart';
import '../widgets/subject_list_item.dart';
import '../widgets/subject_dialogs.dart';

class SubjectsListScreen extends ConsumerWidget {
  const SubjectsListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeColor = Theme.of(context).colorScheme.primary;

    return Scaffold(
      backgroundColor: const Color(0xFFFDFBF7),
      appBar: AppBar(
        title: Text('Os meus Cadernos', style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 22)),
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (ref.watch(syncProvider) == SyncState.syncing)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)),
            ),
        ],
      ),
      drawer: const AppDrawer(),
      body: const SubjectsListBody(),
      floatingActionButton: FloatingActionButton(
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
  const SubjectsListBody({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subjects = ref.watch(subjectsProvider);

    if (subjects.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.menu_book_rounded, size: 64, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text('Nenhuma disciplina criada.', style: GoogleFonts.inter(color: Colors.grey, fontSize: 16)),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 80),
      itemCount: subjects.length,
      itemBuilder: (context, index) {
        return SubjectListItem(subject: subjects[index]);
      },
    );
  }
}
