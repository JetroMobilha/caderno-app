import '../models/canvas_enums.dart';
import 'select_tool.dart';

/// 🚀 v10.5: Ferramenta Organizadora.
/// Reutiliza a lógica de seleção, mas ignora o estado \u0027locked\u0027.
class OrganizerTool extends SelectTool {
  const OrganizerTool() : super(ToolMode.organizer);
}
