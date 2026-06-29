import 'yolo_detector.dart';

class DetectionService {
  DetectionService._();

  static final DetectionService instance = DetectionService._();

  final YoloDetector detector = YoloDetector();
  Future<void>? _loadFuture;

  Future<void> ensureLoaded() {
    return _loadFuture ??= detector.load();
  }
}
