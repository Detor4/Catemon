import 'dart:ui';

/// Kamera preview va detection overlay uchun letterbox layout.
class PreviewLayout {
  const PreviewLayout({
    required this.renderWidth,
    required this.renderHeight,
    required this.offsetX,
    required this.offsetY,
  });

  final double renderWidth;
  final double renderHeight;
  final double offsetX;
  final double offsetY;

  static PreviewLayout letterbox({
    required Size container,
    required Size content,
  }) {
    if (content.width <= 0 || content.height <= 0) {
      return PreviewLayout(
        renderWidth: container.width,
        renderHeight: container.height,
        offsetX: 0,
        offsetY: 0,
      );
    }

    final contentAspect = content.width / content.height;
    final containerAspect = container.width / container.height;

    late final double renderWidth;
    late final double renderHeight;

    if (contentAspect > containerAspect) {
      renderWidth = container.width;
      renderHeight = container.width / contentAspect;
    } else {
      renderHeight = container.height;
      renderWidth = container.height * contentAspect;
    }

    return PreviewLayout(
      renderWidth: renderWidth,
      renderHeight: renderHeight,
      offsetX: (container.width - renderWidth) / 2,
      offsetY: (container.height - renderHeight) / 2,
    );
  }
}
