import 'package:flutter/material.dart';
import '../../models/local_page_model.dart';

class ExportPdfDialog extends StatefulWidget {
  final String notebookTitle;
  final List<LocalPage> allPages;

  const ExportPdfDialog({
    super.key,
    required this.notebookTitle,
    required this.allPages,
  });

  static Future<List<LocalPage>?> show(
    BuildContext context, {
    required String notebookTitle,
    required List<LocalPage> allPages,
  }) {
    return showDialog<List<LocalPage>>(
      context: context,
      builder: (context) => ExportPdfDialog(
        notebookTitle: notebookTitle,
        allPages: allPages,
      ),
    );
  }

  @override
  State<ExportPdfDialog> createState() => _ExportPdfDialogState();
}

class _ExportPdfDialogState extends State<ExportPdfDialog> {
  bool _exportAll = true;
  late Set<String> _selectedClientIds;

  @override
  void initState() {
    super.initState();
    _selectedClientIds = widget.allPages.map((p) => p.clientId).toSet();
  }

  List<LocalPage> get _effectiveSelectedPages {
    if (_exportAll) return widget.allPages;
    return widget.allPages.where((p) => _selectedClientIds.contains(p.clientId)).toList();
  }

  void _toggleSelectAll(bool selectAll) {
    setState(() {
      if (selectAll) {
        _selectedClientIds = widget.allPages.map((p) => p.clientId).toSet();
      } else {
        _selectedClientIds.clear();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedCount = _effectiveSelectedPages.length;
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        width: 440,
        constraints: const BoxConstraints(maxHeight: 560),
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF0F4C5C), size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Exportar para PDF',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        widget.notebookTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context, null),
                  icon: const Icon(Icons.close_rounded),
                  tooltip: 'Fechar',
                ),
              ],
            ),
            const Divider(height: 24),

            // Opções de Escopo
            RadioListTile<bool>(
              value: true,
              groupValue: _exportAll,
              onChanged: (val) {
                if (val != null) setState(() => _exportAll = val);
              },
              title: Text('Caderno Inteiro (${widget.allPages.length} páginas)'),
              subtitle: const Text('Exportar todas as páginas do caderno em sequência'),
              activeColor: const Color(0xFF0F4C5C),
              contentPadding: EdgeInsets.zero,
            ),
            RadioListTile<bool>(
              value: false,
              groupValue: _exportAll,
              onChanged: (val) {
                if (val != null) setState(() => _exportAll = val);
              },
              title: const Text('Selecionar Páginas Específicas'),
              subtitle: const Text('Escolher quais folhas devem ser incluídas no PDF'),
              activeColor: const Color(0xFF0F4C5C),
              contentPadding: EdgeInsets.zero,
            ),

            // Lista de Páginas para Seleção
            if (!_exportAll) ...[
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Páginas (${_selectedClientIds.length}/${widget.allPages.length})',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey.shade700),
                  ),
                  Row(
                    children: [
                      TextButton(
                        onPressed: () => _toggleSelectAll(true),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                        child: const Text('Marcar Todas', style: TextStyle(fontSize: 11)),
                      ),
                      TextButton(
                        onPressed: () => _toggleSelectAll(false),
                        style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                        child: const Text('Desmarcar', style: TextStyle(fontSize: 11, color: Colors.redAccent)),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Expanded(
                child: Material(
                  color: Colors.grey.shade50,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                    side: BorderSide(color: Colors.grey.shade200),
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: ListView.separated(
                    itemCount: widget.allPages.length,
                    separatorBuilder: (context, index) => Divider(height: 1, color: Colors.grey.shade200),
                    itemBuilder: (context, index) {
                      final page = widget.allPages[index];
                      final isSelected = _selectedClientIds.contains(page.clientId);
                      return CheckboxListTile(
                        value: isSelected,
                        onChanged: (val) {
                          setState(() {
                            if (val == true) {
                              _selectedClientIds.add(page.clientId);
                            } else {
                              _selectedClientIds.remove(page.clientId);
                            }
                          });
                        },
                        title: Text('Página ${page.pageNumber}'),
                        subtitle: page.title.isNotEmpty ? Text(page.title, maxLines: 1, overflow: TextOverflow.ellipsis) : null,
                        activeColor: const Color(0xFF0F4C5C),
                        dense: true,
                        controlAffinity: ListTileControlAffinity.leading,
                      );
                    },
                  ),
                ),
              ),
            ] else
              const Spacer(),

            const SizedBox(height: 16),

            // Ações
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton(
                  onPressed: () => Navigator.pop(context, null),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 12),
                ElevatedButton.icon(
                  onPressed: selectedCount > 0
                      ? () => Navigator.pop(context, _effectiveSelectedPages)
                      : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C5C),
                    foregroundColor: Colors.white,
                  ),
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: Text('Exportar PDF ($selectedCount págs)'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
