import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/background_catalog.dart';
import '../models/notebook_configuration.dart';
import 'page_preview.dart';

class BackgroundSelectorSheet extends StatefulWidget {
  final Function(BackgroundConfig) onSelected;

  const BackgroundSelectorSheet({super.key, required this.onSelected});

  @override
  State<BackgroundSelectorSheet> createState() => _BackgroundSelectorSheetState();
}

class _BackgroundSelectorSheetState extends State<BackgroundSelectorSheet> {
  // 🚀 MEMÓRIA DE SESSÃO: Lembrar a última categoria e opção selecionadas
  static String _lastCategoryId = 'writing';
  static String? _lastOptionId;
  
  late String _selectedCategoryId;

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = _lastCategoryId;
  }

  void _onCategoryTap(String id) {
    setState(() {
      _selectedCategoryId = id;
      _lastCategoryId = id; // Guardar na memória estática
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Row(
              children: [
                Text('Escolher Fundo', style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),

          // Categories & Options
          Expanded(
            child: Row(
              children: [
                // Navigation Rail / Categories
                Container(
                  width: 100,
                  color: Colors.black.withOpacity(0.03),
                  child: ListView.builder(
                    itemCount: BackgroundCatalog.categories.length,
                    itemBuilder: (context, index) {
                      final cat = BackgroundCatalog.categories[index];
                      final isSelected = _selectedCategoryId == cat.id;
                      return InkWell(
                        onTap: () => _onCategoryTap(cat.id),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          color: isSelected ? Colors.white : Colors.transparent,
                          child: Column(
                            children: [
                              Icon(cat.icon, color: isSelected ? const Color(0xFF0F4C5C) : Colors.black38),
                              const SizedBox(height: 4),
                              Text(cat.label, 
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 10, 
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF0F4C5C) : Colors.black38
                                )
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),

                // Options Grid
                Expanded(
                  child: _buildOptionsGrid(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOptionsGrid() {
    final category = BackgroundCatalog.categories.firstWhere((c) => c.id == _selectedCategoryId);
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 0.75,
      ),
      itemCount: category.options.length,
      itemBuilder: (context, index) {
        final option = category.options[index];
        return _buildOptionCard(option);
      },
    );
  }

  Widget _buildOptionCard(BackgroundOption option) {
    final bool isLastSelected = _lastOptionId == option.id;

    return InkWell(
      onTap: () {
        setState(() {
          _lastOptionId = option.id;
        });
        widget.onSelected(option.config);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(16),
      child: Column(
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isLastSelected ? const Color(0xFF0F4C5C) : Colors.black12,
                  width: isLastSelected ? 2.0 : 1.0,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Stack(
                  children: [
                    PagePreview(
                      isVibrant: true,
                      config: NotebookConfiguration(
                        page: PageConfig(width: 210, height: 297),
                        background: option.config,
                        margins: MarginsConfig(),
                        header: HeaderFooterConfig(),
                        footer: HeaderFooterConfig(),
                        numbering: NumberingConfig(),
                      ),
                    ),
                    if (isLastSelected)
                      Positioned(
                        top: 4, right: 4,
                        child: CircleAvatar(
                          radius: 10,
                          backgroundColor: const Color(0xFF0F4C5C),
                          child: Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(option.label, 
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 11, 
              fontWeight: isLastSelected ? FontWeight.bold : FontWeight.w500,
              color: isLastSelected ? const Color(0xFF0F4C5C) : Colors.black87,
            )
          ),
        ],
      ),
    );
  }
}
