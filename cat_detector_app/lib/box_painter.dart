import 'package:flutter/material.dart';

import 'detection.dart';
import 'theme/app_colors.dart';

/// Corner-bracket uslubidagi bounding box (to'liq to'rtburchak emas).
class DetectionBoxPainter extends CustomPainter {
  DetectionBoxPainter({
    required this.detections,
    required this.imageSize,
    this.color = AppColors.accentTeal,
  });

  final List<Detection> detections;
  final Size imageSize;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    if (detections.isEmpty || imageSize.width <= 0 || imageSize.height <= 0) {
      return;
    }

    final imageAspect = imageSize.width / imageSize.height;
    final widgetAspect = size.width / size.height;

    late final double renderWidth;
    late final double renderHeight;
    late final double offsetX;
    late final double offsetY;

    if (imageAspect > widgetAspect) {
      renderHeight = size.height;
      renderWidth = size.height * imageAspect;
      offsetX = (size.width - renderWidth) / 2;
      offsetY = 0;
    } else {
      renderWidth = size.width;
      renderHeight = size.width / imageAspect;
      offsetX = 0;
      offsetY = (size.height - renderHeight) / 2;
    }

    final bracketPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round;

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.35)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 7
      ..strokeCap = StrokeCap.round
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

    const cornerLen = 20.0;

    for (final detection in detections) {
      final rect = Rect.fromLTRB(
        offsetX + detection.left * renderWidth,
        offsetY + detection.top * renderHeight,
        offsetX + detection.right * renderWidth,
        offsetY + detection.bottom * renderHeight,
      );

      for (final paint in [glowPaint, bracketPaint]) {
        _drawCorners(canvas, rect, cornerLen, paint);
      }
    }
  }

  void _drawCorners(Canvas canvas, Rect rect, double len, Paint paint) {
    // Top-left
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(len, 0), paint);
    canvas.drawLine(rect.topLeft, rect.topLeft + Offset(0, len), paint);
    // Top-right
    canvas.drawLine(rect.topRight, rect.topRight + Offset(-len, 0), paint);
    canvas.drawLine(rect.topRight, rect.topRight + Offset(0, len), paint);
    // Bottom-left
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(len, 0), paint);
    canvas.drawLine(rect.bottomLeft, rect.bottomLeft + Offset(0, -len), paint);
    // Bottom-right
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(-len, 0), paint);
    canvas.drawLine(rect.bottomRight, rect.bottomRight + Offset(0, -len), paint);
  }

  @override
  bool shouldRepaint(covariant DetectionBoxPainter oldDelegate) {
    return oldDelegate.detections != detections ||
        oldDelegate.imageSize != imageSize ||
        oldDelegate.color != color;
  }
}
