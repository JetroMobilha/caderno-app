import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:caderno_digital_app/features/canvas/providers/canvas_document_provider.dart';
import 'package:caderno_digital_app/features/canvas/providers/canvas_viewport_provider.dart';
import '../models/explanation_model.dart';
import '../controllers/explanation_controller.dart';
import 'animators/math_animator.dart';
import 'animators/physics_animator.dart';
import 'animators/engineering_animator.dart';

class SimulationStudioSheet extends ConsumerStatefulWidget {
  final Size canvasSize;

  const SimulationStudioSheet({
    super.key,
    this.canvasSize = const Size(800, 1000),
  });

  static Future<void> show(BuildContext context, {Size? canvasSize}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SimulationStudioSheet(canvasSize: canvasSize ?? const Size(800, 1000)),
    );
  }

  @override
  ConsumerState<SimulationStudioSheet> createState() => _SimulationStudioSheetState();
}

class _SimulationStudioSheetState extends ConsumerState<SimulationStudioSheet> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  
  ExplanationType _selectedCategory = ExplanationType.mathFunction;
  
  // Opções Matemática
  MathKind _selectedMathKind = MathKind.sineWave;
  double _mathFrequency = 1.0;
  double _mathAmplitude = 50.0;
  bool _mathShowAxes = true;

  // Opções Física
  PhysicsKind _selectedPhysicsKind = PhysicsKind.inclinedPlane;
  double _physicsAngle = 30.0;
  double _physicsMass = 2.0;
  double _physicsLength = 120.0;

  // Opções Engenharia
  EngineeringKind _selectedEngKind = EngineeringKind.gears;
  double _engSpeed = 1.0;
  double _engVoltage = 12.0;
  double _engResistance = 10.0;
  double _engGearRatio = 2.0;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  ExplanationModel _buildCurrentModel() {
    final Offset centerPos = Offset(widget.canvasSize.width / 2, widget.canvasSize.height / 3);

    switch (_selectedCategory) {
      case ExplanationType.mathFunction:
        return MathExplanation(
          position: centerPos,
          kind: _selectedMathKind,
          frequency: _mathFrequency,
          amplitude: _mathAmplitude,
          showAxes: _mathShowAxes,
        );
      case ExplanationType.physicsBody:
        return PhysicsExplanation(
          position: centerPos,
          kind: _selectedPhysicsKind,
          angleDegrees: _physicsAngle,
          mass: _physicsMass,
          length: _physicsLength,
        );
      case ExplanationType.engineeringMechanism:
        return EngineeringExplanation(
          position: centerPos,
          kind: _selectedEngKind,
          angularVelocity: _engSpeed,
          voltage: _engVoltage,
          resistance: _engResistance,
          gearRatio: _engGearRatio,
        );
    }
  }

  void _handleInsert() {
    final model = _buildCurrentModel();
    final viewportState = ref.read(canvasViewportProvider);
    final String? pageClientId = viewportState.currentPageClientId;

    if (pageClientId != null) {
      final docState = ref.read(canvasDocumentProvider);
      final page = docState.pages.where((p) => p.clientId == pageClientId).firstOrNull;
      if (page != null) {
        final modelWithZIndex = model.copyWith(zIndex: page.objects.length);
        ref.read(canvasDocumentProvider.notifier).addObject(page, modelWithZIndex);
      }
    } else {
      ref.read(explanationProvider.notifier).addExplanation(model);
    }

    Navigator.of(context).pop();
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ilustração animada inserida na página!'),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF0F4C5C),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentModel = _buildCurrentModel();

    return Container(
      height: MediaQuery.of(context).size.height * 0.85,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        children: [
          // Cabeçalho
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            decoration: BoxDecoration(
              border: Border(bottom: BorderSide(color: Colors.black.withOpacity(0.08))),
            ),
            child: Row(
              children: [
                const Icon(Icons.auto_awesome_motion, color: Color(0xFF0F4C5C)),
                const SizedBox(width: 12),
                const Text(
                  'Estúdio de Ilustrações Animadas',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF0F4C5C)),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),

          // Abas Principais (Matemática, Física, Engenharia)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                _buildCategoryTab(ExplanationType.mathFunction, Icons.functions_rounded, 'Matemática'),
                _buildCategoryTab(ExplanationType.physicsBody, Icons.speed_rounded, 'Física'),
                _buildCategoryTab(ExplanationType.engineeringMechanism, Icons.settings_suggest_rounded, 'Engenharia'),
              ],
            ),
          ),

          // Área Principal: Pré-visualização Animada e Painel de Parâmetros
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Pré-visualização Ao Vivo
                Expanded(
                  flex: 3,
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.black12),
                    ),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _animController,
                        builder: (context, _) {
                          return CustomPaint(
                            size: const Size(300, 240),
                            painter: _PreviewPainter(
                              model: currentModel,
                              time: _animController.value,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ),

                // 2. Controlos de Parâmetros
                Expanded(
                  flex: 2,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: _buildControlsForCategory(),
                  ),
                ),
              ],
            ),
          ),

          // Rodapé com Botão de Inserção
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.black.withOpacity(0.08))),
            ),
            child: Row(
              children: [
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _handleInsert,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F4C5C),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  icon: const Icon(Icons.add_to_photos_rounded),
                  label: const Text('Inserir na Página', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryTab(ExplanationType type, IconData icon, String label) {
    final bool isSelected = _selectedCategory == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedCategory = type),
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFF0F4C5C) : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 18, color: isSelected ? Colors.white : Colors.black54),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildControlsForCategory() {
    switch (_selectedCategory) {
      case ExplanationType.mathFunction:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tipo de Ilustração', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<MathKind>(
              value: _selectedMathKind,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: MathKind.sineWave, child: Text('Onda Senoidal / Função Sin')),
                DropdownMenuItem(value: MathKind.polynomial, child: Text('Função Polinomial / Parábola')),
                DropdownMenuItem(value: MathKind.trigCircle, child: Text('Círculo Trigonométrico')),
              ],
              onChanged: (v) => setState(() => _selectedMathKind = v!),
            ),
            const SizedBox(height: 16),
            Text('Frequência / Velocidade: ${_mathFrequency.toStringAsFixed(1)}x'),
            Slider(
              value: _mathFrequency,
              min: 0.5, max: 3.0, divisions: 10,
              activeColor: const Color(0xFF0F4C5C),
              onChanged: (v) => setState(() => _mathFrequency = v),
            ),
            if (_selectedMathKind != MathKind.trigCircle) ...[
              const SizedBox(height: 8),
              Text('Amplitude: ${_mathAmplitude.toInt()} px'),
              Slider(
                value: _mathAmplitude,
                min: 20.0, max: 80.0, divisions: 12,
                activeColor: const Color(0xFF0F4C5C),
                onChanged: (v) => setState(() => _mathAmplitude = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Exibir Eixos Cartesianos'),
                value: _mathShowAxes,
                activeColor: const Color(0xFF0F4C5C),
                onChanged: (v) => setState(() => _mathShowAxes = v),
              ),
            ],
          ],
        );

      case ExplanationType.physicsBody:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Tipo de Fenómeno Físico', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<PhysicsKind>(
              value: _selectedPhysicsKind,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: PhysicsKind.inclinedPlane, child: Text('Plano Inclinado & Forças')),
                DropdownMenuItem(value: PhysicsKind.simplePendulum, child: Text('Pêndulo Simples (MHS)')),
                DropdownMenuItem(value: PhysicsKind.massSpring, child: Text('Sistema Massa-Mola')),
              ],
              onChanged: (v) => setState(() => _selectedPhysicsKind = v!),
            ),
            const SizedBox(height: 16),
            if (_selectedPhysicsKind == PhysicsKind.inclinedPlane) ...[
              Text('Ângulo de Inclinação: ${_physicsAngle.toInt()}°'),
              Slider(
                value: _physicsAngle,
                min: 10.0, max: 60.0, divisions: 10,
                activeColor: const Color(0xFF0F4C5C),
                onChanged: (v) => setState(() => _physicsAngle = v),
              ),
            ],
            if (_selectedPhysicsKind == PhysicsKind.simplePendulum) ...[
              Text('Comprimento da Corda: ${_physicsLength.toInt()} px'),
              Slider(
                value: _physicsLength,
                min: 80.0, max: 160.0, divisions: 8,
                activeColor: const Color(0xFF0F4C5C),
                onChanged: (v) => setState(() => _physicsLength = v),
              ),
            ],
            Text('Massa do Corpo: ${_physicsMass.toStringAsFixed(1)} kg'),
            Slider(
              value: _physicsMass,
              min: 0.5, max: 10.0, divisions: 19,
              activeColor: const Color(0xFF0F4C5C),
              onChanged: (v) => setState(() => _physicsMass = v),
            ),
          ],
        );

      case ExplanationType.engineeringMechanism:
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mecanismo de Engenharia', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            const SizedBox(height: 8),
            DropdownButtonFormField<EngineeringKind>(
              value: _selectedEngKind,
              decoration: InputDecoration(
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
              items: const [
                DropdownMenuItem(value: EngineeringKind.gears, child: Text('Par de Engrenagens Acopladas')),
                DropdownMenuItem(value: EngineeringKind.dcCircuit, child: Text('Circuito Elétrico DC (Fluxo de Elétrons)')),
                DropdownMenuItem(value: EngineeringKind.trussBeam, child: Text('Viga com Cargas e Apoios')),
              ],
              onChanged: (v) => setState(() => _selectedEngKind = v!),
            ),
            const SizedBox(height: 16),
            if (_selectedEngKind == EngineeringKind.gears) ...[
              Text('Rácio de Transmissão (Ratio): ${_engGearRatio.toStringAsFixed(1)}:1'),
              Slider(
                value: _engGearRatio,
                min: 1.0, max: 3.0, divisions: 4,
                activeColor: const Color(0xFF0F4C5C),
                onChanged: (v) => setState(() => _engGearRatio = v),
              ),
              Text('Velocidade Angular: ${_engSpeed.toStringAsFixed(1)} rad/s'),
              Slider(
                value: _engSpeed,
                min: 0.5, max: 3.0, divisions: 10,
                activeColor: const Color(0xFF0F4C5C),
                onChanged: (v) => setState(() => _engSpeed = v),
              ),
            ],
            if (_selectedEngKind == EngineeringKind.dcCircuit) ...[
              Text('Tensão da Fonte: ${_engVoltage.toInt()} V'),
              Slider(
                value: _engVoltage,
                min: 3.0, max: 24.0, divisions: 7,
                activeColor: const Color(0xFF0F4C5C),
                onChanged: (v) => setState(() => _engVoltage = v),
              ),
              Text('Resistência: ${_engResistance.toInt()} Ω'),
              Slider(
                value: _engResistance,
                min: 2.0, max: 50.0, divisions: 12,
                activeColor: const Color(0xFF0F4C5C),
                onChanged: (v) => setState(() => _engResistance = v),
              ),
            ],
          ],
        );
    }
  }
}

class _PreviewPainter extends CustomPainter {
  final ExplanationModel model;
  final double time;

  final MathAnimator _mathAnimator = MathAnimator();
  final PhysicsAnimator _physicsAnimator = PhysicsAnimator();
  final EngineeringAnimator _engAnimator = EngineeringAnimator();

  _PreviewPainter({required this.model, required this.time});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.save();
    canvas.translate(size.width / 2, size.height / 2);

    if (model is MathExplanation) {
      _mathAnimator.paint(canvas, size, model, time);
    } else if (model is PhysicsExplanation) {
      _physicsAnimator.paint(canvas, size, model, time);
    } else if (model is EngineeringExplanation) {
      _engAnimator.paint(canvas, size, model, time);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _PreviewPainter oldDelegate) => true;
}
