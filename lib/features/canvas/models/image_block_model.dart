import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ImageBlock {
  final String id;
  String imagePath; // Pode ser path local, Blob (Web) ou URL remota
  Offset position;
  double width;
  double height;
  double rotation;
  double baseScale = 1.0;
  double baseRotation = 0.0;

  ImageBlock({
    String? id,
    required this.imagePath,
    required this.position,
    this.width = 300.0,
    this.height = 200.0,
    this.rotation = 0.0,
  }) : id = id ?? const Uuid().v4();

  // =========================================================================
  // ⚡ MAPA LEVE: Usado para Realtime (WebSocket) e Base de Dados Local
  // =========================================================================
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'dx': position.dx,
      'dy': position.dy,
      'width': width,
      'height': height,
      'rotation': rotation,
      'image_path': imagePath,
    };
  }

  // =========================================================================
  // ☁️ MAPA COMPLETO: Usado pelo SyncService para persistência na Nuvem
  // =========================================================================
  Future<Map<String, dynamic>> toMapAsync() async {
    String? base64Image;
    
    // Se o caminho for local (não for HTTP), precisamos de enviar os bytes para a nuvem
    if (!imagePath.startsWith('http')) {
      try {
        if (kIsWeb) {
          if (imagePath.startsWith('blob:')) {
            // Na Web, usamos o pacote http para ler o conteúdo do Blob URL
            final response = await http.get(Uri.parse(imagePath));
            if (response.statusCode == 200) {
              base64Image = base64Encode(response.bodyBytes);
            }
          }
        } else {
          // No Mobile, usamos dart:io (precisamos de contornar o import se formos puristas, 
          // mas o Flutter trata isto se estiver dentro de um bloco !kIsWeb)
          final bytes = await File(imagePath).readAsBytes();
          base64Image = base64Encode(bytes);
        }
      } catch (e) {
        debugPrint('⚠️ Erro ao preparar imagem para sync: $e');
      }
    }

    final map = toMap();
    map['image_base64'] = base64Image;
    return map;
  }

  factory ImageBlock.fromMap(Map<String, dynamic> map) {
    String path = map['image_path']?.toString() ?? '';

    // Se a Nuvem enviou binário (Base64) e estamos no Mobile, salvamos localmente
    if (!kIsWeb && map['image_base64'] != null && map['image_base64'].toString().isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(map['image_base64']);
        final tempDir = Directory.systemTemp;
        final File file = File('${tempDir.path}/sync_img_${map['id']}.png');
        file.writeAsBytesSync(bytes);
        path = file.path;
      } catch (e) {
        debugPrint('⚠️ Erro ao reconstruir imagem sync: $e');
      }
    }

    return ImageBlock(
      id: map['id']?.toString() ?? const Uuid().v4(),
      imagePath: path,
      position: Offset(
        (map['dx'] as num?)?.toDouble() ?? 0.0,
        (map['dy'] as num?)?.toDouble() ?? 0.0,
      ),
      width: (map['width'] as num?)?.toDouble() ?? 300.0,
      height: (map['height'] as num?)?.toDouble() ?? 200.0,
      rotation: (map['rotation'] as num?)?.toDouble() ?? 0.0,
    );
  }
}
