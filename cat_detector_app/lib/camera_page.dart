import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';

import 'box_painter.dart';
import 'detection.dart';
import 'detection_service.dart';
import 'frame_processor.dart';
import 'gallery_page.dart';
import 'preview_layout.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';

class CameraPage extends StatefulWidget {
  const CameraPage({super.key});

  @override
  State<CameraPage> createState() => _CameraPageState();
}

class _CameraPageState extends State<CameraPage> with WidgetsBindingObserver {
  static const _requiredConfirmFrames = 2;
  static const _inferenceIntervalMs = 350;

  final _detector = DetectionService.instance.detector;
  CameraController? _controller;
  List<Detection> _confirmedDetections = const [];
  Size _frameSize = Size.zero;
  String _status = 'Model yuklanmoqda...';
  bool _isProcessing = false;
  bool _isCapturing = false;
  bool _isPickingGallery = false;
  int _confirmStreak = 0;
  DateTime? _lastInferenceAt;

  @override
  void initState() {
    super.initState();
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.immersiveSticky,
    );
    WidgetsBinding.instance.addObserver(this);
    _initialize();
  }

  @override
  void dispose() {
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    WidgetsBinding.instance.removeObserver(this);
    _stopCamera();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    if (state == AppLifecycleState.inactive) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _startCamera();
    }
  }

  Future<void> _initialize() async {
    try {
      await DetectionService.instance.ensureLoaded();
      await _startCamera();
      if (mounted) {
        setState(() => _status = 'Kameraga qarang');
      }
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Xatolik: $e');
      }
    }
  }

  Future<void> _startCamera() async {
    final cameras = await availableCameras();
    if (cameras.isEmpty) {
      setState(() => _status = 'Kamera topilmadi');
      return;
    }

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.back,
      orElse: () => cameras.first,
    );

    final controller = CameraController(
      camera,
      ResolutionPreset.high,
      enableAudio: false,
      imageFormatGroup: Platform.isAndroid
          ? ImageFormatGroup.yuv420
          : ImageFormatGroup.bgra8888,
    );

    await controller.initialize();
    if (!mounted) {
      await controller.dispose();
      return;
    }

    setState(() => _controller = controller);
    await controller.startImageStream(_onCameraImage);
  }

  Future<void> _captureCatPhoto() async {
    if (_confirmedDetections.isEmpty || _isCapturing) return;

    final controller = _controller;
    if (controller == null || !controller.value.isInitialized) return;

    setState(() => _isCapturing = true);

    try {
      if (controller.value.isStreamingImages) {
        await controller.stopImageStream();
      }

      final photo = await controller.takePicture();
      if (!mounted) return;

      final preferredDetection = _primaryDetection(_confirmedDetections);

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GalleryPage(
            pendingPhotoPath: photo.path,
            preferredDetection: preferredDetection,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Rasm olishda xatolik: $e')),
        );
        setState(() => _isCapturing = false);
        if (controller.value.isInitialized &&
            !controller.value.isStreamingImages) {
          try {
            await controller.startImageStream(_onCameraImage);
          } catch (_) {}
        }
      }
    }
  }

  Future<void> _pickFromGallery() async {
    if (_isCapturing || _isPickingGallery) return;

    final controller = _controller;
    final wasStreaming = controller?.value.isStreamingImages ?? false;

    if (wasStreaming && controller != null) {
      await controller.stopImageStream();
    }

    setState(() => _isPickingGallery = true);

    try {
      final picked = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        imageQuality: 95,
      );
      if (!mounted) return;
      if (picked == null) return;

      setState(() => _status = 'Rasm tekshirilmoqda...');

      await DetectionService.instance.ensureLoaded();

      final bytes = await picked.readAsBytes();
      final image = img.decodeImage(bytes);
      if (image == null) {
        _showGalleryResult(found: false, message: 'Rasm ochib bo\'lmadi');
        return;
      }

      final detections = await _detector.detect(image);
      if (!mounted) return;

      if (detections.isEmpty) {
        _showGalleryResult(found: false, message: 'Mushuk yo\'q');
        return;
      }

      final preferredDetection = _primaryDetection(detections);

      await Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => GalleryPage(
            pendingPhotoPath: picked.path,
            preferredDetection: preferredDetection,
          ),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingGallery = false;
          if (_confirmedDetections.isNotEmpty) {
            _status = '${_confirmedDetections.length} ta mushuk!';
          } else {
            _status = 'Qidirilmoqda...';
          }
        });
        if (wasStreaming &&
            controller != null &&
            controller.value.isInitialized &&
            !controller.value.isStreamingImages) {
          try {
            await controller.startImageStream(_onCameraImage);
          } catch (_) {}
        }
      }
    }
  }

  void _showGalleryResult({required bool found, required String message}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: found
            ? AppColors.accentTeal.withValues(alpha: 0.95)
            : AppColors.surfaceElevated,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        margin: const EdgeInsets.all(16),
        duration: const Duration(seconds: 3),
        content: Row(
          children: [
            Icon(
              found ? Icons.pets_rounded : Icons.pets_outlined,
              color: found ? Colors.white : AppColors.textSecondary,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: AppText.game(14,
                    color: found ? Colors.white : AppColors.textPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _stopCamera() async {
    final controller = _controller;
    if (controller == null) return;

    if (controller.value.isStreamingImages) {
      await controller.stopImageStream();
    }
    await controller.dispose();
    _controller = null;
  }

  void _applyDetections(List<Detection> detections, Size frameSize) {
    String nextStatus;
    List<Detection> nextDetections;
    var nextStreak = _confirmStreak;

    if (detections.isNotEmpty) {
      nextStreak++;
      if (nextStreak >= _requiredConfirmFrames) {
        nextDetections = detections;
        nextStatus = '${detections.length} ta mushuk!';
      } else {
        nextDetections = const [];
        nextStatus = 'Aniqlanmoqda...';
      }
    } else {
      nextStreak = 0;
      nextDetections = const [];
      nextStatus = 'Qidirilmoqda...';
    }

    if (nextStatus == _status &&
        nextStreak == _confirmStreak &&
        _detectionsEqual(nextDetections, _confirmedDetections) &&
        frameSize == _frameSize) {
      return;
    }

    setState(() {
      _frameSize = frameSize;
      _confirmStreak = nextStreak;
      _confirmedDetections = nextDetections;
      _status = nextStatus;
    });
  }

  Detection? _primaryDetection(List<Detection> detections) {
    if (detections.isEmpty) return null;
    return detections.reduce(
      (a, b) => a.confidence >= b.confidence ? a : b,
    );
  }

  bool _detectionsEqual(List<Detection> a, List<Detection> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      final left = a[i];
      final right = b[i];
      if ((left.confidence - right.confidence).abs() > 0.01 ||
          (left.left - right.left).abs() > 0.02 ||
          (left.top - right.top).abs() > 0.02) {
        return false;
      }
    }
    return true;
  }

  Future<void> _onCameraImage(CameraImage image) async {
    if (_isProcessing || !_detector.isReady) return;

    final now = DateTime.now();
    if (_lastInferenceAt != null &&
        now.difference(_lastInferenceAt!) <
            const Duration(milliseconds: _inferenceIntervalMs)) {
      return;
    }

    _isProcessing = true;
    _lastInferenceAt = now;

    try {
      final rotation = _controller?.description.sensorOrientation ?? 0;
      final frameData = frameDataFromCameraImage(image, rotation);

      final prepared = await compute(
        prepareFrameDataIsolate,
        [frameData, _detector.inputSize],
      );

      final detections = await _detector.detectFromInput(
        prepared.input,
        prepared.frameWidth,
        prepared.frameHeight,
      );

      if (!mounted) return;

      _applyDetections(
        detections,
        Size(
          prepared.frameWidth.toDouble(),
          prepared.frameHeight.toDouble(),
        ),
      );
    } catch (e) {
      if (mounted) {
        setState(() => _status = 'Aniqlash xatosi: $e');
      }
    } finally {
      _isProcessing = false;
    }
  }

  Size _previewDisplaySize(CameraController controller) {
    final previewSize = controller.value.previewSize;
    if (previewSize == null) return Size.zero;
    return Size(previewSize.height.toDouble(), previewSize.width.toDouble());
  }

  // ───────────────────────── UI ─────────────────────────

  bool get _hasCat => _confirmedDetections.isNotEmpty;

  double get _topConfidence {
    final primary = _primaryDetection(_confirmedDetections);
    return primary?.confidence ?? 0;
  }

  Widget _buildCameraView(CameraController controller) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final container = Size(constraints.maxWidth, constraints.maxHeight);
        final content = _previewDisplaySize(controller);
        final layout = PreviewLayout.letterbox(
          container: container,
          content: content,
        );

        return Stack(
          fit: StackFit.expand,
          children: [
            const ColoredBox(color: Colors.black),
            Positioned(
              left: layout.offsetX,
              top: layout.offsetY,
              width: layout.renderWidth,
              height: layout.renderHeight,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  RepaintBoundary(
                    child: ClipRect(child: CameraPreview(controller)),
                  ),
                  CustomPaint(
                    painter: DetectionBoxPainter(
                      detections: _confirmedDetections,
                      imageSize: _frameSize,
                      color: AppColors.accentTeal,
                    ),
                  ),
                  if (!_hasCat) const _ScanLine(),
                ],
              ),
            ),
            _buildTopBar(),
            _buildBottomControls(),
            if (_isPickingGallery) const _GalleryAnalyzingOverlay(),
          ],
        );
      },
    );
  }

  Widget _buildTopBar() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        height: 130,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xCC0D0D0F), Color(0x000D0D0F)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                _CircleIconButton(
                  icon: Icons.close_rounded,
                  onTap: () => Navigator.of(context).maybePop(),
                ),
                Expanded(child: Center(child: _StatusBadge(
                  status: _status,
                  hasCat: _hasCat,
                ))),
                _CircleIconButton(
                  icon: Icons.photo_library_outlined,
                  onTap: _isPickingGallery ? null : _pickFromGallery,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildBottomControls() {
    return Align(
      alignment: Alignment.bottomCenter,
      child: Container(
        height: 200,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Color(0xE60D0D0F), Color(0x000D0D0F)],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (_hasCat)
                  _ConfidenceChip(confidence: _topConfidence)
                      .animate()
                      .fadeIn(duration: 250.ms)
                      .slideY(begin: 0.4, curve: Curves.easeOut),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _GalleryPickButton(
                      busy: _isPickingGallery,
                      onTap: _pickFromGallery,
                    ),
                    const SizedBox(width: 28),
                    _CaptureButton(
                      enabled: _hasCat,
                      isCapturing: _isCapturing,
                      onPressed: _captureCatPhoto,
                    ),
                    const SizedBox(width: 28),
                    const SizedBox(width: 48, height: 48),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = _controller;

    return Scaffold(
      backgroundColor: Colors.black,
      body: controller == null || !controller.value.isInitialized
          ? Stack(
              children: [
                Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text('🐾', style: const TextStyle(fontSize: 56))
                          .animate(onPlay: (c) => c.repeat())
                          .rotate(duration: 1400.ms),
                      const SizedBox(height: 18),
                      Text(
                        _status,
                        style: AppText.body(14, color: AppColors.textSecondary),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: _CircleIconButton(
                      icon: Icons.close_rounded,
                      onTap: () => Navigator.of(context).maybePop(),
                    ),
                  ),
                ),
              ],
            )
          : _buildCameraView(controller),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.surface.withValues(alpha: 0.85),
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Icon(
            icon,
            color: onTap == null
                ? AppColors.textMuted
                : AppColors.textPrimary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status, required this.hasCat});

  final String status;
  final bool hasCat;

  @override
  Widget build(BuildContext context) {
    final color = hasCat ? AppColors.accentTeal : AppColors.textSecondary;

    final badge = Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: color.withValues(alpha: 0.6)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(hasCat ? Icons.pets : Icons.search_rounded, color: color, size: 16),
          const SizedBox(width: 8),
          Text(status, style: AppText.game(14, color: color)),
        ],
      ),
    );

    if (hasCat) {
      return badge
          .animate(key: const ValueKey('cat'))
          .scale(
            begin: const Offset(0.8, 0.8),
            end: const Offset(1, 1),
            duration: 300.ms,
            curve: Curves.elasticOut,
          );
    }
    return badge
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .fadeIn(duration: 900.ms)
        .then()
        .fade(begin: 1, end: 0.45, duration: 900.ms);
  }
}

