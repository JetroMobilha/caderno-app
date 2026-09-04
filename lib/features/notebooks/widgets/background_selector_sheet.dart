import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/background_catalog.dart';
import '../models/notebook_configuration.dart';
import 'page_preview.dart';

class BackgroundSelectorSheet extends StatefulWidget {
  final Function(BackgroundConfig) onSelected;
  final BackgroundConfig? initialConfig; 

  const BackgroundSelectorSheet({
    super.key, 
    required this.onSelected,
    this.initialConfig,
  });

  @override
  State<BackgroundSelectorSheet> createState() => _BackgroundSelectorSheetState();
}

class _BackgroundSelectorSheetState extends State<BackgroundSelectorSheet> {
  static String _lastCategoryId = 'basic';
  
  late String _selectedCategoryId;
  String? _currentOptionId; 

  @override
  void initState() {
    super.initState();
    _selectedCategoryId = _lastCategoryId;
    
    if (widget.initialConfig != null) {
      _findCurrentOption(widget.initialConfig!);
    }
  }

  void _findCurrentOption(BackgroundConfig config) {
    for (var cat in BackgroundCatalog.categories) {
      for (var opt in cat.options) {
        if (_isMatch(opt.config, config)) {
          _currentOptionId = opt.id;
          _selectedCategoryId = cat.id;
          _lastCategoryId = cat.id;
          return;
        }
      }
    }
  }

  bool _isMatch(BackgroundConfig a, BackgroundConfig b) {
    return a.type == b.type && 
           a.subType == b.subType && 
           (a.spacing - b.spacing).abs() < 0.1 &&
           a.showRedMargin == b.showRedMargin;
  }

  void _onCategoryTap(String id) {
    setState(() {
      _selectedCategoryId = id;
      _lastCategoryId = id;
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
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 12, 10),
            child: Row(
              children: [
                Text('Escolher Fundo', style: GoogleFonts.lora(fontSize: 22, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close_rounded), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 100,
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.02),
                    border: Border(right: BorderSide(color: Colors.black.withValues(alpha: 0.05))),
                  ),
                  child: ListView.builder(
                    itemCount: BackgroundCatalog.categories.length,
                    itemBuilder: (context, index) {
                      final cat = BackgroundCatalog.categories[index];
                      final isSelected = _selectedCategoryId == cat.id;
                      return InkWell(
                        onTap: () => _onCategoryTap(cat.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.transparent,
                            border: isSelected ? const Border(left: BorderSide(color: Color(0xFF0F4C5C), width: 4)) : null,
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(cat.icon, 
                                color: isSelected ? const Color(0xFF0F4C5C) : Colors.black38,
                                size: 24,
                              ),
                              const SizedBox(height: 6),
                              Text(cat.label, 
                                textAlign: TextAlign.center,
                                style: GoogleFonts.inter(
                                  fontSize: 10, 
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                                  color: isSelected ? const Color(0xFF0F4C5C) : Colors.black45
                                )
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
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
      padding: const EdgeInsets.all(20),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 20,
        crossAxisSpacing: 20,
        childAspectRatio: 0.72,
      ),
      itemCount: category.options.length,
      itemBuilder: (context, index) {
        final option = category.options[index];
        return _buildOptionCard(option);
      },
    );
  }

  Widget _buildOptionCard(BackgroundOption option) {
    final bool isSelected = _currentOptionId == option.id;

    return InkWell(
      onTap: () {
        setState(() => _currentOptionId = option.id);
        widget.onSelected(option.config);
        Navigator.pop(context);
      },
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isSelected ? const Color(0xFF0F4C5C) : Colors.black.withValues(alpha: 0.1),
                  width: isSelected ? 2.5 : 1.0, 
                ),
                boxShadow: isSelected ? [
                  BoxShadow(color: const Color(0xFF0F4C5C).withValues(alpha: 0.15), blurRadius: 10, offset: const Offset(0, 4))
                ] : null,
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: Stack(
                  children: [
                    PagePreview(
                      isVibrant: true,
                      config: NotebookConfiguration(
                        page: PageConfig(
                          width: 210, 
                          height: 297, 
                          paperSize: 'A4',
                          orientation: 'portrait',
                        ),
                        background: option.config,
                        margins: MarginsConfig(),
                        header: HeaderFooterConfig(),
                        footer: HeaderFooterConfig(),
                        numbering: NumberingConfig(),
                      ),
                    ),
                    if (isSelected)
                      Positioned(
                        top: 8, right: 8,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(color: Color(0xFF0F4C5C), shape: BoxShape.circle),
                          child: const Icon(Icons.check_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(option.label, 
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.inter(
              fontSize: 11, 
              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
              color: isSelected ? const Color(0xFF0F4C5C) : Colors.black87,
            )
          ),
        ],
      ),
    );
  }
}
