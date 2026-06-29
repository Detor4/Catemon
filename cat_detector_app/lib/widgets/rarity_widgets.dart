import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../cat_grade.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// CAPS rarity pill — e.g. "RARE".
class RarityPill extends StatelessWidget {
  const RarityPill({
    super.key,
    required this.rarity,
    this.fontSize = 10,
  });

  final String rarity;
  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final color = AppRarity.color(rarity);
    final gradient = AppRarity.gradient(rarity);

    final pill = Container(
      padding: EdgeInsets.symmetric(horizontal: fontSize * 0.8, vertical: 4),
      decoration: BoxDecoration(
        color: gradient == null ? color : null,
        gradient: gradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
      ),
      child: Text(
        rarity.toUpperCase(),
        style: AppText.caps(fontSize, color: Colors.white),
      ),
    );

    if (AppRarity.isAnimated(rarity)) {
      return pill
          .animate(onPlay: (c) => c.repeat())
          .shimmer(duration: 1800.ms, color: Colors.white.withValues(alpha: 0.6));
    }
    return pill;
  }
}

/// Star row — filled/empty up to [maxStars].
class RarityStars extends StatelessWidget {
  const RarityStars({
    super.key,
    required this.rarity,
    this.size = 14,
    this.maxStars = 7,
    this.showEmpty = true,
  });

  final String rarity;
  final double size;
  final int maxStars;
  final bool showEmpty;

  @override
  Widget build(BuildContext context) {
    final color = AppRarity.color(rarity);
    final filled = AppRarity.stars(rarity);
    final total = showEmpty ? maxStars : filled;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final isFilled = i < filled;
        return Icon(
          isFilled ? Icons.star_rounded : Icons.star_outline_rounded,
          size: size,
          color: isFilled ? color : AppColors.textMuted,
        );
      }),
    );
  }
}

/// Compact badge used over gallery / upgrade thumbnails.
class GradeGalleryBadge extends StatelessWidget {
  const GradeGalleryBadge({super.key, required this.grade});

  final CatGrade grade;

  @override
  Widget build(BuildContext context) {
    final rarity = grade.tier.rarity;
    final color = AppRarity.color(rarity);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.background.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          RarityStars(rarity: rarity, size: 11, showEmpty: false),
          const SizedBox(height: 2),
          Text(rarity, style: AppText.game(11, color: color)),
        ],
      ),
    );
  }
}