class _ConfidenceChip extends StatelessWidget {
  const _ConfidenceChip({required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: AppColors.accentTeal.withValues(alpha: 0.5)),
      ),
      child: Text(
        '🐱 ${(confidence * 100).round()}% ishonch',
        style: AppText.game(13, color: AppColors.accentTeal),
      ),
    );
  }
}

class _ScanLine extends StatelessWidget {
  const _ScanLine();

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final h = constraints.maxHeight;
        return IgnorePointer(
          child: Align(
            alignment: Alignment.topCenter,
            child: Container(
              height: 2,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.accentTeal.withValues(alpha: 0),
                    AppColors.accentTeal.withValues(alpha: 0.7),
                    AppColors.accentTeal.withValues(alpha: 0),
                  ],
                ),
              ),
            )
                .animate(onPlay: (c) => c.repeat())
                .moveY(begin: 0, end: h, duration: 1800.ms, curve: Curves.easeInOut),
          ),
        );
      },
    );
  }
}

class _GalleryPickButton extends StatelessWidget {
  const _GalleryPickButton({
    required this.busy,
    required this.onTap,
  });

  final bool busy;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: busy ? null : onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppColors.surface.withValues(alpha: 0.85),
          border: Border.all(color: AppColors.border),
        ),
        child: busy
            ? const Padding(
                padding: EdgeInsets.all(12),
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: AppColors.accent,
                ),
              )
            : const Icon(
                Icons.photo_library_outlined,
                color: AppColors.textPrimary,
                size: 24,
              ),
      ),
    );
  }
}

