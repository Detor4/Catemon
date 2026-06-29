import 'dart:typed_data';

import 'package:camera/camera.dart';

/// Kamera kadrini isolate ga uzatish uchun yengil paket.
class FrameData {
  const FrameData({
    required this.width,
    required this.height,
    required this.rotation,
    required this.yBytes,
    required this.uBytes,
    required this.vBytes,
    required this.yRowStride,
    required this.uvRowStride,
    required this.uvPixelStride,
  });

  final int width;
  final int height;
  final int rotation;
  final Uint8List yBytes;
  final Uint8List uBytes;
  final Uint8List vBytes;
  final int yRowStride;
  final int uvRowStride;
  final int uvPixelStride;
}

class PreparedFrame {
  const PreparedFrame({
    required this.input,
    required this.frameWidth,
    required this.frameHeight,
  });

  final Float32List input;
  final int frameWidth;
  final int frameHeight;
}

FrameData frameDataFromCameraImage(CameraImage image, int rotation) {
  if (image.format.group == ImageFormatGroup.bgra8888) {
    final plane = image.planes[0];
    return FrameData(
      width: image.width,
      height: image.height,
      rotation: rotation,
      yBytes: Uint8List.fromList(plane.bytes),
      uBytes: Uint8List(0),
      vBytes: Uint8List(0),
      yRowStride: plane.bytesPerRow,
      uvRowStride: 0,
      uvPixelStride: 0,
    );
  }

  return FrameData(
    width: image.width,
    height: image.height,
    rotation: rotation,
    yBytes: Uint8List.fromList(image.planes[0].bytes),
    uBytes: Uint8List.fromList(image.planes[1].bytes),
    vBytes: Uint8List.fromList(image.planes[2].bytes),
    yRowStride: image.planes[0].bytesPerRow,
    uvRowStride: image.planes[1].bytesPerRow,
    uvPixelStride: image.planes[1].bytesPerPixel ?? 1,
  );
}

PreparedFrame prepareYuvFrame(FrameData data, int inputSize) {
  final input = Float32List(3 * inputSize * inputSize);
  final w = data.width;
  final h = data.height;

  final frameWidth =
      data.rotation == 90 || data.rotation == 270 ? h : w;
  final frameHeight =
      data.rotation == 90 || data.rotation == 270 ? w : h;

  for (int dy = 0; dy < inputSize; dy++) {
    for (int dx = 0; dx < inputSize; dx++) {
      final px = (dx + 0.5) / inputSize;
      final py = (dy + 0.5) / inputSize;

      late double sxNorm;
      late double syNorm;
      switch (data.rotation) {
        case 90:
          sxNorm = py;
          syNorm = 1.0 - px;
        case 270:
          sxNorm = 1.0 - py;
          syNorm = px;
        case 180:
          sxNorm = 1.0 - px;
          syNorm = 1.0 - py;
        default:
          sxNorm = px;
          syNorm = py;
      }

      final sx = (sxNorm * (w - 1)).clamp(0, w - 1).round();
      final sy = (syNorm * (h - 1)).clamp(0, h - 1).round();

      final yIndex = sy * data.yRowStride + sx;
      final uvIndex =
          (sy ~/ 2) * data.uvRowStride + (sx ~/ 2) * data.uvPixelStride;

      final yVal = data.yBytes[yIndex];
      final uVal = data.uBytes[uvIndex];
      final vVal = data.vBytes[uvIndex];

      final r = (yVal + 1.370705 * (vVal - 128)).clamp(0, 255);
      final g =
          (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128)).clamp(0, 255);
      final b = (yVal + 1.732446 * (uVal - 128)).clamp(0, 255);

      final offset = dy * inputSize + dx;
      input[offset] = r / 255.0;
      input[inputSize * inputSize + offset] = g / 255.0;
      input[2 * inputSize * inputSize + offset] = b / 255.0;
    }
  }

  return PreparedFrame(
    input: input,
    frameWidth: frameWidth,
    frameHeight: frameHeight,
  );
}

PreparedFrame prepareBgraFrame(
  FrameData data,
  int inputSize,
) {
  final input = Float32List(3 * inputSize * inputSize);
  final w = data.width;
  final h = data.height;
  final bytes = data.yBytes;
  final rowStride = data.yRowStride;

  final frameWidth =
      data.rotation == 90 || data.rotation == 270 ? h : w;
  final frameHeight =
      data.rotation == 90 || data.rotation == 270 ? w : h;

  for (int dy = 0; dy < inputSize; dy++) {
    for (int dx = 0; dx < inputSize; dx++) {
      final px = (dx + 0.5) / inputSize;
      final py = (dy + 0.5) / inputSize;

      late double sxNorm;
      late double syNorm;
      switch (data.rotation) {
        case 90:
          sxNorm = py;
          syNorm = 1.0 - px;
        case 270:
          sxNorm = 1.0 - py;
          syNorm = px;
        case 180:
          sxNorm = 1.0 - px;
          syNorm = 1.0 - py;
        default:
          sxNorm = px;
          syNorm = py;
      }

      final sx = (sxNorm * (w - 1)).clamp(0, w - 1).round();
      final sy = (syNorm * (h - 1)).clamp(0, h - 1).round();
      final index = sy * rowStride + sx * 4;

      final b = bytes[index];
      final g = bytes[index + 1];
      final r = bytes[index + 2];

      final offset = dy * inputSize + dx;
      input[offset] = r / 255.0;
      input[inputSize * inputSize + offset] = g / 255.0;
      input[2 * inputSize * inputSize + offset] = b / 255.0;
    }
  }

  return PreparedFrame(
    input: input,
    frameWidth: frameWidth,
    frameHeight: frameHeight,
  );
}

PreparedFrame prepareFrameData(FrameData data, int inputSize) {
  if (data.uBytes.isEmpty) {
    return prepareBgraFrame(data, inputSize);
  }
  return prepareYuvFrame(data, inputSize);
}

/// compute() uchun top-level wrapper.
PreparedFrame prepareFrameDataIsolate(List<Object?> args) {
  return prepareFrameData(args[0] as FrameData, args[1] as int);
}
