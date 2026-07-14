import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ImageBlock {
  final String id;
  final String imagePath; // String que aceita local, Blob (Web) e Nuvem (HTTP)
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
  // 🚀 LINGUAGEM NUVEM (JSON ASSÍNCRONO BLINDADO) - A tua genialidade aqui!
  // =========================================================================
  Future<Map<String, dynamic>> toMapAsync() async {
    String? base64Image;
    try {
      // 🛡️ SE FOR WEB E FOR UM BLOB (Ficheiro recém-carregado no Chrome)
      if (kIsWeb && imagePath.startsWith('blob:')) {
        final response = await http.get(Uri.parse(imagePath));
        base64Image = base64Encode(response.bodyBytes);
      }
      // 🛡️ SE FOR MOBILE E FOR UM FICHEIRO FÍSICO (/data/user/...)
      else if (!kIsWeb && !imagePath.startsWith('http') && File(imagePath).existsSync()) {
        final bytes = await File(imagePath).readAsBytes();
        base64Image = base64Encode(bytes);
      }
    } catch (e) {
      debugPrint('⚠️ Erro ao converter imagem para Base64: $e');
    }

    return {
      'id': id,
      'dx': position.dx,
      'dy': position.dy,
      'width': width,
      'height': height,
      'rotation': rotation,
      'image_base64': base64Image,
      'image_path': imagePath,
    };
  }

  factory ImageBlock.fromMap(Map<String, dynamic> map) {
    String path = map['image_path']?.toString() ?? '';

    // Se o Laravel enviou a foto em Base64 e estamos no Mobile, recriamos o ficheiro
    if (!kIsWeb && map['image_base64'] != null && map['image_base64'].toString().isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(map['image_base64']);
        final tempDir = Directory.systemTemp;
        File file = File('${tempDir.path}/sync_img_${map['id']}.png');
        file.writeAsBytesSync(bytes);
        path = file.path;
      } catch (e) {
        debugPrint('⚠️ Erro ao recriar imagem do Base64: $e');
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