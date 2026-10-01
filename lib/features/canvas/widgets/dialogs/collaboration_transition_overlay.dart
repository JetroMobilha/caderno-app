import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../providers/collaboration_provider.dart';

class CollaborationTransitionOverlay extends ConsumerStatefulWidget {
  const CollaborationTransitionOverlay({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (_) => const CollaborationTransitionOverlay(),
    );
  }

  @override
  ConsumerState<CollaborationTransitionOverlay> createState() => _CollaborationTransitionOverlayState();
}

class _CollaborationTransitionOverlayState extends ConsumerState<CollaborationTransitionOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _radarController;

  @override
  void initState() {
    super.initState();
    _radarController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _radarController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final collab = ref.watch(collaborationProvider);
    final int step = collab.currentSyncStepInt;
    final bool isFinished = step == 4;
    final bool isError = step == -1;

    // Se concluiu a ativação, fecha o overlay suavemente em tempo recorde
    if (isFinished) {
      final navigator = Navigator.of(context, rootNavigator: true);
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted && navigator.canPop()) {
          navigator.pop();
        }
      });
    }

    double progress = 0.1;
    if (step == 1) progress = 0.33;
    if (step == 2) progress = 0.66;
    if (step == 3) progress = 0.88;
    if (step == 4) progress = 1.0;
    if (isError) progress = 0.0;

    return BackdropFilter(
      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
      child: Dialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          padding: const EdgeInsets.all(24),
          constraints: const BoxConstraints(maxWidth: 380),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.95),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
              color: isError
                  ? Colors.redAccent.withOpacity(0.4)
                  : (isFinished ? Colors.green.withOpacity(0.4) : const Color(0xFF0F4C5C).withOpacity(0.2)),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: (isError ? Colors.redAccent : const Color(0xFF0F4C5C)).withOpacity(0.12),
                blurRadius: 24,
                spreadRadius: 4,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // 🚀 BOTÃO DE FECHAR/CANCELAR NO CANTO SUPERIOR
              Align(
                alignment: Alignment.topRight,
                child: IconButton(
                  icon: const Icon(Icons.close_rounded, color: Colors.black45, size: 22),
                  onPressed: () {
                    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  },
                ),
              ),

              // 🛰️ ANIMAÇÃO DE RADAR / ÍCONE DE ESTADO
              SizedBox(
                height: 90,
                width: 90,
                child: AnimatedBuilder(
                  animation: _radarController,
                  builder: (context, child) {
                    final double waveValue = _radarController.value;
                    return Stack(
                      alignment: Alignment.center,
                      children: [
                        if (!isError)
                          Transform.scale(
                            scale: 1.0 + (waveValue * 0.5),
                            child: Container(
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isFinished
                                    ? Colors.green.withOpacity(0.15 * (1 - waveValue))
                                    : const Color(0xFF0F4C5C).withOpacity(0.18 * (1 - waveValue)),
                              ),
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isError
                                ? Colors.redAccent
                                : (isFinished ? const Color(0xFF27AE60) : const Color(0xFF0F4C5C)),
                            boxShadow: [
                              BoxShadow(
                                color: (isError
                                        ? Colors.redAccent
                                        : (isFinished ? const Color(0xFF27AE60) : const Color(0xFF0F4C5C)))
                                    .withOpacity(0.3),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 300),
                            child: isError
                                ? const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 30, key: ValueKey('error'))
                                : (isFinished
                                    ? const Icon(Icons.check_rounded, color: Colors.white, size: 30, key: ValueKey('done'))
                                    : const Icon(Icons.wifi_tethering_rounded, color: Colors.white, size: 30, key: ValueKey('wifi'))),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 16),

              // 📜 TÍTULO E SUBTÍTULO
              Text(
                isError
                    ? 'Falha ao Ligar Modo Online'
                    : (isFinished ? 'Sessão Colaborativa Ativa! ✨' : 'A Ligar Modo Online'),
                textAlign: TextAlign.center,
                style: GoogleFonts.lora(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isError
                      ? Colors.red.shade900
                      : (isFinished ? const Color(0xFF1B5E20) : const Color(0xFF0F4C5C)),
                ),
              ),
              const SizedBox(height: 6),
              Text(
                isError
                    ? (collab.currentSyncStepMessage.isNotEmpty
                        ? collab.currentSyncStepMessage
                        : 'Ocorreu um erro ao comunicar com o servidor. Verifique a sua rede.')
                    : (isFinished
                        ? 'Tudo pronto! Edição e transmissão em tempo real ativas.'
                        : 'A preparar sincronização e ligação ao servidor Reverb...'),
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 12, color: Colors.black54),
              ),
              const SizedBox(height: 20),

              if (!isError) ...[
                // 📊 BARRA DE PROGRESSO ANIMADA
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: TweenAnimationBuilder<double>(
                    duration: const Duration(milliseconds: 400),
                    curve: Curves.easeInOut,
                    tween: Tween<double>(begin: 0, end: progress),
                    builder: (context, val, _) => LinearProgressIndicator(
                      value: val,
                      minHeight: 8,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isFinished ? const Color(0xFF27AE60) : const Color(0xFF0F4C5C),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // 📋 CHECKLIST DE ETAPAS
                _buildStepRow(
                  stepNumber: 1,
                  title: 'Sincronizar dados na nuvem',
                  currentStep: step,
                ),
                const SizedBox(height: 10),
                _buildStepRow(
                  stepNumber: 2,
                  title: 'Ligar ao servidor WebSockets',
                  currentStep: step,
                ),
                const SizedBox(height: 10),
                _buildStepRow(
                  stepNumber: 3,
                  title: 'Entrar na sala e validar permissões',
                  currentStep: step,
                ),
              ] else ...[
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: () {
                    if (mounted && Navigator.of(context, rootNavigator: true).canPop()) {
                      Navigator.of(context, rootNavigator: true).pop();
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C5C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  icon: const Icon(Icons.close_rounded, size: 18),
                  label: const Text('Fechar'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStepRow({required int stepNumber, required String title, required int currentStep}) {
    final bool isDone = currentStep > stepNumber || currentStep == 4;
    final bool isCurrent = currentStep == stepNumber;

    Widget statusWidget = Container(
      width: 20,
      height: 20,
      decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey.shade300, width: 2)),
    );

    if (isDone) {
      statusWidget = Container(
        width: 20,
        height: 20,
        decoration: const BoxDecoration(shape: BoxShape.circle, color: Color(0xFF27AE60)),
        child: const Icon(Icons.check, size: 14, color: Colors.white),
      );
    } else if (isCurrent) {
      statusWidget = const SizedBox(
        width: 18,
        height: 18,
        child: CircularProgressIndicator(strokeWidth: 2.5, color: Color(0xFF0F4C5C)),
      );
    }

    return Row(
      children: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: statusWidget,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: isCurrent || isDone ? FontWeight.bold : FontWeight.normal,
              color: isDone ? const Color(0xFF1B5E20) : (isCurrent ? Colors.black87 : Colors.grey.shade500),
            ),
          ),
        ),
      ],
    );
  }
}
