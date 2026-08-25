import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_viewport_provider.dart';

class CanvasAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Notebook notebook;
  final VoidCallback onCollaborationTap;

  const CanvasAppBar({
    super.key,
    required this.notebook,
    required this.onCollaborationTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docState = ref.watch(canvasDocumentProvider);
    final viewportState = ref.watch(canvasViewportProvider);
    final bool hasPages = docState.pages.isNotEmpty;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Builder(
        builder: (scaffoldContext) => InkWell(
          onTap: hasPages ? () => Scaffold.of(scaffoldContext).openEndDrawer() : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  notebook.title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24)),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasPages) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A24).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${viewportState.currentPageIndex + 1} / ${docState.pages.length}',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24)),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                docState.pages.any((p) => p.syncedWithCloud == 0) ? Icons.cloud_off : Icons.cloud_done,
                size: 16,
                color: docState.pages.any((p) => p.syncedWithCloud == 0) ? Colors.orange : Colors.green,
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFDFBF7),
      foregroundColor: const Color(0xFF1A1A24),
      actions: [
        if (hasPages) ...[
          IconButton(
            icon: const Icon(Icons.people_alt_outlined),
            onPressed: onCollaborationTap,
          ),
          Builder(
            builder: (scaffoldContext) => IconButton(
              icon: const Icon(Icons.menu_open_rounded),
              onPressed: () => Scaffold.of(scaffoldContext).openEndDrawer(),
              tooltip: 'Lista de Folhas',
            ),
          ),
        ]
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
