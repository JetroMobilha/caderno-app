

import 'package:caderno_digital_app/features/canvas/models/canvas_action_model.dart';

import '../models/local_page_model.dart';

/// 🚀 v9.6: Gestor independente para o histórico de ações do Canvas.
/// Centraliza a lógica de Undo/Redo para simplificar o DocumentNotifier.
class UndoRedoManager {
  final List<CanvasAction> _undoStack = [];
  final List<CanvasAction> _redoStack = [];
  final int maxHistory;

  UndoRedoManager({this.maxHistory = 50});

  List<CanvasAction> get undoStack => List.unmodifiable(_undoStack);
  List<CanvasAction> get redoStack => List.unmodifiable(_redoStack);

  bool get canUndo => _undoStack.isNotEmpty;
  bool get canRedo => _redoStack.isNotEmpty;

  void addAction(CanvasAction action) {
    _undoStack.add(action);
    if (_undoStack.length > maxHistory) {
      _undoStack.removeAt(0);
    }
    _redoStack.clear();
  }

  LocalPage? undo(LocalPage page) {
    if (_undoStack.isEmpty) return null;
    final action = _undoStack.removeLast();
    final updatedPage = action.undo(page);
    _redoStack.add(action);
    return updatedPage;
  }

  LocalPage? redo(LocalPage page) {
    if (_redoStack.isEmpty) return null;
    final action = _redoStack.removeLast();
    final updatedPage = action.execute(page);
    _undoStack.add(action);
    return updatedPage;
  }

  void clear() {
    _undoStack.clear();
    _redoStack.clear();
  }
}
