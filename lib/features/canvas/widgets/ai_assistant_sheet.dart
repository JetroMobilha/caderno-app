import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/ai_assistant_controller.dart';

class AIAssistantSheet extends ConsumerStatefulWidget {
  final int? notebookId;
  final int? pageId;

  const AIAssistantSheet({super.key, this.notebookId, this.pageId});

  @override
  ConsumerState<AIAssistantSheet> createState() => _AIAssistantSheetState();
}

class _AIAssistantSheetState extends ConsumerState<AIAssistantSheet> {
  final TextEditingController _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(aiAssistantProvider);
    final controller = ref.read(aiAssistantProvider.notifier);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Assistente SyncScribe 🧠',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF0F4C5C)),
              ),
              IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Pergunta algo sobre as tuas notas...',
              suffixIcon: IconButton(
                icon: const Icon(Icons.send, color: Color(0xFF0F4C5C)),
                onPressed: () {
                  if (_searchController.text.isNotEmpty) {
                    controller.search(_searchController.text, notebookId: widget.notebookId);
                  }
                },
              ),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              filled: true,
              fillColor: Colors.grey[50],
            ),
          ),
          const SizedBox(height: 20),
          if (state.isSearching)
            const Center(child: CircularProgressIndicator(color: Color(0xFF0F4C5C)))
          else if (state.error != null)
            Text(state.error!, style: const TextStyle(color: Colors.red))
          else if (state.searchResults.isEmpty && state.lastSummary == null)
             _buildSuggestions(controller)
          else ...[
            if (state.lastSummary != null) _buildSummaryCard(state.lastSummary!),
            if (state.searchResults.isNotEmpty) _buildSearchResults(state.searchResults),
          ],
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildSuggestions(AIAssistantController controller) {
    return Column(
      children: [
        const Text("Dicas rápidas:", style: TextStyle(fontWeight: FontWeight.w600)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          children: [
            ActionChip(
              label: const Text("Resumir Página"),
              onPressed: () {
                if (widget.pageId != null) controller.summarizePage(widget.pageId!);
              },
            ),
            ActionChip(
              label: const Text("Encontrar 'Álgebra'"),
              onPressed: () {
                _searchController.text = "Onde escrevi sobre Álgebra?";
                controller.search("Álgebra", notebookId: widget.notebookId);
              },
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildSummaryCard(String summary) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F4C5C).withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFF0F4C5C).withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Resumo IA", style: TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text(summary),
        ],
      ),
    );
  }

  Widget _buildSearchResults(List<dynamic> results) {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        itemCount: results.length,
        itemBuilder: (context, index) {
          final res = results[index];
          return ListTile(
            leading: const Icon(Icons.description_outlined),
            title: Text(res.text, maxLines: 2, overflow: TextOverflow.ellipsis),
            subtitle: Text("Página ${res.pageNumber} • Confiança: ${(res.confidence * 100).toInt()}%"),
            onTap: () {
              // Navegar para a página?
              Navigator.pop(context);
            },
          );
        },
      ),
    );
  }
}
