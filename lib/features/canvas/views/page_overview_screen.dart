import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:reorderable_grid_view/reorderable_grid_view.dart';
// ignore: implementation_imports
import 'package:reorderable_grid_view/src/reorderable_grid_mixin.dart';
import '../providers/canvas_document_provider.dart';
import '../providers/canvas_viewport_provider.dart';
import '../models/local_page_model.dart';

class PageOverviewScreen extends ConsumerStatefulWidget {
  const PageOverviewScreen({super.key});

  @override
  ConsumerState<PageOverviewScreen> createState() => _PageOverviewScreenState();
}

class _PageOverviewScreenState extends ConsumerState<PageOverviewScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedPageClientIds = {};

  void _toggleSelection(String clientId) {
    setState(() {
      if (_selectedPageClientIds.contains(clientId)) {
        _selectedPageClientIds.remove(clientId);
        if (_selectedPageClientIds.isEmpty) _isSelectionMode = false;
      } else {
        _selectedPageClientIds.add(clientId);
        _isSelectionMode = true;
      }
    });
  }

  void _clearSelection() {
    setState(() {
      _selectedPageClientIds.clear();
      _isSelectionMode = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final docState = ref.watch(canvasDocumentProvider);
    final viewportState = ref.watch(canvasViewportProvider);
    final viewportNotifier = ref.read(canvasViewportProvider.notifier);

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F7),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: Icon(_isSelectionMode ? Icons.close_rounded : Icons.arrow_back_ios_new_rounded, color: Colors.black87, size: 20),
          onPressed: () {
            if (_isSelectionMode) _clearSelection();
            else Navigator.pop(context);
          },
        ),
        title: Text(
          _isSelectionMode ? '${_selectedPageClientIds.length} selecionadas' : 'Vista Geral',
          style: GoogleFonts.lora(color: Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          if (!_isSelectionMode)
            TextButton(
              onPressed: () => setState(() => _isSelectionMode = true),
              child: const Text('Selecionar', style: TextStyle(color: Color(0xFF0F4C5C), fontWeight: FontWeight.bold)),
            )
          else
            TextButton(
              onPressed: () {
                setState(() {
                  if (_selectedPageClientIds.length == docState.pages.length) {
                    _selectedPageClientIds.clear();
                  } else {
                    _selectedPageClientIds.addAll(docState.pages.map((p) => p.clientId));
                  }
                });
              },
              child: Text(
                _selectedPageClientIds.length == docState.pages.length ? 'Desmarcar' : 'Todos',
                style: const TextStyle(color: Color(0xFF0F4C5C), fontWeight: FontWeight.bold),
              ),
            ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          // 🚀 RESPONSIVIDADE: Calcular colunas dinamicamente
          final double width = constraints.maxWidth;
          int crossAxisCount = (width / 160).floor().clamp(2, 8);
          
          return Column(
            children: [
              Expanded(
                child: ReorderableGridView.builder(
                  padding: const EdgeInsets.all(20),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: crossAxisCount,
                    childAspectRatio: 0.72,
                    crossAxisSpacing: 20,
                    mainAxisSpacing: 20,
                  ),
                  itemCount: docState.pages.length,
                  onReorder: (oldIndex, newIndex) {
                    ref.read(canvasDocumentProvider.notifier).reorderPage(oldIndex, newIndex);
                  },
                  // 🚀 DESATIVADO GLOBALMENTE: Vamos ativar apenas no ícone
                  dragEnabled: false,
                  itemBuilder: (context, index) {
                    final page = docState.pages[index];
                    final bool isSelected = _selectedPageClientIds.contains(page.clientId);
                    final bool isCurrent = viewportState.currentPageIndex == index;

                    return _PageGridItem(
                      key: ValueKey('grid_${page.clientId}'),
                      page: page,
                      index: index,
                      isSelected: isSelected,
                      isCurrent: isCurrent,
                      isSelectionMode: _isSelectionMode,
                      onTap: () {
                        if (_isSelectionMode) {
                          _toggleSelection(page.clientId);
                        } else {
                          viewportNotifier.jumpToPage(index, clientId: page.clientId);
                          Navigator.pop(context);
                        }
                      },
                      onLongPress: () {
                        if (!_isSelectionMode) {
                          _toggleSelection(page.clientId);
                        }
                      },
                    );
                  },
                ),
              ),
              if (_isSelectionMode) _buildBatchActionBar(docState.pages),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBatchActionBar(List<LocalPage> allPages) {
    final selectedPages = allPages.where((p) => _selectedPageClientIds.contains(p.clientId)).toList();
    
    return Container(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).padding.bottom + 12, top: 12, left: 16, right: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 10, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _ActionButton(
            icon: Icons.copy_rounded,
            label: 'Duplicar',
            onTap: () {
              ref.read(canvasDocumentProvider.notifier).duplicatePages(selectedPages);
              _clearSelection();
            },
          ),
          _ActionButton(
            icon: Icons.folder_open_rounded,
            label: 'Secção',
            onTap: () => _showBatchSectionDialog(selectedPages),
          ),
          _ActionButton(
            icon: Icons.star_rounded,
            label: 'Favorito',
            onTap: () {
              for (var p in selectedPages) {
                ref.read(canvasDocumentProvider.notifier).toggleFavorite(p);
              }
              _clearSelection();
            },
          ),
          _ActionButton(
            icon: Icons.delete_outline_rounded,
            label: 'Apagar',
            color: Colors.redAccent,
            onTap: () => _confirmBatchDelete(selectedPages),
          ),
        ],
      ),
    );
  }

  void _showBatchSectionDialog(List<LocalPage> pages) {
    final controller = TextEditingController();
    String? selectedColor;
    
    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Mover ${pages.length} páginas', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  hintText: 'Nome da Secção',
                  filled: true,
                  fillColor: Colors.black.withOpacity(0.03),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                ),
              ),
              const SizedBox(height: 20),
              const Text('Cor da Secção (Opcional)', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black38)),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8, runSpacing: 8,
                children: [
                  '#0F4C5C', '#E36414', '#5F0F40', '#9A031E', '#2D6A4F', '#3C096C', '#264653'
                ].map((colorHex) {
                  final bool isSel = selectedColor == colorHex;
                  return InkWell(
                    onTap: () => setDialogState(() => selectedColor = colorHex),
                    child: Container(
                      width: 32, height: 32,
                      decoration: BoxDecoration(
                        color: Color(int.parse(colorHex.replaceFirst('#', '0xFF'))),
                        shape: BoxShape.circle,
                        border: Border.all(color: isSel ? Colors.black : Colors.transparent, width: 2),
                        boxShadow: isSel ? [BoxShadow(color: Colors.black26, blurRadius: 4)] : null,
                      ),
                      child: isSel ? const Icon(Icons.check, size: 16, color: Colors.white) : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
            ElevatedButton(
              onPressed: () {
                ref.read(canvasDocumentProvider.notifier).updatePagesSection(
                  pages, 
                  controller.text.trim(),
                  sectionColor: selectedColor,
                );
                Navigator.pop(ctx);
                _clearSelection();
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C5C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('MOVER'),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmBatchDelete(List<LocalPage> pages) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Apagar ${pages.length} páginas?'),
        content: const Text('Esta ação removerá permanentemente as folhas selecionadas.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('CANCELAR')),
          TextButton(
            onPressed: () {
              ref.read(canvasDocumentProvider.notifier).deletePages(pages);
              Navigator.pop(ctx);
              _clearSelection();
            },
            child: const Text('APAGAR', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}

class _PageGridItem extends StatelessWidget {
  final LocalPage page;
  final int index;
  final bool isSelected;
  final bool isCurrent;
  final bool isSelectionMode;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const _PageGridItem({
    super.key,
    required this.page,
    required this.index,
    required this.isSelected,
    required this.isCurrent,
    required this.isSelectionMode,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    const themeColor = Color(0xFF0F4C5C);

    return GestureDetector(
      onTap: onTap,
      onLongPress: onLongPress,
      child: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected 
                        ? themeColor 
                        : (isCurrent ? themeColor.withOpacity(0.3) : Colors.black.withOpacity(0.05)),
                      width: isSelected ? 3 : (isCurrent ? 2 : 1),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: isSelected ? themeColor.withOpacity(0.1) : Colors.black.withOpacity(0.03),
                        blurRadius: isSelected ? 12 : 6,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Stack(
                      children: [
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _PageThumbnailPainter(lineType: page.lineType ?? 'ruled'),
                          ),
                        ),
                        if (page.isFavorite)
                          const Positioned(
                            top: 6, right: 6,
                            child: Icon(Icons.star_rounded, color: Colors.orange, size: 18),
                          ),
                        if (page.sectionTitle != null && page.sectionTitle!.isNotEmpty)
                          Positioned(
                            bottom: 0, left: 0, right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                              color: themeColor.withOpacity(0.8),
                              child: Text(
                                page.sectionTitle!,
                                style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                if (isSelectionMode)
                  Positioned(
                    top: 8, left: 8,
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        color: isSelected ? themeColor : Colors.white70,
                        shape: BoxShape.circle,
                        border: Border.all(color: isSelected ? themeColor : Colors.black26),
                      ),
                      child: Icon(
                        isSelected ? Icons.check : null,
                        size: 14,
                        color: Colors.white,
                      ),
                    ),
                  )
                else
                  // 🚀 PUXADOR DE REORDENAÇÃO: Ativa o arrastamento IMEDIATO ao tocar no ícone
                  Positioned(
                    top: 4, left: 4,
                    child: Listener(
                      onPointerDown: (event) {
                        final listState = ReorderableGridStateMixin.of(context);
                        listState.startDragRecognizer(
                          index, 
                          event, 
                          ImmediateMultiDragGestureRecognizer(
                            debugOwner: context,
                          ),
                        );
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.drag_indicator_rounded, size: 20, color: Colors.black45),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isCurrent ? themeColor : Colors.black12,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '${index + 1}',
                  style: TextStyle(
                    color: isCurrent ? Colors.white : Colors.black54,
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  page.title.isEmpty ? 'Página ${index + 1}' : page.title,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                    color: isCurrent ? themeColor : Colors.black87,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color color;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color = const Color(0xFF0F4C5C),
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}

class _PageThumbnailPainter extends CustomPainter {
  final String lineType;
  _PageThumbnailPainter({required this.lineType});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black.withOpacity(0.04)
      ..strokeWidth = 0.8;

    if (lineType == 'ruled') {
      for (double y = 15; y < size.height; y += 10) {
        canvas.drawLine(Offset(8, y), Offset(size.width - 8, y), paint);
      }
    } else if (lineType == 'grid') {
      for (double x = 0; x < size.width; x += 10) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y < size.height; y += 10) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
