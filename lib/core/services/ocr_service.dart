import 'dart:async';
import 'dart:io'; // 🚀 Necessário para Platform
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_digital_ink_recognition/google_mlkit_digital_ink_recognition.dart' as ml;
import '../../features/canvas/models/stroke_model.dart' as model;

abstract class OCRService {
  Future<String> recognizeHandwriting(List<model.Stroke> strokes);
  Future<void> initializeModel();
}

class HandwritingOCRService implements OCRService {
  final ml.DigitalInkRecognizerModelManager _modelManager = ml.DigitalInkRecognizerModelManager();
  final String _languageCode = 'pt'; // Português
  
  static bool _isModelPermanentlyReady = false; 
  static bool _isCheckingModel = false; 

  bool _isModelReady = false;

  HandwritingOCRService() {
    _isModelReady = _isModelPermanentlyReady;
  }

  /// 🚀 Pré-carregar o modelo de forma ultra-segura (Lazy)
  /// Só será chamado quando houver desenhos reais e o utilizador parar de escrever.
  @override
  Future<void> initializeModel() async {
    // 🛡️ PROTEÇÃO: ML Kit Digital Ink só funciona em Android e iOS
    if (kIsWeb || (!Platform.isAndroid && !Platform.isIOS)) {
      debugPrint('ℹ️ [OCR] O motor local ML Kit não é suportado nesta plataforma.');
      return;
    }
    
    if (_isModelPermanentlyReady || _isCheckingModel) return;

    _isCheckingModel = true;
    
    try {
      debugPrint('🧠 [OCR] Verificando modelo de forma preguiçosa (Lazy Load)...');
      final isDownloaded = await _modelManager.isModelDownloaded(_languageCode);
      
      if (isDownloaded) {
        _isModelReady = true;
        _isModelPermanentlyReady = true;
        debugPrint('🧠 [OCR] Modelo Português verificado e pronto.');
      } else {
        debugPrint('⬇️ [OCR] Modelo não encontrado. Iniciando download silencioso...');
        final success = await _modelManager.downloadModel(_languageCode);
        if (success) {
          _isModelReady = true;
          _isModelPermanentlyReady = true;
          debugPrint('✅ [OCR] Download concluído.');
        }
      }
    } catch (e) {
      debugPrint('🚨 [OCR] Erro silencioso na inicialização: $e');
    } finally {
      _isCheckingModel = false;
    }
  }

  @override
  Future<String> recognizeHandwriting(List<model.Stroke> strokes) async {
    if (strokes.isEmpty || kIsWeb) return ""; 

    // Se o modelo ainda não foi verificado nesta sessão, tenta fazê-lo agora.
    if (!_isModelReady) {
      // Usamos unawaited para não travar o fluxo de quem chamou, 
      // embora o primeiro reconhecimento vá falhar (retornar "") por segurança.
      initializeModel();
      return "";
    }

    try {
      final recognizer = ml.DigitalInkRecognizer(languageCode: _languageCode);
      
      final ink = ml.Ink();
      for (var stroke in strokes) {
        final mlStroke = ml.Stroke();
        for (var point in stroke.points) {
          mlStroke.points.add(ml.StrokePoint(
            x: point.dx, 
            y: point.dy, 
            t: DateTime.now().millisecondsSinceEpoch
          ));
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
