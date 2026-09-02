import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ColorEngine {
  /// 🚀 SERVIÇO DE CORES: Abre o seletor rico e retorna a cor escolhida.
  static Future<String?> show(BuildContext context, {
    required String initialColor,
    String title = 'Escolher Cor',
    bool showNotebookPreview = true,
  }) async {
    return await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _ColorStudioSheet(
        initialColor: initialColor,
        title: title,
        showNotebookPreview: showNotebookPreview,
      ),
    );
  }
}

class _ColorStudioSheet extends StatefulWidget {
  final String initialColor;
  final String title;
  final bool showNotebookPreview;

  const _ColorStudioSheet({
    required this.initialColor,
    required this.title,
    required this.showNotebookPreview,
  });

  @override
  State<_ColorStudioSheet> createState() => _ColorStudioSheetState();
}

class _ColorStudioSheetState extends State<_ColorStudioSheet> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late String _selectedColorHex;
  late HSVColor _hsvColor;

  static final List<String> _recentColors = []; // Memória de sessão

  // 🚀 PALETA ÚNICA E RICA (30 Cores Profissionais)
  final List<String> _allPresets = [
    '#0F4C5C', '#1F4E79', '#2E5A88', '#3F51B5', '#5C6BC0', '#7986CB', // Azuis
    '#1E8449', '#27AE60', '#2ECC71', '#82E0AA', '#A9DFBF', '#D5F5E3', // Verdes
    '#8B0000', '#B03A2E', '#CB4335', '#E74C3C', '#F1948A', '#F9EBEA', // Vermelhos/Vinhos
    '#D35400', '#E67E22', '#F39C12', '#F5B041', '#F8C471', '#FEF9E7', // Laranjas/Amarelos
    '#6C3483', '#8E44AD', '#9B59B6', '#AF7AC5', '#D2B4DE', '#EBDEF0', // Roxos
    '#D81B60', '#E91E63', '#F06292', '#F48FB1', '#F8BBD0', '#FDEDEC', // Rosas
    '#2C3E50', '#566573', '#7F8C8D', '#99A3A4', '#BDC3C7', '#D6DBDF', // Cinzas
    '#000000', '#1A1A1A', '#333333', '#4D4D4D', '#666666', '#808080', // Escuros
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedColorHex = widget.initialColor;
    _hsvColor = HSVColor.fromColor(Color(int.parse(_selectedColorHex.replaceFirst('#', '0xFF'))));
  }

  void _onColorSelected(String hex) {
    setState(() {
      _selectedColorHex = hex;
      _hsvColor = HSVColor.fromColor(Color(int.parse(hex.replaceFirst('#', '0xFF'))));
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      decoration: const BoxDecoration(
        color: Color(0xFFF8F9FA),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          // Drag Handle
          const SizedBox(height: 12),
          Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.black12, borderRadius: BorderRadius.circular(2))),
          
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
            child: Row(
              children: [
                Text(widget.title, style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(icon: const Icon(Icons.close_rounded, size: 20), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),

          // PREVIEW COMPACTO (🚀 REDUZIDO)
          _buildContextualPreview(),

          // TABS
          TabBar(
            controller: _tabController,
            labelColor: const Color(0xFF0F4C5C),
            unselectedLabelColor: Colors.black38,
            indicatorColor: const Color(0xFF0F4C5C),
            indicatorSize: TabBarIndicatorSize.label,
            labelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
            tabs: const [
              Tab(text: 'PALETAS'),
              Tab(text: 'ESTÚDIO'),
            ],
          ),

          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildPresetsTab(),
                _buildStudioTab(),
              ],
            ),
          ),

          // ACTION BUTTON
          _buildConfirmButton(),
        ],
      ),
    );
  }

  Widget _buildContextualPreview() {
    final Color color = _hsvColor.toColor();
    final bool isDark = color.computeLuminance() < 0.5;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 12),
      height: 60, // 🚀 Altura reduzida
      width: 100, // 🚀 Largura reduzida
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [BoxShadow(color: color.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Stack(
        children: [
          if (widget.showNotebookPreview) ...[
            Positioned(left: 0, top: 0, bottom: 0, width: 8, child: Container(color: Colors.black.withOpacity(0.1))),
            Center(child: Icon(Icons.auto_stories_rounded, color: isDark ? Colors.white24 : Colors.black12, size: 24)),
          ] else
            Center(child: Icon(Icons.folder_rounded, color: isDark ? Colors.white24 : Colors.black12, size: 32)),
          
          Positioned(
            bottom: 4, right: 6,
            child: Text(_selectedColorHex.toUpperCase(), 
              style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.bold, color: isDark ? Colors.white38 : Colors.black26)
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPresetsTab() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        if (_recentColors.isNotEmpty) ...[
          _buildCategoryHeader('Recentes'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 12, runSpacing: 12,
            children: _recentColors.map((hex) => _buildColorCircle(hex)).toList(),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
        ],
        
        _buildCategoryHeader('Paleta de Cores'),
        const SizedBox(height: 16),
        Center(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            alignment: WrapAlignment.start,
            children: _allPresets.map((hex) => _buildColorCircle(hex)).toList(),
          ),
        ),
        const SizedBox(height: 40),
      ],
    );
  }

  Widget _buildStudioTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          _buildStudioSlider('Cor Base', _hsvColor.hue, 0, 360, (v) => setState(() => _hsvColor = _hsvColor.withHue(v))),
          const SizedBox(height: 20),
          _buildStudioSlider('Intensidade', _hsvColor.saturation, 0, 1, (v) => setState(() => _hsvColor = _hsvColor.withSaturation(v))),
          const SizedBox(height: 20),
          _buildStudioSlider('Brilho', _hsvColor.value, 0, 1, (v) => setState(() => _hsvColor = _hsvColor.withValue(v))),
        ],
      ),
    );
  }

  Widget _buildCategoryHeader(String title) {
    return Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black26, letterSpacing: 1.1));
  }

  Widget _buildColorCircle(String hex) {
    final bool isSelected = _selectedColorHex.toUpperCase() == hex.toUpperCase();
    final Color color = Color(int.parse(hex.replaceFirst('#', '0xFF')));

    return GestureDetector(
      onTap: () {
        _onColorSelected(hex);
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: isSelected ? const Color(0xFF0F4C5C) : Colors.black.withOpacity(0.05), 
            width: isSelected ? 3 : 1
          ),
          boxShadow: isSelected ? [BoxShadow(color: color.withOpacity(0.3), blurRadius: 6, offset: const Offset(0, 2))] : null,
        ),
        child: isSelected ? const Icon(Icons.check, size: 18, color: Colors.white) : null,
      ),
    );
  }

  Widget _buildStudioSlider(String title, double value, double min, double max, Function(double) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.black54)),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: _hsvColor.toColor(),
            thumbColor: _hsvColor.toColor(),
            overlayColor: _hsvColor.toColor().withOpacity(0.12),
            trackHeight: 4,
          ),
          child: Slider(
            value: value, 
            min: min, 
            max: max, 
            onChanged: (v) {
              onChanged(v);
              final color = _hsvColor.toColor();
              _selectedColorHex = '#${color.value.toRadixString(16).substring(2).toUpperCase()}';
            },
          ),
        ),
      ],
    );
  }

  Widget _buildConfirmButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
      decoration: BoxDecoration(
        color: Colors.white, 
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, -5))]
      ),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton(
          onPressed: () {
            // Guardar nos recentes
            if (!_recentColors.contains(_selectedColorHex)) {
              _recentColors.insert(0, _selectedColorHex);
              if (_recentColors.length > 12) _recentColors.removeLast();
            }
            Navigator.pop(context, _selectedColorHex);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF0F4C5C),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            elevation: 0,
          ),
          child: const Text('CONFIRMAR SELEÇÃO', style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5)),
        ),
      ),
    );
  }
}
