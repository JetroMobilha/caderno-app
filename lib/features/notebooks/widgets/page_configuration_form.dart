import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notebook_configuration.dart';
import 'background_selector_sheet.dart';

class PageConfigurationForm extends StatefulWidget {
  final NotebookConfiguration config;
  final Function(NotebookConfiguration) onChanged;

  const PageConfigurationForm({
    super.key,
    required this.config,
    required this.onChanged,
  });

  @override
  State<PageConfigurationForm> createState() => _PageConfigurationFormState();
}

class _PageConfigurationFormState extends State<PageConfigurationForm> {
  int? _openSectionIndex = 0; 
  final Map<int, ExpansionTileController> _controllers = {}; // 🚀 CONTROLO PRECISO

  final List<String> _masterFields = [
    'Disciplina', 'Professor', 'Aluno', 'Turma', 'Data', 'Tema', 
    'Curso', 'Semestre', 'Instituição', 'Projeto', 'Equipamento', 
    'Revisão', 'Local', 'Participantes', 'Prioridade'
  ];

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView( // 🚀 Corrigir overflow
      child: Column(
        children: [
          _buildSection(
            index: 0,
            title: 'Papel e Formato',
            icon: Icons.description_outlined,
            children: [
              const SizedBox(height: 16), // 🚀 Espaço aumentado entre título e input
              _buildPaperSizeSelector(),
              const SizedBox(height: 24),
              _buildOrientationSelector(),
              const SizedBox(height: 8),
            ],
          ),
          _buildSection(
            index: 1,
            title: 'Estilo de Fundo',
            icon: Icons.palette_outlined,
            children: [
              Material(
                color: Colors.transparent,
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text('Fundo Atual', style: GoogleFonts.inter(fontSize: 14)),
                  subtitle: Text(widget.config.background.subType ?? widget.config.background.type, style: const TextStyle(fontSize: 12)),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => _showBackgroundSelector(context),
                ),
              ),
            ],
          ),
          _buildSection(
            index: 2,
            title: 'Margens (mm)',
            icon: Icons.square_foot_rounded,
            children: [
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(child: _buildMarginInput('Topo', widget.config.margins.top, (v) => _updateMargins(top: v))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMarginInput('Base', widget.config.margins.bottom, (v) => _updateMargins(bottom: v))),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _buildMarginInput('Esquerda', widget.config.margins.left, (v) => _updateMargins(left: v))),
                  const SizedBox(width: 12),
                  Expanded(child: _buildMarginInput('Direita', widget.config.margins.right, (v) => _updateMargins(right: v))),
                ],
              ),
            ],
          ),
          _buildSection(
            index: 3,
            title: 'Cabeçalho e Rodapé',
            icon: Icons.vertical_align_top_rounded,
            children: [
              _buildHeaderFooterToggle(true),
              if (widget.config.header.enabled) ...[
                const Divider(),
                _buildFieldPicker(true),
              ],
              const SizedBox(height: 16),
              _buildHeaderFooterToggle(false),
              if (widget.config.footer.enabled) ...[
                const Divider(),
                _buildFieldPicker(false),
              ],
            ],
          ),
          _buildSection(
            index: 4,
            title: 'Numeração',
            icon: Icons.format_list_numbered_rounded,
            children: [
               SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Ativar Numeração', style: TextStyle(fontSize: 14)),
                value: widget.config.numbering.enabled,
                onChanged: (val) => _updateNumbering(enabled: val),
              ),
              if (widget.config.numbering.enabled) ...[
                const SizedBox(height: 8),
                _buildNumberingFormatSelector(),
              ],
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSection({required int index, required String title, required IconData icon, required List<Widget> children}) {
    final controller = _controllers.putIfAbsent(index, () => ExpansionTileController());

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black.withOpacity(0.05)),
        boxShadow: [
          if (_openSectionIndex == index)
            BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 8, offset: const Offset(0, 4)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: ExpansionTile(
          controller: controller,
          initiallyExpanded: _openSectionIndex == index,
          leading: Icon(icon, 
            color: _openSectionIndex == index ? const Color(0xFF0F4C5C) : Colors.black38, 
            size: 22
          ),
          title: Text(title, 
            style: GoogleFonts.inter(
              fontWeight: _openSectionIndex == index ? FontWeight.bold : FontWeight.w600, 
              fontSize: 14,
              color: _openSectionIndex == index ? const Color(0xFF0F4C5C) : Colors.black87,
            )
          ),
          onExpansionChanged: (isExpanded) {
            if (isExpanded) {
              setState(() => _openSectionIndex = index);
              // Fechar todos os outros manualmente
              _controllers.forEach((idx, ctrl) {
                if (idx != index) ctrl.collapse();
              });
            } else if (_openSectionIndex == index) {
              setState(() => _openSectionIndex = null);
            }
          },
          shape: const RoundedRectangleBorder(side: BorderSide.none),
          collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20), // 🚀 Padding interno aumentado
          expandedCrossAxisAlignment: CrossAxisAlignment.start,
          children: children,
        ),
      ),
    );
  }

  Widget _buildPaperSizeSelector() {
    return DropdownButtonFormField<String>(
      value: widget.config.page.paperSize,
      isExpanded: true,
      decoration: const InputDecoration(
        labelText: 'Tamanho da Folha', 
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
      items: ['A0', 'A1', 'A2', 'A3', 'A4', 'A5'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
      onChanged: (val) {
        if (val == null) return;
        double w = 210, h = 297;
        switch (val) {
          case 'A0': w = 841; h = 1189; break;
          case 'A1': w = 594; h = 841; break;
          case 'A2': w = 420; h = 594; break;
          case 'A3': w = 297; h = 420; break;
          case 'A4': w = 210; h = 297; break;
          case 'A5': w = 148; h = 210; break;
        }
        if (widget.config.page.orientation == 'landscape') {
          final temp = w; w = h; h = temp;
        }
        widget.onChanged(widget.config.copyWith(page: PageConfig(width: w, height: h, orientation: widget.config.page.orientation)));
      },
    );
  }

  Widget _buildOrientationSelector() {
    return Row(
      children: [
        _buildOrientationButton(
          label: 'Vertical',
          icon: Icons.stay_current_portrait_rounded,
          isSelected: widget.config.page.orientation == 'portrait',
          onTap: () => _updateOrientation('portrait'),
        ),
        const SizedBox(width: 12),
        _buildOrientationButton(
          label: 'Horizontal',
          icon: Icons.stay_current_landscape_rounded,
          isSelected: widget.config.page.orientation == 'landscape',
          onTap: () => _updateOrientation('landscape'),
        ),
      ],
    );
  }

  Widget _buildOrientationButton({
    required String label, 
    required IconData icon, 
    required bool isSelected, 
    required VoidCallback onTap
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F4C5C).withOpacity(0.1) : Colors.transparent,
            border: Border.all(
              color: isSelected ? const Color(0xFF0F4C5C) : Colors.black12,
              width: isSelected ? 1.5 : 1,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? const Color(0xFF0F4C5C) : Colors.black38, size: 24),
              const SizedBox(height: 4),
              Text(label, 
                style: GoogleFonts.inter(
                  fontSize: 12, 
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? const Color(0xFF0F4C5C) : Colors.black54,
                )
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMarginInput(String label, double value, Function(double) onVal) {
    return TextFormField(
      initialValue: value.toInt().toString(),
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label, 
        hintText: '0',
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12))),
      ),
      onChanged: (v) => onVal(double.tryParse(v) ?? 0),
    );
  }

  Widget _buildHeaderFooterToggle(bool isHeader) {
    final hf = isHeader ? widget.config.header : widget.config.footer;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(isHeader ? 'Ativar Cabeçalho' : 'Ativar Rodapé', style: const TextStyle(fontSize: 14)),
      value: hf.enabled,
      onChanged: (val) => _updateHeaderFooter(isHeader: isHeader, enabled: val),
    );
  }

  Widget _buildFieldPicker(bool isHeader) {
    final hf = isHeader ? widget.config.header : widget.config.footer;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.black.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Campos disponíveis:', 
            style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black45)
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _masterFields.map((field) {
              final bool isSelected = hf.fields.contains(field);
              return InkWell(
                onTap: () {
                   final List<String> newFields = List.from(hf.fields);
                   if (isSelected) newFields.remove(field); else newFields.add(field);
                   _updateHeaderFooter(isHeader: isHeader, fields: newFields);
                },
                borderRadius: BorderRadius.circular(12),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: isSelected ? const Color(0xFF0F4C5C) : Colors.white,
                    border: Border.all(color: isSelected ? const Color(0xFF0F4C5C) : Colors.black12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isSelected ? Icons.check_circle_rounded : Icons.add_circle_outline_rounded, 
                        size: 14, 
                        color: isSelected ? Colors.white : Colors.black26
                      ),
                      const SizedBox(width: 6),
                      Text(field, 
                        style: TextStyle(
                          fontSize: 11, 
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                          color: isSelected ? Colors.white : Colors.black54
                        )
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  void _updateOrientation(String orientation) {
    if (widget.config.page.orientation == orientation) return;
    widget.onChanged(widget.config.copyWith(page: PageConfig(width: widget.config.page.height, height: widget.config.page.width, orientation: orientation)));
  }

  void _updateMargins({double? top, double? bottom, double? left, double? right}) {
    widget.onChanged(widget.config.copyWith(margins: MarginsConfig(
      top: top ?? widget.config.margins.top,
      bottom: bottom ?? widget.config.margins.bottom,
      left: left ?? widget.config.margins.left,
      right: right ?? widget.config.margins.right,
    )));
  }

  void _updateHeaderFooter({required bool isHeader, bool? enabled, List<String>? fields}) {
    final hf = isHeader ? widget.config.header : widget.config.footer;
    final updated = HeaderFooterConfig(
      enabled: enabled ?? hf.enabled, 
      fields: fields ?? hf.fields, 
      customText: hf.customText
    );
    widget.onChanged(widget.config.copyWith(
      header: isHeader ? updated : widget.config.header,
      footer: isHeader ? widget.config.footer : updated,
    ));
  }

  Widget _buildNumberingFormatSelector() {
    final formats = {
      'numeric': 'Simples (1)',
      'counter': 'Contador (1 / n)',
      'labeled': 'Etiquetado (Pág. 1)',
      'roman': 'Romano (I)',
    };

    return DropdownButtonFormField<String>(
      value: widget.config.numbering.format,
      decoration: const InputDecoration(
        labelText: 'Formato da Numeração', 
        isDense: true, 
        border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(12)))
      ),
      items: formats.entries.map((e) => DropdownMenuItem(value: e.key, child: Text(e.value))).toList(),
      onChanged: (val) => _updateNumbering(format: val),
    );
  }

  void _updateNumbering({bool? enabled, String? format}) {
    widget.onChanged(widget.config.copyWith(numbering: NumberingConfig(
      enabled: enabled ?? widget.config.numbering.enabled,
      format: format ?? widget.config.numbering.format,
      position: widget.config.numbering.position,
    )));
  }

  void _showBackgroundSelector(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => BackgroundSelectorSheet(onSelected: (bg) => widget.onChanged(widget.config.copyWith(background: bg))),
    );
  }
}

extension NotebookConfigCopy on NotebookConfiguration {
  NotebookConfiguration copyWith({
    PageConfig? page,
    BackgroundConfig? background,
    MarginsConfig? margins,
    HeaderFooterConfig? header,
    HeaderFooterConfig? footer,
    NumberingConfig? numbering,
  }) {
    return NotebookConfiguration(
      page: page ?? this.page,
      background: background ?? this.background,
      margins: margins ?? this.margins,
      header: header ?? this.header,
      footer: footer ?? this.footer,
      numbering: numbering ?? this.numbering,
    );
  }
}
