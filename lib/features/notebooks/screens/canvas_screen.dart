import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/drawing_point_model.dart';
import '../repositories/notebook_repository.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CanvasScreen extends StatefulWidget {
  final int notebookId;
  final String notebookTitle;
  final String lineType;
  final String paperSize;

  const CanvasScreen({
    super.key,
    required this.notebookId,
    required this.notebookTitle,
    this.lineType = 'ruled',
    required this.paperSize,
  });

  @override
  State<CanvasScreen> createState() => _CanvasScreenState();
}

// 🚀 Máquina de Estados para as ferramentas
enum ToolMode { draw, pan, select, text, eraser, insertImage, imageEdit }

class _CanvasScreenState extends State<CanvasScreen> {
  // 🚀 INSTÂNCIA DO REPOSITÓRIO E CONTROLO DE CARREGAMENTO
  final NotebookRepository _repository = NotebookRepository();
  bool _isLoading = true;

  List<LocalPage> _pages = [];
  int _currentPageIndex = 0;
  // 🚀 NOTIFICADOR DE ALTA PERFORMANCE (Evita o setState enquanto desenhas!)
  final ValueNotifier<List<Offset>> _activePointsNotifier = ValueNotifier([]);

  ToolMode _currentTool = ToolMode.draw;
  // 🚀 NOVOS CONTROLADORES PARA A EDIÇÃO INLINE (Direto na Folha)
  TextBlock? _editingTextBlock;
  final FocusNode _textFocusNode = FocusNode();
  final TextEditingController _textController = TextEditingController();

  final Set<String> _selectedStrokeIds = {};
  Offset? _selectionRectStart;
  Offset? _selectionRectEnd;
  bool _isMovingStrokes = false;
  Offset? _lastPanOffset;

  String _selectedColorHex = '#2C3E50';
  double _selectedThickness = 3.0;

  final PageController _pageController = PageController(initialPage: 0);

  // 📐 DIMENSÕES ISO
  final Map<String, Size> _paperSizes = {
    'A5': const Size(420, 595),
    'A4': const Size(595, 842),
    'A3': const Size(842, 1191),
    'A2': const Size(1191, 1684),
    'A1': const Size(1684, 2384),
    'A0': const Size(2384, 3370),
  };

  // 🚀 PALETA EXPANDIDA
  final Map<String, Color> _colorPalette = {
    'Preto': const Color(0xFF1A1A24),
    'Cinzento Escuro': const Color(0xFF455A64),
    'Cinzento Claro': const Color(0xFF90A4AE),
    'Azul Marinho': const Color(0xFF2C3E50),
    'Azul Clássico': const Color(0xFF1976D2),
    'Ciano': const Color(0xFF00BCD4),
    'Verde Floresta': const Color(0xFF27AE60),
    'Verde Alface': const Color(0xFF8BC34A),
    'Amarelo': const Color(0xFFFBC02D),
    'Laranja': const Color(0xFFE67E22),
    'Vermelho': const Color(0xFFE74C3C),
    'Bordô': const Color(0xFFB71C1C),
    'Rosa': const Color(0xFFE91E63),
    'Roxo': const Color(0xFF9B59B6),
    'Castanho': const Color(0xFF795548),
  };

  final List<double> _thicknessOptions = [1.0, 2.0, 3.0, 5.0, 10.0, 20.0];

  @override
  void initState() {
    super.initState();
    _loadSavedPages();
  }

