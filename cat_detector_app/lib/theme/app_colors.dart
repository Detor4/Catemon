import 'package:flutter/material.dart';

/// CatchCat-inspired dark playful palette.
class AppColors {
  const AppColors._();

  // Base surfaces
  static const background = Color(0xFF0D0D0F);
  static const surface = Color(0xFF18181C);
  static const surfaceElevated = Color(0xFF222228);
  static const border = Color(0xFF2E2E38);

  // Accents
  static const accent = Color(0xFFFF6B35); // warm neon orange
  static const accentLight = Color(0xFFFF8C42);
  static const accentSecondary = Color(0xFFFFD166); // golden yellow
  static const accentTeal = Color(0xFF06D6A0); // detection success
  static const accentTealDeep = Color(0xFF00B4D8);
  static const accentPurple = Color(0xFF9B5DE5); // epic/legendary glow

  // Text
  static const textPrimary = Color(0xFFF5F5F7);
  static const textSecondary = Color(0xFF8E8E99);
  static const textMuted = Color(0xFF52525C);

  static const orangeGradient = LinearGradient(
    colors: [accent, accentLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const tealGradient = LinearGradient(
    colors: [accentTeal, accentTealDeep],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const mythicGradient = LinearGradient(
    colors: [accent, accentSecondary, accentPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

/// Rarity -> color / star count / emoji helpers.
///
/// Rarity nomlari `cat_grade.dart` dagi `CatGradeTier.rarity` bilan mos:
/// Common, Common+, Uncommon, Rare, Epic, Legendary, Mythic.
class AppRarity {
  const AppRarity._();

  static Color color(String rarity) => switch (rarity.toLowerCase()) {
        'common' => const Color(0xFF9CA3AF),
        'common+' => const Color(0xFFF59E0B),
        'uncommon' => const Color(0xFF3B82F6),
        'rare' => const Color(0xFF8B5CF6),
        'epic' => const Color(0xFFEC4899),
        'legendary' => const Color(0xFFFF6B35),
        'mythic' => const Color(0xFFFFD166),
        _ => const Color(0xFF9CA3AF),
      };

  static int stars(String rarity) => switch (rarity.toLowerCase()) {
        'common' => 1,
        'common+' => 2,
        'uncommon' => 3,
        'rare' => 4,
        'epic' => 5,
        'legendary' => 6,
        'mythic' => 7,
        _ => 1,
      };

  static String emoji(String rarity) => switch (rarity.toLowerCase()) {
        'common' => '⭐',
        'common+' => '⭐⭐',
        'uncommon' => '🔵',
        'rare' => '💜',
        'epic' => '💗',
        'legendary' => '🔥',
        'mythic' => '✨',
        _ => '⭐',
      };

  /// Mythic uchun animatsion shimmer gradient, qolganlar uchun null.
  static Gradient? gradient(String rarity) {
    if (rarity.toLowerCase() == 'mythic') return AppColors.mythicGradient;
    return null;
  }

  static bool isAnimated(String rarity) {
    final r = rarity.toLowerCase();
    return r == 'mythic' || r == 'legendary';
  }
}
