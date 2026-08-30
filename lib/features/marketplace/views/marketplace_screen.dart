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

              // --- LISTA DE CADERNOS PAGINADA ---
              Expanded(
                child: state.isLoading
                    ? const Center(child: CircularProgressIndicator())
                    : state.notebooks.isEmpty
                    ? Center(child: Text('Nenhum caderno encontrado na loja.', style: GoogleFonts.inter(color: AppColors.textMuted)))
                    : ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 80),
                  itemCount: state.notebooks.length + (state.isLoadingMore ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Se chegámos ao fim da lista e está a carregar mais, mostra o indicador
                    if (index == state.notebooks.length) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }

                    final notebook = state.notebooks[index];
                    final isFree = notebook.price == 0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      color: AppColors.paper,
                      elevation: 0,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(16),
                        leading: Container(
                          width: 50,
                          height: 60,
                          decoration: BoxDecoration(
                            color: Color(int.tryParse(notebook.color?.replaceFirst('#', '0xFF') ?? '0xFF0F4C5C') ?? 0xFF0F4C5C),
                            borderRadius: BorderRadius.circular(8),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 4, offset: const Offset(0, 2))],
                          ),
                          child: const Icon(Icons.book, color: Colors.white),
                        ),
                        title: Text(notebook.title, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 4),
                            Text(notebook.authorName ?? 'Autor Anónimo', style: GoogleFonts.inter(fontSize: 12, color: AppColors.textMuted)),
                            if (notebook.description != null && notebook.description!.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(notebook.description!, maxLines: 2, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 13, color: AppColors.textDark)),
                            ],
                          ],
                        ),
                        trailing: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: isFree ? AppColors.accent : AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          onPressed: () => _handleAcquire(notebook),
                          child: Text(
                            isFree ? 'OBTER' : '${notebook.price.toStringAsFixed(0)} Kz',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
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
