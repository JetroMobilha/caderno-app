import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/canvas_viewport_provider.dart';
import '../providers/canvas_document_provider.dart';
import '../models/local_page_model.dart';

class CanvasZoomControl extends ConsumerWidget {
  final LocalPage currentPage;
  final bool isCompact;

  const CanvasZoomControl({
    super.key,
    required this.currentPage,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final viewportNotifier = ref.read(canvasViewportProvider.notifier);
    final controller = viewportNotifier.getControllerFor(currentPage.clientId);

    return ListenableBuilder(
      listenable: controller,
      builder: (context, _) {
        final double scale = controller.value.getMaxScaleOnAxis();
        final int percentage = (scale * 100).round();

        return Container(
          height: isCompact ? 36 : 40,
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // AFSTAR (-)
              _buildActionButton(
                icon: Icons.remove_rounded,
                onTap: () => _handleZoom(ref, 0.9),
                tooltip: 'Afastar',
              ),
              
              _buildDivider(),

              // INDICADOR (%)
              InkWell(
                onTap: () {
                  viewportNotifier.resetZoom(currentPage.clientId, currentPage);
                },
                borderRadius: BorderRadius.circular(4),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: Alignment.center,
                  child: Text(
                    '$percentage%',
                    style: GoogleFonts.inter(
                      fontSize: 11, 
                      fontWeight: FontWeight.bold, 
                      color: const Color(0xFF1A1A24)
                    ),
                  ),
                ),
              ),

              _buildDivider(),

              // APROXIMAR (+)
              _buildActionButton(
                icon: Icons.add_rounded,
                onTap: () => _handleZoom(ref, 1.1),
                tooltip: 'Aproximar',
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildActionButton({required IconData icon, required VoidCallback onTap, required String tooltip}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Icon(icon, size: 18, color: const Color(0xFF1A1A24)),
      ),
    );
  }

  Widget _buildDivider() {
    return Container(
      width: 1,
      height: 16,
      color: Colors.black.withValues(alpha: 0.1),
    );
  }

  void _handleZoom(WidgetRef ref, double factor) {
    final viewportNotifier = ref.read(canvasViewportProvider.notifier);
    viewportNotifier.zoom(currentPage.clientId, factor);
    // 🚀 REMOVIDO: Não salvar no DB para evitar flicker global
  }

  void _saveViewport(WidgetRef ref, Matrix4 matrix) {
    // 🚀 DESATIVADO
  }
}
