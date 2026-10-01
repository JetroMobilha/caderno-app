import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/features/notebooks/models/notebook_model.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_viewport_provider.dart';
import '../providers/collaboration_provider.dart';
import 'collaboration_center_sheet.dart';

class CanvasAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final Notebook notebook;

  const CanvasAppBar({super.key, required this.notebook});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final docState = ref.watch(canvasDocumentProvider);
    final viewportState = ref.watch(canvasViewportProvider);
    final collab = ref.watch(collaborationProvider);
    final bool hasPages = docState.pages.isNotEmpty;
    final int onlineCount = collab.onlineUsers.length;
    final bool isCollabActive = collab.isCollaborationEnabled;

    return AppBar(
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Builder(
        builder: (scaffoldContext) => InkWell(
          onTap: hasPages
              ? () => Scaffold.of(scaffoldContext).openEndDrawer()
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  notebook.title,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1A1A24),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (hasPages) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1A1A24).withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${viewportState.currentPageIndex + 1} / ${docState.pages.length}',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFF1A1A24),
                    ),
                  ),
                ),
              ],
              const SizedBox(width: 8),
              Icon(
                docState.pages.any((p) => p.syncedWithCloud == 0)
                    ? Icons.cloud_off
                    : Icons.cloud_done,
                size: 16,
                color: docState.pages.any((p) => p.syncedWithCloud == 0)
                    ? Colors.orange
                    : Colors.green,
              ),
            ],
          ),
        ),
      ),
      backgroundColor: const Color(0xFFFDFBF7),
      foregroundColor: const Color(0xFF1A1A24),
      actions: [
        if (isCollabActive || onlineCount > 0)
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: Colors.transparent,
                  builder: (context) =>
                      CollaborationCenterSheet(notebook: notebook),
                );
              },
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFA5D6A7)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF2E7D32),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$onlineCount online',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF1B5E20),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (hasPages)
          Builder(
            builder: (scaffoldContext) => IconButton(
              icon: const Icon(Icons.menu_open_rounded),
              onPressed: () => Scaffold.of(scaffoldContext).openEndDrawer(),
              tooltip: 'Lista de Folhas',
            ),
          ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
