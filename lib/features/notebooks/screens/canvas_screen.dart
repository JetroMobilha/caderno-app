import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/drawing_point_model.dart';
import '../repositories/notebook_repository.dart';


class CanvasScreen extends StatefulWidget {
  final int notebookId; // 🚀 ADICIONADO
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

// 🚀 NOVO: Máquina de Estados clara para as ferramentas principais
enum ToolMode { draw, pan, select }

class _CanvasScreenState extends State<CanvasScreen> {
  List<LocalPage> _pages = [];
  int _currentPageIndex = 0;
  List<Offset> _currentPoints = [];

  // 🚀 ATUALIZADO: A variável que controla a ferramenta ativa
  ToolMode _currentTool = ToolMode.draw;

  final Set<String> _selectedStrokeIds = {};
  Offset? _selectionRectStart;
  Offset? _selectionRectEnd;
  bool _isMovingStrokes = false;
  Offset? _lastPanOffset;

  String _selectedColorHex = '#2C3E50';
  double _selectedThickness = 3.0;


  bool _isToolbarVisible = true;
  bool _isToolbarPinned = true;

  // Controlador do motor de animação e deslize horizontal das folhas
  final PageController _pageController = PageController(initialPage: 0);

  // 📐 DIMENSÕES ISO PURAS PARA EXPORTAÇÃO MILIMÉTRICA EM PDF
  final Map<String, Size> _paperSizes = {
    'A5': const Size(420, 595),
    'A4': const Size(595, 842),
    'A3': const Size(842, 1191),
    'A2': const Size(1191, 1684),
    'A1': const Size(1684, 2384),
    'A0': const Size(2384, 3370),
  };

  // 🚀 PALETA EXPANDIDA: 15 Cores prontas para o novo Diálogo
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

  // 🚀 EXPANDIDO: Lista de Traços Suportados de 1px até 30px
  final List<double> _thicknessOptions = [1.0, 2.0, 3.0, 5.0 , 10.0, 20.0];

  @override
  void dispose() {
    _pageController.dispose();
    // Limpa os controladores de zoom de todas as páginas para evitar vazamentos de memória
    for (var page in _pages) {
      page.dispose();
    }
    super.dispose();
  }

  // Define a escala inicial ideal sem quebrar as proporções do papel
  void _resetZoomForPage(LocalPage page, String paperSize) {
    final double initialScale = paperSize == 'A0' || paperSize == 'A1' ? 0.25 : 1.4;
    page.transformationController.value = Matrix4.identity()..scale(initialScale);
  }

  // Controla o Zoom via Botão focado na página que está atualmente visível
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

  // Diálogo para escolher a orientação da nova folha
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
              onPressed: () {
                final newPage = LocalPage(isLandscape: selectedIsLandscape);
                _resetZoomForPage(newPage, widget.paperSize);

                setState(() {
                  _pages.add(newPage);
                });
                Navigator.pop(context);

                // Desliza com animação realista até à folha recém-criada
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

  // 🎨 ESTÚDIO DE CORES (Diálogo Rico com Grelha)
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
              // 1. Renderiza as 15 cores prontas do sistema
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

              // 🚀 2. O NOVO BOTÃO: Atalho para abrir a paleta livre de 16 milhões de cores
              GestureDetector(
                onTap: () {
                  Navigator.pop(context); // Fecha o diálogo das cores básicas
                  _showAdvancedColorPicker(); // Abre o misturador avançado RGB
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
                    child: Icon(Icons.colorize, size: 16, color: Color(0xFF0F4C5C)), // Ícone de conta-gotas/paleta
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 🚀 NOVO: Estúdio Avançado RGB para seleção de qualquer cor do espectro
  void _showAdvancedColorPicker() {
    // Transforma o Hex atual numa cor nativa do Flutter para extrair os canais
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
                // Círculo de pré-visualização da nova cor misturada
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

                // Canal Vermelho (Red)
                _buildRGBSlider('V', r, Colors.red, (val) => setModalState(() => r = val)),
                // Canal Verde (Green)
                _buildRGBSlider('Vd', g, Colors.green, (val) => setModalState(() => g = val)),
                // Canal Azul (Blue)
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
                  // Converte o RGB de volta para a String HEX pura que o teu motor já usa
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

  // Widget auxiliar para desenhar as linhas do misturador
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
          child: Text('${value.toInt()}', style: GoogleFonts.inter(fontSize: 12, color: Colors.black54), textAlign: Alignment.centerRight == null ? null : TextAlign.right),
        ),
      ],
    );
  }

