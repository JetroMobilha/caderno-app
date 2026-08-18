import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/network/realtime_service.dart';
import '../../canvas/views/canvas_screen.dart';
import '../../notebooks/controllers/notebooks_controller.dart';
import '../../notebooks/models/notebook_model.dart';
import '../../auth/controllers/auth_controller.dart';

class NotificationOverlay extends ConsumerStatefulWidget {
  final Widget child;
  const NotificationOverlay({super.key, required this.child});

  @override
  ConsumerState<NotificationOverlay> createState() => _NotificationOverlayState();
}

class _NotificationOverlayState extends ConsumerState<NotificationOverlay> {
  StreamSubscription? _inviteSubscription;
  StreamSubscription? _syncSubscription;

  @override
  void initState() {
    super.initState();
    _initListeners();
  }

  void _initListeners() {
    final rt = ref.read(realtimeServiceProvider);
    
    _inviteSubscription = rt.onLiveInviteReceived.listen((data) {
      if (!mounted) return;
      _showInviteNotification(data);
    });

    _syncSubscription = rt.onSyncRequestedReceived.listen((data) {
      if (!mounted) return;
      _showSyncNotification(data);
    });
  }

  @override
  void dispose() {
    _inviteSubscription?.cancel();
    _syncSubscription?.cancel();
    super.dispose();
  }

  void _showInviteNotification(Map<String, dynamic> data) {
    final String senderName = data['sender_name'] ?? 'Um colega';
    final int notebookId = data['notebook_id'];
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 10),
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF0F4C5C),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.2), blurRadius: 10, offset: const Offset(0, 4)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.podcasts, color: Colors.white, size: 28),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Convite para Aula Live! 🛰️',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 14),
                    ),
                    Text(
                      '$senderName convidou-te para estudar agora.',
                      style: GoogleFonts.inter(color: Colors.white70, fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).hideCurrentSnackBar();
                  _enterLiveSession(notebookId);
                },
                style: TextButton.styleFrom(backgroundColor: Colors.white, foregroundColor: const Color(0xFF0F4C5C)),
                child: const Text('Entrar', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _enterLiveSession(int notebookServerId) async {
    // 1. Procurar o caderno localmente pelo serverId
    final notebooks = ref.read(notebooksProvider).notebooks;
    Notebook? target;
    try {
      target = notebooks.firstWhere((n) => n.serverId == notebookServerId);
    } catch (_) {}

    if (target != null) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => CanvasScreen(notebook: target!),
        ),
      );
    } else {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Caderno não encontrado localmente. Fazendo sincronização...'), backgroundColor: Colors.orange),
      );
      // Aqui poderíamos disparar um PULL forçado se necessário
    }
  }

  void _showSyncNotification(Map<String, dynamic> data) {
    // 🚀 ALERTA DE SINCRONIZAÇÃO / NOVO CADERNO
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        duration: const Duration(seconds: 4),
        backgroundColor: Colors.transparent,
        elevation: 0,
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF27AE60),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Row(
            children: [
              const Icon(Icons.sync, color: Colors.white, size: 20),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Atualização detetada! Dados sincronizados. ✨',
                  style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, color: Colors.white70, size: 16),
                onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
