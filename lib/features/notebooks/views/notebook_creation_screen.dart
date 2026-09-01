import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/notebook_model.dart';
import '../models/notebook_template.dart';
import '../models/notebook_configuration.dart';
import '../controllers/notebooks_controller.dart';
import '../../subjects/models/subject_model.dart';
import '../widgets/page_preview.dart';
import '../widgets/background_selector_sheet.dart';
import '../models/background_catalog.dart';
import '../widgets/page_configuration_form.dart';

class NotebookCreationScreen extends ConsumerStatefulWidget {
  final Subject activeSubject;

  const NotebookCreationScreen({super.key, required this.activeSubject});

  @override
  ConsumerState<NotebookCreationScreen> createState() => _NotebookCreationScreenState();
}

class _NotebookCreationScreenState extends ConsumerState<NotebookCreationScreen> {
  int _currentStep = 0;
  NotebookTemplateType? _selectedTemplateType;
  late NotebookConfiguration _currentConfig;
  bool _isCustomizing = false;
  final TransformationController _transformationController = TransformationController();
  BackgroundConfig? _lastCustomBackground; // 🚀 MEMÓRIA DE FUNDO
  
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  String _selectedColorHex = '#8B0000';
  
  @override
  void initState() {
    super.initState();
    _currentConfig = NotebookConfiguration.defaultBlank();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _transformationController.dispose();
    super.dispose();
  }

  void _onTemplateSelected(NotebookTemplateType type) {
    setState(() {
      _selectedTemplateType = type;
      final template = NotebookTemplateConfig.templates[type]!;
      
      // 🚀 LÓGICA DE MEMÓRIA: Usar último fundo se o utilizador já tiver escolhido um
      _currentConfig = template.config.copyWith(
        background: _lastCustomBackground ?? template.config.background,
      );

      _selectedColorHex = '#${template.suggestedColor.value.toRadixString(16).substring(2).toUpperCase()}';
      _titleController.text = 'Meu Caderno ${template.label}';
      _isCustomizing = false; // Reset
      _currentStep = 1; // 🚀 Agora vai para o passo de Decisão
    });
  }

  @override
  Widget build(BuildContext context) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 900;
    
    // 🚀 AJUSTE DE PASSOS: 
    // 0: Seleção
    // 1: Decisão (Preview + Escolha)
    // 2 (+3 se mobile): Personalização (Opcional)
    // Final: Metadados
    final int totalSteps = isWide ? 4 : 5;
    final int lastStepIdx = totalSteps - 1;

