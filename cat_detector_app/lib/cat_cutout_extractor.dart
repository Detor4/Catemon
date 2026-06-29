import 'dart:io';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'detection.dart';
import 'yolo_detector.dart';

class CatCutoutResult {
  const CatCutoutResult({
    required this.pngBytes,
    required this.confidence,
  });

  final Uint8List pngBytes;
  final double confidence;
}

class CatCutoutExtractor {
  const CatCutoutExtractor._();

  static Future<CatCutoutResult> extractFromFile(
    String photoPath,
    YoloDetector detector, {
    Detection? preferredTarget,
  }) async {
    final bytes = await File(photoPath).readAsBytes();
    final image = img.decodeImage(bytes);
    if (image == null) {
      throw StateError('Rasm ochib bo\'lmadi');
    }

    final meta = await detector.extractBestCatCutoutWithMeta(
      image,
      preferredTarget: preferredTarget,
    );
    if (meta == null) {
      throw StateError('Rasmda mushuk aniqlanmadi');
    }

    return CatCutoutResult(
      pngBytes: Uint8List.fromList(img.encodePng(meta.image)),
      confidence: meta.confidence,
    );
  }
}
