import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/local_page_model.dart';

class LayerManagerSheet extends ConsumerWidget {
  final LocalPage page;

  const LayerManagerSheet({super.key, required this.page});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
              Text('Camadas da Página', 
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))
              ),
              const Spacer(),
              IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
            ],
          ),
          const SizedBox(height: 16),
          Flexible(
            child: ListView.separated(
              shrinkWrap: true,
              itemCount: page.layers.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final layer = page.layers[index];
                return ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    layer.id == 'drawings' ? Icons.brush_rounded :
                    layer.id == 'text' ? Icons.text_fields_rounded :
                    layer.id == 'background' ? Icons.grid_on_rounded :
                    Icons.layers_rounded,
                    color: const Color(0xFF0F4C5C),
                  ),
                  title: Text(layer.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(layer.isVisible ? Icons.visibility_rounded : Icons.visibility_off_rounded),
                        onPressed: () {
                          ref.read(canvasDocumentProvider.notifier).updateLayerVisibility(page, layer.id, !layer.isVisible);
                        },
                      ),
                      IconButton(
                        icon: Icon(layer.isLocked ? Icons.lock_rounded : Icons.lock_open_rounded),
                        onPressed: () {
                          ref.read(canvasDocumentProvider.notifier).updateLayerLock(page, layer.id, !layer.isLocked);
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            onPressed: () async {
              final controller = TextEditingController();
              final String? name = await showDialog<String>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Nova Camada'),
                  content: TextField(controller: controller, autofocus: true, decoration: const InputDecoration(hintText: 'Ex: Anotações Extras')),
                  actions: [
                    TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
                    TextButton(onPressed: () => Navigator.pop(ctx, controller.text.trim()), child: const Text('CRIAR')),
                  ],
                ),
              );
              if (name != null && name.isNotEmpty) {
                ref.read(canvasDocumentProvider.notifier).addNewLayer(page, name);
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C5C),
              foregroundColor: Colors.white,
              minimumSize: const Size(double.infinity, 50),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            icon: const Icon(Icons.add_box_outlined),
            label: const Text('ADICIONAR CAMADA'),
          ),
        ],
      ),
    );
  }
}
