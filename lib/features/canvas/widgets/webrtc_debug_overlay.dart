import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_webrtc/flutter_webrtc.dart';
import '../../../core/network/webrtc_service.dart';

class WebRTCDebugOverlay extends ConsumerWidget {
  const WebRTCDebugOverlay({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final service = ref.watch(webrtcServiceProvider);
    final peers = service.peers;

    if (!service.hasLocalVideo && peers.isEmpty) return const SizedBox.shrink();

    return Positioned(
      bottom: 110,
      right: 16,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // Meu vídeo (Local)
          if (service.localRenderer != null && service.hasLocalVideo)
            _buildVideoBox(
              'Eu (Câmara)',
              service.localRenderer!,
              Colors.blue,
              true,
              width: 100,
              height: 130,
            ),

          const SizedBox(height: 8),

          // Vídeo dos Peers (Remoto)
          ...peers.entries.map((entry) {
            final peer = entry.value;
            if (peer.remoteRenderer == null) {
              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding: const EdgeInsets.all(4),
                color: Colors.black54,
                child: Text('A ligar a ${entry.key}...', style: const TextStyle(color: Colors.white, fontSize: 10)),
              );
            }
            return _buildVideoBox(
              '${peer.pc.iceConnectionState?.name.split('.').last ?? '...'} | ${entry.key}',
              peer.remoteRenderer!,
              Colors.green,
              false,
              width: 160,
              height: 120,
            );
          }),
        ],
      ),
    );
  }

  Widget _buildVideoBox(String label, RTCVideoRenderer renderer, Color borderColor, bool isLocal, {double width = 150, double height = 110}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.black,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor, width: 2),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.5), blurRadius: 4)],
      ),
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: RTCVideoView(
              renderer,
              objectFit: RTCVideoViewObjectFit.RTCVideoViewObjectFitCover,
              mirror: isLocal,
            ),
          ),
          Positioned(
            bottom: 4,
            left: 4,
            right: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              color: Colors.black54,
              child: Text(
                label,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
