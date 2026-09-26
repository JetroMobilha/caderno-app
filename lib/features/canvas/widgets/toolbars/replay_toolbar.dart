import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/canvas_tool_provider.dart';

class ReplayToolbar extends ConsumerStatefulWidget {
  const ReplayToolbar({super.key});
  @override
  ConsumerState<ReplayToolbar> createState() => _ReplayToolbarState();
}

class _ReplayToolbarState extends ConsumerState<ReplayToolbar> {
  Timer? _timer;
  bool _isPlaying = false;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _togglePlay() {
    final notifier = ref.read(canvasToolProvider.notifier);
    if (_isPlaying) {
      _timer?.cancel();
      setState(() => _isPlaying = false);
    } else {
      double currentProgress = ref.read(canvasToolProvider).replayProgress;
      if (currentProgress >= 1.0) currentProgress = 0.0;
      
      setState(() => _isPlaying = true);
      _timer = Timer.periodic(const Duration(milliseconds: 50), (timer) {
        currentProgress += 0.005; // ~10 segundos para rever a página toda
        if (currentProgress >= 1.0) {
          currentProgress = 1.0;
          timer.cancel();
          setState(() => _isPlaying = false);
        }
        notifier.setReplayProgress(currentProgress);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(canvasToolProvider);
    final notifier = ref.read(canvasToolProvider.notifier);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            icon: Icon(_isPlaying ? Icons.pause_circle_filled_rounded : Icons.play_circle_fill_rounded),
            color: const Color(0xFF0F4C5C),
            iconSize: 28,
            onPressed: _togglePlay,
          ),
          const SizedBox(width: 4),
          const Text('Replay', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Color(0xFF0F4C5C))),
          const SizedBox(width: 8),
          SizedBox(
            width: 150,
            child: Slider(
              value: state.replayProgress,
              min: 0.0,
              max: 1.0,
              activeColor: const Color(0xFF0F4C5C),
              onChanged: (v) {
                if (_isPlaying) _togglePlay(); // Pausa ao mexer manualmente
                notifier.setReplayProgress(v);
              },
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.redAccent),
            iconSize: 20,
            onPressed: () {
              _timer?.cancel();
              notifier.setIsReplaying(false);
              notifier.setReplayProgress(1.0);
            },
            tooltip: 'Sair do Replay',
          ),
        ],
      ),
    );
  }
}
