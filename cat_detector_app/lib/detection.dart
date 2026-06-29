class Detection {
  const Detection({
    required this.left,
    required this.top,
    required this.right,
    required this.bottom,
    required this.confidence,
  });

  /// Normalized coordinates relative to the analyzed frame (0..1).
  final double left;
  final double top;
  final double right;
  final double bottom;
  final double confidence;
}
