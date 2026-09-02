import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/canvas_document_provider.dart';
import '../../models/local_page_model.dart'; 
import '../../../../core/utils/geometry_utils.dart'; 
import '../../../notebooks/widgets/background_selector_sheet.dart'; 
import '../../../notebooks/models/notebook_configuration.dart'; 
import '../../../notebooks/widgets/page_preview.dart'; 

class AddPageDialog extends StatefulWidget {
  final String defaultLineType;
  final double defaultLineSpacing;
  final int? insertIndex; 

  const AddPageDialog({
    super.key,
    this.defaultLineType = 'ruled',
    this.defaultLineSpacing = 28.0,
    this.insertIndex,
  });

  @override
  State<AddPageDialog> createState() => _AddPageDialogState();
}

class _AddPageDialogState extends State<AddPageDialog> {
  String _selectedSize = 'A4';
  bool _isLandscape = false;
  bool _isInfinite = false; 
  late BackgroundConfig _selectedBackground; 
  final TextEditingController _sectionController = TextEditingController();
  int _quantity = 1; 
  
  final List<String> _sizes = ['A0', 'A1', 'A2', 'A3', 'A4', 'A5'];

  @override
  void initState() {
    super.initState();
    _selectedBackground = BackgroundConfig(type: widget.defaultLineType, spacing: widget.defaultLineSpacing);
  }

  @override
  void dispose() {
    _sectionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, child) {
        return AlertDialog(
          backgroundColor: const Color(0xFFFDFBF7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24), 
          title: Text(
            'Nova Folha',
            style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C)),
          ),
          content: Container(
            width: MediaQuery.of(context).size.width > 600 ? 500 : MediaQuery.of(context).size.width * 0.95,
            constraints: const BoxConstraints(maxWidth: 600),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Página Infinita', style: _sectionStyle()),
                    subtitle: const Text('Espaço de trabalho ilimitado', style: TextStyle(fontSize: 10)),
                    value: _isInfinite,
                    onChanged: (val) {
                      setState(() {
                        _isInfinite = val;
                        if (val) _selectedSize = 'A4'; 
                      });
                    },
                    activeColor: const Color(0xFF0F4C5C),
                  ),
                  const SizedBox(height: 12),

