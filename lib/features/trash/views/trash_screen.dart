import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/core/theme/app_colors.dart';
import 'package:caderno_digital_app/core/network/time_service.dart';
import '../../subjects/controllers/subjects_controller.dart';
import '../../notebooks/controllers/notebooks_controller.dart';
import '../../subjects/models/subject_model.dart';
import '../../notebooks/models/notebook_model.dart';
import '../../subjects/utils/subject_utils.dart';

class TrashScreen extends ConsumerStatefulWidget {
  final int initialTabIndex;
  const TrashScreen({super.key, this.initialTabIndex = 0});

  @override
  ConsumerState<TrashScreen> createState() => _TrashScreenState();
}

class _TrashScreenState extends ConsumerState<TrashScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Subject> _deletedSubjects = [];
  List<Notebook> _deletedNotebooks = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(
      length: 2, 
      vsync: this,
      initialIndex: widget.initialTabIndex,
    );
    _loadTrash();
  }

  Future<void> _loadTrash() async {
    setState(() => _isLoading = true);
    final subjects = await ref.read(subjectsProvider.notifier).getTrashItems();
    final notebooks = await ref.read(notebooksProvider.notifier).getTrashItems();
    
    // Filtro de 30 dias (opcional, mas solicitado no conceito)
    final now = TimeService().nowMs();
    final thirtyDaysMs = 30 * 24 * 60 * 60 * 1000;
    
    if (mounted) {
      setState(() {
        _deletedSubjects = subjects.where((s) => (now - s.updatedAt) < thirtyDaysMs).toList();
        _deletedNotebooks = notebooks.where((n) => (now - n.updatedAt) < thirtyDaysMs).toList();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.paper,
      appBar: AppBar(
        title: Text('Lixeira (30 dias)', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Pastas', icon: Icon(Icons.folder_delete_outlined)),
            Tab(text: 'Cadernos', icon: Icon(Icons.book_outlined)),
          ],
        ),
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : TabBarView(
            controller: _tabController,
            children: [
              _buildSubjectsList(),
              _buildNotebooksList(),
            ],
          ),
    );
  }

  Widget _buildSubjectsList() {
    if (_deletedSubjects.isEmpty) return _buildEmptyState('Nenhuma pasta na lixeira.');

    return ListView.builder(
      itemCount: _deletedSubjects.length,
      itemBuilder: (context, index) {
        final sub = _deletedSubjects[index];
        final daysLeft = 30 - ((TimeService().nowMs() - sub.updatedAt) / (1000 * 60 * 60 * 24)).floor();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: Icon(SubjectUtils.getSubjectIcon(sub.icon), color: Colors.grey),
            title: Text(sub.name, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Elimina-se em $daysLeft dias'),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  icon: const Icon(Icons.restore_from_trash_rounded, color: Colors.green),
                  onPressed: () async {
                    await ref.read(subjectsProvider.notifier).restoreSubject(sub);
                    _loadTrash();
                    if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pasta restaurada!')));
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildNotebooksList() {
    if (_deletedNotebooks.isEmpty) return _buildEmptyState('Nenhum caderno na lixeira.');

    return ListView.builder(
      itemCount: _deletedNotebooks.length,
      itemBuilder: (context, index) {
        final nb = _deletedNotebooks[index];
        final daysLeft = 30 - ((TimeService().nowMs() - nb.updatedAt) / (1000 * 60 * 60 * 24)).floor();

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListTile(
            leading: const Icon(Icons.book, color: Colors.grey),
            title: Text(nb.title, style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text('Elimina-se em $daysLeft dias'),
            trailing: IconButton(
              icon: const Icon(Icons.restore_from_trash_rounded, color: Colors.green),
              onPressed: () async {
                await ref.read(notebooksProvider.notifier).restoreNotebook(nb);
                _loadTrash();
                if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Caderno restaurado!')));
              },
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.delete_outline_rounded, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(message, style: GoogleFonts.inter(color: Colors.grey)),
        ],
      ),
    );
  }
}
