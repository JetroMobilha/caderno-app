import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/canvas_tool_provider.dart';
import '../../models/local_page_model.dart';
import '../../models/canvas_enums.dart';

class TextLayer extends ConsumerWidget {
  final LocalPage page;
  final TextEditingController textController;
  final FocusNode textFocusNode;
  final VoidCallback onTitleTap;
  final Function(LocalPage, dynamic) onTextBlockTap;

  const TextLayer({
    super.key,
    required this.page,
    required this.textController,
    required this.textFocusNode,
    required this.onTitleTap,
    required this.onTextBlockTap,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final toolState = ref.watch(canvasToolProvider);

    return Stack(
      fit: StackFit.expand,
      children: [
        // Blocos de Texto
        ...page.textBlocks.where((t) => !t.isDeleted).map((tb) {
          final bool isEditing = toolState.activeTextBlock?.id == tb.id;
          return Positioned(
            left: tb.position.dx,
            top: tb.position.dy,
            child: GestureDetector(
              onTapDown: (_) => onTextBlockTap(page, tb),
              onPanUpdate: !isEditing
                  ? (d) {
                      tb.position += d.delta;
                    }
                  : null,
              child: isEditing
                  ? SizedBox(
                      width: 300,
                      child: TextField(
                        controller: textController,
                        focusNode: textFocusNode,
                        maxLines: null,
                        style: GoogleFonts.inter(fontSize: tb.fontSize),
                        decoration: const InputDecoration(border: InputBorder.none),
                        onChanged: (v) {
                          tb.text = v;
                        },
                      ),
                    )
                  : Text(
                      tb.text,
                      style: GoogleFonts.inter(
                        fontSize: tb.fontSize,
                        color: Color(int.parse(tb.textColorHex.replaceFirst('#', '0xFF'))),
                      ),
                    ),
            ),
          );
        }),
        // Título da Página
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