                  if (!_isInfinite) ...[
                    Text('Orientação', style: _sectionStyle()),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        _buildOptionCard(
                          label: 'Vertical',
                          icon: Icons.stay_current_portrait_rounded,
                          isSelected: !_isLandscape,
                          onTap: () => setState(() => _isLandscape = false),
                        ),
                        const SizedBox(width: 12),
                        _buildOptionCard(
                          label: 'Horizontal',
                          icon: Icons.stay_current_landscape_rounded,
                          isSelected: _isLandscape,
                          onTap: () => setState(() => _isLandscape = true),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),

                    Text('Tamanho do Papel', style: _sectionStyle()),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sizes.map((size) {
                        final bool isSelected = _selectedSize == size;
                        
                        return ChoiceChip(
                          label: Text(size),
                          selected: isSelected,
                          onSelected: (val) => setState(() => _selectedSize = size),
                          selectedColor: const Color(0xFF0F4C5C).withValues(alpha: 0.15),
                          labelStyle: TextStyle(
                            color: isSelected ? const Color(0xFF0F4C5C) : Colors.black87,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 24),
                  ],

                  Text('Estilo de Fundo', style: _sectionStyle()),
                  const SizedBox(height: 12),
                  InkWell(
                    onTap: () => _showBackgroundSelector(context),
                    borderRadius: BorderRadius.circular(16),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFF0F4C5C), width: 2.0), 
                        boxShadow: [BoxShadow(color: const Color(0xFF0F4C5C).withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4))],
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 54, height: 70, 
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.black.withValues(alpha: 0.1)),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: PagePreview(
                                isVibrant: true,
                                config: NotebookConfiguration(
                                  page: PageConfig(width: 210, height: 297, paperSize: 'A4'),
                                  background: _selectedBackground,
                                  margins: MarginsConfig(),
                                  header: HeaderFooterConfig(),
                                  footer: HeaderFooterConfig(),
                                  numbering: NumberingConfig(),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_selectedBackground.type.toUpperCase(), 
                                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14, color: const Color(0xFF0F4C5C))
                                ),
                                Text(_selectedBackground.subType ?? 'Padrão', 
                                  style: const TextStyle(fontSize: 11, color: Colors.black45)
                                ),
                                const SizedBox(height: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF0F4C5C).withValues(alpha: 0.08),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text('ALTERAR ESTILO', style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: Color(0xFF0F4C5C), letterSpacing: 0.5)),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.swap_horiz_rounded, color: Color(0xFF0F4C5C), size: 22),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  Text('Quantidade de Folhas', style: _sectionStyle()),
                  const SizedBox(height: 12),
                  _buildQuantitySelector(),
                  const SizedBox(height: 24),

                  Text('Secção (Opcional)', style: _sectionStyle()),
                  const SizedBox(height: 12),
                  _buildSectionAutocomplete(ref),
                ],
              ),
            ),
          ),
          actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('CANCELAR', style: TextStyle(color: Colors.black45, fontWeight: FontWeight.bold)),
            ),
            ElevatedButton(
              onPressed: () {
                ref.read(canvasDocumentProvider.notifier).addNewPage(
                  isLandscape: _isLandscape,
                  paperSize: _selectedSize,
                  isInfinite: _isInfinite,
                  lineType: _selectedBackground.type,
                  lineSpacing: _selectedBackground.spacing,
                  sectionTitle: _sectionController.text.trim().isEmpty ? null : _sectionController.text.trim(),
                  count: _quantity,
                  insertIndex: widget.insertIndex,
                );
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C5C),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('ADICIONAR', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );
  }

  void _showBackgroundSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BackgroundSelectorSheet(
        onSelected: (bg) => setState(() => _selectedBackground = bg),
      ),
    );
  }

  TextStyle _sectionStyle() => GoogleFonts.inter(
    fontSize: 12,
    fontWeight: FontWeight.bold,
    color: Colors.black38,
    letterSpacing: 1.1,
  );

  Widget _buildQuantitySelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _quantityButton(Icons.remove, () {
            if (_quantity > 1) setState(() => _quantity--);
          }),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '$_quantity',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C)),
            ),
          ),
          _quantityButton(Icons.add, () {
            if (_quantity < 50) setState(() => _quantity++);
          }),
          const SizedBox(width: 12),
          Text(
            _quantity == 1 ? 'folha' : 'folhas',
            style: GoogleFonts.inter(fontSize: 14, color: Colors.black45),
          ),
        ],
      ),
    );
  }

  Widget _quantityButton(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 4)],
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF0F4C5C)),
      ),
    );
  }

  Widget _buildSectionAutocomplete(WidgetRef ref) {
    final docState = ref.watch(canvasDocumentProvider);
    final List<String> existingSections = docState.pages
        .map((p) => p.sectionTitle)
        .where((s) => s != null && s.isNotEmpty)
        .cast<String>()
        .toSet()
        .toList();

    return Autocomplete<String>(
      optionsBuilder: (TextEditingValue textEditingValue) {
        if (textEditingValue.text.isEmpty) {
          return existingSections;
        }
        return existingSections.where((String option) {
          return option.toLowerCase().contains(textEditingValue.text.toLowerCase());
        });
      },
      onSelected: (String selection) {
        _sectionController.text = selection;
      },
      fieldViewBuilder: (context, fieldController, focusNode, onFieldSubmitted) {
        return TextField(
          controller: fieldController,
          focusNode: focusNode,
          onChanged: (val) => _sectionController.text = val,
          decoration: InputDecoration(
            hintText: 'Ex: Resumo Aula 1',
            filled: true,
            fillColor: Colors.black.withValues(alpha: 0.03),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            suffixIcon: const Icon(Icons.arrow_drop_down, color: Colors.black26),
          ),
          style: GoogleFonts.inter(fontSize: 14),
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 8,
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: MediaQuery.of(context).size.width * 0.7,
              constraints: const BoxConstraints(maxHeight: 200, maxWidth: 400),
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length,
                itemBuilder: (BuildContext context, int index) {
                  final String option = options.elementAt(index);
                  return ListTile(
                    dense: true,
                    title: Text(option, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                    onTap: () => onSelected(option),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildOptionCard({
    required String label,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F4C5C).withValues(alpha: 0.1) : Colors.transparent,
            border: Border.all(
              color: isSelected ? const Color(0xFF0F4C5C) : Colors.black12,
              width: isSelected ? 2 : 1,
            ),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Icon(icon, size: 18, color: isSelected ? const Color(0xFF0F4C5C) : Colors.black54),
              const SizedBox(height: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF0F4C5C) : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
