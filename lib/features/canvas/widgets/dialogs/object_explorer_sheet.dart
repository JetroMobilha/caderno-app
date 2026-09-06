import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/local_page_model.dart';
import '../../models/page_object.dart';
import '../../models/text_block_model.dart';
import '../../models/image_block_model.dart';
import '../../models/stroke_model.dart';
import '../../models/shape_model.dart';
import '../../models/table_model.dart';

class ObjectExplorerSheet extends ConsumerWidget {
  final String pageClientId;

  const ObjectExplorerSheet({super.key, required this.pageClientId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // 🚀 v4.1: Observar o provider para reagir a mudanças de visibilidade/bloqueio instantaneamente
    final docState = ref.watch(canvasDocumentProvider);
    final pageIdx = docState.pages.indexWhere((p) => p.clientId == pageClientId);
    
    if (pageIdx == -1) return const SizedBox.shrink();
    final page = docState.pages[pageIdx];

    // 🚀 Ordenar explicitamente por Z-Index (Top-down)
    final List<PageObject> manageableObjects = page.objects
        .where((o) => !o.isDeleted && o is! Stroke)
        .toList();
    
    manageableObjects.sort((a, b) => b.zIndex.compareTo(a.zIndex));

    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.account_tree_outlined, color: Color(0xFF0F4C5C)),
              const SizedBox(width: 12),
              Text('Explorador de Objetos', 
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const Text('Arraste para mudar a ordem (quem fica por cima)', 
            style: TextStyle(fontSize: 11, color: Colors.black38)
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () => ref.read(canvasDocumentProvider.notifier).applyNaturalSort(page),
                icon: const Icon(Icons.auto_fix_high_rounded, size: 16),
                label: const Text('ARRUMAÇÃO NATURAL', style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF0F4C5C),
                  backgroundColor: const Color(0xFF0F4C5C).withOpacity(0.05),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Expanded(
            child: manageableObjects.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.layers_clear_outlined, size: 48, color: Colors.black.withOpacity(0.1)),
                        const SizedBox(height: 12),
                        const Text('Página sem objetos manipuláveis', style: TextStyle(color: Colors.black38)),
                      ],
                    ),
                  )
                : ReorderableListView.builder(
                    onReorder: (oldIndex, newIndex) {
                      if (newIndex > oldIndex) newIndex -= 1;
                      
                      final item = manageableObjects[oldIndex];
                      final targetItem = manageableObjects[newIndex];
                      
                      final realOldIndex = page.objects.indexOf(item);
                      final realNewIndex = page.objects.indexOf(targetItem);

                      ref.read(canvasDocumentProvider.notifier).reorderObject(page, realOldIndex, realNewIndex);
                    },
                    itemCount: manageableObjects.length,
                    itemBuilder: (context, index) {
                      final obj = manageableObjects[index];
                      return _buildObjectItem(context, ref, page, obj, key: ValueKey(obj.id));
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildObjectItem(BuildContext context, WidgetRef ref, LocalPage page, PageObject obj, {required Key key}) {
    String title = 'Objeto';
    IconData icon = Icons.help_outline_rounded;

    if (obj is TextBlock) {
      title = obj.text.trim().isEmpty ? 'Bloco de Texto' : (obj.text.length > 30 ? '${obj.text.substring(0, 30)}...' : obj.text);
      icon = Icons.text_fields_rounded;
    } else if (obj is ImageBlock) {
      title = 'Imagem';
      icon = Icons.image_rounded;
    } else if (obj is TableObject) {
      title = 'Tabela (${obj.rows}x${obj.cols})';
      icon = Icons.table_chart_rounded;
    } else if (obj is ShapeObject) {
      title = 'Forma: ${obj.shapeType.name.toUpperCase()}';
      icon = Icons.interests_rounded;
    }

    return ListTile(
      key: key,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(color: const Color(0xFF0F4C5C).withOpacity(0.05), borderRadius: BorderRadius.circular(10)),
        child: Icon(icon, color: const Color(0xFF0F4C5C), size: 20),
      ),
      title: Text(title, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold), maxLines: 1),
      subtitle: Text('Ordem: ${obj.zIndex}', style: const TextStyle(fontSize: 10, color: Colors.black45)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            tooltip: 'Visibilidade',
            icon: Icon(obj.isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded, 
              size: 20, color: obj.isVisible ? const Color(0xFF0F4C5C) : Colors.black26),
            onPressed: () {
              obj.isVisible = !obj.isVisible;
              ref.read(canvasDocumentProvider.notifier).updateObject(page, obj);
            },
          ),
          IconButton(
            tooltip: 'Bloquear Movimento',
            icon: Icon(obj.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded, 
              size: 20, color: obj.isLocked ? Colors.orange : Colors.black26),
            onPressed: () {
              obj.isLocked = !obj.isLocked;
              ref.read(canvasDocumentProvider.notifier).updateObject(page, obj);
            },
          ),
          IconButton(
            tooltip: 'Apagar Objeto',
            icon: const Icon(Icons.delete_outline_rounded, size: 20, color: Colors.redAccent),
            onPressed: () => ref.read(canvasDocumentProvider.notifier).deleteObjects(page, [obj.id]),
          ),
          const SizedBox(width: 4),
          const Icon(Icons.drag_handle_rounded, color: Colors.black12),
        ],
      ),
    );
  }
}
