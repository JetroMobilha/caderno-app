import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:uuid/uuid.dart';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';

class Stroke {
  final String id;
  final String color;
  final double thickness;
  final List<Offset> points;

  Stroke({
    String? id,
    required this.color,
    required this.thickness,
    required this.points,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'color': color,
      'thickness': thickness,
      'points': points.map((p) => {'dx': p.dx, 'dy': p.dy}).toList(),
    };
  }

  factory Stroke.fromMap(Map<String, dynamic> map) {
    return Stroke(
      id: map['id']?.toString(),
      color: map['color']?.toString() ?? '#1A1A24',
      thickness: (map['thickness'] as num?)?.toDouble() ?? 3.0,
      points: map['points'] != null
          ? (map['points'] as List)
          .map((p) => Offset((p['dx'] as num).toDouble(), (p['dy'] as num).toDouble()))
          .toList()
          : <Offset>[],
    );
  }

  String toJsonString() => jsonEncode(toMap());
  factory Stroke.fromJsonString(String jsonStr) => Stroke.fromMap(jsonDecode(jsonStr));
}
// 🚀 ATUALIZADO: Bloco de Texto com Suporte a Tamanho de Fonte (fontSize)
class TextBlock {
  final String id;
  String text;
  Offset position;

  bool isBold;
  bool isItalic;
  bool isUnderline;
  String textColorHex;
  double fontSize; // 🚀 NOVO CAMPO

  TextBlock({
    String? id,
    required this.text,
    required this.position,
    this.isBold = false,
    this.isItalic = false,
    this.isUnderline = false,
    this.textColorHex = '#1A1A24',
    this.fontSize = 18.0, // Tamanho padrão
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() => {
    'id': id,
    'text': text,
    'dx': position.dx,
    'dy': position.dy,
    'isBold': isBold,
    'isItalic': isItalic,
    'isUnderline': isUnderline,
    'textColorHex': textColorHex,
    'fontSize': fontSize, // 🚀 SALVA O TAMANHO
  };

  factory TextBlock.fromMap(Map<String, dynamic> map) => TextBlock(
    id: map['id']?.toString(),
    text: map['text']?.toString() ?? '',
    position: Offset(
      (map['dx'] as num?)?.toDouble() ?? 0.0,
      (map['dy'] as num?)?.toDouble() ?? 0.0,
    ),
    isBold: map['isBold'] ?? false,
    isItalic: map['isItalic'] ?? false,
    isUnderline: map['isUnderline'] ?? false,
    textColorHex: map['textColorHex']?.toString() ?? '#1A1A24',
    fontSize: (map['fontSize'] as num?)?.toDouble() ?? 18.0, // 🚀 LÊ O TAMANHO (protegido)
  );
}

// 🚀 O NOVO MODELO PARA IMAGENS INSERIDAS NA FOLHA
class ImageBlock {
  final String id;
  final File imageFile;
  Offset position;
  double width;  // 🚀 Largura real em pixéis na folha
  double height; // 🚀 Altura real em pixéis na folha
  double rotation;

  double baseScale = 1.0;
  double baseRotation = 0.0;

  ImageBlock({
    required this.id,
    required this.imageFile,
    required this.position,
    this.width = 300.0,  // Tamanho padrão inicial
    this.height = 200.0,
    this.rotation = 0.0,
  });

  // 🚀 LINGUAGEM NUVEM (JSON): Converte a foto em Base64 para viajar na rede!
  Map<String, dynamic> toMap() {
    String? base64Image;
    try {
      if (imageFile.existsSync()) {
        final bytes = imageFile.readAsBytesSync();
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
      'image_base64': base64Image, // A fotografia convertida em texto
      'image_path': imageFile.path,
    };
  }

  // 🚀 LINGUAGEM NUVEM (JSON): Recebe do Laravel e recria o ficheiro localmente
  factory ImageBlock.fromMap(Map<String, dynamic> map) {
    File file = File(map['image_path'] ?? '');

    // Se o Laravel enviou a foto em Base64, recriamos o ficheiro no disco temporário!
    if (map['image_base64'] != null && map['image_base64'].toString().isNotEmpty) {
      try {
        final Uint8List bytes = base64Decode(map['image_base64']);
        // Cria um ficheiro temporário no telemóvel para o Image.file poder ler
        final tempDir = Directory.systemTemp;
        file = File('${tempDir.path}/sync_img_${map['id']}.png');
        file.writeAsBytesSync(bytes);
      } catch (e) {
        debugPrint('⚠️ Erro ao recriar imagem do Base64: $e');
      }
    }

    return ImageBlock(
      id: map['id']?.toString() ?? '',
      imageFile: file,
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