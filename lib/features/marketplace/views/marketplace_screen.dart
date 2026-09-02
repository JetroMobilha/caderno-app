import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/theme/app_colors.dart';
import '../controllers/marketplace_controller.dart';
import '../../notebooks/models/notebook_model.dart';

class MarketplaceScreen extends ConsumerStatefulWidget {
  const MarketplaceScreen({super.key});

  @override
  ConsumerState<MarketplaceScreen> createState() => _MarketplaceScreenState();
}

class _MarketplaceScreenState extends ConsumerState<MarketplaceScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    // 💡 Deteta quando o utilizador chega perto do fim da página
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
        ref.read(marketplaceProvider.notifier).loadMore();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(marketplaceProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Loja de Cadernos 🛒', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.primary,
        elevation: 0,
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // --- BARRA DE PESQUISA ---
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Pesquisar por pasta, autor ou título...',
                    filled: true,
                    fillColor: AppColors.paper,
                    prefixIcon: const Icon(Icons.search),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        ref.read(marketplaceProvider.notifier).loadInitial();
                      },
                    ),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                  ),
                  onSubmitted: (val) => ref.read(marketplaceProvider.notifier).loadInitial(query: val),
                ),
              ),

              // --- LISTA DE CADERNOS PAGINADA (GRELHA) ---
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.notebooks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.search_off_rounded, size: 64, color: Colors.black12),
                            const SizedBox(height: 16),
                            Text('Nenhum caderno encontrado na loja.', 
                              style: GoogleFonts.inter(color: AppColors.textMuted)
                            ),
                          ],
                        ),
                      )
                    : GridView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 80),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: MediaQuery.of(context).size.width > 900 ? 4 : (MediaQuery.of(context).size.width > 600 ? 3 : 2),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.72,
                  ),
                  itemCount: state.notebooks.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.notebooks.length) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final notebook = state.notebooks[index];
                    final isFree = notebook.price == 0;
                    final Color coverColor = Color(int.tryParse(notebook.color?.replaceFirst('#', '0xFF') ?? '0xFF0F4C5C') ?? 0xFF0F4C5C);

                    return Card(
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      clipBehavior: Clip.antiAlias,
                      child: InkWell(
                        onTap: () => _handleAcquire(notebook),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 🚀 CAPA MINIATURA
                            Expanded(
                              flex: 5,
                              child: Container(
                                width: double.infinity,
                                color: coverColor.withOpacity(0.9),
                                child: Stack(
                                  children: [
                                    Positioned(left: 0, top: 0, bottom: 0, width: 10, child: Container(color: Colors.black.withOpacity(0.1))),
                                    Center(
                                      child: Icon(
                                        _getIconForTemplate(notebook.templateType), 
                                        color: Colors.white.withOpacity(0.5), 
                                        size: 40
                                      ),
                                    ),
                                    if (!isFree)
                                      Positioned(
                                        top: 8, right: 8,
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(8)),
                                          child: Text('${notebook.price.toStringAsFixed(0)} Kz', 
                                            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                            // 🚀 INFORMAÇÕES
                            Expanded(
                              flex: 4,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(notebook.title, 
                                      maxLines: 2, overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13, height: 1.2)
                                    ),
                                    const Spacer(),
                                    Text(notebook.displayAuthor, // 🚀 FIX: Usar getter inteligente
                                      maxLines: 1, overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.inter(fontSize: 10, color: AppColors.textMuted)
                                    ),
                                    const SizedBox(height: 8),
                                    SizedBox(
                                      width: double.infinity,
                                      height: 32,
                                      child: ElevatedButton(
                                        onPressed: () => _handleAcquire(notebook),
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: isFree ? AppColors.accent : AppColors.primary,
                                          foregroundColor: Colors.white,
                                          elevation: 0,
                                          padding: EdgeInsets.zero,
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                        ),
                                        child: Text(isFree ? 'GRÁTIS' : 'COMPRAR', 
                                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)
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
                    );
                  },
                ),
              ),
            ],
          ),

          // --- OVERLAY DE CARREGAMENTO (DURANTE AQUISIÇÃO) ---
          if (state.isAcquiring)
            Container(
              color: Colors.black26,
              child: Center(
                child: Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const CircularProgressIndicator(),
                        const SizedBox(height: 16),
                        Text('A preparar o teu caderno...', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  IconData _getIconForTemplate(String template) {
    switch (template) {
      case 'school': return Icons.school_outlined;
      case 'university': return Icons.account_balance_outlined;
      case 'engineering': return Icons.architecture_outlined;
      case 'laboratory': return Icons.science_outlined;
      case 'music': return Icons.music_note_outlined;
      case 'accounting': return Icons.calculate_outlined;
      case 'drawing': return Icons.palette_outlined;
      case 'diary': return Icons.auto_stories_outlined;
      case 'meeting': return Icons.groups_outlined;
      case 'project': return Icons.assignment_outlined;
      case 'planner': return Icons.calendar_today_outlined;
      case 'study': return Icons.auto_stories_rounded;
      default: return Icons.book_outlined;
    }
  }

  Future<void> _handleAcquire(Notebook notebook) async {
    if (notebook.serverId == null) return;

    final success = await ref.read(marketplaceProvider.notifier).acquireNotebook(notebook.serverId!);
    
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Caderno "${notebook.title}" adquirido! 📚✨ Verifica na tua secretária.'),
            backgroundColor: AppColors.accent,
            duration: const Duration(seconds: 4),
            action: SnackBarAction(
              label: 'VER AGORA',
              textColor: Colors.white,
              onPressed: () => Navigator.pop(context),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível adquirir o caderno. Tenta novamente.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }
}
