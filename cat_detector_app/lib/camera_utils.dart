import 'package:camera/camera.dart';
import 'package:image/image.dart' as img;

img.Image? cameraImageToRgb(CameraImage image) {
  if (image.format.group == ImageFormatGroup.yuv420) {
    return _yuv420ToImage(image);
  }
  if (image.format.group == ImageFormatGroup.bgra8888) {
    return _bgra8888ToImage(image);
  }
  return null;
}

img.Image _yuv420ToImage(CameraImage image) {
  final width = image.width;
  final height = image.height;
  final yPlane = image.planes[0];
  final uPlane = image.planes[1];
  final vPlane = image.planes[2];

  final out = img.Image(width: width, height: height);
  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final yIndex = y * yPlane.bytesPerRow + x;
      final uvIndex = (y ~/ 2) * uPlane.bytesPerRow + (x ~/ 2) * uPlane.bytesPerPixel!;
      final yVal = yPlane.bytes[yIndex];
      final uVal = uPlane.bytes[uvIndex];
      final vVal = vPlane.bytes[uvIndex];

      final r = (yVal + 1.370705 * (vVal - 128)).round().clamp(0, 255);
      final g = (yVal - 0.337633 * (uVal - 128) - 0.698001 * (vVal - 128))
          .round()
          .clamp(0, 255);
      final b = (yVal + 1.732446 * (uVal - 128)).round().clamp(0, 255);
      out.setPixelRgb(x, y, r, g, b);
    }
  }
  return out;
}

img.Image _bgra8888ToImage(CameraImage image) {
  final plane = image.planes[0];
  final width = image.width;
  final height = image.height;
  final out = img.Image(width: width, height: height);

  for (int y = 0; y < height; y++) {
    for (int x = 0; x < width; x++) {
      final index = y * plane.bytesPerRow + x * 4;
      final b = plane.bytes[index];
      final g = plane.bytes[index + 1];
      final r = plane.bytes[index + 2];
      out.setPixelRgb(x, y, r, g, b);
    }
  }
  return out;
}