  // 🚀 MÉTODO DE CARREGAMENTO OFFLINE-FIRST (Agora 100% Ativo)
  Future<void> _loadSavedPages() async {
    try {
      // 1. Vai buscar as folhas pesadas ao SQLite através do Repositório
      final pages = await _repository.getFullPagesForNotebook(widget.notebookId);

      setState(() {
        _pages = pages;
        _isLoading = false;
      });

    } catch (e) {
      print("Erro ao carregar o caderno: $e");
      setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _activePointsNotifier.dispose(); // 🚀 LIMPEZA DE MEMÓRIA
    _pageController.dispose();
    _textFocusNode.dispose();
    _textController.dispose();
    for (var page in _pages) {
      page.dispose();
    }
    super.dispose();
  }

  // 🚀 GUARDA O TEXTO E DEVOLVE A BARRA NORMAL
  void _finishEditingText(LocalPage page) {
    if (_editingTextBlock == null) return;

    setState(() {
      _editingTextBlock!.text = _textController.text.trim();

      // Se ele não escreveu nada, removemos o bloco da folha
      if (_editingTextBlock!.text.isEmpty) {
        page.textBlocks.remove(_editingTextBlock);
      } else if (page.id != null) {
        // Gravação ultra-rápida no SQLite
        _repository.saveSingleTextBlock(page.id!, _editingTextBlock!);
      }

      _editingTextBlock = null; // Sai do modo de edição
    });

    _textFocusNode.unfocus(); // Esconde o teclado do telemóvel
  }

  void _resetZoomForPage(LocalPage page, String paperSize) {
    final double initialScale = paperSize == 'A0' || paperSize == 'A1' ? 0.25 : 1.4;
    page.transformationController.value = Matrix4.identity()..scale(initialScale);
  }

  void _zoom(double factor) {
    if (_pages.isEmpty) return;
    final currentPage = _pages[_currentPageIndex];

    setState(() {
      final Matrix4 matrix = currentPage.transformationController.value;
      final double currentScale = matrix.getMaxScaleOnAxis();
      if (currentScale * factor < 0.1 || currentScale * factor > 6.0) return;

      final Size screenSize = MediaQuery.of(context).size;
      final double centerX = screenSize.width / 2;
      final double centerY = screenSize.height / 2;

      matrix.translate(centerX, centerY);
      matrix.scale(factor);
      matrix.translate(-centerX, -centerY);

      currentPage.transformationController.value = matrix;
    });
  }

  void _showAddPageDialog() {
    bool selectedIsLandscape = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFFFDFBF7),
          title: Text('Nova Folha', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Escolha a orientação desta folha:', style: GoogleFonts.inter(fontSize: 14)),
              const SizedBox(height: 16),
              RadioListTile<bool>(
                title: const Text('Retrato (Vertical)'),
                value: false,
                groupValue: selectedIsLandscape,
                onChanged: (value) => setModalState(() => selectedIsLandscape = value!),
              ),
              RadioListTile<bool>(
                title: const Text('Paisagem (Horizontal)'),
                value: true,
                groupValue: selectedIsLandscape,
                onChanged: (value) => setModalState(() => selectedIsLandscape = value!),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C)),
              onPressed: () async {
                // 🚀 ADAPTAÇÃO AO TEU SQLITE: Informa o ID do caderno e número da página
                final newPage = LocalPage(
                  notebookId: widget.notebookId,
                  pageNumber: _pages.length + 1,
                  isLandscape: selectedIsLandscape,
                );

                _resetZoomForPage(newPage, widget.paperSize);

                setState(() {
                  _pages.add(newPage);
                });
                Navigator.pop(context);

                // 🚀 BULK SAVE PARA CRIAR A FOLHA NO SQLITE IMEDIATAMENTE
                await _repository.saveFullNotebook(widget.notebookId, _pages);

                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_pageController.hasClients) {
                    _pageController.animateToPage(
                      _pages.length - 1,
                      duration: const Duration(milliseconds: 400),
                      curve: Curves.easeOutCubic,
                    );
                  }
                });
              },
              child: const Text('Adicionar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  void _showColorStudioDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Cor da Caneta', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
        content: SizedBox(
          width: double.maxFinite,
          child: Wrap(
            spacing: 16,
            runSpacing: 16,
            alignment: WrapAlignment.center,
            children: [
              ..._colorPalette.entries.map((entry) {
                final hex = '#${entry.value.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                final isSelected = _selectedColorHex == hex;
                return GestureDetector(
                  onTap: () {
                    setState(() => _selectedColorHex = hex);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: isSelected ? const Color(0xFF0F4C5C) : Colors.transparent, width: 2),
                    ),
                    child: CircleAvatar(radius: 16, backgroundColor: entry.value),
                  ),
                );
              }),
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                  _showAdvancedColorPicker();
                },
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black26, width: 2),
                  ),
                  child: const CircleAvatar(
                    radius: 16,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.colorize, size: 16, color: Color(0xFF0F4C5C)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAdvancedColorPicker() {
    Color currentColor = Color(int.parse(_selectedColorHex.replaceFirst('#', '0xFF')));
    double r = currentColor.red.toDouble();
    double g = currentColor.green.toDouble();
    double b = currentColor.blue.toDouble();

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) {
          final previewColor = Color.fromARGB(255, r.toInt(), g.toInt(), b.toInt());

          return AlertDialog(
            backgroundColor: const Color(0xFFFDFBF7),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text('Misturador de Cores', style: GoogleFonts.lora(fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: previewColor,
                  child: Container(
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white24, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '#${r.toInt().toRadixString(16).padLeft(2, '0')}${g.toInt().toRadixString(16).padLeft(2, '0')}${b.toInt().toRadixString(16).padLeft(2, '0')}'.toUpperCase(),
                  style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.black54),
                ),
                const SizedBox(height: 20),
                _buildRGBSlider('V', r, Colors.red, (val) => setModalState(() => r = val)),
                _buildRGBSlider('Vd', g, Colors.green, (val) => setModalState(() => g = val)),
                _buildRGBSlider('Az', b, Colors.blue, (val) => setModalState(() => b = val)),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C)),
                onPressed: () {
                  final hexString = '#${r.toInt().toRadixString(16).padLeft(2, '0')}${g.toInt().toRadixString(16).padLeft(2, '0')}${b.toInt().toRadixString(16).padLeft(2, '0')}'.toUpperCase();
                  setState(() => _selectedColorHex = hexString);
                  Navigator.pop(context);
                },
                child: const Text('Confirmar', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showTextInputDialog({
    required String initialText,
    String title = 'Editar Texto',
    bool initialBold = false,
    bool initialItalic = false,
    bool initialUnderline = false,
    String initialColorHex = '#1A1A24',
    double initialFontSize = 18.0,
    required Function(String text, bool bold, bool italic, bool underline, String colorHex, double fontSize) onSave
  })
  {
    final TextEditingController textController = TextEditingController(text: initialText);
    bool bold = initialBold;
    bool italic = initialItalic;
    bool underline = initialUnderline;
    String colorHex = initialColorHex;
    double fontSize = initialFontSize;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          insetPadding: const EdgeInsets.all(16),
          backgroundColor: const Color(0xFFFDFBF7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Text(title, style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: BoxDecoration(color: Colors.black.withOpacity(0.03), borderRadius: BorderRadius.circular(8)),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 4,
                      runSpacing: 8,
                      children: [
                        IconButton(
                          constraints: const BoxConstraints(), padding: const EdgeInsets.all(6),
                          icon: Icon(Icons.format_bold, color: bold ? const Color(0xFF0F4C5C) : Colors.black45),
                          onPressed: () => setModalState(() => bold = !bold),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(), padding: const EdgeInsets.all(6),
                          icon: Icon(Icons.format_italic, color: italic ? const Color(0xFF0F4C5C) : Colors.black45),
                          onPressed: () => setModalState(() => italic = !italic),
                        ),
                        IconButton(
                          constraints: const BoxConstraints(), padding: const EdgeInsets.all(6),
                          icon: Icon(Icons.format_underlined, color: underline ? const Color(0xFF0F4C5C) : Colors.black45),
                          onPressed: () => setModalState(() => underline = !underline),
                        ),
                        Container(height: 24, width: 1, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
                        ...[const Color(0xFF1A1A24), const Color(0xFFE74C3C), const Color(0xFF27AE60), const Color(0xFF1976D2)].map((c) {
                          final currentHex = '#${c.value.toRadixString(16).padLeft(8, '0').substring(2).toUpperCase()}';
                          final isCurrentSelected = colorHex == currentHex;
                          return GestureDetector(
                            onTap: () => setModalState(() => colorHex = currentHex),
                            child: Container(
                              margin: const EdgeInsets.symmetric(horizontal: 4),
                              padding: const EdgeInsets.all(2),
                              decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isCurrentSelected ? const Color(0xFF0F4C5C) : Colors.transparent, width: 2)),
                              child: CircleAvatar(radius: 10, backgroundColor: c),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Icon(Icons.format_size, color: Colors.black45, size: 18),
                      Expanded(
                        child: Slider(
                          value: fontSize,
                          min: 10.0,
                          max: 64.0,
                          divisions: 54,
                          activeColor: const Color(0xFF0F4C5C),
                          inactiveColor: Colors.black12,
                          onChanged: (val) => setModalState(() => fontSize = val),
                        ),
                      ),
                      SizedBox(
                          width: 36,
                          child: Text('${fontSize.toInt()}px', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54))
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: textController,
                    autofocus: true,
                    maxLines: null,
                    minLines: 4,
                    style: GoogleFonts.inter(
                      fontSize: fontSize.clamp(10.0, 28.0),
                      fontWeight: bold ? FontWeight.bold : FontWeight.normal,
                      fontStyle: italic ? FontStyle.italic : FontStyle.normal,
                      decoration: underline ? TextDecoration.underline : TextDecoration.none,
                      color: Color(int.parse(colorHex.replaceFirst('#', '0xFF'))),
                    ),
                    decoration: const InputDecoration(
                      hintText: 'Escreva as suas notas aqui...',
                      border: OutlineInputBorder(),
                      focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: Color(0xFF0F4C5C), width: 2)),
                      contentPadding: EdgeInsets.all(12),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancelar', style: TextStyle(color: Colors.black54))),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C)),
              onPressed: () {
                onSave(textController.text, bold, italic, underline, colorHex, fontSize);
                Navigator.pop(context);
              },
              child: const Text('Salvar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRGBSlider(String label, double value, Color color, ValueChanged<double> onChanged) {
    return Row(
      children: [
        SizedBox(
          width: 24,
          child: Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.black54)),
        ),
        Expanded(
          child: Slider(
            value: value,
            min: 0.0,
            max: 255.0,
            activeColor: color,
            inactiveColor: color.withOpacity(0.15),
            onChanged: onChanged,
          ),
        ),
        SizedBox(
          width: 30,
          child: Text('${value.toInt()}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54), textAlign: TextAlign.right),
        ),
      ],
    );
  }

  void _showThicknessStudioDialog() {
    double tempThickness = _selectedThickness;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => AlertDialog(
          backgroundColor: const Color(0xFFFDFBF7),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Espessura', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                height: 60,
                alignment: Alignment.center,
                child: CircleAvatar(
                  radius: tempThickness / 1.5,
                  backgroundColor: Color(int.parse(_selectedColorHex.replaceFirst('#', '0xFF'))),
                ),
              ),
              Text('${tempThickness.toInt()} px', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.black87)),
              const SizedBox(height: 20),
              Slider(
                value: tempThickness,
                min: 1.0,
                max: 50.0,
                activeColor: const Color(0xFF0F4C5C),
                inactiveColor: Colors.black12,
                onChanged: (value) => setModalState(() => tempThickness = value),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 12,
                alignment: WrapAlignment.center,
                children: _thicknessOptions.map((t) => ActionChip(
                  label: Text('${t.toInt()}'),
                  backgroundColor: tempThickness == t ? const Color(0xFF0F4C5C) : Colors.white,
                  labelStyle: TextStyle(color: tempThickness == t ? Colors.white : Colors.black87, fontSize: 12),
                  onPressed: () => setModalState(() => tempThickness = t),
                )).toList(),
              )
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF0F4C5C)),
              onPressed: () {
                setState(() => _selectedThickness = tempThickness);
                Navigator.pop(context);
              },
              child: const Text('Aplicar', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  // 🚀 O MOTOR DA BORRACHA VETORIAL
  void _eraseAtPosition(Offset pos, LocalPage page) {
    const double eraserRadius = 20.0; // O raio de alcance da borracha
    List<Stroke> strokesToRemove = [];

    // Procura todos os traços onde pelo menos um ponto cruzou o raio da borracha
    for (var stroke in page.strokes) {
      for (var point in stroke.points) {
        if ((point - pos).distance < eraserRadius) {
          strokesToRemove.add(stroke);
          break; // Mal deteta o toque, marca a linha toda para morrer
        }
      }
    }

    // Se encontrou traços, remove do ecrã e do SQLite
    if (strokesToRemove.isNotEmpty) {
      setState(() {
        for (var stroke in strokesToRemove) {
          page.strokes.remove(stroke);
          // Garante que o apagão sobrevive ao fechar a app
          if (page.id != null) {
            _repository.deleteSingleStroke(page.id!, stroke.id);
          }
        }
      });
    }
  }

  // 🚀 MÉTODO REFATORADO: Importa a imagem com dimensões base e grava no SQLite
  Future<void> _pickAndInsertImage(LocalPage page) async {
    final ImagePicker picker = ImagePicker();

    // Abre a galeria nativa
    final XFile? pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85, // Comprime para não estourar a RAM do telemóvel
    );

    if (pickedFile != null) {
      final File imageFile = File(pickedFile.path);

      // 🚀 ATUALIZADO: Criamos o bloco com a nova estrutura de largura e altura
      final newImageBlock = ImageBlock(
        id: const Uuid().v4(), // ID único String
        imageFile: imageFile,
        position: const Offset(100, 150),
        width: 300.0,
        height: 200.0,
      );

      setState(() {
        page.imageBlocks.add(newImageBlock);
        _currentTool = ToolMode.imageEdit; //
      });

      // 🚀 CIMENTAÇÃO IMEDIATA: Grava a nova imagem diretamente no teu SQLite v3
      if (page.id != null) {
        await _repository.saveSingleImageBlock(page.id!, newImageBlock);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Imagem inserida e guardada na base de dados!'),
              backgroundColor: Color(0xFF0F4C5C)
          ),
        );
      }
    }
  }

  void _undo() {
    if (_pages.isEmpty) return;
    final currentPage = _pages[_currentPageIndex];
    if (currentPage.strokes.isNotEmpty) {
      setState(() {
        currentPage.redoHistory.add(currentPage.strokes.removeLast());
      });
      // Na versão final, podes querer atualizar o status "is_deleted" no SQLite
    }
  }

  void _redo() {
    if (_pages.isEmpty) return;
    final currentPage = _pages[_currentPageIndex];
    if (currentPage.redoHistory.isNotEmpty) {
      final strokeToRestore = currentPage.redoHistory.removeLast();
      setState(() {
        currentPage.strokes.add(strokeToRestore);
      });
      // Re-gravar o traço no SQLite se necessário
      if (currentPage.id != null) {
        _repository.saveSingleStroke(currentPage.id!, strokeToRestore);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // 🚀 Ecrã de carregamento Polido e Imersivo
    if (_isLoading) {
      return Scaffold(
        backgroundColor: const Color(0xFFD6D6D6),
        appBar: _buildAppBar(false),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(
                width: 56,
                height: 56,
                child: CircularProgressIndicator(color: Color(0xFF0F4C5C), strokeWidth: 4),
              ),
              const SizedBox(height: 24),
              Text(
                'A preparar as suas folhas...',
                style: GoogleFonts.lora(fontSize: 20, fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C)),
              ),
              const SizedBox(height: 8),
              Text(
                'Por favor, aguarde.',
                style: GoogleFonts.inter(fontSize: 14, color: Colors.black54),
              ),
            ],
          ),
        ),
      );
    }


    final bool hasPages = _pages.isNotEmpty;
    final LocalPage? currentPage = hasPages ? _pages[_currentPageIndex] : null;

    final Size baseSize = _paperSizes[widget.paperSize] ?? const Size(595, 842);
    final Size pageSize = (currentPage?.isLandscape ?? false)
        ? Size(baseSize.height, baseSize.width)
        : baseSize;

    return Scaffold(
      backgroundColor: const Color(0xFFD6D6D6),
      appBar: _buildAppBar(hasPages),
      body: !hasPages
          ? _buildEmptyState()
          : Stack(
        children: [
          PageView.builder(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPageIndex = index),
            itemBuilder: (context, index) {
              final page = _pages[index];
              final Size currentPageSize = page.isLandscape ? Size(baseSize.height, baseSize.width) : baseSize;

              // 🚀 O CÉREBRO DA ARENA: Se estivermos em Pan, Texto ou Edição de Imagem,
              // o vidro da caneta fica 100% permeável aos dedos!
              final bool isBackgroundBlocked = _currentTool == ToolMode.pan ||
                  _currentTool == ToolMode.text ||
                  _currentTool == ToolMode.imageEdit;

              return InteractiveViewer.builder(
                scaleEnabled: _currentTool == ToolMode.pan,
                panEnabled: _currentTool == ToolMode.pan,
                maxScale: 6.0,
                minScale: 0.1,
                transformationController: page.transformationController,
                boundaryMargin: const EdgeInsets.all(3000),
                builder: (context, viewport) {

                  // 🚀 O CÉREBRO DA ARENA: Se estivermos a editar imagens, a escrever texto ou em Pan,
                  // a antena vetorial da caneta adormece!
                  final bool isBackgroundBlocked = _currentTool == ToolMode.pan ||
                      _currentTool == ToolMode.text ||
                      _currentTool == ToolMode.imageEdit;

                  return Center(
                    child: Container(
                      width: currentPageSize.width,
                      height: currentPageSize.height,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFDFBF7),
                        borderRadius: BorderRadius.circular(2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 15, offset: const Offset(0, 8)),
                        ],
                      ),
                      child: ClipRect(
                        child: Stack(
                          clipBehavior: Clip.none,
                          children: [

                            // =============================================================
                            // 🍞 CAMADA 1: A PAUTA DO PAPEL (Fundo passivo)
                            // =============================================================
                            RepaintBoundary(
                              child: CustomPaint(
                                size: currentPageSize,
                                willChange: false,
                                painter: StaticNotebookPainter(
                                  strokes: const [], lineType: widget.lineType,
                                  selectedStrokeIds: const {}, selectionRect: null,
                                ),
                              ),
                            ),

                            // =============================================================
                            // 🥩 CAMADA 2: AS IMAGENS (Ativadas exclusivamente por ToolMode.imageEdit)
                            // =============================================================
                            ...(page.imageBlocks ?? []).map((img) {
                              final bool isImageMode = _currentTool == ToolMode.imageEdit;

                              return Positioned(
                                key: ValueKey('img_${img.id}'),
                                left: img.position.dx,
                                top: img.position.dy,
                                child: SizedBox(
                                  // 🚀 O SEGREDO DO FLUTTER: Damos +24px de "chão físico" invisível
                                  // para a direita e para baixo. Agora o HitTest abrange o botão todo!
                                  width: img.width + 24,
                                  height: img.height + 24,
                                  child: Stack(
                                    clipBehavior: Clip.none,
                                    children: [

                                      // 1. A FOTOGRAFIA REAL (amarrada estritamente ao seu tamanho X/Y)
                                      Positioned(
                                        left: 0, top: 0,
                                        width: img.width, height: img.height,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: isImageMode ? Border.all(color: const Color(0xFF0F4C5C), width: 2.0) : null,
                                          ),
                                          child: Image.file(img.imageFile, fit: BoxFit.fill),
                                        ),
                                      ),

                                      if (isImageMode) ...[
                                        // 🎯 PONTO AZUL PARA MOVER (Caixa de toque perfeita ISO: 44x44)
                                        Positioned(
                                          left: (img.width / 2) - 22,
                                          top: (img.height / 2) - 22,
                                          width: 44, height: 44,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onPanUpdate: (d) => setState(() => img.position += d.delta),
                                            onPanEnd: (d) { if (page.id != null) _repository.saveSingleImageBlock(page.id!, img); },
                                            child: const CircleAvatar(backgroundColor: Color(0xFF0F4C5C), child: Icon(Icons.open_with, size: 20, color: Colors.white)),
                                          ),
                                        ),

                                        // 📐 ALÇA LARANJA PARA REDIMENSIONAR (O Íman de Dedos!)
                                        Positioned(
                                          // O centro exato de uma caixa de 44px a começar em (-22) bate milimetricamente na quina da foto!
                                          left: img.width - 22,
                                          top: img.height - 22,
                                          width: 44, height: 44,
                                          child: GestureDetector(
                                            behavior: HitTestBehavior.opaque,
                                            onPanUpdate: (d) => setState(() {
                                              img.width = (img.width + d.delta.dx).clamp(80.0, 900.0);
                                              img.height = (img.height + d.delta.dy).clamp(80.0, 900.0);
                                            }),
                                            onPanEnd: (d) { if (page.id != null) _repository.saveSingleImageBlock(page.id!, img); },
                                            child: Center(
                                              // Desenhamos a bolinha bonita de 30px DENTRO do íman invisível de 44px
                                              child: Container(
                                                width: 30, height: 30,
                                                decoration: const BoxDecoration(color: Colors.orange, shape: BoxShape.circle),
                                                child: const Icon(Icons.open_in_full, size: 14, color: Colors.white),
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              );
                            }),

                            // =============================================================
                            // ✍️ CAMADA 3: O VIDRO VETORIAL DA CANETA
                            // =============================================================
                            Positioned.fill(
                              child: IgnorePointer(
                                // 🚀 BLINDAGEM MÁGICA: Se estás a editar a foto ou em Pan, este vidro desaparece fisicamente!
                                ignoring: _currentTool == ToolMode.imageEdit || _currentTool == ToolMode.pan,
                                child: GestureDetector(
                                  behavior: HitTestBehavior.translucent,
                                  onTapUp: !isBackgroundBlocked ? (details) {
                                    if (_editingTextBlock != null) _finishEditingText(page);

                                    if (_currentTool == ToolMode.text) {
                                      final newBlock = TextBlock(text: '', position: details.localPosition, isBold: false, isItalic: false, isUnderline: false, textColorHex: _selectedColorHex, fontSize: 18.0);
                                      setState(() { page.textBlocks.add(newBlock); _editingTextBlock = newBlock; _textController.text = ''; });
                                      _textFocusNode.requestFocus();
                                    } else if (_currentTool == ToolMode.eraser) {
                                      _eraseAtPosition(details.localPosition, page);
                                    }
                                  } : null,
                                  onPanStart: !isBackgroundBlocked ? (details) {
                                    final localPos = details.localPosition;
                                    if (_currentTool == ToolMode.draw) {
                                      _activePointsNotifier.value = [localPos]; page.undoHistory.clear(); page.redoHistory.clear();
                                    } else if (_currentTool == ToolMode.select) {
                                      bool clickedOnSelected = false;
                                      for (var id in _selectedStrokeIds) {
                                        final stroke = page.strokes.firstWhere((s) => s.id == id);
                                        for (var pt in stroke.points) { if ((pt - localPos).distance < 25.0) { clickedOnSelected = true; break; } }
                                        if (clickedOnSelected) break;
                                      }
                                      if (clickedOnSelected) { _isMovingStrokes = true; _lastPanOffset = localPos; }
                                      else { _isMovingStrokes = false; _selectionRectStart = localPos; _selectionRectEnd = localPos; setState(() => _selectedStrokeIds.clear()); }
                                    } else if (_currentTool == ToolMode.eraser) { _eraseAtPosition(localPos, page); }
                                  } : null,
                                  onPanUpdate: !isBackgroundBlocked ? (details) {
                                    final localPos = details.localPosition;
                                    if (_currentTool == ToolMode.draw) {
                                      final currentList = _activePointsNotifier.value;
                                      if (currentList.isEmpty || (localPos - currentList.last).distance > 1.5) { _activePointsNotifier.value = List.from(currentList)..add(localPos); }
                                    } else if (_currentTool == ToolMode.select) {
                                      if (_isMovingStrokes && _lastPanOffset != null) {
                                        final delta = localPos - _lastPanOffset!;
                                        setState(() {
                                          for (var id in _selectedStrokeIds) {
                                            final stroke = page.strokes.firstWhere((s) => s.id == id);
                                            for (int i = 0; i < stroke.points.length; i++) { stroke.points[i] = stroke.points[i] + delta; }
                                          }
                                        });
                                        _lastPanOffset = localPos;
                                      } else if (_selectionRectStart != null) {
                                        setState(() {
                                          _selectionRectEnd = localPos; final rect = Rect.fromPoints(_selectionRectStart!, _selectionRectEnd!); _selectedStrokeIds.clear();
                                          for (var stroke in page.strokes) { for (var pt in stroke.points) { if (rect.contains(pt)) { _selectedStrokeIds.add(stroke.id); break; } } }
                                        });
                                      }
                                    } else if (_currentTool == ToolMode.eraser) { _eraseAtPosition(localPos, page); }
                                  } : null,
                                  onPanEnd: !isBackgroundBlocked ? (details) {
                                    if (_currentTool == ToolMode.draw) {
                                      final newStroke = Stroke(color: _selectedColorHex, thickness: _selectedThickness, points: List.from(_activePointsNotifier.value));
                                      setState(() => page.strokes.add(newStroke)); _activePointsNotifier.value = [];
                                      if (page.id != null) _repository.saveSingleStroke(page.id!, newStroke);
                                    } else if (_currentTool == ToolMode.select) {
                                      setState(() { _isMovingStrokes = false; _selectionRectStart = null; _selectionRectEnd = null; _lastPanOffset = null; });
                                    }
                                  } : null,
                                  child: RepaintBoundary(
                                    child: Stack(
                                      fit: StackFit.expand,
                                      children: [
                                        CustomPaint(
                                          size: currentPageSize, isComplex: true, willChange: false,
                                          painter: StaticNotebookPainter(
                                            strokes: page.strokes, lineType: 'none', selectedStrokeIds: _selectedStrokeIds,
                                            selectionRect: _selectionRectStart != null && _selectionRectEnd != null ? Rect.fromPoints(_selectionRectStart!, _selectionRectEnd!) : null,
                                          ),
                                        ),
                                        ValueListenableBuilder<List<Offset>>(
                                          valueListenable: _activePointsNotifier,
                                          builder: (context, activePoints, child) => CustomPaint(size: currentPageSize, painter: ActiveStrokePainter(currentPoints: activePoints, currentColor: _selectedColorHex, currentThickness: _selectedThickness)),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ),

                            // =============================================================
                            // 📝 CAMADA 4: TEXTOS TECLADO
                            // =============================================================
                            ...page.textBlocks.map((tb) {
                              final isEditing = tb == _editingTextBlock;
                              return Positioned(
                                left: tb.position.dx, top: tb.position.dy,
                                child: GestureDetector(
                                  onPanUpdate: _currentTool == ToolMode.text && !isEditing ? (d) => setState(() => tb.position += d.delta) : null, // 🚀 Corrigido: Textos só movem na ferramenta Texto!
                                  onTap: _currentTool == ToolMode.text && !isEditing ? () {
                                    if (_editingTextBlock != null) _finishEditingText(page);
                                    setState(() { _editingTextBlock = tb; _textController.text = tb.text; });
                                    _textFocusNode.requestFocus();
                                  } : null,
                                  child: isEditing
                                      ? Container(width: 250, padding: const EdgeInsets.all(4), decoration: BoxDecoration(border: Border.all(color: const Color(0xFF0F4C5C).withOpacity(0.5))), child: TextField(controller: _textController, focusNode: _textFocusNode, maxLines: null, autofocus: true, style: GoogleFonts.inter(fontSize: tb.fontSize, fontWeight: tb.isBold ? FontWeight.bold : FontWeight.normal, fontStyle: tb.isItalic ? FontStyle.italic : FontStyle.normal, decoration: tb.isUnderline ? TextDecoration.underline : TextDecoration.none, color: Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF')))), decoration: const InputDecoration(isDense: true, contentPadding: EdgeInsets.zero, border: InputBorder.none, hintText: 'Escreva aqui...'), onChanged: (val) => tb.text = val))
                                      : Container(padding: const EdgeInsets.all(4), decoration: BoxDecoration(border: _currentTool == ToolMode.text ? Border.all(color: Colors.blueAccent.withOpacity(0.2)) : null), child: Text(tb.text, style: GoogleFonts.inter(fontSize: tb.fontSize, fontWeight: tb.isBold ? FontWeight.bold : FontWeight.normal, fontStyle: tb.isItalic ? FontStyle.italic : FontStyle.normal, decoration: tb.isUnderline ? TextDecoration.underline : TextDecoration.none, color: Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF')))))),
                                ),
                              );
                            }),

                            // =============================================================
                            // 📄 CAMADA 5: TÍTULO E RODAPÉ
                            // =============================================================
                            Positioned(
                              top: 30, left: 0, right: 0,
                              child: Center(child: GestureDetector(onTap: _currentTool == ToolMode.text ? () => _showTextInputDialog(initialText: page.title, title: 'Título', onSave: (v, b, i, u, c, s) { setState(() => page.title = v); if (page.id != null) _repository.updatePageMetadata(page.id!, page.title, page.footer); }) : null, child: Text(page.title.isEmpty ? (_currentTool == ToolMode.text ? 'Tocar para Título' : '') : page.title, style: GoogleFonts.lora(fontSize: 26, fontWeight: FontWeight.bold, color: const Color(0xFF1A1A24))))),
                            ),
                            Positioned(
                              bottom: 30, left: 0, right: 0,
                              child: Center(child: GestureDetector(onTap: _currentTool == ToolMode.text ? () => _showTextInputDialog(initialText: page.footer, title: 'Rodapé', onSave: (v, b, i, u, c, s) { setState(() => page.footer = v); if (page.id != null) _repository.updatePageMetadata(page.id!, page.title, page.footer); }) : null, child: Text(page.footer.isEmpty ? (_currentTool == ToolMode.text ? 'Tocar para Rodapé' : '') : page.footer, style: GoogleFonts.inter(fontSize: 12, color: Colors.black54)))),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),

          Positioned(
            bottom: 20, left: 0, right: 0,
            child: Center(child: _buildFloatingToolbar(currentPage!)),
          ),
        ],
      ),
      floatingActionButton: hasPages ? null : FloatingActionButton(
        backgroundColor: const Color(0xFF0F4C5C),
        foregroundColor: Colors.white,
        onPressed: _showAddPageDialog,
        child: const Icon(Icons.note_add),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(bool hasPages) {
    return AppBar(
      backgroundColor: Colors.white,
      elevation: 1,
      iconTheme: const IconThemeData(color: Color(0xFF1A1A24)),
      title: hasPages ? _buildAppBarDropdown() : Text(widget.notebookTitle, style: GoogleFonts.lora(color: const Color(0xFF1A1A24), fontWeight: FontWeight.bold, fontSize: 16)),
      actions: [
        if (hasPages)
          IconButton(
            icon: const Icon(Icons.save, color: Color(0xFF27AE60)),
            tooltip: 'Guardar Caderno (Bulk)',
            onPressed: () async {
              await _repository.saveFullNotebook(widget.notebookId, _pages);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Caderno sincronizado localmente!'), backgroundColor: Color(0xFF27AE60)),
                );
              }
            },
          ),
      ],
    );
  }

  Widget _buildAppBarDropdown() {
    return DropdownButtonHideUnderline(
      child: DropdownButton<int>(
        value: _currentPageIndex,
        icon: const Icon(Icons.arrow_drop_down, color: Color(0xFF1A1A24)),
        selectedItemBuilder: (BuildContext context) {
          List<Widget> selectedItems = _pages.asMap().entries.map<Widget>((entry) {
            return Container(
              alignment: Alignment.centerLeft,
              child: Text(
                '${widget.notebookTitle} - Folha ${entry.key + 1}/${_pages.length}',
                style: GoogleFonts.lora(color: const Color(0xFF1A1A24), fontWeight: FontWeight.bold, fontSize: 16),
              ),
            );
          }).toList();
          selectedItems.add(const SizedBox.shrink());
          return selectedItems;
        },
        items: [
          ..._pages.asMap().entries.map((entry) {
            return DropdownMenuItem<int>(
              value: entry.key,
              child: Text('Ir para Folha ${entry.key + 1}', style: GoogleFonts.inter(fontWeight: FontWeight.w500)),
            );
          }),
          DropdownMenuItem<int>(
            value: _pages.length,
            child: Row(
              children: [
                const Icon(Icons.add, size: 18, color: Color(0xFF0F4C5C)),
                const SizedBox(width: 8),
                Text('Nova Folha', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0F4C5C))),
              ],
            ),
          ),
        ],
        onChanged: (int? newIndex) {
          if (newIndex != null) {
            if (newIndex == _pages.length) {
              _showAddPageDialog();
            } else {
              _pageController.animateToPage(newIndex, duration: const Duration(milliseconds: 350), curve: Curves.easeInOut);
            }
          }
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.insert_page_break_outlined, size: 80, color: Colors.black.withOpacity(0.1)),
          const SizedBox(height: 16),
          Text(
            'Este caderno está vazio.\nClique no + para adicionar a primeira folha.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(color: Colors.black45, fontSize: 16),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(IconData icon, ToolMode mode, String tooltip) {
    final isActive = _currentTool == mode;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF0F4C5C).withOpacity(0.15) : Colors.transparent,
        shape: BoxShape.circle,
      ),
      child: IconButton(
        iconSize: 20,
        constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        padding: EdgeInsets.zero,
        icon: Icon(icon, color: isActive ? const Color(0xFF0F4C5C) : const Color(0xFF1A1A24)),
        onPressed: () => setState(() {
          _currentTool = mode;
          if (mode != ToolMode.select) _selectedStrokeIds.clear();
        }),
        tooltip: tooltip,
      ),
    );
  }

  Widget _buildCompactIconButton(IconData icon, VoidCallback? onPressed, String tooltip, Color color) {
    return IconButton(
      iconSize: 20,
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
      padding: EdgeInsets.zero,
      icon: Icon(icon, color: color),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  Widget _buildFloatingToolbar(LocalPage currentPage) {
    if (_editingTextBlock != null) {
      return _buildTextEditingToolbar(currentPage);
    }

    // 🚀 RADAR: Menos de 600px é Telemóvel
    final bool isSmallScreen = MediaQuery.of(context).size.width < 600;

    // 🚀 UI CONDICIONAL: A folha atual tem pelo menos 1 imagem guardada?
    final bool hasImages = currentPage.imageBlocks.isNotEmpty;

    // 🚀 REGRA CAMALEÃO: Se no telemóvel ele ativou uma ferramenta escondida, ela mostra-se!
    final bool isEraserActive = _currentTool == ToolMode.eraser;
    final bool isSelectActive = _currentTool == ToolMode.select;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(30),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.12), blurRadius: 15, offset: const Offset(0, 8)),
        ],
      ),
      child: Wrap(
        spacing: 6,
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          // 1. CANETA (Sempre visível)
          _buildToolButton(Icons.brush, ToolMode.draw, 'Caneta'),

          // 2. BORRACHA (PC: Sempre visível | Mobile: Só aparece se estiver a ser usada!)
          if (!isSmallScreen || isEraserActive)
            _buildToolButton(Icons.backspace_outlined, ToolMode.eraser, 'Borracha'),

          // 3. MOVER FOLHA / PAN (Sempre visível)
          _buildToolButton(Icons.pan_tool, ToolMode.pan, 'Mover Folha'),

          // 4. TEXTO (Sempre visível)
          _buildToolButton(Icons.text_fields, ToolMode.text, 'Texto'),

          // 5. SELECIONAR TINTA (PC: Sempre visível | Mobile: Só aparece se ativa)
          if (!isSmallScreen || isSelectActive)
            _buildToolButton(Icons.highlight_alt, ToolMode.select, 'Selecionar Tinta'),

          // 6. ADICIONAR IMAGEM (PC: Sempre visível | Mobile: Escondido no menu)
          if (!isSmallScreen)
            _buildCompactIconButton(
                Icons.add_photo_alternate_outlined,
                    () => _pickAndInsertImage(currentPage),
                'Adicionar Imagem',
                const Color(0xFF1A1A24)),

          // 7. 🚀 MOVER/EDITAR IMAGEM (Só nasce na barra se a folha tiver fotos!)
          if (hasImages)
            _buildToolButton(Icons.transform, ToolMode.imageEdit, 'Editar Imagem'),

          // 8. 🚀 DESFAZER EVIDENCIADO (No Mobile salta para a barra principal!)
          if (isSmallScreen)
            _buildCompactIconButton(
                Icons.undo,
                currentPage.strokes.isNotEmpty ? _undo : null,
                'Desfazer',
                currentPage.strokes.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.3)),

          // =================================================================
          // 9. GAVETA DE TRANSBORDO MOBILE (Onde escondemos o resto)
          // =================================================================
          if (isSmallScreen)
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert, color: Color(0xFF1A1A24)),
              tooltip: 'Mais ferramentas',
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              color: const Color(0xFFFDFBF7),
              onSelected: (value) {
                if (value == 'insert_image') _pickAndInsertImage(currentPage);
                if (value == 'eraser') setState(() => _currentTool = ToolMode.eraser);
                if (value == 'select') setState(() => _currentTool = ToolMode.select);
                if (value == 'redo' && currentPage.redoHistory.isNotEmpty) _redo();
                if (value == 'clear' && currentPage.strokes.isNotEmpty) _confirmClearPage(currentPage);
              },
              itemBuilder: (context) => [
                const PopupMenuItem(
                  value: 'insert_image',
                  child: Row(children: [Icon(Icons.add_photo_alternate_outlined, color: Color(0xFF0F4C5C)), SizedBox(width: 12), Text('Inserir Imagem')]),
                ),
                const PopupMenuItem(
                  value: 'eraser',
                  child: Row(children: [Icon(Icons.backspace_outlined, color: Color(0xFF1A1A24)), SizedBox(width: 12), Text('Borracha')]),
                ),
                const PopupMenuItem(
                  value: 'select',
                  child: Row(children: [Icon(Icons.highlight_alt, color: Color(0xFF1A1A24)), SizedBox(width: 12), Text('Selecionar Tinta')]),
                ),
                const PopupMenuDivider(),
                PopupMenuItem(
                  value: 'redo',
                  enabled: currentPage.redoHistory.isNotEmpty,
                  child: Row(children: [Icon(Icons.redo, color: currentPage.redoHistory.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey), const SizedBox(width: 12), const Text('Avançar (Redo)')]),
                ),
                PopupMenuItem(
                  value: 'clear',
                  enabled: currentPage.strokes.isNotEmpty,
                  child: Row(children: [Icon(Icons.delete_sweep, color: currentPage.strokes.isNotEmpty ? Colors.redAccent : Colors.grey), const SizedBox(width: 12), const Text('Apagar Tudo', style: TextStyle(color: Colors.redAccent))]),
                ),
              ],
            )
          else ...[
            // 🖥️ COMPORTAMENTO PC / TABLET (Mantém o painel expandido)
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildCompactIconButton(Icons.undo, currentPage.strokes.isNotEmpty ? _undo : null, 'Desfazer', currentPage.strokes.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.5)),
            _buildCompactIconButton(Icons.redo, currentPage.redoHistory.isNotEmpty ? _redo : null, 'Avançar', currentPage.redoHistory.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.5)),
            _buildCompactIconButton(Icons.delete_sweep, currentPage.strokes.isNotEmpty ? () => _confirmClearPage(currentPage) : null, 'Apagar Tudo', currentPage.strokes.isNotEmpty ? Colors.redAccent : Colors.grey.withOpacity(0.5)),
          ],

          // 10. ESTÚDIO DE CORES DA CANETA
          if (_currentTool == ToolMode.draw) ...[
            Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),
            _buildColorButton(),
            _buildThicknessButton(),
          ],
        ],
      ),
    );
  }

  // 🚀 A NOVA BARRA EXCLUSIVA PARA EDIÇÃO DE TEXTO
  Widget _buildTextEditingToolbar(LocalPage currentPage) {
    final tb = _editingTextBlock!;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBF7), // Um tom ligeiramente diferente para destacar
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFF0F4C5C).withOpacity(0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 20, offset: const Offset(0, 10))],
      ),
      child: Wrap(
        spacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          _buildCompactIconButton(Icons.format_bold, () => setState(() => tb.isBold = !tb.isBold), 'Negrito', tb.isBold ? const Color(0xFF0F4C5C) : Colors.black45),
          _buildCompactIconButton(Icons.format_italic, () => setState(() => tb.isItalic = !tb.isItalic), 'Itálico', tb.isItalic ? const Color(0xFF0F4C5C) : Colors.black45),
          _buildCompactIconButton(Icons.format_underlined, () => setState(() => tb.isUnderline = !tb.isUnderline), 'Sublinhado', tb.isUnderline ? const Color(0xFF0F4C5C) : Colors.black45),
          Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),

          // Controlo de Tamanho de Letra Inline
          _buildCompactIconButton(Icons.text_decrease, () => setState(() => tb.fontSize = (tb.fontSize - 2).clamp(10.0, 64.0)), 'Diminuir', Colors.black87),
          Text('${tb.fontSize.toInt()}', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold)),
          _buildCompactIconButton(Icons.text_increase, () => setState(() => tb.fontSize = (tb.fontSize + 2).clamp(10.0, 64.0)), 'Aumentar', Colors.black87),
          Container(width: 1, height: 24, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 4)),

          // Cores Rápidas (Para não tapar o teclado com diálogos)
          ...['#1A1A24', '#E74C3C', '#27AE60', '#1976D2'].map((hex) {
            final isSelected = tb.textColorHex == hex;
            return GestureDetector(
              onTap: () => setState(() => tb.textColorHex = hex),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 3),
                padding: const EdgeInsets.all(2),
                decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: isSelected ? const Color(0xFF0F4C5C) : Colors.transparent, width: 2)),
                child: CircleAvatar(radius: 8, backgroundColor: Color(int.parse(hex.replaceFirst('#', '0xFF')))),
              ),
            );
          }),

          const SizedBox(width: 8),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF0F4C5C),
                shape: const StadiumBorder(),
                minimumSize: const Size(50, 30),
                padding: const EdgeInsets.symmetric(horizontal: 12)
            ),
            onPressed: () => _finishEditingText(currentPage),
            child: const Text('OK', style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
          )
        ],
      ),
    );
  }

  Widget _buildColorButton() {
    return InkWell(
      onTap: _showColorStudioDialog,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: CircleAvatar(
            radius: 11,
            backgroundColor: Color(int.parse(_selectedColorHex.replaceFirst('#', '0xFF')))
        ),
      ),
    );
  }

  Widget _buildThicknessButton() {
    return InkWell(
      onTap: _showThicknessStudioDialog,
      customBorder: const CircleBorder(),
      child: Container(
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: CircleAvatar(
          radius: 11,
          backgroundColor: Colors.black12,
          child: CircleAvatar(
            radius: (_selectedThickness / 1.5).clamp(2.0, 9.0),
            backgroundColor: const Color(0xFF1A1A24),
          ),
        ),
      ),
    );
  }

  void _confirmClearPage(LocalPage page) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFFFDFBF7),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.warning_amber_rounded, color: Colors.redAccent),
            const SizedBox(width: 8),
            Text('Apagar Folha', style: GoogleFonts.lora(fontWeight: FontWeight.bold, color: Colors.redAccent, fontSize: 18)),
          ],
        ),
        content: Text(
            'Tem a certeza que deseja apagar todos os traços desta folha?\n(Poderá anular esta ação depois usando o botão Voltar).',
            style: GoogleFonts.inter(fontSize: 14)
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar', style: TextStyle(color: Colors.black54)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () {
              setState(() {
                page.undoHistory.addAll(page.strokes);
                page.strokes.clear();
                page.redoHistory.clear();
              });
              Navigator.pop(context);
            },
            child: const Text('Apagar Tudo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// 📐 MATEMÁTICA VETORIAL: Transforma pontos tremidos em curvas perfeitas
// ============================================================================
// ============================================================================
// 📐 MATEMÁTICA VETORIAL: Alta Fidelidade para Caligrafia (Preserva Esquinas)
// ============================================================================
Path _buildSmoothPath(List<Offset> points) {
  final path = Path();
  if (points.isEmpty) return path;

  path.moveTo(points.first.dx, points.first.dy);

  if (points.length == 1) {
    // Se for só um toque (ponto da letra 'i'), desenha uma bolinha redonda
    path.addOval(Rect.fromCircle(center: points.first, radius: 0.5));
    return path;
  }

  // 🚀 LIGAÇÃO DIRETA DE ALTA PRECISÃO (GPU Path)
  // Como o nosso filtro agora capta pontos a cada 1.5 pixéis, a linha fica suave
  // naturalmente, mas não corta os bicos nem os ângulos agressivos do manuscrito!
  for (int i = 1; i < points.length; i++) {
    path.lineTo(points[i].dx, points[i].dy);
  }

  return path;
}

// ============================================================================
// 🎨 PAINTER 1: ESTÁTICO (Renderiza a pauta e as notas velhas)
// ============================================================================
class StaticNotebookPainter extends CustomPainter {
  final List<Stroke> strokes;
  final String lineType;
  final Set<String> selectedStrokeIds;
  final Rect? selectionRect;

  StaticNotebookPainter({
    required this.strokes, required this.lineType,
    required this.selectedStrokeIds, required this.selectionRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // 1. DESENHO DA PAUTA COM AS MARGENS DE LUXO
    final backgroundPaint = Paint()..color = const Color(0xFF1B365D).withOpacity(0.18)..strokeWidth = 1.0;

    if (lineType == 'ruled') {
      const double leftMargin = 60.0; const double rightMargin = 20.0;
      const double topMargin = 90.0; const double bottomMargin = 60.0;

      canvas.drawLine(const Offset(leftMargin, 0), Offset(leftMargin, size.height), Paint()..color = Colors.redAccent.withOpacity(0.4)..strokeWidth = 1.5);
      for (double y = topMargin; y < size.height - bottomMargin; y += 28) {
        canvas.drawLine(Offset(leftMargin, y), Offset(size.width - rightMargin, y), backgroundPaint);
      }
    } else if (lineType == 'grid') {
      const double margin = 20.0; const double topMargin = 90.0; const double bottomMargin = 60.0; const double gridSize = 25.0;
      for (double y = topMargin; y < size.height - bottomMargin; y += gridSize) { canvas.drawLine(Offset(margin, y), Offset(size.width - margin, y), backgroundPaint); }
      for (double x = margin; x < size.width - margin; x += gridSize) { canvas.drawLine(Offset(x, topMargin), Offset(x, size.height - bottomMargin), backgroundPaint); }
    }

    // 2. DESENHO EM MASSA DOS TRAÇOS (Usando Paths super rápidos)
    for (final stroke in strokes) {
      final isSelected = selectedStrokeIds.contains(stroke.id);

      final paint = Paint()
        ..color = Color(int.parse(stroke.color.replaceFirst('#', '0xFF')))
        ..strokeWidth = stroke.thickness
        ..style = PaintingStyle.stroke // 🚀 OBRIGATÓRIO PARA PATHS
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Sombra azul de seleção
      if (isSelected && stroke.points.isNotEmpty) {
        double minX = stroke.points.first.dx, maxX = stroke.points.first.dx; double minY = stroke.points.first.dy, maxY = stroke.points.first.dy;
        for (var pt in stroke.points) {
          if (pt.dx < minX) minX = pt.dx; if (pt.dx > maxX) maxX = pt.dx;
          if (pt.dy < minY) minY = pt.dy; if (pt.dy > maxY) maxY = pt.dy;
        }
        final bounds = Rect.fromLTRB(minX - 6, minY - 6, maxX + 6, maxY + 6);
        canvas.drawRect(bounds, Paint()..color = const Color(0x220000FF)..style = PaintingStyle.fill);
        canvas.drawRect(bounds, Paint()..color = const Color(0xFF0000FF)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      }

      // 🚀 INJEÇÃO DO PATH DE ALTA PERFORMANCE (Em vez de milhares de drawLines soltas)
      canvas.drawPath(_buildSmoothPath(stroke.points), paint);
    }

    // Ferramenta de Laço/Seleção
    if (selectionRect != null) {
      canvas.drawRect(selectionRect!, Paint()..color = const Color(0x190F4C5C)..style = PaintingStyle.fill);
      canvas.drawRect(selectionRect!, Paint()..color = const Color(0xFF0F4C5C)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  // O Segredo: O ecrã de fundo SÓ precisa de ser repintado se a quantidade de traços for diferente!
  @override
  bool shouldRepaint(covariant StaticNotebookPainter oldDelegate) => strokes.length != oldDelegate.strokes.length || selectionRect != oldDelegate.selectionRect;
}

// ============================================================================
// 🚀 PAINTER 2: DINÂMICO (Só desenha o que está a nascer do teu dedo agora)
// ============================================================================
class ActiveStrokePainter extends CustomPainter {
  final List<Offset> currentPoints;
  final String currentColor;
  final double currentThickness;

  ActiveStrokePainter({required this.currentPoints, required this.currentColor, required this.currentThickness});

  @override
  void paint(Canvas canvas, Size size) {
    if (currentPoints.isEmpty) return;

    final activePaint = Paint()
      ..color = Color(int.parse(currentColor.replaceFirst('#', '0xFF')))
      ..strokeWidth = currentThickness
      ..style = PaintingStyle.stroke // 🚀 OBRIGATÓRIO PARA PATHS
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(_buildSmoothPath(currentPoints), activePaint);
  }

  // Este pinta a 60 FPS o tempo todo, mas como é super leve, o telemóvel não sofre!
  @override
  bool shouldRepaint(covariant ActiveStrokePainter oldDelegate) => true;
}