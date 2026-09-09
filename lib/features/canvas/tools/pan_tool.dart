import 'package:flutter/material.dart';
import '../models/local_page_model.dart';
import '../models/canvas_enums.dart';
import 'canvas_tool.dart';

class PanTool extends CanvasTool {
  const PanTool() : super(ToolMode.pan);
  @override
  void onTapDown(Offset localPos, dynamic ref, LocalPage page) {}
  @override
  void onPanStart(Offset localPos, dynamic ref, LocalPage page, [double pressure = 0.5]) {}
  @override
  void onPanUpdate(Offset localPos, Offset delta, dynamic ref, LocalPage page, [double pressure = 0.5]) {}
  @override
  void onPanEnd(dynamic ref, LocalPage page) {}
}
