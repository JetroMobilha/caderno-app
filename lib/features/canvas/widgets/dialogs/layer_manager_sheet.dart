import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/canvas_document_provider.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../models/local_page_model.dart';
import '../../models/page_object.dart';
import '../../models/stroke_model.dart';
import '../../models/text_block_model.dart';
import '../../models/image_block_model.dart';
import '../../models/table_model.dart';

/// 🚀 v10.1: Gestor de Objetos e Camadas com Suporte a Grupos.
class LayerManagerSheet extends ConsumerWidget {
  final LocalPage page;

  const LayerManagerSheet({super.key, required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final interactionState = ref.watch(canvasInteractionProvider);
    final interactionNotifier = ref.read(canvasInteractionProvider.notifier);
    final docNotifier = ref.read(canvasDocumentProvider.notifier);

    final objects = page.objects.where((o) => !o.isDeleted).toList().reversed.toList();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: const Color(0xFF0F4C5C).withValues(alpha: 0.1), shape: BoxShape.circle),
                child: const Icon(Icons.account_tree_outlined, color: Color(0xFF0F4C5C), size: 20),
              ),
              const SizedBox(width: 12),
              Text('Explorador de Objetos', 
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          
          if (objects.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Text('Folha vazia.', style: GoogleFonts.inter(color: Colors.black26, fontSize: 13)),
            )
          else
            Flexible(
              child: ReorderableListView.builder(
                shrinkWrap: true,
                itemCount: objects.length,
                onReorder: (oldIndex, newIndex) {
                   if (newIndex > oldIndex) newIndex--;
                   docNotifier.reorderObject(page, (objects.length - 1) - oldIndex, (objects.length - 1) - newIndex);
                },
                itemBuilder: (context, index) {
                  final obj = objects[index];
                  final isSelected = interactionState.selectedObjectIds.contains(obj.id);
                  final bool inGroup = obj.parentId != null;

                  return ListTile(
                    key: ValueKey('layer_${obj.id}'),
                    selected: isSelected,
                    selectedTileColor: inGroup ? Colors.indigo.withValues(alpha: 0.03) : const Color(0xFF0F4C5C).withValues(alpha: 0.05),
                    onTap: () {
                      interactionNotifier.selectIds(objectIds: {obj.id});
                    },
                    leading: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (inGroup) const Icon(Icons.link_rounded, size: 14, color: Colors.indigoAccent),
                        const SizedBox(width: 4),
                        _buildObjectIcon(obj),
                      ],
                    ),
                    title: Text(_getObjectName(obj), 
                      style: GoogleFonts.inter(fontSize: 14, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)
                    ),
                    subtitle: Text(
                      inGroup ? 'Grupo Ativo | Z: ${obj.zIndex}' : 'Z-Index: ${obj.zIndex}', 
                      style: const TextStyle(fontSize: 10, color: Colors.black26)
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(obj.isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, 
                            size: 18, color: obj.isVisible ? const Color(0xFF0F4C5C) : Colors.black12),
                          onPressed: () => docNotifier.updateObject(page, obj.copyWith(isVisible: !obj.isVisible)),
                        ),
                        IconButton(
                          icon: Icon(obj.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, 
                            size: 18, color: obj.isLocked ? Colors.orange : Colors.black12),
                          onPressed: () => docNotifier.updateObject(page, obj.copyWith(isLocked: !obj.isLocked)),
                        ),
                        const Icon(Icons.drag_indicator_rounded, color: Colors.black12, size: 20),
                      ],
                    ),
                  );
                },
              ),
            ),
          
          const SizedBox(height: 24),
          
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => docNotifier.applyNaturalSort(page),
                  icon: const Icon(Icons.auto_awesome_motion_rounded, size: 18),
                  label: const Text('AUTO-ORDENAR'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => interactionNotifier.clearSelection(),
                  icon: const Icon(Icons.deselect_rounded, size: 18),
                  label: const Text('DESELECIONAR'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.grey.shade100,
                    foregroundColor: Colors.black87,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildObjectIcon(PageObject obj) {
    IconData icon;
    if (obj is Stroke) icon = Icons.brush_rounded;
    else if (obj is TextBlock) icon = Icons.text_fields_rounded;
    else if (obj is ImageBlock) icon = Icons.image_rounded;
    else if (obj is TableObject) icon = Icons.grid_on_rounded;
    else icon = Icons.extension_rounded;
    return Icon(icon, color: const Color(0xFF0F4C5C), size: 18);
  }

  String _getObjectName(PageObject obj) {
    if (obj is TextBlock) return obj.text.isEmpty ? 'Bloco de Texto' : (obj.text.length > 20 ? '${obj.text.substring(0, 20)}...' : obj.text);
    if (obj is Stroke) return 'Traço de Desenho';
    if (obj is ImageBlock) return 'Imagem';
    if (obj is TableObject) return 'Tabela (${obj.rows}x${obj.cols})';
    return obj.type.toUpperCase();
  }
}
