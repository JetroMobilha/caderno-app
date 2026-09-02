import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../models/local_page_model.dart';
import '../../models/canvas_enums.dart';

class LiveTextEditLayer extends ConsumerWidget {
  final LocalPage page;
  final TextEditingController textController;
  final FocusNode textFocusNode;
  final VoidCallback onTitleTap;

  const LiveTextEditLayer({
    super.key,
    required this.page,
    required this.textController,
    required this.textFocusNode,
    required this.onTitleTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolState = ref.watch(canvasToolProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        // 🚀 APENAS O BLOCO SENDO EDITADO ATUALMENTE
        if (toolState.activeTextBlock != null)
          Positioned(
            left: toolState.activeTextBlock!.position.dx,
            top: toolState.activeTextBlock!.position.dy,
            child: SizedBox(
              width: 300,
              child: TextField(
                controller: textController,
                focusNode: textFocusNode,
                maxLines: null,
                autofocus: true,
                style: GoogleFonts.inter(
                  fontSize: toolState.activeTextBlock!.fontSize,
                  color: Color(int.parse(toolState.activeTextBlock!.textColorHex.replaceFirst('#', '0xFF'))),
                ),
                decoration: const InputDecoration(border: InputBorder.none),
                onChanged: (v) {
                  toolState.activeTextBlock!.text = v;
                },
              ),
            ),
          ),
        
        // Título da Página permanece editável
        Positioned(
          top: 25,
          left: 0,
          right: 0,
          child: Center(
            child: Builder(
              builder: (context) {
                final bool isEditingTitle = toolState.activeInlineTarget == InlineTarget.title;
                return isEditingTitle
                    ? SizedBox(
                        width: 400,
                        child: TextField(
                          textAlign: TextAlign.center,
                          autofocus: true,
                          controller: textController,
                          focusNode: textFocusNode,
                          style: GoogleFonts.lora(fontSize: 28, fontWeight: FontWeight.bold),
                          decoration: const InputDecoration(border: InputBorder.none),
                          onSubmitted: (v) {
                            page.title = v;
                          },
                        ),
                      )
                    : GestureDetector(
                        onTap: onTitleTap,
                        child: Text(
                          page.title.isEmpty ? 'Sem título' : page.title,
                          style: GoogleFonts.lora(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: page.title.isEmpty ? Colors.black12 : Colors.black87,
                          ),
                        ),
                      );
              },
            ),
          ),
        ),
      ],
    );
  }
}