    // 🚀 SEGURANÇA: Ajustar passo se a tela mudar de tamanho
    if (_currentStep > lastStepIdx) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _currentStep = lastStepIdx);
      });
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        title: Text(_getTitle(isWide), 
          style: GoogleFonts.lora(fontWeight: FontWeight.bold, fontSize: 18)
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(_currentStep == 0 ? Icons.close : Icons.arrow_back_ios_new_rounded, size: 20),
          onPressed: () {
            if (_currentStep == 0) Navigator.pop(context);
            else if (_currentStep == lastStepIdx && !_isCustomizing) setState(() => _currentStep = 1);
            else setState(() => _currentStep--);
          },
        ),
        actions: [
          // 🚀 REMOVIDO "CRIAR RÁPIDO" DA APPBAR QUANDO JÁ ESTAMOS NA DECISÃO (Passo 1)
          if (_currentStep == 0 && _selectedTemplateType != null)
             Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton.icon(
                onPressed: () {
                  setState(() {
                    _isCustomizing = false;
                    _currentStep = lastStepIdx;
                  });
                },
                icon: const Icon(Icons.bolt_rounded, color: Colors.orange, size: 20),
                label: const Text('RÁPIDO', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ),
            ),
          if (_currentStep == lastStepIdx)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: TextButton(
                onPressed: _createNotebook,
                child: const Text('CONCLUIR', style: TextStyle(fontWeight: FontWeight.bold, color: Color(0xFF0F4C5C))),
              ),
            ),
        ],
      ),
      body: _buildStepContent(isWide, lastStepIdx),
      bottomNavigationBar: _currentStep > 0 ? _buildBottomBar(isWide, lastStepIdx) : null,
    );
  }

  String _getTitle(bool isWide) {
    if (_currentStep == 0) return 'Escolher Modelo';
    if (_currentStep == 1) return 'Confirmar Modelo';
    
    if (isWide) {
      if (_currentStep == 2) return 'Personalizar';
      return 'Finalizar';
    } else {
      if (_currentStep == 2) return 'Configurar';
      if (_currentStep == 3) return 'Pré-visualizar';
      return 'Finalizar';
    }
  }

  Widget _buildStepContent(bool isWide, int lastStepIdx) {
    if (isWide) {
      switch (_currentStep) {
        case 0: return _buildTemplateSelection();
        case 1: return _buildDecisionStep(isWide, lastStepIdx);
        case 2: return _buildPersonalizationWide();
        case 3: return _buildMetadata();
        default: return Container();
      }
    } else {
      switch (_currentStep) {
        case 0: return _buildTemplateSelection();
        case 1: return _buildDecisionStep(isWide, lastStepIdx);
        case 2: return _buildOptionsOnly();
        case 3: return _buildPreviewOnly();
        case 4: return _buildMetadata();
        default: return Container();
      }
    }
  }

  Widget _buildDecisionStep(bool isWide, int lastStepIdx) {
    return Flex(
      direction: isWide ? Axis.horizontal : Axis.vertical,
      children: [
        Expanded(
          flex: isWide ? 1 : 1, // 🚀 Permitir que ambos escalem em Mobile
          child: Container(
            padding: EdgeInsets.all(isWide ? 32 : 16),
            color: Colors.black.withOpacity(0.05),
            child: _buildZoomablePreview(),
          ),
        ),
        Expanded(
          flex: isWide ? 1 : 1,
          child: Container(
            color: Colors.white,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: isWide ? CrossAxisAlignment.start : CrossAxisAlignment.center,
                children: [
                  Icon(_selectedTemplateType != null ? NotebookTemplateConfig.templates[_selectedTemplateType]!.icon : Icons.book, 
                    size: isWide ? 48 : 36, color: const Color(0xFF0F4C5C)
                  ),
                  const SizedBox(height: 12),
                  Text('Ótima escolha!', 
                    textAlign: isWide ? TextAlign.left : TextAlign.center,
                    style: GoogleFonts.lora(fontSize: isWide ? 24 : 20, fontWeight: FontWeight.bold)
                  ),
                  const SizedBox(height: 8),
                  Text(
                  'Este modelo já vem configurado com as melhores definições de pauta, margens e cabeçalho.',
                  textAlign: isWide ? TextAlign.left : TextAlign.center,
                  style: GoogleFonts.inter(color: Colors.black54, fontSize: isWide ? 14 : 13),
                ),
                const SizedBox(height: 32),
                  // 🚀 BOTÕES REFINADOS E MODERNOS
                  Center( // 🚀 Garantir centralização em mobile se houver espaço
                    child: Container(
                      width: double.infinity,
                      constraints: const BoxConstraints(maxWidth: 400),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: double.infinity,
                            height: isWide ? 56 : 52, // 🚀 Altura ligeiramente maior para mobile
                            child: ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isCustomizing = false;
                                  _currentStep = lastStepIdx;
                                });
                              },
                              icon: const Icon(Icons.bolt_rounded, size: 20),
                              label: Text('USAR PADRÕES', 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: isWide ? 15 : 14,
                                  letterSpacing: 0.5
                                )
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF0F4C5C),
                                foregroundColor: Colors.white,
                                elevation: 0,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            height: isWide ? 56 : 52,
                            child: OutlinedButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isCustomizing = true;
                                  _currentStep = 2;
                                });
                              },
                              icon: const Icon(Icons.tune_rounded, size: 20),
                              label: Text('PERSONALIZAR', 
                                style: TextStyle(
                                  fontWeight: FontWeight.bold, 
                                  fontSize: isWide ? 15 : 14,
                                  letterSpacing: 0.5
                                )
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFF0F4C5C),
                                side: const BorderSide(color: Color(0xFF0F4C5C), width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _showBackgroundSelector() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => BackgroundSelectorSheet(
        onSelected: (config) {
          setState(() {
            _currentConfig = NotebookConfiguration(
              page: _currentConfig.page,
              background: config,
              margins: _currentConfig.margins,
              header: _currentConfig.header,
              footer: _currentConfig.footer,
              numbering: _currentConfig.numbering,
            );
          });
        },
      ),
    );
  }

  Widget _buildTemplateSelection() {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isWide = screenWidth > 900;
    
    final Map<String, List<NotebookTemplateType>> categorizedTemplates = {
      'Geral': [NotebookTemplateType.blank],
      'Educação': [NotebookTemplateType.school, NotebookTemplateType.university, NotebookTemplateType.study],
      'Técnico': [NotebookTemplateType.engineering, NotebookTemplateType.accounting, NotebookTemplateType.laboratory],
      'Criativo': [NotebookTemplateType.drawing, NotebookTemplateType.music],
      'Gestão': [NotebookTemplateType.planner, NotebookTemplateType.project, NotebookTemplateType.meeting],
      'Pessoal': [NotebookTemplateType.diary],
    };

    return ListView.builder(
      padding: EdgeInsets.all(isWide ? 32 : 16),
      itemCount: categorizedTemplates.length + 1, // +1 for 'Personalizado'
      itemBuilder: (context, index) {
        if (index == categorizedTemplates.length) {
          return _buildCustomTemplateSection();
        }

        final category = categorizedTemplates.keys.elementAt(index);
        final types = categorizedTemplates[category]!;
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              child: Text(
                category.toUpperCase(),
                style: GoogleFonts.inter(
                  fontSize: 12, 
                  fontWeight: FontWeight.bold, 
                  color: Colors.black38,
                  letterSpacing: 1.2
                ),
              ),
            ),
            _buildTemplateGrid(types),
            const SizedBox(height: 16),
          ],
        );
      },
    );
  }

  Widget _buildTemplateGrid(List<NotebookTemplateType> types) {
    final double screenWidth = MediaQuery.of(context).size.width;
    int crossAxisCount = 2;
    if (screenWidth > 1200) crossAxisCount = 5;
    else if (screenWidth > 800) crossAxisCount = 4;
    else if (screenWidth > 500) crossAxisCount = 3;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1.1,
      ),
      itemCount: types.length,
      itemBuilder: (context, idx) {
        final type = types[idx];
        final template = NotebookTemplateConfig.templates[type]!;
        return _buildTemplateCard(type, template);
      },
    );
  }

  Widget _buildCustomTemplateSection() {
     return Column(
       crossAxisAlignment: CrossAxisAlignment.start,
       children: [
         const Divider(height: 64),
         Text(
           'OUTROS',
           style: GoogleFonts.inter(
             fontSize: 12, 
             fontWeight: FontWeight.bold, 
             color: Colors.black38,
             letterSpacing: 1.2
           ),
         ),
         const SizedBox(height: 16),
         _buildTemplateGrid([NotebookTemplateType.custom]),
         const SizedBox(height: 64),
       ],
     );
  }

  Widget _buildTemplateCard(NotebookTemplateType type, NotebookTemplateConfig template) {
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool isDesktop = screenWidth > 800;

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.black.withOpacity(0.05))
      ),
      child: InkWell(
        onTap: () => _onTemplateSelected(type),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                template.icon, 
                size: isDesktop ? 28 : 32,
                color: template.suggestedColor
              ),
              const SizedBox(height: 12),
              Text(
                template.label, 
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold, 
                  fontSize: isDesktop ? 13 : 14
                )
              ),
              ...[
                const SizedBox(height: 4),
                Text(
                  template.description, 
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontSize: 10, color: Colors.black38),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPersonalizationWide() {
    return Flex(
      direction: Axis.horizontal,
      children: [
        // Preview Panel
        Expanded(
          flex: 3,
          child: Container(
            height: double.infinity,
            color: Colors.black.withOpacity(0.05),
            padding: const EdgeInsets.all(32),
            child: _buildZoomablePreview(),
          ),
        ),
        // Options Panel
        Expanded(
          flex: 2,
          child: Container(
            color: Colors.white,
            child: Center(
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                child: PageConfigurationForm( // 🚀 NOVO: Form Reutilizável
                  config: _currentConfig,
                  onChanged: (newConfig) {
                    setState(() {
                      _currentConfig = newConfig;
                      _lastCustomBackground = newConfig.background; // 🚀 Guardar na memória
                    });
                  },
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildOptionsOnly() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: PageConfigurationForm(
        config: _currentConfig,
        onChanged: (newConfig) {
          setState(() {
            _currentConfig = newConfig;
            _lastCustomBackground = newConfig.background; // 🚀 Guardar na memória
          });
        },
      ),
    );
  }

  Widget _buildPreviewOnly() {
    return Container(
      color: Colors.black.withOpacity(0.05),
      padding: const EdgeInsets.all(32),
      child: _buildZoomablePreview(),
    );
  }

  Widget _buildZoomablePreview() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return Stack(
          children: [
            // 🚀 CONTAINER DE RECORTE (CLIPPING)
            ClipRect(
              child: InteractiveViewer(
                transformationController: _transformationController,
                clipBehavior: Clip.hardEdge, // 🚀 PRENDER O ZOOM NA ZONA
                minScale: 0.5,
                maxScale: 4.0,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.all(20),
                    constraints: BoxConstraints(
                      maxHeight: constraints.maxHeight * 0.95,
                      maxWidth: constraints.maxWidth * 0.95,
                    ),
                    child: PagePreview(config: _currentConfig),
                  ),
                ),
              ),
            ),
            // 🚀 BOTÕES DE ZOOM MAIS DISCRETOS
            Positioned(
              right: 12,
              bottom: 0,
              top: 0,
              child: Center(
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.4),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildZoomButton(Icons.add, () {
                        final currentScale = _transformationController.value.getMaxScaleOnAxis();
                        if (currentScale < 4.0) {
                          _transformationController.value = Matrix4.identity()..scale(currentScale + 0.5);
                        }
                      }),
                      const SizedBox(height: 4),
                      _buildZoomButton(Icons.remove, () {
                        final currentScale = _transformationController.value.getMaxScaleOnAxis();
                        if (currentScale > 0.5) {
                          _transformationController.value = Matrix4.identity()..scale(currentScale - 0.5);
                        }
                      }),
                      const SizedBox(height: 4),
                      _buildZoomButton(Icons.restart_alt, () {
                        _transformationController.value = Matrix4.identity();
                      }),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      }
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return Material(
      color: Colors.white.withOpacity(0.9),
      elevation: 1,
      shape: const CircleBorder(),
      child: InkWell(
        onTap: onTap,
        customBorder: const CircleBorder(),
        child: Container(
          width: 32, // 🚀 MUITO MAIS COMPACTO
          height: 32,
          alignment: Alignment.center,
          child: Icon(icon, size: 16, color: const Color(0xFF0F4C5C)),
        ),
      ),
    );
  }

  Widget _buildOptionsList() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text('Configurações da Página', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 18)),
        const SizedBox(height: 24),
        _buildOptionHeader('Tamanho e Orientação'),
        _buildPaperSizeSelector(),
        const SizedBox(height: 16),
        _buildOrientationSelector(),
        const Divider(height: 40),
        _buildOptionHeader('Fundo e Linhas'),
        Material(
          color: Colors.transparent,
          child: _buildBackgroundTypeSelector(),
        ),
        const Divider(height: 40),
        _buildOptionHeader('Cabeçalho e Rodapé'),
        Material(
          color: Colors.transparent,
          child: Column(
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Cabeçalho'),
                value: _currentConfig.header.enabled,
                onChanged: (val) => _updateHeaderFooter(true, enabled: val),
              ),
              if (_currentConfig.header.enabled)
                _buildFieldSelector(true),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Rodapé'),
                value: _currentConfig.footer.enabled,
                onChanged: (val) => _updateHeaderFooter(false, enabled: val),
              ),
              if (_currentConfig.footer.enabled)
                _buildFieldSelector(false),
            ],
          ),
        ),
        const Divider(height: 40),
        _buildOptionHeader('Numeração'),
        Material(
          color: Colors.transparent,
          child: SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Numeração de Páginas'),
            value: _currentConfig.numbering.enabled,
            onChanged: (val) => _updateNumbering(enabled: val),
          ),
        ),
        const SizedBox(height: 100),
      ],
    );
  }

  Widget _buildMetadata() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Center(
        child: Container(
          constraints: const BoxConstraints(maxWidth: 600),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Quase lá!', style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Dê um nome e uma identidade ao seu novo caderno.', style: GoogleFonts.inter(color: Colors.black54)),
              const SizedBox(height: 40),
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Título do Caderno',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.book_outlined),
                ),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Descrição (Opcional)',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.description_outlined),
                ),
              ),
              const SizedBox(height: 40),
              Text('Cor da Capa', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              _buildColorPicker(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar(bool isWide, int lastStepIdx) {
    // 🚀 OCULTAR BARRA NO PASSO DE SELEÇÃO E DECISÃO
    if (_currentStep == 0 || _currentStep == 1) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 4, offset: const Offset(0, -2))],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          TextButton(
            onPressed: () => setState(() => _currentStep--),
            child: const Text('VOLTAR'),
          ),
          ElevatedButton(
            onPressed: () {
              if (_currentStep < lastStepIdx) setState(() => _currentStep++);
              else _createNotebook();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF0F4C5C),
              foregroundColor: Colors.white,
              elevation: 0,
              padding: EdgeInsets.symmetric(horizontal: isWide ? 32 : 24, vertical: isWide ? 16 : 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(_currentStep == lastStepIdx ? 'CRIAR CADERNO' : 'CONTINUAR',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  void _updateHeaderFooter(bool isHeader, {bool? enabled, List<String>? fields}) {
    setState(() {
      final old = isHeader ? _currentConfig.header : _currentConfig.footer;
      final updated = HeaderFooterConfig(
        enabled: enabled ?? old.enabled,
        fields: fields ?? old.fields,
        customText: old.customText,
      );
      _currentConfig = NotebookConfiguration(
        page: _currentConfig.page,
        background: _currentConfig.background,
        margins: _currentConfig.margins,
        header: isHeader ? updated : _currentConfig.header,
        footer: isHeader ? _currentConfig.footer : updated,
        numbering: _currentConfig.numbering,
      );
    });
  }

  void _updateNumbering({bool? enabled}) {
    setState(() {
      _currentConfig = NotebookConfiguration(
        page: _currentConfig.page,
        background: _currentConfig.background,
        margins: _currentConfig.margins,
        header: _currentConfig.header,
        footer: _currentConfig.footer,
        numbering: NumberingConfig(
          enabled: enabled ?? _currentConfig.numbering.enabled,
          format: _currentConfig.numbering.format,
          position: _currentConfig.numbering.position,
        ),
      );
    });
  }

  Widget _buildFieldSelector(bool isHeader) {
    final hf = isHeader ? _currentConfig.header : _currentConfig.footer;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Wrap(
        spacing: 4,
        children: hf.fields.map((f) => Chip(
          label: Text(f, style: const TextStyle(fontSize: 10)),
          onDeleted: () {
             final newFields = List<String>.from(hf.fields)..remove(f);
             _updateHeaderFooter(isHeader, fields: newFields);
          },
        )).toList(),
      ),
    );
  }

  Widget _buildOptionHeader(String title) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.black38, letterSpacing: 1.2)),
  );

  Widget _buildPaperSizeSelector() => DropdownButtonFormField<String>(
    value: _currentConfig.page.paperSize,
    decoration: const InputDecoration(labelText: 'Tamanho do Papel'),
    items: ['A0', 'A1', 'A2', 'A3', 'A4', 'A5'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
    onChanged: (val) {
      if (val == null) return;
      double w = 210, h = 297; // A4 default
      
      switch (val) {
        case 'A0': w = 841; h = 1189; break;
        case 'A1': w = 594; h = 841; break;
        case 'A2': w = 420; h = 594; break;
        case 'A3': w = 297; h = 420; break;
        case 'A4': w = 210; h = 297; break;
        case 'A5': w = 148; h = 210; break;
      }
      
      if (_currentConfig.page.orientation == 'landscape') {
        final temp = w; w = h; h = temp;
      }

      setState(() {
        _currentConfig = NotebookConfiguration(
          page: PageConfig(width: w, height: h, unit: 'mm', orientation: _currentConfig.page.orientation),
          background: _currentConfig.background,
          margins: _currentConfig.margins,
          header: _currentConfig.header,
          footer: _currentConfig.footer,
          numbering: _currentConfig.numbering,
        );
      });
    },
  );

  Widget _buildOrientationSelector() => Row(
    children: [
      ChoiceChip(
        label: const Text('Vertical'), 
        selected: _currentConfig.page.orientation == 'portrait', 
        onSelected: (val) => _updateOrientation('portrait')
      ),
      const SizedBox(width: 8),
      ChoiceChip(
        label: const Text('Horizontal'), 
        selected: _currentConfig.page.orientation == 'landscape', 
        onSelected: (val) => _updateOrientation('landscape')
      ),
    ],
  );

  void _updateOrientation(String orientation) {
    if (_currentConfig.page.orientation == orientation) return;
    setState(() {
      final w = _currentConfig.page.height;
      final h = _currentConfig.page.width;
      _currentConfig = NotebookConfiguration(
        page: PageConfig(width: w, height: h, unit: 'mm', orientation: orientation),
        background: _currentConfig.background,
        margins: _currentConfig.margins,
        header: _currentConfig.header,
        footer: _currentConfig.footer,
        numbering: _currentConfig.numbering,
      );
    });
  }

  Widget _buildBackgroundTypeSelector() {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text('Estilo de Fundo', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
      subtitle: Text(_currentConfig.background.subType ?? _currentConfig.background.type),
      trailing: const Icon(Icons.chevron_right),
      onTap: _showBackgroundSelector,
    );
  }

  Widget _buildColorPicker() {
    final List<String> availableColors = [
      '#8B0000', '#0F4C5C', '#1F4E79', '#3F51B5',
      '#6C3483', '#9B59B6', '#D81B60', '#E91E63',
      '#E67E22', '#D35400', '#F1C40F', '#1E8449',
    ];
    return Wrap(
      spacing: 12, runSpacing: 12,
      children: availableColors.map((hex) => GestureDetector(
        onTap: () => setState(() => _selectedColorHex = hex),
        child: CircleAvatar(
          backgroundColor: Color(int.parse(hex.replaceFirst('#', '0xFF'))),
          radius: 20,
          child: _selectedColorHex == hex ? const Icon(Icons.check, color: Colors.white) : null,
        ),
      )).toList(),
    );
  }

  void _createNotebook() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Por favor, dê um nome ao caderno.')));
      return;
    }

    final newNotebook = Notebook(
      subjectId: widget.activeSubject.id ?? 0,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      coverType: 'color',
      color: _selectedColorHex,
      templateType: _selectedTemplateType?.name ?? 'blank',
      configuration: _currentConfig,
    );

    final id = await ref.read(notebooksProvider.notifier).addNotebook(newNotebook, widget.activeSubject.serverId);
    if (mounted) {
      Navigator.pop(context);
      // Optional: Navigate to the new notebook
    }
  }
}
