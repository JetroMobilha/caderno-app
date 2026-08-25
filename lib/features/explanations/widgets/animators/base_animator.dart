import 'package:flutter/material.dart';
import '../../models/explanation_model.dart';

abstract class BaseAnimator {
  void paint(Canvas canvas, Size size, ExplanationModel model, double time);
}
