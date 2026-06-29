import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'app_strings.dart';
import 'cat_grade.dart';
import 'cat_photo_store.dart';
import 'theme/app_colors.dart';
import 'theme/app_theme.dart';
import 'widgets/rarity_widgets.dart';

class CatPlayViewPage extends StatefulWidget {
  const CatPlayViewPage({
    super.key,
    required this.path,
    this.grade,
    this.heroTag,
  });

  final String path;
  final CatGrade? grade;
  final String? heroTag;

  @override
  State<CatPlayViewPage> createState() => _CatPlayViewPageState();
}

class _CatPlayViewPageState extends State<CatPlayViewPage>
    with SingleTickerProviderStateMixin {
  double _rotationX = 0;
  double _rotationY = 0;
  double _scale = 1;
  double _baseScale = 1;

  static const _maxTilt = 0.26; // ~15 degrees
  static const _minScale = 0.8;
  static const _maxScale = 2.0;
  static const _perspective = 0.0015;

  // Panel holati: 1 = ochiq (mushuk kichik), 0 = yopiq (mushuk katta).
  double _panelFraction = 1;
  double _expandedHeight = 0;

  void _resetView() {
    setState(() {
      _rotationX = 0;
      _rotationY = 0;
      _scale = 1;
      _baseScale = 1;
    });
  }

  Matrix4 _buildTransform() {
    return Matrix4.identity()
      ..setEntry(3, 2, _perspective)
      ..rotateX(_rotationX)
      ..rotateY(_rotationY)
      ..scaleByDouble(_scale, _scale, _scale, 1);
  }

  String _relativeDate() {
    final s = S.current;
    try {
      final modified = File(widget.path).statSync().modified;
      final diff = DateTime.now().difference(modified);
      if (diff.inDays >= 1) return s.daysAgo(diff.inDays);
      if (diff.inHours >= 1) return s.hoursAgo(diff.inHours);
      if (diff.inMinutes >= 1) return s.minutesAgo(diff.inMinutes);
      return s.justNow;
    } catch (_) {
      return '—';
    }
  }

  Future<void> _delete() async {
    final s = S.current;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surfaceElevated,
        title: Text(s.deleteCatTitle, style: AppText.heading(18)),
        content: Text(s.deleteCatBody, style: AppText.body(14)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(s.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(s.delete,
                style: const TextStyle(color: AppColors.accent)),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await CatPhotoStore.instance.delete(widget.path);
      if (mounted) Navigator.of(context).pop();
    }
  }

  void _onPanelDrag(double dy) {
    if (_expandedHeight <= 0) return;
    setState(() {
      _panelFraction =
          (_panelFraction - dy / _expandedHeight).clamp(0.0, 1.0);
    });
  }

  void _onPanelDragEnd(double velocity) {
    setState(() {
      if (velocity > 350) {
        _panelFraction = 0; // pastga otildi → yopiq
      } else if (velocity < -350) {
        _panelFraction = 1; // tepaga otildi → ochiq
      } else {
        _panelFraction = _panelFraction >= 0.5 ? 1 : 0;
      }
    });
  }

  void _togglePanel() {
    setState(() => _panelFraction = _panelFraction >= 0.5 ? 0 : 1);
  }

  @override
  Widget build(BuildContext context) {
    final grade = widget.grade;
    final rarity = grade?.tier.rarity ?? 'Common';
    final color = AppRarity.color(rarity);
    final screenH = MediaQuery.sizeOf(context).height;
    _expandedHeight = screenH * 0.56;
    final panelHeight = _expandedHeight * _panelFraction;
    final panelOpen = _panelFraction > 0.04;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Stage — qolgan bo'sh joyni egallaydi, mushuk avtomatik o'lchamlanadi.
          Positioned.fill(
            bottom: panelHeight,
            child: _build3dStage(color),
          ),
          // Panel
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            height: panelHeight,
            child: panelOpen
                ? _buildInfoPanel(grade, rarity, color)
                : const SizedBox.shrink(),
          ),
          // Yopiq holatda — ma'lumotni ochish tugmasi
          if (!panelOpen)
            Positioned(
              left: 0,
              right: 0,
              bottom: 24 + MediaQuery.paddingOf(context).bottom,
              child: Center(child: _InfoPill(onTap: _togglePanel)),
            ),
        ],
      ),
    );
  }

  Widget _build3dStage(Color color) {
    return Stack(
      children: [
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                radius: 0.9,
                colors: [color.withValues(alpha: 0.2), Colors.transparent],
              ),
            ),
          ),
        ),
        Positioned.fill(child: CustomPaint(painter: _DotsPainter())),
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onScaleStart: (_) => _baseScale = _scale,
            onScaleUpdate: (details) {
              setState(() {
                _rotationY =
                    (_rotationY - details.focalPointDelta.dx * 0.006)
                        .clamp(-_maxTilt, _maxTilt);
                _rotationX =
                    (_rotationX + details.focalPointDelta.dy * 0.006)
                        .clamp(-_maxTilt, _maxTilt);
                _scale =
                    (_baseScale * details.scale).clamp(_minScale, _maxScale);
              });
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Transform(
                        alignment: Alignment.center,
                        transform: _buildTransform(),
                        child: _CatImage(
                          path: widget.path,
                          heroTag: widget.heroTag,
                          maxWidth: constraints.maxWidth * 0.78,
                          maxHeight: constraints.maxHeight * 0.74,
                        ),
                      ),
                      Container(
                        width: 140,
                        height: 22,
                        margin: const EdgeInsets.only(top: 12),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(100),
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 30,
                              spreadRadius: 4,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                _circleBtn(Icons.arrow_back_rounded,
                    () => Navigator.of(context).maybePop()),
                const Spacer(),
                _circleBtn(Icons.refresh_rounded, _resetView),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _circleBtn(IconData icon, VoidCallback onTap) {
    return Material(
      color: AppColors.surfaceElevated,
      shape: const CircleBorder(),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          width: 42,
          height: 42,
          child: Icon(icon, color: AppColors.textPrimary, size: 20),
        ),
      ),
    );
  }

  Widget _buildInfoPanel(CatGrade? grade, String rarity, Color color) {
    final s = S.current;
    final quality = grade?.qualityScore ?? 0;
    final confidence = grade?.confidenceScore ?? 0;
    final colorName = grade?.tier.nameEn ?? 'Brown Tabby';

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(color: Colors.black54, blurRadius: 20, offset: Offset(0, -6)),
        ],
      ),
      child: Column(
        children: [
          // Tortiladigan tutqich
          GestureDetector(
            behavior: HitTestBehavior.opaque,
            onVerticalDragUpdate: (d) => _onPanelDrag(d.delta.dy),
            onVerticalDragEnd: (d) =>
                _onPanelDragEnd(d.primaryVelocity ?? 0),
            onTap: _togglePanel,
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 12),
              color: Colors.transparent,
              child: Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(AppRarity.emoji(rarity),
                          style: const TextStyle(fontSize: 28)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _RarityTitle(rarity: rarity, color: color),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  RarityStars(rarity: rarity, size: 22),
                  const SizedBox(height: 16),
                  Text('${s.colorQuality}: ${(quality * 100).round()}%',
                      style: AppText.body(13, color: AppColors.textSecondary)),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: quality.clamp(0.0, 1.0),
                      backgroundColor: AppColors.border,
                      color: color,
                      minHeight: 8,
                    ),
                  ),
                  const SizedBox(height: 20),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    mainAxisExtent: 64,
                    children: [
                      _StatCard(
                        icon: Icons.verified_rounded,
                        label: s.accuracy,
                        value: '${(confidence * 100).round()}%',
                        color: AppColors.accentTeal,
                      ),
                      _StatCard(
                        icon: Icons.palette_rounded,
                        label: s.color,
                        value: colorName,
                        color: color,
                      ),
                      _StatCard(
                        icon: Icons.auto_awesome_rounded,
                        label: s.quality,
                        value: '${(quality * 100).round()}%',
                        color: AppColors.accentSecondary,
                      ),
                      _StatCard(
                        icon: Icons.schedule_rounded,
                        label: s.date,
                        value: _relativeDate(),
                        color: AppColors.accentPurple,
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: _SecondaryButton(
                          icon: Icons.delete_outline_rounded,
                          label: s.delete,
                          onTap: _delete,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _GradientButton(
                          icon: Icons.ios_share_rounded,
                          label: s.share,
                          onTap: () {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(s.comingSoon),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceElevated.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(AppTheme.radiusPill),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.keyboard_arrow_up_rounded,
                color: AppColors.textPrimary, size: 20),
            const SizedBox(width: 6),
            Text(S.current.info, style: AppText.game(13)),
          ],
        ),
      ),
    ).animate(onPlay: (c) => c.repeat(reverse: true)).moveY(
          begin: 0,
          end: -4,
          duration: 1000.ms,
          curve: Curves.easeInOut,
        );
  }
}