class _GalleryAnalyzingOverlay extends StatelessWidget {
  const _GalleryAnalyzingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.75),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🐾', style: const TextStyle(fontSize: 48))
                .animate(onPlay: (c) => c.repeat())
                .rotate(duration: 1400.ms),
            const SizedBox(height: 16),
            Text('Rasm tekshirilmoqda...', style: AppText.heading(15)),
            const SizedBox(height: 6),
            Text('Mushuk qidirilmoqda',
                style: AppText.body(12, color: AppColors.textMuted)),
          ],
        ),
      ),
    );
  }
}

class _CaptureButton extends StatelessWidget {
  const _CaptureButton({
    required this.enabled,
    required this.isCapturing,
    required this.onPressed,
  });

  final bool enabled;
  final bool isCapturing;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Container(
        width: 64,
        height: 64,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: AppColors.textSecondary, width: 3),
        ),
        child: Center(
          child: Container(
            width: 14,
            height: 14,
            decoration: const BoxDecoration(
              color: AppColors.textMuted,
              shape: BoxShape.circle,
            ),
          ),
        ),
      );
    }

    final button = GestureDetector(
      onTap: isCapturing ? null : onPressed,
      child: Container(
        width: 72,
        height: 72,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: AppColors.tealGradient,
          boxShadow: [
            BoxShadow(
              color: AppColors.accentTeal.withValues(alpha: 0.55),
              blurRadius: 24,
            ),
          ],
          border: Border.all(color: Colors.white, width: 4),
        ),
        child: isCapturing
            ? const Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white),
              )
            : const Icon(Icons.camera_alt_rounded, color: Colors.white, size: 28),
      ),
    );

    if (isCapturing) return button;

    return button
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(1.08, 1.08),
          duration: 800.ms,
          curve: Curves.easeInOut,
        );
  }
}