  // 📐 ESTÚDIO DE ESPESSURA (Predefinições + Controlo Deslizante Livre)
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
              // Pré-visualização do traço em tempo real
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

              // O Slider de precisão
              Slider(
                value: tempThickness,
                min: 1.0,
                max: 50.0,
                activeColor: const Color(0xFF0F4C5C),
                inactiveColor: Colors.black12,
                onChanged: (value) => setModalState(() => tempThickness = value),
              ),
              const SizedBox(height: 10),

              // Botões rápidos de predefinição
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

  void _undo() {
    if (_pages.isEmpty) return;
    final currentPage = _pages[_currentPageIndex];
    if (currentPage.strokes.isNotEmpty) {
      setState(() {
        // Remove do ecrã e atira para o "futuro" (redo)
        currentPage.redoHistory.add(currentPage.strokes.removeLast());
      });
    }
  }

  // 🚀 NOVA: Função para Avançar linhas
  void _redo() {
    if (_pages.isEmpty) return;
    final currentPage = _pages[_currentPageIndex];
    if (currentPage.redoHistory.isNotEmpty) {
      setState(() {
        // Puxa do "futuro" de volta para o ecrã
        currentPage.strokes.add(currentPage.redoHistory.removeLast());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
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
          // 🚀 MOTOR DE RENDERIZAÇÃO DE FOLHAS ANIMADAS
          PageView.builder(
            controller: _pageController,
            // 🚀 Bloqueia o deslize de página a menos que estejamos no modo de mover a folha
            physics: _currentTool == ToolMode.pan ? const BouncingScrollPhysics() : const NeverScrollableScrollPhysics(),
            itemCount: _pages.length,
            onPageChanged: (index) => setState(() => _currentPageIndex = index),
            itemBuilder: (context, index) {
              final page = _pages[index];
              final Size currentPageSize = page.isLandscape ? Size(baseSize.height, baseSize.width) : baseSize;

              return InteractiveViewer.builder(
                // 🚀 A folha só é movível se a ferramenta Mão estiver ativa!
                scaleEnabled: _currentTool == ToolMode.pan,
                panEnabled: _currentTool == ToolMode.pan,
                maxScale: 6.0,
                minScale: 0.1,
                transformationController: page.transformationController,
                boundaryMargin: const EdgeInsets.all(3000),
                builder: (context, viewport) {
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
                      child: GestureDetector(
                        // 🚀 Se a ferramenta Mão estiver ativa, o GestureDetector é desativado (retorna null)
                        onPanStart: _currentTool != ToolMode.pan ? (details) {
                          final localPos = details.localPosition;
                          if (_currentTool == ToolMode.draw) {
                            setState(() {
                              _currentPoints = [localPos];
                              page.undoHistory.clear();
                              page.redoHistory.clear();
                            });
                          } else if (_currentTool == ToolMode.select) {
                            bool clickedOnSelected = false;
                            for (var id in _selectedStrokeIds) {
                              final stroke = page.strokes.firstWhere((s) => s.id == id);
                              for (var pt in stroke.points) {
                                if ((pt - localPos).distance < 25.0) {
                                  clickedOnSelected = true;
                                  break;
                                }
                              }
                              if (clickedOnSelected) break;
                            }

                            if (clickedOnSelected) {
                              _isMovingStrokes = true;
                              _lastPanOffset = localPos;
                            } else {
                              _isMovingStrokes = false;
                              _selectionRectStart = localPos;
                              _selectionRectEnd = localPos;
                              setState(() => _selectedStrokeIds.clear());
                            }
                          }
                        } : null,
                        onPanUpdate: _currentTool != ToolMode.pan ? (details) {
                          final localPos = details.localPosition;
                          if (_currentTool == ToolMode.draw) {
                            setState(() => _currentPoints.add(localPos));
                          } else if (_currentTool == ToolMode.select) {
                            if (_isMovingStrokes && _lastPanOffset != null) {
                              final delta = localPos - _lastPanOffset!;
                              setState(() {
                                for (var id in _selectedStrokeIds) {
                                  final stroke = page.strokes.firstWhere((s) => s.id == id);
                                  for (int i = 0; i < stroke.points.length; i++) {
                                    stroke.points[i] = stroke.points[i] + delta;
                                  }
                                }
                              });
                              _lastPanOffset = localPos;
                            } else if (_selectionRectStart != null) {
                              setState(() {
                                _selectionRectEnd = localPos;
                                final rect = Rect.fromPoints(_selectionRectStart!, _selectionRectEnd!);
                                _selectedStrokeIds.clear();
                                for (var stroke in page.strokes) {
                                  for (var pt in stroke.points) {
                                    if (rect.contains(pt)) {
                                      _selectedStrokeIds.add(stroke.id);
                                      break;
                                    }
                                  }
                                }
                              });
                            }
                          }
                        } : null,
                        onPanEnd: _currentTool != ToolMode.pan ? (details) {
                          if (_currentTool == ToolMode.draw) {
                            setState(() {
                              page.strokes.add(
                                Stroke(color: _selectedColorHex, thickness: _selectedThickness, points: List.from(_currentPoints)),
                              );
                              _currentPoints.clear();
                            });
                          } else if (_currentTool == ToolMode.select) {
                            setState(() {
                              _isMovingStrokes = false;
                              _selectionRectStart = null;
                              _selectionRectEnd = null;
                              _lastPanOffset = null;
                            });
                          }
                        } : null,
                        child: RepaintBoundary(
                          child: CustomPaint(
                            key: const Key('canvas_custom_paint'),
                            size: currentPageSize,
                            painter: NotebookPainter(
                              strokes: page.strokes,
                              currentPoints: _currentPoints,
                              currentColor: _selectedColorHex,
                              currentThickness: _selectedThickness,
                              lineType: widget.lineType,
                              selectedStrokeIds: _selectedStrokeIds,
                              selectionRect: _selectionRectStart != null && _selectionRectEnd != null
                                  ? Rect.fromPoints(_selectionRectStart!, _selectionRectEnd!)
                                  : null,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              );
            },
          ),
          Positioned(
            bottom: 20,
            left: 0,
            right: 0,
            child: Center(
              child: _buildFloatingToolbar(currentPage!),
            ),
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

  // 🛠️ MÉTODOS DE EXTRAÇÃO DE LAYOUT (Estilo de Código Flutter Limpo e Declarativo)

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
            tooltip: 'Guardar Caderno',
            onPressed: () async {
              final repo = NotebookRepository();
              await repo.saveFullNotebook(widget.notebookId, _pages);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Caderno guardado localmente!'), backgroundColor: Color(0xFF27AE60)),
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

  // 🚀 CONSTRUTOR DE BOTÕES ULTRA-COMPACTOS (Poupa muito espaço na altura)
  Widget _buildCompactIconButton(IconData icon, VoidCallback? onPressed, String tooltip, Color color) {
    return IconButton(
      iconSize: 20, // Ícone ligeiramente mais pequeno
      constraints: const BoxConstraints(minWidth: 36, minHeight: 36), // Área de toque mínima do Material Design
      padding: EdgeInsets.zero, // Remove o padding gigante padrão do Flutter
      icon: Icon(icon, color: color),
      onPressed: onPressed,
      tooltip: tooltip,
    );
  }

  Widget _buildFloatingToolbar(LocalPage currentPage) {
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
        spacing: 6,       // 🚀 Aumentei ligeiramente o espaço natural para compensar a falta da linha
        runSpacing: 4,
        crossAxisAlignment: WrapCrossAlignment.center,
        alignment: WrapAlignment.center,
        children: [
          _buildToolButton(Icons.brush, ToolMode.draw, 'Caneta'),
          _buildToolButton(Icons.highlight_alt, ToolMode.select, 'Selecionar e Mover'),
          _buildToolButton(Icons.pan_tool, ToolMode.pan, 'Mover Folha / Zoom'),

          _buildCompactIconButton(Icons.zoom_out, () => _zoom(0.8), 'Afastar', const Color(0xFF1A1A24)),
          _buildCompactIconButton(Icons.zoom_in, () => _zoom(1.2), 'Aproximar', const Color(0xFF1A1A24)),

          _buildCompactIconButton(Icons.undo, currentPage.strokes.isNotEmpty ? _undo : null, 'Desfazer', currentPage.strokes.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.5)),
          _buildCompactIconButton(Icons.redo, currentPage.redoHistory.isNotEmpty ? _redo : null, 'Avançar', currentPage.redoHistory.isNotEmpty ? const Color(0xFF1A1A24) : Colors.grey.withOpacity(0.5)),
          _buildCompactIconButton(Icons.delete_sweep, currentPage.strokes.isNotEmpty ? () => _confirmClearPage(currentPage) : null, 'Apagar Tudo', currentPage.strokes.isNotEmpty ? Colors.redAccent : Colors.grey.withOpacity(0.5)),

          if (_currentTool == ToolMode.draw) ...[
            _buildColorButton(),
            _buildThicknessButton(),
          ],
        ],
      ),
    );
  }

// 🎨 BOTÃO DE COR: Abre o estúdio de cores
  Widget _buildColorButton() {
    return InkWell(
      onTap: _showColorStudioDialog, // 🚀 Chama o diálogo
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

  // 📐 BOTÃO DE ESPESSURA: Abre o estúdio de calibração
  Widget _buildThicknessButton() {
    return InkWell(
      onTap: _showThicknessStudioDialog, // 🚀 Chama o diálogo
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
  // 🚀 REDE DE SEGURANÇA: Diálogo para confirmar a limpeza da folha
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
                // Guarda o estado atual no histórico antes de apagar, permitindo o "Desfazer"
                page.undoHistory.addAll(page.strokes);
                page.strokes.clear();
                page.redoHistory.clear();
              });
              Navigator.pop(context); // Fecha o diálogo
            },
            child: const Text('Apagar Tudo', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

class NotebookPainter extends CustomPainter {
  final List<Stroke> strokes;
  final List<Offset> currentPoints;
  final String currentColor;
  final double currentThickness;
  final String lineType;
  final Set<String> selectedStrokeIds; // 🚀 NOVO
  final Rect? selectionRect; // 🚀 NOVO

  NotebookPainter({
    required this.strokes,
    required this.currentPoints,
    required this.currentColor,
    required this.currentThickness,
    required this.lineType,
    required this.selectedStrokeIds,
    required this.selectionRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final backgroundPaint = Paint()
      ..color = const Color(0xFF1B365D).withOpacity(0.18)
      ..strokeWidth = 1.0;

    if (lineType == 'ruled') {
      for (double y = 40; y < size.height; y += 28) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), backgroundPaint);
      }
    } else if (lineType == 'grid') {
      const double gridSize = 25.0;
      for (double y = gridSize; y < size.height; y += gridSize) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), backgroundPaint);
      }
      for (double x = gridSize; x < size.width; x += gridSize) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), backgroundPaint);
      }
    }

    // Desenha todos os traços salvos
    for (final stroke in strokes) {
      final isSelected = selectedStrokeIds.contains(stroke.id);

      final paint = Paint()
        ..color = Color(int.parse(stroke.color.replaceFirst('#', '0xFF')))
        ..strokeWidth = stroke.thickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      // Se o traço estiver selecionado, desenha primeiro uma caixa azul de destaque por baixo
      if (isSelected && stroke.points.isNotEmpty) {
        double minX = stroke.points.first.dx, maxX = stroke.points.first.dx;
        double minY = stroke.points.first.dy, maxY = stroke.points.first.dy;
        for (var pt in stroke.points) {
          if (pt.dx < minX) minX = pt.dx; if (pt.dx > maxX) maxX = pt.dx;
          if (pt.dy < minY) minY = pt.dy; if (pt.dy > maxY) maxY = pt.dy;
        }
        final bounds = Rect.fromLTRB(minX - 6, minY - 6, maxX + 6, maxY + 6);
        canvas.drawRect(bounds, Paint()..color = const Color(0x220000FF)..style = PaintingStyle.fill);
        canvas.drawRect(bounds, Paint()..color = const Color(0xFF0000FF)..style = PaintingStyle.stroke..strokeWidth = 1.0);
      }

      for (int i = 0; i < stroke.points.length - 1; i++) {
         canvas.drawLine(stroke.points[i], stroke.points[i + 1], paint);
      }
    }

    // Linha atual que está a ser desenhada
    if (currentPoints.length > 1) {
      final activePaint = Paint()
        ..color = Color(int.parse(currentColor.replaceFirst('#', '0xFF')))
        ..strokeWidth = currentThickness
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      for (int i = 0; i < currentPoints.length - 1; i++) {
        canvas.drawLine(currentPoints[i], currentPoints[i + 1], activePaint);
      }
    }

    // 🚀 Desenha o retângulo semi-transparente do arrasto do Lasso de Caixa
    if (selectionRect != null) {
      canvas.drawRect(selectionRect!, Paint()..color = const Color(0x190F4C5C)..style = PaintingStyle.fill);
      canvas.drawRect(selectionRect!, Paint()..color = const Color(0xFF0F4C5C)..style = PaintingStyle.stroke..strokeWidth = 1.5);
    }
  }

  @override
  bool shouldRepaint(covariant NotebookPainter oldDelegate) => true;
}