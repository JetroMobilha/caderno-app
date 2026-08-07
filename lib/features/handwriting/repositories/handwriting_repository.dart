import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/api_service.dart';

class HandwritingRepository {
  final ApiService _apiService = ApiService();

  /// ✍️ Guardar ou atualizar um caractere da caligrafia no servidor
  Future<bool> saveCharacter({
    required String character,
    required List<List<Offset>> strokes,
  }) async {
    try {
      // 🚀 Converter os traços (List<List<Offset>>) para o formato JSON esperado pelo backend
      final List<List<Map<String, double>>> strokeData = strokes.map((stroke) {
        return stroke.map((point) => {
          'x': double.parse(point.dx.toStringAsFixed(1)),
          'y': double.parse(point.dy.toStringAsFixed(1)),
        }).toList();
      }).toList();

      final response = await _apiService.post('/handwriting/alphabet', {
        'character': character,
        'stroke_data': strokeData,
      });

      if (response.statusCode == 200 || response.statusCode == 201) {
        debugPrint('✅ [Handwriting] Caractere "$character" guardado com sucesso.');
        return true;
      } else {
        debugPrint('❌ [Handwriting] Erro ao guardar caractere: ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('🚨 [Handwriting] Exceção ao comunicar com a API: $e');
      return false;
    }
  }

  /// 📋 Obter o progresso do alfabeto do utilizador (opcional, para marcar como concluído)
  Future<List<String>> getTrainedCharacters() async {
    try {
      // Nota: Este endpoint pode não existir ainda no backend, mas fica preparado.
      final response = await _apiService.get('/handwriting/alphabet');
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => item['character'].toString()).toList();
      }
    } catch (e) {
      debugPrint('⚠️ [Handwriting] Erro ao obter caracteres treinados: $e');
    }
    return [];
  }
}

final handwritingRepositoryProvider = Provider<HandwritingRepository>((ref) {
  return HandwritingRepository();
});
