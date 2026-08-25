import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/explanation_controller.dart';
import '../models/explanation_model.dart';
import 'animators/math_animator.dart';
import 'animators/physics_animator.dart';
import 'animators/engineering_animator.dart';

class ExplanationLayer extends ConsumerStatefulWidget {
  final Size pageSize;

  const ExplanationLayer({super.key, required this.pageSize});

  @override
  ConsumerState<ExplanationLayer> createState() => _ExplanationLayerState();
}

class _ExplanationLayerState extends ConsumerState<ExplanationLayer> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(); // Ticker contínuo para o motor
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(explanationProvider);

    if (state.activeExplanations.isEmpty) {
      return const SizedBox.shrink();
    }

    return AnimatedBuilder(
      animation: _animationController,
      builder: (context, child) {
        return CustomPaint(
          size: widget.pageSize,
          painter: ExplanationPainter(
            explanations: state.activeExplanations,
            time: _animationController.value,
          ),
        );
      },
    );
  }
}

class ExplanationPainter extends CustomPainter {
  final List<ExplanationModel> explanations;
  final double time;
  final MathAnimator _mathAnimator = MathAnimator();
  final PhysicsAnimator _physicsAnimator = PhysicsAnimator();
  final EngineeringAnimator _engAnimator = EngineeringAnimator();

  ExplanationPainter({required this.explanations, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    for (final exp in explanations) {
      if (!exp.isVisible) continue;

      canvas.save();
      canvas.translate(exp.position.dx, exp.position.dy);
      canvas.scale(exp.scale);

      if (exp is MathExplanation) {
        _mathAnimator.paint(canvas, size, exp, time);
      } else if (exp is PhysicsExplanation) {
        _physicsAnimator.paint(canvas, size, exp, time);
      } else if (exp is EngineeringExplanation) {
        _engAnimator.paint(canvas, size, exp, time);
      }

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant ExplanationPainter oldDelegate) => true; // Sempre repinta enquanto o motor corre
}
