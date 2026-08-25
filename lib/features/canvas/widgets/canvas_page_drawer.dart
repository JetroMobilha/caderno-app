import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_viewport_provider.dart';

class CanvasPageDrawer extends ConsumerWidget {
  final Notebook notebook;
  final VoidCallback onAddPage;

  const CanvasPageDrawer({
    super.key,
    required this.notebook,
    required this.onAddPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    const themeColor = Color(0xFF0F4C5C);
    final docState = ref.watch(canvasDocumentProvider);
    final viewportState = ref.watch(canvasViewportProvider);
    final viewportNotifier = ref.read(canvasViewportProvider.notifier);

    return Drawer(
      backgroundColor: const Color(0xFFFDFBF7),
      width: MediaQuery.of(context).size.width * 0.8,
      child: Column(
        children: [
          Container(
            width: double.infinity,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [themeColor, themeColor.withValues(alpha: 0.85)],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Icon(Icons.auto_stories_rounded, color: Colors.white, size: 32),
                        Text(
                          '${docState.pages.length} Folhas',
                          style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Text(
                      notebook.title,
                      style: GoogleFonts.lora(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 12),
              itemCount: docState.pages.length,
              itemBuilder: (context, index) {
                final page = docState.pages[index];
                final bool isCurrent = viewportState.currentPageIndex == index;
                return ListTile(
                  leading: CircleAvatar(
                    backgroundColor: isCurrent ? themeColor : Colors.black12,
                    child: Text('${index + 1}', style: TextStyle(color: isCurrent ? Colors.white : Colors.black87)),
                  ),
                  title: Text(
                    page.title.isEmpty ? 'Página ${index + 1}' : page.title,
                    style: TextStyle(fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal),
                  ),
                  onTap: () {
                    viewportNotifier.jumpToPage(index);
                    Navigator.pop(context);
                  },
                );
              },
            ),
          ),
          if (docState.currentUserRole != 'viewer')
            Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  onAddPage();
                },
                icon: const Icon(Icons.add),
                label: const Text('ADICIONAR FOLHA'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: themeColor,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 50),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
