import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'app_strings.dart';
import 'cat_cutout_extractor.dart';
import 'cat_grade.dart';
import 'cat_photo_store.dart';
import 'cat_play_view.dart';
import 'detection.dart';
import 'detection_service.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/rarity_widgets.dart';

class GalleryPage extends StatefulWidget {
  const GalleryPage({
    super.key,
    this.pendingPhotoPath,
    this.preferredDetection,
  });

  final String? pendingPhotoPath;
  final Detection? preferredDetection;

  @override
  State<GalleryPage> createState() => _GalleryPageState();
}

class _GalleryPageState extends State<GalleryPage> {
  final _store = CatPhotoStore.instance;

  bool _processing = false;

  @override
  void initState() {
    super.initState();
    _store.addListener(_onStoreChanged);
    if (widget.pendingPhotoPath != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _processPendingPhoto(widget.pendingPhotoPath!);
      });
    }
  }

  @override
  void dispose() {
    _store.removeListener(_onStoreChanged);
    super.dispose();
  }

  void _onStoreChanged() {
    if (mounted) setState(() {});
  }

  // ── Logic glue (saqlash + daraja) — o'zgartirilmagan ──
  Future<void> _processPendingPhoto(String photoPath) async {
    if (_processing) return;

    setState(() => _processing = true);

    try {
      await DetectionService.instance.ensureLoaded();
      final cutout = await CatCutoutExtractor.extractFromFile(
        photoPath,
        DetectionService.instance.detector,
        preferredTarget: widget.preferredDetection,
      );

      if (!mounted) return;

      final grade = CatGrader.gradeFromBytes(
        cutout.pngBytes,
        confidence: cutout.confidence,
      );

      await _store.saveCutoutBytes(cutout.pngBytes, grade: grade);

      if (mounted) {
        _showRaritySnack(grade);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Xatolik: $e')),
        );
      }
    } finally {
      try {
        await File(photoPath).delete();
      } catch (_) {}

      if (mounted) {
        setState(() => _processing = false);
      }
    }
  }

  void _showRaritySnack(CatGrade grade) {
    final color = AppRarity.color(grade.tier.rarity);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        backgroundColor: color.withValues(alpha: 0.95),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
        ),
        margin: const EdgeInsets.all(16),
        content: Row(
          children: [
            Text(AppRarity.emoji(grade.tier.rarity),
                style: const TextStyle(fontSize: 18)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${grade.tier.rarity}  +1',
                style: AppText.game(15, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(CatPhoto photo) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(S.current.deleteCatTitle, style: AppText.heading(18)),
        content: Text(
          S.current.deleteCatBody,
          style: AppText.body(14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(S.current.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(S.current.delete,
                style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await _store.delete(photo.path);
    }
  }

  void _openPhoto(CatPhoto photo) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => CatPlayViewPage(
          path: photo.path,
          grade: photo.grade,
          heroTag: 'cat_${photo.path}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final photos = _store.photos;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('🐾 ${S.current.myCollection}', style: AppText.display(22)),
            Text(
              S.current.catsFound(photos.length),
              style: AppText.body(13, color: AppColors.textSecondary),
            ),
          ],
        ),
      ),
      body: Stack(
        children: [
          if (photos.isEmpty && !_processing)
            _EmptyState(onCamera: () => Navigator.of(context).maybePop())
          else
            GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                childAspectRatio: 0.75,
              ),
              itemCount: photos.length,
              itemBuilder: (context, index) {
                final photo = photos[index];
                return _CatCard(
                  photo: photo,
                  onTap: () => _openPhoto(photo),
                  onLongPress: () => _confirmDelete(photo),
                ).animate().fadeIn(
                      duration: 300.ms,
                      delay: (index * 40).ms,
                    ).scale(begin: const Offset(0.94, 0.94));
              },
            ),
          if (_processing) const _ProcessingOverlay(),
        ],
      ),
    );
  }
}

class _CatCard extends StatelessWidget {
  const _CatCard({
    required this.photo,
    required this.onTap,
    required this.onLongPress,
  });

  final CatPhoto photo;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  String _relativeDate() {
    final s = S.current;
    try {
      final modified = File(photo.path).statSync().modified;
      final diff = DateTime.now().difference(modified);
      if (diff.inDays >= 1) return s.daysAgo(diff.inDays);
      if (diff.inHours >= 1) return s.hoursAgo(diff.inHours);
      if (diff.inMinutes >= 1) return s.minutesAgo(diff.inMinutes);
      return s.justNow;
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    final grade = photo.grade;
    final rarity = grade?.tier.rarity ?? 'Common';
    final color = AppRarity.color(rarity);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        onLongPress: onLongPress,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        splashColor: color.withValues(alpha: 0.1),
        child: Container(
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1.5),
            boxShadow: [
              BoxShadow(color: color.withValues(alpha: 0.15), blurRadius: 16),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    const _CheckerboardBackground(),
                    Hero(
                      tag: 'cat_${photo.path}',
                      child: Image.file(File(photo.path), fit: BoxFit.cover),
                    ),
                    Positioned(
                      top: 8,
                      right: 8,
                      child: RarityPill(rarity: rarity),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RarityStars(rarity: rarity, size: 14, showEmpty: false),
                    const SizedBox(height: 4),
                    Text(rarity, style: AppText.heading(15, color: color)),
                    const SizedBox(height: 2),
                    Text(
                      _relativeDate(),
                      style: AppText.body(12, color: AppColors.textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onCamera});

  final VoidCallback onCamera;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🐾',
                style: TextStyle(
                    fontSize: 120,
                    color: Colors.white.withValues(alpha: 0.15))),
            const SizedBox(height: 8),
            Text(S.current.emptyGalleryTitle, style: AppText.heading(20)),
            const SizedBox(height: 8),
            Text(
              S.current.emptyGalleryBody,
              textAlign: TextAlign.center,
              style: AppText.body(14, color: AppColors.textMuted),
            ),
            const SizedBox(height: 24),
            GestureDetector(
              onTap: onCamera,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                decoration: BoxDecoration(
                  gradient: AppColors.orangeGradient,
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                  boxShadow: AppTheme.neon(AppColors.accent),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.camera_alt_rounded,
                        color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(S.current.goToCamera,
                        style: AppText.game(15, color: Colors.white)),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProcessingOverlay extends StatelessWidget {
  const _ProcessingOverlay();

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.background.withValues(alpha: 0.88),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('🐾', style: const TextStyle(fontSize: 56))
                .animate(onPlay: (c) => c.repeat())
                .rotate(duration: 1400.ms),
            const SizedBox(height: 20),
            Text('Mushuk ajratilmoqda...', style: AppText.heading(16)),
            const SizedBox(height: 6),
            Text('Fon olib tashlanmoqda, daraja hisoblanmoqda',
                style: AppText.body(12, color: AppColors.textMuted)),
            const SizedBox(height: 20),
            SizedBox(
              width: 180,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: const LinearProgressIndicator(
                  backgroundColor: AppColors.border,
                  color: AppColors.accent,
                  minHeight: 6,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CheckerboardBackground extends StatelessWidget {
  const _CheckerboardBackground();

  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _CheckerboardPainter());
  }
}

class _CheckerboardPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    const tile = 12.0;
    final paint = Paint();
    for (double y = 0; y < size.height; y += tile) {
      for (double x = 0; x < size.width; x += tile) {
        final isDark = ((x / tile).floor() + (y / tile).floor()) % 2 == 0;
        paint.color = isDark
            ? const Color(0xFF202024)
            : const Color(0xFF26262C);
        canvas.drawRect(Rect.fromLTWH(x, y, tile, tile), paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
