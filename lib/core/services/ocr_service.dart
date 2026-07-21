import 'package:flutter/foundation.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart' as ml;
import '../../features/canvas/models/stroke_model.dart' as model;

abstract class OCRService {
  Future<String> recognizeHandwriting(List<model.Stroke> strokes);
}

class HandwritingOCRService implements OCRService {
  final ml.DigitalInkRecognizerModelManager _modelManager = ml.DigitalInkRecognizerModelManager();
  final String _languageCode = 'pt'; // Português

  @override
  Future<String> recognizeHandwriting(List<model.Stroke> strokes) async {
    if (strokes.isEmpty) return "";

    // 🚀 INTEGRAÇÃO REAL COM ML KIT
    if (kIsWeb) {
      debugPrint('🌐 [OCR] Reconhecimento via Web ainda não disponível localmente. Enviar para Backend...');
      return "";
    }

    try {
      final isModelDownloaded = await _modelManager.isModelDownloaded(_languageCode);
      
      if (!isModelDownloaded) {
        debugPrint('⬇️ [OCR] Descarregando modelo de Português (~20MB)...');
        // Nota: O ideal seria avisar o utilizador na UI, mas aqui fazemos em background
        final success = await _modelManager.downloadModel(_languageCode);
        if (!success) return "";
      }

      final recognizer = ml.DigitalInkRecognizer(languageCode: _languageCode);
      
      final ink = ml.Ink();
      for (var stroke in strokes) {
        final mlStroke = ml.Stroke();
        for (var point in stroke.points) {
          mlStroke.points.add(ml.StrokePoint(x: point.dx, y: point.dy, t: DateTime.now().millisecondsSinceEpoch));
        }
        ink.strokes.add(mlStroke);
      }

      final List<ml.RecognitionCandidate> candidates = await recognizer.recognize(ink);
      
      await recognizer.close();

      if (candidates.isNotEmpty) {
        final String bestMatch = candidates.first.text;
        debugPrint('🧠 [OCR] Sucesso: $bestMatch');
        return bestMatch;
      }
    } catch (e) {
      debugPrint('🚨 [OCR] Erro no reconhecimento: $e');
    }

    return "";
  }
}