class _CatImage extends StatelessWidget {
  const _CatImage({
    required this.path,
    this.heroTag,
    required this.maxWidth,
    required this.maxHeight,
  });

  final String path;
  final String? heroTag;
  final double maxWidth;
  final double maxHeight;

  @override
  Widget build(BuildContext context) {
    final image = ConstrainedBox(
      constraints: BoxConstraints(
        maxWidth: maxWidth.clamp(0, double.infinity),
        maxHeight: maxHeight.clamp(0, double.infinity),
      ),
      child: Image.file(
        File(path),
        fit: BoxFit.contain,
        filterQuality: FilterQuality.high,
      ),
    );
    if (heroTag == null) return image;
    return Hero(tag: heroTag!, child: image);
  }
}

class _RarityTitle extends StatelessWidget {
  const _RarityTitle({required this.rarity, required this.color});

  final String rarity;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final text = Text(rarity, style: AppText.display(32, color: color));
    if (AppRarity.isAnimated(rarity)) {
      return text.animate(onPlay: (c) => c.repeat()).shimmer(
          duration: 2000.ms, color: Colors.white.withValues(alpha: 0.7));
    }
    return text;
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.game(15)),
                Text(label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.body(11, color: AppColors.textMuted)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.textSecondary, size: 18),
            const SizedBox(width: 8),
            Text(label, style: AppText.game(14, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }
}

class _GradientButton extends StatelessWidget {
  const _GradientButton({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusButton),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          gradient: AppColors.orangeGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          boxShadow: AppTheme.neon(AppColors.accent),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.white, size: 18),
            const SizedBox(width: 8),
            Text(label, style: AppText.game(14, color: Colors.white)),
          ],
        ),
      ),
    );
  }
}

class _DotsPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.03);
    const spacing = 20.0;
    for (double y = 0; y < size.height; y += spacing) {
      for (double x = 0; x < size.width; x += spacing) {
        canvas.drawCircle(Offset(x, y), 1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
