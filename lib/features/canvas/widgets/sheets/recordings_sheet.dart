import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:caderno_digital_app/features/canvas/controllers/canvas_controller.dart';

class RecordingsSheet extends StatelessWidget {
  final CanvasController controller;

  const RecordingsSheet({super.key, required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.7,
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBF7),
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        children: [
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              Text(
                'Gravações da Aula',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF0F4C5C),
                ),
              ),
              const CloseButton(),
            ],
          ),
          Expanded(
            child: ListView.builder(
              itemCount: controller.lessonRecordings.length,
              itemBuilder: (context, index) {
                final rec = controller.lessonRecordings[index];
                return ListTile(
                  title: Text(rec.title),
                  trailing: IconButton(
                    icon: const Icon(Icons.play_circle),
                    onPressed: () => controller.playRecording(rec),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
